import Agentic
import AgenticExecution
import AgenticIO
import AgenticWorkspace
import Foundation
import MediaAV
import Path
import Primitives
import Timecode
import Schema
import SchemaMacros

/// Remux one media source to a destination while deriving native timecode from embedded LTC.
@JSONSchema
public struct TimecodeLTCRemuxToolInput:
    Sendable,
    Codable,
    Hashable
{
    /// Workspace root identifier. Defaults to project.
    @Schema(required: false)
    public let rootID: PathAccessRootIdentifier

    /// Source media path relative to the selected workspace root.
    public let source: String

    /// Destination media path relative to the selected workspace root.
    public let destination: String

    public init(
        rootID: PathAccessRootIdentifier = .project,
        source: String,
        destination: String
    ) {
        self.rootID = rootID
        self.source = source
        self.destination = destination
    }
}

private extension TimecodeLTCRemuxToolInput {
    enum CodingKeys: String, CodingKey {
        case rootID
        case source
        case destination
    }
}

public extension TimecodeLTCRemuxToolInput {
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

        source = try container.decode(
            String.self,
            forKey: .source
        )

        destination = try container.decode(
            String.self,
            forKey: .destination
        )
    }
}

public struct TimecodeLTCRemuxTool: TypedAgentTool {
    public typealias Input = TimecodeLTCRemuxToolInput

    public static let identifier: AgentToolIdentifier =
        "timecode_ltc_remux"

    public static let description =
        "Create a new MOV whose native timecode track is derived from embedded audio LTC while preserving encoded media essence."

    public static let risk: ActionRisk = .boundedmutate


    public init() {}

