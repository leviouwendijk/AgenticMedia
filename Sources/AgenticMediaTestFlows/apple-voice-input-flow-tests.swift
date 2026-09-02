import Agentic
import AgenticInterfaces
import AgenticMediaApple
import AgenticRuntime
import TestFlows

private enum AppleVoiceInputFixtureFailure:
    Error
{
    case missingProvider
}

extension AgenticMediaFlowSuite {
    static func runAppleVoiceInputSurface()
        async throws
        -> [TestFlowDiagnostic]
    {
        let provider =
            AppleVoiceInputProvider(
                localeIdentifier: "en-US"
            )

        let application =
            Agentic.application(
                "apple-voice-input-fixture"
            ) {
                voiceInput(
                    provider
                )
            }

        guard application.voiceInputProvider
            != nil
        else {
            throw AppleVoiceInputFixtureFailure
                .missingProvider
        }

        let availability =
            await provider.availability()

        try Expect.equal(
            availability == .unconfigured,
            false,
            "apple-voice.provider-configured"
        )

        return []
    }
}
