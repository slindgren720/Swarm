// NewPrimitivesTests.swift
// Swarm Framework
//
// TDD tests for Branch, RepeatWhile, NoOpStep, and HumanApproval orchestration primitives.

@testable import Swarm
import Testing

// MARK: - Test Helpers

private struct NPEchoAgent: AgentRuntime {
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

private struct NPPrefixAgent: AgentRuntime {
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

private struct NPUppercaseAgent: AgentRuntime {
    let tools: [any AnyJSONTool] = []
    let instructions = "Uppercase agent"
    var configuration: AgentConfiguration

    init(name: String = "uppercase") {
        configuration = AgentConfiguration(name: name)
    }

    func run(
        _ input: String,
        session _: (any Session)? = nil,
        hooks _: (any RunHooks)? = nil
    ) async throws -> AgentResult {
        AgentResult(output: input.uppercased())
    }

    nonisolated func stream(
        _ input: String,
        session _: (any Session)? = nil,
        hooks _: (any RunHooks)? = nil
    ) -> AsyncThrowingStream<AgentEvent, Error> {
        StreamHelper.makeTrackedStream { continuation in
            continuation.yield(.started(input: input))
            continuation.yield(.completed(result: AgentResult(output: input.uppercased())))
            continuation.finish()
        }
    }

    func cancel() async {}
}

// MARK: - Branch Tests

@Suite("Branch -- Conditional Routing")
struct BranchTests {
    @Test("Branch takes then path when condition is true")
    func branchTakesThenPath() async throws {
        let step = Branch({ _ in true }) {
            NPPrefixAgent(prefix: "THEN:")
        } otherwise: {
            NPPrefixAgent(prefix: "OTHERWISE:")
        }

        let result = try await step.execute("hello", hooks: nil)
        #expect(result.output == "THEN:hello")
    }

    @Test("Branch takes otherwise path when condition is false")
    func branchTakesOtherwisePath() async throws {
        let step = Branch({ _ in false }) {
            NPPrefixAgent(prefix: "THEN:")
        } otherwise: {
            NPPrefixAgent(prefix: "OTHERWISE:")
        }

        let result = try await step.execute("hello", hooks: nil)
        #expect(result.output == "OTHERWISE:hello")
    }

    @Test("Branch with no otherwise passes input through")
    func branchNoOtherwise() async throws {
        let step = Branch({ _ in false }) {
            NPPrefixAgent(prefix: "THEN:")
        }

        let result = try await step.execute("hello", hooks: nil)
        #expect(result.output == "hello")
    }

    @Test("Branch condition receives previous step output")
    func branchConditionReceivesOutput() async throws {
        // Use result to verify condition received the correct input:
        // If input contains "special", the SPECIAL: prefix is applied
        let step = Branch({ input in
            input.contains("special")
        }) {
            NPPrefixAgent(prefix: "SPECIAL:")
        } otherwise: {
            NPPrefixAgent(prefix: "NORMAL:")
        }

        let result = try await step.execute("this is special data", hooks: nil)
        // If the condition received the correct input, "special" was found → SPECIAL: prefix
        #expect(result.output == "SPECIAL:this is special data")
    }

    @Test("Branch metadata includes path taken")
    func branchMetadata() async throws {
        let step = Branch({ _ in true }) {
            NPPrefixAgent(prefix: "THEN:")
        } otherwise: {
            NPPrefixAgent(prefix: "OTHERWISE:")
        }

        let result = try await step.execute("hello", hooks: nil)
        #expect(result.metadata["branch.took_path"]?.stringValue == "then")
    }

    @Test("Branch metadata includes otherwise path when taken")
    func branchMetadataOtherwise() async throws {
        let step = Branch({ _ in false }) {
            NPPrefixAgent(prefix: "THEN:")
        } otherwise: {
            NPPrefixAgent(prefix: "OTHERWISE:")
        }

        let result = try await step.execute("hello", hooks: nil)
        #expect(result.metadata["branch.took_path"]?.stringValue == "otherwise")
    }

