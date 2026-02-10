// LoopTests.swift
// Swarm Framework
//
// TDD tests for ResumeToken (~Copyable) and Loop orchestration step.

import Foundation
@testable import Swarm
import Testing

// MARK: - Test Helpers

private struct LoopEchoAgent: AgentRuntime {
    let tools: [any AnyJSONTool] = []
    let instructions = "Echo agent"
    var configuration: AgentConfiguration

    init(name: String = "echo") {
        configuration = AgentConfiguration(name: name)
    }

    func run(
        _ input: String,
        session _: (any Session)? = nil,
        hooks _: (any RunHooks)? = nil
    ) async throws -> AgentResult {
        AgentResult(output: input)
    }

    nonisolated func stream(
        _ input: String,
        session _: (any Session)? = nil,
        hooks _: (any RunHooks)? = nil
    ) -> AsyncThrowingStream<AgentEvent, Error> {
        StreamHelper.makeTrackedStream { continuation in
            continuation.yield(.started(input: input))
            continuation.yield(.completed(result: AgentResult(output: input)))
            continuation.finish()
        }
    }

    func cancel() async {}
}

private struct LoopPrefixAgent: AgentRuntime {
    let prefix: String
    let tools: [any AnyJSONTool] = []
    let instructions: String
    var configuration: AgentConfiguration

    init(prefix: String, name: String? = nil) {
        self.prefix = prefix
        instructions = "Prefix agent: \(prefix)"
        configuration = AgentConfiguration(name: name ?? "prefix-\(prefix)")
    }

    func run(
        _ input: String,
        session _: (any Session)? = nil,
        hooks _: (any RunHooks)? = nil
    ) async throws -> AgentResult {
        AgentResult(output: "\(prefix)\(input)")
    }

    nonisolated func stream(
        _ input: String,
        session _: (any Session)? = nil,
        hooks _: (any RunHooks)? = nil
    ) -> AsyncThrowingStream<AgentEvent, Error> {
        StreamHelper.makeTrackedStream { continuation in
            continuation.yield(.started(input: input))
            continuation.yield(.completed(result: AgentResult(output: "\(prefix)\(input)")))
            continuation.finish()
        }
    }

    func cancel() async {}
}

// MARK: - ResumeToken Tests

@Suite("ResumeToken -- ~Copyable Suspension Token")
struct ResumeTokenTests {
    @Test("ResumeToken can be created and has correct properties")
    func resumeTokenProperties() {
        let context = OrchestrationStepContext(
            agentContext: AgentContext(input: "test"),
            session: nil,
            hooks: nil,
            orchestrator: nil,
            orchestratorName: "test",
            handoffs: []
        )

        let token = ResumeToken(
            suspensionPoint: "step-3",
            capturedInput: "hello",
            capturedStep: Transform { $0.uppercased() },
            capturedContext: context
        )

        #expect(token.suspension == "step-3")
        // id should be a valid UUID
        _ = token.id
    }

    @Test("ResumeToken resume executes captured step with new input")
    func resumeTokenResume() async throws {
        let context = OrchestrationStepContext(
            agentContext: AgentContext(input: "test"),
            session: nil,
            hooks: nil,
            orchestrator: nil,
            orchestratorName: "test",
            handoffs: []
        )

        var token = ResumeToken(
            suspensionPoint: "step-1",
            capturedInput: "original",
            capturedStep: Transform { $0.uppercased() },
            capturedContext: context
        )

        let result = try await token.resume(with: "new input")
        #expect(result.output == "NEW INPUT")
    }

    @Test("ResumeToken cancel consumes the token without execution")
    func resumeTokenCancel() {
        let context = OrchestrationStepContext(
            agentContext: AgentContext(input: "test"),
            session: nil,
            hooks: nil,
            orchestrator: nil,
            orchestratorName: "test",
            handoffs: []
        )

        var token = ResumeToken(
            suspensionPoint: "step-2",
            capturedInput: "data",
            capturedStep: Transform { $0 },
            capturedContext: context
        )

        token.cancel()
        // Token is consumed -- compiler prevents further use
    }

    @Test("ResumeToken preserves custom orchestration ID")
    func resumeTokenCustomID() {
        let customID = UUID()
        let context = OrchestrationStepContext(
            agentContext: AgentContext(input: "test"),
            session: nil,
            hooks: nil,
            orchestrator: nil,
            orchestratorName: "test",
            handoffs: []
        )

        let token = ResumeToken(
            orchestrationID: customID,
            suspensionPoint: "checkpoint",
            capturedInput: "state",
            capturedStep: Transform { $0 },
            capturedContext: context
        )

        #expect(token.id == customID)
    }
}

// MARK: - Loop Tests

