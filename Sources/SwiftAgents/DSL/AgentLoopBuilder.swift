// AgentLoopBuilder.swift
// SwiftAgents Framework
//
// Result builder for constructing sequential `AgentLoop` values.

import Foundation

/// A result builder that constructs a sequential `AgentLoop`.
///
/// Within an `AgentLoopBuilder` block, each statement is executed in order.
@resultBuilder
public struct AgentLoopBuilder {
    public static func buildBlock(_ components: AgentLoop...) -> AgentLoop {
        AgentLoop(steps: components.flatMap(\.steps))
    }

    public static func buildOptional(_ component: AgentLoop?) -> AgentLoop {
        component ?? AgentLoop(steps: [])
    }

    public static func buildEither(first component: AgentLoop) -> AgentLoop { component }
    public static func buildEither(second component: AgentLoop) -> AgentLoop { component }

    public static func buildArray(_ components: [AgentLoop]) -> AgentLoop {
        AgentLoop(steps: components.flatMap(\.steps))
    }

    public static func buildExpression(_ loop: AgentLoop) -> AgentLoop { loop }

    public static func buildExpression(_ step: OrchestrationStep) -> AgentLoop {
        AgentLoop(steps: [step])
    }

    public static func buildExpression(_ agent: any AgentRuntime) -> AgentLoop {
        AgentLoop(steps: [AgentStep(agent)])
    }

    public static func buildExpression<A: Agent>(_ agent: A) -> AgentLoop {
        AgentLoop(steps: [LoopAgentStep(agent)])
    }
}

