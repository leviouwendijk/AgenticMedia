import Agentic
import AgenticIO
import AgenticMedia
import CodecsLAME
import Foundation
import Macros
import MediaTranscoding
import Path
import Schema
import Workspace

extension MediaAudioTranscodeResult: @retroactive JSONSchemaProviding {
    public static var jsonschema: JSONSchema { .object() }
}

public enum AgenticAudioConversionError: Error, Sendable {
    case sameSourceAndDestination
    case invalidDestinationExtension
    case destinationExists
    case negativeChannelIndex
}

public extension Media.Tools {
    @Tool("media_audio_convert")
    struct ConvertAudio: Tool {
        public typealias Input = AgenticAudioConversionInput
        public typealias Output = MediaAudioTranscodeResult

        public static let purpose = "Encode one authorized media asset to a new MP3, preserving the source and verifying the output."
        public static let risk: ActionRisk = .boundedmutate

        public init() {}

        public func preflight(_ input: Input, in context: ToolContext) async throws -> ToolPreflight {
            let paths = try authorize(input, in: context)
            return .init(
                tool: Self.definition.identifier,
                risk: Self.risk,
                summary: "Create one verified MP3 without modifying the input or replacing any existing file.",
                access: .init(
                    targets: [paths.source.presentationPath, paths.destination.presentationPath],
                    roots: [input.rootID.rawValue],
                    capabilities: [.read, .write]
                ),
                estimates: .init(write: .init(count: 1)),
                sideEffects: ["create one MP3 destination", "retain original source unchanged"],
                policyChecks: [
                    "workspace_required", "source_read_authorized", "destination_write_authorized",
                    "source_destination_distinct", "mp3_destination_required",
                    "existing_output_not_replaced", "single_destination_write_set"
                ]
            )
        }

        public func call(_ input: Input, in context: ToolContext) async throws -> Output {
            let paths = try authorize(input, in: context)
            let encoder: LAMEEncoder
            switch input.mode {
            case .maximum: encoder = LAMEEncoder(quality: .maximum)
            case .high: encoder = LAMEEncoder(quality: .high)
            case .balanced: encoder = LAMEEncoder(quality: .balanced)
            case .cbr320: encoder = LAMEEncoder(bitrate: .kbps320)
            }
            return try await MediaAudioTranscoder().transcode(
                paths.source.absoluteURL,
                to: paths.destination.absoluteURL,
                using: encoder,
                channelIndex: input.channelIndex
            )
        }

        private func authorize(
            _ input: Input,
            in context: ToolContext
        ) throws -> (source: AuthorizedPath, destination: AuthorizedPath) {
            if let channelIndex = input.channelIndex, channelIndex < 0 {
                throw AgenticAudioConversionError.negativeChannelIndex
            }
            let source = try FileToolAccess.authorize(
                workspace: context.workspace,
                rootID: input.rootID,
                path: input.source,
                capability: .read,
                toolName: Self.identifier.rawValue,
                type: .file
            )
            let destination = try FileToolAccess.authorize(
                workspace: context.workspace,
                rootID: input.rootID,
                path: input.destination,
                capability: .write,
                toolName: Self.identifier.rawValue,
                type: .file
            )
            guard source.absoluteURL.standardizedFileURL != destination.absoluteURL.standardizedFileURL else {
                throw AgenticAudioConversionError.sameSourceAndDestination
            }
            guard destination.absoluteURL.pathExtension.lowercased() == "mp3" else {
                throw AgenticAudioConversionError.invalidDestinationExtension
            }
            guard !FileManager.default.fileExists(atPath: destination.absoluteURL.path) else {
                throw AgenticAudioConversionError.destinationExists
            }
            return (source, destination)
        }
    }
}
