//
//  NametagPumpToServer.swift
//
//
//  Created by Mafalda on 10/31/23.
//

import Foundation

import Chord
import Dandelion
import TransmissionAsync
import TransmissionAsyncNametag

class NametagPumpToServer
{
    let router: NametagRouter
    let clients: AsyncQueue<AsyncNametagServerConnection>
    let ackChannel: AsyncQueue<AckOrError>

    var pump: Task<(), Never>? = nil

    init(router: NametagRouter, clients: AsyncQueue<AsyncNametagServerConnection>, ackChannel: AsyncQueue<AckOrError>)
    {
        self.router = router
        self.clients = clients

        self.ackChannel = ackChannel

        self.pump = Task
        {
            print("⚘⏛⚘ NametagPumpToServer: calling transferTransportToTarget()")
            await self.transferTransportToTarget()
        }
    }
    
    func transferTransportToTarget() async
    {
        print("⚘⏛⚘ Transport to Target")

        while await router.state != .closing
        {
            print("⚘⏛⚘ NametagPumpToServer attempting to deqeue a connection from clients.")
            let client = await self.clients.dequeue()
            print("⚘⏛⚘ NametagPumpToServer deqeued a connection from clients.")
            
            let dandelionProtocolConnection = DandelionProtocol(client.network)

            while await router.state == .active
            {
                do
                {
                    print("⚘⏛⚘ Transport to Target: Attempting to read from the transport connection.")

                    let dandelionMessage = try await dandelionProtocolConnection.readMessage()

                    switch dandelionMessage
                    {
                        case .close:
                            print("⚘⏛⚘ Transport to Target: received a close message from the client. Closing the target and transport connection.")
                            await router.serverClosed()
                            return

                        case .write(let dataFromTransport):
                            print("⚘⏛⚘ Transport to Target: received \(dataFromTransport.count) bytes while reading from the transport connection.")

                            guard dataFromTransport.count > 0 else
                            {
                                continue
                            }

                            do
                            {
                                print("⚘⏛⚘ Transport to Target: attempting to write \(dataFromTransport.count) bytes to the target connection.")
                                try await router.targetConnection.write(dataFromTransport)
                                print("⚘⏛⚘ Transport to Target: Wrote \(dataFromTransport.count) bytes to the target connection.")
                            }
                            catch (let error)
                            {
                                print("⚘⏛⚘ Transport to Target: Unable to send transport data to the target connection. The connection was likely closed. Error: \(error)")
                                await router.serverClosed()
                                return
                            }

                        case .ack:
                            await self.ackChannel.enqueue(element: .ack)

                            if let unackedData = await router.unAckedClientData
                            {
                                print("⚘⏛⚘ Transport to Target: ACKed \(unackedData.count)")
                            }
                            else
                            {
                                print("⚘⏛⚘ Transport to Target: received an ACK from the client, but the unAcked buffer is nil. ")
                            }
                            await router.updateBuffer(data: nil) // Clear the unACKed data

                            if await router.unsentClientData.count > 0
                            {
                                let dataToSend = try await router.unsentClientData.read()
                                await router.updateBuffer(data: dataToSend)

                                print("⚘⏛⚘ Transport to Target: Writing buffered data (\(dataToSend.count) bytes) to the client connection.")
                                try await client.network.write(dataToSend)
                                print("⚘⏛⚘ Transport to Target: Wrote \(dataToSend.count) bytes of buffered data to the client connection.")
                            }
                    }
                }
                catch (let error)
                {
                    print("⚘⏛⚘ Transport to Target: Received no data from the transport on read. Error: \(error)")
                    await ackChannel.enqueue(element: .error(error))
                    await router.clientClosed()
                    break
                }

                await Task.yield() // Take turns y'all
            }
        }
    }
    
    public func close()
    {
        self.pump?.cancel()
    }
}
