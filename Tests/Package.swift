// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "AgenticMediaTests",
    platforms: [
        .macOS(.v26),
    ],
    products: [
        .executable(
            name: "amtest",
            targets: [
                "AgenticMediaTestFlows",
            ]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-agentic/Agentic.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/swift-agentic/AgenticRuntime.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Primitives.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Path.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/swift-agentic/AgenticInterfaces.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Capture.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Transcribe.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/swift-tooling/TestFlows.git",
            branch: "master"
        ),
        .package(path: ".."),
    ],
    targets: [
        .executableTarget(
            name: "AgenticMediaTestFlows",
            dependencies: [
                .product(name: "AgenticMedia", package: "AgenticMedia"),
                .product(name: "AgenticMediaApple", package: "AgenticMedia"),
                .product(name: "AgenticMediaCodecs", package: "AgenticMedia"),
                .product(name: "Capture", package: "Capture"),
                .product(
                    name: "AgenticRuntime",
                    package: "AgenticRuntime"
                ),
                .product(
                    name: "AgenticInterfaces",
                    package: "AgenticInterfaces"
                ),
                .product(name: "AgenticPresentation", package: "AgenticInterfaces"),
                .product(
                    name: "Agentic",
                    package: "Agentic"
                ),
                .product(
                    name: "Path",
                    package: "Path"
                ),
                .product(
                    name: "Primitives",
                    package: "Primitives"
                ),
                .product(
                    name: "Transcribe",
                    package: "Transcribe"
                ),
                .product(
                    name: "Diarization",
                    package: "Transcribe"
                ),
                .product(
                    name: "SpeechAnalysis",
                    package: "Transcribe"
                ),
                .product(
                    name: "TestFlows",
                    package: "TestFlows"
                ),
            ]
        ),
    ],
    swiftLanguageModes: [
        .v6,
    ]
)

for target in package.targets {
    switch target.type {
    case .regular, .executable, .test, .macro:
        var settings = target.swiftSettings ?? []

        settings.append(
            .treatAllWarnings(as: .error)
        )

        settings.append(
            .unsafeFlags(
                [
                    "-continue-building-after-errors"
                ]
            )
        )

        target.swiftSettings = settings

    case .plugin, .system, .binary:
        break

    @unknown default:
        break
    }
}
