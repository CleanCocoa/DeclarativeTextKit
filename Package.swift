// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DeclarativeTextKit",
    platforms: [.macOS(.v10_13)],
    products: [
        .library(
            name: "TextBuffer",
            targets: ["TextBuffer"]),
        .library(
            name: "DeclarativeTextKit",
            targets: ["DeclarativeTextKit"]),
        .library(
            name: "TextBufferTesting",
            targets: ["TextBufferTesting"]),
    ],
    targets: [
        .target(name: "TextBuffer"),
        .target(
            name: "TextBufferTesting",
            dependencies: ["TextBuffer"]),
        .testTarget(
            name: "TextBufferTests",
            dependencies: ["TextBuffer"]),
        .target(
            name: "DeclarativeTextKit",
            dependencies: ["TextBuffer"]),
        .testTarget(
            name: "DeclarativeTextKitTests",
            dependencies: ["TextBuffer", "DeclarativeTextKit", "TextBufferTesting"]),
    ]
)
