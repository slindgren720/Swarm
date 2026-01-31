Prompt:
You are a Swift 6.2 performance engineer. Define the evaluation and benchmarks needed to validate Hive v1 correctness, determinism, and runtime efficiency with actionable metrics.

Goal:
Create a benchmark plan and success criteria covering determinism, reducer correctness, checkpoint performance, and streaming overhead, with clear metrics and baselines.

Task BreakDown:
- Define benchmark suites for: reducer application, step commit ordering, event emission, checkpoint save/load, and fan-out task scheduling.
- Specify input scales (channel count, write count, task count, message sizes) and the metrics to record (latency, throughput, memory, allocation counts).
- Create a determinism test harness that replays identical runs and compares golden traces + final store fingerprints.
- Add regression thresholds (e.g., max acceptable latency per step, max checkpoint size growth, max variance across runs).
- Provide a benchmarking harness plan using Swift Testing or a lightweight in-package benchmark target (no external dependencies).
- Include tooling and reporting guidance: how to run benchmarks, where results are stored, and how to compare baselines.
- Identify the minimal set of benchmarks required for v1 readiness and which can be deferred to v1.1.