    @Test("Branch metadata includes duration")
    func branchDuration() async throws {
        let step = Branch({ _ in true }) {
            NPPrefixAgent(prefix: "THEN:")
        } otherwise: {
            NPPrefixAgent(prefix: "OTHERWISE:")
        }

        let result = try await step.execute("hello", hooks: nil)
        let duration = result.metadata["branch.duration"]?.doubleValue
        #expect(duration != nil)
        #expect(duration! >= 0)
    }

    @Test("Branch nests inside Sequential")
    func branchInSequential() async throws {
        let workflow = Orchestration {
            Sequential {
                NPUppercaseAgent()
                Branch({ $0.contains("HELLO") }) {
                    NPPrefixAgent(prefix: "MATCHED:")
                } otherwise: {
                    NPPrefixAgent(prefix: "MISSED:")
                }
            }
        }

        let result = try await workflow.run("hello")
        #expect(result.output == "MATCHED:HELLO")
    }

    @Test("Branch inside Sequential takes otherwise path correctly")
    func branchInSequentialOtherwise() async throws {
        let workflow = Orchestration {
            Sequential {
                NPUppercaseAgent()
                Branch({ $0.contains("GOODBYE") }) {
                    NPPrefixAgent(prefix: "MATCHED:")
                } otherwise: {
                    NPPrefixAgent(prefix: "MISSED:")
                }
            }
        }

        let result = try await workflow.run("hello")
        #expect(result.output == "MISSED:HELLO")
    }

    @Test("Nested Branch composes correctly")
    func nestedBranch() async throws {
        let step = Branch({ $0.count > 3 }) {
            Branch({ $0.count > 5 }) {
                NPPrefixAgent(prefix: "LONG:")
            } otherwise: {
                NPPrefixAgent(prefix: "MEDIUM:")
            }
        } otherwise: {
            NPPrefixAgent(prefix: "SHORT:")
        }

        let shortResult = try await step.execute("hi", hooks: nil)
        #expect(shortResult.output == "SHORT:hi")

        let medResult = try await step.execute("test", hooks: nil)
        #expect(medResult.output == "MEDIUM:test")

        let longResult = try await step.execute("longer", hooks: nil)
        #expect(longResult.output == "LONG:longer")
    }

    @Test("Branch with async condition works")
    func branchAsyncCondition() async throws {
        let step = Branch({ input in
            // Simulate async work
            try? await Task.sleep(nanoseconds: 1_000)
            return input == "go"
        }) {
            NPPrefixAgent(prefix: "GO:")
        } otherwise: {
            NPPrefixAgent(prefix: "STOP:")
        }

        let goResult = try await step.execute("go", hooks: nil)
        #expect(goResult.output == "GO:go")

        let stopResult = try await step.execute("stop", hooks: nil)
        #expect(stopResult.output == "STOP:stop")
    }

    @Test("Branch nested steps are discoverable")
    func branchNestedSteps() {
        let step = Branch({ _ in true }) {
            NPPrefixAgent(prefix: "A:")
        } otherwise: {
            NPPrefixAgent(prefix: "B:")
        }

        let nested = (step as _AgentLoopNestedSteps)._nestedSteps
        #expect(nested.count == 2)
    }
}

// MARK: - RepeatWhile Tests

@Suite("RepeatWhile -- Loop Primitive")
struct RepeatWhileTests {
    @Test("RepeatWhile executes body until condition is false")
    func repeatWhileBasic() async throws {
        // Condition: keep going until output contains "DONE"
        let step = RepeatWhile(maxIterations: 10, condition: { output in
            !output.contains("DONE")
        }) {
            Transform { input in
                if input.count > 10 {
                    return input + " DONE"
                }
                return input + " more"
            }
        }

        let result = try await step.execute("start", hooks: nil)
        #expect(result.output.contains("DONE"))
        // Should have iterated more than once based on string length growth
        let iterCount = result.metadata["repeatwhile.iteration_count"]?.intValue ?? 0
        #expect(iterCount > 1)
    }

    @Test("RepeatWhile respects maxIterations limit")
    func repeatWhileMaxIterations() async throws {
        let step = RepeatWhile(maxIterations: 3, condition: { _ in true }) {
            NPPrefixAgent(prefix: "+")
        }

        let result = try await step.execute("x", hooks: nil)
        #expect(result.output == "+++x")
    }

