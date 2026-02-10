// HiveStep.swift
// Swarm Framework
//
// Escape hatch for injecting raw Hive node closures into Swarm orchestrations,
// and an Interrupt step for workflow interruption.

import Foundation

// MARK: - Interrupt

/// A step that interrupts the workflow by throwing `OrchestrationError.workflowInterrupted`.
///
/// `Interrupt` halts workflow execution at the point where it appears. The payload
/// builder transforms the current input into the interruption reason.
///
/// Example:
/// ```swift
/// Sequential {
///     preprocessAgent
///     Interrupt { "Human review needed: \($0)" }
///     // This step is never reached
///     postprocessAgent
/// }
/// ```
public struct Interrupt: OrchestrationStep, Sendable {
    /// Transforms the current input into the interruption payload.
    public let payloadBuilder: @Sendable (String) -> String

    /// Creates a new interrupt step.
    /// - Parameter payloadBuilder: A closure that transforms the current input into
    ///   the interruption reason. Defaults to identity (passes input through as-is).
    public init(_ payloadBuilder: @escaping @Sendable (String) -> String = { $0 }) {
        self.payloadBuilder = payloadBuilder
    }

    public func execute(_ input: String, context: OrchestrationStepContext) async throws -> AgentResult {
        throw OrchestrationError.workflowInterrupted(reason: payloadBuilder(input))
    }
}

// MARK: - HiveStep (Hive Runtime)

#if SWARM_HIVE_RUNTIME && canImport(HiveCore)

import HiveCore

/// An escape hatch that injects a raw Hive node closure into a Swarm orchestration.
///
/// When running under the Hive runtime, `HiveStep`'s `nodeFactory` is emitted directly
/// as a Hive graph node during compilation, giving full access to `HiveNodeInput` and
/// `HiveNodeOutput`. When running under the Swift runtime, the step acts as a passthrough.
///
/// Example:
/// ```swift
/// Orchestration(configuration: .init(runtimeMode: .hive)) {
///     Sequential {
///         preprocessAgent
///         HiveStep { input in
///             let currentInput = try input.store.get(OrchestrationHiveEngine.Schema.currentInputKey)
///             // Custom Hive-level processing...
///             return HiveNodeOutput(writes: [
///                 AnyHiveWrite(OrchestrationHiveEngine.Schema.currentInputKey, currentInput)
///             ])
///         }
///         postprocessAgent
///     }
/// }
/// ```
public struct HiveStep: OrchestrationStep, Sendable {
    /// The raw Hive node closure to inject into the graph.
    let nodeFactory: @Sendable (HiveNodeInput<OrchestrationHiveEngine.Schema>) async throws
        -> HiveNodeOutput<OrchestrationHiveEngine.Schema>

    /// Creates a new HiveStep with a raw Hive node closure.
    /// - Parameter node: A closure that receives `HiveNodeInput` and returns `HiveNodeOutput`.
    init(
        _ node: @escaping @Sendable (HiveNodeInput<OrchestrationHiveEngine.Schema>) async throws
            -> HiveNodeOutput<OrchestrationHiveEngine.Schema>
    ) {
        nodeFactory = node
    }

    /// Direct execution fallback for Swift runtime mode.
    ///
    /// When HiveStep is executed directly (not compiled into a Hive graph),
    /// it acts as a passthrough, preserving the input unchanged.
    public func execute(_ input: String, context: OrchestrationStepContext) async throws -> AgentResult {
        AgentResult(output: input, metadata: ["hive_step.direct": .bool(true)])
    }
}

#else

/// An escape hatch for injecting custom processing into orchestrations.
///
/// When the Hive runtime is not available, `HiveStep` accepts a simple string
/// transform closure. In Swift runtime mode the step acts as a passthrough,
/// preserving the input unchanged. The closure is stored but only used when
/// compiled into a Hive graph (which requires the Hive runtime).
///
/// Example:
/// ```swift
/// HiveStep { input in
///     // This closure is stored but not invoked in Swift-only mode.
///     "transformed: \(input)"
/// }
/// ```
public struct HiveStep: OrchestrationStep, Sendable {
    /// Stored closure (used only during Hive graph compilation).
    public let transform: @Sendable (String) -> String

    /// Creates a new HiveStep with a transform closure.
    /// - Parameter transform: A closure stored for Hive graph compilation.
    ///   In Swift runtime mode the step is a passthrough.
    public init(_ transform: @escaping @Sendable (String) -> String) {
        self.transform = transform
    }

    /// Direct execution: passthrough with metadata indicating direct mode.
    public func execute(_ input: String, context: OrchestrationStepContext) async throws -> AgentResult {
        AgentResult(output: input, metadata: ["hive_step.direct": .bool(true)])
    }
}

#endif
