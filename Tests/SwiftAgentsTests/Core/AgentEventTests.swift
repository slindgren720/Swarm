// AgentEventTests.swift
// SwiftAgentsTests
//
// Comprehensive tests for AgentEvent, ToolCall, and ToolResult types.

import Testing
import Foundation
@testable import SwiftAgents

// MARK: - AgentEvent Tests

@Suite("AgentEvent Tests")
struct AgentEventTests {
    
    // MARK: - Lifecycle Events
    
    @Test("AgentEvent.started creation")
    func startedEventCreation() {
        let event = AgentEvent.started(input: "What is 2+2?")
        
        // Verify the event can be pattern-matched
        if case .started(let input) = event {
            #expect(input == "What is 2+2?")
        } else {
            Issue.record("Expected .started event")
        }
    }
    
    @Test("AgentEvent.completed creation")
    func completedEventCreation() {
        let result = AgentResult(
            output: "The answer is 4",
            iterationCount: 2,
            duration: .seconds(1)
        )
        
        let event = AgentEvent.completed(result: result)
        
        // Verify the event can be pattern-matched
        if case .completed(let capturedResult) = event {
            #expect(capturedResult.output == "The answer is 4")
            #expect(capturedResult.iterationCount == 2)
        } else {
            Issue.record("Expected .completed event")
        }
    }
    
    @Test("AgentEvent.failed creation")
    func failedEventCreation() {
        let error = AgentError.toolNotFound(name: "calculator")
        let event = AgentEvent.failed(error: error)
        
        // Verify the event can be pattern-matched
        if case .failed(let capturedError) = event {
            #expect(capturedError == error)
        } else {
            Issue.record("Expected .failed event")
        }
    }
    
    @Test("AgentEvent.cancelled creation")
    func cancelledEventCreation() {
        let event = AgentEvent.cancelled
        
        // Verify the event can be pattern-matched
        if case .cancelled = event {
            // Success
        } else {
            Issue.record("Expected .cancelled event")
        }
    }
    
    // MARK: - Thinking Events
    
    @Test("AgentEvent.thinking creation")
    func thinkingEventCreation() {
        let event = AgentEvent.thinking(thought: "I need to calculate 2+2")
        
        // Verify the event can be pattern-matched
        if case .thinking(let thought) = event {
            #expect(thought == "I need to calculate 2+2")
        } else {
            Issue.record("Expected .thinking event")
        }
    }
    
    @Test("AgentEvent.thinkingPartial creation")
    func thinkingPartialEventCreation() {
        let event = AgentEvent.thinkingPartial(partialThought: "I need to")
        
        // Verify the event can be pattern-matched
        if case .thinkingPartial(let partial) = event {
            #expect(partial == "I need to")
        } else {
            Issue.record("Expected .thinkingPartial event")
        }
    }
    
    // MARK: - Tool Events
    
    @Test("AgentEvent.toolCallStarted creation")
    func toolCallStartedEventCreation() {
        let toolCall = ToolCall(
            toolName: "calculator",
            arguments: ["expression": .string("2+2")]
        )
        
        let event = AgentEvent.toolCallStarted(call: toolCall)
        
        // Verify the event can be pattern-matched
        if case .toolCallStarted(let call) = event {
            #expect(call.toolName == "calculator")
            #expect(call.arguments["expression"] == .string("2+2"))
        } else {
            Issue.record("Expected .toolCallStarted event")
        }
    }
    
    @Test("AgentEvent.toolCallCompleted creation")
    func toolCallCompletedEventCreation() {
        let toolCall = ToolCall(
            toolName: "calculator",
            arguments: ["expression": .string("2+2")]
        )
        
        let result = ToolResult.success(
            callId: toolCall.id,
            output: .int(4),
            duration: .milliseconds(100)
        )
        
        let event = AgentEvent.toolCallCompleted(call: toolCall, result: result)
        
        // Verify the event can be pattern-matched
        if case .toolCallCompleted(let call, let capturedResult) = event {
            #expect(call.toolName == "calculator")
            #expect(capturedResult.isSuccess == true)
            #expect(capturedResult.output == .int(4))
        } else {
            Issue.record("Expected .toolCallCompleted event")
        }
    }
    
