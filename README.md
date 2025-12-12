# SwiftAgents

[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2026%20|%20macOS%2026%20|%20watchOS%2026%20|%20tvOS%2026%20|%20visionOS%2026-blue.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**LangChain for Apple Platforms** — A comprehensive Swift framework for building AI agents with Apple's Foundation Models.

SwiftAgents provides the agent orchestration layer for autonomous reasoning, memory systems, and multi-agent coordination, designed specifically for Apple's ecosystem.

---

## Features

- 🤖 **Agent Framework** - ReAct, Plan-and-Execute, and custom agent patterns
- 🧠 **Memory Systems** - Conversation, vector, and summary memory
- 🛠️ **Tool Integration** - Extensible tool protocol with `@Tool` macro
- 🎭 **Multi-Agent Orchestration** - Supervisor-worker and collaborative patterns
- 📊 **Observability** - Built-in tracing, metrics, and debugging
- 🔄 **Resilience** - Retry policies, circuit breakers, and fallbacks
- 🎨 **SwiftUI Components** - Ready-to-use chat and status views

---

## Requirements

- iOS 26.0+ / macOS 26.0+ / watchOS 26.0+ / tvOS 26.0+ / visionOS 26.0+
- Swift 6.2+
- Xcode 26.0+

---

## Installation

### Swift Package Manager

Add SwiftAgents to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/chriskarani/SwiftAgents.git", from: "1.0.0")
]
```

Then add the dependency to your target:

```swift
.target(
    name: "YourApp",
    dependencies: [
        "SwiftAgents",
        "SwiftAgentsUI"  // Optional: for SwiftUI components
    ]
)
```

---

## Quick Start

### Basic Agent

```swift
import SwiftAgents

// Create a simple agent
let agent = ReActAgent(
    model: FoundationModel.default,
    tools: [SearchTool(), CalculatorTool()]
)

// Run the agent
let response = try await agent.execute("What is 25 * 4?")
print(response.content)
```

### With Memory

```swift
import SwiftAgents

// Create agent with conversation memory
let memory = ConversationMemory(maxTokens: 4000)
let agent = ReActAgent(
    model: FoundationModel.default,
    memory: memory
)

// Conversation maintains context
let response1 = try await agent.execute("My name is Alice")
let response2 = try await agent.execute("What's my name?")
// Agent remembers: "Your name is Alice"
```

### SwiftUI Integration

```swift
import SwiftUI
import SwiftAgentsUI

struct ChatView: View {
    @State private var agent = ReActAgent.default

    var body: some View {
        AgentChatView(agent: agent)
            .navigationTitle("AI Assistant")
    }
}
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Your Application                      │
├─────────────────────────────────────────────────────────┤
│                     SwiftAgentsUI                        │
│              (ChatView, StatusView, etc.)                │
├─────────────────────────────────────────────────────────┤
│                      SwiftAgents                         │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐    │
│  │ Agents  │  │ Memory  │  │  Tools  │  │  Orch.  │    │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘    │
├─────────────────────────────────────────────────────────┤
│              Foundation Models / SwiftAI SDK             │
│                   (Inference Layer)                      │
└─────────────────────────────────────────────────────────┘
```

---

## Documentation

- [Getting Started Guide](docs/getting-started.md)
- [Agent Patterns](docs/agent-patterns.md)
- [Memory Systems](docs/memory-systems.md)
- [Tool Development](docs/tool-development.md)
- [Multi-Agent Orchestration](docs/orchestration.md)
- [API Reference](docs/api-reference.md)

---

## Examples

| Example | Description |
|---------|-------------|
| [BasicAgent](Examples/BasicAgent) | Minimal agent setup and execution |
| [ChatApp](Examples/ChatApp) | Complete SwiftUI chat application |
| [MultiAgentWorkflow](Examples/MultiAgentWorkflow) | Supervisor-worker orchestration |

---

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## License

SwiftAgents is released under the MIT License. See [LICENSE](LICENSE) for details.

---

## Acknowledgments

- Inspired by [LangChain](https://langchain.com) and [AutoGPT](https://autogpt.net)
- Built for Apple's [Foundation Models](https://developer.apple.com/machine-learning/foundation-models/)
- Part of the SwiftAI ecosystem
