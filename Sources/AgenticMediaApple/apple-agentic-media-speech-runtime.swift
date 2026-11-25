import AgenticMedia
import Diarization
import DiarizationFluidAudio
import TranscribeApple

public extension AgenticMediaSpeechRuntime {
    /// Apple transcription (speech model where the locale supports it,
    /// dictation otherwise) with FluidAudio's offline diarizer. FluidAudio
    /// downloads its models on first use.
    static var apple: Self {
        .init(
            transcribe: { file, localeIdentifier in
                let result = try await AppleTranscriber().transcribe(
                    file: file,
                    localeIdentifier: localeIdentifier,
                    model: await AppleTranscriber.preferredModel(
                        localeIdentifier: localeIdentifier
                    )
                )

                return result.transcription
            },
            analyze: { file, localeIdentifier, speakerCount in
                let result = try await AppleSpeechAnalysisRunner().analyze(
                    file: file,
                    localeIdentifier: localeIdentifier,
                    model: await AppleTranscriber.preferredModel(
                        localeIdentifier: localeIdentifier
                    ),
                    speakerDiarizer: .backend(
                        FluidAudioDiarizationBackend(),
                        speakerCount: speakerCount
                    )
                )

                return result.analysis
            }
        )
    }
}
