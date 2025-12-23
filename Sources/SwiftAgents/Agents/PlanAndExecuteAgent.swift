// PlanAndExecuteAgent.swift
// SwiftAgents Framework
//
// Plan-and-Execute agent implementation.
// Implements a three-phase paradigm: Plan, Execute, and Replan.

import Foundation
import Logging

// MARK: - StepStatus

/// The execution status of a plan step.
public enum StepStatus: String, Sendable, Equatable, Codable {
    /// Step has not yet started.
    case pending
    /// Step is currently being executed.
    case inProgress
    /// Step completed successfully.
    case completed
    /// Step execution failed.
    case failed
    /// Step was skipped due to dependency failure or plan revision.
    case skipped
}

// MARK: - PlanStep

/// An individual step in an execution plan.
///
/// Each step represents a discrete action that the agent needs to perform
/// to achieve the overall goal. Steps may depend on other steps and can
/// optionally invoke tools.
public struct PlanStep: Sendable, Equatable, Identifiable, Codable {
    /// Unique identifier for this step.
    public let id: UUID

    /// The ordinal position of this step in the plan.
    public let stepNumber: Int

    /// A description of what this step accomplishes.
    public let stepDescription: String

    /// The name of the tool to invoke, if any.
    public let toolName: String?

    /// Arguments to pass to the tool.
    public let toolArguments: [String: SendableValue]

    /// IDs of steps that must complete before this step can execute.
    public let dependsOn: [UUID]

    /// Current execution status of this step.
    public var status: StepStatus

    /// Result output from executing this step.
    public var result: String?

    /// Error message if the step failed.
    public var error: String?

    /// Creates a new plan step.
    /// - Parameters:
    ///   - id: Unique identifier. Default: new UUID
    ///   - stepNumber: The step's position in the plan.
    ///   - stepDescription: What this step accomplishes.
    ///   - toolName: Optional tool to invoke. Default: nil
    ///   - toolArguments: Arguments for the tool. Default: [:]
    ///   - dependsOn: Dependencies on other steps. Default: []
    ///   - status: Initial status. Default: .pending
    ///   - result: Step result. Default: nil
    ///   - error: Error message. Default: nil
    public init(
        id: UUID = UUID(),
        stepNumber: Int,
        stepDescription: String,
        toolName: String? = nil,
        toolArguments: [String: SendableValue] = [:],
        dependsOn: [UUID] = [],
        status: StepStatus = .pending,
        result: String? = nil,
        error: String? = nil
    ) {
        self.id = id
        self.stepNumber = stepNumber
        self.stepDescription = stepDescription
        self.toolName = toolName
        self.toolArguments = toolArguments
        self.dependsOn = dependsOn
        self.status = status
        self.result = result
        self.error = error
    }
}

// MARK: - PlanStep + CustomStringConvertible

extension PlanStep: CustomStringConvertible {
    public var description: String {
        let toolInfo = toolName.map { " [tool: \($0)]" } ?? ""
        return "Step \(stepNumber): \(stepDescription)\(toolInfo) (\(status.rawValue))"
    }
}

// MARK: - ExecutionPlan

/// A collection of steps that form a complete plan to achieve a goal.
///
/// The execution plan maintains the sequence of steps, tracks their status,
/// and provides utilities for determining which steps can be executed next.
public struct ExecutionPlan: Sendable, Equatable {
    /// The steps in this plan.
    public var steps: [PlanStep]

    /// The goal this plan is designed to achieve.
    public let goal: String

    /// When this plan was created.
    public let createdAt: Date

    /// Number of times this plan has been revised.
    public var revisionCount: Int

    /// Whether all steps have completed successfully.
    public var isComplete: Bool {
        steps.allSatisfy { $0.status == .completed || $0.status == .skipped }
    }

    /// Whether any step has failed.
    public var hasFailed: Bool {
        steps.contains { $0.status == .failed }
    }

