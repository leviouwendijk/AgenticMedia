import AgenticExecution

public struct AgenticMediaToolSet: AgentToolSet {
    private let speech: AgenticMediaSpeechRuntime?

    public init(
        speech: AgenticMediaSpeechRuntime? = nil
    ) {
        self.speech = speech
    }

    public func register(
        into registry: inout ToolRegistry
    ) throws {
        try registry.register {
            MediaInspectTool()
            TimecodeLTCProbeTool()
            TimecodeLTCRemuxTool()
            ImageDiscoverTool()
            ImageCompressTool()
        }

        if let speech {
            try registry.register(
                AgenticMediaSpeechToolSet(
                    runtime: speech
                )
            )
        }
    }
}
