# Swarm DSL + HiveDSL: Implementation Progress

## Status: In Progress

Last Updated: 2026-02-09
Branch: `bugfixrd`
Build Status: PASSING
Test Status: SmartGraphCompilationTests 17/17 PASSING

---

## Current State (Pre-Implementation)

### Build Status
- Swift build: PASSING
- All tests: PASSING
- Branch: `bugfixrd` (off `main`)
- Recent commits:
  - `1708a10`: Review and fix uncommitted changes
  - `d476e0f`: Merge remote-tracking branch 'origin/main' into bugfixrd
  - `d9b7e90`: Add OpenAI SDK-inspired API improvements for developer ergonomics

### Modified Files (bugfixrd)
- `Sources/Swarm/Core/AgentConfiguration.swift`
- `Sources/Swarm/Core/AgentEvent.swift`
- `Sources/Swarm/Orchestration/OrchestrationError.swift`
- `Sources/Swarm/Orchestration/OrchestrationHiveEngine.swift`
- `Tests/HiveSwarmTests/HiveBackedAgentStreamingTests.swift`
- `Tests/HiveSwarmTests/ModelRouterTests.swift`

### New/Untracked Files (DSL/Orchestration features)
- `DSL/` directory (new DSL namespace)
- `Sources/Swarm/DSL/` — Main DSL module
  - `CLAUDE.md` — DSL sub-agent documentation
  - `Core/` — Core DSL protocols and builders
  - `Flow/` — Flow control DSL (Parallel, Router, Sequential)
  - `Modifiers/` — DSL step modifiers and chainable APIs
- `Sources/Swarm/Memory/CLAUDE.md` — Memory systems sub-agent
- `Sources/Swarm/Orchestration/ConditionalBranch.swift` — Branch/Router step
- `Sources/Swarm/Orchestration/DAGWorkflow.swift` — DAG-based workflow composition
- `Sources/Swarm/Orchestration/HumanApproval.swift` — Human approval step
- `Sources/Swarm/Orchestration/RepeatWhile.swift` — Loop primitive (DONE)
- `Sources/Swarm/Orchestration/WorkflowCheckpoint.swift` — Checkpoint/savepoint
- `Tests/SwarmTests/DSL/CLAUDE.md` — DSL testing sub-agent
- `Tests/SwarmTests/Orchestration/NewPrimitivesTests.swift` — Tests for new step types
- `Tests/SwarmTests/Orchestration/SmartGraphCompilationTests.swift` — Smart graph tests (DONE: 17/17)
- `docs/SMART_GRAPH_COMPILATION_PLAN.md` — Detailed phase breakdown

---

## Phase Status

### Phase 1: Smart Graph Compilation — **COMPLETE**

**Status**: All 17 tests passing. Recursive Hive DAG compilation fully functional.

**Deliverables**:
- [x] `computeMaxParallelism()` — Recursively computes workflow's max concurrent tasks
  - Single agent: 1
  - Sequential: 1 (sequential by definition)
  - Parallel: max count of branches
  - Router: max parallelism of any branch
  - Group: max parallelism of inner steps
  - Tests: 8/8 PASSING

- [x] `compileStep()` — Recursive function that converts OrchestrationStep → Hive DAG
  - AgentStep/Transform: single node
  - Sequential/Group: chain (node0 → node1 → ... → nodeN)
  - Parallel: fan-out (dispatch → [branch0, branch1, ...] → merge)
  - Router: conditional (eval → HiveRouter → {branch_a | branch_b | ...} → converge)
  - Tests: 6/6 PASSING

- [x] `compileParallel()` — Fan-out/fan-in compilation
  - Dispatch node clears branchResults channel
  - Branch nodes run concurrently, write BranchResult
  - Merge node reads all results, applies MergeStrategy, updates currentInput
  - Tests: 2/2 PASSING

