import Agentic
import AgenticExecution
import AgenticIO
import AgenticWorkspace
import Foundation
import Images
import Path
import Primitives
import Schema
import SchemaMacros

/// Compress configured outputs in a workspace Images project.
@JSONSchema
public struct ImageCompressToolInput:
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

private extension ImageCompressToolInput {
    enum CodingKeys: String, CodingKey {
        case rootID
        case path
        case overwrite
        case incremental
    }
}

public extension ImageCompressToolInput {
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

public struct ImageCompressTool: TypedAgentTool {
    public typealias Input = ImageCompressToolInput

    public static let identifier: AgentToolIdentifier =
        "image_compress"

    public static let description =
        "Compress configured outputs in a workspace Images project without pruning unconfigured files."

    public static let risk: ActionRisk = .boundedmutate


    public init() {}

    public func preflight(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> ToolPreflight {
        let decoded = try JSONToolBridge.decode(
            ImageCompressToolInput.self,
            from: input
        )

        let authorization = try authorizeOperation(
            decoded,
            workspace: workspace
        )

        return .init(
            toolName: name,
            risk: risk,
            workspaceRoot: workspace?.rootURL.path,
            targetPaths: authorization.targetPaths,
            summary: "Compress \(authorization.outputCount) configured image output(s) without pruning unconfigured files.",
            estimatedWriteCount: authorization.targetPaths.count,
            sideEffects: [
                "write or replace configured compressed image outputs",
                "create parent directories required by configured outputs",
                "update \(ImageProjectDefaults.incrementalStateFilename)",
            ],
            rootIDs: [
                decoded.rootID.rawValue,
            ],
            capabilitiesRequired: [
                .read,
                .write,
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
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> JSONValue {
        let decoded = try JSONToolBridge.decode(
            ImageCompressToolInput.self,
            from: input
        )

        let authorization = try authorizeOperation(
            decoded,
            workspace: workspace
        )

        let report = ImageCompression.compress(
            in: authorization.project,
            configuration: authorization.configuration,
            options: .init(
                overwrite: decoded.overwrite,
                prune: false,
                incremental: decoded.incremental
            )
        )

        return try JSONToolBridge.encode(
            report
        )
    }

    private func authorizeOperation(
        _ input: ImageCompressToolInput,
        workspace: AgentWorkspace?
    ) throws -> ImageCompressAuthorization {
        let projectAccess = try FileToolAccess.authorize(
            workspace: workspace,
            rootID: input.rootID,
            path: input.path,
            capability: .read,
            toolName: name,
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
            toolName: name,
            type: .file
        )

        let configuration = try ImageConfiguration.read(
            from: configurationAccess.absoluteURL
        )

        var destinationAccesses: [AgenticAuthorizedPath] = []

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
                toolName: name,
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
                        toolName: name,
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
            toolName: name,
            type: .file
        )

        let incrementalStateAccess = try FileToolAccess.authorize(
            workspace: workspace,
            rootID: input.rootID,
            path: incrementalStatePath,
            capability: .write,
            toolName: name,
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

private struct ImageCompressAuthorization {
    let project: ImageProject
    let configuration: ImageConfiguration
    let destinations: [AgenticAuthorizedPath]
    let incrementalState: AgenticAuthorizedPath

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
