// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "DeclarativeTextKit",
    platforms: [.macOS(.v10_13)],
    products: [
        .library(
            name: "DeclarativeTextKit",
            targets: ["DeclarativeTextKit"]),
    ],
    targets: [
        .target(
            name: "DeclarativeTextKit"),
        .testTarget(
            name: "DeclarativeTextKitTests",
            dependencies: ["DeclarativeTextKit"]),
    ]
)
