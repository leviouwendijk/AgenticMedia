import AgenticExecution

public struct AgenticMediaSpeechToolSet: AgentToolSet {
    public let runtime: AgenticMediaSpeechRuntime

    public init(
        runtime: AgenticMediaSpeechRuntime
    ) {
        self.runtime = runtime
    }

    public func register(
        into registry: inout ToolRegistry
    ) throws {
        try registry.register {
            SpeechTranscribeTool(
                runtime: runtime
            )
            SpeechAnalyzeTool(
                runtime: runtime
            )
        }
    }
}
