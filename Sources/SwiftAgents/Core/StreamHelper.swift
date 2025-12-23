//
//  StreamHelper.swift
//  SwiftAgents
//
//  Created as part of audit remediation - Phase 1
//

import Foundation

/// Centralized stream creation utilities with safe defaults
///
/// This utility ensures all streams in SwiftAgents use:
/// - Bounded buffers to prevent memory exhaustion
/// - Proper cancellation handling to prevent resource leaks
///
/// Usage:
/// ```swift
/// // Simple bounded stream
/// let (stream, continuation) = StreamHelper.makeStream()
///
/// // Tracked stream with automatic cancellation
/// let stream = StreamHelper.makeTrackedStream { continuation in
///     // Your async work here
///     continuation.yield(event)
///     continuation.finish()
/// }
/// ```
public enum StreamHelper {
    /// Default buffer size for all streams (prevents unbounded memory growth)
    public static let defaultBufferSize = 100

    /// Create a safe stream with bounded buffer
    ///
    /// - Parameter bufferSize: Maximum events to buffer (default: 100)
    /// - Returns: A tuple of the stream and its continuation
    ///
    /// This replaces direct `AsyncThrowingStream.makeStream()` calls which
    /// use unbounded buffers by default.
    public static func makeStream<T: Sendable>(
        bufferSize: Int = defaultBufferSize
    ) -> (stream: AsyncThrowingStream<T, Error>,
          continuation: AsyncThrowingStream<T, Error>.Continuation) {
        AsyncThrowingStream<T, Error>.makeStream(
            bufferingPolicy: .bufferingNewest(bufferSize)
        )
    }

    /// Create a stream with automatic task tracking for cancellation
    ///
    /// - Parameters:
    ///   - bufferSize: Maximum events to buffer (default: 100)
    ///   - operation: The async operation that produces events
    /// - Returns: A stream that automatically cancels on termination
    ///
    /// This pattern ensures:
    /// - Task is cancelled when consumer stops iterating
    /// - Resources are cleaned up properly
    /// - No orphaned tasks remain
    ///
    /// Example:
    /// ```swift
    /// func stream(_ input: String) -> AsyncThrowingStream<AgentEvent, Error> {
    ///     StreamHelper.makeTrackedStream { continuation in
    ///         continuation.yield(.started(input: input))
    ///         let result = try await self.run(input)
    ///         continuation.yield(.completed(result: result))
    ///         continuation.finish()
    ///     }
    /// }
    /// ```
    public static func makeTrackedStream<T: Sendable>(
        bufferSize: Int = defaultBufferSize,
        operation: @escaping @Sendable (AsyncThrowingStream<T, Error>.Continuation) async throws -> Void
    ) -> AsyncThrowingStream<T, Error> {
        let (stream, continuation): (AsyncThrowingStream<T, Error>, AsyncThrowingStream<T, Error>.Continuation) = makeStream(bufferSize: bufferSize)

        let task = Task { @Sendable in
            do {
                try await operation(continuation)
            } catch {
                continuation.finish(throwing: error)
            }
        }

        continuation.onTermination = { @Sendable (_: AsyncThrowingStream<T, Error>.Continuation.Termination) in
            task.cancel()
        }

        return stream
    }

    /// Create a stream with actor isolation
    ///
    /// - Parameters:
    ///   - actor: The actor instance
    ///   - bufferSize: Maximum events to buffer
    ///   - operation: The async operation with actor reference
    /// - Returns: A stream that handles actor operations gracefully
    ///
    /// Use this when creating streams from actor methods.
    /// Note: Actors cannot be weakly captured in Swift.
    public static func makeTrackedStream<A: Actor, T: Sendable>(
        for actor: A,
        bufferSize: Int = defaultBufferSize,
        operation: @escaping @Sendable (A, AsyncThrowingStream<T, Error>.Continuation) async throws -> Void
    ) -> AsyncThrowingStream<T, Error> {
        let (stream, continuation): (AsyncThrowingStream<T, Error>, AsyncThrowingStream<T, Error>.Continuation) = makeStream(bufferSize: bufferSize)

        let task = Task { @Sendable in
            do {
                try await operation(actor, continuation)
            } catch {
                continuation.finish(throwing: error)
            }
        }

        continuation.onTermination = { @Sendable (_: AsyncThrowingStream<T, Error>.Continuation.Termination) in
            task.cancel()
        }

        return stream
    }
}
