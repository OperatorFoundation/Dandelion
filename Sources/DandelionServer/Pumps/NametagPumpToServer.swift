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
            print("⚘🍂 NametagPumpToServer: calling transferTransportToTarget()")
            await self.transferTransportToTarget()
        }
    }
    
    func transferTransportToTarget() async
    {
        print("⚘🍂 Transport to Target")

        while await router.state != .closing
        {
            print("⚘🍂 NametagPumpToServer attempting to deqeue a connection from clients.")
            let client = await self.clients.dequeue()
            print("⚘🍂 NametagPumpToServer deqeued a connection from clients.")
            
            let dandelionProtocolConnection = DandelionProtocol(client.network)

            while await router.state == .active
            {
                do
                {
                    print("⚘🍂 Transport to Target: Attempting to read from the transport connection.")

                    let dandelionMessage = try await dandelionProtocolConnection.readMessage()

                    switch dandelionMessage
                    {
                        case .close:
                            print("⚘🍂 Transport to Target: received a close message from the client. Closing the target and transport connection.")
                            await router.serverClosed()
                            return

                        case .write(let dataFromTransport):
                            print("⚘🍂 Transport to Target: received \(dataFromTransport.count) bytes while reading from the transport connection.")

                            guard dataFromTransport.count > 0 else
                            {
                                continue
                            }

                            do
                            {
                                print("⚘🍂 Transport to Target: attempting to write \(dataFromTransport.count) bytes to the target connection.")
                                try await router.targetConnection.write(dataFromTransport)
                                print("⚘🍂 Transport to Target: Wrote \(dataFromTransport.count) bytes to the target connection.")
                            }
                            catch (let error)
                            {
                                print("⚘🍂 Transport to Target: Unable to send transport data to the target connection. The connection was likely closed. Error: \(error)")
                                await router.serverClosed()
                                return
                            }

                        case .ack:
                            await self.ackChannel.enqueue(element: .ack)
                    }
                }
                catch (let error)
                {
                    print("⚘🍂 Transport to Target: Received no data from the transport on read. Error: \(error)")
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
