//
//  NametagPumpToClient.swift
//
//
//  Created by Mafalda on 10/31/23.
//

import Foundation

import Chord
import Dandelion
import TransmissionAsync
import TransmissionAsyncNametag

class NametagPumpToClient
{
    let targetToTransportQueue = DispatchQueue(label: "ShapeshifterDispatcherSwift.targetToTransportQueue")
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
            print("⚘🍃 NametagPumpToClient: calling transferTargetToTransport()")
            await self.transferTargetToTransport()
        }
    }
    
    func transferTargetToTransport() async
    {
        print("⚘🍃 Target to Transport")
        var dataFromTarget: Data? = nil

        while await router.state != .closing
        {
            print("⚘🍃 NametagPumpToClient attempting to deqeue a connection from clients.")
            let client = await self.clients.dequeue() // New client
            print("⚘🍃 NametagPumpToClient deqeued a connection from clients.")
            
            while await router.state == .active
            {
                do
                {
                    if let dataWaiting = dataFromTarget
                    {
                        do
                        {
                            try await sendAndAckWait(client: client, dataToSend: dataWaiting)
                            dataFromTarget = nil
                        }
                        catch
                        {
                            await router.clientClosed()
                            break
                        }
                    }
                    else
                    {
                        // We don't have any data to send
                        // Let's try getting some
                        print("⚘🍃 Target to Transport: attempting to read from the target connection.")
                        
                        // Get new data from the server
                        let newData = try await router.targetConnection.readMinMaxSize(1, NametagRouter.maxReadSize)
                        
                        guard newData.count > 0 else
                        {
                            // Skip to the next round
                            print("⚘🍃 Target to Transport: Received 0 bytes while reading from the target connection.")
                            continue
                        }
                        
                        print("⚘🍃 Target to Transport: Received \(newData.count) bytes while reading from the target connection.")
                        
                        do
                        {
                            try await sendAndAckWait(client: client, dataToSend: newData)
                        }
                        catch
                        {
                            // Save the data we didn't get an ack for so we can try again in the next round
                            dataFromTarget = newData
                            await router.clientClosed()
                            break
                        }
                    }
                    
                }
                catch (let error)
                {
                    print("⚘🍃 Target to Transport: Unable to read data from the target. Error: \(error)")
                    await router.serverClosed()
                }
            }
            
            await Task.yield() // Take turns
        }

        print("⚘🍃 Target to Transport: loop finished.")
    }
    
    func sendAndAckWait(client: AsyncNametagServerConnection, dataToSend: Data) async throws
    {
        print("⚘ Target to Transport: Writing buffered data (\(dataToSend.count) bytes) to the client connection.")
        try await client.network.writeWithLengthPrefix(dataToSend, DandelionProtocol.lengthPrefix)
        print("⚘ Target to Transport: Wrote \(dataToSend.count) bytes of buffered data to the client connection.")
        
        print("⚘🍃 Target to Transport: attempting to dequeue from the ack channel.")
        let ackOrError = await self.ackChannel.dequeue()
        print("⚘🍃 Target to Transport: dequeued from the ack channel.")
        
        switch ackOrError
        {
            case .ack:
                print("⚘🍃 received ack from other pump")

            case .error(let error):
                print("⚘🍃 Error received from other pump: \(error)")
                throw error
        }
    }
    
    public func close()
    {
        self.pump?.cancel()
    }
}