    /// The next step that can be executed.
    ///
    /// Returns the first pending step whose dependencies have all completed.
    public var nextExecutableStep: PlanStep? {
        for step in steps where step.status == .pending {
            let dependenciesMet = step.dependsOn.allSatisfy { depId in
                steps.first { $0.id == depId }?.status == .completed
            }
            if dependenciesMet {
                return step
            }
        }
        return nil
    }

    /// Steps that have completed successfully.
    public var completedSteps: [PlanStep] {
        steps.filter { $0.status == .completed }
    }

    /// Steps that are still pending.
    public var pendingSteps: [PlanStep] {
        steps.filter { $0.status == .pending }
    }

    /// Steps that failed during execution.
    public var failedSteps: [PlanStep] {
        steps.filter { $0.status == .failed }
    }

    /// Creates a new execution plan.
    /// - Parameters:
    ///   - steps: The steps in the plan.
    ///   - goal: The goal to achieve.
    ///   - createdAt: Creation timestamp. Default: now
    ///   - revisionCount: Number of revisions. Default: 0
    public init(
        steps: [PlanStep],
        goal: String,
        createdAt: Date = Date(),
        revisionCount: Int = 0
    ) {
        self.steps = steps
        self.goal = goal
        self.createdAt = createdAt
        self.revisionCount = revisionCount
    }

    /// Updates a step's status by its ID.
    /// - Parameters:
    ///   - id: The step ID to update.
    ///   - status: The new status.
    ///   - result: Optional result to set.
    ///   - error: Optional error to set.
    public mutating func updateStep(
        id: UUID,
        status: StepStatus,
        result: String? = nil,
        error: String? = nil
    ) {
        guard let index = steps.firstIndex(where: { $0.id == id }) else { return }
        steps[index].status = status
        if let result { steps[index].result = result }
        if let error { steps[index].error = error }
    }

    /// Marks all pending steps that depend on a failed step as skipped.
    /// - Parameter failedStepId: The ID of the failed step.
    public mutating func skipDependentSteps(of failedStepId: UUID) {
        for index in steps.indices {
            if steps[index].dependsOn.contains(failedStepId) && steps[index].status == .pending {
                steps[index].status = .skipped
                steps[index].error = "Skipped due to dependency failure"
                // Recursively skip steps that depend on this one
                skipDependentSteps(of: steps[index].id)
            }
        }
    }
}

// MARK: - ExecutionPlan + CustomStringConvertible

extension ExecutionPlan: CustomStringConvertible {
    public var description: String {
        let stepDescriptions = steps.map { "  \($0)" }.joined(separator: "\n")
        return """
        ExecutionPlan(goal: "\(goal)", revision: \(revisionCount))
        Steps:
        \(stepDescriptions)
        """
    }
}

// MARK: - PlanAndExecuteAgent

