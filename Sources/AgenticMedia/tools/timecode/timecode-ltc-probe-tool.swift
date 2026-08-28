import Agentic
import AgenticExecution
import AgenticIO
import AgenticWorkspace
import Foundation
import Primitives
import Timecode

public struct TimecodeLTCProbeTool: StaticAgentTool {
    public static let identifier: AgentToolIdentifier =
        "timecode_ltc_probe"

    public static let description =
        "Probe embedded audio LTC in a workspace media asset and summarize detected signals and anchors."

    public static let risk: ActionRisk = .observe

    public static var inputSchema: JSONValue? {
        AgenticMediaPathInput.schema
    }

    public init() {}

    public func preflight(
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> ToolPreflight {
        let decoded = try JSONToolBridge.decode(
            AgenticMediaPathInput.self,
            from: input
        )

        let authorized = try FileToolAccess.authorize(
            workspace: workspace,
            rootID: decoded.rootID,
            path: decoded.path,
            capability: .read,
            toolName: name,
            type: .file
        )

        return .init(
            toolName: name,
            risk: risk,
            workspaceRoot: workspace?.rootURL.path,
            targetPaths: [
                authorized.presentationPath,
            ],
            summary: "Decode and summarize embedded audio LTC without modifying the asset.",
            sideEffects: [],
            rootIDs: [
                decoded.rootID.rawValue,
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
        input: JSONValue,
        workspace: AgentWorkspace?
    ) async throws -> JSONValue {
        let decoded = try JSONToolBridge.decode(
            AgenticMediaPathInput.self,
            from: input
        )

        let authorized = try FileToolAccess.authorize(
            workspace: workspace,
            rootID: decoded.rootID,
            path: decoded.path,
            capability: .read,
            toolName: name,
            type: .file
        )

        let signals = try await LTC.AssetSignalResolver().scan(
            authorized.absoluteURL
        )

        return try JSONToolBridge.encode(
            AgenticLTCProbeOutput(
                source: authorized.presentationPath,
                signals: signals.map { signal in
                    summarize(
                        signal
                    )
                }
            )
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

private struct AgenticLTCProbeOutput:
    Sendable,
    Codable,
    Hashable
{
    let source: String
    let signals: [AgenticLTCSignalSummary]
}

private struct AgenticLTCSignalSummary:
    Sendable,
    Codable,
    Hashable
{
    let trackID: Int32
    let channel: Int
    let frameRate: String
    let framesPerSecond: Double
    let nominalFrameRate: Int
    let dropFrame: Bool
    let measuredFramesPerSecond: Double
    let decodedFrameCount: Int
    let firstTimecode: String
    let lastTimecode: String
    let anchor: AgenticLTCAnchorSummary?
    let anchorError: String?
}

private struct AgenticLTCAnchorSummary:
    Sendable,
    Codable,
    Hashable
{
    let timecode: String
    let containingFrameAtMediaStart: Int64
    let frameAtMediaStart: Double
    let phaseWithinContainingFrame: Double
    let framesUsed: Int
    let maxResidualFrames: Double
}