- [x] `compileRouter()` — Conditional routing compilation
  - Eval node evaluates conditions, writes routerDecision channel
  - HiveRouter routes based on decision
  - Converge node merges result back to currentInput
  - Tests: 1/1 PASSING

- [x] BranchResult type and channel infrastructure
  - `struct BranchResult: Codable, Sendable, Equatable`
  - Fields: groupID, branchIndex, name, output, toolCalls, toolResults, iterationCount, metadata
  - Channel: `branchResultsKey` (multi-write, append reducer)
  - Reducer: `branchResultsReduce()` appends results
  - Tests: 3/3 PASSING

- [x] `makeRunOptions()` updated to use computed parallelism
  - Reads `maxConcurrentTasks` from `computeMaxParallelism()`
  - Tests integrated into SmartGraphCompilationTests

**Files**:
- `Sources/Swarm/Orchestration/OrchestrationHiveEngine.swift` — Main implementation
- `Tests/SwarmTests/Orchestration/SmartGraphCompilationTests.swift` — Test suite (17 tests)

**Key Architecture**:
```swift
// Schema channels
static let branchResultsKey = HiveChannelKey<Self, [BranchResult]>(
    HiveChannelID("branchResults")
)
static let routerDecisionKey = HiveChannelKey<Self, String>(
    HiveChannelID("routerDecision")
)
```

---

### Phase 2: BranchResult Type + Channel Infrastructure — **COMPLETE**

**Status**: Fully integrated into Phase 1. BranchResult and channels are operational.

**Deliverables**:
- [x] BranchResult struct with all required fields
- [x] Equatable, Codable, Sendable conformance
- [x] branchResultsKey channel in Schema
- [x] branchResultsReduce() appends results without loss
- [x] routerDecisionKey channel for router branch selection
- [x] Merge node applies MergeStrategy correctly
- [x] Tests: branchResultsReduce tests (3/3 PASSING)

**Integration Notes**:
- branchResults channel scope: `.global`
- Update policy: `.multi` (multiple writes allowed)
- Persistence: `.checkpointed` (survives restarts)
- routerDecision channel scope: `.global`
- Update policy: `.single` (one write per execution)

---

### Phase 3: HiveDSL Escape Hatch — **TODO**

**Status**: Planned. Allows direct Hive step embedding when DSL isn't expressive enough.

**Goal**: Enable Hive step injection for advanced use cases (interrupts, custom nodes, etc.).

**Planned Deliverables**:
- [ ] `HiveStep.swift` — New file
  ```swift
  public struct HiveStep: OrchestrationStep {
      public let node: (inout HiveGraphBuilder<OrchestrationHiveEngine.Schema>) -> HiveNodeID
      public func execute(_ input: String, context: OrchestrationStepContext) async throws -> AgentResult
  }
  ```

- [ ] Interrupt step support (pause/resume workflows)
  ```swift
  HiveStep { builder in
      builder.addNode(MyInterruptNode())
  }
  ```

- [ ] `buildExpression` for HiveStep in OrchestrationBuilder
  - Allows: `@OrchestrationBuilder { HiveStep { ... } }`

- [ ] `compileStep` handling for HiveStep in engine
  - Directly returns the builder result (no wrapping)

- [ ] Tests: `HiveStepTests.swift`
  - Test embedding custom nodes
  - Test interrupt semantics
  - Test compilation integration

**Dependencies**: Phase 1 (compilation engine in place)

---

### Phase 4: Unified Channel-Based State — **TODO**

**Status**: Planned. Provides general-purpose channel access for steps.

**Goal**: Allow steps to read/write arbitrary channels without needing schema modification.

**Planned Deliverables**:
- [ ] `OrchestrationChannels.swift` — New file (channel bag pattern)
  ```swift
  public struct OrchestrationChannel<Value: Codable & Sendable>: Sendable {
      public let id: String
      public init(id: String)
  }
  ```

