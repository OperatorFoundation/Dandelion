import XCTest
@testable import Dandelion

import Logging

import DandelionClient
import KeychainCli
import Nametag
import ShadowSwift
import Transmission
import TransmissionAsync
import TransmissionAsyncNametag
import TransmissionNametag

final class DandelionTests: XCTestCase 
{
    let serverIP = ""
    let serverPort = 1234
    let keychainLabel = "Nametag"
    let testKeychainURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".keychainTest")
    let shadowConfigURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("ShadowClientConfig.json")
    let shadowToDandelionConfigURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("ShadowToDandelionClientConfig3.json")
    let shadowToDandelionConfigURLSecond = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("ShadowToDandelionClientConfig4.json")
    let testLog = Logger(label: "Dandelion Logger")
    let message1 = "Hello"
    let message2 = " Dandelion."
    let completeMessage = "Hello Dandelion."
    
    
    // MARK: These tests are designed to be run against a Dandelion server that has an echo server as its target
    
    func testShadowToDandelionServerConnectOnceWriteThenRead() async throws
    {
        guard let dandelionClient = DandelionClient(keychainURL: testKeychainURL, keychainLabel: keychainLabel) else
        {
            XCTFail()
            return
        }
        
        do
        {
            // Connect
            let dandelionShadowConnection = try await dandelionClient.connectShadowToDandelionServer(shadowConfigURL: shadowConfigURL)
            print("• Created a Dandelion Shadow connection.")
            
            do 
            {
                // Write
                try await dandelionShadowConnection.write(completeMessage.data)
                print("• Wrote some data to the Dandelion Shadow connection.")
                                            
                do
                {
                    // Read
                    let readResult = try await dandelionShadowConnection.readSize(16)
                    print("• Read from the Dandelion Shadow connection: \(readResult.string)")
                    
                    // The client must always close the connection when finished.
                    try await dandelionShadowConnection.close()
                    try await Task.sleep(for: .seconds(5))
                    
                    // Check for echo
                    XCTAssertEqual(completeMessage, readResult.string)
                }
                catch (let readError)
                {
                    print("🔺 Failed to read from the Dandelion server: \(readError)")
                    XCTFail()
                }
            }
            catch (let writeError)
            {
                print("🔺 Failed to write to the Dandelion server: \(writeError)")
                XCTFail()
            }
        }
        catch (let error)
        {
            print("Failed to create a Dandelion Shadow connection: \(error)")
            XCTFail()
            return
        }
    }
    
    func testConnectShadowToToDandelionServerFirst() async throws
    {
        guard let dandelionClient = DandelionClient(keychainURL: testKeychainURL, keychainLabel: keychainLabel) else
        {
            XCTFail()
            return
        }
        
        do
        {
            let dandelionShadowConnection = try await dandelionClient.connectShadowToDandelionServer(shadowConfigURL: shadowConfigURL)
            print("• Created a Dandelion Shadow connection.")
            
            try await dandelionShadowConnection.write(message1.data)
            print("• Wrote some data to the Dandelion Shadow connection.")
            
            try await dandelionShadowConnection.close()
            try await Task.sleep(for: .seconds(1))
        }
        catch (let error)
        {
            print("Failed to create a Dandelion Shadow connection: \(error)")
            XCTFail()
            return
        }
    }
    
    func testConnectShadowToDandelionServerSecond() async throws
    {
        guard let dandelionClient = DandelionClient(keychainURL: testKeychainURL, keychainLabel: keychainLabel) else
        {
            XCTFail()
            return
        }
        
        do
        {
            // Connect
            let dandelionShadowConnection = try await dandelionClient.connectShadowToDandelionServer(shadowConfigURL: shadowConfigURL)
            print("• Created a Dandelion Shadow connection.")
            
            do
            {
                // Write the second message
                try await dandelionShadowConnection.write(message2.data)
                print("• Wrote some data to the Dandelion Shadow connection.")
                    
                // Read
                let readResult = try await dandelionShadowConnection.readSize(16)
                print("• Read from the Dandelion Shadow connection: \(readResult.string)")
                
                // The client must always close the connection when finished.
                try await dandelionShadowConnection.close()
                try await Task.sleep(for: .seconds(1))
                
                XCTAssertEqual(completeMessage, readResult.string)
            }
            catch
            {
                try await dandelionShadowConnection.close()
                print("🔺 Failed to read or write from the Dandelion server: \(error)")
                XCTFail()
            }
            
            
        }
        catch (let error)
        {
            print("Failed to create a Dandelion Shadow connection: \(error)")
            XCTFail()
            return
        }
    }
    
    func testConnectShadowToDandelionServerTwice() async throws
    {
        guard let dandelionClient = DandelionClient(keychainURL: testKeychainURL, keychainLabel: keychainLabel) else
        {
            XCTFail()
            return
        }
        
        do
        {
            // Connect
            let dandelionShadowConnection = try await dandelionClient.connectShadowToDandelionServer(shadowConfigURL: shadowToDandelionConfigURL)
            print("• Created a Dandelion Shadow connection.")
            
            // Write first message
            try await dandelionShadowConnection.write(message1.data)
            print("• Wrote some data to the Dandelion Shadow connection.")
            
            // Close
            try await dandelionShadowConnection.close()
            try await Task.sleep(for: .seconds(5))
            
            // Connect again
            let dandelionShadowConnection2 = try await dandelionClient.connectShadowToDandelionServer(shadowConfigURL: shadowToDandelionConfigURLSecond)
            print("• Created a second Dandelion Shadow connection.")
            
            // Write second message
            try await dandelionShadowConnection2.write(message2.data)
            print("• Wrote some more data to the Dandelion Shadow connection.")
              
            // Read
            let readResult = try await dandelionShadowConnection2.readSize(16)
            print("• Read from the Dandelion Shadow connection: \(readResult.string)")
            
            // Close the second connection
            try await dandelionShadowConnection2.close()
            
            // Check for correct echo
            XCTAssertEqual(completeMessage, readResult.string)
            try await Task.sleep(for: .seconds(5))
        }
        catch (let error)
        {
            print("Failed to create a Dandelion Shadow connection: \(error)")
            XCTFail()
            return
        }
        
    }
    
    // MARK: Dandelion only tests, the server IP and port should be set to the Dandelion server
    func testConnectOnceWriteThenRead() async throws
    {
        guard let dandelionClient = DandelionClient(keychainURL: testKeychainURL, keychainLabel: keychainLabel) else
        {
            XCTFail()
            return
        }
        
        do
        {
            // Connect
            let connection = try await dandelionClient.connectToDandelionServer(serverIP: serverIP, serverPort: serverPort)
            print("• Created an AsyncDandelionConnection connection.")
            
            // Write
            try await connection.write(completeMessage.data)
            print("• Wrote some data to the AsyncDandelionConnection connection.")
            
            // Read
            let readResult = try await connection.readSize(16)
            print("• Read from the AsyncDandelionConnection connection: \(readResult.string)")
            
            // Close the connection
            try await connection.close()
            
            // Check for echo
            XCTAssertEqual(completeMessage, readResult.string)
        }
        catch (let error)
        {
            print("• Failed to create a AsyncDandelionConnection connection: \(error)")
            XCTFail()
            return
        }
    }
    
    func testConnectToDandelionServerFirst() async throws
    {
        guard let dandelionClient = DandelionClient(keychainURL: testKeychainURL, keychainLabel: keychainLabel) else
        {
            XCTFail()
            return
        }
        
        do
        {
            // Connect
            let connection = try await dandelionClient.connectToDandelionServer(serverIP: serverIP, serverPort: serverPort)
            print("• Created an AsyncDandelionConnection connection.")
            
            // Write first half of the message
            try await connection.write(message1.data)
            print("• Wrote some data to the AsyncDandelionConnection connection.")

            // Close
            try await connection.close()
            try await Task.sleep(for: .seconds(1))
        }
        catch (let error)
        {
            print("• Failed to create an AsyncDandelionConnection connection: \(error)")
            XCTFail()
            return
        }
    }
    
    func testConnectToDandelionServerSecond() async throws
    {
        guard let dandelionClient = DandelionClient(keychainURL: testKeychainURL, keychainLabel: keychainLabel) else
        {
            XCTFail()
            return
        }
        
        do
        {
            // Connect
            let connection = try await dandelionClient.connectToDandelionServer(serverIP: serverIP, serverPort: serverPort)
            print("• Created an AsyncDandelionConnection connection.")
            
            // Write the second half of the message
            try await connection.write(message2.data)
            print("• Wrote some data to the AsyncDandelionConnection connection.")
            
            // Read
            let readResult = try await connection.readSize(16)
            print("• Read from the AsyncDandelionConnection connection: \(readResult.string)")
            
            // Close the connection
            try await connection.close()
            
            // Check for echo of the complete message
            XCTAssertEqual(message1 + message2, readResult.string)
        }
        catch (let error)
        {
            print("• Failed to create a Dandelion Server connection: \(error)")
            XCTFail()
            return
        }
    }
    
    func testConnectToDandelionServerTwice() async throws
    {
        guard let dandelionClient = DandelionClient(keychainURL: testKeychainURL, keychainLabel: keychainLabel) else
        {
            XCTFail()
            return
        }
        
        do
        {
            // First Connection
            let connection = try await dandelionClient.connectToDandelionServer(serverIP: serverIP, serverPort: serverPort)
            print("• Created a AsyncDandelionConnection connection.")
            
            // Write the first message
            try await connection.write(message1.data)
            print("• Wrote some data to the AsyncDandelionConnection connection.")
            
            // Close the first connection
            try await connection.close()
            try await Task.sleep(for: .seconds(1))

            // Second connection
            let connection2 = try await dandelionClient.connectToDandelionServer(serverIP: serverIP, serverPort: serverPort)
            print("• Created a 2nd AsyncDandelionConnection connection.")
            
            // Write the second message
            try await connection2.write(message2.data)
            print("• Wrote some data to the AsyncDandelionConnection connection.")
            
            // Read
            let readResult = try await connection2.readSize(16)
            print("Read from the AsyncDandelionConnection connection: \(readResult.string)")
            
            // Close the second connection
            try await connection2.close()
            
            // Check for echo of the complete message
            XCTAssertEqual(message1 + message2, readResult.string)
        }
        catch (let error)
        {
            print("• Failed to create a Dandelion Server connection: \(error)")
            XCTFail()
            return
        }
    }

}
