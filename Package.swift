// swift-tools-version:5.5

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
            exclude: ["../../WormholyDemo"],
            resources: [
                .process("Resources/ActionableTableViewCell.xib"),
                .process("Resources/Assets.xcassets"),
                .process("Resources/Flow.storyboard"),
                .process("Resources/RequestCell.xib"),
                .process("Resources/RequestTitleSectionView.xib"),
                .process("Resources/TextTableViewCell.xib"),
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
