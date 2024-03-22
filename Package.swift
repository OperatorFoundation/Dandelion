// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Dandelion",
    platforms: [
        .macOS(.v14)
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
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.3"),
        .package(url: "https://github.com/apple/swift-log", from: "1.5.3"),
        .package(url: "https://github.com/OperatorFoundation/Chord.git", from: "0.1.5"),
        .package(url: "https://github.com/OperatorFoundation/Keychain", from: "1.0.3"),
        .package(url: "https://github.com/OperatorFoundation/KeychainCli", from: "1.0.2"),
        .package(url: "https://github.com/OperatorFoundation/Nametag", from: "0.1.3"),
        .package(url: "https://github.com/OperatorFoundation/ShadowSwift", from: "5.0.3"),
        .package(url: "https://github.com/OperatorFoundation/Straw", from: "1.0.4"),
        .package(url: "https://github.com/OperatorFoundation/TransmissionAsync", from: "0.1.5"),
        .package(url: "https://github.com/OperatorFoundation/TransmissionAsyncNametag", from: "1.0.1"),
    ],
    
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Dandelion",
            dependencies: [
                "KeychainCli",
                "Nametag",
                "TransmissionAsync",
                "Straw",
                .product(name: "TransmissionAsyncNametag", package: "TransmissionAsyncNametag"),
        ]),
        .target(
            name: "DandelionServer",
            dependencies: [
                "Chord",
                "Dandelion",
                "Keychain",
                "Straw",
                "TransmissionAsync",
                .product(name: "Logging", package: "swift-log"),
                .product(name: "TransmissionAsyncNametag", package: "TransmissionAsyncNametag"),
        ]),
        .target(
            name: "DandelionClient",
            dependencies: [
                "Dandelion",
                "Keychain",
                "ShadowSwift",
                .product(name: "Logging", package: "swift-log"),
                .product(name: "TransmissionNametag", package: "Nametag"),
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
                "Keychain",
                "KeychainCli",

                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "TransmissionNametag", package: "Nametag"),
                .product(name: "TransmissionAsyncNametag", package: "TransmissionAsyncNametag"),
        ]),
    ]
)
