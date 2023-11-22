//
//  DandelionProtocol.swift
//
//
//  Created by Dr. Brandon Wiley on 11/21/23.
//

import Foundation
import TransmissionAsync

extension UInt8
{
    public func check(bitmask: UInt8) -> Bool
    {
        return (self & bitmask) == 1
    }
}

public enum DandelionProtocolBitmask: UInt8
{
    case close = 0b00000001
    case write = 0b00000010
    case ack   = 0b00000100
}

public enum DandelionProtocolMessage
{
    static public func parseCommand(_ byte: UInt8, _ payload: Data) -> [DandelionProtocolMessage]
    {
        var results: [DandelionProtocolMessage] = []

        if byte.check(bitmask: DandelionProtocolBitmask.ack.rawValue)
        {
            results.append(.ack)
        }

        if byte.check(bitmask: DandelionProtocolBitmask.write.rawValue)
        {
            results.append(.write(payload))
        }

        if byte.check(bitmask: DandelionProtocolBitmask.close.rawValue)
        {
            results.append(.close)
        }

        return results
    }

    static public func encode(payload: Data? = nil, ack: Bool = false, close: Bool = false) -> Data
    {
        var command: UInt8 = 0

        if ack
        {
            command |= DandelionProtocolBitmask.ack.rawValue
        }

        if close
        {
            command |= DandelionProtocolBitmask.close.rawValue
        }

        if let payload = payload
        {
            command |= DandelionProtocolBitmask.write.rawValue
            var result = Data(array: [command])
            result.append(payload)

            return result
        }
        else
        {
            return Data(array: [command])
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

    public func readMessage() async throws -> [DandelionProtocolMessage]
    {
        let data = try await self.connection.readWithLengthPrefix(prefixSizeInBits: Self.lengthPrefix)
        guard let command = data.first else
        {
            throw DandelionProtocolError.chunkTooShort
        }

        let payload = data.dropFirst()

        return DandelionProtocolMessage.parseCommand(command, payload)
    }

    public func writeMessage(write: Data? = nil, ack: Bool = false, close: Bool = false) async throws
    {
        let message = DandelionProtocolMessage.encode(payload: write, ack: ack, close: close)
        try await self.connection.writeWithLengthPrefix(message, Self.lengthPrefix)
    }
}

public enum DandelionProtocolError: Error
{
    case chunkTooShort
}