/// A Plan-and-Execute agent that uses structured planning before execution.
///
/// The Plan-and-Execute paradigm separates planning from execution:
/// 1. **Plan**: Generate a multi-step plan to achieve the goal.
/// 2. **Execute**: Execute each step in order, using tools as needed.
/// 3. **Replan**: If a step fails, generate a revised plan and continue.
///
/// This approach is beneficial for complex tasks that require multiple steps
/// and can benefit from explicit planning and error recovery.
///
/// Example:
/// ```swift
/// let agent = PlanAndExecuteAgent(
///     tools: [WebSearchTool(), CalculatorTool()],
///     instructions: "You are a research assistant."
/// )
///
/// let result = try await agent.run("Find the population of Tokyo and calculate 10% of it")
/// print(result.output)
/// ```
public actor PlanAndExecuteAgent: Agent {
    // MARK: - Agent Protocol Properties

    nonisolated public let tools: [any Tool]
    nonisolated public let instructions: String
    nonisolated public let configuration: AgentConfiguration
    nonisolated public let memory: (any Memory)?
    nonisolated public let inferenceProvider: (any InferenceProvider)?

    // MARK: - Plan-and-Execute Specific Configuration

    /// Maximum number of replan attempts when steps fail.
    nonisolated public let maxReplanAttempts: Int

    // MARK: - Cancellation State

    private enum CancellationState: Sendable {
        case active
        case cancelled
    }

    // MARK: - Internal State

    private var cancellationState: CancellationState = .active
    private let toolRegistry: ToolRegistry

    // MARK: - Initialization

    /// Creates a new PlanAndExecuteAgent.
    /// - Parameters:
    ///   - tools: Tools available to the agent. Default: []
    ///   - instructions: System instructions. Default: ""
    ///   - configuration: Agent configuration. Default: .default
    ///   - memory: Optional memory system. Default: nil
    ///   - inferenceProvider: Optional inference provider. Default: nil
    ///   - maxReplanAttempts: Maximum replan attempts. Default: 3
    public init(
        tools: [any Tool] = [],
        instructions: String = "",
        configuration: AgentConfiguration = .default,
        memory: (any Memory)? = nil,
        inferenceProvider: (any InferenceProvider)? = nil,
        maxReplanAttempts: Int = 3
    ) {
        self.tools = tools
        self.instructions = instructions
        self.configuration = configuration
        self.memory = memory
        self.inferenceProvider = inferenceProvider
        self.maxReplanAttempts = maxReplanAttempts
        toolRegistry = ToolRegistry(tools: tools)
    }

    // MARK: - Agent Protocol Methods

    /// Executes the agent with the given input and returns a result.
    /// - Parameter input: The user's input/query.
    /// - Returns: The result of the agent's execution.
    /// - Throws: `AgentError` if execution fails.
    public func run(_ input: String) async throws -> AgentResult {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AgentError.invalidInput(reason: "Input cannot be empty")
        }

        cancellationState = .active
        let resultBuilder = AgentResult.Builder()
        _ = resultBuilder.start()

        // Store input in memory if available
        if let mem = memory {
            await mem.add(.user(input))
        }

        // Execute the Plan-and-Execute loop
        let output = try await executePlanAndExecuteLoop(
            input: input,
            resultBuilder: resultBuilder
        )

        _ = resultBuilder.setOutput(output)

        // Store output in memory if available
        if let mem = memory {
            await mem.add(.assistant(output))
        }

        return resultBuilder.build()
    }

    /// Streams the agent's execution, yielding events as they occur.
    /// - Parameter input: The user's input/query.
    /// - Returns: An async stream of agent events.
    nonisolated public func stream(_ input: String) -> AsyncThrowingStream<AgentEvent, Error> {
        let (stream, continuation) = AsyncThrowingStream<AgentEvent, Error>.makeStream()
        Task { @Sendable [weak self] in
            guard let self else {
                continuation.finish()
                return
            }
            do {
                continuation.yield(.started(input: input))
                let result = try await run(input)
                continuation.yield(.completed(result: result))
                continuation.finish()
            } catch {
                let agentError = error as? AgentError ?? AgentError.internalError(reason: error.localizedDescription)
                continuation.yield(.failed(error: agentError))
                continuation.finish(throwing: agentError)
            }
        }
        return stream
    }

    /// Cancels any ongoing execution.
    public func cancel() async {
        cancellationState = .cancelled
    }

    // MARK: - Plan-and-Execute Loop

    private func executePlanAndExecuteLoop(
        input: String,
        resultBuilder: AgentResult.Builder
    ) async throws -> String {
        var replanAttempts = 0
        let startTime = ContinuousClock.now

        // Phase 1: Generate initial plan
        var plan = try await generatePlan(for: input)
        _ = resultBuilder.setMetadata("initialPlan", .string(plan.description))

        // Phase 2: Execute steps
        while !plan.isComplete {
            try Task.checkCancellation()
            if cancellationState == .cancelled {
                throw AgentError.cancelled
            }

            // Timeout enforcement
            let elapsed = ContinuousClock.now - startTime
            if elapsed > configuration.timeout {
                Log.agents.warning("Plan execution timed out after \(elapsed)")
                throw AgentError.timeout(duration: configuration.timeout)
            }

            guard let step = plan.nextExecutableStep else {
                // No executable step but plan not complete - something is wrong
                if plan.hasFailed {
                    // Phase 3: Replan if possible
                    if replanAttempts < maxReplanAttempts {
                        replanAttempts += 1
                        _ = resultBuilder.incrementIteration()
                        plan = try await replan(original: plan, input: input)
                        _ = resultBuilder.setMetadata("replan_\(replanAttempts)", .string(plan.description))
                        continue
                    } else {
                        // Max replans exceeded, synthesize answer with partial results
                        break
                    }
                }

                // CRITICAL: Check for deadlock - pending steps with unsatisfiable dependencies
                if !plan.pendingSteps.isEmpty {
                    for index in plan.steps.indices {
                        if plan.steps[index].status == .pending {
                            plan.steps[index].status = .skipped
                            plan.steps[index].error = "Skipped: dependency deadlock or circular dependency detected"
                        }
                    }
                }
                break
            }

            _ = resultBuilder.incrementIteration()

            // Mark step as in progress
            plan.updateStep(id: step.id, status: .inProgress)

            // Execute the step
            do {
                let stepResult = try await executeStep(step, plan: plan, resultBuilder: resultBuilder)
                plan.updateStep(id: step.id, status: .completed, result: stepResult)
            } catch {
                let errorMessage = (error as? AgentError)?.localizedDescription ?? error.localizedDescription

                // Log the failure with context
                Log.agents.error("Step \(step.stepNumber) failed: \(errorMessage)")

                plan.updateStep(id: step.id, status: .failed, error: errorMessage)
                plan.skipDependentSteps(of: step.id)

                if configuration.stopOnToolError {
                    throw error
                }
            }
        }

        // Phase 4: Synthesize final answer
        return try await synthesizeFinalAnswer(plan: plan, input: input)
    }

    // MARK: - Plan Generation

    private func generatePlan(for input: String) async throws -> ExecutionPlan {
        let prompt = buildPlanningPrompt(for: input)
        let response = try await generateResponse(prompt: prompt)
        return parsePlan(from: response, goal: input)
    }

    private func buildPlanningPrompt(for input: String) -> String {
        let toolDescriptions = buildToolDescriptions()

        return """
        \(instructions.isEmpty ? "You are a helpful AI assistant that creates structured plans." : instructions)

        You are a planning agent. Your task is to create a step-by-step plan to accomplish the user's goal.

        \(toolDescriptions.isEmpty ? "No tools are available." : "Available Tools:\n\(toolDescriptions)")

        Create a plan with numbered steps. For each step, provide:
        1. A clear description of what the step accomplishes
        2. If a tool is needed, specify: [TOOL: tool_name] with arguments
        3. If the step depends on previous steps, mention which ones

        Format your response EXACTLY as follows:
        PLAN:
        Step 1: [Description] [TOOL: tool_name(arg1: value1)] [DEPENDS: none]
        Step 2: [Description] [TOOL: tool_name(arg1: value1)] [DEPENDS: Step 1]
        Step 3: [Description] [DEPENDS: Step 1, Step 2]
        END_PLAN

        Rules:
        1. Be specific and actionable in each step.
        2. Only use tools that are available.
        3. Keep the plan concise but complete.
        4. Specify dependencies accurately.

        User Goal: \(input)

        Create your plan:
        """
    }

    private func parsePlan(from response: String, goal: String) -> ExecutionPlan {
        var steps: [PlanStep] = []
        var stepNumberToId: [Int: UUID] = [:]

        // Extract content between PLAN: and END_PLAN
        let planContent: String
        if let planStart = response.range(of: "PLAN:", options: .caseInsensitive),
           let planEnd = response.range(of: "END_PLAN", options: .caseInsensitive) {
            planContent = String(response[planStart.upperBound..<planEnd.lowerBound])
        } else {
            planContent = response
        }

        // Parse each line as a step
        let lines = planContent.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        for line in lines {
            // Match "Step N:" pattern
            guard let stepMatch = line.range(of: #"Step\s+(\d+):"#, options: .regularExpression) else {
                continue
            }

            let stepNumberStr = line[stepMatch]
                .components(separatedBy: CharacterSet.decimalDigits.inverted)
                .joined()
            guard let stepNumber = Int(stepNumberStr) else { continue }

            // Extract description (everything after "Step N:" until [TOOL:] or [DEPENDS:])
            let afterStep = String(line[stepMatch.upperBound...]).trimmingCharacters(in: .whitespaces)
            var description = afterStep
            var toolName: String?
            var toolArguments: [String: SendableValue] = [:]
            var dependsOn: [UUID] = []

            // Parse tool if present
            if let toolStart = afterStep.range(of: "[TOOL:", options: .caseInsensitive) {
                description = String(afterStep[..<toolStart.lowerBound]).trimmingCharacters(in: .whitespaces)

                if let toolEnd = afterStep.range(of: "]", range: toolStart.upperBound..<afterStep.endIndex) {
                    let toolSpec = String(afterStep[toolStart.upperBound..<toolEnd.lowerBound])
                        .trimmingCharacters(in: .whitespaces)

                    // Parse tool_name(arg1: value1, arg2: value2)
                    if let parenStart = toolSpec.firstIndex(of: "("),
                       let parenEnd = toolSpec.lastIndex(of: ")") {
                        toolName = String(toolSpec[..<parenStart]).trimmingCharacters(in: .whitespaces)
                        let argsString = String(toolSpec[toolSpec.index(after: parenStart)..<parenEnd])
                        toolArguments = parseToolArguments(argsString)
                    } else {
                        toolName = toolSpec.trimmingCharacters(in: .whitespaces)
                    }
                }
            }

            // Parse dependencies if present
            if let dependsStart = afterStep.range(of: "[DEPENDS:", options: .caseInsensitive) {
                if let dependsEnd = afterStep.range(of: "]", range: dependsStart.upperBound..<afterStep.endIndex) {
                    let dependsSpec = String(afterStep[dependsStart.upperBound..<dependsEnd.lowerBound])
                        .trimmingCharacters(in: .whitespaces)

                    if dependsSpec.lowercased() != "none" {
                        // Parse "Step 1, Step 2" format
                        let deps = dependsSpec.components(separatedBy: ",")
                            .map { $0.trimmingCharacters(in: .whitespaces) }

                        for dep in deps {
                            let depNumStr = dep.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                            if let depNum = Int(depNumStr), let depId = stepNumberToId[depNum] {
                                dependsOn.append(depId)
                            }
                        }
                    }
                }

                // Remove DEPENDS part from description if it wasn't already removed
                if let dependsStartInDesc = description.range(of: "[DEPENDS:", options: .caseInsensitive) {
                    description = String(description[..<dependsStartInDesc.lowerBound])
                        .trimmingCharacters(in: .whitespaces)
                }
            }

            let stepId = UUID()
            stepNumberToId[stepNumber] = stepId

            let step = PlanStep(
                id: stepId,
                stepNumber: stepNumber,
                stepDescription: description,
                toolName: toolName,
                toolArguments: toolArguments,
                dependsOn: dependsOn
            )
            steps.append(step)
        }

        // If no steps were parsed, create a single generic step
        if steps.isEmpty {
            steps.append(PlanStep(
                stepNumber: 1,
                stepDescription: "Directly answer the user's request without using tools: \(goal)",
                toolName: nil
            ))
        }

        return ExecutionPlan(steps: steps, goal: goal)
    }

    private func parseToolArguments(_ argsString: String) -> [String: SendableValue] {
        var arguments: [String: SendableValue] = [:]
        let pairs = splitArguments(argsString)

        for pair in pairs {
            let parts = pair.components(separatedBy: ":")
            guard parts.count >= 2 else { continue }

            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let valueStr = parts.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
            arguments[key] = parseValue(valueStr)
        }

        return arguments
    }

    // MARK: - Step Execution

    private func executeStep(
        _ step: PlanStep,
        plan: ExecutionPlan,
        resultBuilder: AgentResult.Builder
    ) async throws -> String {
        // If the step has a tool, execute it
        if let toolName = step.toolName {
            let toolCall = ToolCall(
                toolName: toolName,
                arguments: step.toolArguments
            )
            _ = resultBuilder.addToolCall(toolCall)

            let startTime = ContinuousClock.now
            do {
                let toolResult = try await toolRegistry.execute(
                    toolNamed: toolName,
                    arguments: step.toolArguments
                )
                let duration = ContinuousClock.now - startTime

                let result = ToolResult.success(
                    callId: toolCall.id,
                    output: toolResult,
                    duration: duration
                )
                _ = resultBuilder.addToolResult(result)

                return toolResult.description
            } catch {
                let duration = ContinuousClock.now - startTime
                let errorMessage = (error as? AgentError)?.localizedDescription ?? error.localizedDescription

                let result = ToolResult.failure(
                    callId: toolCall.id,
                    error: errorMessage,
                    duration: duration
                )
                _ = resultBuilder.addToolResult(result)

                throw AgentError.toolExecutionFailed(
                    toolName: toolName,
                    underlyingError: errorMessage
                )
            }
        }

        // For steps without tools, use the LLM to execute
        let prompt = buildStepExecutionPrompt(step: step, plan: plan)
        return try await generateResponse(prompt: prompt)
    }

    private func buildStepExecutionPrompt(step: PlanStep, plan: ExecutionPlan) -> String {
        // Gather results from completed dependencies
        var contextFromDeps = ""
        for depId in step.dependsOn {
            if let depStep = plan.steps.first(where: { $0.id == depId }),
               let result = depStep.result {
                contextFromDeps += "Result from Step \(depStep.stepNumber): \(result)\n"
            }
        }

        return """
        \(instructions.isEmpty ? "You are a helpful AI assistant." : instructions)

        You are executing step \(step.stepNumber) of a plan to achieve: \(plan.goal)

        Step description: \(step.stepDescription)

        \(contextFromDeps.isEmpty ? "" : "Context from previous steps:\n\(contextFromDeps)")

        Execute this step and provide the result. Be concise and focused.
        """
    }

    // MARK: - Replanning

    private func replan(original: ExecutionPlan, input: String) async throws -> ExecutionPlan {
        let prompt = buildReplanPrompt(original: original, input: input)
        let response = try await generateResponse(prompt: prompt)
        var newPlan = parsePlan(from: response, goal: input)
        newPlan.revisionCount = original.revisionCount + 1
        return newPlan
    }

    private func buildReplanPrompt(original: ExecutionPlan, input: String) -> String {
        let toolDescriptions = buildToolDescriptions()

        // Summarize what worked and what failed
        var completedSummary = ""
        for step in original.completedSteps {
            completedSummary += "- Step \(step.stepNumber) (completed): \(step.stepDescription)"
            if let result = step.result {
                completedSummary += " -> Result: \(result.prefix(100))"
            }
            completedSummary += "\n"
        }

        var failedSummary = ""
        for step in original.failedSteps {
            failedSummary += "- Step \(step.stepNumber) (failed): \(step.stepDescription)"
            if let error = step.error {
                failedSummary += " -> Error: \(error)"
            }
            failedSummary += "\n"
        }

        return """
        \(instructions.isEmpty ? "You are a helpful AI assistant that creates structured plans." : instructions)

        The previous plan encountered failures and needs revision.

        Original Goal: \(input)

        \(completedSummary.isEmpty ? "No steps completed." : "Completed steps:\n\(completedSummary)")

        \(failedSummary.isEmpty ? "" : "Failed steps:\n\(failedSummary)")

        \(toolDescriptions.isEmpty ? "No tools are available." : "Available Tools:\n\(toolDescriptions)")

        Create a REVISED plan that:
        1. Builds on the successful steps (do not repeat them)
        2. Addresses the failures with alternative approaches
        3. Achieves the original goal

        Format your response EXACTLY as follows:
        PLAN:
        Step 1: [Description] [TOOL: tool_name(arg1: value1)] [DEPENDS: none]
        Step 2: [Description] [DEPENDS: Step 1]
        END_PLAN

        Create your revised plan:
        """
    }

    // MARK: - Final Answer Synthesis

    private func synthesizeFinalAnswer(plan: ExecutionPlan, input: String) async throws -> String {
        // Gather all results
        var results = ""
        for step in plan.steps where step.status == .completed {
            if let result = step.result {
                results += "Step \(step.stepNumber) (\(step.stepDescription)): \(result)\n"
            }
        }

        let prompt = """
        \(instructions.isEmpty ? "You are a helpful AI assistant." : instructions)

        You have completed executing a plan to answer the user's question.

        User Question: \(input)

        Results from execution:
        \(results.isEmpty ? "No results were gathered." : results)

        \(plan.hasFailed ? "Note: Some steps failed during execution. Provide the best answer you can with the available information." : "")

        Synthesize a clear, concise final answer for the user based on the results above.
        """

        return try await generateResponse(prompt: prompt)
    }

    // MARK: - Helper Methods

    private func buildToolDescriptions() -> String {
        var descriptions: [String] = []
        for tool in tools {
            let toolDesc = formatToolDescription(tool)
            descriptions.append(toolDesc)
        }
        return descriptions.joined(separator: "\n\n")
    }

    private func formatToolDescription(_ tool: any Tool) -> String {
        let params = formatParameterDescriptions(tool.parameters)
        if params.isEmpty {
            return "- \(tool.name): \(tool.description)"
        } else {
            return "- \(tool.name): \(tool.description)\n  Parameters:\n\(params)"
        }
    }

    private func formatParameterDescriptions(_ parameters: [ToolParameter]) -> String {
        var lines: [String] = []
        for param in parameters {
            let reqStr = param.isRequired ? "(required)" : "(optional)"
            let line = "    - \(param.name) \(reqStr): \(param.description)"
            lines.append(line)
        }
        return lines.joined(separator: "\n")
    }

    private func generateResponse(prompt: String) async throws -> String {
        if let provider = inferenceProvider {
            let options = InferenceOptions(
                temperature: configuration.temperature,
                maxTokens: configuration.maxTokens
            )
            return try await provider.generate(prompt: prompt, options: options)
        }

        throw AgentError.inferenceProviderUnavailable(
            reason: "No inference provider configured. Please provide an InferenceProvider."
        )
    }

    /// Splits argument string by comma, respecting quotes and nested structures.
    private func splitArguments(_ str: String) -> [String] {
        var result: [String] = []
        var current = ""
        var depth = 0
        var inQuote = false
        var quoteChar: Character = "\""

        for char in str {
            if !inQuote, char == "\"" || char == "'" {
                inQuote = true
                quoteChar = char
                current.append(char)
            } else if inQuote, char == quoteChar {
                inQuote = false
                current.append(char)
            } else if !inQuote, char == "(" || char == "[" || char == "{" {
                depth += 1
                current.append(char)
            } else if !inQuote, char == ")" || char == "]" || char == "}" {
                depth -= 1
                current.append(char)
            } else if !inQuote, depth == 0, char == "," {
                result.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }

        if !current.trimmingCharacters(in: .whitespaces).isEmpty {
            result.append(current.trimmingCharacters(in: .whitespaces))
        }

        return result
    }

    private func parseValue(_ valueStr: String) -> SendableValue {
        let trimmed = valueStr.trimmingCharacters(in: .whitespaces)

        // Null
        if trimmed.lowercased() == "null" || trimmed.lowercased() == "nil" {
            return .null
        }

        // Boolean
        if trimmed.lowercased() == "true" { return .bool(true) }
        if trimmed.lowercased() == "false" { return .bool(false) }

        // Number
        if let intValue = Int(trimmed) { return .int(intValue) }
        if let doubleValue = Double(trimmed) { return .double(doubleValue) }

        // String (remove quotes if present)
        var str = trimmed
        if (str.hasPrefix("\"") && str.hasSuffix("\"")) ||
            (str.hasPrefix("'") && str.hasSuffix("'")) {
            str = String(str.dropFirst().dropLast())
        }
        return .string(str)
    }
}

