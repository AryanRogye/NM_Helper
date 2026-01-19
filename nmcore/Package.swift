// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "nmcore",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "nmcore", targets: ["nmcore"])
    ],
    targets: [
        .target(
            name: "nmcore"
        )
    ]
)
