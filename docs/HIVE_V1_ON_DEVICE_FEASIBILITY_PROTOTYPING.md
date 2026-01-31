Prompt:
You are a performance-aware Swift 6.2 engineer. Design an on-device feasibility/prototyping plan for Hive v1 that validates concurrency, streaming, checkpointing, and memory behavior on iOS 17/macOS 14.

Goal:
Prove the core runtime model is viable on-device by building minimal prototypes that exercise AsyncThrowingStream events, bounded concurrency, checkpoint IO, and task-local fan-out at realistic scales.

Task BreakDown:
- Define a minimal prototype graph (3-5 nodes) that exercises: fan-out via task-local overlays, reducer merges, and deterministic event ordering.
- Build a micro app harness (iOS + macOS) that can run the prototype graph repeatedly and display event counts + timing summaries.
- Prototype event streaming: measure throughput and backpressure behavior for AsyncThrowingStream with a buffered, deterministic emission strategy.
- Prototype checkpointing with Wax: measure save/load latency and serialized size for varying channel counts and message sizes.
- Stress test bounded concurrency: vary maxConcurrentTasks and record CPU usage, memory footprint, and step completion time.
- Validate interruption + resume: simulate tool-approval interrupt, persist, resume after app restart, and compare final store to uninterrupted run.
- Identify mobile constraints: backgrounding, memory pressure, and cancellation propagation, and define mitigations or limits.
- Produce a short feasibility report with findings, bottlenecks, and recommended default settings for v1 (maxSteps, maxConcurrentTasks, checkpoint policy).