    @Test("AgentEvent.toolCallFailed creation")
    func toolCallFailedEventCreation() {
        let toolCall = ToolCall(
            toolName: "calculator",
            arguments: ["expression": .string("invalid")]
        )
        
        let error = AgentError.toolExecutionFailed(
            toolName: "calculator",
            underlyingError: "Invalid expression"
        )
        
        let event = AgentEvent.toolCallFailed(call: toolCall, error: error)
        
        // Verify the event can be pattern-matched
        if case .toolCallFailed(let call, let capturedError) = event {
            #expect(call.toolName == "calculator")
            #expect(capturedError == error)
        } else {
            Issue.record("Expected .toolCallFailed event")
        }
    }
    
    // MARK: - Output Events
    
    @Test("AgentEvent.outputToken creation")
    func outputTokenEventCreation() {
        let event = AgentEvent.outputToken(token: "Hello")
        
        // Verify the event can be pattern-matched
        if case .outputToken(let token) = event {
            #expect(token == "Hello")
        } else {
            Issue.record("Expected .outputToken event")
        }
    }
    
    @Test("AgentEvent.outputChunk creation")
    func outputChunkEventCreation() {
        let event = AgentEvent.outputChunk(chunk: "Hello, world!")
        
        // Verify the event can be pattern-matched
        if case .outputChunk(let chunk) = event {
            #expect(chunk == "Hello, world!")
        } else {
            Issue.record("Expected .outputChunk event")
        }
    }
    
    // MARK: - Iteration Events
    
    @Test("AgentEvent.iterationStarted creation")
    func iterationStartedEventCreation() {
        let event = AgentEvent.iterationStarted(number: 1)
        
        // Verify the event can be pattern-matched
        if case .iterationStarted(let number) = event {
            #expect(number == 1)
        } else {
            Issue.record("Expected .iterationStarted event")
        }
    }
    
    @Test("AgentEvent.iterationCompleted creation")
    func iterationCompletedEventCreation() {
        let event = AgentEvent.iterationCompleted(number: 5)
        
        // Verify the event can be pattern-matched
        if case .iterationCompleted(let number) = event {
            #expect(number == 5)
        } else {
            Issue.record("Expected .iterationCompleted event")
        }
    }
    
    // MARK: - All Event Cases
    
    @Test("All AgentEvent cases are Sendable")
    func allEventCasesAreSendable() {
        // This test verifies compilation - all events should conform to Sendable
        let events: [AgentEvent] = [
            .started(input: "test"),
            .completed(result: AgentResult(output: "done")),
            .failed(error: .cancelled),
            .cancelled,
            .thinking(thought: "thinking"),
            .thinkingPartial(partialThought: "think"),
            .toolCallStarted(call: ToolCall(toolName: "test")),
            .toolCallCompleted(
                call: ToolCall(toolName: "test"),
                result: ToolResult.success(callId: UUID(), output: .null, duration: .zero)
            ),
            .toolCallFailed(call: ToolCall(toolName: "test"), error: .cancelled),
            .outputToken(token: "hi"),
            .outputChunk(chunk: "hello"),
            .iterationStarted(number: 1),
            .iterationCompleted(number: 1)
        ]
        
        #expect(events.count == 13)
    }
}

// MARK: - ToolCall Tests

@Suite("ToolCall Tests")
struct ToolCallTests {
    
    // MARK: - Initialization
    
    @Test("ToolCall default initialization")
    func defaultInitialization() {
        let toolCall = ToolCall(toolName: "calculator")
        
        #expect(toolCall.toolName == "calculator")
        #expect(toolCall.arguments.isEmpty)
        #expect(toolCall.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
        
        // Verify timestamp is recent (within last second)
        let now = Date()
        let difference = now.timeIntervalSince(toolCall.timestamp)
        #expect(difference >= 0)
        #expect(difference < 1.0)
    }
    
