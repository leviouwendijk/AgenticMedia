import Agentic
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
                    from: MediaToolProvider(
                        speech: runtime
                    )
                )

                try Expect.equal(
                    registry.count,
                    7,
                    "speech-enabled AgenticMedia registered tool count"
                )

                let expectedTools = [
                    Media.Tools.TranscribeSpeech.identifier.rawValue,
                    Media.Tools.AnalyzeSpeech.identifier.rawValue,
                    Media.Tools.CompressImages.identifier.rawValue,
                    Media.Tools.DiscoverImages.identifier.rawValue,
                    Media.Tools.Inspect.identifier.rawValue,
                    Media.Tools.ProbeLTC.identifier.rawValue,
                    Media.Tools.RemuxLTC.identifier.rawValue,
                ].sorted()

                let actualTools = registry.definitions
                    .map { $0.identifier.rawValue }
                    .sorted()

                try Expect.equal(
                    actualTools,
                    expectedTools,
                    "speech-enabled AgenticMedia registered tools match expected"
                )

                let missingSemanticSchemas = registry.inspect().tools
                    .filter { $0.semanticInputSchema == nil }
                    .map { $0.identifier.rawValue }
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