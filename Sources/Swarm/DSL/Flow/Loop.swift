// Loop.swift
// Swarm Framework
//
// DSL-friendly loop step for orchestration workflows.

import Foundation

// MARK: - Loop

/// Repeats child steps until a condition is met.
///
/// `Loop` provides a DSL-friendly alternative to `RepeatWhile` with
/// enum-based conditions that make the loop's intent self-documenting.
///
/// In Swift runtime, uses a simple while loop. In Hive runtime, compiles
/// to a single-node approach with an internal loop.
///
/// Example:
/// ```swift
/// Loop(.maxIterations(5)) {
///     refinementAgent
/// }
///
/// Loop(.until({ $0.contains("DONE") })) {
///     processingAgent
/// }
///
/// Loop(.whileTrue({ $0.count < 100 })) {
///     expansionAgent
/// }
/// ```
public struct Loop: OrchestrationStep {
    /// The condition controlling loop termination.
    public enum Condition: Sendable {
        /// Loop exactly N times.
        case maxIterations(Int)

        /// Loop until the predicate returns `true` (checked before each iteration).
        case until(@Sendable (String) async -> Bool)

        /// Loop while the predicate returns `true` (checked before each iteration).
        case whileTrue(@Sendable (String) async -> Bool)
    }

    /// The condition controlling this loop.
    public let condition: Condition

    /// The step to execute on each iteration.
    public let body: OrchestrationStep

    /// Creates a new loop step.
    ///
    /// - Parameters:
    ///   - condition: The condition controlling loop termination.
    ///   - content: A builder closure producing the step to execute on each iteration.
    public init(
        _ condition: Condition,
        @OrchestrationBuilder _ content: () -> OrchestrationStep
    ) {
        self.condition = condition
        self.body = content()
    }

    public func execute(_ input: String, context: OrchestrationStepContext) async throws -> AgentResult {
        let startTime = ContinuousClock.now
        var currentInput = input
        var allToolCalls: [ToolCall] = []
        var allToolResults: [ToolResult] = []
        var totalIterations = 0
        var allMetadata: [String: SendableValue] = [:]
        var count = 0

        let maxIter: Int
        let shouldContinue: @Sendable (String) async -> Bool

        switch condition {
        case .maxIterations(let n):
            maxIter = n
            shouldContinue = { _ in true }
        case .until(let predicate):
            maxIter = 1000 // safety cap
            shouldContinue = { input in !(await predicate(input)) }
        case .whileTrue(let predicate):
            maxIter = 1000 // safety cap
            shouldContinue = predicate
        }

        while count < maxIter, await shouldContinue(currentInput) {
            let result = try await body.execute(currentInput, context: context)
            allToolCalls.append(contentsOf: result.toolCalls)
            allToolResults.append(contentsOf: result.toolResults)
            totalIterations += result.iterationCount
            for (key, value) in result.metadata {
                allMetadata["loop.iter_\(count).\(key)"] = value
            }
            currentInput = result.output
            count += 1
        }

        let duration = ContinuousClock.now - startTime
        allMetadata["loop.iteration_count"] = .int(count)
        allMetadata["loop.duration"] = .double(
            Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
        )

        return AgentResult(
            output: currentInput,
            toolCalls: allToolCalls,
            toolResults: allToolResults,
            iterationCount: totalIterations,
            duration: duration,
            tokenUsage: nil,
            metadata: allMetadata
        )
    }
}

// MARK: - Loop + _AgentLoopNestedSteps

extension Loop: _AgentLoopNestedSteps {
    var _nestedSteps: [OrchestrationStep] { [body] }
}
