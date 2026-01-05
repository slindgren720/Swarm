// ConduitTypeMappersTests.swift
// SwiftAgentsTests
//
// Tests for type mapping between SwiftAgents and Conduit types.

import Foundation
@testable import SwiftAgents
import Testing
import Conduit

@Suite("ConduitTypeMappers Tests")
struct ConduitTypeMappersTests {
    // MARK: - InferenceOptions to GenerateConfig Tests

    @Test("toConduitConfig converts basic options correctly")
    func toConduitConfigConvertsBasicOptionsCorrectly() {
        let options = InferenceOptions(
            temperature: 0.7,
            maxTokens: 1000,
            stopSequences: ["STOP"],
            topP: 0.9,
            topK: 50
        )

        let config = options.toConduitConfig()

        #expect(config.temperature == Float(0.7))
        #expect(config.maxTokens == 1000)
        #expect(config.stopSequences == ["STOP"])
        #expect(config.topP == Float(0.9))
        #expect(config.topK == 50)
    }

    @Test("toConduitConfig handles nil topP with default")
    func toConduitConfigHandlesNilTopPWithDefault() {
        let options = InferenceOptions(temperature: 0.7, maxTokens: 1000, topP: nil)

        let config = options.toConduitConfig()

        #expect(config.topP == 0.9) // Default value
    }

    @Test("toConduitConfig converts penalties correctly")
    func toConduitConfigConvertsPenaltiesCorrectly() {
        let options = InferenceOptions(
            temperature: 0.7,
            maxTokens: 1000,
            presencePenalty: 0.5,
            frequencyPenalty: 0.3
        )

        let config = options.toConduitConfig()

        #expect(config.presencePenalty == Float(0.5))
        #expect(config.frequencyPenalty == Float(0.3))
    }

    @Test("toConduitConfig handles nil penalties with defaults")
    func toConduitConfigHandlesNilPenaltiesWithDefaults() {
        let options = InferenceOptions(
            temperature: 0.7,
            maxTokens: 1000,
            presencePenalty: nil,
            frequencyPenalty: nil
        )

        let config = options.toConduitConfig()

        #expect(config.presencePenalty == 0.0)
        #expect(config.frequencyPenalty == 0.0)
    }

    @Test("from conduitConfig creates options correctly")
    func fromConduitConfigCreatesOptionsCorrectly() {
        let config = GenerateConfig(
            maxTokens: 1000,
            temperature: 0.7,
            topP: 0.9,
            topK: 50,
            frequencyPenalty: 0.3,
            presencePenalty: 0.5,
            stopSequences: ["STOP"]
        )

        let options = InferenceOptions.from(conduitConfig: config)

        #expect(options.temperature == Double(0.7))
        #expect(options.maxTokens == 1000)
        #expect(options.topP == Double(0.9))
        #expect(options.topK == 50)
        #expect(options.frequencyPenalty == Double(0.3))
        #expect(options.presencePenalty == Double(0.5))
        #expect(options.stopSequences == ["STOP"])
    }

    @Test("round trip conversion preserves values within precision")
    func roundTripConversionPreservesValuesWithinPrecision() {
        let original = InferenceOptions(
            temperature: 0.75,
            maxTokens: 2000,
            stopSequences: ["END"],
            topP: 0.95,
            topK: 40,
            presencePenalty: 0.6,
            frequencyPenalty: 0.4
        )

        let config = original.toConduitConfig()
        let result = InferenceOptions.from(conduitConfig: config)

        // Float precision means values may differ slightly but should be very close
        #expect(abs(result.temperature - original.temperature) < 0.0001)
        #expect(result.maxTokens == original.maxTokens)
        #expect(result.stopSequences == original.stopSequences)
        #expect(abs(result.topP! - original.topP!) < 0.0001)
        #expect(result.topK == original.topK)
    }

    // MARK: - FinishReason Mapping Tests

    @Test("FinishReason.stop maps to completed")
    func finishReasonStopMapsToCompleted() {
        let conduitReason = FinishReason.stop
        let agentsReason = conduitReason.toSwiftAgentsFinishReason()

        #expect(agentsReason == .completed)
    }