    @Test("ToolCall custom initialization")
    func customInitialization() {
        let id = UUID()
        let timestamp = Date(timeIntervalSince1970: 1000000)
        let arguments: [String: SendableValue] = [
            "query": .string("search term"),
            "limit": .int(10),
            "verbose": .bool(true)
        ]
        
        let toolCall = ToolCall(
            id: id,
            toolName: "search",
            arguments: arguments,
            timestamp: timestamp
        )
        
        #expect(toolCall.id == id)
        #expect(toolCall.toolName == "search")
        #expect(toolCall.arguments["query"] == .string("search term"))
        #expect(toolCall.arguments["limit"] == .int(10))
        #expect(toolCall.arguments["verbose"] == .bool(true))
        #expect(toolCall.timestamp == timestamp)
    }
    
    @Test("ToolCall with empty arguments")
    func emptyArguments() {
        let toolCall = ToolCall(
            toolName: "get_time",
            arguments: [:]
        )
        
        #expect(toolCall.arguments.isEmpty)
        #expect(toolCall.toolName == "get_time")
    }
    
    @Test("ToolCall with complex arguments")
    func complexArguments() {
        let toolCall = ToolCall(
            toolName: "complex_tool",
            arguments: [
                "nested": .dictionary([
                    "key1": .string("value1"),
                    "key2": .int(42)
                ]),
                "array": .array([.int(1), .int(2), .int(3)]),
                "null": .null
            ]
        )
        
        #expect(toolCall.arguments.count == 3)
        #expect(toolCall.arguments["nested"]?["key1"] == .string("value1"))
        #expect(toolCall.arguments["array"]?[0] == .int(1))
        #expect(toolCall.arguments["null"] == .null)
    }
    
    // MARK: - Equatable Conformance
    
    @Test("ToolCall Equatable - same values")
    func equatableSameValues() {
        let id = UUID()
        let timestamp = Date(timeIntervalSince1970: 1000000)
        let arguments: [String: SendableValue] = ["key": .string("value")]
        
        let toolCall1 = ToolCall(
            id: id,
            toolName: "test",
            arguments: arguments,
            timestamp: timestamp
        )
        
        let toolCall2 = ToolCall(
            id: id,
            toolName: "test",
            arguments: arguments,
            timestamp: timestamp
        )
        
        #expect(toolCall1 == toolCall2)
    }
    
    @Test("ToolCall Equatable - different IDs")
    func equatableDifferentIds() {
        let timestamp = Date(timeIntervalSince1970: 1000000)
        
        let toolCall1 = ToolCall(
            id: UUID(),
            toolName: "test",
            arguments: [:],
            timestamp: timestamp
        )
        
        let toolCall2 = ToolCall(
            id: UUID(),
            toolName: "test",
            arguments: [:],
            timestamp: timestamp
        )
        
        #expect(toolCall1 != toolCall2)
    }
    
    @Test("ToolCall Equatable - different tool names")
    func equatableDifferentToolNames() {
        let id = UUID()
        let timestamp = Date(timeIntervalSince1970: 1000000)
        
        let toolCall1 = ToolCall(
            id: id,
            toolName: "tool1",
            arguments: [:],
            timestamp: timestamp
        )
        
        let toolCall2 = ToolCall(
            id: id,
            toolName: "tool2",
            arguments: [:],
            timestamp: timestamp
        )
        
        #expect(toolCall1 != toolCall2)
    }
    
    @Test("ToolCall Equatable - different arguments")
    func equatableDifferentArguments() {
        let id = UUID()
        let timestamp = Date(timeIntervalSince1970: 1000000)
        
        let toolCall1 = ToolCall(
            id: id,
            toolName: "test",
            arguments: ["key": .string("value1")],
            timestamp: timestamp
        )
        
        let toolCall2 = ToolCall(
            id: id,
            toolName: "test",
            arguments: ["key": .string("value2")],
            timestamp: timestamp
        )
        
        #expect(toolCall1 != toolCall2)
    }
    
    @Test("ToolCall Equatable - different timestamps")
    func equatableDifferentTimestamps() {
        let id = UUID()
        
        let toolCall1 = ToolCall(
            id: id,
            toolName: "test",
            arguments: [:],
            timestamp: Date(timeIntervalSince1970: 1000000)
        )
        
        let toolCall2 = ToolCall(
            id: id,
            toolName: "test",
            arguments: [:],
            timestamp: Date(timeIntervalSince1970: 2000000)
        )
        
        #expect(toolCall1 != toolCall2)
    }
    
