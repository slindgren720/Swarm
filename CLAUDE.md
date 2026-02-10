# Swarm (FoundationAgents) Framework

## Project Context

Swarm is an open-source Swift framework providing "LangChain for Apple platforms"—comprehensive agent development capabilities built on Apple's Foundation Models. It complements SwiftAI SDK (inference layer) by providing the agent layer: autonomous reasoning, memory systems, and multi-agent orchestration.

### Architecture
```
SwiftAI SDK (Inference) → Swarm (Agent Orchestration) → Application
```

### Key Directories
- `Sources/Swarm/` - Core framework source
- `Sources/Swarm/Agents/` - Agent implementations (ReActAgent, PlanAndExecuteAgent)
- `Sources/Swarm/Memory/` - Memory systems (conversation, vector, summary)
- `Sources/Swarm/Tools/` - Tool execution framework
- `Sources/Swarm/Orchestration/` - Multi-agent coordination
- `Sources/Swarm/Observability/` - Tracing and monitoring
- `Tests/SwarmTests/` - Test suites with mock protocols

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
3. Run SwiftFormat - code must be formatted (`swift package plugin --allow-writing-to-package-directory swiftformat`)
4. Run SwiftLint - code must pass linting checks (`swiftlint lint` - install via Homebrew if needed)
5. Verify `Sendable` conformance on public types
6. Ensure documentation comments on public APIs

### Branch Naming
- `feature/agent-memory-system`
- `fix/orchestration-race-condition`
- `refactor/protocol-conformance`

## Technical Guidelines

### Protocols
- Use `associatedtype` for type-safe generic protocols
- Provide protocol extensions with sensible defaults
- Mark class-only protocols with `AnyObject` constraint
- See `Sources/Swarm/Core/Protocols/` for patterns

### Concurrency
- Use structured concurrency (`TaskGroup`, `async let`) over unstructured
- Annotate with `@MainActor` for UI-bound code
- Use `actor` for shared state requiring synchronization
- Apply `nonisolated` explicitly when needed for cross-isolation calls

### Macros
- Use `@AgentActor` macro for agent boilerplate
- Use `@Tool` macro for tool registration
- Use `@Observable` for state management
- See `Sources/SwarmMacros/` for implementation patterns

### Memory Systems
- `ConversationMemory`: Short-term, token-limited context
- `VectorMemory`: Long-term semantic retrieval (requires embedding provider)
- `SummaryMemory`: Compressed conversation history

### Logging
- Use `swift-log` for cross-platform compatibility (Apple platforms + Linux servers)
- Call `Log.bootstrap()` once at application startup to configure logging
- Never use `print()` statements in production code
- Use category-specific loggers:
  - `Log.agents`: Agent lifecycle and execution
  - `Log.memory`: Memory system operations
  - `Log.tracing`: Observability and tracing events
  - `Log.metrics`: Performance and usage metrics
  - `Log.orchestration`: Multi-agent coordination
- Choose appropriate log levels: `.trace`, `.debug`, `.info`, `.notice`, `.warning`, `.error`, `.critical`
- **Privacy Note**: Unlike `os.Logger`, swift-log does not support `privacy:` parameter annotations
  - Do not log sensitive user data, credentials, or PII in production
  - Configure log handlers to redact sensitive information at runtime
  - Default behavior logs all interpolated values as-is
- Example: `Log.memory.error("Failed to save: \(error.localizedDescription)")`
- For Apple-only code, `OSLogTracer` is available with privacy annotations wrapped in `#if canImport(os)`

### Testing Strategy (TDD Required)
- **Test-Driven Development is mandatory** for all new features and bug fixes
- Foundation Models unavailable in simulators—use mock protocols
- All protocols have corresponding `Mock*` implementations in test targets
- Test async code with `XCTestExpectation` or async test methods

### TDD Workflow
Follow Red-Green-Refactor cycle for all development:

1. **Red**: Write failing tests first
   - Define expected behavior through test cases
   - Use `test-specialist` agent to design comprehensive test coverage
   - Tests must fail initially (verifies test is meaningful)

