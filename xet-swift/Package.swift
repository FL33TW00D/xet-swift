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
        .binaryTarget(
            name: "XetSys",
            path: "./XetSys.xcframework"
        ),
        .target(
            name: "xet-swift",
            dependencies: ["XetSys"],
            linkerSettings: [
                .linkedFramework("SystemConfiguration"),
                .linkedFramework("CoreFoundation"),
            ]
        ),
        .testTarget(
            name: "xet-swiftTests",
            dependencies: ["xet-swift"]
        ),
    ]
)