    @Test("FinishReason.length maps to maxTokens")
    func finishReasonLengthMapsToMaxTokens() {
        let conduitReason = FinishReason.length
        let agentsReason = conduitReason.toSwiftAgentsFinishReason()

        #expect(agentsReason == .maxTokens)
    }

    @Test("FinishReason.toolCalls maps to toolCall")
    func finishReasonToolCallsMapsToToolCall() {
        let conduitReason = FinishReason.toolCalls
        let agentsReason = conduitReason.toSwiftAgentsFinishReason()

        #expect(agentsReason == .toolCall)
    }

    @Test("FinishReason.contentFilter maps to contentFiltered")
    func finishReasonContentFilterMapsToContentFiltered() {
        let conduitReason = FinishReason.contentFilter
        let agentsReason = conduitReason.toSwiftAgentsFinishReason()

        #expect(agentsReason == .contentFiltered)
    }

    // MARK: - Usage Mapping Tests

    @Test("Usage converts to TokenUsage correctly")
    func usageConvertsToTokenUsageCorrectly() {
        let usage = Usage(
            inputTokens: 100,
            outputTokens: 50,
            totalTokens: 150
        )

        let tokenUsage = usage.toTokenUsage()

        #expect(tokenUsage.promptTokens == 100)
        #expect(tokenUsage.completionTokens == 50)
        #expect(tokenUsage.totalTokens == 150)
    }

    @Test("nil Usage maps to nil TokenUsage")
    func nilUsageMapsToNilTokenUsage() {
        let usage: Usage? = nil

        let tokenUsage = usage?.toTokenUsage()

        #expect(tokenUsage == nil)
    }

    // MARK: - StructuredContent Mapping Tests

    @Test("text StructuredContent maps to string SendableValue")
    func textStructuredContentMapsToStringSendableValue() throws {
        let content = StructuredContent.text("Hello, world!")
        let sendableValue = try content.toSendableValue()

        if case .string(let text) = sendableValue {
            #expect(text == "Hello, world!")
        } else {
            Issue.record("Expected string SendableValue, got \(sendableValue)")
        }
    }

    @Test("number StructuredContent with integer maps to int SendableValue")
    func numberStructuredContentWithIntegerMapsToIntSendableValue() throws {
        let content = StructuredContent.number(42.0)
        let sendableValue = try content.toSendableValue()

        if case .int(let value) = sendableValue {
            #expect(value == 42)
        } else {
            Issue.record("Expected int SendableValue, got \(sendableValue)")
        }
    }

    @Test("number StructuredContent with decimal maps to double SendableValue")
    func numberStructuredContentWithDecimalMapsToDoubleSendableValue() throws {
        let content = StructuredContent.number(42.5)
        let sendableValue = try content.toSendableValue()

        if case .double(let value) = sendableValue {
            #expect(value == 42.5)
        } else {
            Issue.record("Expected double SendableValue, got \(sendableValue)")
        }
    }

    @Test("boolean StructuredContent maps to bool SendableValue")
    func booleanStructuredContentMapsToBoolSendableValue() throws {
        let content = StructuredContent.boolean(true)
        let sendableValue = try content.toSendableValue()

        if case .bool(let value) = sendableValue {
            #expect(value == true)
        } else {
            Issue.record("Expected bool SendableValue, got \(sendableValue)")
        }
    }

    @Test("null StructuredContent maps to null SendableValue")
    func nullStructuredContentMapsToNullSendableValue() throws {
        let content = StructuredContent.null
        let sendableValue = try content.toSendableValue()

        if case .null = sendableValue {
            // Success
        } else {
            Issue.record("Expected null SendableValue, got \(sendableValue)")
        }
    }

    @Test("array StructuredContent maps to array SendableValue")
    func arrayStructuredContentMapsToArraySendableValue() throws {
        let content = StructuredContent.array([
            .text("item1"),
            .number(42),
            .boolean(true)
        ])

        let sendableValue = try content.toSendableValue()

        if case .array(let items) = sendableValue {
            #expect(items.count == 3)
        } else {
            Issue.record("Expected array SendableValue, got \(sendableValue)")
        }
    }

