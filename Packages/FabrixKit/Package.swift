// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "FabrixKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "FabrixCore", targets: ["FabrixCore"]),
        .library(name: "FabrixDesign", targets: ["FabrixDesign"]),
        .library(name: "FabrixFeatures", targets: ["FabrixFeatures"]),
    ],
    targets: [
        .target(name: "FabrixCore"),
        .target(name: "FabrixDesign", resources: [.copy("Resources/Fonts")]),
        .target(name: "FabrixFeatures", dependencies: ["FabrixCore", "FabrixDesign"]),
        .testTarget(name: "FabrixCoreTests", dependencies: ["FabrixCore"]),
        .testTarget(name: "FabrixDesignTests", dependencies: ["FabrixDesign"]),
        .testTarget(name: "FabrixFeaturesTests", dependencies: ["FabrixFeatures"]),
    ]
)
