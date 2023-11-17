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
            let wroteData = nametagConnection.network.write(string: "Hello Dandelion.")
            
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
            guard let connection = TCPConnection(host: "", port: 5771) else
            {
                XCTFail()
                return
            }
            
            let nametagConnection = try NametagClientConnection(connection, keychain, testLog)
            
            print("• Created a nametag connection.")
            let wroteData = nametagConnection.network.write(string: "Hello Dandelion.")
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
            
            guard let connection = TCPConnection(host: "", port: 5771) else
            {
                XCTFail()
                return
            }
            
            let nametagConnection = try NametagClientConnection(connection, keychain, testLog)
            
            print("• Created a nametag connection.")
            let wroteData = nametagConnection.network.write(string: "Hello")
            print("• Wrote some data to the nametag/Dandelion connection.")
            
            guard wroteData else
            {
                XCTFail()
                return
            }
            
//            connection.close()
            nametagConnection.network.close()
            
            // Second connection
            guard let connection2 = TCPConnection(host: "", port: 5771) else
            {
                XCTFail()
                return
            }
            
            print("• Created a 2nd TCP connection.")
            let nametagConnection2 = try NametagClientConnection(connection, keychain, testLog)
            print("• Created a 2nd nametag connection.")
            let wroteData2 = nametagConnection.network.write(string: " Dandelion.")
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
        }
        catch (let error)
        {
            print("• Failed to create a nametag connection: \(error)")
            XCTFail()
            return
        }
    }
}
