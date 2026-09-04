import Agentic

public extension AgenticMediaSkillProvider {
    static let ltcTimecodeWorkflow = AgentSkill(
        identifier: "ltc-timecode-workflow",
        name: "LTC timecode workflow",
        summary: "Inspect media, prove embedded LTC, remux deliberately, and verify the resulting media state.",
        body: """
        Use a staged LTC workflow instead of mutating media immediately.

        Workflow:
        1. Use `\(MediaInspectTool.identifier.rawValue)` when track layout and native metadata are not already known.
        2. Use `\(TimecodeLTCProbeTool.identifier.rawValue)` to detect and inspect LTC before proposing a remux.
        3. Only use `\(TimecodeLTCRemuxTool.identifier.rawValue)` after the source, destination, and detected LTC state are clear.
        4. Treat remux as a media mutation and preserve the normal Agentic review boundary.
        5. Inspect or otherwise verify the produced media after remux when the result matters to downstream work.
        6. Do not infer usable LTC merely from the existence of an audio track; rely on the deterministic probe result.
        """,
        metadata: .init(
            domains: [],
            tools: .init(
                optional: [
                    .tool(MediaInspectTool.identifier),
                    .tool(TimecodeLTCProbeTool.identifier),
                    .tool(TimecodeLTCRemuxTool.identifier),
                ]
            ),
            tags: [
                "media",
                "timecode",
                "ltc",
            ],
            attributes: [
                "pack": "agentic-media",
                "kind": "workflow",
            ]
        )
    )
}
