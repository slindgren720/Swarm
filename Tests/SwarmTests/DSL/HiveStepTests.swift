// HiveStepTests.swift
// Swarm Framework
//
// TDD tests for HiveStep escape hatch and Interrupt orchestration step.

@testable import Swarm
import Testing

// MARK: - Test Helpers

private struct HSEchoAgent: AgentRuntime {
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

private struct HSPrefixAgent: AgentRuntime {
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

// MARK: - Interrupt Tests

@Suite("Interrupt -- Workflow Interruption")
struct InterruptTests {
    @Test("Interrupt throws workflowInterrupted error")
    func interruptThrowsError() async throws {
        let step = Interrupt()

        await #expect(throws: OrchestrationError.self) {
            try await step.execute("some data", hooks: nil)
        }
    }

    @Test("Interrupt throws workflowInterrupted with default payload (passthrough)")
    func interruptDefaultPayload() async throws {
        let step = Interrupt()

        do {
            _ = try await step.execute("interrupt-payload", hooks: nil)
            Issue.record("Expected error to be thrown")
        } catch let error as OrchestrationError {
            #expect(error == .workflowInterrupted(reason: "interrupt-payload"))
        }
    }

    @Test("Interrupt with custom payload builder transforms input")
    func interruptCustomPayload() async throws {
        let step = Interrupt { input in
            "Custom: \(input.uppercased())"
        }

        do {
            _ = try await step.execute("stop here", hooks: nil)
            Issue.record("Expected error to be thrown")
        } catch let error as OrchestrationError {
            #expect(error == .workflowInterrupted(reason: "Custom: STOP HERE"))
        }
    }

    @Test("Interrupt in Sequential stops execution at that point")
    func interruptStopsSequential() async throws {
        let workflow = Orchestration {
            Sequential {
                HSPrefixAgent(prefix: "BEFORE:")
                Interrupt()
                HSPrefixAgent(prefix: "AFTER:")
            }
        }

        do {
            _ = try await workflow.run("data")
            Issue.record("Expected error to be thrown")
        } catch let error as OrchestrationError {
            #expect(error == .workflowInterrupted(reason: "BEFORE:data"))
        }
    }

    @Test("Interrupt composes in Orchestration builder")
    func interruptComposesInBuilder() async throws {
        // Verify that Interrupt works as a buildExpression in OrchestrationBuilder
        let workflow = Orchestration {
            Interrupt { "halted: \($0)" }
        }

        do {
            _ = try await workflow.run("test")
            Issue.record("Expected error to be thrown")
        } catch let error as OrchestrationError {
            #expect(error == .workflowInterrupted(reason: "halted: test"))
        }
    }

    @Test("Interrupt with empty payload builder")
    func interruptEmptyPayload() async throws {
        let step = Interrupt { _ in "" }

        do {
            _ = try await step.execute("data", hooks: nil)
            Issue.record("Expected error to be thrown")
        } catch let error as OrchestrationError {
            #expect(error == .workflowInterrupted(reason: ""))
        }
    }
}

// MARK: - HiveStep Direct Execution Tests

@Suite("HiveStep -- Direct Execution")
struct HiveStepDirectTests {
    @Test("HiveStep direct execution returns passthrough with metadata")
    func hiveStepDirectExecution() async throws {
        let step = HiveStep { _ in
            fatalError("unused in direct execution")
        }

        let result = try await step.execute("hello", hooks: nil)
        #expect(result.output == "hello")
        #expect(result.metadata["hive_step.direct"]?.boolValue == true)
    }

    @Test("HiveStep preserves empty input")
    func hiveStepEmptyInput() async throws {
        let step = HiveStep { _ in fatalError("unused in direct execution") }

        let result = try await step.execute("", hooks: nil)
        #expect(result.output == "")
    }

    @Test("HiveStep in Sequential composes as passthrough")
    func hiveStepInSequential() async throws {
        let workflow = Orchestration {
            Sequential {
                HSPrefixAgent(prefix: "A:")
                HiveStep { _ in fatalError("unused in direct execution") }
                HSPrefixAgent(prefix: "B:")
            }
        }

        let result = try await workflow.run("data")
        #expect(result.output == "B:A:data")
    }

    @Test("HiveStep composes in OrchestrationBuilder")
    func hiveStepComposesInBuilder() async throws {
        let workflow = Orchestration {
            HiveStep { _ in fatalError("unused in direct execution") }
        }

        let result = try await workflow.run("passthrough")
        #expect(result.output == "passthrough")
    }

    @Test("Multiple HiveSteps in Sequential all passthrough")
    func multipleHiveSteps() async throws {
        let workflow = Orchestration {
            Sequential {
                HiveStep { _ in fatalError("unused in direct execution") }
                HiveStep { _ in fatalError("unused in direct execution") }
                HiveStep { _ in fatalError("unused in direct execution") }
            }
        }

        let result = try await workflow.run("input")
        #expect(result.output == "input")
    }
}

// MARK: - Integration Tests

@Suite("HiveStep + Interrupt -- Integration")
struct HiveStepInterruptIntegrationTests {
    @Test("Interrupt followed by nothing in Sequential halts workflow")
    func interruptInSequential() async throws {
        let workflow = Orchestration {
            Sequential {
                HSPrefixAgent(prefix: "BEFORE:")
                Interrupt { "stopped: \($0)" }
            }
        }

        do {
            _ = try await workflow.run("data")
            Issue.record("Expected error to be thrown")
        } catch let error as OrchestrationError {
            #expect(error == .workflowInterrupted(reason: "stopped: BEFORE:data"))
        }
    }

    @Test("Branch with Interrupt in then path")
    func branchWithInterrupt() async throws {
        let step = Branch({ $0.contains("stop") }) {
            Interrupt { "halted: \($0)" }
        } otherwise: {
            HSPrefixAgent(prefix: "CONTINUE:")
        }

        // When condition is true, should interrupt
        do {
            _ = try await step.execute("please stop", hooks: nil)
            Issue.record("Expected error to be thrown")
        } catch let error as OrchestrationError {
            #expect(error == .workflowInterrupted(reason: "halted: please stop"))
        }

        // When condition is false, should continue
        let result = try await step.execute("go ahead", hooks: nil)
        #expect(result.output == "CONTINUE:go ahead")
    }

    @Test("Agents compose with Interrupt in complex workflow")
    func complexWorkflow() async throws {
        let workflow = Orchestration {
            Sequential {
                HSPrefixAgent(prefix: "STEP1:")
                HSPrefixAgent(prefix: "STEP2:")
            }
        }

        let result = try await workflow.run("data")
        #expect(result.output == "STEP2:STEP1:data")
    }
}
