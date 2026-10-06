import Agentic
import AgenticIO
import Workspace
import Macros
import Transcribe

public extension Media.Tools {
    @Tool("speech_transcribe")
    struct TranscribeSpeech: Tool {
        public typealias Input = SpeechTranscribeInput
        public typealias Output = Transcription

        public static let purpose =
            "Transcribe spoken content from an authorized workspace media file without speaker diarization."

        public static let risk: ActionRisk = .observe

        public let runtime: AgenticMediaSpeechRuntime

        public init(
        runtime: AgenticMediaSpeechRuntime
    ) {
        self.runtime = runtime
    }

    public func preflight(
        _ input: Input,
        in context: ToolContext
    ) async throws -> ToolPreflight {
        let authorized = try FileToolAccess.authorize(
            workspace: context.workspace,
            rootID: input.rootID,
            path: input.path,
            capability: .read,
            toolName: Self.identifier.rawValue,
            type: .file
        )

        return .init(
            tool: Self.definition.identifier,
            risk: Self.risk,
            summary: "Transcribe spoken content without modifying the media file.",
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
                "read_only_speech_transcription",
            ]
        )
    }

    public func call(
        _ input: Input,
        in context: ToolContext
    ) async throws -> Output {
        let authorized = try FileToolAccess.authorize(
            workspace: context.workspace,
            rootID: input.rootID,
            path: input.path,
            capability: .read,
            toolName: Self.identifier.rawValue,
            type: .file
        )

        return try await runtime.transcribe(
            file: authorized.absoluteURL,
            localeIdentifier: input.localeIdentifier
        )
    }
}
}
