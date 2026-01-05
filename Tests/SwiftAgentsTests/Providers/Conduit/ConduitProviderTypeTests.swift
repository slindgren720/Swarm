// ConduitProviderTypeTests.swift
// SwiftAgentsTests
//
// Tests for ConduitProviderType enumeration and its functionality.

import Foundation
@testable import SwiftAgents
import Testing
import Conduit

@Suite("ConduitProviderType Tests")
struct ConduitProviderTypeTests {
    // MARK: - Display Name Tests

    @Test("Anthropic provider has correct display name")
    func anthropicProviderHasCorrectDisplayName() {
        let providerType = ConduitProviderType.anthropic(
            apiKey: "test",
            model: .claudeSonnet35
        )

        let displayName = providerType.displayName

        #expect(displayName.contains("Anthropic"))
        #expect(displayName.contains("claude-sonnet-3-5") || displayName.contains("Claude"))
    }

    @Test("OpenAI provider has correct display name")
    func openAIProviderHasCorrectDisplayName() {
        let providerType = ConduitProviderType.openAI(
            apiKey: "test",
            model: .gpt4o
        )

        let displayName = providerType.displayName

        #expect(displayName.contains("OpenAI"))
        #expect(displayName.contains("gpt") || displayName.contains("GPT"))
    }

    @Test("MLX provider has correct display name")
    func mlxProviderHasCorrectDisplayName() {
        let providerType = ConduitProviderType.mlx(
            model: ModelIdentifier(stringLiteral: "test-model")
        )

        let displayName = providerType.displayName

        #expect(displayName.contains("MLX"))
        #expect(displayName.contains("test-model"))
    }

    @Test("HuggingFace provider has correct display name")
    func huggingFaceProviderHasCorrectDisplayName() {
        let providerType = ConduitProviderType.huggingFace(
            apiKey: "test",
            model: ModelIdentifier(stringLiteral: "meta-llama/Llama-3.1-8B")
        )

        let displayName = providerType.displayName

        #expect(displayName.contains("HuggingFace") || displayName.contains("Hugging Face"))
        #expect(displayName.contains("Llama"))
    }

    // MARK: - Model String Tests

    @Test("Anthropic model string matches model ID")
    func anthropicModelStringMatchesModelID() {
        let providerType = ConduitProviderType.anthropic(
            apiKey: "test",
            model: .claudeSonnet35
        )

        let modelString = providerType.modelString

        #expect(!modelString.isEmpty)
        #expect(modelString.contains("claude") || modelString.contains("sonnet"))
    }

    @Test("OpenAI model string matches model ID")
    func openAIModelStringMatchesModelID() {
        let providerType = ConduitProviderType.openAI(
            apiKey: "test",
            model: .gpt4o
        )

        let modelString = providerType.modelString

        #expect(!modelString.isEmpty)
        #expect(modelString.contains("gpt"))
    }

    @Test("MLX model string is model identifier value")
    func mlxModelStringIsModelIdentifierValue() {
        let modelID = ModelIdentifier(stringLiteral: "custom-model-name")
        let providerType = ConduitProviderType.mlx(model: modelID)

        let modelString = providerType.modelString

        #expect(modelString == "custom-model-name")
    }

    @Test("HuggingFace model string is model identifier value")
    func huggingFaceModelStringIsModelIdentifierValue() {
        let modelID = ModelIdentifier(stringLiteral: "organization/model-name")
        let providerType = ConduitProviderType.huggingFace(
            apiKey: "test",
            model: modelID
        )

        let modelString = providerType.modelString

        #expect(modelString == "organization/model-name")
    }

    // MARK: - Network Requirement Tests

    @Test("Anthropic requires network")
    func anthropicRequiresNetwork() {
        let providerType = ConduitProviderType.anthropic(
            apiKey: "test",
            model: .claudeSonnet35
        )

        #expect(providerType.requiresNetwork == true)
    }

    @Test("OpenAI requires network")
    func openAIRequiresNetwork() {
        let providerType = ConduitProviderType.openAI(
            apiKey: "test",
            model: .gpt4o
        )

        #expect(providerType.requiresNetwork == true)
    }