    @Test("RepeatWhile with maxIterations=1 executes exactly once")
    func repeatWhileSingleIteration() async throws {
        let step = RepeatWhile(maxIterations: 1, condition: { _ in true }) {
            NPUppercaseAgent()
        }

        let result = try await step.execute("hello", hooks: nil)
        #expect(result.output == "HELLO")
    }

    @Test("RepeatWhile with false initial condition never executes body")
    func repeatWhileFalseInitialCondition() async throws {
        let step = RepeatWhile(maxIterations: 10, condition: { _ in false }) {
            NPPrefixAgent(prefix: "SHOULD_NOT_RUN:")
        }

        let result = try await step.execute("hello", hooks: nil)
        #expect(result.output == "hello")
    }

    @Test("RepeatWhile metadata includes iteration count")
    func repeatWhileMetadata() async throws {
        let step = RepeatWhile(maxIterations: 3, condition: { _ in true }) {
            NPPrefixAgent(prefix: "+")
        }

        let result = try await step.execute("x", hooks: nil)
        #expect(result.metadata["repeatwhile.iteration_count"]?.intValue == 3)
        #expect(result.metadata["repeatwhile.terminated_by"]?.stringValue == "maxIterations")
    }

    @Test("RepeatWhile terminated by condition reports correctly")
    func repeatWhileTerminatedByCondition() async throws {
        // Condition: stop when output has 2+ prefix characters
        let step = RepeatWhile(maxIterations: 100, condition: { output in
            output.count < 3  // "+x" is 2 chars (keep going), "++x" is 3 (stop)
        }) {
            NPPrefixAgent(prefix: "+")
        }

        let result = try await step.execute("x", hooks: nil)
        #expect(result.metadata["repeatwhile.iteration_count"]?.intValue == 2)
        #expect(result.metadata["repeatwhile.terminated_by"]?.stringValue == "condition")
    }

    @Test("RepeatWhile nests inside Sequential")
    func repeatWhileInSequential() async throws {
        let workflow = Orchestration {
            Sequential {
                Transform { "count:0 " + $0 }
                RepeatWhile(maxIterations: 3, condition: { _ in true }) {
                    NPPrefixAgent(prefix: "+")
                }
            }
        }

        let result = try await workflow.run("data")
        #expect(result.output == "+++count:0 data")
    }

    @Test("RepeatWhile accumulates tool calls across iterations")
    func repeatWhileAccumulatesToolCalls() async throws {
        let step = RepeatWhile(maxIterations: 2, condition: { _ in true }) {
            NPEchoAgent()
        }

        let result = try await step.execute("data", hooks: nil)
        // Even though NPEchoAgent has no tool calls, iteration count should be accurate
        #expect(result.metadata["repeatwhile.iteration_count"]?.intValue == 2)
    }

    @Test("RepeatWhile nested steps are discoverable")
    func repeatWhileNestedSteps() {
        let step = RepeatWhile(maxIterations: 5, condition: { _ in true }) {
            NPPrefixAgent(prefix: "+")
        }

        let nested = (step as _AgentLoopNestedSteps)._nestedSteps
        #expect(nested.count == 1)
    }

    @Test("RepeatWhile default maxIterations is 10")
    func repeatWhileDefaultMaxIterations() {
        let step = RepeatWhile(condition: { _ in true }) {
            NPEchoAgent()
        }
        #expect(step.maxIterations == 10)
    }

}

// MARK: - NoOpStep Tests

@Suite("NoOpStep -- Passthrough")
struct NoOpStepTests {
    @Test("NoOpStep passes input through unchanged")
    func noOpPassthrough() async throws {
        let step = NoOpStep()
        let result = try await step.execute("hello", hooks: nil)
        #expect(result.output == "hello")
    }

    @Test("NoOpStep preserves empty string")
    func noOpEmptyString() async throws {
        let step = NoOpStep()
        let result = try await step.execute("", hooks: nil)
        #expect(result.output == "")
    }