2. **Green**: Write minimal implementation
   - Only write enough code to make tests pass
   - No premature optimization or extra features
   - Focus on satisfying test assertions

3. **Refactor**: Improve code quality
   - Clean up implementation while keeping tests green
   - Apply Swift patterns and conventions
   - Use `code-reviewer` agent to verify refactoring

**TDD Guidelines**:
- Never write implementation before tests
- One test case per behavior/feature
- Test edge cases and error conditions
- Mock external dependencies (LLM providers, network)
- Run `swift test` frequently during development

## Integration Points
- **SwiftAI SDK**: Inference provider abstraction
- **Foundation Models**: Apple's on-device models (iOS 26+)
- **MLX**: Local model execution fallback

## Agent Orchestration System

### Agent Registry

#### Tier 1: Orchestration Layer (Route & Coordinate)
| Agent | Model | Mode | Role |
|-------|-------|------|------|
| **Lead Session** (Claude Code main) | opus | — | Router, delegator, user interface. Always active. |
| `context-builder` | sonnet | plan | Research at start of tasks spanning 3+ files |
| `context-manager` | haiku | default | Context preservation between phases, before compaction |

#### Tier 2: Design Layer (Think & Plan — Read-Only)
| Agent | Model | When to Use |
|-------|-------|-------------|
| `protocol-architect` | sonnet | Designing protocols, type hierarchies, protocol composition, generic constraints |
| `api-designer` | sonnet | Public API naming, fluent interfaces, progressive disclosure, builder patterns |
| `framework-architect` | sonnet | Multi-agent orchestration patterns, new step types, Hive DAG compilation design |
| `concurrency-expert` | sonnet | Actor isolation design, Sendable conformance, data-race prevention review |

#### Tier 3: Implementation Layer (Write Code)
| Agent | Model | Scope | When to Use |
|-------|-------|-------|-------------|
| `swarm-implementer` | sonnet | `Sources/Swarm/` | Swarm framework code: orchestration steps, agents, memory, DSL, tools |
| `hive-implementer` | sonnet | `Sources/HiveSwarm/` + Hive compilation | HiveSwarm bridge code, DAG compilation, checkpoint serialization |
| `swift-expert` | opus | Any Swift | Complex: new subsystems, multi-file refactors, novel architectural patterns |
| `implementer` | sonnet | Any Swift | Medium complexity: add methods, implement protocols, standard patterns |
| `fixer` | haiku | Any Swift | Low complexity: rename, fix imports, small single-file edits (<20 lines) |

#### Tier 4: Quality Layer (Verify & Validate)
| Agent | Model | When to Use |
|-------|-------|-------------|
| `test-specialist` | sonnet | TDD Red phase: write failing tests, create mocks, design coverage. Never production code. |
| `macro-engineer` | sonnet | Create/modify Swift macros (@AgentActor, @Tool, custom macros) |
| `swift-code-reviewer` | — | After code changes, before commits |
| `swift-debug-agent` | — | Build failures, compilation errors, linker issues |

### Routing Decision Tree

