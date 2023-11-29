//
//  AckOrError.swift
//
//
//  Created by Dr. Brandon Wiley on 11/29/23.
//

import Foundation

public enum AckOrError
{
    case ack
    case error(Error)
}