    // MARK: - Identifiable Conformance
    
    @Test("ToolCall Identifiable conformance")
    func identifiableConformance() {
        let toolCall1 = ToolCall(toolName: "test")
        let toolCall2 = ToolCall(toolName: "test")
        
        // Each tool call should have a unique ID
        #expect(toolCall1.id != toolCall2.id)
        
        // ID should be stable for the same instance
        let id1 = toolCall1.id
        let id2 = toolCall1.id
        #expect(id1 == id2)
    }
    
    // MARK: - Codable Conformance
    
    @Test("ToolCall Codable round-trip")
    func codableRoundTrip() throws {
        let original = ToolCall(
            id: UUID(uuidString: "12345678-1234-1234-1234-123456789012")!,
            toolName: "calculator",
            arguments: [
                "expression": .string("2+2"),
                "verbose": .bool(true),
                "precision": .int(2)
            ],
            timestamp: Date(timeIntervalSince1970: 1000000)
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ToolCall.self, from: data)
        
        #expect(decoded == original)
        #expect(decoded.id == original.id)
        #expect(decoded.toolName == original.toolName)
        #expect(decoded.arguments == original.arguments)
        #expect(decoded.timestamp.timeIntervalSince1970 == original.timestamp.timeIntervalSince1970)
    }
    
    @Test("ToolCall Codable with empty arguments")
    func codableEmptyArguments() throws {
        let original = ToolCall(
            toolName: "simple_tool",
            arguments: [:]
        )
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ToolCall.self, from: data)
        
        #expect(decoded.toolName == original.toolName)
        #expect(decoded.arguments.isEmpty)
    }
    
    @Test("ToolCall Codable with nested arguments")
    func codableNestedArguments() throws {
        let original = ToolCall(
            toolName: "nested_tool",
            arguments: [
                "config": .dictionary([
                    "timeout": .int(30),
                    "retry": .bool(true),
                    "endpoints": .array([
                        .string("http://api1.com"),
                        .string("http://api2.com")
                    ])
                ])
            ]
        )
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ToolCall.self, from: data)
        
        #expect(decoded.toolName == original.toolName)
        #expect(decoded.arguments["config"]?["timeout"] == .int(30))
        #expect(decoded.arguments["config"]?["retry"] == .bool(true))
        #expect(decoded.arguments["config"]?["endpoints"]?[0] == .string("http://api1.com"))
    }
    
    // MARK: - CustomStringConvertible
    
    @Test("ToolCall description")
    func customStringConvertible() {
        let toolCall = ToolCall(
            toolName: "search",
            arguments: ["query": .string("swift")]
        )
        
        let description = toolCall.description
        
        #expect(description.contains("ToolCall"))
        #expect(description.contains("search"))
        #expect(description.contains("args"))
    }
}

// MARK: - ToolResult Tests

@Suite("ToolResult Tests")
struct ToolResultTests {
    
    // MARK: - Success Factory Method
    
    @Test("ToolResult.success factory")
    func successFactory() {
        let callId = UUID()
        let output: SendableValue = .string("Success result")
        let duration = Duration.seconds(2)
        
        let result = ToolResult.success(
            callId: callId,
            output: output,
            duration: duration
        )
        
        #expect(result.callId == callId)
        #expect(result.isSuccess == true)
        #expect(result.output == output)
        #expect(result.duration == duration)
        #expect(result.errorMessage == nil)
    }
    
    @Test("ToolResult.success with different output types")
    func successDifferentOutputTypes() {
        let callId = UUID()
        
        // String output
        let stringResult = ToolResult.success(
            callId: callId,
            output: .string("text"),
            duration: .milliseconds(100)
        )
        #expect(stringResult.output == .string("text"))
        
        // Int output
        let intResult = ToolResult.success(
            callId: callId,
            output: .int(42),
            duration: .milliseconds(100)
        )
        #expect(intResult.output == .int(42))
        
        // Dictionary output
        let dictResult = ToolResult.success(
            callId: callId,
            output: .dictionary(["key": .string("value")]),
            duration: .milliseconds(100)
        )
        #expect(dictResult.output["key"] == .string("value"))
        
        // Array output
        let arrayResult = ToolResult.success(
            callId: callId,
            output: .array([.int(1), .int(2)]),
            duration: .milliseconds(100)
        )
        #expect(arrayResult.output[0] == .int(1))
    }
    
