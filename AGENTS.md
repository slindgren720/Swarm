# Repository Guidelines

## Project Structure & Module Organization
- `Sources/SwiftAgents/` contains the core framework (agents, tools, memory, orchestration, observability).
- `Sources/SwiftAgentsMacros/` hosts macro implementations.
- `Sources/SwiftAgentsDemo/` is the demo executable target.
- `Tests/SwiftAgentsTests/` and `Tests/SwiftAgentsMacrosTests/` contain Swift Testing suites.
- `docs/` holds architectural notes, guides, and API references.
- `scripts/` contains developer utilities (for example `generate-coverage-report.sh`).

## Build, Test, and Development Commands
- `swift build` builds the package and validates Swift 6.2 compatibility.
- `swift test` runs all test suites.
- `swift test --filter AgentTests` runs a focused subset of tests.
- `swift run SwiftAgentsDemo` runs the demo executable target.
- `./scripts/generate-coverage-report.sh` generates coverage artifacts in `.build/coverage/` and enforces a minimum threshold (70% by default).
- `swift package plugin --allow-writing-to-package-directory swiftformat` applies SwiftFormat.
- `swiftlint lint` runs linting (install via Homebrew if needed).

## Coding Style & Naming Conventions
- Swift 6.2, strict concurrency enabled; public types must be `Sendable`.
- Prefer value types (`struct`) and actors for shared mutable state.
- Protocol-first design; use generics and protocol extensions for defaults.
- Naming: `UpperCamelCase` for types, verb phrases for mutating methods, `is/has/should` for booleans.
- Keep logging on `swift-log` (`Log.*` categories); avoid `print()` in production code.

## Testing Guidelines
- Use Swift Testing (`import Testing`) with `@Suite` and `@Test`.
- Follow TDD: write failing tests first, then minimal implementation, then refactor.
- Tests live under `Tests/SwiftAgentsTests/` and `Tests/SwiftAgentsMacrosTests/`.

## Commit & Pull Request Guidelines
- Commit messages are short, imperative, and capitalized (e.g., `Add`, `Refactor`, `Default`, `Revert`).
- PRs should include: clear description, linked issue (if any), test results, and docs updates when APIs change.
- Include screenshots or logs for UI/observability changes.

## Security & Configuration Tips
- Avoid logging secrets or PII; redact sensitive data at runtime.
- Use mock providers for tests and avoid external network calls in unit tests.
