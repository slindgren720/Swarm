# Phase 2 RunHooks Code Review Summary

**Date:** 2025-12-26
**Branch:** feature/phase2-runhooks
**Reviewers:** 6 parallel code review agents

## Status: FIXES NEEDED

### OpenAI SDK Parity
- **7/7 core hooks MATCH** + 2 Swift extensions (onError, onGuardrailTriggered)
- SwiftAgents EXCEEDS OpenAI SDK by including tool arguments in hooks

## Critical Issues (Must Fix)

### 1. Duplicate Hook Notifications
- **Files:** `Tool.swift:320-345` + All agents
- **Fix:** Remove hook calls from ToolRegistry

### 2. Empty inputMessages in onLLMStart
- **Locations:** ReActAgent:220, ToolCallingAgent:246,390, PlanAndExecuteAgent:489,740,773,871
- **Fix:** Pass actual MemoryMessage array

### 3. Missing onHandoff in Orchestration
- **Files:** SequentialChain, SupervisorAgent, AgentRouter, ResilientAgent
- **Fix:** Add onHandoff calls before delegating

### 4. Data Race in RecordingHooks
- **File:** RunHooksTests.swift:38
- **Fix:** Change to actor

### 5. Unnecessary await
- **File:** LoggingRunHooks (all methods)
- **Fix:** Remove await for nonisolated property

## Memory Recovery Command

```
mcp__memory__open_nodes(["Phase2_RunHooks_Implementation", "Code_Review_Results", "Phase2_Critical_Fixes_Needed"])
```

## Plan File Location
`/Users/chriskarani/.claude/plans/floating-hugging-stearns.md`
