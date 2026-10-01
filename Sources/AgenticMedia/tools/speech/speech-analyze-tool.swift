import Agentic
import AgenticExecution
import AgenticIO
import Workspace
import Macros
import Foundation
import SpeechAnalysisContext

public extension Media.Tools {
    @Tool("speech_analyze")
    struct AnalyzeSpeech: Tool {
        public typealias Input = SpeechAnalyzeInput
        public typealias Output = SpeechAnalysisContext

        public static let purpose =
            "Analyze an authorized workspace media file for transcription, diarization, and speaker attribution using a bounded conversation projection."

        public static let risk: ActionRisk = .observe

        public let runtime: AgenticMediaSpeechRuntime

        public init(
        runtime: AgenticMediaSpeechRuntime
    ) {
        self.runtime = runtime
    }

    public func preflight(
        _ input: Input,
        workspace: WorkspaceContext?
    ) async throws -> ToolPreflight {
        try validate(input)

        let authorized = try FileToolAccess.authorize(
            workspace: workspace,
            rootID: input.rootID,
            path: input.path,
            capability: .read,
            toolName: Self.identifier.rawValue,
            type: .file
        )

        return .init(
            tool: Self.definition.identifier,
            risk: Self.risk,
            summary: "Analyze speech and speaker attribution without modifying the media file.",
            access: .init(
                targets: [
                    authorized.presentationPath,
                ],
                roots: [
                    input.rootID.rawValue,
                ],
                capabilities: [
                    .read,
                ]
            ),
            policyChecks: [
                "workspace_required",
                "workspace_path_authorized",
                "read_only_speech_analysis",
                "conversation_projection_only",
            ]
        )
    }

    public func call(
        _ input: Input,
        workspace: WorkspaceContext?
    ) async throws -> Output {
        try validate(input)

        let authorized = try FileToolAccess.authorize(
            workspace: workspace,
            rootID: input.rootID,
            path: input.path,
            capability: .read,
            toolName: Self.identifier.rawValue,
            type: .file
        )

        let analysis = try await runtime.analyze(
            file: authorized.absoluteURL,
            localeIdentifier: input.localeIdentifier,
            expectedSpeakerCount: input.expectedSpeakerCount
        )

        return SpeechAnalysisContextProjector().project(
            analysis,
            detail: .conversation
        )
    }

    private func validate(
        _ input: SpeechAnalyzeInput
    ) throws {
        if let expectedSpeakerCount = input.expectedSpeakerCount,
           expectedSpeakerCount < 1
        {
            throw SpeechAnalyzeError.invalidExpectedSpeakerCount(
                expectedSpeakerCount
            )
        }
    }
}
}

private enum SpeechAnalyzeError:
    Error,
    Sendable,
    LocalizedError
{
    case invalidExpectedSpeakerCount(Int)

    var errorDescription: String? {
        switch self {
        case .invalidExpectedSpeakerCount(let count):
            return "Expected speaker count must be positive; received \(count)."
        }
    }
}
