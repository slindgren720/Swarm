# SwiftAgents Implementation Todo List

> Tracking implementation gaps vs OpenAI Agents SDK

## Legend
- [ ] Not started
- [~] In progress
- [x] Completed

---

## Phase 1: Safety & Validation (Critical - P0)

### Guardrails System
- [ ] Create `GuardrailResult` struct with `tripwireTriggered`, `outputInfo`, `metadata`
- [ ] Create `InputGuardrail` protocol with `validate(_:context:)` method
- [ ] Create `OutputGuardrail` protocol with `validate(_:agent:context:)` method
- [ ] Create `GuardrailTripwireTriggered` error type
- [ ] Add `inputGuardrails` property to `Agent` protocol
- [ ] Add `outputGuardrails` property to `Agent` protocol
- [ ] Implement guardrail execution in agent `run()` methods
- [ ] Create `@InputGuardrail` property wrapper for declarative guardrails
- [ ] Create `@OutputGuardrail` property wrapper for declarative guardrails
- [ ] Add guardrail tests

### Tool-Level Guardrails
- [ ] Create `ToolInputGuardrail` protocol
- [ ] Create `ToolOutputGuardrail` protocol
- [ ] Create `ToolGuardrailData` struct with context, agent, arguments
- [ ] Add `inputGuardrails` property to `Tool` protocol
- [ ] Add `outputGuardrails` property to `Tool` protocol
- [ ] Integrate tool guardrails into `ToolRegistry.execute()`
- [ ] Add tool guardrail tests

---

## Phase 2: Streaming & Events (Important - P1)

### Enhanced AgentEvent
- [ ] Add `thinking(thought: String)` case
- [ ] Add `toolCallStarted(name:arguments:spanId:)` case
- [ ] Add `toolCallCompleted(name:result:duration:spanId:)` case
- [ ] Add `toolCallFailed(name:error:spanId:)` case
- [ ] Add `outputToken(token: String)` case for streaming
- [ ] Add `outputChunk(chunk: String)` case
- [ ] Add `iterationStarted(iteration:)` case
- [ ] Add `iterationCompleted(iteration:)` case
- [ ] Add `handoff(from:to:reason:)` case
- [ ] Add `guardrailTriggered(name:reason:)` case
- [ ] Add `memoryAccessed(operation:count:)` case

### Emit Events from Agents
- [ ] Update `ReActAgent` to emit thinking events
- [ ] Update `ReActAgent` to emit tool call events
- [ ] Update `ReActAgent` to emit iteration events
- [ ] Update `ToolCallingAgent` to emit tool call events
- [ ] Update `PlanAndExecuteAgent` to emit plan/step events
- [ ] Update `SupervisorAgent` to emit routing/handoff events
- [ ] Add streaming output token support to agents

### RunHooks Protocol
- [ ] Create `RunHooks` protocol with lifecycle methods
- [ ] Add `onAgentStart(context:agent:input:)` method
- [ ] Add `onAgentEnd(context:agent:result:)` method
- [ ] Add `onToolStart(context:tool:arguments:)` method
- [ ] Add `onToolEnd(context:tool:result:)` method
- [ ] Add `onHandoff(context:from:to:)` method
- [ ] Add `onError(context:error:)` method
- [ ] Add `onGuardrailTriggered(context:guardrail:result:)` method
- [ ] Create default no-op `RunHooks` extension
- [ ] Add `hooks` parameter to agent `run()` methods
- [ ] Add RunHooks tests

---

## Phase 3: Context & Memory (Important - P1)

### Session Protocol
- [ ] Create `Session` protocol as actor
- [ ] Add `sessionId: String` property
- [ ] Add `getItems(limit:)` async method
- [ ] Add `addItems(_:)` async method
- [ ] Add `popItem()` async method
- [ ] Add `clearSession()` async method
- [ ] Create `InMemorySession` implementation
- [ ] Create `PersistentSession` implementation (SwiftData-backed)
- [ ] Add `session` parameter to agent `run()` methods
- [ ] Auto-populate session from agent execution
- [ ] Add Session tests

### Trace Context Manager
- [ ] Create `TraceContext` actor
- [ ] Add `name`, `groupId`, `traceId`, `metadata` properties
- [ ] Create `withTrace(_:groupId:metadata:operation:)` static method
- [ ] Store current trace in task-local storage
- [ ] Auto-inject traceId/groupId into TraceEvents
- [ ] Update `TracingHelper` to use current TraceContext
- [ ] Add trace grouping to `MetricsCollector`
- [ ] Add TraceContext tests

---

## Phase 4: Multi-Agent & Providers (Important - P1)

### Enhanced Handoff System
- [ ] Create `HandoffConfiguration` struct
- [ ] Add `onHandoff` callback property
- [ ] Add `inputFilter` transformation property
- [ ] Add `toolNameOverride` property
- [ ] Add `toolDescriptionOverride` property
- [ ] Add `isEnabled` dynamic check property
- [ ] Create `HandoffInputData` struct for filtering
- [ ] Update `Handoff` to use `HandoffConfiguration`
- [ ] Create `HandoffEvent` for tracking transitions
- [ ] Emit `HandoffEvent` from `HandoffCoordinator`
- [ ] Add enhanced handoff tests

