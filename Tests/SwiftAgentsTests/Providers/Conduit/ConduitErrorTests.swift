// ConduitErrorTests.swift
// SwiftAgentsTests
//
// Tests for ConduitProviderError and error mapping functionality.

import Foundation
@testable import SwiftAgents
import Testing
import Conduit

@Suite("ConduitError Tests")
struct ConduitErrorTests {
    // MARK: - Error Mapping to AgentError Tests

    @Test("invalidInput maps to AgentError.invalidInput")
    func invalidInputMapsToAgentError() {
        let conduitError = ConduitProviderError.invalidInput(reason: "Test invalid input")
        let agentError = conduitError.toAgentError()

        if case .invalidInput(let reason) = agentError {
            #expect(reason == "Test invalid input")
        } else {
            Issue.record("Expected invalidInput, got \(agentError)")
        }
    }

    @Test("rateLimitExceeded maps to AgentError.rateLimitExceeded")
    func rateLimitExceededMapsToAgentError() {
        let conduitError = ConduitProviderError.rateLimitExceeded(retryAfter: 60)
        let agentError = conduitError.toAgentError()

        if case .rateLimitExceeded(let retryAfter) = agentError {
            #expect(retryAfter == 60)
        } else {
            Issue.record("Expected rateLimitExceeded, got \(agentError)")
        }
    }

    @Test("authenticationFailed maps to AgentError.inferenceProviderError")
    func authenticationFailedMapsToAgentError() {
        let conduitError = ConduitProviderError.authenticationFailed(reason: "Invalid API key")
        let agentError = conduitError.toAgentError()

        if case .inferenceProviderError(let description) = agentError {
            #expect(description.contains("Invalid API key"))
        } else {
            Issue.record("Expected inferenceProviderError, got \(agentError)")
        }
    }

    @Test("networkError maps to AgentError.inferenceProviderError")
    func networkErrorMapsToAgentError() {
        let networkError = NSError(domain: "test", code: -1, userInfo: nil)
        let conduitError = ConduitProviderError.networkError(networkError)
        let agentError = conduitError.toAgentError()

        if case .inferenceProviderError = agentError {
            // Success - correct mapping
        } else {
            Issue.record("Expected inferenceProviderError, got \(agentError)")
        }
    }

    @Test("contextLengthExceeded maps to AgentError.contextLengthExceeded")
    func contextLengthExceededMapsToAgentError() {
        let conduitError = ConduitProviderError.contextLengthExceeded(
            currentTokens: 10000,
            maxTokens: 8000
        )
        let agentError = conduitError.toAgentError()

        if case .contextLengthExceeded = agentError {
            // Success - correct mapping
        } else {
            Issue.record("Expected contextLengthExceeded, got \(agentError)")
        }
    }

    @Test("inferenceProviderUnavailable maps to AgentError.inferenceProviderUnavailable")
    func inferenceProviderUnavailableMapsToAgentError() {
        let conduitError = ConduitProviderError.inferenceProviderUnavailable(reason: "Provider offline")
        let agentError = conduitError.toAgentError()

        if case .inferenceProviderUnavailable(let reason) = agentError {
            #expect(reason == "Provider offline")
        } else {
            Issue.record("Expected inferenceProviderUnavailable, got \(agentError)")
        }
    }

    // MARK: - AIError Mapping Tests

    @Test("AIError.invalidRequest maps correctly")
    func aiErrorInvalidRequestMapsCorrectly() {
        let aiError = AIError.invalidRequest(message: "Bad request")
        let conduitError = ConduitProviderError.fromAIError(aiError)

        if case .invalidInput(let reason) = conduitError {
            #expect(reason.contains("Bad request"))
        } else {
            Issue.record("Expected invalidInput, got \(conduitError)")
        }
    }

    @Test("AIError.authenticationFailed maps correctly")
    func aiErrorAuthenticationFailedMapsCorrectly() {
        let aiError = AIError.authenticationFailed(message: "Auth failed")
        let conduitError = ConduitProviderError.fromAIError(aiError)

        if case .authenticationFailed(let reason) = conduitError {
            #expect(reason.contains("Auth failed"))
        } else {
            Issue.record("Expected authenticationFailed, got \(conduitError)")
        }
    }

    @Test("AIError.rateLimitExceeded maps with retry hint")
    func aiErrorRateLimitExceededMapsWithRetryHint() {
        let aiError = AIError.rateLimitExceeded(
            message: "Rate limit hit",
            retryAfter: 120
        )
        let conduitError = ConduitProviderError.fromAIError(aiError)

        if case .rateLimitExceeded(let retryAfter) = conduitError {
            #expect(retryAfter == 120)
        } else {
            Issue.record("Expected rateLimitExceeded with retry hint, got \(conduitError)")
        }
    }

