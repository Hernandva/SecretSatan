// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SecretSatanUI",
    defaultLocalization: "en",
    platforms: [.iOS("18.0"), .macOS("15.0")],
    products: [
        .library(name: "SecretSatanUI", targets: ["SecretSatanUI"])
    ],
    targets: [
        .target(
            name: "SecretSatanUI",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "SecretSatanUITests",
            dependencies: ["SecretSatanUI"]
        )
    ],
    swiftLanguageModes: [.v6]
)
