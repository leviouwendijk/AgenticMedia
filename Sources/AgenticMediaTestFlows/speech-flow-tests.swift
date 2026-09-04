import AgenticExecution
import AgenticMedia
import AgenticMediaApple
import SpeechAnalysis
import TestFlows
import Transcribe

extension AgenticMediaFlowSuite {
    static var speechToolSurfaceFlow: TestFlow {
        TestFlow(
            "agentic-media-speech-tool-surface",
            tags: [
                "agentic-media",
                "speech",
                "tools",
                "registration",
            ]
        ) {
            Step("register optional speech capability tool set") {
                _ = AgenticMediaSpeechRuntime.apple

                let runtime = AgenticMediaSpeechRuntime(
                    transcribe: { _, localeIdentifier in
                        Transcription(
                            localeIdentifier: localeIdentifier,
                            segments: []
                        )
                    },
                    analyze: { _, localeIdentifier, _ in
                        SpeechAnalysisResult(
                            transcription: Transcription(
                                localeIdentifier: localeIdentifier,
                                segments: []
                            )
                        )
                    }
                )

                var registry = ToolRegistry()

                try registry.register(
                    AgenticMediaToolSet(
                        speech: runtime
                    )
                )

                try Expect.equal(
                    registry.count,
                    7,
                    "speech-enabled AgenticMedia registered tool count"
                )

                let names = registry.definitions
                    .map(\.name)
                    .sorted()

                try Expect.true(
                    names.contains(
                        SpeechTranscribeTool.identifier.rawValue
                    ),
                    "AgenticMedia registers speech_transcribe"
                )

                try Expect.true(
                    names.contains(
                        SpeechAnalyzeTool.identifier.rawValue
                    ),
                    "AgenticMedia registers speech_analyze"
                )

                let missingSemanticSchemas = registry.capabilities
                    .filter {
                        $0.semanticInputSchema == nil
                    }
                    .map(\.definition.name)
                    .sorted()

                try Expect.equal(
                    missingSemanticSchemas,
                    [String](),
                    "speech-enabled AgenticMedia tools all expose semantic input schemas"
                )
            }
        }
    }
}
