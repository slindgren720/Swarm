# SwiftAgents (FoundationAgents) Framework

## Project Context

SwiftAgents is an open-source Swift framework providing "LangChain for Apple platforms"—comprehensive agent development capabilities built on Apple's Foundation Models. It complements SwiftAI SDK (inference layer) by providing the agent layer: autonomous reasoning, memory systems, and multi-agent orchestration.

### Architecture
```
SwiftAI SDK (Inference) → SwiftAgents (Agent Orchestration) → Application
```

### Key Directories
- `Sources/SwiftAgents/` - Core framework source
- `Sources/SwiftAgents/Agents/` - Agent implementations (ReActAgent, PlanAndExecuteAgent)
- `Sources/SwiftAgents/Memory/` - Memory systems (conversation, vector, summary)
- `Sources/SwiftAgents/Tools/` - Tool execution framework
- `Sources/SwiftAgents/Orchestration/` - Multi-agent coordination
- `Sources/SwiftAgents/Observability/` - Tracing and monitoring
- `Tests/SwiftAgentsTests/` - Test suites with mock protocols

## Development Standards

### Swift 6.2 Requirements
- **Minimum**: iOS 17+, macOS 14+, Swift 6.2
- **Concurrency**: Use `async/await`, actors, and `@MainActor` isolation by default
- **Data Safety**: All public types must be `Sendable`; use `@concurrent` for explicit parallel execution
- **Value Types**: Prefer `struct` over `class`; use actors for shared mutable state

### API Design Principles
- Protocol-first: Define behavior contracts before implementations
- Composition over inheritance: Use protocol composition (`Runnable & Observable`)
- Fluent interfaces: Enable chaining with `@discardableResult` where appropriate
- Progressive disclosure: Simple defaults, advanced configuration via builders

### Naming Conventions
- Types/Protocols: `UpperCamelCase` (e.g., `AgentProtocol`, `MemoryStore`)
- Methods: Verb phrases for mutations (`execute`, `store`), noun phrases for accessors (`configuration`)
- Boolean properties: Use `is`, `has`, `should` prefixes
- Generics: Descriptive names (`Element`, `Input`, `Output`) over single letters when unclear

## Workflow

### Verification Commands
```bash
swift build                           # Build framework
swift test                            # Run test suite
swift test --filter AgentTests        # Run specific tests
swift package plugin --allow-writing-to-package-directory swiftformat  # Format code
```

### Before Committing
1. Run `swift build` - ensure no compilation errors
2. Run `swift test` - all tests must pass
3. Run SwiftFormat - code must be formatted
4. Verify `Sendable` conformance on public types
5. Ensure documentation comments on public APIs

### Branch Naming
- `feature/agent-memory-system`
- `fix/orchestration-race-condition`
- `refactor/protocol-conformance`

## Technical Guidelines

### Protocols
- Use `associatedtype` for type-safe generic protocols
- Provide protocol extensions with sensible defaults
- Mark class-only protocols with `AnyObject` constraint
- See `Sources/SwiftAgents/Core/Protocols/` for patterns

### Concurrency
- Use structured concurrency (`TaskGroup`, `async let`) over unstructured
- Annotate with `@MainActor` for UI-bound code
- Use `actor` for shared state requiring synchronization
- Apply `nonisolated` explicitly when needed for cross-isolation calls

### Macros
- Use `@Agent` macro for agent boilerplate
- Use `@Tool` macro for tool registration
- Use `@Observable` for state management
- See `Sources/SwiftAgentsMacros/` for implementation patterns

### Memory Systems
- `ConversationMemory`: Short-term, token-limited context
- `VectorMemory`: Long-term semantic retrieval (requires embedding provider)
- `SummaryMemory`: Compressed conversation history

### Testing Strategy
- Foundation Models unavailable in simulators—use mock protocols
- All protocols have corresponding `Mock*` implementations in test targets
- Test async code with `XCTestExpectation` or async test methods

## Integration Points
- **SwiftAI SDK**: Inference provider abstraction
- **Foundation Models**: Apple's on-device models (iOS 26+)
- **MLX**: Local model execution fallback

## Quick References
- API patterns: See `Sources/SwiftAgents/Examples/`
- Protocol design: See `Sources/SwiftAgents/Core/Protocols/`
- Testing mocks: See `Tests/SwiftAgentsTests/Mocks/`
