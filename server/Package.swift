// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MyMcpServer",
    platforms: [
        .macOS(.v15),
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.9.0")
    ],
    targets: [
        .executableTarget(
            name: "MyMcpServer",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk")
            ]
        ),
    ]
)
