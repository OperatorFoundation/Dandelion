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
    
    func testConnectShadowToDandelionServer() async throws
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
    
    func testConnectToDandelionServerTwiceAsync() async throws
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
            
            // FIXME: Sleep shouldn't be necessary
            try await Task.sleep(for: .seconds(5))

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
    
//    func testConnectToDandelionServerFirst() async throws
//    {
//        guard let keychain = Keychain(baseDirectory: testKeychainURL) else
//        {
//            XCTFail()
//            return
//        }
//        
//        guard let privateSigningKey = keychain.retrieveOrGeneratePrivateKey(label: "Nametag", type: KeyType.P256Signing) else
//        {
//            XCTFail()
//            return
//        }
//        
//        let publicKey = privateSigningKey.publicKey
//        
//        print("• Initializing nametag. Public key is \(publicKey.data!.count) bytes, expected public key size is 65 bytes.")
//        
//        guard let _ = Nametag(keychain: keychain) else
//        {
//            XCTFail()
//            return
//        }
//        
//        print("• Created a Nametag instance.")
//        
//        do
//        {
//            let connection = try await AsyncDandelionClientConnection(keychain, serverIP, serverPort, testLog, verbose: true)
//            
//            print("• Created an AsyncDandelionConnection connection.")
//            
//            try await connection.write(message1.data)
//            print("• Wrote some data to the AsyncDandelionConnection connection.")
//
//            
//            try await connection.close()
//            try await Task.sleep(for: .seconds(10))
//        }
//        catch (let error)
//        {
//            print("• Failed to create an AsyncDandelionConnection connection: \(error)")
//            XCTFail()
//            return
//        }
//    }
    
//    func testConnectToDandelionServerSecond() async throws
//    {
//        guard let keychain = Keychain(baseDirectory: testKeychainURL) else
//        {
//            XCTFail()
//            return
//        }
//        
//        guard let privateSigningKey = keychain.retrieveOrGeneratePrivateKey(label: "Nametag", type: KeyType.P256Signing) else
//        {
//            XCTFail()
//            return
//        }
//        
//        let publicKey = privateSigningKey.publicKey
//        
//        print("• Initializing nametag. Public key is \(publicKey.data!.count) bytes, expected public key size is 65 bytes.") //Nametag.expectedPublicKeySize
//        
//        guard let _ = Nametag(keychain: keychain) else
//        {
//            XCTFail()
//            return
//        }
//        
//        print("• created a Nametag instance.")
//        
//        do
//        {
//            let connection = try await AsyncDandelionClientConnection(keychain, serverIP, serverPort, testLog, verbose: true)
//            
//            print("• Created an AsyncDandelionConnection connection.")
//            
//            try await connection.write(message2.data)
//            print("• Wrote some data to the AsyncDandelionConnection connection.")
//            
//            let readResult = try await connection.readSize(16)
//            
//            print("• Read from the nametag connection: \(readResult.string)")
//            XCTAssertEqual(message1 + message2, readResult.string)
//        }
//        catch (let error)
//        {
//            print("• Failed to create a nametag connection: \(error)")
//            XCTFail()
//            return
//        }
//    }

}
