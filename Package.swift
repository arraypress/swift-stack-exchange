// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StackExchange",
    platforms: [.macOS(.v14), .iOS(.v16)],
    products: [
        .library(name: "StackExchange", targets: ["StackExchange"]),
    ],
    targets: [
        .target(name: "StackExchange"),
        .testTarget(
            name: "StackExchangeTests",
            dependencies: ["StackExchange"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
