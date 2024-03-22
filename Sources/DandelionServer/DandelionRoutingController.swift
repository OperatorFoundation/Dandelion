//
//  DandelionRoutingController.swift
//
//
//  Created by Mafalda on 10/26/23.
//

import Foundation
import Logging

import Chord
import Keychain
import TransmissionAsync
import TransmissionAsyncNametag


public class DandelionRoutingController
{
    var routes = [PublicKey: NametagRouter]()
    var connectionQueue = DispatchQueue(label: "NametagClientConnectionQueue")
    var logger: Logger
    
    public init(logger: Logger)
    {
        self.logger = logger
    }
    
    public func handleListener(dandelionListener: DandelionServer, targetHost: String, targetPort: Int)
    {
        print("⚘ RoutingController.handleListener()")
        
        while true
        {
            do
            {
                let transportConnection = try AsyncAwaitThrowingSynchronizer<AsyncNametagServerConnection>.sync
                {
                    let connection = try await dandelionListener.accept()
                    print("⚘ Accepted a connection.")
                    return connection
                }
                
                Task
                {
                    do
                    {
                        let clientConnection = ClientConnection(connection: transportConnection)
                        try await self.handleConnection(clientConnection: clientConnection, targetHost: targetHost, targetPort: targetPort)
                    }
                    catch (let clientConnectionError)
                    {
                        print("⚘ Received an error while accepting a client connection: \(clientConnectionError)")
                    }
                }

            }
            catch
            {
                print("⚘ RoutingController.handleListener: Failed to accept a new connection: \(error).")
                continue
            }
        }
    }
    
    func handleConnection(clientConnection: ClientConnection, targetHost: String, targetPort: Int) async throws
    {
        print("⚘ Dandelion listener accepted a transport connection.")
        
        if let existingRoute = routes[clientConnection.connection.publicKey]
        {
            print("⚘ Handling a connection from an existing route...")
            
            /// While that incoming connection is open, data is pumped between the incoming connection and the newly opened target application server connection.            
            try await existingRoute.clientConnected(connection: clientConnection)
            print("⚘ An existing route has been updated.")
        }
        else
        {
            /// If the public key of the incoming connection is not in the table,
            /// a new connection to the target application server is created.
            do
            {
                let targetConnection = try await AsyncTcpSocketConnection(targetHost, targetPort, logger)
                print("⚘ Dandelion target connection created.")
                
                /// While that incoming connection is open, data is pumped between the incoming connection and the newly opened target application server connection.
                let route = await NametagRouter(controller: self, transportConnection: clientConnection, targetConnection: targetConnection)
                print("⚘ A new route has been created.")
                
                // We don't already have this public key, save it to our routes
                routes[clientConnection.connection.publicKey] = route
            }
            catch (let error)
            {
                print("⚘ RoutingController.handleListener: Failed to connect to the target server. Error: \(error)")
                try await clientConnection.connection.network.close()
                return
            }
        }
    }
    
    func remove(route: NametagRouter) async
    {
        self.routes.removeValue(forKey: route.clientConnection.connection.publicKey)
    }
}
