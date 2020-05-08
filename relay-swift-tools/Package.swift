// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "relay-swift-tools",
    dependencies: [
        .package(name: "SwiftSyntax", url: "https://github.com/apple/swift-syntax.git", .exact("0.50200.0")),
    ],
    targets: [
        .target(
            name: "find-graphql-tags",
            dependencies: ["SwiftSyntax"]),
        .target(
            name: "generate-type-defs",
            dependencies: ["SwiftSyntax", .product(name: "SwiftSyntaxBuilder", package: "SwiftSyntax")]),
    ]
)
