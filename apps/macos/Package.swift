// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Kaiwu",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Kaiwu", targets: ["KaiwuApp"]),
        .executable(name: "repository-check", targets: ["RepositoryChecks"]),
        .library(name: "KaiwuCore", targets: ["KaiwuCore"]),
        .library(name: "KaiwuUI", targets: ["KaiwuUI"]),
        .library(name: "ArchiveFeature", targets: ["ArchiveFeature"]),
        .library(name: "NetworkFeature", targets: ["NetworkFeature"]),
        .library(name: "TerminalFeature", targets: ["TerminalFeature"]),
        .library(name: "ProxyFeature", targets: ["ProxyFeature"]),
        .library(name: "CloudServices", targets: ["CloudServices"]),
    ],
    targets: [
        .target(name: "KaiwuCore", exclude: ["README.md"]),
        .target(name: "KaiwuUI", dependencies: ["KaiwuCore"], exclude: ["README.md"]),
        .target(name: "ArchiveFeature", dependencies: ["KaiwuCore", "KaiwuUI"], exclude: ["README.md"]),
        .target(name: "NetworkFeature", dependencies: ["KaiwuCore", "KaiwuUI"], exclude: ["README.md"]),
        .target(name: "TerminalFeature", dependencies: ["KaiwuCore", "KaiwuUI"], exclude: ["README.md"]),
        .target(name: "ProxyFeature", dependencies: ["KaiwuCore", "KaiwuUI"], exclude: ["README.md"]),
        .target(name: "CloudServices", exclude: ["README.md"]),
        .executableTarget(
            name: "KaiwuApp",
            dependencies: [
                "KaiwuCore", "KaiwuUI", "ArchiveFeature", "NetworkFeature",
                "TerminalFeature", "ProxyFeature", "CloudServices",
            ], exclude: ["README.md", "Resources"]),
        .testTarget(name: "KaiwuCoreTests", dependencies: ["KaiwuCore"]),
        .testTarget(name: "ArchiveFeatureTests", dependencies: ["ArchiveFeature", "KaiwuCore"]),
        .testTarget(name: "NetworkFeatureTests", dependencies: ["NetworkFeature", "KaiwuCore"]),
        .testTarget(name: "ProxyFeatureTests", dependencies: ["ProxyFeature"]),
        .testTarget(name: "CloudServicesTests", dependencies: ["CloudServices"]),
        .executableTarget(name: "RepositoryChecks", path: "Tools/RepositoryChecks", exclude: ["README.md"]),
        .testTarget(name: "RepositoryChecksTests", dependencies: ["RepositoryChecks"]),
    ],
    swiftLanguageModes: [.v6]
)
