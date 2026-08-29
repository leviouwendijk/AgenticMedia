import Agentic
import AgenticExecution
import AgenticIO
import AgenticWorkspace
import MediaAV
import Primitives

public struct MediaInspectTool: StaticSchemaAgentTool {
    public typealias Input = AgenticMediaPathInput

    public static let identifier: AgentToolIdentifier =
        "media_inspect"

    public static let description =
        "Inspect tracks, formats, timing, and native timecode metadata for a workspace media asset."

    public static let risk: ActionRisk = .observe


    public init() {}

    public func preflight(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> ToolPreflight {
        let decoded = try JSONToolBridge.decode(
            AgenticMediaPathInput.self,
            from: input
        )

        let authorized = try FileToolAccess.authorize(
            workspace: workspace,
            rootID: decoded.rootID,
            path: decoded.path,
            capability: .read,
            toolName: name,
            type: .file
        )

        return .init(
            toolName: name,
            risk: risk,
            workspaceRoot: workspace?.rootURL.path,
            targetPaths: [
                authorized.presentationPath,
            ],
            summary: "Inspect media metadata without modifying the asset.",
            sideEffects: [],
            rootIDs: [
                decoded.rootID.rawValue,
            ],
            capabilitiesRequired: [
                .read,
            ],
            policyChecks: [
                "workspace_required",
                "workspace_path_authorized",
                "read_only_media_inspection",
            ]
        )
    }

    public func call(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> JSONValue {
        let decoded = try JSONToolBridge.decode(
            AgenticMediaPathInput.self,
            from: input
        )

        let authorized = try FileToolAccess.authorize(
            workspace: workspace,
            rootID: decoded.rootID,
            path: decoded.path,
            capability: .read,
            toolName: name,
            type: .file
        )

        let inspection = try await MediaAssetInspector().inspect(
            authorized.absoluteURL
        )

        return try JSONToolBridge.encode(
            inspection
        )
    }
}
