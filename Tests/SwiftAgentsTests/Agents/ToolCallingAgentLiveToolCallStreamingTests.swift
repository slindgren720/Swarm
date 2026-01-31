import Testing
@testable import SwiftAgents

@Suite("ToolCallingAgent Live Tool Call Streaming")
struct ToolCallingAgentLiveToolCallStreamingTests {
    @Test("Emits toolCallPartial before toolCallStarted when provider streams tool-call assembly")
    func emitsPartialUpdatesBeforeToolExecution() async throws {
        struct EchoTool: AnyJSONTool, Sendable {
            let name = "echo"
            let description = "Echoes the input text"
            let parameters: [ToolParameter] = [
                ToolParameter(name: "text", description: "Text to echo", type: .string)
            ]

            func execute(arguments: [String: SendableValue]) async throws -> SendableValue {
                .string(try requiredString("text", from: arguments))
            }
        }

        actor ScriptedStreamingProvider: @preconcurrency ToolCallStreamingInferenceProvider {
            private var scripts: [[InferenceStreamUpdate]]
            private var index: Int = 0

            init(scripts: [[InferenceStreamUpdate]]) {
                self.scripts = scripts
            }

            func nextScript() -> [InferenceStreamUpdate] {
                defer { index += 1 }
                return scripts[min(index, scripts.count - 1)]
            }

            func generate(prompt _: String, options _: InferenceOptions) async throws -> String {
                throw AgentError.generationFailed(reason: "Unexpected call to generate() in streaming test")
            }

            func stream(prompt _: String, options _: InferenceOptions) -> AsyncThrowingStream<String, Error> {
                StreamHelper.makeTrackedStream { continuation in
                    continuation.finish(throwing: AgentError.generationFailed(reason: "Unexpected call to stream() in streaming test"))
                }
            }

            func generateWithToolCalls(
                prompt _: String,
                tools _: [ToolSchema],
                options _: InferenceOptions
            ) async throws -> InferenceResponse {
                throw AgentError.generationFailed(reason: "Unexpected call to generateWithToolCalls() in streaming test")
            }

            func streamWithToolCalls(
                prompt _: String,
                tools _: [ToolSchema],
                options _: InferenceOptions
            ) -> AsyncThrowingStream<InferenceStreamUpdate, Error> {
                StreamHelper.makeTrackedStream { continuation in
                    let updates = await self.nextScript()
                    for update in updates {
                        continuation.yield(update)
                    }
                    continuation.finish()
                }
            }

            func callCount() -> Int { index }
        }

        let partial1 = PartialToolCallUpdate(
            providerCallId: "call_1",
            toolName: "echo",
            index: 0,
            argumentsFragment: #"{"text":"#
        )
        let partial2 = PartialToolCallUpdate(
            providerCallId: "call_1",
            toolName: "echo",
            index: 0,
            argumentsFragment: #"{"text":"hi"}"#
        )
        let completed = [
            InferenceResponse.ParsedToolCall(id: "call_1", name: "echo", arguments: ["text": .string("hi")])
        ]

        let provider = ScriptedStreamingProvider(scripts: [
            [
                .toolCallPartial(partial1),
                .toolCallPartial(partial2),
                .usage(.init(inputTokens: 1, outputTokens: 1)),
                .toolCallsCompleted(completed),
            ],
            [
                .outputChunk("All done"),
                .usage(.init(inputTokens: 1, outputTokens: 1)),
            ],
        ])

        let agent = ToolCallingAgent(
            tools: [EchoTool()],
            configuration: .default.maxIterations(3),
            inferenceProvider: provider
        )

        var events: [AgentEvent] = []
        for try await event in agent.stream("Hi") {
            events.append(event)
        }

        let partialIndex = events.firstIndex { event in
            if case .toolCallPartial = event { return true }
            return false
        }
        let toolStartIndex = events.firstIndex { event in
            if case .toolCallStarted = event { return true }
            return false
        }

        #expect(partialIndex != nil)
        #expect(toolStartIndex != nil)
        if let partialIndex, let toolStartIndex {
            #expect(partialIndex < toolStartIndex)
        }

        if let idx = toolStartIndex,
           case let .toolCallStarted(call) = events[idx]
        {
            #expect(call.providerCallId == "call_1")
            #expect(call.toolName == "echo")
        } else {
            Issue.record("Missing expected toolCallStarted event")
        }

        if let completedEvent = events.last(where: { if case .completed = $0 { true } else { false } }),
           case let .completed(result) = completedEvent
        {
            #expect(result.output == "All done")
            #expect(result.toolCalls.first?.providerCallId == "call_1")
        } else {
            Issue.record("Missing expected completed event")
        }

        let count = await provider.callCount()
        #expect(count == 2)
    }
}