    public func preflight(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> ToolPreflight {
        let decoded = try JSONToolBridge.decode(
            TimecodeLTCRemuxToolInput.self,
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
            targetPaths: [
                authorization.source.presentationPath,
                authorization.destination.presentationPath,
            ],
            summary: "Derive native timecode from source LTC and create one new MOV destination without overwriting existing output.",
            estimatedWriteCount: 1,
            sideEffects: [
                "create one destination MOV",
                "add native tmcd timecode derived from embedded audio LTC",
                "preserve encoded source media essence through passthrough remux",
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
                "source_media_authorized",
                "destination_media_authorized",
                "source_and_destination_distinct",
                "destination_mov_required",
                "existing_destination_not_overwritten",
                "single_destination_write_set",
            ]
        )
    }

    public func call(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> JSONValue {
        let decoded = try JSONToolBridge.decode(
            TimecodeLTCRemuxToolInput.self,
            from: input
        )

        let authorization = try authorizeOperation(
            decoded,
            workspace: workspace
        )

        let sourceURL = authorization.source.absoluteURL
        let destinationURL = authorization.destination.absoluteURL

        let signal = try await LTC.AssetSignalResolver().resolve(
            sourceURL
        )

        let anchor = try signal.anchor()
        let sourceFrame = anchor.containingFrameAtMediaStart

        guard let frameNumber = Int32(
            exactly: sourceFrame
        ) else {
            throw TimecodeLTCRemuxToolError.frameNumberOutOfRange(
                sourceFrame
            )
        }

        try await MediaAssetTimecodeRemuxer().remux(
            sourceURL,
            to: destinationURL,
            frameNumber: frameNumber,
            phaseWithinFrame: anchor.phaseWithinContainingFrame,
            format: signal.format.mediaTimecodeFormat
        )

        let writtenFrame = try await MediaAssetTimecodeReader()
            .firstFrameNumber(
                destinationURL
            )

        guard writtenFrame == frameNumber else {
            throw TimecodeLTCRemuxToolError.timecodeReadbackMismatch(
                expected: frameNumber,
                actual: writtenFrame
            )
        }

        let inspection = try await MediaAssetInspector().inspect(
            destinationURL
        )

        guard inspection.timecodeTracks.count == 1 else {
            throw TimecodeLTCRemuxToolError.unexpectedTimecodeTrackCount(
                inspection.timecodeTracks.count
            )
        }

        let timecodeTrack = inspection.timecodeTracks[0]

        for videoTrack in inspection.videoTracks {
            guard videoTrack.associatedTimecodeTrackIDs.contains(
                timecodeTrack.id
            ) else {
                throw TimecodeLTCRemuxToolError.missingTimecodeAssociation(
                    videoTrackID: videoTrack.id,
                    timecodeTrackID: timecodeTrack.id
                )
            }
        }

        let essence = try await MediaAssetEssenceVerifier().verify(
            sourceURL,
            against: destinationURL
        )

        return try JSONToolBridge.encode(
            TimecodeLTCRemuxToolOutput(
                source: authorization.source.presentationPath,
                destination: authorization.destination.presentationPath,
                ltcTrackID: signal.trackID,
                ltcChannel: signal.channel,
                frameRate: signal.format.frameRate.rationalString,
                dropFrame: signal.format.dropFrame,
                sourceTimecode: anchor.timecode.string,
                frameNumber: frameNumber,
                phaseWithinFrame: anchor.phaseWithinContainingFrame,
                outputTimecodeTrackID: timecodeTrack.id,
                videoTrackCount: inspection.videoTracks.count,
                essenceTrackCount: essence.tracks.count,
                essenceByteCount: essence.totalByteCount
            )
        )
    }

    private func authorizeOperation(
        _ input: TimecodeLTCRemuxToolInput,
        workspace: AgentWorkspace?
    ) throws -> TimecodeLTCRemuxAuthorization {
        let source = try FileToolAccess.authorize(
            workspace: workspace,
            rootID: input.rootID,
            path: input.source,
            capability: .read,
            toolName: name,
            type: .file
        )

        let destination = try FileToolAccess.authorize(
            workspace: workspace,
            rootID: input.rootID,
            path: input.destination,
            capability: .write,
            toolName: name,
            type: .file
        )

        guard source.absoluteURL.standardizedFileURL
            != destination.absoluteURL.standardizedFileURL else {
            throw TimecodeLTCRemuxToolError.identicalSourceAndDestination
        }

        guard destination.absoluteURL
            .pathExtension
            .lowercased()
            == "mov" else {
            throw TimecodeLTCRemuxToolError.destinationMustBeMOV(
                destination.presentationPath
            )
        }

        return TimecodeLTCRemuxAuthorization(
            source: source,
            destination: destination
        )
    }
}

private struct TimecodeLTCRemuxAuthorization {
    let source: AgenticAuthorizedPath
    let destination: AgenticAuthorizedPath
}

private struct TimecodeLTCRemuxToolOutput:
    Sendable,
    Codable,
    Hashable
{
    let source: String
    let destination: String
    let ltcTrackID: Int32
    let ltcChannel: Int
    let frameRate: String
    let dropFrame: Bool
    let sourceTimecode: String
    let frameNumber: Int32
    let phaseWithinFrame: Double
    let outputTimecodeTrackID: Int32
    let videoTrackCount: Int
    let essenceTrackCount: Int
    let essenceByteCount: Int64
}

private enum TimecodeLTCRemuxToolError:
    Error,
    Sendable,
    LocalizedError
{
    case identicalSourceAndDestination
    case destinationMustBeMOV(String)
    case frameNumberOutOfRange(Int64)
    case timecodeReadbackMismatch(
        expected: Int32,
        actual: Int32
    )
    case unexpectedTimecodeTrackCount(Int)
    case missingTimecodeAssociation(
        videoTrackID: Int32,
        timecodeTrackID: Int32
    )

    var errorDescription: String? {
        switch self {
        case .identicalSourceAndDestination:
            return "LTC remux requires distinct source and destination files."

        case .destinationMustBeMOV(let path):
            return "LTC remux destination must use a .mov extension: \(path)"

        case .frameNumberOutOfRange(let frame):
            return "LTC source frame does not fit the TimeCode32 representation: \(frame)."

        case .timecodeReadbackMismatch(
            let expected,
            let actual
        ):
            return "Written timecode readback mismatch; expected \(expected), received \(actual)."

        case .unexpectedTimecodeTrackCount(let count):
            return "Remuxed media contains \(count) timecode tracks instead of exactly one."

        case .missingTimecodeAssociation(
            let videoTrackID,
            let timecodeTrackID
        ):
            return "Video track \(videoTrackID) is not associated with timecode track \(timecodeTrackID)."
        }
    }
}
