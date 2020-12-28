// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Relay.swift",
    platforms: [
        .macOS(.v11),
        .iOS(.v14),
        .tvOS(.v14),
        .watchOS(.v7),
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
        .package(name: "SwiftSyntax", url: "https://github.com/apple/swift-syntax.git", .exact("0.50300.0")),
        .package(name: "SnapshotTesting", url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.8.0"),
        .package(name: "Nimble", url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "8.0.1")),
    ],
    targets: [
        .target(
            name: "Relay",
            dependencies: []),
        .testTarget(
            name: "RelayTests",
            dependencies: ["Relay", "RelayTestHelpers", "SnapshotTesting", "Nimble"],
            exclude: ["__Snapshots__"]),
        .target(
            name: "RelaySwiftUI",
            dependencies: ["Relay"]),
        .testTarget(
            name: "RelaySwiftUITests",
            dependencies: ["RelaySwiftUI", "RelayTestHelpers", "SnapshotTesting", "Nimble"],
            exclude: ["__Snapshots__"]),
        .target(
            name: "RelayTestHelpers",
            dependencies: ["Relay", "RelaySwiftUI", "SnapshotTesting"],
            exclude: ["StarWars/schema.graphql", "ToDo/schema.graphql"]),
        .target(
            name: "find-graphql-tags",
            dependencies: ["SwiftSyntax"]),
    ]
)
