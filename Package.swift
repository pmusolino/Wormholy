// swift-tools-version: 5.9
import PackageDescription

//let package = Package(
//    name: "Wormholy",
//    platforms: [
//        .iOS(.v15)
//    ],
//    products: [
//        .library(
//            name: "Wormholy",
//            targets: ["Wormholy"]
//        )
//    ],
//    targets: [
////        .target(
////            name: "WormholyObjC",
////            path: "Sources/Wormholy/ObjC",
////            publicHeadersPath: ".",
////            cSettings: [
////                .headerSearchPath(".")
////            ]
////        ),
////        .target(
////            name: "Wormholy",
////            dependencies: ["WormholyObjC"],
////            path: "Sources/Wormholy/Swift",
////            resources: [
////                .process("Support Files/Assets.xcassets")
////            ]
////        ),
////        .testTarget(
////            name: "WormholyTests",
////            dependencies: ["Wormholy"],
////            path: "Tests/WormholyTests"
////        )
//        .target(
//            name: "Wormholy",
//            dependencies: [],
//            path: "Sources",
//            publicHeadersPath: "include",
//            cSettings: [
//                .headerSearchPath("include")
//            ]
//        )
//    ]
//)

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
//                .process("UI"),
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
