//
//  NametagPumpToServer.swift
//
//
//  Created by Mafalda on 10/31/23.
//

import Foundation

import Dandelion
import TransmissionAsync
import TransmissionAsyncNametag

class NametagPumpToServer
{
    let transportToTargetQueue = DispatchQueue(label: "ShapeshifterDispatcherSwift.transportToTargetQueue")
    
    var router: NametagRouter
    
    
    init(router: NametagRouter)
    {
        self.router = router
        
        Task
        {
            print("⚘ NametagPumpToServer: calling transferTransportToTarget()")
            await self.transferTransportToTarget(transportConnection: router.clientConnection, targetConnection: router.targetConnection)
        }
    }
    
    func transferTransportToTarget(transportConnection: AsyncNametagServerConnection, targetConnection: AsyncConnection) async
    {
        print("⚘ Transport to Target")
        let dandelionProtocolConnection = DandelionProtocol(transportConnection.network)
        
        while await router.state == .active
        {
            do
            {
                print("⚘ Transport to Target: Attempting to read from the transport connection.")
                
                let dandelionMessage = try await dandelionProtocolConnection.readMessage()
                
                switch dandelionMessage 
                {
                    case .close:
                        print("⚘ Transport to Target: received a close message from the client. Closing the target and transport connection.")
                        await router.serverClosed()
                        break
                        
                    case .write(let dataFromTransport):
                        print("⚘ Transport to Target: received \(dataFromTransport.count) bytes while reading from the transport connection.")
                        
                        guard dataFromTransport.count > 0 else
                        {
                            continue
                        }
                        
                        do
                        {
                            try await targetConnection.write(dataFromTransport)
                        }
                        catch (let error)
                        {
                            print("⚘ Transport to Target: Unable to send transport data to the target connection. The connection was likely closed. Error: \(error)")
                            await router.serverClosed()
                            break
                        }
                        
                    case .ack:
                        await router.updateBuffer(data: nil) // Clear the unACKed data
                        
                        if await router.unsentClientData.count > 0
                        {
                            let dataToSend = try await router.unsentClientData.read()
                            await router.updateBuffer(data: dataToSend)
                            try await transportConnection.network.write(dataToSend)
                        }
                }
            }
            catch (let error)
            {
                print("⚘ Transport to Target: Received no data from the transport on read. Error: \(error)")
                await router.clientClosed()
                break
            }
            
            await Task.yield() // Take turns y'all
        }
    }
}
