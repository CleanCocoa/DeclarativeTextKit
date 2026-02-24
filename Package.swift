// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "DeclarativeTextKit",
    products: [
        .library(
            name: "DeclarativeTextKit",
            targets: ["DeclarativeTextKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/CleanCocoa/TextBuffer", from: "0.2.0"),
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
