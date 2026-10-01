import AgenticIO
import Path
import Schema
import Macros

/// Select one path relative to an authorized Agentic workspace root.
@JSONSchema
public struct MediaPathInput:
    Sendable,
    Codable,
    Hashable
{
    /// Workspace root identifier. Defaults to project.
    @Schema(required: false)
    public let rootID: PathAccessRootIdentifier

    /// Path relative to the selected Agentic workspace root.
    public let path: String

    public init(
        rootID: PathAccessRootIdentifier = .project,
        path: String
    ) {
        self.rootID = rootID
        self.path = path
    }
}

private extension MediaPathInput {
    enum CodingKeys: String, CodingKey {
        case rootID
        case path
    }
}

public extension MediaPathInput {
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
    }
}