    @Test("NoOpStep preserves long input")
    func noOpLongInput() async throws {
        let longInput = String(repeating: "a", count: 10_000)
        let step = NoOpStep()
        let result = try await step.execute(longInput, hooks: nil)
        #expect(result.output == longInput)
    }
}

// MARK: - HumanApproval Tests

/// Thread-safe capture for approval requests in tests.
private actor RequestCapture {
    var value: ApprovalRequest?
    func store(_ request: ApprovalRequest) {
        value = request
    }
}

/// A handler that records the request and returns a configurable response.
private struct RecordingApprovalHandler: HumanApprovalHandler {
    let response: ApprovalResponse
    let onRequest: @Sendable (ApprovalRequest) async -> Void

    init(response: ApprovalResponse, onRequest: @escaping @Sendable (ApprovalRequest) async -> Void = { _ in }) {
        self.response = response
        self.onRequest = onRequest
    }

    func requestApproval(_ request: ApprovalRequest) async throws -> ApprovalResponse {
        await onRequest(request)
        return response
    }
}

/// A handler that delays before responding, useful for timeout tests.
private struct DelayedApprovalHandler: HumanApprovalHandler {
    let delay: Duration
    let response: ApprovalResponse

    func requestApproval(_ request: ApprovalRequest) async throws -> ApprovalResponse {
        try await Task.sleep(for: delay)
        return response
    }
}

@Suite("HumanApproval -- Human-in-the-Loop")
struct HumanApprovalTests {
    @Test("HumanApproval with auto-approve handler continues workflow")
    func autoApproveHandler() async throws {
        let step = HumanApproval(
            "Approve this?",
            handler: AutoApproveHandler()
        )

        let result = try await step.execute("workflow data", hooks: nil)
        #expect(result.output == "workflow data")
        #expect(result.metadata["approval.response"]?.stringValue == "approved")
    }

    @Test("HumanApproval without handler auto-approves")
    func noHandlerAutoApproves() async throws {
        let step = HumanApproval("Approve this?")

        let result = try await step.execute("data", hooks: nil)
        #expect(result.output == "data")
        #expect(result.metadata["approval.response"]?.stringValue == "approved")
    }

    @Test("HumanApproval metadata includes prompt")
    func metadataIncludesPrompt() async throws {
        let step = HumanApproval(
            "Review the analysis results?",
            handler: AutoApproveHandler()
        )

        let result = try await step.execute("analysis output", hooks: nil)
        #expect(result.metadata["approval.prompt"]?.stringValue == "Review the analysis results?")
    }

    @Test("HumanApproval metadata includes wait duration")
    func metadataIncludesWaitDuration() async throws {
        let step = HumanApproval(
            "Approve?",
            handler: AutoApproveHandler()
        )

        let result = try await step.execute("data", hooks: nil)
        let waitDuration = result.metadata["approval.wait_duration"]?.doubleValue
        #expect(waitDuration != nil)
        #expect(waitDuration! >= 0)
    }

    @Test("HumanApproval rejected throws error")
    func rejectedThrowsError() async throws {
        let step = HumanApproval(
            "Approve this?",
            handler: RecordingApprovalHandler(response: .rejected(reason: "Looks wrong"))
        )

        await #expect(throws: OrchestrationError.self) {
            try await step.execute("data", hooks: nil)
        }
    }

    @Test("HumanApproval rejected error contains prompt and reason")
    func rejectedErrorDetails() async throws {
        let step = HumanApproval(
            "Review output?",
            handler: RecordingApprovalHandler(response: .rejected(reason: "Invalid format"))
        )

        do {
            _ = try await step.execute("data", hooks: nil)
            Issue.record("Expected error to be thrown")
        } catch let error as OrchestrationError {
            #expect(error == .humanApprovalRejected(prompt: "Review output?", reason: "Invalid format"))
        }
    }

    @Test("HumanApproval modified replaces output")
    func modifiedReplacesOutput() async throws {
        let step = HumanApproval(
            "Approve?",
            handler: RecordingApprovalHandler(response: .modified(newInput: "corrected data"))
        )

        let result = try await step.execute("original data", hooks: nil)
        #expect(result.output == "corrected data")
        #expect(result.metadata["approval.response"]?.stringValue == "modified")
    }

