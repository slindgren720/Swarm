// RepeatWhile.swift
// Swarm Framework
//
// Loop primitive for orchestration workflows.

import Foundation

// MARK: - RepeatWhile

/// A step that repeatedly executes its body while a condition holds.
///
/// `RepeatWhile` provides loop semantics within orchestration workflows.
/// The body is executed repeatedly as long as the condition returns `true`,
/// up to a maximum number of iterations to prevent infinite loops.
///
/// The condition is evaluated **before** each iteration using the current
/// output. If the condition is `false` on the first check, the body is
/// never executed and the input passes through unchanged.
///
/// Example:
/// ```swift
/// RepeatWhile(maxIterations: 5, condition: { !$0.contains("DONE") }) {
///     refinementAgent
/// }
/// ```
///
/// With a transform body:
/// ```swift
/// RepeatWhile(maxIterations: 3, condition: { _ in true }) {
///     Transform { $0 + " iteration" }
/// }
/// ```
public struct RepeatWhile: OrchestrationStep, Sendable {
    /// The step to execute on each iteration.
    public let body: any OrchestrationStep

    /// The condition evaluated before each iteration.
    public let condition: @Sendable (String) async throws -> Bool

    /// The maximum number of iterations allowed.
    public let maxIterations: Int

    /// Creates a new repeat-while loop step.
    /// - Parameters:
    ///   - maxIterations: Maximum number of iterations before forced termination. Default: 10
    ///   - condition: A closure evaluated before each iteration. The loop continues while this returns `true`.
    ///   - body: A builder closure producing the step to execute on each iteration.
    public init(
        maxIterations: Int = 10,
        condition: @escaping @Sendable (String) async throws -> Bool,
        @OrchestrationBuilder body: () -> OrchestrationStep
    ) {
        precondition(maxIterations > 0, "maxIterations must be positive")
        self.maxIterations = maxIterations
        self.condition = condition
        self.body = body()
    }

    public func execute(_ input: String, context: OrchestrationStepContext) async throws -> AgentResult {
        let startTime = ContinuousClock.now

        var currentInput = input
        var allToolCalls: [ToolCall] = []
        var allToolResults: [ToolResult] = []
        var totalIterations = 0
        var allMetadata: [String: SendableValue] = [:]
        var count = 0

        while count < maxIterations {
            guard try await condition(currentInput) else { break }

            let result = try await body.execute(currentInput, context: context)

            // Accumulate tool calls and results
            allToolCalls.append(contentsOf: result.toolCalls)
            allToolResults.append(contentsOf: result.toolResults)
            totalIterations += result.iterationCount

            // Merge iteration metadata with iteration-prefixed keys
            for (key, value) in result.metadata {
                allMetadata["repeatwhile.iter_\(count)_\(key)"] = value
            }

            currentInput = result.output
            count += 1
        }

        let duration = ContinuousClock.now - startTime
        let terminatedBy = count >= maxIterations ? "maxIterations" : "condition"

        allMetadata["repeatwhile.iteration_count"] = .int(count)
        allMetadata["repeatwhile.terminated_by"] = .string(terminatedBy)
        allMetadata["repeatwhile.duration"] = .double(
            Double(duration.components.seconds) +
                Double(duration.components.attoseconds) / 1e18
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

extension RepeatWhile: _AgentLoopNestedSteps {
    var _nestedSteps: [OrchestrationStep] { [body] }
}
