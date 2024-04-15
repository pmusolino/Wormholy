// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Wormholy",
    platforms:[
        .iOS(.v11)
    ],
    products: [
         .library(
             name: "Wormholy",
             targets: ["Wormholy"]
         ),
    ],
    targets: [
        .target(
            name: "_WormholySwift",
            path: "Sources",
            exclude: [
                "Objc",
                "spm",
                "module.modulemap"
            ],
            resources: [
                .copy("Models/Postman/Postman_demo_collection.json"),
                .process("Support Files/Assets.xcassets"),
                .copy("UI/Cells/ActionableTableViewCell.xib"),
                .copy("UI/Cells/RequestCell.xib"),
                .copy("UI/Cells/TextTableViewCell.xib"),
                .copy("UI/Sections/RequestTitleSectionView.xib"),
                .copy("UI/Flow.storyboard"),
            ],
            cSettings: [
                .define("SWIFT_PACKAGE")
            ]
        ),

        .target(
            name: "_WormholyObjC",
            dependencies: [
                "_WormholySwift"
            ],
            path: "Sources/Objc",
            cSettings: [
                .define("SWIFT_PACKAGE")
            ]
        ),

        .target(
            name: "Wormholy",
            dependencies: [
                "_WormholySwift",
                "_WormholyObjC"
            ],
            path: "Sources/spm/AggregatedModule",
            cSettings: [
                .define("SWIFT_PACKAGE")
            ]
        ),
    ]
)