    // MARK: - Failure Factory Method
    
    @Test("ToolResult.failure factory")
    func failureFactory() {
        let callId = UUID()
        let error = "Connection timeout"
        let duration = Duration.seconds(5)
        
        let result = ToolResult.failure(
            callId: callId,
            error: error,
            duration: duration
        )
        
        #expect(result.callId == callId)
        #expect(result.isSuccess == false)
        #expect(result.output == .null)
        #expect(result.duration == duration)
        #expect(result.errorMessage == error)
    }
    
    @Test("ToolResult.failure with different error messages")
    func failureDifferentErrors() {
        let callId = UUID()
        
        let errors = [
            "Network error",
            "Invalid input",
            "Permission denied",
            "Resource not found"
        ]
        
        for errorMessage in errors {
            let result = ToolResult.failure(
                callId: callId,
                error: errorMessage,
                duration: .milliseconds(50)
            )
            
            #expect(result.isSuccess == false)
            #expect(result.errorMessage == errorMessage)
            #expect(result.output == .null)
        }
    }
    
    // MARK: - Direct Initialization
    
    @Test("ToolResult direct initialization - success")
    func directInitializationSuccess() {
        let callId = UUID()
        let result = ToolResult(
            callId: callId,
            isSuccess: true,
            output: .int(100),
            duration: .seconds(1),
            errorMessage: nil
        )
        
        #expect(result.callId == callId)
        #expect(result.isSuccess == true)
        #expect(result.output == .int(100))
        #expect(result.duration == .seconds(1))
        #expect(result.errorMessage == nil)
    }
    
    @Test("ToolResult direct initialization - failure")
    func directInitializationFailure() {
        let callId = UUID()
        let result = ToolResult(
            callId: callId,
            isSuccess: false,
            output: .null,
            duration: .milliseconds(500),
            errorMessage: "Failed"
        )
        
        #expect(result.callId == callId)
        #expect(result.isSuccess == false)
        #expect(result.output == .null)
        #expect(result.duration == .milliseconds(500))
        #expect(result.errorMessage == "Failed")
    }
    
    // MARK: - Equatable Conformance
    
    @Test("ToolResult Equatable - same values")
    func equatableSameValues() {
        let callId = UUID()
        let duration = Duration.seconds(1)
        
        let result1 = ToolResult.success(
            callId: callId,
            output: .string("test"),
            duration: duration
        )
        
        let result2 = ToolResult.success(
            callId: callId,
            output: .string("test"),
            duration: duration
        )
        
        #expect(result1 == result2)
    }
    
    @Test("ToolResult Equatable - different callIds")
    func equatableDifferentCallIds() {
        let result1 = ToolResult.success(
            callId: UUID(),
            output: .string("test"),
            duration: .seconds(1)
        )
        
        let result2 = ToolResult.success(
            callId: UUID(),
            output: .string("test"),
            duration: .seconds(1)
        )
        
        #expect(result1 != result2)
    }
    
    @Test("ToolResult Equatable - different success states")
    func equatableDifferentSuccessStates() {
        let callId = UUID()
        
        let success = ToolResult.success(
            callId: callId,
            output: .string("test"),
            duration: .seconds(1)
        )
        
        let failure = ToolResult.failure(
            callId: callId,
            error: "error",
            duration: .seconds(1)
        )
        
        #expect(success != failure)
    }
    
    @Test("ToolResult Equatable - different outputs")
    func equatableDifferentOutputs() {
        let callId = UUID()
        
        let result1 = ToolResult.success(
            callId: callId,
            output: .string("output1"),
            duration: .seconds(1)
        )
        
        let result2 = ToolResult.success(
            callId: callId,
            output: .string("output2"),
            duration: .seconds(1)
        )
        
        #expect(result1 != result2)
    }
    
