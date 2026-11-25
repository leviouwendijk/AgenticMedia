import Agentic
import AgenticMedia
import AgenticMediaApple
import AgenticMediaCodecs
import AgenticRuntime
import Diarization
import Foundation
import SpeechAnalysis
import TestFlows
import Transcribe

private final class SpeakerCountRecorder:
    @unchecked Sendable
{
    private let lock = NSLock()
    private var recorded: [SpeakerCountBounds] = []

    func record(
        _ value: SpeakerCountBounds
    ) {
        lock.lock()
        recorded.append(
            value
        )
        lock.unlock()
    }

    var values: [SpeakerCountBounds] {
        lock.lock()
        defer {
            lock.unlock()
        }
        return recorded
    }
}

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

                let application = try Agentic.application(
                    "fixture.media.derived_speech"
                ) {
                    try install(
                        Media.self,
                        overrides: .init(replacing:
                            install(Media.Tools.TranscribeSpeech(runtime: runtime))
                            + install(Media.Tools.AnalyzeSpeech(runtime: runtime))
                        )
                    )
                }
                let registry = try InstalledCapabilities(application: application).tools

                let expectedTools = [
                    Media.Tools.TranscribeSpeech.identifier.rawValue,
                    Media.Tools.AnalyzeSpeech.identifier.rawValue,
                    Media.Tools.CompressImages.identifier.rawValue,
                    Media.Tools.ConvertAudio.identifier.rawValue,
                    Media.Tools.DiscoverImages.identifier.rawValue,
                    Media.Tools.Inspect.identifier.rawValue,
                    Media.Tools.ProbeLTC.identifier.rawValue,
                    Media.Tools.RemuxLTC.identifier.rawValue,
                ].sorted()

                try Expect.equal(
                    registry.count,
                    expectedTools.count,
                    "speech-enabled AgenticMedia registered tool count"
                )

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

            Step("speaker count reaches the runtime as bounds; automatic by default") {
                let received = SpeakerCountRecorder()
                let runtime = AgenticMediaSpeechRuntime(
                    transcribe: { _, localeIdentifier in
                        Transcription(
                            localeIdentifier: localeIdentifier,
                            segments: []
                        )
                    },
                    analyze: { _, localeIdentifier, speakerCount in
                        received.record(
                            speakerCount
                        )

                        return SpeechAnalysisResult(
                            transcription: Transcription(
                                localeIdentifier: localeIdentifier,
                                segments: []
                            )
                        )
                    }
                )
                let file = URL(
                    fileURLWithPath: "/tmp/session.wav"
                )

                _ = try await runtime.analyze(
                    file: file,
                    localeIdentifier: "nl-NL"
                )
                _ = try await runtime.analyze(
                    file: file,
                    localeIdentifier: "nl-NL",
                    speakerCount: .init(
                        maximum: 3
                    )
                )

                try Expect.equal(
                    received.values,
                    [
                        .automatic,
                        .init(
                            maximum: 3
                        ),
                    ],
                    "speech runtime forwards speaker-count bounds"
                )

                let input = try JSONDecoder().decode(
                    SpeechAnalyzeInput.self,
                    from: Data(
                        #"{"path":"session.wav","localeIdentifier":"nl-NL","maximumSpeakerCount":2}"#.utf8
                    )
                )

                try Expect.equal(
                    input.maximumSpeakerCount,
                    2,
                    "speech analyze input decodes maximumSpeakerCount"
                )

                try Expect.equal(
                    input.expectedSpeakerCount,
                    nil,
                    "speech analyze input leaves expectedSpeakerCount unset"
                )
            }
        }
    }
}