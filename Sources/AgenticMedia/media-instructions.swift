import Agentic

/// Authored guidance, independently selectable from capability exposure.
public extension Media.Instructions {
    @Instruction
    enum SpeechAnalysis {
        public static let content = """
        Choose speech tooling according to what the task actually needs.

        Workflow:
        1. Use `\(Media.Tools.TranscribeSpeech.identifier.rawValue)` when the task only needs the spoken words.
        2. Use `\(Media.Tools.AnalyzeSpeech.identifier.rawValue)` when speaker attribution, turn-taking, or who-said-what matters.
        3. Use `\(Media.Tools.Inspect.identifier.rawValue)` first when the media asset, available tracks, or suitability of the source is uncertain.
        4. Do not routinely invoke both speech tools for the same purpose.
        5. The speaker count is detected automatically. Supply expectedSpeakerCount or maximumSpeakerCount only when the user or reliable evidence supports it; do not guess either to force diarization.
        6. Treat speaker identifiers as anonymous inferred speaker clusters, not as real-world identities. Quiet speakers far from the microphone may be detected but barely transcribed.
        7. Read the transcript by turns. Keep `overlap` turns (several candidate speakers) and `uncertain` turns as they are instead of assigning them to a speaker yourself.
        8. Check `provenance` for how the transcript was made (transcriber, locale, diarizer) before comparing analyses.
        9. Prefer the bounded conversation result for ordinary reasoning. Do not request or manufacture diagnostic inference, embedding observations, or acoustic evidence unless a dedicated diagnostic workflow explicitly requires them.
        """
    }

    @Instruction
    enum LTCTimecodeWorkflow {
        public static let content = """
        Use a staged LTC workflow instead of mutating media immediately.

        Workflow:
        1. Use `\(Media.Tools.Inspect.identifier.rawValue)` when track layout and native metadata are not already known.
        2. Use `\(Media.Tools.ProbeLTC.identifier.rawValue)` to detect and inspect LTC before proposing a remux.
        3. Only use `\(Media.Tools.RemuxLTC.identifier.rawValue)` after the source, destination, and detected LTC state are clear.
        4. Treat remux as a media mutation and preserve the normal Agentic review boundary.
        5. Inspect or otherwise verify the produced media after remux when the result matters to downstream work.
        6. Do not infer usable LTC merely from the existence of an audio track; rely on the deterministic probe result.
        """
    }
}
