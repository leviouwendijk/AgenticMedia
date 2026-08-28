import Path
import Primitives

public struct AgenticMediaPathInput:
    Sendable,
    Codable,
    Hashable
{
    public let rootID: PathAccessRootIdentifier
    public let path: String

    public init(
        rootID: PathAccessRootIdentifier = .project,
        path: String
    ) {
        self.rootID = rootID
        self.path = path
    }

    private enum CodingKeys: String, CodingKey {
        case rootID
        case path
    }

    public init(
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

    public static var schema: JSONValue {
        JSONSchema.object {
            JSONSchema.string(
                "rootID",
                description: "Workspace root identifier. Defaults to project."
            )

            JSONSchema.string(
                "path",
                required: true,
                description: "Path relative to the selected Agentic workspace root."
            )
        }
    }
}
