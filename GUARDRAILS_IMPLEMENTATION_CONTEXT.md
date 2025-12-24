# Guardrails Implementation Context

> **IMPORTANT**: This file maintains context for long-running implementation. Update after each sprint/phase.

## Current Status

| Sprint | Status | Items Completed |
|--------|--------|-----------------|
| Sprint 1 | IN PROGRESS | 2/4 (tests done, implementing) |
| Sprint 2 | TESTS DONE | 3/6 (tests done, implementation pending) |
| Sprint 3 | TESTS DONE | 1/3 (tests done, implementation pending) |
| Sprint 4 | PENDING | 0/6 |
| Sprint 5 | TESTS DONE | 1/2 (integration tests done) |

## Test Files Created (TDD Phase Complete)
- ✅ GuardrailResultTests.swift
- ✅ GuardrailErrorTests.swift
- ✅ InputGuardrailTests.swift
- ✅ OutputGuardrailTests.swift
- ✅ ToolGuardrailTests.swift
- ✅ GuardrailRunnerTests.swift
- ✅ GuardrailIntegrationTests.swift

**Branch**: `guardrails`
**Approach**: TDD (tests first, then implementation)
**Last Updated**: 2025-12-25

---

## OpenAI Reference Implementation (from Context7)

### Key Types from OpenAI agents-python

```python
# GuardrailFunctionOutput - The result type
class GuardrailFunctionOutput:
    output_info: Any = None           # Additional info about the check
    tripwire_triggered: bool = False  # If True, raises exception

# InputGuardrail - Wrapper for input guardrail functions
@dataclass
class InputGuardrail:
    guardrail_function: Callable[
        [RunContextWrapper, Agent, str | list[TResponseInputItem]],
        MaybeAwaitable[GuardrailFunctionOutput],
    ]
    name: str | None = None

# OutputGuardrail - Wrapper for output guardrail functions
@dataclass
class OutputGuardrail:
    guardrail_function: Callable[
        [RunContextWrapper, Agent, Any],
        MaybeAwaitable[GuardrailFunctionOutput],
    ]
    name: str | None = None

# Exceptions
class InputGuardrailTripwireTriggered(Exception):
    guardrail: InputGuardrail
    output: GuardrailFunctionOutput

class OutputGuardrailTripwireTriggered(Exception):
    guardrail: OutputGuardrail
    agent: Agent
    agent_output: Any
    output: GuardrailFunctionOutput
```

### OpenAI Usage Pattern

```python
@input_guardrail
async def math_guardrail(ctx, agent, input) -> GuardrailFunctionOutput:
    result = await Runner.run(guardrail_agent, input, context=ctx.context)
    return GuardrailFunctionOutput(
        output_info=result.final_output,
        tripwire_triggered=result.final_output.is_math_homework,
    )

agent = Agent(
    name="Customer support agent",
    input_guardrails=[math_guardrail],  # Array of guardrails
)

try:
    await Runner.run(agent, "Hello, help me with math")
except InputGuardrailTripwireTriggered:
    print("Guardrail tripped")
```

---

## SwiftAgents Implementation Mapping

### GuardrailResult (Swift equivalent of GuardrailFunctionOutput)

```swift
public struct GuardrailResult: Sendable, Equatable {
    public let tripwireTriggered: Bool
    public let outputInfo: SendableValue?
    public let message: String?
    public let metadata: [String: SendableValue]

    public static func passed(...) -> GuardrailResult
    public static func tripwire(...) -> GuardrailResult
}
```

### GuardrailError (Swift equivalent of *TripwireTriggered exceptions)

```swift
public enum GuardrailError: Error, Sendable, LocalizedError {
    case inputTripwireTriggered(guardrailName: String, message: String?, outputInfo: SendableValue?)
    case outputTripwireTriggered(guardrailName: String, agentName: String, message: String?, outputInfo: SendableValue?)
    case toolInputTripwireTriggered(guardrailName: String, toolName: String, message: String?, outputInfo: SendableValue?)
    case toolOutputTripwireTriggered(guardrailName: String, toolName: String, message: String?, outputInfo: SendableValue?)
    case executionFailed(guardrailName: String, underlyingError: String)
}
```

### InputGuardrail Protocol

```swift
public protocol InputGuardrail: Sendable {
    var name: String { get }
    func validate(_ input: String, context: AgentContext?) async throws -> GuardrailResult
}
```

### OutputGuardrail Protocol

```swift
public protocol OutputGuardrail: Sendable {
    var name: String { get }
    func validate(_ output: String, agent: any Agent, context: AgentContext?) async throws -> GuardrailResult
}
```

---

## Files Progress

### Sprint 1 (Foundation) - TESTS DONE
- [x] `Tests/SwiftAgentsTests/Guardrails/GuardrailResultTests.swift` ✅ CREATED
- [ ] `Sources/SwiftAgents/Guardrails/GuardrailResult.swift` ⏳ NEXT
- [x] `Tests/SwiftAgentsTests/Guardrails/GuardrailErrorTests.swift` ✅ CREATED
- [ ] `Sources/SwiftAgents/Guardrails/GuardrailError.swift` ⏳ PENDING

