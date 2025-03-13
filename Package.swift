// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "Wormholy",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "Wormholy",
            targets: ["WormholySwift", "WormholyObjC"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "WormholySwift",
            dependencies: [],
            resources: [
                .process("Resources/Assets.xcassets")
            ]
        ),
        .target(
            name: "WormholyObjC",
            dependencies: [
                "WormholySwift"
            ]),
        .testTarget(
            name: "WormholyTests",
            dependencies: [
                "WormholySwift",
                "WormholyObjC"
            ]),
    ]
)
