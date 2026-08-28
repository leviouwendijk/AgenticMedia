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
                        named: ImageDiscoverTool.identifier.rawValue
                    ),
                    "agentic-media.image-discover"
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
    ]
}
