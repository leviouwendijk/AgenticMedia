import Agentic
import AgenticExecution
import AgenticIO
import AgenticWorkspace
import Foundation
import SpeechAnalysisContext

public struct SpeechAnalyzeTool: AgentTool {
    public typealias Input = SpeechAnalyzeToolInput
    public typealias Output = SpeechAnalysisContext

    public static let identifier: AgentToolIdentifier =
        "speech_analyze"

    public static let description =
        "Analyze an authorized workspace media file for transcription, diarization, and speaker attribution using a bounded conversation projection."

    public static let risk: ActionRisk = .observe

    public var identifier: AgentToolIdentifier {
        Self.identifier
    }

    public var description: String {
        Self.description
    }

    public var risk: ActionRisk {
        Self.risk
    }

    public var execution: AgentToolExecutionContract {
        .targetable
    }

    public let runtime: AgenticMediaSpeechRuntime

    public init(
        runtime: AgenticMediaSpeechRuntime
    ) {
        self.runtime = runtime
    }

    public func preflight(
        _ input: Input,
        context: AgentToolExecutionContext
    ) async throws -> ToolPreflight {
        try validate(input)

        let authorized = try FileToolAccess.authorize(
            workspace: context.workspace,
            rootID: input.rootID,
            path: input.path,
            capability: .read,
            toolName: name,
            type: .file
        )

        return .init(
            toolName: name,
            risk: risk,
            workspaceRoot: context.workspace?.rootURL.path,
            targetPaths: [
                authorized.presentationPath,
            ],
            summary: "Analyze speech and speaker attribution without modifying the media file.",
            sideEffects: [],
            rootIDs: [
                input.rootID.rawValue,
            ],
            capabilitiesRequired: [
                .read,
            ],
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
        context: AgentToolExecutionContext
    ) async throws -> Output {
        try validate(input)

        let authorized = try FileToolAccess.authorize(
            workspace: context.workspace,
            rootID: input.rootID,
            path: input.path,
            capability: .read,
            toolName: name,
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
        _ input: SpeechAnalyzeToolInput
    ) throws {
        if let expectedSpeakerCount = input.expectedSpeakerCount,
           expectedSpeakerCount < 1
        {
            throw SpeechAnalyzeToolError.invalidExpectedSpeakerCount(
                expectedSpeakerCount
            )
        }
    }
}

private enum SpeechAnalyzeToolError:
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
