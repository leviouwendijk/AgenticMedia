import Agentic
import AgenticIO
import Workspace
import Macros
import MediaAV

public extension Media.Tools {
    @Tool("media_inspect")
    struct Inspect: Tool {
        public typealias Input = MediaPathInput
        public typealias Output = MediaAssetInspection

        public static let purpose =
            "Inspect tracks, formats, timing, and native timecode metadata for a workspace media asset."

        public static let risk: ActionRisk = .observe

        public init() {}

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
            summary: "Inspect media metadata without modifying the asset.",
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
                "read_only_media_inspection",
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

        return try await MediaAssetInspector().inspect(
            authorized.absoluteURL
        )
    }
}
}