    @Test("ToolResult Equatable - different durations")
    func equatableDifferentDurations() {
        let callId = UUID()
        
        let result1 = ToolResult.success(
            callId: callId,
            output: .string("test"),
            duration: .seconds(1)
        )
        
        let result2 = ToolResult.success(
            callId: callId,
            output: .string("test"),
            duration: .seconds(2)
        )
        
        #expect(result1 != result2)
    }
    
    @Test("ToolResult Equatable - different error messages")
    func equatableDifferentErrorMessages() {
        let callId = UUID()
        
        let result1 = ToolResult.failure(
            callId: callId,
            error: "error1",
            duration: .seconds(1)
        )
        
        let result2 = ToolResult.failure(
            callId: callId,
            error: "error2",
            duration: .seconds(1)
        )
        
        #expect(result1 != result2)
    }
    
    // MARK: - Codable Conformance
    
    @Test("ToolResult Codable round-trip - success")
    func codableRoundTripSuccess() throws {
        let original = ToolResult.success(
            callId: UUID(uuidString: "12345678-1234-1234-1234-123456789012")!,
            output: .dictionary([
                "result": .int(42),
                "message": .string("Success")
            ]),
            duration: .seconds(3)
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ToolResult.self, from: data)
        
        #expect(decoded == original)
        #expect(decoded.isSuccess == true)
        #expect(decoded.output["result"] == .int(42))
        #expect(decoded.errorMessage == nil)
    }
    
    @Test("ToolResult Codable round-trip - failure")
    func codableRoundTripFailure() throws {
        let original = ToolResult.failure(
            callId: UUID(uuidString: "12345678-1234-1234-1234-123456789012")!,
            error: "Something went wrong",
            duration: .milliseconds(250)
        )
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ToolResult.self, from: data)
        
        #expect(decoded == original)
        #expect(decoded.isSuccess == false)
        #expect(decoded.output == .null)
        #expect(decoded.errorMessage == "Something went wrong")
    }
    
    @Test("ToolResult Codable with null output")
    func codableNullOutput() throws {
        let original = ToolResult.success(
            callId: UUID(),
            output: .null,
            duration: .seconds(1)
        )
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ToolResult.self, from: data)
        
        #expect(decoded.output == .null)
        #expect(decoded.isSuccess == true)
    }
    
    // MARK: - CustomStringConvertible
    
    @Test("ToolResult description - success")
    func customStringConvertibleSuccess() {
        let result = ToolResult.success(
            callId: UUID(),
            output: .string("result"),
            duration: .seconds(1)
        )
        
        let description = result.description
        
        #expect(description.contains("ToolResult"))
        #expect(description.contains("success"))
        #expect(description.contains("duration"))
    }
    
    @Test("ToolResult description - failure")
    func customStringConvertibleFailure() {
        let result = ToolResult.failure(
            callId: UUID(),
            error: "Test error",
            duration: .seconds(2)
        )
        
        let description = result.description
        
        #expect(description.contains("ToolResult"))
        #expect(description.contains("failure"))
        #expect(description.contains("duration"))
    }
    
    // MARK: - Edge Cases
    
    @Test("ToolResult with zero duration")
    func zeroDuration() {
        let result = ToolResult.success(
            callId: UUID(),
            output: .string("instant"),
            duration: .zero
        )
        
        #expect(result.duration == .zero)
    }
    
    @Test("ToolResult with very long duration")
    func longDuration() {
        let result = ToolResult.success(
            callId: UUID(),
            output: .string("slow"),
            duration: .seconds(3600) // 1 hour
        )
        
        #expect(result.duration == .seconds(3600))
    }
    
    @Test("ToolResult with empty error message")
    func emptyErrorMessage() {
        let result = ToolResult.failure(
            callId: UUID(),
            error: "",
            duration: .milliseconds(100)
        )
        
        #expect(result.errorMessage == "")
        #expect(result.isSuccess == false)
    }
    
    @Test("ToolResult with complex nested output")
    func complexNestedOutput() {
        let output: SendableValue = .dictionary([
            "data": .array([
                .dictionary([
                    "id": .int(1),
                    "name": .string("Item 1"),
                    "tags": .array([.string("tag1"), .string("tag2")])
                ]),
                .dictionary([
                    "id": .int(2),
                    "name": .string("Item 2"),
                    "tags": .array([.string("tag3")])
                ])
            ]),
            "metadata": .dictionary([
                "count": .int(2),
                "cached": .bool(true)
            ])
        ])
        
        let result = ToolResult.success(
            callId: UUID(),
            output: output,
            duration: .milliseconds(500)
        )
        
        #expect(result.isSuccess == true)
        #expect(result.output["data"]?[0]?["name"] == .string("Item 1"))
        #expect(result.output["metadata"]?["count"] == .int(2))
    }
}

