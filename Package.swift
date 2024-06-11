// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DeclarativeTextKit",
    platforms: [.macOS(.v10_13)],
    products: [
        .library(
            name: "DeclarativeTextKit",
            targets: ["DeclarativeTextKit"]),
        .library(
            name: "DeclarativeTextKitTesting",
            targets: ["DeclarativeTextKitTesting"]),
    ],
    targets: [
        .target(
            name: "DeclarativeTextKit"),
        .target(
            name: "DeclarativeTextKitTesting",
            dependencies: ["DeclarativeTextKit"]),
        .testTarget(
            name: "DeclarativeTextKitTests",
            dependencies: ["DeclarativeTextKit", "DeclarativeTextKitTesting"]),
    ]
)
