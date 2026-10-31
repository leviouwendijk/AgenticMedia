import AgenticIO
import Macros
import Path
import Schema

/// Single-choice encoding specification, never simultaneous bitrate and quality knobs.
public enum AgenticAudioConversionMode: String, Sendable, Codable, Hashable, CaseIterable, JSONSchemaProviding {
    case maximum
    case high
    case balanced
    case cbr320

    public static var jsonschema: JSONSchema { .string() }
}

@JSONSchema
public struct AgenticAudioConversionInput: Sendable, Codable, Hashable {
    @Schema(required: false)
    public let rootID: PathAccessRootIdentifier
    public let source: String
    public let destination: String
    public let mode: AgenticAudioConversionMode
    @Schema(required: false)
    public let channelIndex: Int?

    public init(
        rootID: PathAccessRootIdentifier = .project,
        source: String,
        destination: String,
        mode: AgenticAudioConversionMode = .maximum,
        channelIndex: Int? = nil
    ) {
        self.rootID = rootID
        self.source = source
        self.destination = destination
        self.mode = mode
        self.channelIndex = channelIndex
    }

}

private extension AgenticAudioConversionInput {
    enum CodingKeys: String, CodingKey {
        case rootID, source, destination, mode, channelIndex
    }
}

public extension AgenticAudioConversionInput {
    init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        rootID = try values.decodeIfPresent(PathAccessRootIdentifier.self, forKey: .rootID) ?? .project
        source = try values.decode(String.self, forKey: .source)
        destination = try values.decode(String.self, forKey: .destination)
        mode = try values.decodeIfPresent(AgenticAudioConversionMode.self, forKey: .mode) ?? .maximum
        channelIndex = try values.decodeIfPresent(Int.self, forKey: .channelIndex)
    }
}
