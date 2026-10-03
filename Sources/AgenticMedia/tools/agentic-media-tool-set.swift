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
        try registry.register {
            AgentToolRegistration.tool(
                Media.Tools.Inspect(),
                execution: .targetable
            )
            AgentToolRegistration.tool(
                Media.Tools.ProbeLTC(),
                execution: .targetable
            )
            AgentToolRegistration.tool(
                Media.Tools.RemuxLTC(),
                execution: .targetable
            )
            AgentToolRegistration.tool(
                Media.Tools.DiscoverImages(),
                execution: .targetable
            )
            AgentToolRegistration.tool(
                Media.Tools.CompressImages(),
                execution: .targetable
            )
        }

        if let speech {
            try MediaSpeechToolProvider(
                runtime: speech
            ).registerTools(
                into: &registry
            )
        }
    }
}
