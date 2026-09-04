import Agentic
import AgenticExecution
import AgenticIO
import AgenticWorkspace
import Foundation
import Timecode

public struct TimecodeLTCProbeTool: AgentTool {
    public typealias Input = AgenticMediaPathInput
    public typealias Output = AgenticLTCProbeOutput

    public static let identifier: AgentToolIdentifier =
        "timecode_ltc_probe"

    public static let description =
        "Probe embedded audio LTC in a workspace media asset and summarize detected signals and anchors."

    public static let risk: ActionRisk = .observe

    public var identifier: AgentToolIdentifier {
        Self.identifier
    }

    public var description: String {
        Self.description
    }

    public var risk: ActionRisk {
        Self.risk
    }

    public var execution: AgentToolExecutionContract {
        .targetable
    }

    public init() {}

    public func preflight(
        _ input: Input,
        context: AgentToolExecutionContext
    ) async throws -> ToolPreflight {
        let authorized = try FileToolAccess.authorize(
            workspace: context.workspace,
            rootID: input.rootID,
            path: input.path,
            capability: .read,
            toolName: name,
            type: .file
        )

        return .init(
            toolName: name,
            risk: risk,
            workspaceRoot: context.workspace?.rootURL.path,
            targetPaths: [
                authorized.presentationPath,
            ],
            summary: "Decode and summarize embedded audio LTC without modifying the asset.",
            sideEffects: [],
            rootIDs: [
                input.rootID.rawValue,
            ],
            capabilitiesRequired: [
                .read,
            ],
            policyChecks: [
                "workspace_required",
                "workspace_path_authorized",
                "read_only_ltc_probe",
            ]
        )
    }

    public func call(
        _ input: Input,
        context: AgentToolExecutionContext
    ) async throws -> Output {
        let authorized = try FileToolAccess.authorize(
            workspace: context.workspace,
            rootID: input.rootID,
            path: input.path,
            capability: .read,
            toolName: name,
            type: .file
        )

        let signals = try await LTC.AssetSignalResolver().scan(
            authorized.absoluteURL
        )

        return AgenticLTCProbeOutput(
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
    ) -> AgenticLTCSignalSummary {
        let anchor: AgenticLTCAnchorSummary?
        let anchorError: String?

        do {
            let resolved = try signal.anchor()

            anchor = AgenticLTCAnchorSummary(
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

        return AgenticLTCSignalSummary(
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

public struct AgenticLTCProbeOutput:
    Sendable,
    Codable,
    Hashable
{
    public let source: String
    public let signals: [AgenticLTCSignalSummary]

    public init(
        source: String,
        signals: [AgenticLTCSignalSummary]
    ) {
        self.source = source
        self.signals = signals
    }
}

public struct AgenticLTCSignalSummary:
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
    public let anchor: AgenticLTCAnchorSummary?
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
        anchor: AgenticLTCAnchorSummary?,
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

public struct AgenticLTCAnchorSummary:
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
