//
//  DandelionServerError.swift
//
//
//  Created by Mafalda on 9/25/23.
//

import Foundation

public enum DandelionServerError: Error
{
    case invalidPublicKey
    
    public var description: String
    {
        switch self {
            case .invalidPublicKey:
                return "The config key and the connection key do not match."
        }
    }
}
