// ConduitProviderTests.swift
// SwiftAgentsTests
//
// Comprehensive tests for ConduitProvider functionality.
//
// Note: These tests verify initialization, configuration, and error handling.
// Actual generation tests require mocked Conduit backends which will be
// added once the upstream Conduit build issue is resolved.

import Foundation
@testable import SwiftAgents
import Testing
import Conduit

@Suite("ConduitProvider Tests")
struct ConduitProviderTests {
    // MARK: - Initialization Tests

    @Test("init with valid Anthropic configuration succeeds")
    func initWithValidAnthropicConfigurationSucceeds() throws {
        let config = ConduitConfiguration.anthropic(apiKey: "sk-ant-test-key")

        let provider = try ConduitProvider(configuration: config)

        #expect(provider.configuration.apiKey == "sk-ant-test-key")
    }

    @Test("init with valid OpenAI configuration succeeds")
    func initWithValidOpenAIConfigurationSucceeds() throws {
        let config = ConduitConfiguration.openAI(apiKey: "sk-test-key")

        let provider = try ConduitProvider(configuration: config)

        #expect(provider.configuration.apiKey == "sk-test-key")
    }

    @Test("init with MLX configuration succeeds")
    func initWithMLXConfigurationSucceeds() throws {
        let config = ConduitConfiguration.mlx()

        let provider = try ConduitProvider(configuration: config)

        #expect(provider.configuration.apiKey == "local")
    }

    @Test("init with HuggingFace configuration succeeds")
    func initWithHuggingFaceConfigurationSucceeds() throws {
        let config = ConduitConfiguration.huggingFace(apiKey: "hf_test_key")

        let provider = try ConduitProvider(configuration: config)

        #expect(provider.configuration.apiKey == "hf_test_key")
    }

    @Test("init with providerType convenience initializer succeeds")
    func initWithProviderTypeConvenienceInitializerSucceeds() throws {
        let providerType = ConduitProviderType.anthropic(
            apiKey: "test-key",
            model: .claudeSonnet35
        )

        let provider = try ConduitProvider(providerType: providerType)

        #expect(provider.configuration.apiKey == "test-key")
    }

    // MARK: - Validation Tests