// MARK: - Integration Tests

@Suite("AgentEvent Integration Tests")
struct AgentEventIntegrationTests {
    
    @Test("Complete event sequence")
    func completeEventSequence() {
        // Simulate a complete agent execution event sequence
        let events: [AgentEvent] = [
            .started(input: "Calculate 2+2"),
            .iterationStarted(number: 1),
            .thinking(thought: "I need to use the calculator"),
            .toolCallStarted(call: ToolCall(
                toolName: "calculator",
                arguments: ["expression": .string("2+2")]
            )),
            .toolCallCompleted(
                call: ToolCall(toolName: "calculator"),
                result: ToolResult.success(
                    callId: UUID(),
                    output: .int(4),
                    duration: .milliseconds(50)
                )
            ),
            .iterationCompleted(number: 1),
            .outputChunk(chunk: "The answer is 4"),
            .completed(result: AgentResult(output: "The answer is 4"))
        ]
        
        #expect(events.count == 8)
        
        // Verify first event is started
        if case .started(let input) = events[0] {
            #expect(input == "Calculate 2+2")
        } else {
            Issue.record("Expected first event to be .started")
        }
        
        // Verify last event is completed
        if case .completed(let result) = events[7] {
            #expect(result.output == "The answer is 4")
        } else {
            Issue.record("Expected last event to be .completed")
        }
    }
    
    @Test("Error event sequence")
    func errorEventSequence() {
        // Simulate an error during execution
        let events: [AgentEvent] = [
            .started(input: "Use invalid tool"),
            .iterationStarted(number: 1),
            .thinking(thought: "I'll call the missing tool"),
            .failed(error: .toolNotFound(name: "missing_tool"))
        ]
        
        #expect(events.count == 4)
        
        // Verify error event
        if case .failed(let error) = events[3] {
            #expect(error == .toolNotFound(name: "missing_tool"))
        } else {
            Issue.record("Expected .failed event")
        }
    }
    
    @Test("Streaming output sequence")
    func streamingOutputSequence() {
        // Simulate streaming token output
        let tokens = ["Hello", ", ", "world", "!"]
        var events: [AgentEvent] = [.started(input: "Say hello")]
        
        for token in tokens {
            events.append(.outputToken(token: token))
        }
        
        events.append(.completed(result: AgentResult(output: "Hello, world!")))
        
        #expect(events.count == 6) // 1 started + 4 tokens + 1 completed
        
        // Verify all tokens
        var collectedTokens: [String] = []
        for event in events {
            if case .outputToken(let token) = event {
                collectedTokens.append(token)
            }
        }
        
        #expect(collectedTokens == tokens)
    }
    
    @Test("Multi-iteration sequence")
    func multiIterationSequence() {
        // Simulate multiple reasoning iterations
        let events: [AgentEvent] = [
            .started(input: "Complex task"),
            .iterationStarted(number: 1),
            .thinking(thought: "First thought"),
            .iterationCompleted(number: 1),
            .iterationStarted(number: 2),
            .thinking(thought: "Second thought"),
            .iterationCompleted(number: 2),
            .iterationStarted(number: 3),
            .thinking(thought: "Final thought"),
            .iterationCompleted(number: 3),
            .completed(result: AgentResult(output: "Done", iterationCount: 3))
        ]
        
        #expect(events.count == 11)
        
        // Count iterations
        var iterationStarts = 0
        var iterationEnds = 0
        
        for event in events {
            if case .iterationStarted = event {
                iterationStarts += 1
            }
            if case .iterationCompleted = event {
                iterationEnds += 1
            }
        }
        
        #expect(iterationStarts == 3)
        #expect(iterationEnds == 3)
    }
}
