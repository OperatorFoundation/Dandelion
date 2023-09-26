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
        .package(url: "git@github.com:apple/swift-argument-parser.git", from: "1.2.3"),
        .package(url: "git@github.com:OperatorFoundation/Keychain.git", branch: "main"),
        .package(url: "git@github.com:OperatorFoundation/Nametag.git", branch: "main"),
        .package(url: "git@github.com:OperatorFoundation/Transmission.git", branch: "main"),
    ],
    
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Dandelion",
            dependencies: [
        ]),
        .target(
            name: "DandelionServer",
            dependencies: [
                "Dandelion",
                "Keychain",
                "Transmission",
                .product(name: "TransmissionNametag", package: "Nametag"),
        ]),
        .target(
            name: "DandelionClient",
            dependencies: [
                "Dandelion",
                "Keychain",
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
                "DandelionCLI"
        ]),
    ]
)
