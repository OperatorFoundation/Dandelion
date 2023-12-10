//
//  DandelionErrors.swift
//  
//
//  Created by Mafalda on 9/18/23.
//

import Foundation

public enum DandelionConfigError: Error
{
    case urlIsNotDirectory
    case failedToSaveFile(filePath: String)
    case invalidJSON
    case invalidServerPort(serverAddress: String)
    case failedToLoadKeychain(keychainURL: URL)
    case failedToGeneratePrivateKey
    
    public var description: String
    {
        switch self
        {
            case .urlIsNotDirectory:
                return "The provided URL is not a directory."
            case .failedToSaveFile(let filePath):
                return "Failed to save the config file to \(filePath)"
            case .invalidJSON:
                return "Error decoding JSON data."
            case .invalidServerPort(let serverAddress):
                return "Error decoding Dandelion config data: invalid server port from address: \(serverAddress)"
            case .failedToLoadKeychain(let keychainURL):
                return "Error loading keychain at \(keychainURL.absoluteString)"
            case .failedToGeneratePrivateKey:
                return "Error generating a new private key."
        }
    }
}