// MARK: - PlanAndExecuteAgent.Builder

public extension PlanAndExecuteAgent {
    /// Builder for creating PlanAndExecuteAgent instances with a fluent API.
    ///
    /// Example:
    /// ```swift
    /// let agent = PlanAndExecuteAgent.Builder()
    ///     .tools([CalculatorTool(), DateTimeTool()])
    ///     .instructions("You are a research assistant.")
    ///     .maxReplanAttempts(5)
    ///     .build()
    /// ```
    final class Builder: @unchecked Sendable {
        // MARK: Public

        /// Creates a new builder.
        public init() {}

        /// Sets the tools.
        /// - Parameter tools: The tools to use.
        /// - Returns: Self for chaining.
        @discardableResult
        public func tools(_ tools: [any Tool]) -> Builder {
            self.tools = tools
            return self
        }

        /// Adds a tool.
        /// - Parameter tool: The tool to add.
        /// - Returns: Self for chaining.
        @discardableResult
        public func addTool(_ tool: any Tool) -> Builder {
            tools.append(tool)
            return self
        }

        /// Adds built-in tools.
        /// - Returns: Self for chaining.
        @discardableResult
        public func withBuiltInTools() -> Builder {
            tools.append(contentsOf: BuiltInTools.all)
            return self
        }

