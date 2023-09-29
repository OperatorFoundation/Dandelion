//
//  DandelionFrontendServer.swift
//
//
//  Created by Mafalda on 9/19/23.
//

import Foundation
import Net

#if os(macOS) || os(iOS)
import os.log
#else
import Logging
#endif

import Dandelion
import Transmission
import TransmissionNametag


public class DandelionFrontendServer
{
    let config: DandelionConfig.ServerConfig
    let listener: TransmissionListener
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
        
        guard let newListener = TransmissionListener(port: Int(config.serverPort), logger: logger) else
        {
            logger.error("Failed to start a listener on port \(config.serverPort)")
            return nil
        }
        
        self.listener = newListener
        self.logger = logger
        self.config = config
    }
    
    public func accept() throws -> NametagServerConnection
    {
        let connection = listener.accept()
        let authenticatedConnection = try NametagServerConnection(connection, logger)
        
        guard authenticatedConnection.publicKey == config.serverPublicKey else
        {
            throw DandelionServerError.invalidPublicKey
        }
        
        
        return authenticatedConnection
    }
    
    public func close() 
    {
        listener.close()
    }
    
    
}