- [ ] Channel bag pattern using single [String:Data] channel
  - Constraint: HiveChannelKey requires compile-time registration
  - Workaround: Use single `channelBagKey` channel holding [String:Data]
  - Each OrchestrationChannel<T> is keyed by `OrchestrationChannel.id`

- [ ] `OrchestrationStepContext` extensions
  ```swift
  extension OrchestrationStepContext {
      func read<T>(_ channel: OrchestrationChannel<T>) async throws -> T?
      func write<T>(_ channel: OrchestrationChannel<T>, value: T) async throws
  }
  ```

- [ ] Tests: `OrchestrationChannelTests.swift`
  - Test read/write semantics
  - Test serialization/deserialization
  - Test concurrent access patterns

**Dependencies**: Phase 1 (schema in place)

**Notes**:
- This enables custom state sharing between steps without modifying Schema
- Use case: step-local counters, caches, intermediate results
- Alternative to modifying Schema (which requires HiveChannelKey registration)

---

### Phase 5: Bidirectional Compilation — **TODO**

**Status**: Planned. Enables loops and nested Hive blueprints.

**Goal**: Support cycles (loops) and Hive graph composition bidirectionally.

**Planned Deliverables**:
- [ ] `Loop.swift` — New file (cycle support in Hive)
  - RepeatWhile already exists (swift-runtime only)
  - Loop uses Hive graph cycles (backward edges)
  ```swift
  public struct Loop: OrchestrationStep {
      public let body: any OrchestrationStep
      public let condition: @Sendable (String) async throws -> Bool
      public let maxIterations: Int

      public func execute(_ input: String, context: OrchestrationStepContext) async throws -> AgentResult
  }
  ```

- [ ] `HiveAgentBlueprint.swift` — New file (embed Hive graphs as steps)
  ```swift
  public struct HiveAgentBlueprint: OrchestrationStep {
      public let graph: HiveGraph<Schema>

      public func execute(_ input: String, context: OrchestrationStepContext) async throws -> AgentResult
  }
  ```

- [ ] `buildExpression` for Loop in OrchestrationBuilder
  - Allows nested loops in DSL

- [ ] `compileStep` handling for Loop
  - Detects cycles, creates backward edges in Hive graph
  - Manages condition evaluation at cycle entry

- [ ] `compileStep` handling for HiveAgentBlueprint
  - Embeds pre-built Hive graph as sub-workflow

- [ ] Tests: `LoopTests.swift`, `HiveAgentBlueprintTests.swift`
  - Test loop compilation
  - Test cycle detection
  - Test nested blueprint composition

**Dependencies**: Phase 1 (compilation engine), Phase 3 (HiveStep escape hatch)

**Challenge**: Hive doesn't have explicit backward edges. Loop will use condition evaluation to simulate cycles.

---

### Phase 6: Swift Language-Powered DSL Evolution — **TODO**

**Status**: Planned. Advanced Swift 6 language features for ergonomics.

**Goal**: Leverage Swift's type system and macros for cleaner, safer DSL.

**Sub-Phases** (can be developed in parallel after Phase 1):

#### 6a: TypedParallel — Parameter Pack Parallel
**Status**: TODO
```swift
@OrchestrationBuilder
func complexFlow() {
    TypedParallel(
        agent1,
        agent2,
        agent3
    )
}
```
**Files**: `TypedParallel.swift`
**Dependencies**: Swift 5.9+ parameter packs, Phase 1

#### 6b: @Workflow Macro
**Status**: TODO (LAST — depends on 6a-6j)
```swift
@Workflow
func myWorkflow(@OrchestrationBuilder body: () -> OrchestrationStep) {
    Sequential {
        agent1
        Parallel { agent2; agent3 }
    }
}
```
**Files**: `Sources/SwarmMacros/WorkflowMacro.swift`, plugin updates
**Dependencies**: All other Phase 6 sub-phases

