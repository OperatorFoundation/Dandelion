// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Dandelion",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Dandelion",
            targets: ["Dandelion"]),
        .library(
            name: "DandelionServer",
            targets: ["DandelionServer"]),
        .library(
            name: "DandelionClient",
            targets: ["DandelionClient"]),
    ],
    
    dependencies: [
<<<<<<< HEAD
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.3"),
        .package(url: "https://github.com/apple/swift-log", from: "1.5.3"),
        .package(url: "https://github.com/OperatorFoundation/Keychain", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/KeychainCli", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Nametag", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/ShadowSwift", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/TransmissionAsync", branch: "main"),
=======
        .package(url: "git@github.com:apple/swift-argument-parser.git", from: "1.2.3"),
        .package(url: "git@github.com:apple/swift-log.git", from: "1.5.3"),
        .package(url: "git@github.com:OperatorFoundation/Keychain.git", branch: "main"),
        .package(url: "git@github.com:OperatorFoundation/KeychainCli.git", branch: "main"),
        .package(url: "git@github.com:OperatorFoundation/Nametag.git", branch: "main"),
        .package(url: "git@github.com:OperatorFoundation/ShadowSwift.git", branch: "main"),
        .package(url: "git@github.com:OperatorFoundation/Straw.git", branch: "main"),
        .package(url: "git@github.com:OperatorFoundation/TransmissionAsync.git", branch: "main"),
>>>>>>> 655f582d2aa65074f03c1aa871ce742b92a93442
    ],
    
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Dandelion",
            dependencies: [
                "KeychainCli",
                "Nametag",
<<<<<<< HEAD

=======
                "TransmissionAsync",
                "Straw",
>>>>>>> 655f582d2aa65074f03c1aa871ce742b92a93442
                .product(name: "TransmissionAsyncNametag", package: "Nametag"),
        ]),
        .target(
            name: "DandelionServer",
            dependencies: [
                "Dandelion",
                "Keychain",
                "TransmissionAsync",
                .product(name: "Logging", package: "swift-log"),
                .product(name: "TransmissionAsyncNametag", package: "Nametag"),
        ]),
        .target(
            name: "DandelionClient",
            dependencies: [
                "Dandelion",
                "Keychain",
                "ShadowSwift",
                .product(name: "Logging", package: "swift-log")
        ]),
        .executableTarget(
            name: "DandelionCLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ]),
        .testTarget(
            name: "DandelionTests",
            dependencies: [
                "Dandelion",
                "DandelionServer",
                "DandelionClient",
                "DandelionCLI",
                .product(name: "TransmissionNametag", package: "Nametag"),
                .product(name: "TransmissionAsyncNametag", package: "Nametag"),
        ]),
    ]
)
