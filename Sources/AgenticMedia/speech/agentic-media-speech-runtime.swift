import Diarization
import Foundation
import SpeechAnalysis
import Transcribe

public struct AgenticMediaSpeechRuntime: Sendable {
    public typealias TranscribeHandler = @Sendable (
        URL,
        String
    ) async throws -> Transcription

    public typealias AnalyzeHandler = @Sendable (
        URL,
        String,
        SpeakerCountBounds
    ) async throws -> SpeechAnalysisResult

    private let transcribeHandler: TranscribeHandler
    private let analyzeHandler: AnalyzeHandler

    public init(
        transcribe: @escaping TranscribeHandler,
        analyze: @escaping AnalyzeHandler
    ) {
        self.transcribeHandler = transcribe
        self.analyzeHandler = analyze
    }

    public func transcribe(
        file: URL,
        localeIdentifier: String
    ) async throws -> Transcription {
        try await transcribeHandler(
            file,
            localeIdentifier
        )
    }

    /// `speakerCount` defaults to automatic: the diarizer decides how many
    /// speakers there are.
    public func analyze(
        file: URL,
        localeIdentifier: String,
        speakerCount: SpeakerCountBounds = .automatic
    ) async throws -> SpeechAnalysisResult {
        try await analyzeHandler(
            file,
            localeIdentifier,
            speakerCount
        )
    }
}
