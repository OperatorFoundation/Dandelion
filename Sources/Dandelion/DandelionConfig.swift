//
//  DandelionConfig.swift
//  
//
//  Created by Mafalda on 9/18/23.
//

import Foundation

public class DandelionConfig
{
    public struct ServerConfig: Codable
    {
        public static let serverConfigFilename = "DandelionServerConfig.json"
        
        public let serverAddress: String
        public let serverIP: String
        public let serverPort: UInt16
        public var transportName = "dandelion"
        
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
                print("Error decoding Dandelion ServerConfig data: invalid server port \(addressStrings[1])")
                throw DandelionConfigError.invalidServerPort(serverAddress: serverAddress)
            }
            
            self.serverPort = port
        }
        
        public init?(from data: Data)
        {
            let decoder = JSONDecoder()
            
            do
            {
                self = try decoder.decode(ServerConfig.self, from: data)
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
            self.transportName = try container.decode(String.self, forKey: .transportName)
        }
    }
    
    public struct ClientConfig: Codable
    {
        public static let clientConfigFilename = "DandelionClientConfig.json"
        
        public let serverAddress: String
        public let serverIP: String
        public let serverPort: UInt16
        public var transportName = "dandelion"
        
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
        }
        
        public init?(from data: Data)
        {
            let decoder = JSONDecoder()
            
            do
            {
                self = try decoder.decode(ClientConfig.self, from: data)
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
                print("Error decoding Dandelion ClientConfig data: invalid server port")
                throw DandelionConfigError.invalidJSON
            }
            
            self.serverIP = String(addressStrings[0])
            self.serverAddress = address
            self.serverPort = port
            self.transportName = try container.decode(String.self, forKey: .transportName)
        }
    }
    
    public static func generateNewConfigPair(serverAddress: String) throws -> (serverConfig: ServerConfig, clientConfig: ClientConfig)
    {
        let serverConfig = try ServerConfig(serverAddress: serverAddress)
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
