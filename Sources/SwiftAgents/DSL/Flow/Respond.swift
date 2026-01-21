// Respond.swift
// SwiftAgents Framework
//
// Core LLM execution step for declarative `Agent` loops.

import Foundation

/// Executes the current `Agent`'s core model step.
///
/// Place `Respond()` in an agent's `loop` to make the "LLM turn" explicit.
/// The response becomes the next step's input.
public struct Respond: OrchestrationStep {
    public init() {}

    public func execute(_ input: String, context: OrchestrationStepContext) async throws -> AgentResult {
        guard let orchestrator = context.orchestrator as? any _LoopOrchestrator else {
            throw AgentError.internalError(reason: "Respond() can only be used inside an Agent loop")
        }

        return try await orchestrator._respond(input, session: context.session, hooks: context.hooks)
    }
}

