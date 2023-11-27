//
//  NametagPumpToClient.swift
//
//
//  Created by Mafalda on 10/31/23.
//

import Foundation

import TransmissionAsync
import TransmissionAsyncNametag


class NametagPumpToClient
{
    let targetToTransportQueue = DispatchQueue(label: "ShapeshifterDispatcherSwift.targetToTransportQueue")
    
    var router: NametagRouter
    
    
    init(router: NametagRouter)
    {
        self.router = router
        
        Task
        {
            print("⚘ NametagPumpToClient: calling transferTargetToTransport()")
            await self.transferTargetToTransport(transportConnection: router.clientConnection, targetConnection: router.targetConnection)
        }
    }
    
    func transferTargetToTransport(transportConnection: AsyncNametagServerConnection, targetConnection: AsyncConnection) async
    {
        print("⚘ Target to Transport")
        
        // Check to see if we have data waiting for the client from a previous session
        // Send it if we do and clear it out when we are done
        if let dataWaiting = await router.bufferedDataForClient
        {
            do
            {
                print("⚘ Target to Transport: Writing buffered data (\(dataWaiting.count) bytes) to the client connection.")
                try await transportConnection.network.write(dataWaiting)
                await router.updateBuffer(data: nil)
            }
            catch (let error)
            {
                print("⚘ Target to Transport: Unable to send target data to the transport connection. The connection was likely closed. Error: \(error)")
                await router.clientClosed()
                return
            }
        }
        
        while await router.state == .active
        {
            do
            {
                let dataFromTarget = try await targetConnection.readMinMaxSize(1, NametagRouter.maxReadSize)
                
                guard dataFromTarget.count > 0 else
                {
                    // Skip to the next round
                    print("⚘ Target to Transport: Received 0 bytes while reading from the target connection.")
                    continue
                }
                  
                print("⚘ Target to Transport: Received \(dataFromTarget.count) bytes while reading from the target connection.")
                
                do
                {
                    try await transportConnection.network.write(dataFromTarget)
                    print("⚘ Target to Transport: Wrote \(dataFromTarget.count) bytes to the transport connection.")
                }
                catch (let error)
                {
                    print("⚘ Target to Transport: Unable to send target data to the transport connection. The connection was likely closed. Error: \(error)")
                    await router.updateBuffer(data: dataFromTarget)
                    await router.clientClosed()
                    break
                }
            }
            catch (let error)
            {
                print("⚘ Target to Transport: Received no data from the target on read. Error: \(error)")
                await router.serverClosed()
                break
            }
            
            await Task.yield() // Take turns
        }
        
        print("⚘ Target to Transport: loop finished.")
    }
}
