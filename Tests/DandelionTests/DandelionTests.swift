import XCTest
@testable import Dandelion

import Logging

import KeychainCli
import Nametag
import ShadowSwift
import TransmissionAsync
import TransmissionAsyncNametag

final class DandelionTests: XCTestCase 
{
    let logger: Logger = Logger(label: "Dandelion Logger")
    
    func testConnectToDandelionServer() async throws
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
        
        do
        {
            let nametagConnection = try await AsyncNametagClientConnection(config: shadowConfig, keychain: keychain, logger: logger)
            try await nametagConnection.network.write("Hello Dandelion.")
                        
            let readResult = try await nametagConnection.network.readSize( 15)
            XCTAssertNotNil(readResult)
            
            print("Read from the nametag connection: \(readResult.string)")
        }
        catch (let error)
        {
            print("Failed to create a nametag connection: \(error)")
            XCTFail()
            return
        }
    }
}
