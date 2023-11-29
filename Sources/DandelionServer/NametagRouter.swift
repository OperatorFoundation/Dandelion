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

actor NametagRouter
{
    static let maxReadSize = 2048 // Could be tuned through testing in the future
    
    public let clientConnection: AsyncNametagServerConnection

    let uuid = UUID()

    var cleaner: NametagRouterCleanup? = nil
    var serverPump: NametagPumpToServer? = nil
    var clientPump: NametagPumpToClient? = nil
    var connectionReaper: NametagConnectionReaper? = nil
    
    // MARK: Shared State
    let clientsForClientPump: AsyncQueue<AsyncNametagServerConnection> = AsyncQueue<AsyncNametagServerConnection>()
    let clientsForServerPump: AsyncQueue<AsyncNametagServerConnection> = AsyncQueue<AsyncNametagServerConnection>()

    let targetConnection: AsyncConnection
    let controller: DandelionRoutingController
    var clientConnectionCount = 1
    var state: NametagRouterState = .active
    var unAckedClientData: Data? = nil
    var unsentClientData = Straw()
    
    // MARK: End Shared State
    
    init(controller: DandelionRoutingController, transportConnection: AsyncNametagServerConnection, targetConnection: AsyncConnection) async
    {
        self.controller = controller
        self.clientConnection = transportConnection
        self.targetConnection = targetConnection

        self.cleaner = NametagRouterCleanup(router: self)

        await self.clientsForClientPump.enqueue(element: transportConnection)
        await self.clientsForServerPump.enqueue(element: transportConnection)

        self.serverPump = NametagPumpToServer(router: self, clients: self.clientsForClientPump)
        self.clientPump = NametagPumpToClient(router: self, clients: self.clientsForServerPump)
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
    
    func clientConnected(connection: AsyncNametagServerConnection) async throws
    {
        switch state 
        {
            case .closing:
                print("⚘ Client connected while in the router closing state, connections cannot be accepted. This is an error, closing the client connection.")
                self.state = .closing
                try await connection.network.close()
                throw NametagRouterError.connectionWhileClosing
                
            case .paused:
                print("⚘ Client connected while in the paused state. Setting this router state to active.")
                await self.clientsForClientPump.enqueue(element: connection)
                await self.clientsForServerPump.enqueue(element: connection)

                self.state = .active
                self.connectionReaper = nil
                
            case .active:
                print("⚘ Client connected while in the active state. This is an error, closing the client connection and setting this router state to closing.")
                self.state = .closing
                try await connection.network.close()
                throw NametagRouterError.connectionWhileActive
        }
    }
    
    func clientClosed() async
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
    
    func serverClosed() async
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
    
    func reconnect(clientConnection: AsyncNametagServerConnection) async
    {
        await self.clientsForClientPump.enqueue(element: clientConnection)
        await self.clientsForServerPump.enqueue(element: clientConnection)
    }
    
    func updateBuffer(data: Data?)
    {
        self.unAckedClientData = data
    }
}

extension NametagRouter: Equatable
{
    static func == (lhs: NametagRouter, rhs: NametagRouter) -> Bool
    {
        return lhs.uuid == rhs.uuid
    }
}

enum NametagRouterState
{
    case closing
    case paused
    case active
}

public enum NametagRouterError: Error
{
    case connectionWhileClosing
    case connectionWhileActive
    
    var description: String
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
