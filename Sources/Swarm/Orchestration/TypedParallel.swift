// TypedParallel.swift
// Swarm Framework
//
// Type-safe parallel execution that preserves individual agent results as tuples.

import Foundation

// MARK: - TypedParallel

/// Type-safe parallel execution that preserves individual results.
///
/// Unlike `Parallel` (which merges results into a single `AgentResult`),
/// `TypedParallel` returns a tuple of results — one per agent — so callers
/// can inspect each agent's output independently.
///
/// Fixed-arity overloads (2 through 5 agents) are provided instead of
/// parameter packs for maximum compiler compatibility.
///
/// Example:
/// ```swift
/// let (analysis, summary) = try await TypedParallel.run(
///     analysisAgent, summaryAgent,
///     input: "Review this document..."
/// )
/// print(analysis.output)  // detailed analysis
/// print(summary.output)   // brief summary
/// ```
public enum TypedParallel {
    /// Executes 2 agents in parallel, returning a typed tuple of results.
    /// - Parameters:
    ///   - a1: The first agent to run.
    ///   - a2: The second agent to run.
    ///   - input: The input string passed to all agents.
    ///   - session: Optional session for conversation history.
    ///   - hooks: Optional hooks for lifecycle callbacks.
    /// - Returns: A tuple of two `AgentResult` values.
    public static func run(
        _ a1: any AgentRuntime,
        _ a2: any AgentRuntime,
        input: String,
        session: (any Session)? = nil,
        hooks: (any RunHooks)? = nil
    ) async throws -> (AgentResult, AgentResult) {
        async let r1 = a1.run(input, session: session, hooks: hooks)
        async let r2 = a2.run(input, session: session, hooks: hooks)
        return try await (r1, r2)
    }

    /// Executes 3 agents in parallel, returning a typed tuple of results.
    /// - Parameters:
    ///   - a1: The first agent to run.
    ///   - a2: The second agent to run.
    ///   - a3: The third agent to run.
    ///   - input: The input string passed to all agents.
    ///   - session: Optional session for conversation history.
    ///   - hooks: Optional hooks for lifecycle callbacks.
    /// - Returns: A tuple of three `AgentResult` values.
    public static func run(
        _ a1: any AgentRuntime,
        _ a2: any AgentRuntime,
        _ a3: any AgentRuntime,
        input: String,
        session: (any Session)? = nil,
        hooks: (any RunHooks)? = nil
    ) async throws -> (AgentResult, AgentResult, AgentResult) {
        async let r1 = a1.run(input, session: session, hooks: hooks)
        async let r2 = a2.run(input, session: session, hooks: hooks)
        async let r3 = a3.run(input, session: session, hooks: hooks)
        return try await (r1, r2, r3)
    }

    /// Executes 4 agents in parallel, returning a typed tuple of results.
    /// - Parameters:
    ///   - a1: The first agent to run.
    ///   - a2: The second agent to run.
    ///   - a3: The third agent to run.
    ///   - a4: The fourth agent to run.
    ///   - input: The input string passed to all agents.
    ///   - session: Optional session for conversation history.
    ///   - hooks: Optional hooks for lifecycle callbacks.
    /// - Returns: A tuple of four `AgentResult` values.
    public static func run(
        _ a1: any AgentRuntime,
        _ a2: any AgentRuntime,
        _ a3: any AgentRuntime,
        _ a4: any AgentRuntime,
        input: String,
        session: (any Session)? = nil,
        hooks: (any RunHooks)? = nil
    ) async throws -> (AgentResult, AgentResult, AgentResult, AgentResult) {
        async let r1 = a1.run(input, session: session, hooks: hooks)
        async let r2 = a2.run(input, session: session, hooks: hooks)
        async let r3 = a3.run(input, session: session, hooks: hooks)
        async let r4 = a4.run(input, session: session, hooks: hooks)
        return try await (r1, r2, r3, r4)
    }

    /// Executes 5 agents in parallel, returning a typed tuple of results.
    /// - Parameters:
    ///   - a1: The first agent to run.
    ///   - a2: The second agent to run.
    ///   - a3: The third agent to run.
    ///   - a4: The fourth agent to run.
    ///   - a5: The fifth agent to run.
    ///   - input: The input string passed to all agents.
    ///   - session: Optional session for conversation history.
    ///   - hooks: Optional hooks for lifecycle callbacks.
    /// - Returns: A tuple of five `AgentResult` values.
    public static func run(
        _ a1: any AgentRuntime,
        _ a2: any AgentRuntime,
        _ a3: any AgentRuntime,
        _ a4: any AgentRuntime,
        _ a5: any AgentRuntime,
        input: String,
        session: (any Session)? = nil,
        hooks: (any RunHooks)? = nil
    ) async throws -> (AgentResult, AgentResult, AgentResult, AgentResult, AgentResult) {
        async let r1 = a1.run(input, session: session, hooks: hooks)
        async let r2 = a2.run(input, session: session, hooks: hooks)
        async let r3 = a3.run(input, session: session, hooks: hooks)
        async let r4 = a4.run(input, session: session, hooks: hooks)
        async let r5 = a5.run(input, session: session, hooks: hooks)
        return try await (r1, r2, r3, r4, r5)
    }
}
