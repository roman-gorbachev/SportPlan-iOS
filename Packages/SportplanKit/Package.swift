// swift-tools-version: 6.2

import PackageDescription

let approachableConcurrency: [SwiftSetting] = [
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("MemberImportVisibility"),
]

let mainActorByDefault: [SwiftSetting] = approachableConcurrency + [
    .defaultIsolation(MainActor.self),
]

let package = Package(
    name: "SportplanKit",
    defaultLocalization: "ru",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "WorkoutActivity", targets: ["WorkoutActivity"]),
    ],
    targets: [
        .target(
            name: "Domain",
            swiftSettings: approachableConcurrency
        ),
        .target(
            name: "DesignSystem",
            resources: [.copy("Resources/Fonts")],
            swiftSettings: mainActorByDefault
        ),
        .target(
            name: "WorkoutActivity",
            swiftSettings: approachableConcurrency
        ),
        .testTarget(
            name: "DomainTests",
            dependencies: ["Domain"],
            swiftSettings: approachableConcurrency
        ),
        .testTarget(
            name: "WorkoutActivityTests",
            dependencies: ["WorkoutActivity"],
            swiftSettings: approachableConcurrency
        ),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: ["DesignSystem"],
            swiftSettings: mainActorByDefault
        ),
    ]
)
