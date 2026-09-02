import Agentic
import AgenticExecution
import AgenticMedia
import Path
import Primitives
import TestFlows

enum AgenticMediaFlowSuite: TestFlowRegistry {
    static let title = "AgenticMedia"

    static let flows: [TestFlow] = [
        TestFlow(
            "apple-voice-input",
            tags: [
                "agentic-media",
                "apple",
                "voice",
            ]
        ) {
            try await AgenticMediaFlowSuite
                .runAppleVoiceInputSurface()
        },
        speechToolSurfaceFlow,
        speechSkillSurfaceFlow,
        TestFlow(
            "agentic-media-tool-surface",
            tags: [
                "agentic-media",
                "tools",
                "registration",
            ]
        ) {
            Step("register media capability tool set") {
                var registry = ToolRegistry()

                try registry.register(
                    AgenticMediaToolSet()
                )

                _ = try Expect.notNil(
                    registry.tool(
                        named: MediaInspectTool.identifier.rawValue
                    ),
                    "agentic-media.media-inspect"
                )

                _ = try Expect.notNil(
                    registry.tool(
                        named: TimecodeLTCProbeTool.identifier.rawValue
                    ),
                    "agentic-media.timecode-ltc-probe"
                )

                _ = try Expect.notNil(
                    registry.tool(
                        named: TimecodeLTCRemuxTool.identifier.rawValue
                    ),
                    "agentic-media.timecode-ltc-remux"
                )

                _ = try Expect.notNil(
                    registry.tool(
                        named: ImageDiscoverTool.identifier.rawValue
                    ),
                    "agentic-media.image-discover"
                )

                _ = try Expect.notNil(
                    registry.tool(
                        named: ImageCompressTool.identifier.rawValue
                    ),
                    "agentic-media.image-compress"
                )
            }
        },

        TestFlow(
            "agentic-media-path-input",
            tags: [
                "agentic-media",
                "input",
                "workspace",
            ]
        ) {
            Step("path input defaults to project root") {
                let decoded = try JSONToolBridge.decode(
                    AgenticMediaPathInput.self,
                    from: .object(
                        [
                            "path": .string(
                                "clip.mov"
                            ),
                        ]
                    )
                )

                try Expect.equal(
                    decoded.rootID,
                    .project,
                    "agentic-media.path.root-default"
                )

                try Expect.equal(
                    decoded.path,
                    "clip.mov",
                    "agentic-media.path.value"
                )
            }
        },

        TestFlow(
            "agentic-media-image-compress-input",
            tags: [
                "agentic-media",
                "images",
                "mutation",
                "input",
            ]
        ) {
            Step("image compression input uses bounded defaults") {
                let decoded = try JSONToolBridge.decode(
                    ImageCompressToolInput.self,
                    from: .object(
                        [
                            "path": .string(
                                "image-project"
                            ),
                        ]
                    )
                )

                try Expect.equal(
                    decoded.rootID,
                    .project,
                    "agentic-media.image-compress.root-default"
                )

                try Expect.equal(
                    decoded.path,
                    "image-project",
                    "agentic-media.image-compress.path"
                )

                try Expect.equal(
                    decoded.overwrite,
                    true,
                    "agentic-media.image-compress.overwrite-default"
                )

                try Expect.equal(
                    decoded.incremental,
                    true,
                    "agentic-media.image-compress.incremental-default"
                )
            }
        },

        TestFlow(
            "agentic-media-timecode-remux-input",
            tags: [
                "agentic-media",
                "timecode",
                "ltc",
                "mutation",
                "input",
            ]
        ) {
            Step("timecode remux input defaults to project root") {
                let decoded = try JSONToolBridge.decode(
                    TimecodeLTCRemuxToolInput.self,
                    from: .object(
                        [
                            "source": .string(
                                "source.mp4"
                            ),
                            "destination": .string(
                                "output.mov"
                            ),
                        ]
                    )
                )

                try Expect.equal(
                    decoded.rootID,
                    .project,
                    "agentic-media.timecode-remux.root-default"
                )

                try Expect.equal(
                    decoded.source,
                    "source.mp4",
                    "agentic-media.timecode-remux.source"
                )

                try Expect.equal(
                    decoded.destination,
                    "output.mov",
                    "agentic-media.timecode-remux.destination"
                )
            }
        },
    ]
}
