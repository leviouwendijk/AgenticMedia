import Agentic

public struct MediaToolProvider: AgentToolProvider {
    private let speech: AgenticMediaSpeechRuntime?

    public init(
        speech: AgenticMediaSpeechRuntime? = nil
    ) {
        self.speech = speech
    }

    public func registerTools(
        into registry: inout ToolRegistry
    ) throws {
        try registry.register(Media.Tools.Inspect())
        try registry.register(Media.Tools.ProbeLTC())
        try registry.register(Media.Tools.RemuxLTC())
        try registry.register(Media.Tools.DiscoverImages())
        try registry.register(Media.Tools.CompressImages())

        if let speech {
            try MediaSpeechToolProvider(
                runtime: speech
            ).registerTools(
                into: &registry
            )
        }
    }
}