#### 6c: Regex Conditions in AgentRouter
**Status**: TODO
```swift
Router {
    When(.regex(#"code:\s*\w+"#)) { codeAgent }
    When(.prefix("urgent:")) { urgentAgent }
    Otherwise { defaultAgent }
}
```
**Files**: `AgentRouter+Regex.swift`
**Dependencies**: Phase 1

#### 6d: Variadic Combinators in AgentRouter
**Status**: TODO
```swift
Router {
    When(.all(.contains("urgent"), .contains("priority"))) { escalationAgent }
    When(.any(.contains("bug"), .contains("issue"))) { debugAgent }
    When(.exactly(1, .contains("wait"))) { delayAgent }
    Otherwise { normalAgent }
}
```
**Files**: `AgentRouter+Combinators.swift`
**Dependencies**: Phase 1

#### 6e: Key Path Transforms in OrchestrationBuilder
**Status**: TODO
```swift
@OrchestrationBuilder
func customFlow() {
    Sequential {
        agent1
        Transform { $0.uppercased() }
        Transform(\.split(separator: " ").first ?? "")
    }
}
```
**Files**: `Transform+KeyPath.swift`
**Dependencies**: Phase 1

#### 6f: StepModifiers Protocol
**Status**: TODO
```swift
public protocol StepModifier {
    associatedtype Body: OrchestrationStep
    var body: Body { get }
}

extension OrchestrationStep {
    func timeout(_ duration: Duration) -> some OrchestrationStep
    func retry(_ maxAttempts: Int) -> some OrchestrationStep
    func onError(_ handler: @Sendable (Error) async -> Void) -> some OrchestrationStep
}
```
**Files**: `StepModifiers.swift`, `Modifier+Builtins.swift`
**Dependencies**: Phase 1

#### 6g: PromptString Domain Interpolations
**Status**: TODO
```swift
let workflow = """
Ask \(agent1) to analyze.
Then send to \(agent2).
"""
```
**Files**: `PromptString+DSL.swift`
**Dependencies**: None (independent)

#### 6h: ResumeToken — `~Copyable` Token
**Status**: TODO (depends on Phase 3: HiveStep)
```swift
public struct ResumeToken: ~Copyable {
    let checkpoint: WorkflowCheckpoint
    let resumeStep: HiveNodeID

    consuming func resume(with input: String) async throws -> AgentResult
}
```
**Files**: `ResumeToken.swift`
**Dependencies**: Phase 3 (HiveStep escape hatch), Phase 5 (checkpoints)
**Note**: Uses ~Copyable to ensure token is consumed exactly once

#### 6i: CallableAgent — @dynamicCallable Wrapper
**Status**: TODO
```swift
@dynamicCallable
struct CallableAgent {
    let agent: any AgentRuntime

    func dynamicallyCall(withArguments args: String...) async throws -> AgentResult
}

let result = try await callableAgent("input1", "input2")
```
**Files**: `CallableAgent.swift`
**Dependencies**: None (independent)

#### 6j: Fallback + Auto-Naming in ParallelBuilder
**Status**: TODO
```swift
Parallel {
    agent1              // auto-name: "agent1"
    agent2              // auto-name: "agent2"
}
.fallback(agent3)       // if parallel fails, use fallback

Parallel {
    agent1.named("fast")
    slowAgent.named("thorough")
}.merge(.interleaved)   // custom merge strategy
```
**Files**: `Fallback.swift`, `ParallelBuilder+AutoNaming.swift`
**Dependencies**: Phase 1

#### 6k: Convenience Methods on Orchestration
**Status**: TODO
```swift
extension Orchestration {
    func run(_ input: String) async throws -> AgentResult
    func stream(_ input: String) -> AsyncThrowingStream<AgentEvent, Error>
}
```
**Files**: `Orchestration+Convenience.swift`
**Dependencies**: Phase 1

---

## Implementation Dependencies

