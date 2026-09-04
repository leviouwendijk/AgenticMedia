import Agentic
import AgenticExecution
import AgenticIO
import AgenticWorkspace
import Transcribe

public struct SpeechTranscribeTool: AgentTool {
    public typealias Input = SpeechTranscribeToolInput
    public typealias Output = Transcription

    public static let identifier: AgentToolIdentifier =
        "speech_transcribe"

    public static let description =
        "Transcribe spoken content from an authorized workspace media file without speaker diarization."

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
            summary: "Transcribe spoken content without modifying the media file.",
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
                "read_only_speech_transcription",
            ]
        )
    }

    public func call(
        _ input: Input,
        context: AgentToolExecutionContext
    ) async throws -> Output {
        let authorized = try FileToolAccess.authorize(
            workspace: context.workspace,
            rootID: input.rootID,
            path: input.path,
            capability: .read,
            toolName: name,
            type: .file
        )

        return try await runtime.transcribe(
            file: authorized.absoluteURL,
            localeIdentifier: input.localeIdentifier
        )
    }
}