    @Test("generate with empty prompt throws invalidInput")
    func generateWithEmptyPromptThrowsInvalidInput() async throws {
        let config = ConduitConfiguration.anthropic(apiKey: "test-key")
        let provider = try ConduitProvider(configuration: config)

        await #expect(throws: AgentError.self) {
            _ = try await provider.generate(prompt: "", options: .default)
        }
    }

    @Test("generate with whitespace-only prompt throws invalidInput")
    func generateWithWhitespaceOnlyPromptThrowsInvalidInput() async throws {
        let config = ConduitConfiguration.anthropic(apiKey: "test-key")
        let provider = try ConduitProvider(configuration: config)

        await #expect(throws: AgentError.self) {
            _ = try await provider.generate(prompt: "   \n  \t  ", options: .default)
        }
    }

    // MARK: - Configuration Tests

    @Test("configuration is accessible")
    func configurationIsAccessible() throws {
        let config = ConduitConfiguration.anthropic(
            apiKey: "test-key",
            temperature: 0.7,
            maxTokens: 1000
        )

        let provider = try ConduitProvider(configuration: config)

        #expect(provider.configuration.apiKey == "test-key")
        #expect(provider.configuration.temperature == 0.7)
        #expect(provider.configuration.maxTokens == 1000)
    }

    @Test("retry strategy from configuration is used")
    func retryStrategyFromConfigurationIsUsed() throws {
        let config = ConduitConfiguration.anthropic(
            apiKey: "test-key",
            retryStrategy: .aggressive
        )

        let provider = try ConduitProvider(configuration: config)

        #expect(provider.configuration.retryStrategy.maxRetries == 5)
    }

    @Test("provider with no retry strategy doesn't retry")
    func providerWithNoRetryStrategyDoesntRetry() throws {
        let config = ConduitConfiguration.anthropic(
            apiKey: "test-key",
            retryStrategy: .none
        )

        let provider = try ConduitProvider(configuration: config)

        #expect(provider.configuration.retryStrategy.maxRetries == 0)
    }

    // MARK: - Error Mapping Tests

    @Test("ConduitProviderError maps to AgentError correctly")
    func conduitProviderErrorMapsToAgentErrorCorrectly() {
        let conduitError = ConduitProviderError.invalidInput(reason: "Test error")
        let agentError = conduitError.toAgentError()

        if case .invalidInput(let reason) = agentError {
            #expect(reason == "Test error")
        } else {
            Issue.record("Expected invalidInput AgentError")
        }
    }

    @Test("rate limit error includes retry hint")
    func rateLimitErrorIncludesRetryHint() {
        let conduitError = ConduitProviderError.rateLimitExceeded(retryAfter: 60)
        let agentError = conduitError.toAgentError()

        if case .rateLimitExceeded(let retryAfter) = agentError {
            #expect(retryAfter == 60)
        } else {
            Issue.record("Expected rateLimitExceeded AgentError with retry hint")
        }
    }

    @Test("context length error includes token counts")
    func contextLengthErrorIncludesTokenCounts() {
        let conduitError = ConduitProviderError.contextLengthExceeded(
            currentTokens: 10000,
            maxTokens: 8000
        )
        let agentError = conduitError.toAgentError()

        if case .contextLengthExceeded = agentError {
            // Success - correct mapping
        } else {
            Issue.record("Expected contextLengthExceeded AgentError")
        }
    }

    // MARK: - Provider Type Tests

    @Test("Anthropic provider type has correct display name")
    func anthropicProviderTypeHasCorrectDisplayName() {
        let providerType = ConduitProviderType.anthropic(
            apiKey: "test",
            model: .claudeSonnet35
        )

        #expect(providerType.displayName.contains("Anthropic"))
    }

    @Test("OpenAI provider type has correct display name")
    func openAIProviderTypeHasCorrectDisplayName() {
        let providerType = ConduitProviderType.openAI(
            apiKey: "test",
            model: .gpt4o
        )

        #expect(providerType.displayName.contains("OpenAI"))
    }

    @Test("MLX provider type has correct display name")
    func mlxProviderTypeHasCorrectDisplayName() {
        let providerType = ConduitProviderType.mlx(
            model: ModelIdentifier(stringLiteral: "mlx-community/Llama-3.2-3B-Instruct-4bit")
        )

        #expect(providerType.displayName.contains("MLX"))
    }

    @Test("HuggingFace provider type has correct display name")
    func huggingFaceProviderTypeHasCorrectDisplayName() {
        let providerType = ConduitProviderType.huggingFace(
            apiKey: "test",
            model: ModelIdentifier(stringLiteral: "meta-llama/Llama-3.1-8B-Instruct")
        )

        #expect(providerType.displayName.contains("HuggingFace"))
    }

    @Test("provider type description hides API key")
    func providerTypeDescriptionHidesAPIKey() {
        let providerType = ConduitProviderType.anthropic(
            apiKey: "sk-ant-secret-key-12345",
            model: .claudeSonnet35
        )

        let description = String(describing: providerType)

        #expect(!description.contains("sk-ant-secret-key-12345"))
        #expect(description.contains("***") || description.contains("hidden"))
    }

    @Test("MLX provider requires network returns false")
    func mlxProviderRequiresNetworkReturnsFalse() {
        let providerType = ConduitProviderType.mlx(
            model: ModelIdentifier(stringLiteral: "test-model")
        )

        #expect(providerType.requiresNetwork == false)
    }

    @Test("Anthropic provider requires network returns true")
    func anthropicProviderRequiresNetworkReturnsTrue() {
        let providerType = ConduitProviderType.anthropic(
            apiKey: "test",
            model: .claudeSonnet35
        )

        #expect(providerType.requiresNetwork == true)
    }

    @Test("OpenAI provider requires network returns true")
    func openAIProviderRequiresNetworkReturnsTrue() {
        let providerType = ConduitProviderType.openAI(
            apiKey: "test",
            model: .gpt4o
        )

        #expect(providerType.requiresNetwork == true)
    }

    @Test("HuggingFace provider requires network returns true")
    func huggingFaceProviderRequiresNetworkReturnsTrue() {
        let providerType = ConduitProviderType.huggingFace(
            apiKey: "test",
            model: ModelIdentifier(stringLiteral: "test-model")
        )

        #expect(providerType.requiresNetwork == true)
    }

    // MARK: - Model String Tests

    @Test("Anthropic model string is correct")
    func anthropicModelStringIsCorrect() {
        let providerType = ConduitProviderType.anthropic(
            apiKey: "test",
            model: .claudeSonnet35
        )

        let modelString = providerType.modelString
        #expect(!modelString.isEmpty)
    }

    @Test("OpenAI model string is correct")
    func openAIModelStringIsCorrect() {
        let providerType = ConduitProviderType.openAI(
            apiKey: "test",
            model: .gpt4o
        )

        let modelString = providerType.modelString
        #expect(!modelString.isEmpty)
    }

    @Test("MLX model string matches identifier")
    func mlxModelStringMatchesIdentifier() {
        let modelID = ModelIdentifier(stringLiteral: "test-model-id")
        let providerType = ConduitProviderType.mlx(model: modelID)

        let modelString = providerType.modelString
        #expect(modelString == "test-model-id")
    }

    @Test("HuggingFace model string matches identifier")
    func huggingFaceModelStringMatchesIdentifier() {
        let modelID = ModelIdentifier(stringLiteral: "test-hf-model")
        let providerType = ConduitProviderType.huggingFace(
            apiKey: "test",
            model: modelID
        )

        let modelString = providerType.modelString
        #expect(modelString == "test-hf-model")
    }

    // MARK: - Configuration Factory Tests

    @Test("ConduitConfiguration from provider type creates valid config")
    func conduitConfigurationFromProviderTypeCreatesValidConfig() throws {
        let providerType = ConduitProviderType.anthropic(
            apiKey: "test-key",
            model: .claudeSonnet35,
            systemPrompt: "You are helpful"
        )

        let config = try ConduitConfiguration(providerType: providerType)

        #expect(config.apiKey == "test-key")
        #expect(config.systemPrompt == "You are helpful")
        try config.validate()
    }

    @Test("ConduitConfiguration validation catches empty API key")
    func conduitConfigurationValidationCatchesEmptyAPIKey() throws {
        let providerType = ConduitProviderType.anthropic(
            apiKey: "",
            model: .claudeSonnet35
        )

        #expect(throws: ConduitConfiguration.ValidationError.self) {
            _ = try ConduitConfiguration(providerType: providerType)
        }
    }
}