@Suite("Loop -- DSL-Friendly Loop Step")
struct LoopTests {
    @Test("Loop with maxIterations stops after N iterations")
    func loopMaxIterations() async throws {
        let step = Loop(.maxIterations(3)) {
            LoopPrefixAgent(prefix: "+")
        }

        let result = try await step.execute("x", hooks: nil)
        #expect(result.output == "+++x")
        #expect(result.metadata["loop.iteration_count"]?.intValue == 3)
    }

    @Test("Loop with .until stops when predicate becomes true")
    func loopUntil() async throws {
        let step = Loop(.until({ output in output.contains("DONE") })) {
            Transform { input in
                if input.count > 10 {
                    return input + " DONE"
                }
                return input + " more"
            }
        }

        let result = try await step.execute("start", hooks: nil)
        #expect(result.output.contains("DONE"))
        let iterCount = result.metadata["loop.iteration_count"]?.intValue ?? 0
        #expect(iterCount > 1)
    }

    @Test("Loop with .whileTrue continues while predicate is true")
    func loopWhileTrue() async throws {
        let step = Loop(.whileTrue({ output in output.count < 5 })) {
            LoopPrefixAgent(prefix: "+")
        }

        let result = try await step.execute("x", hooks: nil)
        // Should iterate until output reaches length 5: "+x" (2), "++x" (3), "+++x" (4), "++++x" (5)
        // condition checked before each iter: "x"(1)<5 -> "+x"(2)<5 -> "++x"(3)<5 -> "+++x"(4)<5 -> "++++x"(5) not <5 -> stop
        #expect(result.output == "++++x")
        #expect(result.metadata["loop.iteration_count"]?.intValue == 4)
    }

    @Test("Loop accumulates metadata per iteration")
    func loopMetadata() async throws {
        let step = Loop(.maxIterations(2)) {
            LoopPrefixAgent(prefix: "+")
        }

        let result = try await step.execute("x", hooks: nil)
        #expect(result.metadata["loop.iteration_count"]?.intValue == 2)
        // Duration should be present
        #expect(result.metadata["loop.duration"] != nil)
    }

    @Test("Loop composes inside Sequential")
    func loopInSequential() async throws {
        let workflow = Orchestration {
            Sequential {
                Transform { "count:0 " + $0 }
                Loop(.maxIterations(3)) {
                    LoopPrefixAgent(prefix: "+")
                }
            }
        }

        let result = try await workflow.run("data")
        #expect(result.output == "+++count:0 data")
    }

    @Test("Nested Loop works correctly")
    func nestedLoop() async throws {
        let step = Loop(.maxIterations(2)) {
            Loop(.maxIterations(2)) {
                LoopPrefixAgent(prefix: "+")
            }
        }

        let result = try await step.execute("x", hooks: nil)
        // Inner loop: 2 iterations -> "++x"
        // Outer loop iteration 1: "++x" -> inner loop: "++++x"
        // Outer loop iteration 2 done
        #expect(result.output == "++++x")
    }

    @Test("Loop with .until predicate true immediately does not execute body")
    func loopUntilImmediatelyTrue() async throws {
        let step = Loop(.until({ _ in true })) {
            LoopPrefixAgent(prefix: "SHOULD_NOT_RUN:")
        }

        let result = try await step.execute("hello", hooks: nil)
        #expect(result.output == "hello")
        #expect(result.metadata["loop.iteration_count"]?.intValue == 0)
    }

    @Test("Loop with .whileTrue predicate false immediately does not execute body")
    func loopWhileTrueImmediatelyFalse() async throws {
        let step = Loop(.whileTrue({ _ in false })) {
            LoopPrefixAgent(prefix: "SHOULD_NOT_RUN:")
        }

        let result = try await step.execute("hello", hooks: nil)
        #expect(result.output == "hello")
        #expect(result.metadata["loop.iteration_count"]?.intValue == 0)
    }

    @Test("Loop with safety cap prevents infinite loops")
    func loopSafetyCap() async throws {
        // Using .whileTrue with always-true predicate, should cap at 1000
        let step = Loop(.whileTrue({ _ in true })) {
            LoopEchoAgent()
        }

        let result = try await step.execute("hello", hooks: nil)
        #expect(result.metadata["loop.iteration_count"]?.intValue == 1000)
    }

    @Test("Loop nested steps are discoverable")
    func loopNestedSteps() {
        let step = Loop(.maxIterations(5)) {
            LoopPrefixAgent(prefix: "+")
        }

        let nested = (step as _AgentLoopNestedSteps)._nestedSteps
        #expect(nested.count == 1)
    }

    @Test("Loop works in OrchestrationBuilder via buildExpression")
    func loopBuildExpression() async throws {
        let workflow = Orchestration {
            Loop(.maxIterations(2)) {
                LoopPrefixAgent(prefix: "+")
            }
        }

        let result = try await workflow.run("x")
        #expect(result.output == "++x")
    }
}
