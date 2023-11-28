//
//  AsyncDandelionClientConnection.swift
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

public class AsyncDandelionClientConnection: AsyncChannelConnection<DandelionClientChannel>
{
    public convenience init(_ keychain: any KeychainProtocol, _ host: String, _ port: Int, _ logger: Logger, verbose: Bool = false) async throws
    {
        let network = try await AsyncTcpSocketConnection(host, port, logger, verbose: verbose)

        try await self.init(keychain, network, logger, verbose: verbose)
    }

    public convenience init<T>(_ keychain: any KeychainProtocol, _ connection: AsyncChannelConnection<T>, _ logger: Logger, verbose: Bool = false) async throws
    {
        guard let privateSigningKey = keychain.retrieveOrGeneratePrivateKey(label: "Nametag", type: KeyType.P256Signing) else
        {
            throw AsyncDandelionClientConnectionError.keychainError
        }

        let publicKey = privateSigningKey.publicKey

        print("Initializing nametag. Public key is \(publicKey.data!.count) bytes.")
        print("Nametag expected public key size is 65 bytes.") //Nametag.expectedPublicKeySize

        guard let _ = Nametag(keychain: keychain) else
        {
            throw AsyncDandelionClientConnectionError.nametagError
        }

        let nametagConnection = try await AsyncNametagClientConnection(connection, keychain, logger)

        self.init(nametagConnection, logger, verbose: verbose)
    }

    public init(_ connection: AsyncNametagClientConnection, _ logger: Logger, verbose: Bool = false)
    {
        let channel = DandelionClientChannel(connection, logger: logger, verbose: verbose)

        super.init(channel, logger, verbose: verbose)
    }
}

public class DandelionClientChannel: Channel
{
    public typealias R = DandelionClientReadable
    public typealias W = DandelionClientWritable

    public var readable: DandelionClientReadable
    {
        return DandelionClientReadable(self.connection, logger: self.logger, verbose: self.verbose)
    }

    public var writable: DandelionClientWritable
    {
        return DandelionClientWritable(self.connection, logger: self.logger, verbose: self.verbose)
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

public class DandelionClientReadable: Readable
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
        
        let receivedData = try await connection.network.readWithLengthPrefix(prefixSizeInBits: DandelionProtocol.lengthPrefix)
        try await self.dandelion.ack()
        
        return receivedData
    }

    public func read(_ size: Int) async throws -> Data
    {
        if self.straw.count >= size
        {
            return try self.straw.read(size: size)
        }

        while self.straw.count < size
        {
            let message = try await connection.network.readWithLengthPrefix(prefixSizeInBits: DandelionProtocol.lengthPrefix)
            try await self.dandelion.ack()
            self.straw.write(message)

            await Task.yield()
        }

        return try self.straw.read(size: size)
    }

    public func readNonblocking(_ size: Int) async throws -> Data
    {
        throw AsyncDandelionClientConnectionError.unimplemented
    }
}

public class DandelionClientWritable: Writable
{
    let connection: AsyncNametagClientConnection
    let dandelion: DandelionProtocol
    let logger: Logger
    let verbose: Bool
    let straw: UnsafeStraw

    public init(_ connection: AsyncNametagClientConnection, logger: Logger, verbose: Bool = false)
    {
        self.connection = connection
        self.dandelion = DandelionProtocol(connection.network)
        self.logger = logger
        self.verbose = verbose

        self.straw = UnsafeStraw()
    }

    public func write(_ data: Data) async throws
    {
        try await self.dandelion.write(data: data)
    }
}

public enum AsyncDandelionClientConnectionError: Error
{
    case keychainError
    case nametagError
    case connectionClosed
    case unimplemented
}
