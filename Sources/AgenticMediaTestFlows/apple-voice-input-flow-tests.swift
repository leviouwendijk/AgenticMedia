import AgenticInterfaces
import AgenticMediaApple
import TestFlows

extension AgenticMediaFlowSuite {
    static func runAppleVoiceInputSurface()
        async throws
        -> [TestFlowDiagnostic]
    {
        let provider: any VoiceInputProvider =
            AppleVoiceInputProvider(
                localeIdentifier: "en-US"
            )

        _ = provider

        return []
    }
}
