//
//  ClientConnection.swift
//
//
//  Created by Dr. Brandon Wiley on 12/12/23.
//

import Foundation

import TransmissionAsyncNametag

public class ClientConnection
{
    public let connection: AsyncNametagServerConnection
    public let uuid: UUID

    public init(connection: AsyncNametagServerConnection)
    {
        self.connection = connection

        self.uuid = UUID()
    }
}
