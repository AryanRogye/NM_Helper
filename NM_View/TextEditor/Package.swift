// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TextEditor",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "TextEditor",
            targets: ["TextEditor"]
        ),
    ],
    dependencies: [
        .package(name: "LocalShortcuts", path: "../LocalShortcuts")
    ],
    targets: [
        .target(
            name: "TextEditor",
            dependencies: [
                .product(name: "LocalShortcuts", package: "LocalShortcuts"),
            ]
        ),
        .testTarget(
            name: "TextEditorTests",
            dependencies: [
                "TextEditor"
            ]
        ),
    ],
    swiftLanguageModes: [
        .v6
    ],
)
