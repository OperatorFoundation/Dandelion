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
    let serverPort = 5771
    let keychainLabel = "Nametag"
    let testKeychainURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".keychainTest")
    let shadowConfigURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("ShadowClientConfig.json")
    let testLog = Logger(label: "Dandelion Logger")
    let message1 = "Hello"
    let message2 = " Dandelion."
    let completeMessage = "Hello Dandelion."
    
    func testShadowToDandelionServerConnectOnceWriteThenRead() async throws
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
            
            try await dandelionShadowConnection.write(completeMessage.data)
            print("• Wrote some data to the Dandelion Shadow connection.")
                        
            let readResult = try await dandelionShadowConnection.readSize(16)
            print("• Read from the Dandelion Shadow connection: \(readResult.string)")
            
            XCTAssertEqual(completeMessage, readResult.string)
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
            let dandelionShadowConnection = try await dandelionClient.connectShadowToDandelionServer(shadowConfigURL: shadowConfigURL)
            print("• Created a Dandelion Shadow connection.")
            
            try await dandelionShadowConnection.write(message2.data)
            print("• Wrote some data to the Dandelion Shadow connection.")
                        
            let readResult = try await dandelionShadowConnection.readSize(16)
            print("• Read from the Dandelion Shadow connection: \(readResult.string)")
            
            XCTAssertEqual(completeMessage, readResult.string)
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
            let dandelionShadowConnection = try await dandelionClient.connectShadowToDandelionServer(shadowConfigURL: shadowConfigURL)
            print("• Created a Dandelion Shadow connection.")
            
            try await dandelionShadowConnection.write(message1.data)
            print("• Wrote some data to the Dandelion Shadow connection.")
            
            try await dandelionShadowConnection.close()
            try await Task.sleep(for: .seconds(1))
            
            let dandelionShadowConnection2 = try await dandelionClient.connectShadowToDandelionServer(shadowConfigURL: shadowConfigURL)
            print("• Created a second Dandelion Shadow connection.")
            
            try await dandelionShadowConnection2.write(message2.data)
            print("• Wrote smore data to the Dandelion Shadow connection.")
                        
            let readResult = try await dandelionShadowConnection2.readSize(16)
            print("• Read from the Dandelion Shadow connection: \(readResult.string)")
            
            XCTAssertEqual(completeMessage, readResult.string)
        }
        catch (let error)
        {
            print("Failed to create a Dandelion Shadow connection: \(error)")
            XCTFail()
            return
        }
        
    }
    
    func testConnectOnceWriteThenRead() async throws
    {
        guard let dandelionClient = DandelionClient(keychainURL: testKeychainURL, keychainLabel: keychainLabel) else
        {
            XCTFail()
            return
        }
        
        do
        {
            let connection = try await dandelionClient.connectToDandelionServer(serverIP: serverIP, serverPort: serverPort)
            
            print("• Created an AsyncDandelionConnection connection.")
            
            try await connection.write(completeMessage.data)
            print("• Wrote some data to the AsyncDandelionConnection connection.")

            
            let readResult = try await connection.readSize(16)
            
            print("• Read from the AsyncDandelionConnection connection: \(readResult.string)")
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
            let connection = try await dandelionClient.connectToDandelionServer(serverIP: serverIP, serverPort: serverPort)
            
            print("• Created an AsyncDandelionConnection connection.")
            
            try await connection.write(message1.data)
            print("• Wrote some data to the AsyncDandelionConnection connection.")

            
            try await connection.close()
            try await Task.sleep(for: .seconds(10))
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
            let connection = try await dandelionClient.connectToDandelionServer(serverIP: serverIP, serverPort: serverPort)
            
            print("• Created an AsyncDandelionConnection connection.")
            
            try await connection.write(message2.data)
            print("• Wrote some data to the AsyncDandelionConnection connection.")
            
            let readResult = try await connection.readSize(16)
            
            print("• Read from the AsyncDandelionConnection connection: \(readResult.string)")
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
            let connection = try await dandelionClient.connectToDandelionServer(serverIP: serverIP, serverPort: serverPort)
            
            print("• Created a AsyncDandelionConnection connection.")
            try await connection.write(message1.data)
            print("• Wrote some data to the AsyncDandelionConnection connection.")

            try await connection.close()
            try await Task.sleep(for: .seconds(1))

            // Second connection
            let connection2 = try await dandelionClient.connectToDandelionServer(serverIP: serverIP, serverPort: serverPort)
            print("• Created a 2nd AsyncDandelionConnection connection.")
            
            try await connection2.write(message2.data)
            print("• Wrote some data to the AsyncDandelionConnection connection.")

            let readResult = try await connection2.readSize(16)
            print("Read from the AsyncDandelionConnection connection: \(readResult.string)")
            
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
