// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "AgenticMedia",
    platforms: [
        .macOS(.v26),
    ],
    products: [
        .library(
            name: "AgenticMedia",
            targets: [
                "AgenticMedia",
            ]
        ),
        .library(
            name: "AgenticMediaApple",
            targets: [
                "AgenticMediaApple",
            ]
        ),
        .executable(
            name: "amtest",
            targets: [
                "AgenticMediaTestFlows",
            ]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/leviouwendijk/Agentic.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/AgenticExecution.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/AgenticWorkspace.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/AgenticIO.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Primitives.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Schema.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/SchemaMacros.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Path.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Media.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Timecode.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Images.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/AgenticRuntime.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/AgenticInterfaces.git",
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
            url: "https://github.com/leviouwendijk/TestFlows.git",
            branch: "master"
        ),
    ],
    targets: [
        .target(
            name: "AgenticMedia",
            dependencies: [
                .product(
                    name: "Agentic",
                    package: "Agentic"
                ),
                .product(
                    name: "AgenticExecution",
                    package: "AgenticExecution"
                ),
                .product(
                    name: "AgenticWorkspace",
                    package: "AgenticWorkspace"
                ),
                .product(
                    name: "AgenticIO",
                    package: "AgenticIO"
                ),
                .product(
                    name: "Primitives",
                    package: "Primitives"
                ),
                .product(
                    name: "Schema",
                    package: "Schema"
                ),
                .product(
                    name: "SchemaMacros",
                    package: "SchemaMacros"
                ),
                .product(
                    name: "Path",
                    package: "Path"
                ),
                .product(
                    name: "MediaAV",
                    package: "Media"
                ),
                .product(
                    name: "Timecode",
                    package: "Timecode"
                ),
                .product(
                    name: "Images",
                    package: "Images"
                ),
                .product(
                    name: "Transcribe",
                    package: "Transcribe"
                ),
                .product(
                    name: "SpeechAnalysis",
                    package: "Transcribe"
                ),
                .product(
                    name: "SpeechAnalysisContext",
                    package: "Transcribe"
                ),
            ]
        ),
        .target(
            name: "AgenticMediaApple",
            dependencies: [
                "AgenticMedia",
                .product(
                    name: "AgenticRuntime",
                    package: "AgenticRuntime"
                ),
                .product(
                    name: "AgenticInterfaces",
                    package: "AgenticInterfaces"
                ),
                .product(
                    name: "Capture",
                    package: "Capture"
                ),
                .product(
                    name: "Diarization",
                    package: "Transcribe"
                ),
                .product(
                    name: "TranscribeApple",
                    package: "Transcribe"
                ),
            ]
        ),
        .executableTarget(
            name: "AgenticMediaTestFlows",
            dependencies: [
                "AgenticMedia",
                "AgenticMediaApple",
                .product(
                    name: "AgenticRuntime",
                    package: "AgenticRuntime"
                ),
                .product(
                    name: "AgenticInterfaces",
                    package: "AgenticInterfaces"
                ),
                .product(
                    name: "Agentic",
                    package: "Agentic"
                ),
                .product(
                    name: "AgenticExecution",
                    package: "AgenticExecution"
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
