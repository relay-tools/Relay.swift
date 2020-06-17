// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Relay.swift",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(
            name: "Relay",
            targets: ["Relay"]),
        .library(
            name: "RelaySwiftUI",
            targets: ["RelaySwiftUI"]),
    ],
    dependencies: [
        .package(name: "SwiftSyntax", url: "https://github.com/apple/swift-syntax.git", .exact("0.50200.0")),
        .package(name: "SnapshotTesting", url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.8.0"),
    ],
    targets: [
        .target(
            name: "Relay",
            dependencies: []),
        .testTarget(
            name: "RelayTests",
            dependencies: ["Relay", "SnapshotTesting"]),
        .target(
            name: "RelaySwiftUI",
            dependencies: ["Relay"]),
        .target(
            name: "find-graphql-tags",
            dependencies: ["SwiftSyntax"]),
    ]
)
