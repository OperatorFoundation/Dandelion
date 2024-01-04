//
//  DandelionClient.swift
//
//
//  Created by Mafalda on 9/12/23.
//

import Foundation
import Logging

import Dandelion
import KeychainCli
import Nametag
import ShadowSwift
import TransmissionNametag
import TransmissionAsyncNametag

public class DandelionClient
{
    let keychain: Keychain
    let keychainLabel: String
    let logger = Logger(label: "Dandelion Client Logger")
    
    public init(keychain: Keychain, keychainLabel: String)
    {
        self.keychain = keychain
        self.keychainLabel = keychainLabel
    }
    
    public convenience init?(keychainURL: URL, keychainLabel: String)
    {
        guard let keychain = Keychain(baseDirectory: keychainURL) else
        {
            return nil
        }
        
        self.init(keychain: keychain, keychainLabel: keychainLabel)
    }
    
    public func loadTransportConfigs(from configDirectory: URL) -> Bool
    {
        // TODO: Unimplemented
        return false
    }
    
    public func connectToDandelionServer(serverIP: String, serverPort: Int) async throws -> AsyncDandelionClientConnection
    {
        guard let privateSigningKey = keychain.retrieveOrGeneratePrivateKey(label: keychainLabel, type: KeyType.P256Signing) else
        {
            print("DandelionClient Failed to connect to a Dandelion server: we were unable to retrieve the private key from the keychain provided.")
            throw AsyncDandelionClientConnectionError.keychainError
        }
        
        let publicKey = privateSigningKey.publicKey
        
        print("• Initializing nametag. Public key is \(publicKey.data!.count) bytes, expected public key size is 65 bytes.")
        
        guard let _ = Nametag(keychain: keychain) else
        {
            print("DandelionClient Failed to connect to a Dandelion server: we were unable to a Nametag instance with the keychain provided.")
            throw AsyncDandelionClientConnectionError.nametagError
        }
        
        print("• Created a Nametag instance.")
        
        do
        {
            let connection = try await AsyncDandelionClientConnection(keychain, serverIP, serverPort, logger, verbose: true)
            print("• Created an AsyncDandelionConnection connection.")
            return connection
        }
        catch (let error)
        {
            print("• Failed to create an AsyncDandelionConnection connection: \(error)")
            throw AsyncDandelionClientConnectionError.connectionFailed
        }
    }
    
    public func connectShadowToDandelionServer(shadowConfigURL: URL) async throws -> AsyncDandelionClientConnection
    {
        guard let shadowConfig = ShadowConfig.ShadowClientConfig(path: shadowConfigURL.path()) else
        {
            throw AsyncDandelionClientConnectionError.invalidTransportConfig
        }
        
        return try await connectShadowToDandelionServer(shadowClientConfig: shadowConfig)
    }
    
    public func connectShadowToDandelionServer(shadowClientConfig: ShadowConfig.ShadowClientConfig) async throws -> AsyncDandelionClientConnection
    {
        guard let _ = Nametag(keychain: keychain) else
        {
            throw AsyncDandelionClientConnectionError.nametagError
        }
        
        print("• created a Nametag instance.")
        
        do
        {
            // Use Shadow config to make a Nametag connection
            let nametagConnection = try await AsyncNametagClientConnection(config: shadowClientConfig, keychain: keychain, logger: logger)
            
            return AsyncDandelionClientConnection(nametagConnection, logger, verbose: true)
        }
        catch (let error)
        {
            print("Failed to create a nametag connection: \(error)")
            throw AsyncDandelionClientConnectionError.connectionFailed
        }
    }
}
