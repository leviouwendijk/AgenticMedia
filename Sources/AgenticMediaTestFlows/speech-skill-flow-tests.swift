import Agentic
import AgenticMedia
import TestFlows

extension AgenticMediaFlowSuite {
    static var speechSkillSurfaceFlow: TestFlow {
        TestFlow(
            "agentic-media-skill-surface",
            tags: [
                "agentic-media",
                "skills",
                "speech",
                "timecode",
            ]
        ) {
            Step("register AgenticMedia domain skills") {
                _ = try Agentic.skill.registry(
                    skillProviders: [
                        AgenticMediaSkillProvider(),
                    ]
                )
            }
        }
    }
}