    @Test("HumanApproval handler receives correct request data")
    func handlerReceivesCorrectRequest() async throws {
        let capture = RequestCapture()
        let step = HumanApproval(
            "Check results?",
            handler: RecordingApprovalHandler(
                response: .approved,
                onRequest: { request in
                    await capture.store(request)
                }
            )
        )

        _ = try await step.execute("workflow output", hooks: nil)

        let capturedRequest = await capture.value
        #expect(capturedRequest != nil)
        #expect(capturedRequest?.prompt == "Check results?")
        #expect(capturedRequest?.currentOutput == "workflow output")
    }

    @Test("HumanApproval timeout throws error")
    func timeoutThrowsError() async throws {
        let step = HumanApproval(
            "Approve quickly?",
            timeout: .milliseconds(50),
            handler: DelayedApprovalHandler(
                delay: .seconds(10),
                response: .approved
            )
        )

        await #expect(throws: OrchestrationError.self) {
            try await step.execute("data", hooks: nil)
        }
    }

    @Test("HumanApproval fast response beats timeout")
    func fastResponseBeatsTimeout() async throws {
        let step = HumanApproval(
            "Approve?",
            timeout: .seconds(10),
            handler: DelayedApprovalHandler(
                delay: .milliseconds(10),
                response: .approved
            )
        )

        let result = try await step.execute("data", hooks: nil)
        #expect(result.output == "data")
        #expect(result.metadata["approval.response"]?.stringValue == "approved")
    }

    @Test("HumanApproval in Sequential workflow")
    func humanApprovalInSequential() async throws {
        let workflow = Orchestration {
            Sequential {
                NPUppercaseAgent()
                HumanApproval("Review uppercase result?", handler: AutoApproveHandler())
                NPPrefixAgent(prefix: "APPROVED:")
            }
        }

        let result = try await workflow.run("hello")
        #expect(result.output == "APPROVED:HELLO")
    }

    @Test("HumanApproval modified input flows to next step")
    func modifiedInputFlowsToNextStep() async throws {
        let workflow = Orchestration {
            Sequential {
                NPUppercaseAgent()
                HumanApproval(
                    "Review?",
                    handler: RecordingApprovalHandler(response: .modified(newInput: "human-corrected"))
                )
                NPPrefixAgent(prefix: "NEXT:")
            }
        }

        let result = try await workflow.run("hello")
        #expect(result.output == "NEXT:human-corrected")
    }
}

// MARK: - Integration Tests

@Suite("New Primitives -- Integration")
struct NewPrimitivesIntegrationTests {
    @Test("Branch followed by RepeatWhile in Sequential")
    func branchThenRepeatWhile() async throws {
        let workflow = Orchestration {
            Sequential {
                Branch({ $0.count > 3 }) {
                    NPUppercaseAgent()
                } otherwise: {
                    NPEchoAgent()
                }
                RepeatWhile(maxIterations: 2, condition: { _ in true }) {
                    NPPrefixAgent(prefix: ">")
                }
            }
        }

        let result = try await workflow.run("hello")
        #expect(result.output == ">>HELLO")
    }

    @Test("RepeatWhile with Branch inside body")
    func repeatWhileWithBranchBody() async throws {
        // Use output length to control iterations: stop when length >= 3
        let step = RepeatWhile(maxIterations: 3, condition: { output in
            output.count < 3  // "x"->true, "+x"->true, "++x"->false
        }) {
            Branch({ $0.count < 10 }) {
                NPPrefixAgent(prefix: "+")
            } otherwise: {
                NPEchoAgent()
            }
        }

        let result = try await step.execute("x", hooks: nil)
        // First iteration: "x" (count < 10) -> "+x"
        // Second iteration: "+x" (count < 10) -> "++x"
        #expect(result.output == "++x")
    }

    @Test("Multiple Branches in Sequential")
    func multipleBranchesInSequential() async throws {
        let workflow = Orchestration {
            Sequential {
                Branch({ $0.contains("hello") }) {
                    NPUppercaseAgent()
                }
                Branch({ $0.contains("HELLO") }) {
                    NPPrefixAgent(prefix: "MATCHED:")
                } otherwise: {
                    NPPrefixAgent(prefix: "MISSED:")
                }
            }
        }

        let result = try await workflow.run("hello world")
        #expect(result.output == "MATCHED:HELLO WORLD")
    }
}
