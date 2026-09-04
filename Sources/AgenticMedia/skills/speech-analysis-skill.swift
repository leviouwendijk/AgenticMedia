import Agentic

public extension AgenticMediaSkillProvider {
    static let speechAnalysis = AgentSkill(
        identifier: "speech-analysis",
        name: "Speech analysis",
        summary: "Choose the smallest useful speech capability and interpret speaker attribution conservatively.",
        body: """
        Choose speech tooling according to what the task actually needs.

        Workflow:
        1. Use `\(SpeechTranscribeTool.identifier.rawValue)` when the task only needs the spoken words.
        2. Use `\(SpeechAnalyzeTool.identifier.rawValue)` when speaker attribution, turn-taking, or who-said-what matters.
        3. Use `\(MediaInspectTool.identifier.rawValue)` first when the media asset, available tracks, or suitability of the source is uncertain.
        4. Do not routinely invoke both speech tools for the same purpose.
        5. Supply expectedSpeakerCount only when it is supported by the user or reliable evidence; do not guess it merely to force diarization.
        6. Treat speaker identifiers as anonymous inferred speaker clusters, not as real-world identities.
        7. Preserve unassigned segments and confidence information instead of overstating uncertain attribution.
        8. Prefer the bounded conversation result for ordinary reasoning. Do not request or manufacture diagnostic inference, embedding observations, or acoustic evidence unless a dedicated diagnostic workflow explicitly requires them.
        """,
        metadata: .init(
            domains: [],
            tools: .init(
                optional: [
                    .tool(MediaInspectTool.identifier),
                    .tool(SpeechTranscribeTool.identifier),
                    .tool(SpeechAnalyzeTool.identifier),
                ]
            ),
            tags: [
                "media",
                "speech",
                "transcription",
                "diarization",
            ],
            attributes: [
                "pack": "agentic-media",
                "kind": "workflow",
            ]
        )
    )
}
