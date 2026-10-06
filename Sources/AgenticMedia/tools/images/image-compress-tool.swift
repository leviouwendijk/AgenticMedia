import Agentic
import AgenticIO
import Workspace
import Foundation
import Images
import Path
import Schema
import Macros

/// Compress configured outputs in a workspace Images project.
@JSONSchema
public struct ImageCompressInput:
    Sendable,
    Codable,
    Hashable
{
    /// Workspace root identifier. Defaults to project.
    @Schema(required: false)
    public let rootID: PathAccessRootIdentifier

    /// Path to the Images project relative to the selected workspace root.
    public let path: String

    /// Allow configured outputs to replace existing files. Defaults to true.
    @Schema(required: false)
    public let overwrite: Bool

    /// Reuse Images incremental state when outputs are current. Defaults to true.
    @Schema(required: false)
    public let incremental: Bool

    public init(
        rootID: PathAccessRootIdentifier = .project,
        path: String,
        overwrite: Bool = true,
        incremental: Bool = true
    ) {
        self.rootID = rootID
        self.path = path
        self.overwrite = overwrite
        self.incremental = incremental
    }
}

private extension ImageCompressInput {
    enum CodingKeys: String, CodingKey {
        case rootID
        case path
        case overwrite
        case incremental
    }
}

public extension ImageCompressInput {
    init(
        from decoder: any Decoder
    ) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        rootID = try container.decodeIfPresent(
            PathAccessRootIdentifier.self,
            forKey: .rootID
        ) ?? .project

        path = try container.decode(
            String.self,
            forKey: .path
        )

        overwrite = try container.decodeIfPresent(
            Bool.self,
            forKey: .overwrite
        ) ?? true

        incremental = try container.decodeIfPresent(
            Bool.self,
            forKey: .incremental
        ) ?? true
    }
}

public extension Media.Tools {
    @Tool("image_compress")
    struct CompressImages: Tool {
        public typealias Input = ImageCompressInput
        public typealias Output = ImageCompressionReport

        public static let purpose =
            "Compress configured outputs in a workspace Images project without pruning unconfigured files."

        public static let risk: ActionRisk = .boundedmutate

        public init() {}

    public func preflight(
        _ input: Input,
        in context: ToolContext
    ) async throws -> ToolPreflight {
        let authorization = try authorizeOperation(
            input,
            workspace: context.workspace
        )

        return .init(
            tool: Self.definition.identifier,
            risk: Self.risk,
            summary: "Compress \(authorization.outputCount) configured image output(s) without pruning unconfigured files.",
            access: .init(
                targets: authorization.targetPaths,
                roots: [
                    input.rootID.rawValue,
                ],
                capabilities: [
                    .read,
                    .write,
                ]
            ),
            estimates: .init(
                write: .init(
                    count: authorization.targetPaths.count
                )
            ),
            sideEffects: [
                "write or replace configured compressed image outputs",
                "create parent directories required by configured outputs",
                "update \(ImageProjectDefaults.incrementalStateFilename)",
            ],
            policyChecks: [
                "workspace_required",
                "image_project_configuration_authorized",
                "image_sources_authorized",
                "configured_output_write_set_authorized",
                "incremental_state_authorized",
                "pruning_disabled",
            ]
        )
    }

    public func call(
        _ input: Input,
        in context: ToolContext
    ) async throws -> Output {
        let authorization = try authorizeOperation(
            input,
            workspace: context.workspace
        )

        return ImageCompression.compress(
            in: authorization.project,
            configuration: authorization.configuration,
            options: .init(
                overwrite: input.overwrite,
                prune: false,
                incremental: input.incremental
            )
        )
    }

    private func authorizeOperation(
        _ input: ImageCompressInput,
        workspace: WorkspaceContext?
    ) throws -> ImageCompressAuthorization {
        let projectAccess = try FileToolAccess.authorize(
            workspace: workspace,
            rootID: input.rootID,
            path: input.path,
            capability: .read,
            toolName: Self.identifier.rawValue,
            type: .directory
        )

        let project = ImageProject(
            root: projectAccess.absoluteURL
        )

        let configurationPath = childPath(
            ImageProjectDefaults.configurationFilename,
            under: projectAccess.presentationPath
        )

        let configurationAccess = try FileToolAccess.authorize(
            workspace: workspace,
            rootID: input.rootID,
            path: configurationPath,
            capability: .read,
            toolName: Self.identifier.rawValue,
            type: .file
        )

        let configuration = try ImageConfiguration.read(
            from: configurationAccess.absoluteURL
        )

        var destinationAccesses: [AuthorizedPath] = []

        for image in configuration.images {
            _ = try project.sourceURL(
                image.source
            )

            let sourcePath = childPath(
                image.source.string,
                under: projectAccess.presentationPath
            )

            _ = try FileToolAccess.authorize(
                workspace: workspace,
                rootID: input.rootID,
                path: sourcePath,
                capability: .read,
                toolName: Self.identifier.rawValue,
                type: .file
            )

            for output in image.outputs {
                _ = try project.destinationURL(
                    output.destination
                )

                let destinationPath = childPath(
                    output.destination.string,
                    under: projectAccess.presentationPath
                )

                destinationAccesses.append(
                    try FileToolAccess.authorize(
                        workspace: workspace,
                        rootID: input.rootID,
                        path: destinationPath,
                        capability: .write,
                        toolName: Self.identifier.rawValue,
                        type: .file
                    )
                )
            }
        }

        let incrementalStatePath = childPath(
            ImageProjectDefaults.incrementalStateFilename,
            under: projectAccess.presentationPath
        )

        _ = try FileToolAccess.authorize(
            workspace: workspace,
            rootID: input.rootID,
            path: incrementalStatePath,
            capability: .read,
            toolName: Self.identifier.rawValue,
            type: .file
        )

        let incrementalStateAccess = try FileToolAccess.authorize(
            workspace: workspace,
            rootID: input.rootID,
            path: incrementalStatePath,
            capability: .write,
            toolName: Self.identifier.rawValue,
            type: .file
        )

        return ImageCompressAuthorization(
            project: project,
            configuration: configuration,
            destinations: destinationAccesses,
            incrementalState: incrementalStateAccess
        )
    }

    private func childPath(
        _ child: String,
        under projectPath: String
    ) -> String {
        let projectPath = projectPath
            .trimmingCharacters(
                in: CharacterSet(
                    charactersIn: "/"
                )
            )

        guard !projectPath.isEmpty,
              projectPath != "."
        else {
            return child
        }

        return "\(projectPath)/\(child)"
    }
}
}

private struct ImageCompressAuthorization {
    let project: ImageProject
    let configuration: ImageConfiguration
    let destinations: [AuthorizedPath]
    let incrementalState: AuthorizedPath

    var outputCount: Int {
        configuration.images.reduce(
            into: 0
        ) { count, image in
            count += image.outputs.count
        }
    }

    var targetPaths: [String] {
        var seen = Set<String>()

        return (
            destinations.map(\.presentationPath)
            + [
                incrementalState.presentationPath,
            ]
        )
        .filter { path in
            seen.insert(
                path
            ).inserted
        }
    }
}
