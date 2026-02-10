// Fallback.swift
// Swarm Framework
//
// Tries a primary step; falls back to a backup on failure.

import Foundation

/// An orchestration step that tries a primary step and falls back to a backup on failure.
///
/// `Fallback` executes the primary step first. If it throws an error, optionally retries
/// up to `maxRetries` times. If all attempts fail, executes the backup step instead.
///
/// Metadata is attached to the result to indicate which path was taken:
/// - `fallback.used`: `true` if the backup was used.
/// - `fallback.primary_error`: Description of the primary step's last error (when backup is used).
/// - `fallback.retries_before_success`: Number of retries before primary succeeded (when retries > 0).
///
/// Example:
/// ```swift
/// Orchestration {
///     FallbackStep(primaryAgent, or: backupAgent, retries: 2)
/// }
/// ```
///
/// Builder-style:
/// ```swift
/// FallbackStep {
///     primaryAgent
/// } fallback: {
///     backupAgent
/// }
/// ```
public struct FallbackStep: OrchestrationStep {
    /// The primary step to attempt first.
    public let primary: OrchestrationStep

    /// The backup step to use if primary fails after all retries.
    public let backup: OrchestrationStep

    /// Number of additional retry attempts for the primary step (0 means try once).
    public let maxRetries: Int

    /// Creates a fallback step from existing steps.
    /// - Parameters:
    ///   - primary: The primary step to attempt.
    ///   - backup: The backup step to use on failure.
    ///   - retries: Number of additional retry attempts. Default: 0
    public init(
        _ primary: OrchestrationStep,
        or backup: OrchestrationStep,
        retries: Int = 0
    ) {
        self.primary = primary
        self.backup = backup
        self.maxRetries = retries
    }

    /// Creates a fallback step using result builder closures.
    /// - Parameters:
    ///   - retries: Number of additional retry attempts. Default: 0
    ///   - primary: Builder closure producing the primary step.
    ///   - fallback: Builder closure producing the backup step.
    public init(
        retries: Int = 0,
        @OrchestrationBuilder primary: () -> OrchestrationStep,
        @OrchestrationBuilder fallback: () -> OrchestrationStep
    ) {
        self.primary = primary()
        self.backup = fallback()
        self.maxRetries = retries
    }

    public func execute(_ input: String, context: OrchestrationStepContext) async throws -> AgentResult {
        var lastError: Error?

        for attempt in 0 ... maxRetries {
            do {
                let result = try await primary.execute(input, context: context)

                // If this succeeded after retries, record the retry count
                if attempt > 0 {
                    var metadata = result.metadata
                    metadata["fallback.retries_before_success"] = .int(attempt)
                    return AgentResult(
                        output: result.output,
                        toolCalls: result.toolCalls,
                        toolResults: result.toolResults,
                        iterationCount: result.iterationCount,
                        duration: result.duration,
                        tokenUsage: result.tokenUsage,
                        metadata: metadata
                    )
                }

                return result
            } catch {
                lastError = error
            }
        }

        // Primary failed after all retries -- use backup
        let result = try await backup.execute(input, context: context)

        var metadata = result.metadata
        metadata["fallback.used"] = .bool(true)
        metadata["fallback.primary_error"] = .string(lastError?.localizedDescription ?? "unknown")

        return AgentResult(
            output: result.output,
            toolCalls: result.toolCalls,
            toolResults: result.toolResults,
            iterationCount: result.iterationCount,
            duration: result.duration,
            tokenUsage: result.tokenUsage,
            metadata: metadata
        )
    }
}
