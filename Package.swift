// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DeclarativeTextKit",
    platforms: [.macOS(.v10_13)],
    products: [
        .library(
            name: "DeclarativeTextKit",
            targets: ["DeclarativeTextKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/CleanCocoa/TextBuffer", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "DeclarativeTextKit",
            dependencies: [
                .product(name: "TextBuffer", package: "textbuffer"),
            ]),
        .testTarget(
            name: "DeclarativeTextKitTests",
            dependencies: [
                "DeclarativeTextKit",
                .product(name: "TextBuffer", package: "textbuffer"),
                .product(name: "TextBufferTesting", package: "textbuffer"),
            ]),
    ]
)