```
Phase 1 (Smart Graph Compilation) — DONE
├─→ Phase 3 (HiveDSL Escape Hatch) — TODO
│   └─→ Phase 5 (Bidirectional Compilation) — TODO
│       └─→ 6h (ResumeToken ~Copyable) — TODO
├─→ Phase 4 (Unified Channel State) — TODO
└─→ Phase 2 (BranchResult) — DONE (part of Phase 1)

Phase 6 (Swift Language DSL Evolution) — TODO
├─→ 6a (TypedParallel) — independent
├─→ 6c (Regex Conditions) — independent
├─→ 6d (Variadic Combinators) — independent
├─→ 6e (Key Path Transforms) — independent
├─→ 6f (StepModifiers) — independent
├─→ 6g (PromptString) — independent
├─→ 6i (CallableAgent) — independent
├─→ 6j (Fallback + Auto-Naming) — independent
├─→ 6k (Convenience Methods) — independent
└─→ 6b (@Workflow Macro) — LAST (depends on all Phase 6 sub-phases)
```

**Parallel Development Opportunity**: Phase 6 sub-phases (6a, 6c-6k) can be developed in parallel after Phase 1 is stable. Only 6b (@Workflow macro) must wait for all others.

---

## Key Architecture Notes

### Hive Runtime
- All builds use Hive (no Swift-only fallback for new code)
- Orchestration execution is Hive-only
- New files target Hive exclusively

### Schema Channels (4 core channels)
1. **currentInputKey** — Current step's input (initialized from context, updated by steps)
2. **accumulatorKey** — Accumulated tool calls/results across workflow
3. **branchResultsKey** — Parallel branch results ([BranchResult], multi-write)
4. **routerDecisionKey** — Selected router branch (String, single-write)

### Compilation Model
- **OrchestrationStep → HiveGraph**: Recursive compilation in `compileStep()`
- **Entry/Exit nodes**: Each step tracks entry and exit node IDs
- **maxParallelism**: Computed recursively, used for `maxConcurrentTasks` in RunOptions
- **Node structure**: Each compiled step may be 1 node (agent) or many (parallel, router)

### OrchestrationStep Protocol
```swift
protocol OrchestrationStep {
    func execute(_ input: String, context: OrchestrationStepContext) async throws -> AgentResult
}
```
- Bidirectional implementations can create cycles (needs careful handling in Phase 5)
- All implementations must be Sendable
- New steps in Phase 3+ should provide both Hive (`compileStep`) and Swift (`execute`) paths

### Testing Strategy
- All tests use mock agents (UppercaseAgent, PrefixAgent, etc.)
- No Foundation Models required in simulators
- SmartGraphCompilationTests serves as golden test suite for compilation correctness
- TDD: Write tests first, then implementation

---

## Progress Tracking

### Completed (2026-02-09)
- [x] Phase 1: Smart Graph Compilation (all 17 tests passing)
- [x] Phase 2: BranchResult infrastructure (integrated into Phase 1)
- [x] Repository organization (DSL/, Orchestration/, etc.)
- [x] New primitives: RepeatWhile, ConditionalBranch, DAGWorkflow, HumanApproval, WorkflowCheckpoint
- [x] Test suite: SmartGraphCompilationTests.swift

### Next Steps (Priority Order)
1. **Phase 3** (HiveDSL Escape Hatch) — Enables advanced users, small scope
2. **Phase 4** (Unified Channels) — Enables custom state sharing, medium scope
3. **Phase 5** (Bidirectional Compilation) — Enables loops in Hive graphs, large scope
4. **Phase 6a-6k** (Language Features) — Can proceed in parallel, increasing scope
5. **Phase 6b** (@Workflow Macro) — Final phase, integration

---

## Risk Mitigation

