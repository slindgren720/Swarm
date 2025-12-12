// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SwiftAgents",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .watchOS(.v26),
        .tvOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(name: "SwiftAgents", targets: ["SwiftAgents"]),
        .library(name: "SwiftAgentsUI", targets: ["SwiftAgentsUI"])
    ],
    targets: [
        .target(
            name: "SwiftAgents",
            dependencies: [],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "SwiftAgentsUI",
            dependencies: ["SwiftAgents"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SwiftAgentsTests",
            dependencies: ["SwiftAgents"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SwiftAgentsUITests",
            dependencies: ["SwiftAgentsUI"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ]
)
