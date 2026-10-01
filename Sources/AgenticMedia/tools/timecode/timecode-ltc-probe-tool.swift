import Agentic
import AgenticExecution
import AgenticIO
import Workspace
import Macros
import Foundation
import Timecode

public extension Media.Tools {
    @Tool("timecode_ltc_probe")
    struct ProbeLTC: Tool {
        public typealias Input = MediaPathInput
        public typealias Output = LTCProbeOutput

        public static let purpose =
            "Probe embedded audio LTC in a workspace media asset and summarize detected signals and anchors."

        public static let risk: ActionRisk = .observe

        public init() {}

    public func preflight(
        _ input: Input,
        workspace: WorkspaceContext?
    ) async throws -> ToolPreflight {
        let authorized = try FileToolAccess.authorize(
            workspace: workspace,
            rootID: input.rootID,
            path: input.path,
            capability: .read,
            toolName: Self.identifier.rawValue,
            type: .file
        )

        return .init(
            tool: Self.definition.identifier,
            risk: Self.risk,
            summary: "Decode and summarize embedded audio LTC without modifying the asset.",
            access: .init(
                targets: [
                    authorized.presentationPath,
                ],
                roots: [
                    input.rootID.rawValue,
                ],
                capabilities: [
                    .read,
                ]
            ),
            policyChecks: [
                "workspace_required",
                "workspace_path_authorized",
                "read_only_ltc_probe",
            ]
        )
    }

    public func call(
        _ input: Input,
        workspace: WorkspaceContext?
    ) async throws -> Output {
        let authorized = try FileToolAccess.authorize(
            workspace: workspace,
            rootID: input.rootID,
            path: input.path,
            capability: .read,
            toolName: Self.identifier.rawValue,
            type: .file
        )

        let signals = try await LTC.AssetSignalResolver().scan(
            authorized.absoluteURL
        )

        return LTCProbeOutput(
            source: authorized.presentationPath,
            signals: signals.map { signal in
                summarize(
                    signal
                )
            }
        )
    }

    private func summarize(
        _ signal: LTC.AssetSignal
    ) -> LTCSignalSummary {
        let anchor: LTCAnchorSummary?
        let anchorError: String?

        do {
            let resolved = try signal.anchor()

            anchor = LTCAnchorSummary(
                timecode: resolved.timecode.string,
                containingFrameAtMediaStart: resolved.containingFrameAtMediaStart,
                frameAtMediaStart: resolved.frameAtMediaStart,
                phaseWithinContainingFrame: resolved.phaseWithinContainingFrame,
                framesUsed: resolved.framesUsed,
                maxResidualFrames: resolved.maxResidualFrames
            )

            anchorError = nil
        } catch {
            anchor = nil
            anchorError = error.localizedDescription
        }

        let rate = signal.format.frameRate
        let detection = signal.detection

        return LTCSignalSummary(
            trackID: signal.trackID,
            channel: signal.channel,
            frameRate: rate.rationalString,
            framesPerSecond: rate.framesPerSecond,
            nominalFrameRate: rate.nominalFrameRate,
            dropFrame: signal.format.dropFrame,
            measuredFramesPerSecond: detection.measuredFramesPerSecond,
            decodedFrameCount: detection.frameCount,
            firstTimecode: detection.firstTimecode.string,
            lastTimecode: detection.lastTimecode.string,
            anchor: anchor,
            anchorError: anchorError
        )
    }
}
}

public struct LTCProbeOutput:
    Sendable,
    Codable,
    Hashable
{
    public let source: String
    public let signals: [LTCSignalSummary]

    public init(
        source: String,
        signals: [LTCSignalSummary]
    ) {
        self.source = source
        self.signals = signals
    }
}

public struct LTCSignalSummary:
    Sendable,
    Codable,
    Hashable
{
    public let trackID: Int32
    public let channel: Int
    public let frameRate: String
    public let framesPerSecond: Double
    public let nominalFrameRate: Int
    public let dropFrame: Bool
    public let measuredFramesPerSecond: Double
    public let decodedFrameCount: Int
    public let firstTimecode: String
    public let lastTimecode: String
    public let anchor: LTCAnchorSummary?
    public let anchorError: String?

    public init(
        trackID: Int32,
        channel: Int,
        frameRate: String,
        framesPerSecond: Double,
        nominalFrameRate: Int,
        dropFrame: Bool,
        measuredFramesPerSecond: Double,
        decodedFrameCount: Int,
        firstTimecode: String,
        lastTimecode: String,
        anchor: LTCAnchorSummary?,
        anchorError: String?
    ) {
        self.trackID = trackID
        self.channel = channel
        self.frameRate = frameRate
        self.framesPerSecond = framesPerSecond
        self.nominalFrameRate = nominalFrameRate
        self.dropFrame = dropFrame
        self.measuredFramesPerSecond = measuredFramesPerSecond
        self.decodedFrameCount = decodedFrameCount
        self.firstTimecode = firstTimecode
        self.lastTimecode = lastTimecode
        self.anchor = anchor
        self.anchorError = anchorError
    }
}

public struct LTCAnchorSummary:
    Sendable,
    Codable,
    Hashable
{
    public let timecode: String
    public let containingFrameAtMediaStart: Int64
    public let frameAtMediaStart: Double
    public let phaseWithinContainingFrame: Double
    public let framesUsed: Int
    public let maxResidualFrames: Double

    public init(
        timecode: String,
        containingFrameAtMediaStart: Int64,
        frameAtMediaStart: Double,
        phaseWithinContainingFrame: Double,
        framesUsed: Int,
        maxResidualFrames: Double
    ) {
        self.timecode = timecode
        self.containingFrameAtMediaStart = containingFrameAtMediaStart
        self.frameAtMediaStart = frameAtMediaStart
        self.phaseWithinContainingFrame = phaseWithinContainingFrame
        self.framesUsed = framesUsed
        self.maxResidualFrames = maxResidualFrames
    }
}
