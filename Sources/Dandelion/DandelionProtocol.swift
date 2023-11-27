//
//  DandelionProtocol.swift
//
//
//  Created by Dr. Brandon Wiley on 11/21/23.
//

import Foundation
import TransmissionAsync

public enum DandelionProtocolMessageType: UInt8
{
    case close = 67 // 'C'
    case write = 87 // 'W'
    case ack   = 65 // 'A'
}

public enum DandelionProtocolMessage
{
    public init(data: Data) throws
    {
        guard let type = data.first else
        {
            throw DandelionProtocolError.chunkTooShort
        }

        let payload = data.dropFirst()

        guard let type = DandelionProtocolMessageType(rawValue: type) else
        {
            throw DandelionProtocolError.badCommand(type)
        }

        switch type
        {
            case .ack:
                self = .ack
                return

            case .close:
                self = .close
                return

            case .write:
                self = .write(payload)
                return
        }
    }

    public var data: Data
    {
        switch self
        {
            case .ack:
                return Data(array: [DandelionProtocolMessageType.ack.rawValue])

            case .close:
                return Data(array: [DandelionProtocolMessageType.close.rawValue])

            case .write(let payload):
                return Data(array: [DandelionProtocolMessageType.write.rawValue] + payload)
        }
    }

    case close
    case write(Data)
    case ack
}

public class DandelionProtocol
{
    static let lengthPrefix: Int = 64

    let connection: AsyncConnection

    public init(_ connection: AsyncConnection)
    {
        self.connection = connection
    }

    public func readMessage() async throws -> DandelionProtocolMessage
    {
        let data = try await self.connection.readWithLengthPrefix(prefixSizeInBits: Self.lengthPrefix)
        return try DandelionProtocolMessage(data: data)
    }

    public func write(data: Data) async throws
    {
        let message = DandelionProtocolMessage.write(data)
        try await self.connection.writeWithLengthPrefix(message.data, Self.lengthPrefix)
    }

    public func ack() async throws
    {
        let message = DandelionProtocolMessage.ack
        try await self.connection.writeWithLengthPrefix(message.data, Self.lengthPrefix)
    }

    public func close() async throws
    {
        let message = DandelionProtocolMessage.close
        try await self.connection.writeWithLengthPrefix(message.data, Self.lengthPrefix)
    }
}

public enum DandelionProtocolError: Error
{
    case chunkTooShort
    case badCommand(UInt8)
    case missingData
}