### Sprint 2 (Protocols) - TESTS DONE
- [x] `Tests/SwiftAgentsTests/Guardrails/InputGuardrailTests.swift` ✅ CREATED
- [ ] `Sources/SwiftAgents/Guardrails/InputGuardrail.swift` ⏳ PENDING
- [x] `Tests/SwiftAgentsTests/Guardrails/OutputGuardrailTests.swift` ✅ CREATED
- [ ] `Sources/SwiftAgents/Guardrails/OutputGuardrail.swift` ⏳ PENDING
- [x] `Tests/SwiftAgentsTests/Guardrails/ToolGuardrailTests.swift` ✅ CREATED
- [ ] `Sources/SwiftAgents/Guardrails/ToolGuardrails.swift` ⏳ PENDING

### Sprint 3 (Execution) - TESTS DONE
- [x] `Tests/SwiftAgentsTests/Guardrails/GuardrailRunnerTests.swift` ✅ CREATED
- [ ] `Sources/SwiftAgents/Guardrails/GuardrailRunner.swift` ⏳ PENDING
- [ ] `Tests/SwiftAgentsTests/Mocks/MockGuardrails.swift` ⏳ PENDING

### Sprint 4 (Integration) - NOT STARTED
- [ ] `Sources/SwiftAgents/Core/Agent.swift` (add inputGuardrails/outputGuardrails)
- [ ] `Sources/SwiftAgents/Tools/Tool.swift` (add tool guardrails + ToolRegistry)
- [ ] `Sources/SwiftAgents/Agents/ReActAgent.swift` (integrate guardrails in run())
- [ ] `Sources/SwiftAgents/Agents/ToolCallingAgent.swift` (integrate guardrails)
- [ ] `Sources/SwiftAgents/Agents/PlanAndExecuteAgent.swift` (integrate guardrails)
- [ ] `Sources/SwiftAgents/Agents/AgentBuilder.swift` (add guardrail components)

### Sprint 5 (Verification) - TESTS DONE
- [x] `Tests/SwiftAgentsTests/Guardrails/GuardrailIntegrationTests.swift` ✅ CREATED
- [ ] Build verification
- [ ] Test verification

---

## NEXT ACTIONS AFTER COMPACTION

1. **Read this file first** for full context
2. **Check memory** with `mcp__memory__open_nodes` for "SwiftAgents-Phase1-Guardrails"
3. **Create source files** using implementer sub-agents:
   - GuardrailResult.swift (Sprint 1)
   - GuardrailError.swift (Sprint 1)
   - InputGuardrail.swift (Sprint 2)
   - OutputGuardrail.swift (Sprint 2)
   - ToolGuardrails.swift (Sprint 2)
   - GuardrailRunner.swift (Sprint 3)
   - MockGuardrails.swift (Sprint 3)
4. **Modify existing files** (Sprint 4)
5. **Run code-reviewer** in background after each implementation
6. **Verify build** with `swift build`
7. **Verify tests** with `swift test`

---

## Key Existing Files Reference

| File | Purpose | Key Types |
|------|---------|-----------|
| `Core/Agent.swift` | Agent protocol | `Agent`, `run()` method |
| `Core/AgentError.swift` | Error pattern | `AgentError` enum with LocalizedError |
| `Core/SendableValue.swift` | Dynamic values | `SendableValue` enum |
| `Tools/Tool.swift` | Tool protocol + registry | `Tool`, `ToolRegistry` actor |
| `Agents/AgentBuilder.swift` | Builder pattern | `AgentBuilder`, components |
| `Orchestration/AgentContext.swift` | Execution context | `AgentContext` actor |

---

## Implementation Notes

### Swift 6.2 Requirements
- All public types must be `Sendable`
- Use `actor` for shared mutable state (GuardrailRunner)
- Use `nonisolated` for protocol properties accessed cross-isolation
- Closures must be `@Sendable`

### Pattern: Closure-based Implementation
```swift
public struct ClosureInputGuardrail: InputGuardrail {
    public let name: String
    private let handler: @Sendable (String, AgentContext?) async throws -> GuardrailResult

    public func validate(_ input: String, context: AgentContext?) async throws -> GuardrailResult {
        try await handler(input, context)
    }
}
```

### Pattern: Builder
```swift
public struct InputGuardrailBuilder {
    public func name(_ name: String) -> InputGuardrailBuilder
    public func validate(_ handler: @escaping @Sendable (...) async throws -> GuardrailResult) -> InputGuardrailBuilder
    public func build() -> any InputGuardrail
}
```

---

## Code Review Findings

*(Updated after each code-reviewer run)*

### Sprint 1 Reviews
- TBD

### Sprint 2 Reviews
- TBD

---

## Compaction Recovery Instructions

If context is lost due to compaction, read this file and:
1. Check "Current Status" table for progress
2. Check "Files Created" for what exists
3. Look at todo list for current task
4. Resume from the next uncompleted item
5. Follow TDD: tests first, then implementation
6. Run code-reviewer in background after each item
