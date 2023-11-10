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
import TransmissionNametag

final class DandelionTests: XCTestCase 
{
#if os(macOS) || os(iOS)
    let logger: Logger = Logger()
#else
    let logger: Logger = Logger(label: "Dandelion Logger")
#endif
    
    func testConnectToDandelionServer() throws
    {
        
        // Get a shadow config
        let shadowConfigURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("ShadowClientConfig.json")
        let testKeychainURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".keychainTest")
        
        guard let shadowConfig = ShadowConfig.ShadowClientConfig(path: shadowConfigURL.path()) else
        {
            XCTFail()
            return
        }
        
//        // Make a Shadow connection
//        let shadowConnectionFactory = ShadowConnectionFactory(config: shadowConfig, logger: logger)
//        guard let shadowConnection = shadowConnectionFactory.connect(using: .tcp)
//        else
//        {
//            XCTFail()
//            return
//        }
        
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
            let nametagConnection = try NametagClientConnection(config: shadowConfig, keychain: keychain, logger: logger)
            let writeSuccess = nametagConnection.network.write(string: "Hello Dandelion.")
            
            XCTAssert(writeSuccess)
            
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
}
