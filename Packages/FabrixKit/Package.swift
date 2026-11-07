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
        .library(name: "FabrixTelemetry", targets: ["FabrixTelemetry"]),
    ],
    dependencies: [
        .package(url: "https://github.com/open-telemetry/opentelemetry-swift", from: "2.6.0"),
        .package(url: "https://github.com/open-telemetry/opentelemetry-swift-core", from: "2.6.0"),
    ],
    targets: [
        .target(name: "FabrixCore"),
        .target(
            name: "FabrixDesign",
            resources: [.copy("Resources/Fonts"), .process("Resources/Localizable.xcstrings")]
        ),
        .target(
            name: "FabrixFeatures",
            dependencies: ["FabrixCore", "FabrixDesign"],
            resources: [.process("Resources/Localizable.xcstrings")]
        ),
        .target(
            name: "FabrixTelemetry",
            dependencies: [
                "FabrixCore",
                .product(name: "OpenTelemetryApi", package: "opentelemetry-swift-core"),
                .product(name: "OpenTelemetrySdk", package: "opentelemetry-swift-core"),
                .product(name: "OpenTelemetryProtocolExporterHTTP", package: "opentelemetry-swift"),
                .product(name: "ResourceExtension", package: "opentelemetry-swift"),
                .product(name: "URLSessionInstrumentation", package: "opentelemetry-swift"),
            ]
        ),
        .testTarget(name: "FabrixCoreTests", dependencies: ["FabrixCore"]),
        .testTarget(name: "FabrixDesignTests", dependencies: ["FabrixDesign"]),
        .testTarget(name: "FabrixFeaturesTests", dependencies: ["FabrixFeatures"]),
        .testTarget(
            name: "FabrixTelemetryTests",
            dependencies: [
                "FabrixCore",
                "FabrixTelemetry",
                .product(name: "OpenTelemetryApi", package: "opentelemetry-swift-core"),
                .product(name: "OpenTelemetrySdk", package: "opentelemetry-swift-core"),
            ]
        ),
    ]
)
