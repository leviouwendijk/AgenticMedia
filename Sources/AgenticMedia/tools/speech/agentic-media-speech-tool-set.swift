import Agentic

public struct MediaSpeechToolProvider: AgentToolProvider {
    public let runtime: AgenticMediaSpeechRuntime

    public init(
        runtime: AgenticMediaSpeechRuntime
    ) {
        self.runtime = runtime
    }

    public func registerTools(
        into registry: inout ToolRegistry
    ) throws {
        try registry.register(
            Media.Tools.TranscribeSpeech(
                runtime: runtime
            )
        )
        try registry.register(
            Media.Tools.AnalyzeSpeech(
                runtime: runtime
            )
        )
    }
}
