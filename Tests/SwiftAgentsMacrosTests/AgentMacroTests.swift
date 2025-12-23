// AgentMacroTests.swift
// SwiftAgentsMacrosTests
//
// Tests for the @Agent macro expansion.

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(SwiftAgentsMacros)
    import SwiftAgentsMacros

    let agentMacros: [String: Macro.Type] = [
        "Agent": AgentMacro.self
    ]
#endif

// MARK: - AgentMacroTests

final class AgentMacroTests: XCTestCase {
    // MARK: - Basic Agent Tests

    // swiftlint:disable:next function_body_length
    func testBasicAgentExpansion() throws {
        #if canImport(SwiftAgentsMacros)
            assertMacroExpansion(
                """
                @Agent("You are a helpful assistant")
                actor AssistantAgent {
                    func process(_ input: String) async throws -> String {
                        return "Hello!"
                    }
                }
                """,
                expandedSource: """
                actor AssistantAgent {
                    func process(_ input: String) async throws -> String {
                        return "Hello!"
                    }

                    public let tools: [any Tool]

                    public let instructions: String

                    public let configuration: AgentConfiguration

                    public nonisolated var memory: (any Memory)? {
                        _memory
                    }
                    private nonisolated let _memory: (any Memory)?

                    public nonisolated var inferenceProvider: (any InferenceProvider)? {
                        _inferenceProvider
                    }
                    private nonisolated let _inferenceProvider: (any InferenceProvider)?

                    private var isCancelled: Bool = false

                    public init(
                        tools: [any Tool] = [],
                        instructions: String = "You are a helpful assistant",
                        configuration: AgentConfiguration = .default,
                        memory: (any Memory)? = nil,
                        inferenceProvider: (any InferenceProvider)? = nil
                    ) {
                        self.tools = tools
                        self.instructions = instructions
                        self.configuration = configuration
                        self._memory = memory
                        self._inferenceProvider = inferenceProvider
                    }

                    public func run(_ input: String) async throws -> AgentResult {
                        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                            throw AgentError.invalidInput(reason: "Input cannot be empty")
                        }

                        if isCancelled {
                            throw AgentError.cancelled
                        }

                        let startTime = ContinuousClock.now

                        // Store in memory if available
                        if let mem = memory {
                            await mem.add(.user(input))
                        }

                        // Call user's process method
                        let output = try await process(input)

                        // Store output in memory
                        if let mem = memory {
                            await mem.add(.assistant(output))
                        }

                        let duration = ContinuousClock.now - startTime

                        return AgentResult(
                            output: output,
                            toolCalls: [],
                            toolResults: [],
                            iterationCount: 1,
                            duration: duration,
                            tokenUsage: nil,
                            metadata: [:]
                        )
                    }

                    public nonisolated func stream(_ input: String) -> AsyncThrowingStream<AgentEvent, Error> {
                        let (stream, continuation) = AsyncThrowingStream<AgentEvent, Error>.makeStream()
                        Task { @Sendable [weak self] in
                            guard let self else {
                                continuation.finish()
                                return
                            }
                            do {
                                continuation.yield(.started(input: input))
                                let result = try await self.run(input)
                                continuation.yield(.completed(result: result))
                                continuation.finish()
                            } catch let error as AgentError {
                                continuation.yield(.failed(error: error))
                                continuation.finish(throwing: error)
                            } catch {
                                let agentError = AgentError.internalError(reason: error.localizedDescription)
                                continuation.yield(.failed(error: agentError))
                                continuation.finish(throwing: agentError)
                            }
                        }
                        return stream
                    }

                    public func cancel() async {
                        isCancelled = true
                    }

                    /// A fluent builder for creating AssistantAgent instances.
                    public final class Builder: @unchecked Sendable {
                        private var _tools: [any Tool] = []
                        private var _instructions: String = ""
                        private var _configuration: AgentConfiguration = .default
                        private var _memory: (any Memory)?
                        private var _inferenceProvider: (any InferenceProvider)?

                        /// Creates a new builder with default values.
                        public init() {
                        }

                        /// Sets the tools for the agent.
                        @discardableResult
                        public func tools(_ tools: [any Tool]) -> Builder {
                            self._tools = tools
                            return self
                        }

                        /// Adds a tool to the agent's tool set.
                        @discardableResult
                        public func addTool(_ tool: any Tool) -> Builder {
                            self._tools.append(tool)
                            return self
                        }

                        /// Sets the instructions for the agent.
                        @discardableResult
                        public func instructions(_ instructions: String) -> Builder {
                            self._instructions = instructions
                            return self
                        }

                        /// Sets the configuration for the agent.
                        @discardableResult
                        public func configuration(_ configuration: AgentConfiguration) -> Builder {
                            self._configuration = configuration
                            return self
                        }

                        /// Sets the memory system for the agent.
                        @discardableResult
                        public func memory(_ memory: any Memory) -> Builder {
                            self._memory = memory
                            return self
                        }

                        /// Sets the inference provider for the agent.
                        @discardableResult
                        public func inferenceProvider(_ provider: any InferenceProvider) -> Builder {
                            self._inferenceProvider = provider
                            return self
                        }

                        /// Builds the agent with the configured values.
                        public func build() -> AssistantAgent {
                            AssistantAgent(
                                tools: _tools,
                                instructions: _instructions,
                                configuration: _configuration,
                                memory: _memory,
                                inferenceProvider: _inferenceProvider
                            )
                        }
                    }
                }

                extension AssistantAgent: Agent {
                }
                """,
                macros: agentMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // swiftlint:disable:next function_body_length
    func testAgentWithExistingTools() throws {
        #if canImport(SwiftAgentsMacros)
            assertMacroExpansion(
                """
                @Agent("Math assistant")
                actor MathAgent {
                    let tools: [any Tool] = [CalculatorTool()]

                    func process(_ input: String) async throws -> String {
                        return "Calculated!"
                    }
                }
                """,
                expandedSource: """
                actor MathAgent {
                    let tools: [any Tool] = [CalculatorTool()]

                    func process(_ input: String) async throws -> String {
                        return "Calculated!"
                    }

                    public let instructions: String

                    public let configuration: AgentConfiguration

                    public nonisolated var memory: (any Memory)? {
                        _memory
                    }
                    private nonisolated let _memory: (any Memory)?

                    public nonisolated var inferenceProvider: (any InferenceProvider)? {
                        _inferenceProvider
                    }
                    private nonisolated let _inferenceProvider: (any InferenceProvider)?

                    private var isCancelled: Bool = false

                    public init(
                        tools: [any Tool] = [],
                        instructions: String = "Math assistant",
                        configuration: AgentConfiguration = .default,
                        memory: (any Memory)? = nil,
                        inferenceProvider: (any InferenceProvider)? = nil
                    ) {
                        self.tools = tools
                        self.instructions = instructions
                        self.configuration = configuration
                        self._memory = memory
                        self._inferenceProvider = inferenceProvider
                    }

                    public func run(_ input: String) async throws -> AgentResult {
                        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                            throw AgentError.invalidInput(reason: "Input cannot be empty")
                        }

                        if isCancelled {
                            throw AgentError.cancelled
                        }

                        let startTime = ContinuousClock.now

                        // Store in memory if available
                        if let mem = memory {
                            await mem.add(.user(input))
                        }

                        // Call user's process method
                        let output = try await process(input)

                        // Store output in memory
                        if let mem = memory {
                            await mem.add(.assistant(output))
                        }

                        let duration = ContinuousClock.now - startTime

                        return AgentResult(
                            output: output,
                            toolCalls: [],
                            toolResults: [],
                            iterationCount: 1,
                            duration: duration,
                            tokenUsage: nil,
                            metadata: [:]
                        )
                    }

                    public nonisolated func stream(_ input: String) -> AsyncThrowingStream<AgentEvent, Error> {
                        let (stream, continuation) = AsyncThrowingStream<AgentEvent, Error>.makeStream()
                        Task { @Sendable [weak self] in
                            guard let self else {
                                continuation.finish()
                                return
                            }
                            do {
                                continuation.yield(.started(input: input))
                                let result = try await self.run(input)
                                continuation.yield(.completed(result: result))
                                continuation.finish()
                            } catch let error as AgentError {
                                continuation.yield(.failed(error: error))
                                continuation.finish(throwing: error)
                            } catch {
                                let agentError = AgentError.internalError(reason: error.localizedDescription)
                                continuation.yield(.failed(error: agentError))
                                continuation.finish(throwing: agentError)
                            }
                        }
                        return stream
                    }

                    public func cancel() async {
                        isCancelled = true
                    }

                    /// A fluent builder for creating MathAgent instances.
                    public final class Builder: @unchecked Sendable {
                        private var _tools: [any Tool] = []
                        private var _instructions: String = ""
                        private var _configuration: AgentConfiguration = .default
                        private var _memory: (any Memory)?
                        private var _inferenceProvider: (any InferenceProvider)?

                        /// Creates a new builder with default values.
                        public init() {
                        }

                        /// Sets the tools for the agent.
                        @discardableResult
                        public func tools(_ tools: [any Tool]) -> Builder {
                            self._tools = tools
                            return self
                        }

                        /// Adds a tool to the agent's tool set.
                        @discardableResult
                        public func addTool(_ tool: any Tool) -> Builder {
                            self._tools.append(tool)
                            return self
                        }

                        /// Sets the instructions for the agent.
                        @discardableResult
                        public func instructions(_ instructions: String) -> Builder {
                            self._instructions = instructions
                            return self
                        }

                        /// Sets the configuration for the agent.
                        @discardableResult
                        public func configuration(_ configuration: AgentConfiguration) -> Builder {
                            self._configuration = configuration
                            return self
                        }

                        /// Sets the memory system for the agent.
                        @discardableResult
                        public func memory(_ memory: any Memory) -> Builder {
                            self._memory = memory
                            return self
                        }

                        /// Sets the inference provider for the agent.
                        @discardableResult
                        public func inferenceProvider(_ provider: any InferenceProvider) -> Builder {
                            self._inferenceProvider = provider
                            return self
                        }

                        /// Builds the agent with the configured values.
                        public func build() -> MathAgent {
                            MathAgent(
                                tools: _tools,
                                instructions: _instructions,
                                configuration: _configuration,
                                memory: _memory,
                                inferenceProvider: _inferenceProvider
                            )
                        }
                    }
                }

                extension MathAgent: Agent {
                }
                """,
                macros: agentMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Error Cases

    func testAgentOnlyAppliesToActor() throws {
        #if canImport(SwiftAgentsMacros)
            assertMacroExpansion(
                """
                @Agent("Invalid")
                struct InvalidAgent {
                    func process(_ input: String) async throws -> String {
                        return ""
                    }
                }
                """,
                expandedSource: """
                struct InvalidAgent {
                    func process(_ input: String) async throws -> String {
                        return ""
                    }
                }
                """,
                diagnostics: [
                    DiagnosticSpec(message: "@Agent can only be applied to actors", line: 1, column: 1)
                ],
                macros: agentMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // swiftlint:disable:next function_body_length
    func testAgentWithoutProcessMethod() throws {
        #if canImport(SwiftAgentsMacros)
            // Agent without process method should still compile but run() throws
            assertMacroExpansion(
                """
                @Agent("No process method")
                actor IncompleteAgent {
                }
                """,
                expandedSource: """
                actor IncompleteAgent {

                    public let tools: [any Tool]

                    public let instructions: String

                    public let configuration: AgentConfiguration

                    public nonisolated var memory: (any Memory)? {
                        _memory
                    }
                    private nonisolated let _memory: (any Memory)?

                    public nonisolated var inferenceProvider: (any InferenceProvider)? {
                        _inferenceProvider
                    }
                    private nonisolated let _inferenceProvider: (any InferenceProvider)?

                    private var isCancelled: Bool = false

                    public init(
                        tools: [any Tool] = [],
                        instructions: String = "No process method",
                        configuration: AgentConfiguration = .default,
                        memory: (any Memory)? = nil,
                        inferenceProvider: (any InferenceProvider)? = nil
                    ) {
                        self.tools = tools
                        self.instructions = instructions
                        self.configuration = configuration
                        self._memory = memory
                        self._inferenceProvider = inferenceProvider
                    }

                    public func run(_ input: String) async throws -> AgentResult {
                        throw AgentError.internalError(reason: "No process method implemented")
                    }

                    public nonisolated func stream(_ input: String) -> AsyncThrowingStream<AgentEvent, Error> {
                        let (stream, continuation) = AsyncThrowingStream<AgentEvent, Error>.makeStream()
                        Task { @Sendable [weak self] in
                            guard let self else {
                                continuation.finish()
                                return
                            }
                            do {
                                continuation.yield(.started(input: input))
                                let result = try await self.run(input)
                                continuation.yield(.completed(result: result))
                                continuation.finish()
                            } catch let error as AgentError {
                                continuation.yield(.failed(error: error))
                                continuation.finish(throwing: error)
                            } catch {
                                let agentError = AgentError.internalError(reason: error.localizedDescription)
                                continuation.yield(.failed(error: agentError))
                                continuation.finish(throwing: agentError)
                            }
                        }
                        return stream
                    }

                    public func cancel() async {
                        isCancelled = true
                    }

                    /// A fluent builder for creating IncompleteAgent instances.
                    public final class Builder: @unchecked Sendable {
                        private var _tools: [any Tool] = []
                        private var _instructions: String = ""
                        private var _configuration: AgentConfiguration = .default
                        private var _memory: (any Memory)?
                        private var _inferenceProvider: (any InferenceProvider)?

                        /// Creates a new builder with default values.
                        public init() {
                        }

                        /// Sets the tools for the agent.
                        @discardableResult
                        public func tools(_ tools: [any Tool]) -> Builder {
                            self._tools = tools
                            return self
                        }

                        /// Adds a tool to the agent's tool set.
                        @discardableResult
                        public func addTool(_ tool: any Tool) -> Builder {
                            self._tools.append(tool)
                            return self
                        }

                        /// Sets the instructions for the agent.
                        @discardableResult
                        public func instructions(_ instructions: String) -> Builder {
                            self._instructions = instructions
                            return self
                        }

                        /// Sets the configuration for the agent.
                        @discardableResult
                        public func configuration(_ configuration: AgentConfiguration) -> Builder {
                            self._configuration = configuration
                            return self
                        }

                        /// Sets the memory system for the agent.
                        @discardableResult
                        public func memory(_ memory: any Memory) -> Builder {
                            self._memory = memory
                            return self
                        }

                        /// Sets the inference provider for the agent.
                        @discardableResult
                        public func inferenceProvider(_ provider: any InferenceProvider) -> Builder {
                            self._inferenceProvider = provider
                            return self
                        }

                        /// Builds the agent with the configured values.
                        public func build() -> IncompleteAgent {
                            IncompleteAgent(
                                tools: _tools,
                                instructions: _instructions,
                                configuration: _configuration,
                                memory: _memory,
                                inferenceProvider: _inferenceProvider
                            )
                        }
                    }
                }

                extension IncompleteAgent: Agent {
                }
                """,
                macros: agentMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
