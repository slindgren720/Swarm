// OrchestrationError.swift
// SwiftAgents Framework
//
// Comprehensive error types for multi-agent orchestration operations.

import Foundation

/// Errors that can occur during multi-agent orchestration.
public enum OrchestrationError: Error, Sendable, Equatable {
    // MARK: - Agent Registration Errors

    /// An agent with the given name was not found in the orchestrator.
    case agentNotFound(name: String)

    /// No agents are configured in the orchestrator.
    case noAgentsConfigured

    // MARK: - Handoff Errors

    /// Agent handoff failed between source and target agents.
    case handoffFailed(source: String, target: String, reason: String)

    // MARK: - Routing Errors

    /// Routing decision failed to determine the next agent.
    case routingFailed(reason: String)

    /// Route condition is invalid or cannot be evaluated.
    case invalidRouteCondition(reason: String)

    // MARK: - Parallel Execution Errors

    /// Merge strategy failed to combine parallel agent results.
    case mergeStrategyFailed(reason: String)

    /// All agents in parallel execution failed.
    case allAgentsFailed(errors: [String])
}

// MARK: - LocalizedError Conformance

extension OrchestrationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .agentNotFound(let name):
            return "Agent not found: \(name)"
        case .noAgentsConfigured:
            return "No agents configured in orchestrator"
        case .handoffFailed(let source, let target, let reason):
            return "Handoff failed from '\(source)' to '\(target)': \(reason)"
        case .routingFailed(let reason):
            return "Routing decision failed: \(reason)"
        case .invalidRouteCondition(let reason):
            return "Invalid route condition: \(reason)"
        case .mergeStrategyFailed(let reason):
            return "Merge strategy failed: \(reason)"
        case .allAgentsFailed(let errors):
            let errorList = errors.joined(separator: ", ")
            return "All parallel agents failed: [\(errorList)]"
        }
    }
}

// MARK: - CustomDebugStringConvertible

extension OrchestrationError: CustomDebugStringConvertible {
    public var debugDescription: String {
        "OrchestrationError.\(self)"
    }
}
