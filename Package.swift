// swift-tools-version: 6.2
import PackageDescription
import CompilerPluginSupport
import Foundation

let includeDemo = ProcessInfo.processInfo.environment["SWIFTAGENTS_INCLUDE_DEMO"] == "1"

// Default OFF. Set SWIFTAGENTS_HIVE_RUNTIME=1 to opt in.
let useHiveRuntime = ProcessInfo.processInfo.environment["SWIFTAGENTS_HIVE_RUNTIME"] == "1"

// Optional integration target (bridges SwiftAgents tools into HiveCore).
let includeHiveIntegration = ProcessInfo.processInfo.environment["SWIFTAGENTS_INCLUDE_HIVE"] == "1"

let packageRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent()

let localHiveEnv = ProcessInfo.processInfo.environment["SWIFTAGENTS_USE_LOCAL_HIVE"]
let useLocalHive: Bool
if localHiveEnv == "1" {
    useLocalHive = true
} else if localHiveEnv == "0" {
    useLocalHive = false
} else {
    let localHivePackage = packageRoot.appendingPathComponent("../Hive/libs/hive/Package.swift").path
    useLocalHive = FileManager.default.fileExists(atPath: localHivePackage)
}
let useLocalDependencies = ProcessInfo.processInfo.environment["SWIFTAGENTS_USE_LOCAL_DEPS"] == "1"

var packageProducts: [Product] = [
    .library(name: "SwiftAgents", targets: ["SwiftAgents"])
]

if includeHiveIntegration {
    packageProducts.append(.library(name: "HiveSwiftAgents", targets: ["HiveSwiftAgents"]))
}

if includeDemo {
    packageProducts.append(.executable(name: "SwiftAgentsDemo", targets: ["SwiftAgentsDemo"]))
}

var packageDependencies: [Package.Dependency] = [
    .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0")
]

if useLocalDependencies {
    // NOTE: Local development override.
    let waxCandidates = ["../Wax", "../rag/Wax"]
    let waxPath = waxCandidates.first(where: { candidate in
        FileManager.default.fileExists(atPath: packageRoot.appendingPathComponent(candidate).path)
    }) ?? "../Wax"

    packageDependencies.append(.package(path: waxPath))
    packageDependencies.append(.package(path: "../Conduit"))
} else {
    packageDependencies.append(
        .package(
            url: "https://github.com/christopherkarani/Wax.git",
            from: "0.1.3"
        )
    )
    packageDependencies.append(.package(url: "https://github.com/christopherkarani/Conduit", from: "0.3.1"))
}

if useHiveRuntime || includeHiveIntegration {
    if useLocalHive {
        packageDependencies.append(.package(path: "../Hive/libs/hive"))
    } else {
        packageDependencies.append(.package(url: "https://github.com/christopherkarani/Hive", from: "0.1.0"))
    }
}

var swiftAgentsDependencies: [Target.Dependency] = [
    "SwiftAgentsMacros",
    .product(name: "Logging", package: "swift-log"),
    .product(name: "Conduit", package: "Conduit"),
    .product(name: "Wax", package: "Wax")
]

if useHiveRuntime {
    swiftAgentsDependencies.append(
        .product(
            name: "HiveCore",
            package: "Hive",
            condition: .when(platforms: [.macOS, .iOS])
        )
    )
}

var swiftAgentsSwiftSettings: [SwiftSetting] = [
    .enableExperimentalFeature("StrictConcurrency")
]

if useHiveRuntime {
    swiftAgentsSwiftSettings.append(.define("SWIFTAGENTS_HIVE_RUNTIME"))
}

var packageTargets: [Target] = [
    // MARK: - Macro Implementation (Compiler Plugin)
    .macro(
        name: "SwiftAgentsMacros",
        dependencies: [
            .product(name: "SwiftSyntax", package: "swift-syntax"),
            .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            .product(name: "SwiftSyntaxBuilder", package: "swift-syntax")
        ],
        swiftSettings: [
            .enableExperimentalFeature("StrictConcurrency")
        ]
    ),

    // MARK: - Main Library
    .target(
        name: "SwiftAgents",
        dependencies: swiftAgentsDependencies,
        swiftSettings: swiftAgentsSwiftSettings
    ),

    // MARK: - Tests
    .testTarget(
        name: "SwiftAgentsTests",
        dependencies: ["SwiftAgents"],
        resources: [
            .copy("Guardrails/INTEGRATION_TEST_SUMMARY.md"),
            .copy("Guardrails/QUICK_REFERENCE.md")
        ],
        swiftSettings: [
            .enableExperimentalFeature("StrictConcurrency")
        ]
    ),
    .testTarget(
        name: "SwiftAgentsMacrosTests",
        dependencies: [
            "SwiftAgentsMacros",
            .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
        ],
        swiftSettings: [
            .enableExperimentalFeature("StrictConcurrency")
        ]
    )
]

if includeHiveIntegration {
    packageTargets.append(
        .target(
            name: "HiveSwiftAgents",
            dependencies: [
                "SwiftAgents",
                .product(name: "HiveCore", package: "Hive")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    )

    packageTargets.append(
        .testTarget(
            name: "HiveSwiftAgentsTests",
            dependencies: ["HiveSwiftAgents"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    )
}

if includeDemo {
    packageTargets.append(
        .executableTarget(
            name: "SwiftAgentsDemo",
            dependencies: ["SwiftAgents"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    )
}

let package = Package(
    name: "SwiftAgents",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1)
    ],
    products: packageProducts,
    dependencies: packageDependencies,
    targets: packageTargets
)
