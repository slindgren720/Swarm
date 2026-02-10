// CallableAgentTests.swift
// SwarmTests
//
// Tests for CallableAgent @dynamicCallable wrapper and callAsFunction extensions.

@testable import Swarm
import Testing

// MARK: - Test Agents

private struct CallableEchoAgent: AgentRuntime {
    let tools: [any AnyJSONTool] = []
    let instructions = "Echo agent"
    let configuration: AgentConfiguration

    init(name: String = "Echo") {
        configuration = AgentConfiguration(name: name)
    }

    func run(
        _ input: String,
        session _: (any Session)? = nil,
        hooks _: (any RunHooks)? = nil
    ) async throws -> AgentResult {
        AgentResult(output: "echo: \(input)")
    }

    nonisolated func stream(
        _ input: String,
        session _: (any Session)? = nil,
        hooks _: (any RunHooks)? = nil
    ) -> AsyncThrowingStream<AgentEvent, Error> {
        StreamHelper.makeTrackedStream { continuation in
            continuation.yield(.started(input: input))
            continuation.yield(.completed(result: AgentResult(output: "echo: \(input)")))
            continuation.finish()
        }
    }

    func cancel() async {}
}

// MARK: - CallableAgentTests

@Suite("CallableAgent Tests")
struct CallableAgentTests {
    // MARK: - @dynamicCallable positional args

    @Test("CallableAgent with single positional argument")
    func callableAgentSinglePositionalArg() async throws {
        let agent = CallableEchoAgent()
        let callable = CallableAgent(agent)

        let result = try await callable("hello")
        #expect(result.output == "echo: hello")
    }

    @Test("CallableAgent with multiple positional arguments joins with space")
    func callableAgentMultiplePositionalArgs() async throws {
        let agent = CallableEchoAgent()
        let callable = CallableAgent(agent)

        let result = try await callable("hello", "world")
        #expect(result.output == "echo: hello world")
    }

    @Test("CallableAgent with empty positional arguments")
    func callableAgentEmptyPositionalArgs() async throws {
        let agent = CallableEchoAgent()
        let callable = CallableAgent(agent)

        let result: AgentResult = try await callable.dynamicallyCall(withArguments: [])
        #expect(result.output == "echo: ")
    }

    // MARK: - @dynamicCallable keyword args

    @Test("CallableAgent with keyword arguments")
    func callableAgentKeywordArgs() async throws {
        let agent = CallableEchoAgent()
        let callable = CallableAgent(agent)

        let result = try await callable(topic: "weather", location: "NYC")
        #expect(result.output.contains("topic: weather"))
        #expect(result.output.contains("location: NYC"))
    }

    // MARK: - callAsFunction on AgentRuntime

    @Test("AgentRuntime callAsFunction delegates to run")
    func agentRuntimeCallAsFunction() async throws {
        let agent = CallableEchoAgent()
        let result = try await agent("hello from callAsFunction")
        #expect(result.output == "echo: hello from callAsFunction")
    }

    // MARK: - callAsFunction on Orchestration

    @Test("Orchestration callAsFunction delegates to run")
    func orchestrationCallAsFunction() async throws {
        let agent = CallableEchoAgent()
        let workflow = Orchestration {
            agent
        }

        let result = try await workflow("orchestrated input")
        #expect(result.output == "echo: orchestrated input")
    }

    // MARK: - CallableAgent is Sendable

    @Test("CallableAgent is Sendable")
    func callableAgentIsSendable() async throws {
        let agent = CallableEchoAgent()
        let callable = CallableAgent(agent)

        // Verify Sendable by passing across isolation boundaries
        let result = try await Task {
            try await callable("concurrent test")
        }.value

        #expect(result.output == "echo: concurrent test")
    }
}
