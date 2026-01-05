// ConduitConfigurationTests.swift
// SwiftAgentsTests
//
// Comprehensive tests for ConduitConfiguration validation and factory methods.

import Foundation
@testable import SwiftAgents
import Testing

@Suite("ConduitConfiguration Tests")
struct ConduitConfigurationTests {
    // MARK: - Validation Tests

    @Test("valid configuration passes validation")
    func validConfigurationPassesValidation() throws {
        let config = ConduitConfiguration(
            apiKey: "test-api-key",
            timeout: 30,
            maxRetries: 3,
            temperature: 0.7,
            topP: 0.9,
            topK: 50,
            retryStrategy: .default
        )

        try config.validate()
        // No error thrown means success
    }

    @Test("empty API key throws invalidAPIKey")
    func emptyAPIKeyThrowsError() throws {
        let config = ConduitConfiguration(
            apiKey: "",
            timeout: 30,
            maxRetries: 3
        )

        #expect(throws: ConduitConfiguration.ValidationError.invalidAPIKey) {
            try config.validate()
        }
    }

    @Test("whitespace-only API key throws invalidAPIKey")
    func whitespaceOnlyAPIKeyThrowsError() throws {
        let config = ConduitConfiguration(
            apiKey: "   ",
            timeout: 30,
            maxRetries: 3
        )

        #expect(throws: ConduitConfiguration.ValidationError.invalidAPIKey) {
            try config.validate()
        }
    }

    @Test("negative timeout throws invalidTimeout")
    func negativeTimeoutThrowsError() throws {
        let config = ConduitConfiguration(
            apiKey: "test-key",
            timeout: -1,
            maxRetries: 3
        )

        #expect(throws: ConduitConfiguration.ValidationError.invalidTimeout) {
            try config.validate()
        }
    }

    @Test("zero timeout throws invalidTimeout")
    func zeroTimeoutThrowsError() throws {
        let config = ConduitConfiguration(
            apiKey: "test-key",
            timeout: 0,
            maxRetries: 3
        )

        #expect(throws: ConduitConfiguration.ValidationError.invalidTimeout) {
            try config.validate()
        }
    }

    @Test("negative max retries throws invalidMaxRetries")
    func negativeMaxRetriesThrowsError() throws {
        let config = ConduitConfiguration(
            apiKey: "test-key",
            timeout: 30,
            maxRetries: -1
        )

        #expect(throws: ConduitConfiguration.ValidationError.invalidMaxRetries) {
            try config.validate()
        }
    }

    @Test("temperature below 0 throws invalidTemperature")
    func temperatureBelowZeroThrowsError() throws {
        let config = ConduitConfiguration(
            apiKey: "test-key",
            timeout: 30,
            maxRetries: 3,
            temperature: -0.1
        )

        #expect(throws: ConduitConfiguration.ValidationError.invalidTemperature) {
            try config.validate()
        }
    }

    @Test("temperature above 2 throws invalidTemperature")
    func temperatureAboveTwoThrowsError() throws {
        let config = ConduitConfiguration(
            apiKey: "test-key",
            timeout: 30,
            maxRetries: 3,
            temperature: 2.1
        )

        #expect(throws: ConduitConfiguration.ValidationError.invalidTemperature) {
            try config.validate()
        }
    }

    @Test("topP below 0 throws invalidTopP")
    func topPBelowZeroThrowsError() throws {
        let config = ConduitConfiguration(
            apiKey: "test-key",
            timeout: 30,
            maxRetries: 3,
            topP: -0.1
        )

        #expect(throws: ConduitConfiguration.ValidationError.invalidTopP) {
            try config.validate()
        }
    }

    @Test("topP above 1 throws invalidTopP")
    func topPAboveOneThrowsError() throws {
        let config = ConduitConfiguration(
            apiKey: "test-key",
            timeout: 30,
            maxRetries: 3,
            topP: 1.1
        )

        #expect(throws: ConduitConfiguration.ValidationError.invalidTopP) {
            try config.validate()
        }
    }

    @Test("negative topK throws invalidTopK")
    func negativeTopKThrowsError() throws {
        let config = ConduitConfiguration(
            apiKey: "test-key",
            timeout: 30,
            maxRetries: 3,
            topK: -1
        )

        #expect(throws: ConduitConfiguration.ValidationError.invalidTopK) {
            try config.validate()
        }
    }

    // MARK: - Factory Method Tests

    @Test("anthropic factory creates valid configuration")
    func anthropicFactoryCreatesValidConfiguration() throws {
        let config = ConduitConfiguration.anthropic(apiKey: "test-anthropic-key")

        #expect(config.apiKey == "test-anthropic-key")
        try config.validate()
    }

    @Test("openAI factory creates valid configuration")
    func openAIFactoryCreatesValidConfiguration() throws {
        let config = ConduitConfiguration.openAI(apiKey: "test-openai-key")

        #expect(config.apiKey == "test-openai-key")
        try config.validate()
    }

    @Test("mlx factory creates valid configuration")
    func mlxFactoryCreatesValidConfiguration() throws {
        let config = ConduitConfiguration.mlx()

        #expect(config.apiKey == "local")
        try config.validate()
    }

    @Test("huggingFace factory creates valid configuration")
    func huggingFaceFactoryCreatesValidConfiguration() throws {
        let config = ConduitConfiguration.huggingFace(apiKey: "test-hf-key")

        #expect(config.apiKey == "test-hf-key")
        try config.validate()
    }

    // MARK: - Retry Strategy Tests

    @Test("default retry strategy has sensible values")
    func defaultRetryStrategyHasSensibleValues() {
        let strategy = ConduitConfiguration.RetryStrategy.default

        #expect(strategy.maxRetries == 3)
        #expect(strategy.initialDelay == 1.0)
        #expect(strategy.maxDelay == 60.0)
        #expect(strategy.multiplier == 2.0)
    }

    @Test("none retry strategy has zero retries")
    func noneRetryStrategyHasZeroRetries() {
        let strategy = ConduitConfiguration.RetryStrategy.none

        #expect(strategy.maxRetries == 0)
    }

    @Test("aggressive retry strategy has high retry count")
    func aggressiveRetryStrategyHasHighRetryCount() {
        let strategy = ConduitConfiguration.RetryStrategy.aggressive

        #expect(strategy.maxRetries == 5)
    }

    @Test("custom retry strategy allows configuration")
    func customRetryStrategyAllowsConfiguration() {
        let strategy = ConduitConfiguration.RetryStrategy.custom(
            maxRetries: 10,
            initialDelay: 2.0,
            maxDelay: 120.0,
            multiplier: 3.0
        )

        #expect(strategy.maxRetries == 10)
        #expect(strategy.initialDelay == 2.0)
        #expect(strategy.maxDelay == 120.0)
        #expect(strategy.multiplier == 3.0)
    }

    // MARK: - Equatable Tests

    @Test("identical configurations are equal")
    func identicalConfigurationsAreEqual() {
        let config1 = ConduitConfiguration(
            apiKey: "test-key",
            timeout: 30,
            maxRetries: 3,
            temperature: 0.7
        )

        let config2 = ConduitConfiguration(
            apiKey: "test-key",
            timeout: 30,
            maxRetries: 3,
            temperature: 0.7
        )

        #expect(config1 == config2)
    }

    @Test("different API keys make configurations not equal")
    func differentAPIKeysMakeConfigurationsNotEqual() {
        let config1 = ConduitConfiguration(apiKey: "key1", timeout: 30, maxRetries: 3)
        let config2 = ConduitConfiguration(apiKey: "key2", timeout: 30, maxRetries: 3)

        #expect(config1 != config2)
    }

    @Test("different temperatures make configurations not equal")
    func differentTemperaturesMakeConfigurationsNotEqual() {
        let config1 = ConduitConfiguration(
            apiKey: "test-key",
            timeout: 30,
            maxRetries: 3,
            temperature: 0.7
        )
        let config2 = ConduitConfiguration(
            apiKey: "test-key",
            timeout: 30,
            maxRetries: 3,
            temperature: 0.8
        )

        #expect(config1 != config2)
    }

    // MARK: - Edge Cases

    @Test("maximum valid temperature is accepted")
    func maximumValidTemperatureIsAccepted() throws {
        let config = ConduitConfiguration(
            apiKey: "test-key",
            timeout: 30,
            maxRetries: 3,
            temperature: 2.0
        )

        try config.validate()
    }

    @Test("minimum valid temperature is accepted")
    func minimumValidTemperatureIsAccepted() throws {
        let config = ConduitConfiguration(
            apiKey: "test-key",
            timeout: 30,
            maxRetries: 3,
            temperature: 0.0
        )

        try config.validate()
    }

    @Test("nil optional parameters are accepted")
    func nilOptionalParametersAreAccepted() throws {
        let config = ConduitConfiguration(
            apiKey: "test-key",
            timeout: 30,
            maxRetries: 3,
            temperature: nil,
            topP: nil,
            topK: nil
        )

        try config.validate()
    }
}
