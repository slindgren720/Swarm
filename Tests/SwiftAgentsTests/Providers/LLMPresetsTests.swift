import Conduit
import Testing
@testable import SwiftAgents

@Suite("LLM Presets")
struct LLMPresetsTests {
    @Test("OpenAI preset builds Conduit OpenAI provider")
    func openAIPresetBuildsProvider() {
        let agent = ToolCallingAgent(
            inferenceProvider: .openAI(apiKey: "test-key", model: "gpt-4o-mini")
        )

        let provider = agent.inferenceProvider
        #expect(provider is ConduitInferenceProvider<OpenAIProvider>)
    }

    @Test("Anthropic preset builds Conduit Anthropic provider")
    func anthropicPresetBuildsProvider() {
        let agent = ToolCallingAgent(
            inferenceProvider: .anthropic(apiKey: "test-key", model: "claude-3-opus-20240229")
        )

        let provider = agent.inferenceProvider
        #expect(provider is ConduitInferenceProvider<AnthropicProvider>)
    }

    @Test("OpenRouter preset builds Conduit OpenAI-compatible provider")
    func openRouterPresetBuildsProvider() {
        let agent = ToolCallingAgent(
            inferenceProvider: .openRouter(apiKey: "test-key", model: "anthropic/claude-3-opus")
        )

        let provider = agent.inferenceProvider
        #expect(provider is ConduitInferenceProvider<OpenAIProvider>)
    }
}

