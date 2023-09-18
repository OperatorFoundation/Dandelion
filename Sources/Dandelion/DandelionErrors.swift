//
//  DandelionErrors.swift
//  
//
//  Created by Mafalda on 9/18/23.
//

import Foundation

enum DandelionConfigError: Error
{
    case urlIsNotDirectory
    case failedToSaveFile(filePath: String)
    case invalidJSON
    case invalidServerPort(serverAddress: String)
    
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
        }
    }
}
