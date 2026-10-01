import AgenticExecution

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
        try registry.register {
            AgentToolRegistration.tool(
                Media.Tools.TranscribeSpeech(
                    runtime: runtime
                ),
                execution: .targetable
            )
            AgentToolRegistration.tool(
                Media.Tools.AnalyzeSpeech(
                    runtime: runtime
                ),
                execution: .targetable
            )
        }
    }
}
