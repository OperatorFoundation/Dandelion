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
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.3"),
        .package(url: "https://github.com/apple/swift-log", from: "1.5.3"),
        .package(url: "https://github.com/OperatorFoundation/Keychain", branch: "release"),
        .package(url: "https://github.com/OperatorFoundation/KeychainCli", branch: "release"),
        .package(url: "https://github.com/OperatorFoundation/Nametag", branch: "release"),
        .package(url: "https://github.com/OperatorFoundation/ShadowSwift", branch: "release"),
        .package(url: "https://github.com/OperatorFoundation/Straw", branch: "release"),
        .package(url: "https://github.com/OperatorFoundation/TransmissionAsync", branch: "release"),
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
                .product(name: "TransmissionAsyncNametag", package: "Nametag"),
        ]),
        .target(
            name: "DandelionServer",
            dependencies: [
                "Dandelion",
                "Keychain",
                "Straw",
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
                "Keychain",
                "KeychainCli",

                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "TransmissionNametag", package: "Nametag"),
                .product(name: "TransmissionAsyncNametag", package: "Nametag"),
        ]),
    ]
)