    @Test("object StructuredContent maps to dictionary SendableValue")
    func objectStructuredContentMapsToDictionarySendableValue() throws {
        let content = StructuredContent.object([
            "name": .text("John"),
            "age": .number(30)
        ])

        let sendableValue = try content.toSendableValue()

        if case .dictionary(let dict) = sendableValue {
            #expect(dict.count == 2)
            #expect(dict["name"] != nil)
            #expect(dict["age"] != nil)
        } else {
            Issue.record("Expected dictionary SendableValue, got \(sendableValue)")
        }
    }

    // MARK: - SendableValue to StructuredContent Tests

    @Test("string SendableValue maps to text StructuredContent")
    func stringSendableValueMapsToTextStructuredContent() {
        let value = SendableValue.string("Test")
        let content = value.toStructuredContent()

        if case .text(let text) = content {
            #expect(text == "Test")
        } else {
            Issue.record("Expected text StructuredContent, got \(content)")
        }
    }

    @Test("int SendableValue maps to number StructuredContent")
    func intSendableValueMapsToNumberStructuredContent() {
        let value = SendableValue.int(42)
        let content = value.toStructuredContent()

        if case .number(let num) = content {
            #expect(num == 42.0)
        } else {
            Issue.record("Expected number StructuredContent, got \(content)")
        }
    }

    @Test("double SendableValue maps to number StructuredContent")
    func doubleSendableValueMapsToNumberStructuredContent() {
        let value = SendableValue.double(42.5)
        let content = value.toStructuredContent()

        if case .number(let num) = content {
            #expect(num == 42.5)
        } else {
            Issue.record("Expected number StructuredContent, got \(content)")
        }
    }

    @Test("bool SendableValue maps to boolean StructuredContent")
    func boolSendableValueMapsToBooleanStructuredContent() {
        let value = SendableValue.bool(true)
        let content = value.toStructuredContent()

        if case .boolean(let bool) = content {
            #expect(bool == true)
        } else {
            Issue.record("Expected boolean StructuredContent, got \(content)")
        }
    }

    @Test("null SendableValue maps to null StructuredContent")
    func nullSendableValueMapsToNullStructuredContent() {
        let value = SendableValue.null
        let content = value.toStructuredContent()

        if case .null = content {
            // Success
        } else {
            Issue.record("Expected null StructuredContent, got \(content)")
        }
    }

    @Test("array SendableValue maps to array StructuredContent")
    func arraySendableValueMapsToArrayStructuredContent() {
        let value = SendableValue.array([
            .string("item"),
            .int(42)
        ])

        let content = value.toStructuredContent()

        if case .array(let items) = content {
            #expect(items.count == 2)
        } else {
            Issue.record("Expected array StructuredContent, got \(content)")
        }
    }

    @Test("dictionary SendableValue maps to object StructuredContent")
    func dictionarySendableValueMapsToObjectStructuredContent() {
        let value = SendableValue.dictionary([
            "key": .string("value")
        ])

        let content = value.toStructuredContent()

        if case .object(let dict) = content {
            #expect(dict.count == 1)
            #expect(dict["key"] != nil)
        } else {
            Issue.record("Expected object StructuredContent, got \(content)")
        }
    }

    // MARK: - Round Trip Tests

    @Test("StructuredContent round trip preserves text")
    func structuredContentRoundTripPreservesText() throws {
        let original = StructuredContent.text("Hello")
        let sendable = try original.toSendableValue()
        let result = sendable.toStructuredContent()

        if case .text(let text) = result {
            #expect(text == "Hello")
        } else {
            Issue.record("Round trip failed for text")
        }
    }

    @Test("StructuredContent round trip preserves nested structures")
    func structuredContentRoundTripPreservesNestedStructures() throws {
        let original = StructuredContent.object([
            "user": .object([
                "name": .text("John"),
                "age": .number(30),
                "active": .boolean(true)
            ]),
            "items": .array([
                .text("item1"),
                .number(42)
            ])
        ])

        let sendable = try original.toSendableValue()
        let result = sendable.toStructuredContent()

        if case .object(let dict) = result {
            #expect(dict.count == 2)
            #expect(dict["user"] != nil)
            #expect(dict["items"] != nil)
        } else {
            Issue.record("Round trip failed for nested structure")
        }
    }
}
