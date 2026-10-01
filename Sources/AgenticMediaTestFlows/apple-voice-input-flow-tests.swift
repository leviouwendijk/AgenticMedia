import AgenticInterfaces
import AgenticMediaApple
import TestFlows

extension AgenticMediaFlowSuite {
    static func runAppleVoiceInputSurface()
        async throws
        -> [TestDiagnostic]
    {
        let provider: any VoiceInputProvider =
            AppleVoiceInputProvider(
                localeIdentifier: "en-US"
            )

        _ = provider

        return []
    }
}
