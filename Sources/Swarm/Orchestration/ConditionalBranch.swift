// ConditionalBranch.swift
// Swarm Framework
//
// Conditional branching primitive for orchestration workflows.

import Foundation

// MARK: - NoOpStep

/// A step that passes input through unchanged.
///
/// `NoOpStep` is a passthrough step used as the default `otherwise` branch
/// in `Branch` when no explicit alternative is provided.
///
/// Example:
/// ```swift
/// let step = NoOpStep()
/// let result = try await step.execute("hello", hooks: nil)
/// // result.output == "hello"
/// ```
public struct NoOpStep: OrchestrationStep, Sendable {
    public init() {}

    public func execute(_ input: String, context _: OrchestrationStepContext) async throws -> AgentResult {
        AgentResult(output: input)
    }
}

// MARK: - Branch

/// A step that conditionally routes to different sub-workflows based on runtime state.
///
/// `Branch` evaluates a condition against the current input and executes either
/// the `then` branch or the `otherwise` branch. If no `otherwise` branch is
/// provided, input passes through unchanged via `NoOpStep`.
///
/// Example:
/// ```swift
/// Branch({ $0.contains("urgent") }) {
///     urgentHandlerAgent
/// } otherwise: {
///     normalHandlerAgent
/// }
/// ```
///
/// Nested branches compose naturally:
/// ```swift
/// Branch({ $0.count > 10 }) {
///     Branch({ $0.contains("code") }) {
///         codeAgent
///     } otherwise: {
///         generalAgent
///     }
/// } otherwise: {
///     shortInputAgent
/// }
/// ```
public struct Branch: OrchestrationStep, Sendable {
    /// The condition that determines which branch to take.
    public let condition: @Sendable (String) async -> Bool

    /// The step to execute when the condition is true.
    public let ifTrue: any OrchestrationStep

    /// The step to execute when the condition is false.
    public let ifFalse: any OrchestrationStep

    /// Creates a new conditional branch.
    /// - Parameters:
    ///   - condition: A closure that evaluates the current input and returns `true` or `false`.
    ///   - ifTrue: A builder closure producing the step to execute when the condition is true.
    ///   - ifFalse: A builder closure producing the step to execute when the condition is false.
    ///     Defaults to `NoOpStep()` (passthrough).
    public init(
        _ condition: @escaping @Sendable (String) async -> Bool,
        @OrchestrationBuilder then ifTrue: () -> OrchestrationStep,
        @OrchestrationBuilder otherwise ifFalse: () -> OrchestrationStep = { NoOpStep() }
    ) {
        self.condition = condition
        self.ifTrue = ifTrue()
        self.ifFalse = ifFalse()
    }

    public func execute(_ input: String, context: OrchestrationStepContext) async throws -> AgentResult {
        let startTime = ContinuousClock.now

        let conditionResult = await condition(input)

        let result: AgentResult
        let pathTaken: String

        if conditionResult {
            result = try await ifTrue.execute(input, context: context)
            pathTaken = "then"
        } else {
            result = try await ifFalse.execute(input, context: context)
            pathTaken = "otherwise"
        }

        let duration = ContinuousClock.now - startTime

        // Merge child result metadata with branch prefix
        var metadata: [String: SendableValue] = [:]
        for (key, value) in result.metadata {
            metadata["branch.\(key)"] = value
        }
        metadata["branch.took_path"] = .string(pathTaken)
        metadata["branch.duration"] = .double(
            Double(duration.components.seconds) +
                Double(duration.components.attoseconds) / 1e18
        )

        return AgentResult(
            output: result.output,
            toolCalls: result.toolCalls,
            toolResults: result.toolResults,
            iterationCount: result.iterationCount,
            duration: duration,
            tokenUsage: result.tokenUsage,
            metadata: metadata
        )
    }
}

extension Branch: _AgentLoopNestedSteps {
    var _nestedSteps: [OrchestrationStep] { [ifTrue, ifFalse] }
}
