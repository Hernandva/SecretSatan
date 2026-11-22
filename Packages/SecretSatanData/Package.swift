// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SecretSatanData",
    platforms: [.iOS("18.0"), .macOS("15.0")],
    products: [
        .library(name: "SecretSatanData", targets: ["SecretSatanData"])
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.10.0")
    ],
    targets: [
        .target(
            name: "SecretSatanData",
            dependencies: [.product(name: "Alamofire", package: "Alamofire")]
        ),
        .testTarget(
            name: "SecretSatanDataTests",
            dependencies: ["SecretSatanData", .product(name: "Alamofire", package: "Alamofire")]
        )
    ],
    swiftLanguageModes: [.v6]
)
