import Agentic

public struct AgenticMediaSkillProvider: AgentSkillProvider {
    public init() {}

    public func registerSkills(
        into registry: inout SkillRegistry
    ) throws {
        try registry.register(
            [
                Self.speechAnalysis,
                Self.ltcTimecodeWorkflow,
            ]
        )
    }
}
