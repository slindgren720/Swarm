// OrchestrationChannels.swift
// Swarm Framework
//
// Typed channel-based data passing between orchestration steps.
// Uses a channel bag pattern: a single [String: Data] dictionary
// where OrchestrationChannel<Value> types serialize/deserialize
// using the channel's id as the dictionary key.

import Foundation

// MARK: - OrchestrationChannel

/// A typed key for passing structured data between orchestration steps.
///
/// `OrchestrationChannel` provides a typed API for inter-step communication.
/// Under the hood, values are serialized into a shared channel bag dictionary,
/// enabling typed access without requiring compile-time channel registration
/// for each individual channel.
///
/// Example:
/// ```swift
/// let scoreChannel = OrchestrationChannel<Int>("score", default: 0)
/// let nameChannel = OrchestrationChannel<String>("name", default: "unknown")
///
/// // In a step's execution:
/// try await storage.set(scoreChannel, 42)
/// let score: Int = try await storage.get(scoreChannel)
/// ```
public struct OrchestrationChannel<Value: Codable & Sendable>: Sendable {
    /// The unique identifier for this channel within the bag.
    public let id: String

    /// A closure that produces the default value when the channel has not been written to.
    public let defaultValue: @Sendable () -> Value

    /// Creates a new orchestration channel.
    /// - Parameters:
    ///   - id: A unique string identifier for this channel.
    ///   - defaultValue: The default value returned when the channel has not been written to.
    public init(_ id: String, default defaultValue: @escaping @autoclosure @Sendable () -> Value) {
        self.id = id
        self.defaultValue = defaultValue
    }
}

// MARK: - ChannelBagStorage

/// Actor-based storage for orchestration channel values.
///
/// `ChannelBagStorage` provides thread-safe storage for typed channel values.
/// Values are serialized to `Data` using `JSONEncoder` and stored in a
/// dictionary keyed by channel ID.
///
/// This actor is the backing store for `OrchestrationChannel` reads and writes
/// during orchestration step execution.
public actor ChannelBagStorage {
    private var bag: [String: Data] = [:]

    /// Creates a new empty channel bag storage.
    public init() {}

    /// Creates a channel bag storage pre-populated with data.
    /// - Parameter initial: The initial bag contents.
    public init(bag: [String: Data]) {
        self.bag = bag
    }

    /// Reads a typed value from the channel bag.
    ///
    /// If the channel has not been written to, returns the channel's default value.
    ///
    /// - Parameter channel: The typed channel to read from.
    /// - Returns: The stored value, or the channel's default.
    /// - Throws: `DecodingError` if the stored data cannot be decoded.
    public func get<V: Codable & Sendable>(_ channel: OrchestrationChannel<V>) throws -> V {
        guard let data = bag[channel.id] else {
            return channel.defaultValue()
        }
        return try JSONDecoder().decode(V.self, from: data)
    }

    /// Writes a typed value to the channel bag.
    ///
    /// Overwrites any previously stored value for this channel.
    ///
    /// - Parameters:
    ///   - channel: The typed channel to write to.
    ///   - value: The value to store.
    /// - Throws: `EncodingError` if the value cannot be encoded.
    public func set<V: Codable & Sendable>(_ channel: OrchestrationChannel<V>, _ value: V) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        bag[channel.id] = try encoder.encode(value)
    }

    /// Returns a snapshot of the entire channel bag contents.
    ///
    /// Useful for debugging or for transferring state between contexts.
    public func snapshot() -> [String: Data] {
        bag
    }

    /// Merges external data into the channel bag.
    ///
    /// Existing keys are overwritten by the incoming data.
    ///
    /// - Parameter incoming: The data to merge into the bag.
    public func merge(_ incoming: [String: Data]) {
        for (key, value) in incoming {
            bag[key] = value
        }
    }
}
