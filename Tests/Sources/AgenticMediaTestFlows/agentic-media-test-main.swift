import TestFlows

@main
enum AgenticMediaTestMain {
    static func main() async {
        await TestFlowCLI.run(
            suite: AgenticMediaFlowSuite.self
        )
    }
}
