//
//  DandelionConfig.swift
//  
//
//  Created by Mafalda on 9/18/23.
//

import Foundation

import Keychain

public class DandelionConfig
{
    static let dandelionName = "dandelion"
    
    public struct ServerConfig: Codable
    {
        public static let serverConfigFilename = "DandelionServerConfig.json"
        
        public let serverPublicKey: PublicKey
        public let serverAddress: String
        public let serverIP: String
        public let serverPort: UInt16
        public let transportName: String
        
        private enum CodingKeys : String, CodingKey
        {
            case serverAddress
            case serverPublicKey
            case transportName = "transport"
        }
        
        public init(serverAddress: String, serverPublicKey: PublicKey) throws
        {
            self.serverAddress = serverAddress
            
            let addressStrings = serverAddress.split(separator: ":")
            self.serverIP = String(addressStrings[0])
            guard let port = UInt16(addressStrings[1]) else
            {
                print("Error decoding Dandelion ServerConfig data: invalid server port \(addressStrings[1])")
                throw DandelionConfigError.invalidServerPort(serverAddress: serverAddress)
            }
            
            self.serverPort = port
            self.transportName = DandelionConfig.dandelionName
            self.serverPublicKey = serverPublicKey
        }
        
        public init?(from data: Data)
        {
            let decoder = JSONDecoder()
            
            do
            {
                self = try decoder.decode(ServerConfig.self, from: data)
                
                guard transportName.lowercased() == DandelionConfig.dandelionName.lowercased() else
                {
                    print("Unable to create a Dandelion config, the decoded config data has a different transport name: \(transportName)")
                    return nil
                }
            }
            catch
            {
                print("Error received while attempting to decode a Dandelion ServerConfig json file: \(error)")
                return nil
            }
        }
        
        public init?(path: String)
        {
            let url = URL(fileURLWithPath: path)
            
            do
            {
                let data = try Data(contentsOf: url)
                self.init(from: data)
            }
            catch
            {
                print("Error decoding Dandelion ServerConfig file: \(error)")
                
                return nil
            }
        }
        
        public init(from decoder: Decoder) throws
        {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let address = try container.decode(String.self, forKey: .serverAddress)
            let addressStrings = address.split(separator: ":")
            
            guard let port = UInt16(addressStrings[1]) else
            {
                print("Error decoding Dandelion ServerConfig data: invalid server port")
                throw DandelionConfigError.invalidJSON
            }
            
            self.serverIP = String(addressStrings[0])
            self.serverAddress = address
            self.serverPort = port
            self.serverPublicKey = try container.decode(PublicKey.self, forKey: .serverPublicKey)
            self.transportName = try container.decode(String.self, forKey: .transportName)
            
            guard transportName.lowercased() == DandelionConfig.dandelionName.lowercased() else
            {
                print("Unable to create a Dandelion config, the decoded config data has a different transport name: \(transportName)")
                throw DandelionConfigError.invalidJSON
            }
        }
    }
    
    public struct ClientConfig: Codable
    {
        public static let clientConfigFilename = "DandelionClientConfig.json"
        
        public let serverAddress: String
        public let serverIP: String
        public let serverPort: UInt16
        public let transportName: String
        
        private enum CodingKeys : String, CodingKey
        {
            case serverAddress
            case transportName = "transport"
        }
        
        public init(serverAddress: String) throws
        {
            self.serverAddress = serverAddress
            
            let addressStrings = serverAddress.split(separator: ":")
            self.serverIP = String(addressStrings[0])
            guard let port = UInt16(addressStrings[1]) else
            {
                print("Error decoding Dandelion ClientConfig data: invalid server port \(addressStrings[1])")
                throw DandelionConfigError.invalidServerPort(serverAddress: serverAddress)
            }
            
            self.serverPort = port
            self.transportName = DandelionConfig.dandelionName
        }
        
        public init?(from data: Data)
        {
            let decoder = JSONDecoder()
            
            do
            {
                self = try decoder.decode(ClientConfig.self, from: data)
                
                guard transportName.lowercased() == DandelionConfig.dandelionName.lowercased() else
                {
                    print("Unable to create a Dandelion client config, the decoded config data has a different transport name: \(transportName)")
                    return nil
                }
            }
            catch
            {
                print("Error received while attempting to decode a Dandelion ClientConfig json file: \(error)")
                return nil
            }
        }
        
        public init?(path: String)
        {
            let url = URL(fileURLWithPath: path)
            
            do
            {
                let data = try Data(contentsOf: url)
                self.init(from: data)
            }
            catch
            {
                print("Error decoding Dandelion ClientConfig file: \(error)")
                
                return nil
            }
        }
        
        public init(from decoder: Decoder) throws
        {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let address = try container.decode(String.self, forKey: .serverAddress)
            let addressStrings = address.split(separator: ":")
            
            guard let port = UInt16(addressStrings[1]) else
            {
                print("Error decoding Dandelion client config data: invalid server port")
                throw DandelionConfigError.invalidJSON
            }
            
            self.serverIP = String(addressStrings[0])
            self.serverAddress = address
            self.serverPort = port
            self.transportName = try container.decode(String.self, forKey: .transportName)
            
            guard transportName.lowercased() == DandelionConfig.dandelionName.lowercased() else
            {
                print("Unable to create a Dandelion client config, the decoded config data has a different transport name: \(transportName)")
                throw DandelionConfigError.invalidJSON
            }
            
        }
    }
    
    public static func generateNewConfigPair(serverAddress: String) throws -> (serverConfig: ServerConfig, clientConfig: ClientConfig)
    {
        let privateKey = try PrivateKey(type: .P256KeyAgreement)
        let publicKey = privateKey.publicKey
        
        let serverConfig = try ServerConfig(serverAddress: serverAddress, serverPublicKey: publicKey)
        let clientConfig = try ClientConfig(serverAddress: serverAddress)
        
        return (serverConfig, clientConfig)
    }

    public static func createNewConfigFiles(inDirectory saveDirectory: URL, serverAddress: String) throws
    {
        guard saveDirectory.hasDirectoryPath else
        {
            throw DandelionConfigError.urlIsNotDirectory
        }

        let configPair = try DandelionConfig.generateNewConfigPair(serverAddress: serverAddress)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes, .prettyPrinted]
        let serverJson = try encoder.encode(configPair.serverConfig)
        let serverConfigFilePath = saveDirectory.appendingPathComponent(ServerConfig.serverConfigFilename).path
        
        guard FileManager.default.createFile(atPath: serverConfigFilePath, contents: serverJson) else
        {
            throw DandelionConfigError.failedToSaveFile(filePath: serverConfigFilePath)
        }

        let clientJson = try encoder.encode(configPair.clientConfig)
        
        let clientConfigFilePath = saveDirectory.appendingPathComponent(ClientConfig.clientConfigFilename).path

        guard FileManager.default.createFile(atPath: clientConfigFilePath, contents: clientJson) else
        {
            throw DandelionConfigError.failedToSaveFile(filePath: clientConfigFilePath)
        }
    }
    
    
}
