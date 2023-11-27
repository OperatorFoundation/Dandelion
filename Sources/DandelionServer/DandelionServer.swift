//
//  DandelionBackend.swift
//  
//
//  Created by Mafalda on 9/12/23.
//

import Foundation
import Net
import Logging

import Dandelion
import TransmissionAsync
import TransmissionAsyncNametag

public class DandelionServer
{
    let config: DandelionConfig.ServerConfig
    let listener: AsyncListener
    let logger: Logger
    
    public init?(config: DandelionConfig.ServerConfig, logger: Logger)
    {
        guard config.serverIP != "0.0.0.0" else
        {
            logger.error("0.0.0.0 is not a valid host")
            return nil
        }
        
        guard let _ = IPv4Address(config.serverIP) else
        {
            logger.error("\(config.serverIP) is not a valid IPv4 address")
            return nil
        }
        
        do
        {
            let newListener = try AsyncTcpSocketListener(port:Int(config.serverPort), logger)
            self.listener = newListener
            self.logger = logger
            self.config = config
        }
        catch (let error)
        {
            logger.error("⚘ Failed to start a listener on port \(config.serverPort). Error: \(error)")
            return nil
        }
        
        
    }
    
    public func accept() async throws -> AsyncNametagServerConnection
    {
        let connection = try await listener.accept()
        let authenticatedConnection = try await AsyncNametagServerConnection(connection, logger)
        
        return authenticatedConnection
    }
    
    public func close() async throws
    {
        try await listener.close()
    }
    
}
