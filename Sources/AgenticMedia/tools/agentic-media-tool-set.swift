import AgenticExecution

public struct AgenticMediaToolSet: AgentToolSet {
    public init() {}

    public func register(
        into registry: inout ToolRegistry
    ) throws {
        try registry.register(
            [
                MediaInspectTool(),
                TimecodeLTCProbeTool(),
                ImageDiscoverTool(),
                ImageCompressTool(),
            ]
        )
    }
}