### MultiProvider Routing
- [ ] Create `MultiProvider` actor conforming to `InferenceProvider`
- [ ] Add `providerMap: [String: any InferenceProvider]` storage
- [ ] Add `defaultProvider` property
- [ ] Add `register(prefix:provider:)` method
- [ ] Implement `parseModelName(_:)` to extract prefix
- [ ] Route `generate()` calls to appropriate provider
- [ ] Route `generateWithToolCalls()` calls to appropriate provider
- [ ] Route `stream()` calls to appropriate provider
- [ ] Add convenience prefixes: `openrouter/`, `anthropic/`, `openai/`
- [ ] Add MultiProvider tests

---

## Phase 5: Polish & Minor Features (P2)

### Parallel Tool Calls
- [ ] Add `parallelToolCalls: Bool` to `AgentConfiguration`
- [ ] Update `ToolCallingAgent` to execute tools in parallel when enabled
- [ ] Use `TaskGroup` for parallel execution
- [ ] Maintain result ordering
- [ ] Add parallel tool call tests

### Previous Response ID
- [ ] Add `previousResponseId: String?` to agent run parameters
- [ ] Add `autoPopulatePreviousResponseId: Bool` option
- [ ] Track response IDs in `AgentResult`
- [ ] Skip history when previousResponseId provided (for OpenAI compat)

### Dynamic Handoff Enablement
- [ ] Update `HandoffConfiguration.isEnabled` to be async callable
- [ ] Check enablement before presenting handoff to LLM
- [ ] Filter disabled handoffs from tool definitions

### Handoff Name Overrides
- [ ] Implement `toolNameOverride` in handoff-to-tool conversion
- [ ] Implement `toolDescriptionOverride` in handoff-to-tool conversion
- [ ] Add tests for overrides

### Nest Handoff History
- [ ] Add `nestHandoffHistory: Bool` configuration
- [ ] When true, wrap previous agent's history as nested context
- [ ] When false, flatten history (current behavior)

---

## Phase 6: Future Enhancements (P3 - Backlog)

### Realtime/Voice Agent
- [ ] Research Apple's Speech framework integration
- [ ] Create `RealtimeAgent` protocol
- [ ] Implement WebSocket connection for streaming audio
- [ ] Add audio input processing
- [ ] Add audio output synthesis
- [ ] Handle interruptions gracefully

### MCP (Model Context Protocol) Integration
- [ ] Research MCP specification
- [ ] Create `MCPServer` protocol
- [ ] Create `MCPConfig` for server configuration
- [ ] Add `mcpServers` property to Agent
- [ ] Implement tool discovery from MCP servers
- [ ] Add MCP integration tests

### Computer Use Tools
- [ ] Create `ComputerTool` for screen interaction
- [ ] Create `BashTool` for command execution
- [ ] Create `FileEditorTool` for file operations
- [ ] Add safety guardrails for computer use

### Extended Model Settings
- [ ] Add `frequencyPenalty` to configuration
- [ ] Add `presencePenalty` to configuration
- [ ] Add `truncation` strategy option
- [ ] Add `reasoning` configuration for reasoning models
- [ ] Add `verbosity` level option
- [ ] Add `promptCacheRetention` option

---

## Testing Checklist

### Unit Tests
- [ ] GuardrailResult tests
- [ ] InputGuardrail tests
- [ ] OutputGuardrail tests
- [ ] ToolInputGuardrail tests
- [ ] ToolOutputGuardrail tests
- [ ] Session protocol tests
- [ ] TraceContext tests
- [ ] RunHooks tests
- [ ] MultiProvider tests
- [ ] Enhanced AgentEvent tests
- [ ] HandoffConfiguration tests

### Integration Tests
- [ ] Guardrail + Agent integration
- [ ] Session + Agent integration
- [ ] TraceContext + Tracing integration
- [ ] RunHooks + Agent integration
- [ ] MultiProvider + Agent integration
- [ ] Handoff + SupervisorAgent integration

### Performance Tests
- [ ] Guardrail execution overhead
- [ ] Parallel tool call performance
- [ ] MultiProvider routing latency
- [ ] Session persistence performance

---

## Documentation

- [ ] Update README with guardrails examples
- [ ] Update README with session examples
- [ ] Update README with tracing examples
- [ ] Create Guardrails guide
- [ ] Create Multi-Agent orchestration guide
- [ ] Create Streaming events guide
- [ ] Add API documentation for new protocols
- [ ] Create migration guide from current API

---

## Progress Summary

| Phase | Status | Items | Completed |
|-------|--------|-------|-----------|
| Phase 1: Safety | Not Started | 17 | 0 |
| Phase 2: Events | Not Started | 23 | 0 |
| Phase 3: Context | Not Started | 14 | 0 |
| Phase 4: Multi-Agent | Not Started | 21 | 0 |
| Phase 5: Polish | Not Started | 11 | 0 |
| Phase 6: Future | Backlog | 15 | 0 |
| Testing | Not Started | 17 | 0 |
| Documentation | Not Started | 8 | 0 |
| **Total** | | **126** | **0** |

---

*Last Updated: 2024-12-24*
