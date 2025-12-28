// MCPToolBridge.swift
// SwiftAgents Framework
//
// Bridges MCP tools to SwiftAgents Tool protocol.

import Foundation

// MARK: - MCPToolBridge

/// An actor that bridges Model Context Protocol (MCP) tools to SwiftAgents Tool protocol.
///
/// MCPToolBridge provides seamless integration between MCP servers and SwiftAgents
/// by converting MCP tool definitions into native Tool implementations that can be
/// used with agents, registries, and orchestrators.
///
/// ## Usage
///
/// ```swift
/// // Create a bridge for an MCP server
/// let bridge = MCPToolBridge(server: mcpServer)
///
/// // Convert all MCP tools to SwiftAgents tools
/// let tools = try await bridge.bridgeTools()
///
/// // Register with an agent
/// for tool in tools {
///     await agent.register(tool)
/// }
/// ```
///
/// ## Thread Safety
///
/// MCPToolBridge is an actor, providing thread-safe access to the underlying
/// MCP server. All operations are isolated and can be safely called from
/// multiple async contexts.
public actor MCPToolBridge {
    // MARK: Public

    // MARK: - Initialization

    /// Creates a new MCP tool bridge for the given server.
    ///
    /// - Parameter server: The MCP server to bridge tools from.
    public init(server: any MCPServer) {
        self.server = server
    }

    // MARK: - Public Methods

    /// Converts all MCP tools to SwiftAgents tools.
    ///
    /// This method retrieves all tool definitions from the MCP server and
    /// wraps each one in an `MCPBridgedTool` that delegates execution back
    /// to the server.
    ///
    /// - Returns: An array of Tool implementations that delegate to the MCP server.
    /// - Throws: `MCPError.methodNotFound` if the server does not support tools.
    ///           `MCPError.internalError` if listing tools fails.
    ///
    /// ## Example
    /// ```swift
    /// let bridge = MCPToolBridge(server: fileServer)
    /// let tools = try await bridge.bridgeTools()
    ///
    /// for tool in tools {
    ///     print("Bridged tool: \(tool.name)")
    /// }
    /// ```
    public func bridgeTools() async throws -> [any Tool] {
        let definitions = try await server.listTools()
        return definitions.map { definition in
            MCPBridgedTool(definition: definition, server: server)
        }
    }

    // MARK: Private

    /// The MCP server providing the tools.
    private let server: any MCPServer
}

// MARK: - MCPBridgedTool

/// A Tool implementation that delegates execution to an MCP server.
///
/// MCPBridgedTool wraps an MCP tool definition and routes all execution
/// calls to the underlying MCP server. This enables MCP tools to be used
/// seamlessly within the SwiftAgents framework.
///
/// ## Thread Safety
///
/// MCPBridgedTool is `Sendable` and can be safely shared across async contexts.
/// The underlying MCP server must also be `Sendable` (as required by the
/// `MCPServer` protocol).
struct MCPBridgedTool: Tool, Sendable {
    /// The tool definition from the MCP server.
    let definition: ToolDefinition

    /// The MCP server to delegate execution to.
    let server: any MCPServer

    // MARK: - Tool Protocol

    /// The unique name of the tool.
    var name: String {
        definition.name
    }

    /// A description of what the tool does.
    var description: String {
        definition.description
    }

    /// The parameters this tool accepts.
    var parameters: [ToolParameter] {
        definition.parameters
    }

    /// Executes the tool by delegating to the MCP server.
    ///
    /// - Parameter arguments: The arguments passed to the tool.
    /// - Returns: The result of the tool execution from the MCP server.
    /// - Throws: `MCPError.methodNotFound` if the tool does not exist on the server.
    ///           `MCPError.invalidParams` if the arguments are invalid.
    ///           `MCPError.internalError` if execution fails.
    func execute(arguments: [String: SendableValue]) async throws -> SendableValue {
        try await server.callTool(name: name, arguments: arguments)
    }
}