    @Test("AIError.rateLimitExceeded without retry hint defaults to nil")
    func aiErrorRateLimitExceededWithoutRetryHintDefaultsToNil() {
        let aiError = AIError.rateLimitExceeded(message: "Rate limit hit", retryAfter: nil)
        let conduitError = ConduitProviderError.fromAIError(aiError)

        if case .rateLimitExceeded(let retryAfter) = conduitError {
            #expect(retryAfter == nil)
        } else {
            Issue.record("Expected rateLimitExceeded, got \(conduitError)")
        }
    }

    @Test("AIError.serverError maps correctly")
    func aiErrorServerErrorMapsCorrectly() {
        let aiError = AIError.serverError(message: "Internal error", statusCode: 500)
        let conduitError = ConduitProviderError.fromAIError(aiError)

        if case .serverError(let statusCode, _) = conduitError {
            #expect(statusCode == 500)
        } else {
            Issue.record("Expected serverError, got \(conduitError)")
        }
    }

    @Test("AIError.contextLengthExceeded maps with token counts")
    func aiErrorContextLengthExceededMapsWithTokenCounts() {
        let aiError = AIError.contextLengthExceeded(
            currentTokens: 5000,
            maxTokens: 4096
        )
        let conduitError = ConduitProviderError.fromAIError(aiError)

        if case .contextLengthExceeded(let current, let max) = conduitError {
            #expect(current == 5000)
            #expect(max == 4096)
        } else {
            Issue.record("Expected contextLengthExceeded, got \(conduitError)")
        }
    }

    @Test("AIError.modelNotFound maps correctly")
    func aiErrorModelNotFoundMapsCorrectly() {
        let aiError = AIError.modelNotFound(modelID: "gpt-5")
        let conduitError = ConduitProviderError.fromAIError(aiError)

        if case .modelNotAvailable(let modelID) = conduitError {
            #expect(modelID == "gpt-5")
        } else {
            Issue.record("Expected modelNotAvailable, got \(conduitError)")
        }
    }

    @Test("AIError.unsupportedFeature maps correctly")
    func aiErrorUnsupportedFeatureMapsCorrectly() {
        let aiError = AIError.unsupportedFeature(feature: "vision")
        let conduitError = ConduitProviderError.fromAIError(aiError)

        if case .unsupportedFeature(let feature) = conduitError {
            #expect(feature == "vision")
        } else {
            Issue.record("Expected unsupportedFeature, got \(conduitError)")
        }
    }

    // MARK: - LocalizedError Tests

    @Test("invalidInput provides localized description")
    func invalidInputProvidesLocalizedDescription() {
        let error = ConduitProviderError.invalidInput(reason: "Test reason")
        let description = error.errorDescription

        #expect(description != nil)
        #expect(description!.contains("Test reason"))
    }

    @Test("rateLimitExceeded provides localized description with retry hint")
    func rateLimitExceededProvidesLocalizedDescriptionWithRetryHint() {
        let error = ConduitProviderError.rateLimitExceeded(retryAfter: 60)
        let description = error.errorDescription

        #expect(description != nil)
        #expect(description!.contains("60"))
    }

    @Test("contextLengthExceeded provides localized description with counts")
    func contextLengthExceededProvidesLocalizedDescriptionWithCounts() {
        let error = ConduitProviderError.contextLengthExceeded(
            currentTokens: 10000,
            maxTokens: 8000
        )
        let description = error.errorDescription

        #expect(description != nil)
        #expect(description!.contains("10000") || description!.contains("10,000"))
        #expect(description!.contains("8000") || description!.contains("8,000"))
    }

    // MARK: - Equatable Tests

    @Test("identical errors are equal")
    func identicalErrorsAreEqual() {
        let error1 = ConduitProviderError.invalidInput(reason: "Test")
        let error2 = ConduitProviderError.invalidInput(reason: "Test")

        #expect(error1 == error2)
    }

    @Test("different error types are not equal")
    func differentErrorTypesAreNotEqual() {
        let error1 = ConduitProviderError.invalidInput(reason: "Test")
        let error2 = ConduitProviderError.rateLimitExceeded(retryAfter: nil)

        #expect(error1 != error2)
    }

    @Test("same error type with different values are not equal")
    func sameErrorTypeWithDifferentValuesAreNotEqual() {
        let error1 = ConduitProviderError.invalidInput(reason: "Reason 1")
        let error2 = ConduitProviderError.invalidInput(reason: "Reason 2")

        #expect(error1 != error2)
    }
}
