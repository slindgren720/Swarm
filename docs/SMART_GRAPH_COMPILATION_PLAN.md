# Smart Graph Compilation Plan

## Overview

Refactor `OrchestrationHiveEngine.makeGraph()` to produce proper Hive DAGs instead of linear chains. This unlocks Hive's parallelism, routing, checkpointing, and deterministic replay for Swarm orchestrations.

## Current State

```
makeGraph() produces: step_0 → step_1 → step_2 → ... → step_N
maxConcurrentTasks: 1 (hardcoded)
```

Every step is an opaque node calling `step.execute()`. Hive has no visibility into step structure.

## Target State

```
makeGraph() produces proper DAGs:
  AgentStep    → single node
  Sequential   → chain: node_0 → node_1 → ... → node_N
  Parallel     → fan-out: dispatch → [branch_0, branch_1, ...] → merge
  Router       → conditional: eval → router → {branch_a | branch_b | fallback} → converge
  Transform    → single node
  Group        → chain (like Sequential)
```

`maxConcurrentTasks` computed from workflow's max parallelism.

## Architecture

### Channel Schema Enhancement

Add two new channels to support parallel fan-out and router decisions:

```swift
// New: Collects results from parallel branches
static let branchResultsKey = HiveChannelKey<Self, [BranchResult]>(
    HiveChannelID("branchResults")
)
// scope: .global, reducer: append, updatePolicy: .multi, persistence: .checkpointed

// New: Tracks which router branch was selected
static let routerDecisionKey = HiveChannelKey<Self, String>(
    HiveChannelID("routerDecision")
)
// scope: .global, reducer: .lastWriteWins(), updatePolicy: .single
```

### BranchResult Type

```swift
struct BranchResult: Codable, Sendable, Equatable {
    let groupID: String        // Identifies which Parallel group
    let branchIndex: Int       // Order within group
    let name: String           // Branch name for merge
    let output: String         // Agent output text
    let toolCalls: [ToolCall]
    let toolResults: [ToolResult]
    let iterationCount: Int
    let metadata: [String: SendableValue]
}
```

### Recursive Compilation

New `compileStep()` function returns entry/exit node IDs:

```swift
struct CompilationResult {
    let entryNodeID: HiveNodeID
    let exitNodeID: HiveNodeID
    let maxParallelism: Int
}

func compileStep(
    _ step: OrchestrationStep,
    prefix: String,
    builder: inout HiveGraphBuilder<Schema>
) -> CompilationResult
```

### Parallel Compilation Detail

For `Parallel { agent1.named("a"); agent2.named("b"); agent3.named("c") }`:

```
Hive Graph:
  parallel_0.dispatch → [parallel_0.branch_0, parallel_0.branch_1, parallel_0.branch_2] → parallel_0.merge

Dispatch node:
  - Clears branchResults for this group
  - Writes current input (branches read from currentInput)
  - Returns next: .nodes([branch_0, branch_1, branch_2])  ← runs in SAME superstep

Branch nodes (run concurrently):
  - Each reads currentInput
  - Runs its agent via step.execute()
  - Writes BranchResult to branchResults channel (multi-write, append reducer)
  - Returns next: .nodes([merge_node])

Merge node:
  - Reads branchResults channel
  - Filters by groupID
  - Applies MergeStrategy
  - Writes merged output to currentInput
  - Writes accumulated toolCalls/results to accumulator
```

### Router Compilation Detail

For `Router { When(.contains("code")) { codeAgent }; Otherwise { defaultAgent } }`:

```
Hive Graph:
  router_0.eval → HiveRouter → { router_0.route_0 | router_0.fallback } → router_0.converge

Eval node:
  - Reads currentInput
  - Evaluates conditions, writes decision to routerDecision channel
  - Returns next: .useGraphEdges (router handles branching)

HiveRouter (addRouter):
  - Reads routerDecision channel
  - Returns .nodes([selected_branch_node])

Branch nodes:
  - Reads currentInput, runs agent
  - Writes result to currentInput + accumulator
  - Returns next: .nodes([converge_node])

Converge node:
  - Passthrough (result already in currentInput from winning branch)
  - Adds router metadata
```

### maxConcurrentTasks Computation

```swift
func computeMaxParallelism(steps: [OrchestrationStep]) -> Int {
    var maxP = 1
    for step in steps {
        switch step {
        case let p as Parallel:
            maxP = max(maxP, p.items.count)
        case let s as Sequential:
            maxP = max(maxP, computeMaxParallelism(steps: s.steps))
        case let r as Router:
            for route in r.routes {
                maxP = max(maxP, computeMaxParallelism(steps: [route.step]))
            }
        case let g as OrchestrationGroup:
            maxP = max(maxP, computeMaxParallelism(steps: g.steps))
        default:
            break
        }
    }
    return maxP
}
```

## Implementation Phases

### Phase 1: Foundation (Tests + Channel Schema)
- [ ] Write failing tests for parallel fan-out compilation
- [ ] Write failing tests for router compilation
- [ ] Write failing tests for maxConcurrentTasks computation
- [ ] Add BranchResult type
- [ ] Add branchResults and routerDecision channels to Schema
- [ ] Add BranchResult reducer

### Phase 2: Recursive Compilation Engine
- [ ] Implement CompilationResult struct
- [ ] Implement compileStep() for AgentStep/Transform (single node)
- [ ] Implement compileStep() for Sequential/OrchestrationGroup (chain)
- [ ] Implement compileStep() for Parallel (fan-out)
- [ ] Implement compileStep() for Router (conditional routing)
- [ ] Implement computeMaxParallelism()
- [ ] Refactor makeGraph() to use recursive compilation

### Phase 3: Integration + Verification
- [ ] Update makeRunOptions() to use computed maxConcurrentTasks
- [ ] Update execute() to pass through new capabilities
- [ ] Verify all existing tests pass
- [ ] Write integration tests for nested workflows
- [ ] Add metadata tracking for graph structure

## Risk Mitigation

1. **Backward compatibility**: The Swift runtime path (`case .swift`) is unaffected
2. **Step boundary**: Each compiled node still calls `step.execute()` — no behavior change, just better graph topology
3. **Schema evolution**: New channels are additive; existing currentInput/accumulator channels unchanged
4. **Fallback**: If compilation fails for a step type, fall back to single-node wrapping

## Files Modified

- `Sources/Swarm/Orchestration/OrchestrationHiveEngine.swift` — Main changes
- `Tests/SwarmTests/OrchestrationHiveEngineTests.swift` — New test file (TDD)

## Dependencies

- HiveCore: `HiveGraphBuilder`, `addRouter()`, `HiveRouter`, `HiveNodeOutput.next`
- No new external dependencies required
