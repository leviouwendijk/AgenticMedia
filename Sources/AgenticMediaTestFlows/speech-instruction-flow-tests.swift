import Agentic
import AgenticMedia
import TestFlows

extension AgenticMediaFlowSuite {
    static var speechInstructionSurfaceFlow: TestFlow {
        TestFlow(
            "agentic-media-instruction-surface",
            tags: ["agentic-media", "instructions", "speech", "timecode"]
        ) {
            Step("discover authored Media Instructions without Tool installation") {
                let catalog = Media.catalog
                let speech = Media.Instructions.SpeechAnalysis.definition
                let timecode = Media.Instructions.LTCTimecodeWorkflow.definition
                try Expect.equal(
                    catalog.instructions.contains(speech),
                    true,
                    "media speech guidance is discoverable"
                )
                try Expect.equal(
                    catalog.instructions.contains(timecode),
                    true,
                    "media LTC guidance is discoverable"
                )
                let composed = Instructions(
                    .instruction(speech),
                    .instruction(timecode)
                )
                try Expect.equal(
                    composed.snapshot.references.map(\.identifier),
                    [speech.identifier, timecode.identifier],
                    "composed Media Instructions preserve identity and order"
                )
            }
        }
    }
}
