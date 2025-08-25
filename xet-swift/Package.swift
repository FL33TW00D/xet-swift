// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "XetSwift",
    products: [
        .library(
            name: "XetSwift",
            targets: ["XetSwift"]),
    ],
    targets: [
        .binaryTarget(
            name: "XetSys",
            path: "./XetSys.xcframework"
        ),
        .target(
            name: "XetSwift",
            dependencies: ["XetSys"],
            linkerSettings: [
                .linkedFramework("CoreFoundation", .when(platforms: [.macOS, .iOS])),
                .linkedFramework("SystemConfiguration", .when(platforms: [.macOS, .iOS]))
            ]
        ),
        .testTarget(
            name: "XetSwiftTests",
            dependencies: ["XetSwift"]
        ),
    ]
)
