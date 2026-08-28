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
            ]
        ),
        .executableTarget(
            name: "AgenticMediaTestFlows",
            dependencies: [
                "AgenticMedia",
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
