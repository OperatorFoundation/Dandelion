//
//  NametagRouter.swift
//  
//
//  Created by Mafalda on 10/26/23.
//

import Foundation

import Chord
import KeychainTypes
import Straw
import TransmissionAsync
import TransmissionAsyncNametag

public actor NametagRouter
{
    public static let maxReadSize = 2048 // Could be tuned through testing in the future

    public let clientConnection: ClientConnection
    public let targetConnection: AsyncConnection

    let uuid = UUID()

    var cleaner: NametagRouterCleanup? = nil
    var serverPump: NametagPumpToServer? = nil
    var clientPump: NametagPumpToClient? = nil
    var connectionReaper: NametagConnectionReaper? = nil
    
    // MARK: Shared State
    let clientsForClientPump: AsyncQueue<ClientConnection> = AsyncQueue<ClientConnection>()
    let clientsForServerPump: AsyncQueue<ClientConnection> = AsyncQueue<ClientConnection>()

    let controller: DandelionRoutingController
    var clientConnectionCount = 1
    var state: NametagRouterState = .active
    
    // MARK: End Shared State
    
    public init(controller: DandelionRoutingController, transportConnection: ClientConnection, targetConnection: AsyncConnection) async
    {
        print("⚘ Initializing a NametagRouter.")
        self.controller = controller
        self.clientConnection = transportConnection
        self.targetConnection = targetConnection

        self.cleaner = NametagRouterCleanup(router: self)
        
        print("⚘ Enqueuing a transport connection in the clientsForClientPump.")
        await self.clientsForClientPump.enqueue(element: transportConnection)
        
        print("⚘ Enqueuing a transport connection in the clientsForServerPump.")
        await self.clientsForServerPump.enqueue(element: transportConnection)
        
        print("⚘ Creating an ACK channel.")
        let ackChannel = AsyncQueue<AckOrError>()
        
        print("⚘ Creating a client pump.")
        self.clientPump = NametagPumpToClient(router: self, clients: self.clientsForServerPump, ackChannel: ackChannel)
        
        print("⚘ Creating a server pump.")
        self.serverPump = NametagPumpToServer(router: self, clients: self.clientsForClientPump, ackChannel: ackChannel)
        
        print("⚘ NametagRouter initialization complete.")
    }
    
//    init(transportConnection: AsyncNametagServerConnection, router: NametagRouter) async
//    {
//        self.controller = router.controller
//        self.clientConnection = transportConnection
//        self.targetConnection = router.targetConnection
//        self.unAckedClientData = await router.unAckedClientData
//        self.state = await router.state
//
//        self.cleaner = NametagRouterCleanup(router: self)
//        self.serverPump = NametagPumpToServer(router: self)
//        self.clientPump = NametagPumpToClient(router: self)
//    }
    
    public func clientConnected(connection: ClientConnection) async throws
    {
        switch state 
        {
            case .closing:
                print("⚘ Client connected while in the router closing state, connections cannot be accepted. This is an error, closing the client connection.")
                self.state = .closing
                try await connection.connection.network.close()
                throw NametagRouterError.connectionWhileClosing
                
            case .paused:
                self.state = .active
                
                print("⚘ Client connected while in the paused state. Setting this router state to active.")
                await self.clientsForClientPump.enqueue(element: connection)
                print("⚘ Enqeued a connection with clientsForClientPump.")
                await self.clientsForServerPump.enqueue(element: connection)
                print("⚘ Enqeued a connection with clientsForServerPump.")
                
                self.connectionReaper = nil
                
            case .active:
                print("⚘ Client connected while in the active state. This is an error, closing the client connection and setting this router state to closing.")
                self.state = .closing
                try await connection.connection.network.close()
                throw NametagRouterError.connectionWhileActive
        }
    }
    
    public func clientClosed() async
    {
        print("⚘ NametagRouter: clientClosed() called.")
        switch state
        {
            case .closing:
                state = .closing
            case .paused:
                state = .paused
            case .active:
                state = .paused
//                self.connectionReaper = await NametagConnectionReaper(router: self)
        }
        
        guard let cleaner = cleaner else
        {
            print("⚘ Trying to cleanup but the cleaner is nil!")
            return
        }
        
        await cleaner.cleanup()
    }
    
    public func serverClosed() async
    {
        print("⚘ NametagRouter: serverClosed() called.")
        state = .closing
        
        guard let cleaner = cleaner else
        {
            print("⚘ Trying to cleanup but the cleaner is nil!")
            return
        }
        
        await cleaner.cleanup()
    }
    
}

extension NametagRouter: Equatable
{
    static public func == (lhs: NametagRouter, rhs: NametagRouter) -> Bool
    {
        return lhs.uuid == rhs.uuid
    }
}

public enum NametagRouterState
{
    case closing
    case paused
    case active
}

public enum NametagRouterError: Error
{
    case connectionWhileClosing
    case connectionWhileActive
    
    public var description: String
    {
        switch self 
        {
            case .connectionWhileClosing:
                return "⚘ ERROR: Currently closing new connections cannot be accepted."
            case .connectionWhileActive:
                return "⚘ ERROR: Received a new client connection while a client connection to this target is already active."
        }
    }
}
