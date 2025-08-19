// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "xet-swift",
    products: [
        .library(
            name: "xet-swift",
            targets: ["xet-swift"]),
    ],
    targets: [
        .target(
            name: "CXet",
            linkerSettings: [
                .linkedLibrary("xet_sys"),
                .unsafeFlags(["-L../rust/target/release"])
            ]
        ),
        .target(
            name: "xet-swift",
            dependencies: ["CXet"]
        ),
        .testTarget(
            name: "xet-swiftTests",
            dependencies: ["xet-swift"]
        ),
    ]
)
