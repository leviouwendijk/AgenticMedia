import Agentic
import AgenticIO
import Workspace
import Macros
import Images

public extension Media.Tools {
    @Tool("image_discover")
    struct DiscoverImages: Tool {
        public typealias Input = MediaPathInput
        public typealias Output = ImageDiscoveryOutput

        public static let purpose =
            "Discover supported image sources under the raw directory of a workspace Images project."

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
            capability: .scan,
            toolName: Self.identifier.rawValue,
            type: .directory
        )

        return .init(
            tool: Self.definition.identifier,
            risk: Self.risk,
            summary: "Discover image sources without modifying the Images project.",
            access: .init(
                targets: [
                    authorized.presentationPath,
                ],
                roots: [
                    input.rootID.rawValue,
                ],
                capabilities: [
                    .scan,
                ]
            ),
            policyChecks: [
                "workspace_required",
                "workspace_path_authorized",
                "read_only_image_discovery",
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
            capability: .scan,
            toolName: Self.identifier.rawValue,
            type: .directory
        )

        let sources = try ImageDiscovery.sources(
            in: ImageProject(
                root: authorized.absoluteURL
            )
        )

        return ImageDiscoveryOutput(
            project: authorized.presentationPath,
            sources: sources.map { source in
                ImageSourceSummary(
                    path: source.relative.string,
                    format: source.url.pathExtension.lowercased()
                )
            }
        )
    }
}
}

public struct ImageDiscoveryOutput:
    Sendable,
    Codable,
    Hashable
{
    public let project: String
    public let sources: [ImageSourceSummary]

    public init(
        project: String,
        sources: [ImageSourceSummary]
    ) {
        self.project = project
        self.sources = sources
    }
}

public struct ImageSourceSummary:
    Sendable,
    Codable,
    Hashable
{
    public let path: String
    public let format: String

    public init(
        path: String,
        format: String
    ) {
        self.path = path
        self.format = format
    }
}
