import XCTest
@testable import Dandelion

#if os(macOS) || os(iOS)
import os.log
#else
import Logging
#endif

import KeychainCli
import Nametag
import ShadowSwift
import Transmission
import TransmissionAsync
import TransmissionNametag

final class DandelionTests: XCTestCase 
{
//    let logger: Logger = Logger(label: "Dandelion Logger")
    
    func testConnectShadowToDandelionServer() async throws
    {
        let message = "Hello Dandelion."
        
        // Get a shadow config
        let shadowConfigURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("ShadowClientConfig.json")
        let testKeychainURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".keychainTest")
        
        guard let shadowConfig = ShadowConfig.ShadowClientConfig(path: shadowConfigURL.path()) else
        {
            XCTFail()
            return
        }
        
        
        // Use Shadow connection to make a Nametag connection
        guard let keychain = Keychain(baseDirectory: testKeychainURL) else
        {
            XCTFail()
            return
        }
        
        guard let privateSigningKey = keychain.retrieveOrGeneratePrivateKey(label: "Nametag", type: KeyType.P256Signing) else
        {
            XCTFail()
            return
        }
        
        let publicKey = privateSigningKey.publicKey
        
        print("Initializing nametag. Public key is \(publicKey.data!.count) bytes.")
        print("Nametag expected public key size is 65 bytes.") //Nametag.expectedPublicKeySize
        
        guard let _ = Nametag(keychain: keychain) else
        {
            XCTFail()
            return
        }
        
        print("• created a Nametag instance.")
        
        do
        {
            var testLog = Logger(subsystem: "TestLogger", category: "main")
            let nametagConnection = try NametagClientConnection(config: shadowConfig, keychain: keychain, logger: testLog)
            
            print("• Created a nametag connection.")
            let wroteData = nametagConnection.network.write(string: message)
            
            guard wroteData else
            {
                XCTFail()
                return
            }
                        
            guard let readResult = nametagConnection.network.read(size: 16) else
            {
                XCTFail()
                return
            }
            
            print("Read from the nametag connection: \(readResult.string)")
            
            XCTAssertEqual(message, readResult.string)
        }
        catch (let error)
        {
            print("Failed to create a nametag connection: \(error)")
            XCTFail()
            return
        }
    }
    
    func testConnectToDandelionServer() async throws
    {
        let serverIP = "127.0.0.1"
        let serverPort = 5771
        let message = "Hello Dandelion."
        
        // Get a shadow config
        let testKeychainURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".keychainTest")
        
        
        // Use Shadow connection to make a Nametag connection
        guard let keychain = Keychain(baseDirectory: testKeychainURL) else
        {
            XCTFail()
            return
        }
        
        guard let privateSigningKey = keychain.retrieveOrGeneratePrivateKey(label: "Nametag", type: KeyType.P256Signing) else
        {
            XCTFail()
            return
        }
        
        let publicKey = privateSigningKey.publicKey
        
        print("Initializing nametag. Public key is \(publicKey.data!.count) bytes.")
        print("Nametag expected public key size is 65 bytes.") //Nametag.expectedPublicKeySize
        
        guard let _ = Nametag(keychain: keychain) else
        {
            XCTFail()
            return
        }
        
        print("• created a Nametag instance.")
        
        do
        {
            let testLog = Logger(subsystem: "TestLogger", category: "main")
            guard let connection = TCPConnection(host: serverIP, port: serverPort) else
            {
                XCTFail()
                return
            }
            
            let nametagConnection = try NametagClientConnection(connection, keychain, testLog)
            
            print("• Created a nametag connection.")
            let wroteData = nametagConnection.network.write(string: message)
            print("• Wrote some data to the nametag/Dandelion connection.")
            
            guard wroteData else
            {
                XCTFail()
                return
            }
                        
            guard let readResult = nametagConnection.network.read(size: 15) else
            {
                XCTFail()
                return
            }
            
            print("Read from the nametag connection: \(readResult.string)")
            XCTAssertEqual(message, readResult.string)
        }
        catch (let error)
        {
            print("Failed to create a nametag connection: \(error)")
            XCTFail()
            return
        }
    }
    
    func testConnectToDandelionServerTwice() async throws
    {
        let serverIP = "127.0.0.1"
        let serverPort = 5771
        let message1 = "Hello"
        let message2 = " Dandelion."
        
        // Get a shadow config
        let testKeychainURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".keychainTest")
        
        
        // Use Shadow connection to make a Nametag connection
        guard let keychain = Keychain(baseDirectory: testKeychainURL) else
        {
            XCTFail()
            return
        }
        
        guard let privateSigningKey = keychain.retrieveOrGeneratePrivateKey(label: "Nametag", type: KeyType.P256Signing) else
        {
            XCTFail()
            return
        }
        
        let publicKey = privateSigningKey.publicKey
        
        print("Initializing nametag. Public key is \(publicKey.data!.count) bytes.")
        print("Nametag expected public key size is 65 bytes.") //Nametag.expectedPublicKeySize
        
        guard let _ = Nametag(keychain: keychain) else
        {
            XCTFail()
            return
        }
        
        print("• created a Nametag instance.")
        
        do
        {
            let testLog = Logger(subsystem: "TestLogger", category: "main")
            
            guard let connection = TCPConnection(host: serverIP, port: serverPort) else
            {
                XCTFail()
                return
            }
            
            let nametagConnection = try NametagClientConnection(connection, keychain, testLog)
            
            print("• Created a nametag connection.")
            let wroteData = nametagConnection.network.write(string: message1)
            print("• Wrote some data to the nametag/Dandelion connection.")
            
            guard wroteData else
            {
                XCTFail()
                return
            }
            
            connection.close()
            
            try await Task.sleep(for: .seconds(1))
            
            // Second connection
            guard let connection2 = TCPConnection(host: serverIP, port: serverPort) else
            {
                XCTFail()
                return
            }
            
            print("• Created a 2nd TCP connection.")
            
            try await Task.sleep(for: .seconds(1))
            let nametagConnection2 = try NametagClientConnection(connection, keychain, testLog)
            print("• Created a 2nd nametag connection.")
            let wroteData2 = nametagConnection.network.write(string: message2)
            print("• Wrote some data to the nametag/Dandelion connection.")
            
            guard wroteData2 else
            {
                XCTFail()
                return
            }
                        
            guard let readResult = nametagConnection2.network.read(size: 16) else
            {
                XCTFail()
                return
            }
            
            print("Read from the nametag connection: \(readResult.string)")
            XCTAssertEqual(message1 + message2, readResult.string)
        }
        catch (let error)
        {
            print("• Failed to create a nametag connection: \(error)")
            XCTFail()
            return
        }
    }
}