        /// Sets the instructions.
        /// - Parameter instructions: The system instructions.
        /// - Returns: Self for chaining.
        @discardableResult
        public func instructions(_ instructions: String) -> Builder {
            self.instructions = instructions
            return self
        }

        /// Sets the configuration.
        /// - Parameter configuration: The agent configuration.
        /// - Returns: Self for chaining.
        @discardableResult
        public func configuration(_ configuration: AgentConfiguration) -> Builder {
            self.configuration = configuration
            return self
        }

        /// Sets the memory system.
        /// - Parameter memory: The memory to use.
        /// - Returns: Self for chaining.
        @discardableResult
        public func memory(_ memory: any Memory) -> Builder {
            self.memory = memory
            return self
        }

        /// Sets the inference provider.
        /// - Parameter provider: The provider to use.
        /// - Returns: Self for chaining.
        @discardableResult
        public func inferenceProvider(_ provider: any InferenceProvider) -> Builder {
            inferenceProvider = provider
            return self
        }

        /// Sets the maximum number of replan attempts.
        /// - Parameter attempts: The maximum replan attempts.
        /// - Returns: Self for chaining.
        @discardableResult
        public func maxReplanAttempts(_ attempts: Int) -> Builder {
            maxReplanAttempts = attempts
            return self
        }

        /// Builds the agent.
        /// - Returns: A new PlanAndExecuteAgent instance.
        public func build() -> PlanAndExecuteAgent {
            PlanAndExecuteAgent(
                tools: tools,
                instructions: instructions,
                configuration: configuration,
                memory: memory,
                inferenceProvider: inferenceProvider,
                maxReplanAttempts: maxReplanAttempts
            )
        }

        // MARK: Private

        private var tools: [any Tool] = []
        private var instructions: String = ""
        private var configuration: AgentConfiguration = .default
        private var memory: (any Memory)?
        private var inferenceProvider: (any InferenceProvider)?
        private var maxReplanAttempts: Int = 3
    }
}
