import AgenticIO
import Path
import Schema
import SchemaMacros

/// Transcribe speech from one authorized workspace media file.
@JSONSchema
public struct SpeechTranscribeToolInput:
    Sendable,
    Codable,
    Hashable
{
    /// Workspace root identifier. Defaults to project.
    @Schema(required: false)
    public let rootID: PathAccessRootIdentifier

    /// Media file path relative to the selected workspace root.
    public let path: String

    /// Requested transcription locale identifier.
    public let localeIdentifier: String

    public init(
        rootID: PathAccessRootIdentifier = .project,
        path: String,
        localeIdentifier: String
    ) {
        self.rootID = rootID
        self.path = path
        self.localeIdentifier = localeIdentifier
    }
}

private extension SpeechTranscribeToolInput {
    enum CodingKeys: String, CodingKey {
        case rootID
        case path
        case localeIdentifier
    }
}

public extension SpeechTranscribeToolInput {
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

        localeIdentifier = try container.decode(
            String.self,
            forKey: .localeIdentifier
        )
    }
}

/// Analyze speech, diarization, and speaker attribution for one authorized workspace media file.
@JSONSchema
public struct SpeechAnalyzeToolInput:
    Sendable,
    Codable,
    Hashable
{
    /// Workspace root identifier. Defaults to project.
    @Schema(required: false)
    public let rootID: PathAccessRootIdentifier

    /// Media file path relative to the selected workspace root.
    public let path: String

    /// Requested transcription locale identifier.
    public let localeIdentifier: String

    /// Optional expected number of speakers when reliably known.
    @Schema(required: false)
    public let expectedSpeakerCount: Int?

    public init(
        rootID: PathAccessRootIdentifier = .project,
        path: String,
        localeIdentifier: String,
        expectedSpeakerCount: Int? = nil
    ) {
        self.rootID = rootID
        self.path = path
        self.localeIdentifier = localeIdentifier
        self.expectedSpeakerCount = expectedSpeakerCount
    }
}

private extension SpeechAnalyzeToolInput {
    enum CodingKeys: String, CodingKey {
        case rootID
        case path
        case localeIdentifier
        case expectedSpeakerCount
    }
}

public extension SpeechAnalyzeToolInput {
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

        localeIdentifier = try container.decode(
            String.self,
            forKey: .localeIdentifier
        )

        expectedSpeakerCount = try container.decodeIfPresent(
            Int.self,
            forKey: .expectedSpeakerCount
        )
    }
}
