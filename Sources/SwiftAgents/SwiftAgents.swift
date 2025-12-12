// SwiftAgents.swift
// SwiftAgents Framework
//
// LangChain for Apple Platforms - A comprehensive Swift framework
// for building AI agents with Apple's Foundation Models.

/// SwiftAgents Framework
///
/// Provides agent orchestration, memory systems, tool integration,
/// and multi-agent coordination for Apple platforms.
///
/// ## Overview
///
/// SwiftAgents is the agent layer that sits on top of inference providers
/// like Foundation Models or SwiftAI SDK, enabling autonomous reasoning
/// and complex task execution.
///
/// ## Quick Start
///
/// ```swift
/// import SwiftAgents
///
/// let agent = ReActAgent(
///     model: FoundationModel.default,
///     tools: [SearchTool(), CalculatorTool()]
/// )
/// let response = try await agent.execute("What is 25 * 4?")
/// ```
public enum SwiftAgents {
    /// The current version of the SwiftAgents framework.
    public static let version = "0.1.0"

    /// The minimum platform versions required by SwiftAgents.
    public static let minimumPlatformVersion = "26.0"
}
