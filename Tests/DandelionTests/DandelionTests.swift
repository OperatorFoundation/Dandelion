import XCTest
@testable import Dandelion

#if os(macOS) || os(iOS)
import os.log
import Logging
#else
import Logging
#endif

import KeychainCli
import Nametag
import ShadowSwift
import Transmission
import TransmissionAsync
import TransmissionAsyncNametag
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
            let testLog = Logger(subsystem: "TestLogger", category: "main")
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
    
    func testConnectToDandelionServerFirst() async throws
    {
        let serverIP = "127.0.0.1"
        let serverPort = 5771
        let message1 = "Hello"
        
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
            let testLog = Logger(label: "Dandelion Logger")
            let connection = try await AsyncDandelionClientConnection(keychain, serverIP, serverPort, testLog, verbose: true)
            
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
            let testLog = Logger(label: "Dandelion Logger")
            let connection = try await AsyncDandelionClientConnection(keychain, serverIP, serverPort, testLog, verbose: true)
            
            print("• Created an AsyncDandelionConnection connection.")
            
            try await connection.write(message2.data)
            print("• Wrote some data to the AsyncDandelionConnection connection.")

            
            let readResult = try await connection.readSize(16)
            
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

    func testConnectToDandelionServerTwiceAsync() async throws
    {
        let logger: Logging.Logger = Logging.Logger(label: "test")

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
//            let testLog = Logger(subsystem: "TestLogger", category: "main")

            let connection = try await AsyncTcpSocketConnection(serverIP, serverPort, logger)

            let nametagConnection = try await AsyncNametagClientConnection(connection, keychain, logger)

            print("• Created a nametag connection.")
            try await nametagConnection.network.writeString(string: message1)
            print("• Wrote some data to the nametag/Dandelion connection.")

            try await connection.close()

            try await Task.sleep(for: .seconds(1))

            // Second connection
            let connection2 = try await AsyncTcpSocketConnection(serverIP, serverPort, logger)

            print("• Created a 2nd TCP connection.")

            try await Task.sleep(for: .seconds(1))
            let nametagConnection2 = try await AsyncNametagClientConnection(connection, keychain, logger)
            print("• Created a 2nd nametag connection.")
            try await nametagConnection.network.writeString(string: message2)
            print("• Wrote some data to the nametag/Dandelion connection.")

            let readResult = try await nametagConnection2.network.readSize(16)

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
