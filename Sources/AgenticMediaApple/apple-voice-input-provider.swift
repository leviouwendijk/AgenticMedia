import AgenticInterfaces
import AgenticRuntime
import Capture
import Foundation
import Speech
import TranscribeApple

public enum AppleVoiceInputError:
    Error,
    Sendable,
    LocalizedError
{
    case alreadyRecording
    case notRecording
    case emptyRecording
    case emptyTranscription

    public var errorDescription: String? {
        switch self {
        case .alreadyRecording:
            return "Voice input is already recording."

        case .notRecording:
            return "Voice input is not recording."

        case .emptyRecording:
            return "Voice input captured no audio."

        case .emptyTranscription:
            return "Voice transcription produced no text."
        }
    }
}

public actor AppleVoiceInputProvider:
    VoiceInputProvider
{
    public let localeIdentifier: String
    public let audio: CaptureAudioOptions?

    private var recording:
        CaptureAudioBufferRecordingSession?

    public init(
        localeIdentifier: String =
            Locale.current.identifier,
        audio: CaptureAudioOptions? = nil
    ) {
        self.localeIdentifier =
            localeIdentifier
        self.audio =
            audio
    }

    public func availability() async
        -> AgenticConversationVoice.Availability
    {
        guard SpeechTranscriber.isAvailable else {
            return .unavailable(
                "Speech transcription is unavailable on this Mac."
            )
        }

        let locale = Locale(
            identifier: localeIdentifier
        )

        guard await SpeechTranscriber
            .supportedLocale(
                equivalentTo: locale
            ) != nil
        else {
            return .unavailable(
                "Speech transcription does not support locale \(localeIdentifier)."
            )
        }

        return .available
    }

    public func start() async throws {
        guard recording == nil else {
            throw AppleVoiceInputError
                .alreadyRecording
        }

        let audio: CaptureAudioOptions

        if let configured = self.audio {
            audio = configured
        } else {
            audio = try CaptureAudioOptions()
        }

        let recording =
            CaptureAudioBufferRecordingSession(
                audio: audio
            )

        _ = try await recording.start()

        self.recording =
            recording
    }

    public func stop() async throws
        -> AgenticConversationTranscription
    {
        guard let recording else {
            throw AppleVoiceInputError
                .notRecording
        }

        self.recording =
            nil

        let captured =
            try recording.stop()

        guard !captured.isEmpty else {
            throw AppleVoiceInputError
                .emptyRecording
        }

        let result =
            try await AppleTranscriber()
                .transcribe(
                    buffers: captured.buffers,
                    localeIdentifier:
                        localeIdentifier
                )

        let text =
            result.transcription.text
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !text.isEmpty else {
            throw AppleVoiceInputError
                .emptyTranscription
        }

        return .init(
            text: text,
            localeIdentifier:
                result.transcription
                    .localeIdentifier
        )
    }

    public func cancel() async {
        recording?.cancel()
        recording = nil
    }
}
