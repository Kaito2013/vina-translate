// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VinaTranslate",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "VinaTranslateCore",
            targets: ["VinaTranslateCore"]
        ),
        .executable(
            name: "VinaTranslate",
            targets: ["VinaTranslate"]
        )
    ],
    targets: [
        .target(
            name: "VinaTranslateCore"
        ),
        .executableTarget(
            name: "VinaTranslate",
            dependencies: ["VinaTranslateCore"]
        ),
        .testTarget(
            name: "VinaTranslateCoreTests",
            dependencies: ["VinaTranslateCore"]
        )
    ],
    swiftLanguageModes: [.v5]
)
