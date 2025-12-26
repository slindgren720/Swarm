# Phase 3 Implementation Plan: Session & TraceContext

## Table of Contents
1. [Overview](#overview)
2. [OpenAI Reference Patterns](#openai-reference-patterns)
3. [SwiftAgents Architecture Analysis](#swiftagents-architecture-analysis)
4. [Implementation Specifications](#implementation-specifications)
5. [Testing Strategy](#testing-strategy)
6. [Integration Points](#integration-points)
7. [Success Criteria](#success-criteria)

---

## Overview

### Goals
Implement automatic conversation history management (Session) and execution grouping (TraceContext) following OpenAI SDK patterns while maintaining Swift 6.2 concurrency safety.

### Key Features
1. **Session Protocol**: Automatic conversation history management across agent runs
2. **Session Implementations**: In-memory, persistent (SwiftData), and extensible
3. **TraceContext**: Task-local execution grouping for related traces
4. **Trace Spans**: Hierarchical tracking of operations within traces

### Dependencies
- Phase 1: Guardrails (in PR review)
- Phase 2: Streaming Events & RunHooks (to be implemented)
- Existing: SwiftAgents Memory system, AgentContext

---

## OpenAI Reference Patterns

### Session Protocol (Python)
```python
class Session(Protocol):
    session_id: str

    async def get_items(self, limit: int | None = None) -> list[TResponseInputItem]:
        """Retrieve conversation history."""
        ...

    async def add_items(self, items: list[TResponseInputItem]) -> None:
        """Add items to history."""
        ...

    async def pop_item(self) -> TResponseInputItem | None:
        """Remove and return most recent item."""
        ...

    async def clear_session(self) -> None:
        """Clear all items."""
        ...
```

### TraceContext Usage (Python)
```python
with trace("Customer Service", group_id="chat_123", metadata={"customer": "user_456"}):
    result1 = await Runner.run(agent, query1)
    result2 = await Runner.run(agent, query2)
```

### Key Design Principles
1. **Protocol-first**: Define behavior contract, not implementation
2. **Automatic history**: Sessions handle conversation state transparently
3. **Task-local storage**: TraceContext uses task-local variables
4. **Hierarchical spans**: Parent-child relationships for operation tracking

---

## SwiftAgents Architecture Analysis

### Current Memory System
SwiftAgents has an existing `AgentMemory` protocol:

```swift
public protocol AgentMemory: Actor, Sendable {
    func add(_ message: MemoryMessage) async
    func getContext(for query: String, tokenLimit: Int) async -> String
    func getAllMessages() async -> [MemoryMessage]
    func clear() async
    var count: Int { get async }
}
```

**Existing Implementations:**
- `ConversationMemory`
- `SlidingWindowMemory`
- `SummaryMemory`
- `HybridMemory`
- `SwiftDataMemory` (persistent)

### Key Differences: Session vs AgentMemory

| Aspect | AgentMemory | Session |
|--------|-------------|---------|
| **Purpose** | AI context generation | Conversation persistence |
| **Interface** | `getContext()` for prompts | `get_items()` for history |
| **Scope** | Single agent instance | Cross-agent, cross-run |
| **Token handling** | Token-aware summarization | Raw message storage |
| **Retrieval** | Semantic/contextual | Sequential/chronological |

**Decision**: Keep both protocols, as they serve different purposes:
- `AgentMemory`: AI-specific context management
- `Session`: Conversation state persistence

### Current Tracing System
SwiftAgents has existing tracing infrastructure:

```swift
// Existing Tracer protocol
public protocol Tracer: Sendable {
    func trace(_ message: String) async
    func debug(_ message: String) async
    func info(_ message: String) async
    func warning(_ message: String) async
    func error(_ message: String, error: Error?) async
}
```

**Existing Implementations:**
- `ConsoleTracer`
- `OSLogTracer`
- `CompositeTracer`
- `BufferedTracer`

**Enhancement needed**: Add structured span tracking with TraceContext.

### AgentContext System
SwiftAgents has `AgentContext` for shared state:

```swift
public actor AgentContext {
    private var storage: [String: SendableValue] = [:]
    public let input: String
    
    public init(input: String = "") {
        self.input = input
    }
    
    public func set(key: String, value: SendableValue) async
    public func get(key: String) async -> SendableValue?
}
```

**Integration**: TraceContext will complement (not replace) AgentContext.

---

## Implementation Specifications

### Component 1: Session Protocol

#### File: `Sources/SwiftAgents/Memory/Session.swift`

```swift
import Foundation

/// Protocol for managing conversation session history
/// Provides automatic conversation history management for agents
public protocol Session: Actor, Sendable {
    /// Unique identifier for this session
    var sessionId: String { get }

    /// Retrieve conversation history
    /// - Parameter limit: Maximum items to retrieve (nil = all)
    /// - Returns: Array of messages in chronological order
    func getItems(limit: Int?) async throws -> [MemoryMessage]

    /// Add items to conversation history
    func addItems(_ items: [MemoryMessage]) async throws

    /// Remove and return the most recent item
    func popItem() async throws -> MemoryMessage?

    /// Clear all items in this session
    func clearSession() async throws

    /// Get the total count of items
    var itemCount: Int { get async }
}

// MARK: - Default Implementations

public extension Session {
    /// Add a single item
    func addItem(_ item: MemoryMessage) async throws {
        try await addItems([item])
    }

    /// Get all items (no limit)
    func getAllItems() async throws -> [MemoryMessage] {
        try await getItems(limit: nil)
    }
}
```

**Design Notes:**
- Uses existing `MemoryMessage` type (reuse, not reinvent)
- Actor-isolated for thread safety
- Async throws for error handling
- Mirrors OpenAI Session API closely

**Tests Required:**
```swift
// Tests/SwiftAgentsTests/Memory/SessionTests.swift

// Protocol conformance tests
func testSessionProtocolConformance()
func testAddSingleItem()
func testGetAllItems()
func testSessionIsolation() // Ensure actor safety
```

---

### Component 2: InMemorySession

#### File: `Sources/SwiftAgents/Memory/InMemorySession.swift`

```swift
import Foundation

/// In-memory session implementation for testing and simple use cases
public actor InMemorySession: Session {
    public let sessionId: String
    private var items: [MemoryMessage] = []

    public init(sessionId: String = UUID().uuidString) {
        self.sessionId = sessionId
    }

    public var itemCount: Int {
        items.count
    }

    public func getItems(limit: Int?) async throws -> [MemoryMessage] {
        if let limit = limit {
            let startIndex = max(0, items.count - limit)
            return Array(items[startIndex...])
        }
        return items
    }

    public func addItems(_ newItems: [MemoryMessage]) async throws {
        items.append(contentsOf: newItems)
    }

    public func popItem() async throws -> MemoryMessage? {
        guard !items.isEmpty else { return nil }
        return items.removeLast()
    }

    public func clearSession() async throws {
        items.removeAll()
    }
}
```

**Design Notes:**
- Simplest implementation (good for tests)
- No persistence
- Thread-safe via actor isolation
- Efficient for short-lived sessions

**Tests Required:**
```swift
func testInMemorySessionCreation()
func testAddAndRetrieveItems()
func testLimitedRetrieval()
func testPopItem()
func testClearSession()
func testConcurrentAccess() // Multiple tasks accessing same session
```

---

### Component 3: PersistentSession (SwiftData)

#### File: `Sources/SwiftAgents/Memory/PersistentSession.swift`

```swift
import Foundation
import SwiftData

/// SwiftData-backed persistent session
@available(iOS 17.0, macOS 14.0, *)
public actor PersistentSession: Session {
    public let sessionId: String
    private let backend: SwiftDataBackend

    public init(sessionId: String, backend: SwiftDataBackend) {
        self.sessionId = sessionId
        self.backend = backend
    }

    /// Create with default persistent storage
    public static func persistent(sessionId: String) throws -> PersistentSession {
        let backend = try SwiftDataBackend.persistent()
        return PersistentSession(sessionId: sessionId, backend: backend)
    }

    /// Create with in-memory storage (for testing)
    public static func inMemory(sessionId: String) throws -> PersistentSession {
        let backend = try SwiftDataBackend.inMemory()
        return PersistentSession(sessionId: sessionId, backend: backend)
    }

    public var itemCount: Int {
        get async {
            (try? await backend.messageCount(conversationId: sessionId)) ?? 0
        }
    }

    public func getItems(limit: Int?) async throws -> [MemoryMessage] {
        if let limit = limit {
            return try await backend.fetchRecentMessages(
                conversationId: sessionId, 
                limit: limit
            )
        }
        return try await backend.fetchMessages(conversationId: sessionId)
    }

    public func addItems(_ items: [MemoryMessage]) async throws {
        try await backend.storeAll(items, conversationId: sessionId)
    }

    public func popItem() async throws -> MemoryMessage? {
        let items = try await backend.fetchRecentMessages(
            conversationId: sessionId, 
            limit: 1
        )
        if let last = items.last {
            // Delete the most recent message
            try await backend.deleteOldestMessages(
                conversationId: sessionId, 
                keepRecent: await itemCount - 1
            )
            return last
        }
        return nil
    }

    public func clearSession() async throws {
        try await backend.deleteMessages(conversationId: sessionId)
    }
}
```

**Design Notes:**
- Leverages existing `SwiftDataBackend` from SwiftAgents
- Factory methods for different storage types
- Async properties for item count
- Error propagation from backend

**Tests Required:**
```swift
@available(iOS 17.0, macOS 14.0, *)
func testPersistentSessionWithInMemoryBackend()
func testPersistentSessionWithFileBackend()
func testSessionPersistsAcrossInstances()
func testMultipleSessionsInSameBackend()
func testPopItemPersistence()
```

---

### Component 4: TraceContext

#### File: `Sources/SwiftAgents/Observability/TraceContext.swift`

```swift
import Foundation

/// Context for grouping related traces together
public actor TraceContext {
    /// Name of this trace workflow
    public let name: String

    /// Unique trace identifier
    public let traceId: UUID

    /// Group identifier for linking related traces
    public let groupId: String?

    /// Additional metadata
    public let metadata: [String: SendableValue]

    /// Start time of the trace
    public let startTime: Date

    /// Child spans in this trace
    private var spans: [TraceSpan] = []

    private init(
        name: String,
        traceId: UUID = UUID(),
        groupId: String? = nil,
        metadata: [String: SendableValue] = [:]
    ) {
        self.name = name
        self.traceId = traceId
        self.groupId = groupId
        self.metadata = metadata
        self.startTime = Date()
    }

    /// Execute an operation within a trace context
    /// - Parameters:
    ///   - name: Name of the workflow/trace
    ///   - groupId: Optional group ID to link related traces
    ///   - metadata: Additional metadata to attach
    ///   - operation: The async operation to execute
    /// - Returns: The result of the operation
    public static func withTrace<T: Sendable>(
        _ name: String,
        groupId: String? = nil,
        metadata: [String: SendableValue] = [:],
        operation: @Sendable () async throws -> T
    ) async rethrows -> T {
        let context = TraceContext(name: name, groupId: groupId, metadata: metadata)

        // Store in task-local storage
        return try await TraceContextStorage.$current.withValue(context) {
            try await operation()
        }
    }

    /// Get the current trace context (if any)
    public static var current: TraceContext? {
        TraceContextStorage.current
    }

    /// Add a span to this trace
    public func addSpan(_ span: TraceSpan) {
        spans.append(span)
    }

    /// Get all spans in this trace
    public func getSpans() -> [TraceSpan] {
        spans
    }

    /// Calculate total duration
    public var duration: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
}

// MARK: - Task-Local Storage

private enum TraceContextStorage {
    @TaskLocal
    static var current: TraceContext?
}

// MARK: - Trace Span

public struct TraceSpan: Sendable {
    public let spanId: UUID
    public let parentSpanId: UUID?
    public let name: String
    public let startTime: Date
    public let endTime: Date?
    public let status: SpanStatus
    public let metadata: [String: SendableValue]

    public init(
        spanId: UUID = UUID(),
        parentSpanId: UUID? = nil,
        name: String,
        startTime: Date = Date(),
        endTime: Date? = nil,
        status: SpanStatus = .ok,
        metadata: [String: SendableValue] = [:]
    ) {
        self.spanId = spanId
        self.parentSpanId = parentSpanId
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
        self.metadata = metadata
    }

    public var duration: TimeInterval? {
        guard let end = endTime else { return nil }
        return end.timeIntervalSince(startTime)
    }
}

public enum SpanStatus: String, Sendable {
    case ok
    case error
    case cancelled
}

// MARK: - Convenience Extensions

public extension TraceContext {
    /// Create a new span within this trace
    func span(
        _ name: String,
        parentSpanId: UUID? = nil,
        metadata: [String: SendableValue] = [:]
    ) -> TraceSpan {
        TraceSpan(
            parentSpanId: parentSpanId,
            name: name,
            metadata: metadata
        )
    }
}

// MARK: - Integration with TracingHelper

public extension TracingHelper {
    /// Get the current trace context's traceId
    var currentTraceId: UUID? {
        TraceContext.current?.traceId
    }

    /// Get the current trace context's groupId
    var currentGroupId: String? {
        TraceContext.current?.groupId
    }
}
```

**Design Notes:**
- Uses `@TaskLocal` for Swift-native context propagation
- Actor-isolated for span collection
- Hierarchical span tracking
- Integration point with existing `TracingHelper`

**Tests Required:**
```swift
func testTraceContextCreation()
func testTaskLocalStorage()
func testNestedTraces()
func testSpanCollection()
func testTraceContextInConcurrentTasks()
func testTraceContextMetadata()
func testSpanDurationCalculation()
```

---

### Component 5: Agent Integration

#### Update: `Sources/SwiftAgents/Core/Agent.swift`

```swift
public protocol Agent: Sendable {
    // ... existing properties ...
    
    /// Run the agent with optional session
    func run(
        _ input: String,
        context: AgentContext?,
        session: (any Session)?,
        hooks: (any RunHooks)?
    ) async throws -> AgentResult
    
    /// Stream agent execution with optional session
    func stream(
        _ input: String,
        context: AgentContext?,
        session: (any Session)?
    ) -> AsyncThrowingStream<AgentEvent, Error>
}

// Default implementations
public extension Agent {
    func run(
        _ input: String,
        context: AgentContext? = nil,
        session: (any Session)? = nil,
        hooks: (any RunHooks)? = nil
    ) async throws -> AgentResult {
        // Implementation delegates to concrete agent
    }
}
```

#### Update: `Sources/SwiftAgents/Agents/ReActAgent.swift`

**Session Integration Logic:**
```swift
public func run(
    _ input: String,
    context: AgentContext? = nil,
    session: (any Session)? = nil,
    hooks: (any RunHooks)? = nil
) async throws -> AgentResult {
    let ctx = context ?? AgentContext()
    
    // Load conversation history from session
    var messages: [MemoryMessage] = []
    if let session = session {
        messages = try await session.getItems(limit: 50) // Configurable limit
    }
    
    // Add current user message
    let userMessage = MemoryMessage.user(input)
    messages.append(userMessage)
    
    // Execute agent with full context
    let result = try await executeWithMessages(messages, context: ctx, hooks: hooks)
    
    // Store conversation in session
    if let session = session {
        let assistantMessage = MemoryMessage.assistant(result.output)
        try await session.addItems([userMessage, assistantMessage])
    }
    
    return result
}
```

**TraceContext Integration:**
```swift
private func executeLoop(
    messages: [MemoryMessage],
    context: AgentContext,
    hooks: (any RunHooks)?
) async throws -> AgentResult {
    // Wrap execution in trace context
    return try await TraceContext.withTrace(
        "Agent Execution: \(configuration.name ?? "Unknown")",
        groupId: context.input,
        metadata: [
            "agent_name": .string(configuration.name ?? "Unknown"),
            "max_iterations": .int(configuration.maxIterations)
        ]
    ) {
        // Create span for each iteration
        for iteration in 0..<configuration.maxIterations {
            let span = await TraceContext.current?.span(
                "Iteration \(iteration)",
                metadata: ["iteration": .int(iteration)]
            )
            
            // ... existing iteration logic ...
            
            if let context = TraceContext.current, let span = span {
                var completedSpan = span
                completedSpan.endTime = Date()
                completedSpan.status = .ok
                await context.addSpan(completedSpan)
            }
        }
        
        // ... return result ...
    }
}
```

**Tests Required:**
```swift
func testAgentWithInMemorySession()
func testAgentWithPersistentSession()
func testSessionPreservesHistory()
func testAgentWithoutSession() // Backwards compatibility
func testTraceContextPropagation()
func testSpansCollectedInTrace()
```

---

## Testing Strategy

### Unit Tests

**Session Protocol Tests:**
- Protocol conformance verification
- Default method implementations
- Error handling
- Concurrency safety

**InMemorySession Tests:**
- CRUD operations
- Limit handling
- Clear functionality
- Concurrent access patterns

**PersistentSession Tests:**
- SwiftData backend integration
- Persistence across instances
- Multiple sessions in one backend
- Error propagation

**TraceContext Tests:**
- Task-local storage behavior
- Nested trace contexts
- Span collection
- Metadata handling
- Concurrent task isolation

### Integration Tests

**Agent + Session:**
```swift
func testMultiTurnConversationWithSession() async throws {
    let session = InMemorySession(sessionId: "test_session")
    let agent = ReActAgent.Builder()
        .inferenceProvider(MockProvider())
        .build()
    
    // Turn 1
    let result1 = try await agent.run(
        "My name is Alice",
        session: session
    )
    
    // Turn 2 - agent should remember name
    let result2 = try await agent.run(
        "What's my name?",
        session: session
    )
    
    XCTAssertTrue(result2.output.contains("Alice"))
    
    // Verify session storage
    let items = try await session.getAllItems()
    XCTAssertEqual(items.count, 4) // 2 user + 2 assistant
}
```

**Agent + TraceContext:**
```swift
func testAgentTracingWithContext() async throws {
    let agent = ReActAgent.Builder()
        .inferenceProvider(MockProvider())
        .addTool(CalculatorTool())
        .build()
    
    var capturedTraceId: UUID?
    
    try await TraceContext.withTrace("Test Workflow", groupId: "test_group") {
        let result = try await agent.run("Calculate 2+2")
        
        // Capture trace ID
        capturedTraceId = TraceContext.current?.traceId
        
        // Verify spans were collected
        let spans = await TraceContext.current?.getSpans() ?? []
        XCTAssertGreaterThan(spans.count, 0)
    }
    
    XCTAssertNotNil(capturedTraceId)
}
```

### Performance Tests

```swift
func testSessionPerformanceWith1000Messages() async throws {
    measure {
        // Add 1000 messages and retrieve them
    }
}

func testConcurrentSessionAccess() async throws {
    // Multiple agents accessing same session concurrently
}
```

---

## Integration Points

### 1. Memory System Integration

**Relationship:**
- Session: Persistence layer
- AgentMemory: AI context layer

**Usage Pattern:**
```swift
let session = InMemorySession(sessionId: "user_123")
let memory = ConversationMemory(maxTokens: 4000)

// Session feeds into Memory
let sessionMessages = try await session.getAllItems()
for message in sessionMessages {
    await memory.add(message)
}

// Memory provides context for AI
let context = await memory.getContext(for: query, tokenLimit: 2000)
```

### 2. Tracing System Integration

**Existing:**
- `Tracer` protocol (logging)
- `TracingHelper` (span management)

**New:**
- `TraceContext` (execution grouping)
- `TraceSpan` (operation tracking)

**Usage Pattern:**
```swift
// Existing tracer
let tracer = ConsoleTracer()

// New trace context
try await TraceContext.withTrace("Workflow") {
    // TraceContext captures spans
    let span = await TraceContext.current?.span("Operation")
    
    // Existing tracer logs events
    await tracer.info("Operation started")
    
    // Both systems coexist
}
```

### 3. AgentContext Integration

**Coexistence:**
```swift
let context = AgentContext(input: "User query")
await context.set(key: "user_id", value: .string("123"))

try await TraceContext.withTrace("Request", groupId: "request_456") {
    // Both contexts available
    let result = try await agent.run(
        "Hello",
        context: context,  // AgentContext
        session: session   // Session
    )
    
    // TraceContext is task-local
    let traceId = TraceContext.current?.traceId
}
```

---

## Success Criteria

### Functional Requirements
- [ ] Session protocol defined with all required methods
- [ ] InMemorySession fully functional
- [ ] PersistentSession works with SwiftData backend
- [ ] TraceContext provides task-local storage
- [ ] Spans are correctly collected in traces
- [ ] Agent integration works with sessions
- [ ] Agent integration works with trace contexts
- [ ] Backwards compatibility maintained (sessions are optional)

### Code Quality
- [ ] All code compiles with Swift 6.2 strict concurrency
- [ ] No `@unchecked Sendable` unless documented
- [ ] All public APIs have documentation comments
- [ ] Follows SwiftAgents naming conventions
- [ ] Passes SwiftFormat and SwiftLint checks

### Testing
- [ ] >90% code coverage for new components
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Performance tests show acceptable overhead
- [ ] Concurrency tests demonstrate thread safety

### Documentation
- [ ] Public APIs have DocC comments
- [ ] Usage examples in documentation
- [ ] Migration guide for existing code
- [ ] README updated with Session examples

---

## Migration Guide for Existing Code

### Before (Manual History Management):
```swift
let agent = ReActAgent.Builder().build()

var history: [MemoryMessage] = []

// Turn 1
let result1 = try await agent.run("Hello")
history.append(.user("Hello"))
history.append(.assistant(result1.output))

// Turn 2 - manually manage history
let memory = ConversationMemory()
for msg in history {
    await memory.add(msg)
}
let result2 = try await agent.run("Continue")
```

### After (Automatic with Session):
```swift
let agent = ReActAgent.Builder().build()
let session = InMemorySession(sessionId: "user_123")

// Turn 1
let result1 = try await agent.run("Hello", session: session)

// Turn 2 - history automatically managed
let result2 = try await agent.run("Continue", session: session)
```

---

## Timeline & Milestones

### Week 1: Core Implementation
- [ ] Day 1-2: Session protocol + InMemorySession
- [ ] Day 3-4: PersistentSession + tests
- [ ] Day 5: TraceContext foundation

### Week 2: Integration
- [ ] Day 1-2: Agent integration
- [ ] Day 3-4: Integration tests
- [ ] Day 5: Documentation

### Week 3: Polish
- [ ] Performance testing
- [ ] Bug fixes
- [ ] Code review
- [ ] PR preparation

---

## Appendix: Full Code Reference

See the original implementation plan document for complete code samples for:
- Session protocol with all methods
- InMemorySession complete implementation
- PersistentSession complete implementation
- TraceContext with task-local storage
- TraceSpan structure
- Agent integration examples
- Test templates

---

## Questions & Decisions

### Design Decisions Made:
1. ✅ Keep both Session and AgentMemory protocols (different purposes)
2. ✅ Use task-local storage for TraceContext (Swift-native)
3. ✅ Session is optional parameter (backwards compatibility)
4. ✅ Reuse existing MemoryMessage type (no new types)

### Open Questions:
1. Should sessions have configurable size limits?
2. Should we support session compression for large histories?
3. How should we handle session migration/versioning?

---

## References
- OpenAI Agents SDK: https://github.com/openai/openai-agents-python
- SwiftAgents: https://github.com/christopherkarani/SwiftAgents
- Swift Concurrency: https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html
- SwiftData: https://developer.apple.com/documentation/swiftdata
