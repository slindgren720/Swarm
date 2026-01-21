// AgentLoopStep.swift
// SwiftAgents Framework
//
// OrchestrationStep adapter for executing an `AgentLoop` inline.

import Foundation

/// Executes an `AgentLoop` inline within an orchestration.
public struct AgentLoopStep: OrchestrationStep {
    public let loop: AgentLoop

    public init(_ loop: AgentLoop) {
        self.loop = loop
    }

    public init(@AgentLoopBuilder _ content: () -> AgentLoop) {
        loop = content()
    }

    public func execute(_ input: String, context: OrchestrationStepContext) async throws -> AgentResult {
        try await loop.execute(input, context: context)
    }
}

