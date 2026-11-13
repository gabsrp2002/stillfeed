// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StillfeedCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "StillfeedCore",
            targets: ["StillfeedCore"]
        )
    ],
    targets: [
        .target(
            name: "StillfeedCore"
        ),
        .testTarget(
            name: "StillfeedCoreTests",
            dependencies: ["StillfeedCore"]
        )
    ]
)
