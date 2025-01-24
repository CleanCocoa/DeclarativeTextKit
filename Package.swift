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
            name: "DeclarativeTextKitTesting",
            targets: ["DeclarativeTextKitTesting"]),
    ],
    targets: [
        .target(name: "TextBuffer"),
        .testTarget(
            name: "TextBufferTests",
            dependencies: ["TextBuffer"]),
        .target(
            name: "DeclarativeTextKit",
            dependencies: ["TextBuffer"]),
        .target(
            name: "DeclarativeTextKitTesting",
            dependencies: ["TextBuffer", "DeclarativeTextKit"]),
        .testTarget(
            name: "DeclarativeTextKitTests",
            dependencies: ["TextBuffer", "DeclarativeTextKit", "DeclarativeTextKitTesting"]),
    ]
)