Evaluate conditions **in order** (first-match-wins, inspired by Swarm's `AgentRouter`):

```
TASK RECEIVED
│
├─ NEW SESSION or COMPLEX TASK (3+ files)?
│  └─ YES → context-builder (research phase)
│
├─ DESIGNING a new protocol or type hierarchy?
│  └─ YES → protocol-architect
│
├─ DESIGNING a public API surface?
│  └─ YES → api-designer
│
├─ ORCHESTRATION patterns (routing, chains, parallel, handoffs)?
│  └─ YES → framework-architect
│
├─ CONCURRENCY (actors, Sendable, async, isolation)?
│  └─ YES → concurrency-expert (review) → implementer (code)
│
├─ SWIFT MACROS?
│  └─ YES → macro-engineer
│
├─ WRITING TESTS (TDD Red phase)?
│  └─ YES → test-specialist
│
├─ WRITING CODE?
│  ├─ Swarm framework (Sources/Swarm/, Tests/SwarmTests/)?
│  │  ├─ HiveSwarm bridge (Sources/HiveSwarm/)? → hive-implementer
│  │  └─ YES → swarm-implementer
│  ├─ High complexity (3+ files, novel pattern) → swift-expert (opus)
│  ├─ Medium complexity (standard patterns) → implementer (sonnet)
│  └─ Low complexity (<20 lines) → fixer (haiku)
│
├─ BUILD FAILURE? → swift-debug-agent
├─ CODE REVIEW? → swift-code-reviewer
├─ DOCUMENTATION? → api-documenter
└─ FALLBACK → Lead session handles directly
```

### Common Agent Chains

**New Swarm Feature (TDD)**:
`context-builder → test-specialist → protocol-architect → api-designer → swarm-implementer → concurrency-expert → swift-code-reviewer`

**Hive Bridge Feature**:
`context-builder → framework-architect → test-specialist → hive-implementer → concurrency-expert → swift-code-reviewer`

**Bug Fix (Swarm)**:
`context-builder → swift-debug-agent → swarm-implementer → test-specialist → swift-code-reviewer`

**New Orchestration Pattern**:
`context-builder → framework-architect → protocol-architect → test-specialist → swarm-implementer → concurrency-expert → swift-code-reviewer`

### Agent Delegation Protocol

#### Context Handoff
Every delegation MUST include:
1. Task brief (what to do)
2. Context document path (`.claude/context/active-task.md`)
3. Previous agent output summary
4. File scope constraints (which files to touch)

Every agent MUST return:
1. Summary (< 200 words)
2. Files changed list
3. Decisions made with rationale
4. Handoff notes for next agent
5. Concerns or risks discovered

#### Quality Gates
| Gate | Check | Agent |
|------|-------|-------|
| Design → Implementation | Protocol compiles, API is ergonomic | Lead session review |
| Implementation → Review | `swift build` succeeds | swift-debug-agent |
| Review → Commit | No critical issues | swift-code-reviewer |
| Commit → Done | `swift test` passes | Lead session (Bash) |

#### Conflict Resolution
| Conflict | Resolution |
|----------|------------|
| swarm-implementer vs implementer | Swarm source files → swarm-implementer; non-Swarm → global implementer |
| hive-implementer vs swarm-implementer | `Sources/HiveSwarm/` → hive; `Sources/Swarm/` → swarm |
| swift-expert vs swarm-implementer | Novel patterns / 3+ files → swift-expert; standard Swarm → swarm-implementer |
| implementer vs fixer | Single file, <20 lines → fixer (cost optimization) |
| Design agents disagree | Present both options to user via AskUserQuestion; record decision |

#### Context Management (Long-Running Tasks)
**Always use `context-builder` agent** at the start of complex or long-running tasks to:
- Gather comprehensive requirements before implementation
- Research existing codebase patterns and conventions
- Identify dependencies and integration points
- Create a clear roadmap before delegating to specialist agents

**Context Preservation Workflow**:
1. **Start**: Use `context-builder` to research and gather context
2. **Plan**: Document findings and create implementation plan
3. **Execute**: Delegate to specialist agents with clear context handoffs
4. **Checkpoint**: Re-invoke `context-manager` between major phases
5. **Update**: Keep `.claude/context/active-task.md` and memory updated throughout

### Skills Reference

| Skill | Purpose | When to Load |
|-------|---------|-------------|
| `/swarm-patterns` | Swarm framework patterns reference | Any agent working on Swarm code |
| `/tdd-workflow` | TDD Red-Green-Refactor with Swarm examples | Start of implementation tasks |
| `/swift-concurrency-guide` | Swift 6.2 concurrency quick reference | Concurrency review or async code |

## Quick References
- API patterns: See `Sources/Swarm/Examples/`
- Protocol design: See `Sources/Swarm/Core/Protocols/`
- Testing mocks: See `Tests/SwarmTests/Mocks/`