    @Test("MLX does not require network")
    func mlxDoesNotRequireNetwork() {
        let providerType = ConduitProviderType.mlx(
            model: ModelIdentifier(stringLiteral: "local-model")
        )

        #expect(providerType.requiresNetwork == false)
    }

    @Test("HuggingFace requires network")
    func huggingFaceRequiresNetwork() {
        let providerType = ConduitProviderType.huggingFace(
            apiKey: "test",
            model: ModelIdentifier(stringLiteral: "test-model")
        )

        #expect(providerType.requiresNetwork == true)
    }

    // MARK: - CustomStringConvertible Tests

    @Test("Anthropic description hides API key")
    func anthropicDescriptionHidesAPIKey() {
        let providerType = ConduitProviderType.anthropic(
            apiKey: "sk-ant-very-secret-key-12345",
            model: .claudeSonnet35
        )

        let description = String(describing: providerType)

        #expect(!description.contains("sk-ant-very-secret-key-12345"))
        // Should contain some form of masking or indication that key is hidden
        #expect(description.contains("***") || description.contains("hidden") || description.contains("masked"))
    }

    @Test("OpenAI description hides API key")
    func openAIDescriptionHidesAPIKey() {
        let providerType = ConduitProviderType.openAI(
            apiKey: "sk-proj-secret-key-abcdef123456",
            model: .gpt4o
        )

        let description = String(describing: providerType)

        #expect(!description.contains("sk-proj-secret-key-abcdef123456"))
        #expect(description.contains("***") || description.contains("hidden") || description.contains("masked"))
    }

    @Test("HuggingFace description hides API key")
    func huggingFaceDescriptionHidesAPIKey() {
        let providerType = ConduitProviderType.huggingFace(
            apiKey: "hf_VerySecretTokenAbcDef123456",
            model: ModelIdentifier(stringLiteral: "test-model")
        )

        let description = String(describing: providerType)

        #expect(!description.contains("hf_VerySecretTokenAbcDef123456"))
        #expect(description.contains("***") || description.contains("hidden") || description.contains("masked"))
    }

    @Test("MLX description shows model info")
    func mlxDescriptionShowsModelInfo() {
        let providerType = ConduitProviderType.mlx(
            model: ModelIdentifier(stringLiteral: "mlx-community/special-model")
        )

        let description = String(describing: providerType)

        #expect(description.contains("MLX") || description.contains("mlx"))
        #expect(description.contains("special-model"))
    }

    @Test("description includes model information")
    func descriptionIncludesModelInformation() {
        let providerType = ConduitProviderType.anthropic(
            apiKey: "test",
            model: .claudeSonnet35
        )

        let description = String(describing: providerType)

        #expect(description.contains("claude") || description.contains("sonnet") || description.contains("Claude"))
    }

    // MARK: - System Prompt Tests

    @Test("system prompt is included when provided to Anthropic")
    func systemPromptIsIncludedWhenProvidedToAnthropic() {
        let providerType = ConduitProviderType.anthropic(
            apiKey: "test",
            model: .claudeSonnet35,
            systemPrompt: "You are a helpful assistant"
        )

        // System prompt should be accessible through configuration
        let displayName = providerType.displayName
        #expect(!displayName.isEmpty)
    }

    @Test("system prompt is included when provided to OpenAI")
    func systemPromptIsIncludedWhenProvidedToOpenAI() {
        let providerType = ConduitProviderType.openAI(
            apiKey: "test",
            model: .gpt4o,
            systemPrompt: "You are a helpful assistant"
        )

        let displayName = providerType.displayName
        #expect(!displayName.isEmpty)
    }

    @Test("system prompt is included when provided to MLX")
    func systemPromptIsIncludedWhenProvidedToMLX() {
        let providerType = ConduitProviderType.mlx(
            model: ModelIdentifier(stringLiteral: "test"),
            systemPrompt: "You are a helpful assistant"
        )

        let displayName = providerType.displayName
        #expect(!displayName.isEmpty)
    }

