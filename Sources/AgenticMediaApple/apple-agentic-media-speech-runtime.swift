import AgenticMedia
import Diarization
import TranscribeApple

public extension AgenticMediaSpeechRuntime {
    static var apple: Self {
        .init(
            transcribe: { file, localeIdentifier in
                let result = try await AppleTranscriber().transcribe(
                    file: file,
                    localeIdentifier: localeIdentifier
                )

                return result.transcription
            },
            analyze: { file, localeIdentifier, expectedSpeakerCount in
                let result = try await AppleSpeechAnalysisRunner().analyze(
                    file: file,
                    localeIdentifier: localeIdentifier,
                    diarizationConfiguration: .init(
                        expectedSpeakerCount: expectedSpeakerCount
                    )
                )

                return result.analysis
            }
        )
    }
}
