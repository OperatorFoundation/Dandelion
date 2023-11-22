//
//  AsyncDandelionConnection.swift
//
//
//  Created by Dr. Brandon Wiley on 11/22/23.
//

import Foundation
import Logging

import Keychain
import Nametag
import Straw
import TransmissionAsync
import TransmissionAsyncNametag

public class AsyncDandelionConnection: AsyncChannelConnection<DandelionChannel>
{
    public convenience init(_ keychain: Keychain, _ host: String, _ port: Int, _ logger: Logger, verbose: Bool = false) async throws
    {
        let network = try await AsyncTcpSocketConnection(host, port, logger, verbose: verbose)

        try await self.init(keychain, network, logger, verbose: verbose)
    }

    public convenience init<T>(_ keychain: Keychain, _ connection: AsyncChannelConnection<T>, _ logger: Logger, verbose: Bool = false) async throws
    {
        guard let privateSigningKey = keychain.retrieveOrGeneratePrivateKey(label: "Nametag", type: KeyType.P256Signing) else
        {
            throw AsyncDandelionConnectionError.keychainError
        }

        let publicKey = privateSigningKey.publicKey

        print("Initializing nametag. Public key is \(publicKey.data!.count) bytes.")
        print("Nametag expected public key size is 65 bytes.") //Nametag.expectedPublicKeySize

        guard let _ = Nametag(keychain: keychain) else
        {
            throw AsyncDandelionConnectionError.nametagError
        }

        let nametagConnection = try await AsyncNametagClientConnection(connection, keychain, logger)

        self.init(nametagConnection, logger, verbose: verbose)
    }

    public init(_ connection: AsyncNametagClientConnection, _ logger: Logger, verbose: Bool = false)
    {
        let channel = DandelionChannel(connection, logger: logger, verbose: verbose)

        super.init(channel, logger, verbose: verbose)
    }
}

public class DandelionChannel: Channel
{
    public typealias R = DandelionReadable
    public typealias W = DandelionWritable

    public var readable: DandelionReadable
    {
        return DandelionReadable(self.connection, logger: self.logger, verbose: self.verbose)
    }

    public var writable: DandelionWritable
    {
        return DandelionWritable(self.connection, logger: self.logger, verbose: self.verbose)
    }

    let connection: AsyncNametagClientConnection
    let logger: Logger
    let verbose: Bool

    public init(_ connection: AsyncNametagClientConnection, logger: Logger, verbose: Bool)
    {
        self.connection = connection
        self.logger = logger
        self.verbose = verbose
    }

    public func close()
    {
        Task
        {
            try await self.connection.network.close()
        }
    }
}

public class DandelionReadable: Readable
{
    let connection: AsyncNametagClientConnection
    let dandelion: DandelionProtocol
    let logger: Logger
    let verbose: Bool
    let straw: UnsafeStraw

    public init(_ connection: AsyncNametagClientConnection, logger: Logger, verbose: Bool = false)
    {
        self.connection = connection
        self.logger = logger
        self.verbose = verbose

        self.straw = UnsafeStraw()
        self.dandelion = DandelionProtocol(connection.network)
    }

    public func read() async throws -> Data
    {
        if self.straw.count > 0
        {
            return try self.straw.read()
        }

        let messages = try await self.dandelion.readMessages()
        for message in messages
        {
            switch message
            {
                case .ack:
                    return Data() // FIXME

                case .write(let payload):
                    self.straw.write(payload)

                case .close:
                    try await self.connection.network.close()
            }
        }

        return try self.straw.read()
    }

    public func read(_ size: Int) async throws -> Data
    {
        if self.straw.count >= size
        {
            return try self.straw.read(size: size)
        }

        while self.straw.count < size
        {
            let messages = try await self.dandelion.readMessages()
            for message in messages
            {
                switch message
                {
                    case .ack:
                        return Data() // FIXME

                    case .write(let payload):
                        self.straw.write(payload)

                    case .close:
                        try await self.connection.network.close()
                        if self.straw.count >= size
                        {
                            return try self.straw.read(size: size)
                        }
                        else
                        {
                            throw AsyncDandelionConnectionError.connectionClosed
                        }
                }
            }

            await Task.yield()
        }

        return try self.straw.read(size: size)
    }

    public func readNonblocking(_ size: Int) async throws -> Data
    {
        throw AsyncDandelionConnectionError.unimplemented
    }
}

public class DandelionWritable: Writable
{
    let connection: AsyncNametagClientConnection
    let logger: Logger
    let verbose: Bool
    let straw: UnsafeStraw

    public init(_ connection: AsyncNametagClientConnection, logger: Logger, verbose: Bool = false)
    {
        self.connection = connection
        self.logger = logger
        self.verbose = verbose

        self.straw = UnsafeStraw()
    }

    public func write(_ data: Data) async throws
    {
        try await self.connection.network.writeWithLengthPrefix(data, DandelionProtocol.lengthPrefix)
    }
}

public enum AsyncDandelionConnectionError: Error
{
    case keychainError
    case nametagError
    case connectionClosed
    case unimplemented
}