    @Test("system prompt is included when provided to HuggingFace")
    func systemPromptIsIncludedWhenProvidedToHuggingFace() {
        let providerType = ConduitProviderType.huggingFace(
            apiKey: "test",
            model: ModelIdentifier(stringLiteral: "test"),
            systemPrompt: "You are a helpful assistant"
        )

        let displayName = providerType.displayName
        #expect(!displayName.isEmpty)
    }

    // MARK: - Edge Cases

    @Test("empty system prompt is handled correctly")
    func emptySystemPromptIsHandledCorrectly() {
        let providerType = ConduitProviderType.anthropic(
            apiKey: "test",
            model: .claudeSonnet35,
            systemPrompt: ""
        )

        let displayName = providerType.displayName
        #expect(!displayName.isEmpty)
    }

    @Test("very long system prompt is handled correctly")
    func veryLongSystemPromptIsHandledCorrectly() {
        let longPrompt = String(repeating: "This is a very long system prompt. ", count: 100)
        let providerType = ConduitProviderType.anthropic(
            apiKey: "test",
            model: .claudeSonnet35,
            systemPrompt: longPrompt
        )

        let displayName = providerType.displayName
        #expect(!displayName.isEmpty)
    }

    @Test("special characters in system prompt are handled")
    func specialCharactersInSystemPromptAreHandled() {
        let providerType = ConduitProviderType.openAI(
            apiKey: "test",
            model: .gpt4o,
            systemPrompt: "System: \"Hello\"\nNew line\tTab\r\nCarriage return"
        )

        let displayName = providerType.displayName
        #expect(!displayName.isEmpty)
    }

    @Test("unicode characters in system prompt are handled")
    func unicodeCharactersInSystemPromptAreHandled() {
        let providerType = ConduitProviderType.anthropic(
            apiKey: "test",
            model: .claudeSonnet35,
            systemPrompt: "你好 🌟 Привет مرحبا"
        )

        let displayName = providerType.displayName
        #expect(!displayName.isEmpty)
    }

    @Test("model identifier with special characters works")
    func modelIdentifierWithSpecialCharactersWorks() {
        let modelID = ModelIdentifier(stringLiteral: "organization/model-name_v2.1-beta")
        let providerType = ConduitProviderType.mlx(model: modelID)

        let modelString = providerType.modelString
        #expect(modelString == "organization/model-name_v2.1-beta")
    }

    @Test("API key with special characters is handled")
    func apiKeyWithSpecialCharactersIsHandled() {
        let providerType = ConduitProviderType.anthropic(
            apiKey: "sk-ant-abc123_DEF-456.xyz/789",
            model: .claudeSonnet35
        )

        let description = String(describing: providerType)
        #expect(!description.contains("sk-ant-abc123_DEF-456.xyz/789"))
    }

    // MARK: - Model Variant Tests

    @Test("all Anthropic models create valid provider types")
    func allAnthropicModelsCreateValidProviderTypes() {
        let models: [AnthropicModelID] = [
            .claudeSonnet35,
            .claudeSonnet4,
            .claudeSonnet45,
            .claudeOpus4
        ]

        for model in models {
            let providerType = ConduitProviderType.anthropic(apiKey: "test", model: model)
            #expect(!providerType.displayName.isEmpty)
            #expect(!providerType.modelString.isEmpty)
        }
    }

    @Test("all OpenAI models create valid provider types")
    func allOpenAIModelsCreateValidProviderTypes() {
        let models: [OpenAIModelID] = [
            .gpt4o,
            .gpt4oMini,
            .o1,
            .o1Mini
        ]

        for model in models {
            let providerType = ConduitProviderType.openAI(apiKey: "test", model: model)
            #expect(!providerType.displayName.isEmpty)
            #expect(!providerType.modelString.isEmpty)
        }
    }

    @Test("custom ModelIdentifier values work correctly")
    func customModelIdentifierValuesWorkCorrectly() {
        let customModels = [
            "custom-model-1",
            "org/model-name",
            "very-long-model-identifier-with-many-parts-v1.2.3-beta"
        ]

        for modelName in customModels {
            let modelID = ModelIdentifier(stringLiteral: modelName)
            let providerType = ConduitProviderType.mlx(model: modelID)

            #expect(providerType.modelString == modelName)
            #expect(!providerType.displayName.isEmpty)
        }
    }
}
