import Agentic
import AgenticExecution
import AgenticIO
import AgenticWorkspace
import Images
import Primitives

public struct ImageDiscoverTool: TypedAgentTool {
    public typealias Input = AgenticMediaPathInput

    public static let identifier: AgentToolIdentifier =
        "image_discover"

    public static let description =
        "Discover supported image sources under the raw directory of a workspace Images project."

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
            capability: .scan,
            toolName: name,
            type: .directory
        )

        return .init(
            toolName: name,
            risk: risk,
            workspaceRoot: workspace?.rootURL.path,
            targetPaths: [
                authorized.presentationPath,
            ],
            summary: "Discover image sources without modifying the Images project.",
            sideEffects: [],
            rootIDs: [
                decoded.rootID.rawValue,
            ],
            capabilitiesRequired: [
                .scan,
            ],
            policyChecks: [
                "workspace_required",
                "workspace_path_authorized",
                "read_only_image_discovery",
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
            capability: .scan,
            toolName: name,
            type: .directory
        )

        let sources = try ImageDiscovery.sources(
            in: ImageProject(
                root: authorized.absoluteURL
            )
        )

        return try JSONToolBridge.encode(
            AgenticImageDiscoveryOutput(
                project: authorized.presentationPath,
                sources: sources.map { source in
                    AgenticImageSourceSummary(
                        path: source.relative.string,
                        format: source.url.pathExtension.lowercased()
                    )
                }
            )
        )
    }
}

private struct AgenticImageDiscoveryOutput:
    Sendable,
    Codable,
    Hashable
{
    let project: String
    let sources: [AgenticImageSourceSummary]
}

private struct AgenticImageSourceSummary:
    Sendable,
    Codable,
    Hashable
{
    let path: String
    let format: String
}