### Backward Compatibility
- Swift runtime path (`case .swift`) remains unaffected by Phase 1+
- Hive runtime newly compiled; existing execute() paths unchanged
- Schema additions are purely additive (new channels don't break existing ones)

### Step Boundary Preservation
- Each compiled Hive node still calls `step.execute()` — behavior unchanged
- Graph topology is improved but semantics remain identical
- No change to agent output or tool call semantics

### Fallback Strategy
- If compilation fails for a step type, gracefully wrap in single node
- Phase 3+ steps provide escape hatch for unhandled cases

---

## Testing Checklist

### Phase 1 (DONE)
- [x] computeMaxParallelism tests (8/8)
- [x] compileStep tests (6/6)
- [x] compileParallel tests (2/2)
- [x] compileRouter tests (1/1)
- [x] branchResultsReduce tests (3/3)
- [x] Integration tests with nested workflows

### Phase 3 (Upcoming)
- [ ] HiveStep embedding tests
- [ ] Interrupt semantics tests
- [ ] Builder integration tests

### Phase 4 (Upcoming)
- [ ] Channel read/write tests
- [ ] Serialization/deserialization tests
- [ ] Concurrent access tests

### Phase 5 (Upcoming)
- [ ] Loop compilation tests
- [ ] Cycle detection tests
- [ ] Nested blueprint tests

### Phase 6 (Upcoming)
- [ ] TypedParallel tests
- [ ] Regex condition tests
- [ ] StepModifier tests
- [ ] All other sub-phase tests

---

## Files Reference

### Core Implementation
- `Sources/Swarm/Orchestration/OrchestrationHiveEngine.swift` — Main Hive engine, compilation logic
- `Sources/Swarm/Orchestration/RepeatWhile.swift` — Loop step (completed)
- `Sources/Swarm/Orchestration/ConditionalBranch.swift` — Branch/Router step (in progress)
- `Sources/Swarm/Orchestration/DAGWorkflow.swift` — DAG composition (new)
- `Sources/Swarm/Orchestration/HumanApproval.swift` — Human approval step (new)
- `Sources/Swarm/Orchestration/WorkflowCheckpoint.swift` — Checkpoint step (new)

### Test Suite
- `Tests/SwarmTests/Orchestration/SmartGraphCompilationTests.swift` — Golden test suite (17/17 PASSING)
- `Tests/SwarmTests/Orchestration/NewPrimitivesTests.swift` — New step tests (in progress)

### DSL Module (Planned)
- `Sources/Swarm/DSL/Core/` — Core DSL protocols and builders
- `Sources/Swarm/DSL/Flow/` — Flow control (Parallel, Router, Sequential)
- `Sources/Swarm/DSL/Modifiers/` — Step modifiers and chainable APIs

### Documentation
- `docs/SMART_GRAPH_COMPILATION_PLAN.md` — Detailed technical breakdown
- `docs/DSL_IMPLEMENTATION_PROGRESS.md` — This file
- `Sources/Swarm/DSL/CLAUDE.md` — DSL sub-agent documentation
- `Sources/Swarm/Memory/CLAUDE.md` — Memory systems sub-agent documentation
- `Tests/SwarmTests/DSL/CLAUDE.md` — DSL testing sub-agent documentation

---

## Session Notes

### Branch Context
- Working on `bugfixrd` branch
- Recently merged from `main`
- Ready for PR to main after Phase 1 completion

### Build & Test Status
```bash
swift build                              # PASSING
swift test                               # All tests PASSING
swift test --filter SmartGraphCompilation # 17/17 PASSING
```

### Key Decision Points
1. **Channel bag pattern** (Phase 4): Use single [String:Data] channel instead of per-channel registration
2. **HiveStep escape hatch** (Phase 3): Allow direct builder access for advanced cases
3. **Loop implementation** (Phase 5): Use Hive cycles via condition evaluation
4. **@Workflow macro** (Phase 6b): Defer to end (depends on all Phase 6 features)

---

## Contact & Questions

For implementation details on specific phases:
- Phase 1 (Smart Graph): See `SMART_GRAPH_COMPILATION_PLAN.md`
- Phase 3+ (New steps): See sub-agent CLAUDE.md files in respective directories
- Testing strategy: See `Tests/SwarmTests/CLAUDE.md`
