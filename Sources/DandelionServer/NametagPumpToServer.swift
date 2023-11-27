//
//  NametagPumpToServer.swift
//
//
//  Created by Mafalda on 10/31/23.
//

import Foundation

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
        print("⚘ Transport to Target running...")
        
        while await router.state == .active
        {
            print("⚘ Transport to Target: Attempting to read...")
            
            do
            {
                let dataFromTransport = try await transportConnection.network.readMinMaxSize(1, NametagRouter.maxReadSize)
                print("⚘ Transport to Target: read \(dataFromTransport.count) bytes.")
                
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
                    print("⚘ Transport to Target: Unable to send target data to the target connection. The connection was likely closed. Error: \(error)")
                    await router.serverClosed()
                    break
                }
            }
            catch (let error)
            {
                print("⚘ Transport to Target: Received no data from the target on read. Error: \(error)")
                await router.clientClosed()
                break
            }
            
            await Task.yield() // Take turns y'all
        }
    }
}
