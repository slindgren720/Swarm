// RoutingStrategyTests.swift
// SwiftAgentsTests
//
// Comprehensive tests for routing strategies from SupervisorAgent

import Testing
import Foundation
@testable import SwiftAgents

// MARK: - AgentDescription Tests

@Suite("AgentDescription Tests")
struct AgentDescriptionTests {
    
    @Test("Initialization with all parameters")
    func initializationWithAllParameters() {
        let description = AgentDescription(
            name: "calculator",
            description: "Performs mathematical calculations",
            capabilities: ["arithmetic", "algebra", "trigonometry"],
            keywords: ["calculate", "math", "compute", "sum", "multiply"]
        )
        
        #expect(description.name == "calculator")
        #expect(description.description == "Performs mathematical calculations")
        #expect(description.capabilities == ["arithmetic", "algebra", "trigonometry"])
        #expect(description.keywords == ["calculate", "math", "compute", "sum", "multiply"])
    }
    
    @Test("Initialization with default empty arrays")
    func initializationWithDefaults() {
        let description = AgentDescription(
            name: "simple_agent",
            description: "A simple test agent"
        )
        
        #expect(description.name == "simple_agent")
        #expect(description.description == "A simple test agent")
        #expect(description.capabilities.isEmpty)
        #expect(description.keywords.isEmpty)
    }
    
    @Test("Equatable conformance - equal instances")
    func equatableConformanceEqual() {
        let desc1 = AgentDescription(
            name: "weather",
            description: "Provides weather information",
            capabilities: ["forecast", "current"],
            keywords: ["weather", "temperature"]
        )
        
        let desc2 = AgentDescription(
            name: "weather",
            description: "Provides weather information",
            capabilities: ["forecast", "current"],
            keywords: ["weather", "temperature"]
        )
        
        #expect(desc1 == desc2)
    }
    
    @Test("Equatable conformance - different names")
    func equatableConformanceDifferentNames() {
        let desc1 = AgentDescription(name: "agent1", description: "First")
        let desc2 = AgentDescription(name: "agent2", description: "First")
        
        #expect(desc1 != desc2)
    }
    
    @Test("Equatable conformance - different descriptions")
    func equatableConformanceDifferentDescriptions() {
        let desc1 = AgentDescription(name: "agent", description: "First description")
        let desc2 = AgentDescription(name: "agent", description: "Second description")
        
        #expect(desc1 != desc2)
    }
    
    @Test("Equatable conformance - different capabilities")
    func equatableConformanceDifferentCapabilities() {
        let desc1 = AgentDescription(
            name: "agent",
            description: "Test",
            capabilities: ["one", "two"]
        )
        let desc2 = AgentDescription(
            name: "agent",
            description: "Test",
            capabilities: ["one", "three"]
        )
        
        #expect(desc1 != desc2)
    }
    
    @Test("Equatable conformance - different keywords")
    func equatableConformanceDifferentKeywords() {
        let desc1 = AgentDescription(
            name: "agent",
            description: "Test",
            keywords: ["keyword1"]
        )
        let desc2 = AgentDescription(
            name: "agent",
            description: "Test",
            keywords: ["keyword2"]
        )
        
        #expect(desc1 != desc2)
    }
}

// MARK: - RoutingDecision Tests

@Suite("RoutingDecision Tests")
struct RoutingDecisionTests {
    
    @Test("Initialization with all parameters")
    func initializationWithAllParameters() {
        let decision = RoutingDecision(
            selectedAgentName: "weather_agent",
            confidence: 0.95,
            reasoning: "Input requests weather information"
        )
        
        #expect(decision.selectedAgentName == "weather_agent")
        #expect(decision.confidence == 0.95)
        #expect(decision.reasoning == "Input requests weather information")
    }
    
    @Test("Initialization with defaults")
    func initializationWithDefaults() {
        let decision = RoutingDecision(selectedAgentName: "agent")
        
        #expect(decision.selectedAgentName == "agent")
        #expect(decision.confidence == 1.0)
        #expect(decision.reasoning == nil)
    }
    
    @Test("Confidence clamping - value below zero")
    func confidenceClampingBelowZero() {
        let decision = RoutingDecision(
            selectedAgentName: "agent",
            confidence: -0.5
        )
        
        #expect(decision.confidence == 0.0)
    }
    
    @Test("Confidence clamping - value above one")
    func confidenceClampingAboveOne() {
        let decision = RoutingDecision(
            selectedAgentName: "agent",
            confidence: 1.5
        )
        
        #expect(decision.confidence == 1.0)
    }
    
    @Test("Confidence clamping - extreme negative value")
    func confidenceClampingExtremeNegative() {
        let decision = RoutingDecision(
            selectedAgentName: "agent",
            confidence: -1000.0
        )
        
        #expect(decision.confidence == 0.0)
    }
    
    @Test("Confidence clamping - extreme positive value")
    func confidenceClampingExtremePositive() {
        let decision = RoutingDecision(
            selectedAgentName: "agent",
            confidence: 1000.0
        )
        
        #expect(decision.confidence == 1.0)
    }
    
    @Test("Confidence clamping - valid range values")
    func confidenceClampingValidRange() {
        let decision1 = RoutingDecision(selectedAgentName: "agent", confidence: 0.0)
        let decision2 = RoutingDecision(selectedAgentName: "agent", confidence: 0.5)
        let decision3 = RoutingDecision(selectedAgentName: "agent", confidence: 1.0)
        
        #expect(decision1.confidence == 0.0)
        #expect(decision2.confidence == 0.5)
        #expect(decision3.confidence == 1.0)
    }
    
    @Test("Equatable conformance - equal instances")
    func equatableConformanceEqual() {
        let decision1 = RoutingDecision(
            selectedAgentName: "agent",
            confidence: 0.8,
            reasoning: "test"
        )
        let decision2 = RoutingDecision(
            selectedAgentName: "agent",
            confidence: 0.8,
            reasoning: "test"
        )
        
        #expect(decision1 == decision2)
    }
    
    @Test("Equatable conformance - different agent names")
    func equatableConformanceDifferentNames() {
        let decision1 = RoutingDecision(selectedAgentName: "agent1")
        let decision2 = RoutingDecision(selectedAgentName: "agent2")
        
        #expect(decision1 != decision2)
    }
    
    @Test("Equatable conformance - different confidence")
    func equatableConformanceDifferentConfidence() {
        let decision1 = RoutingDecision(selectedAgentName: "agent", confidence: 0.5)
        let decision2 = RoutingDecision(selectedAgentName: "agent", confidence: 0.8)
        
        #expect(decision1 != decision2)
    }
    
    @Test("Equatable conformance - different reasoning")
    func equatableConformanceDifferentReasoning() {
        let decision1 = RoutingDecision(
            selectedAgentName: "agent",
            reasoning: "reason1"
        )
        let decision2 = RoutingDecision(
            selectedAgentName: "agent",
            reasoning: "reason2"
        )
        
        #expect(decision1 != decision2)
    }
    
    @Test("CustomStringConvertible conformance")
    func customStringConformable() {
        let decision = RoutingDecision(
            selectedAgentName: "test_agent",
            confidence: 0.95,
            reasoning: "matched keywords"
        )
        
        let description = decision.description
        #expect(description.contains("test_agent"))
        #expect(description.contains("0.95"))
        #expect(description.contains("matched keywords"))
    }
}

// MARK: - KeywordRoutingStrategy Tests

@Suite("KeywordRoutingStrategy Tests")
struct KeywordRoutingStrategyTests {
    
    // MARK: - Helper Methods
    
    /// Creates test agent descriptions
    func createTestAgents() -> [AgentDescription] {
        [
            AgentDescription(
                name: "calculator",
                description: "Performs mathematical calculations",
                capabilities: ["arithmetic", "algebra"],
                keywords: ["calculate", "math", "compute", "sum"]
            ),
            AgentDescription(
                name: "weather",
                description: "Provides weather information",
                capabilities: ["forecast", "current"],
                keywords: ["weather", "temperature", "forecast", "rain"]
            ),
            AgentDescription(
                name: "search",
                description: "Searches the web",
                capabilities: ["web_search", "news"],
                keywords: ["search", "find", "look up", "google"]
            )
        ]
    }
    
    // MARK: - Initialization Tests
    
    @Test("Default initialization")
    func testDefaultInitialization() {
        let strategy = KeywordRoutingStrategy()
        
        #expect(strategy.caseSensitive == false)
        #expect(strategy.minimumConfidence == 0.1)
    }
    
    @Test("Custom initialization")
    func testCustomInitialization() {
        let strategy = KeywordRoutingStrategy(
            caseSensitive: true,
            minimumConfidence: 0.5
        )
        
        #expect(strategy.caseSensitive == true)
        #expect(strategy.minimumConfidence == 0.5)
    }
    
    // MARK: - Keyword Matching Tests
    
    @Test("Matches by keyword - highest priority")
    func testMatchesByKeyword() async throws {
        let strategy = KeywordRoutingStrategy()
        let agents = createTestAgents()
        
        let decision = try await strategy.selectAgent(
            for: "What's the weather like today?",
            from: agents,
            context: nil
        )
        
        #expect(decision.selectedAgentName == "weather")
        #expect(decision.confidence > 0.0)
        #expect(decision.reasoning?.contains("score") == true)
    }
    
    @Test("Matches by multiple keywords increases score")
    func testMatchesByMultipleKeywords() async throws {
        let strategy = KeywordRoutingStrategy()
        let agents = createTestAgents()
        
        // "weather" and "forecast" are both keywords for weather agent
        let decision = try await strategy.selectAgent(
            for: "Give me the weather forecast",
            from: agents,
            context: nil
        )
        
        #expect(decision.selectedAgentName == "weather")
        #expect(decision.confidence > 0.0)
    }
    
    @Test("Matches by capability - medium priority")
    func testMatchesByCapability() async throws {
        let strategy = KeywordRoutingStrategy()
        let agents = createTestAgents()
        
        // "arithmetic" is a capability, not a keyword
        let decision = try await strategy.selectAgent(
            for: "I need arithmetic help",
            from: agents,
            context: nil
        )
        
        #expect(decision.selectedAgentName == "calculator")
    }
    
    @Test("Matches by agent name - lowest priority")
    func testMatchesByAgentName() async throws {
        let strategy = KeywordRoutingStrategy()
        let agents = createTestAgents()
        
        // "calculator" is the agent name
        let decision = try await strategy.selectAgent(
            for: "Use the calculator for this",
            from: agents,
            context: nil
        )
        
        #expect(decision.selectedAgentName == "calculator")
    }
    
    // MARK: - Case Sensitivity Tests
    
    @Test("Case insensitive matching by default")
    func testCaseInsensitiveMatching() async throws {
        let strategy = KeywordRoutingStrategy(caseSensitive: false)
        let agents = createTestAgents()
        
        // Keywords are lowercase, but input is uppercase
        let decision = try await strategy.selectAgent(
            for: "WEATHER FORECAST",
            from: agents,
            context: nil
        )
        
        #expect(decision.selectedAgentName == "weather")
    }
    
    @Test("Case sensitive matching when enabled")
    func testCaseSensitiveMatching() async throws {
        let strategy = KeywordRoutingStrategy(caseSensitive: true)
        let agents = [
            AgentDescription(
                name: "agent1",
                description: "Test",
                keywords: ["URGENT"]
            ),
            AgentDescription(
                name: "agent2",
                description: "Test",
                keywords: ["urgent"]
            )
        ]
        
        let decision = try await strategy.selectAgent(
            for: "This is URGENT",
            from: agents,
            context: nil
        )
        
        #expect(decision.selectedAgentName == "agent1")
    }
    
    // MARK: - Confidence Threshold Tests
    
    @Test("Minimum confidence threshold respected")
    func testMinimumConfidenceThreshold() async throws {
        let strategy = KeywordRoutingStrategy(minimumConfidence: 0.9)
        let agents = createTestAgents()
        
        // Weak match should fall below threshold
        let decision = try await strategy.selectAgent(
            for: "calculator",  // Only name match, low score
            from: agents,
            context: nil
        )
        
        // Should fallback to first agent with 0 confidence
        #expect(decision.confidence == 0.0)
        #expect(decision.reasoning?.contains("fallback") == true)
    }
    
    @Test("Returns nil when no match meets threshold")
    func testNoMatchMeetsThreshold() async throws {
        let strategy = KeywordRoutingStrategy(minimumConfidence: 1.0)
        let agents = createTestAgents()
        
        // No perfect match possible
        let decision = try await strategy.selectAgent(
            for: "unrelated query",
            from: agents,
            context: nil
        )
        
        // Falls back to first agent with 0 confidence
        #expect(decision.confidence == 0.0)
        #expect(decision.selectedAgentName == agents[0].name)
    }
    
    // MARK: - Scoring Algorithm Tests
    
    @Test("Scoring algorithm verification - keyword worth 10 points")
    func testScoringAlgorithmKeyword() async throws {
        let strategy = KeywordRoutingStrategy()
        
        let agents = [
            AgentDescription(
                name: "agent1",
                description: "Test",
                capabilities: [],
                keywords: ["unique_keyword"]
            ),
            AgentDescription(
                name: "agent2",
                description: "Test",
                capabilities: [],
                keywords: []
            )
        ]
        
        let decision = try await strategy.selectAgent(
            for: "unique_keyword",
            from: agents,
            context: nil
        )
        
        #expect(decision.selectedAgentName == "agent1")
        #expect(decision.reasoning?.contains("10") == true) // 10 points for keyword
    }
    
    @Test("Scoring algorithm verification - capability worth 5 points")
    func testScoringAlgorithmCapability() async throws {
        let strategy = KeywordRoutingStrategy()
        
        let agents = [
            AgentDescription(
                name: "agent1",
                description: "Test",
                capabilities: ["unique_capability"],
                keywords: []
            ),
            AgentDescription(
                name: "agent2",
                description: "Test",
                capabilities: [],
                keywords: []
            )
        ]
        
        let decision = try await strategy.selectAgent(
            for: "unique_capability",
            from: agents,
            context: nil
        )
        
        #expect(decision.selectedAgentName == "agent1")
        #expect(decision.reasoning?.contains("5") == true) // 5 points for capability
    }
    
    @Test("Scoring algorithm verification - name worth 3 points")
    func testScoringAlgorithmName() async throws {
        let strategy = KeywordRoutingStrategy()
        
        let agents = [
            AgentDescription(
                name: "unique_agent",
                description: "Test",
                capabilities: [],
                keywords: []
            ),
            AgentDescription(
                name: "other_agent",
                description: "Test",
                capabilities: [],
                keywords: []
            )
        ]
        
        let decision = try await strategy.selectAgent(
            for: "unique_agent",
            from: agents,
            context: nil
        )
        
        #expect(decision.selectedAgentName == "unique_agent")
        #expect(decision.reasoning?.contains("3") == true) // 3 points for name
    }
    
    @Test("Scoring algorithm - keywords score higher than capabilities")
    func testScoringKeywordScoreHigher() async throws {
        let strategy = KeywordRoutingStrategy()
        
        let agents = [
            AgentDescription(
                name: "agent1",
                description: "Test",
                capabilities: ["match"],  // 5 points
                keywords: []
            ),
            AgentDescription(
                name: "agent2",
                description: "Test",
                capabilities: [],
                keywords: ["match"]  // 10 points - keywords score higher
            )
        ]
        
        let decision = try await strategy.selectAgent(
            for: "match",
            from: agents,
            context: nil
        )
        
        // Keywords score 10 points, capabilities only 5
        #expect(decision.selectedAgentName == "agent2")
    }
    
    // MARK: - Multiple Matching Agents Tests
    
    @Test("Multiple matching agents - picks highest score")
    func testMultipleMatchingAgentsPicksHighest() async throws {
        let strategy = KeywordRoutingStrategy()
        
        let agents = [
            AgentDescription(
                name: "agent1",
                description: "Test",
                capabilities: [],
                keywords: ["test"]  // 10 points
            ),
            AgentDescription(
                name: "agent2",
                description: "Test",
                capabilities: [],
                keywords: ["test", "example"]  // 20 points for "test example"
            ),
            AgentDescription(
                name: "agent3",
                description: "Test",
                capabilities: ["test"],  // 5 points
                keywords: []
            )
        ]
        
        let decision = try await strategy.selectAgent(
            for: "test example query",
            from: agents,
            context: nil
        )
        
        #expect(decision.selectedAgentName == "agent2")
    }
    
    // MARK: - Edge Cases
    
    @Test("Empty agents array throws error")
    func testEmptyAgentsArrayThrows() async throws {
        let strategy = KeywordRoutingStrategy()
        
        await #expect(throws: AgentError.self) {
            _ = try await strategy.selectAgent(
                for: "test query",
                from: [],
                context: nil
            )
        }
    }
    
    @Test("Single agent always selected")
    func testSingleAgentAlwaysSelected() async throws {
        let strategy = KeywordRoutingStrategy()
        
        let agents = [
            AgentDescription(
                name: "only_agent",
                description: "The only agent",
                capabilities: [],
                keywords: []
            )
        ]
        
        let decision = try await strategy.selectAgent(
            for: "any query at all",
            from: agents,
            context: nil
        )
        
        #expect(decision.selectedAgentName == "only_agent")
        #expect(decision.confidence == 1.0)
        #expect(decision.reasoning == "Only one agent available")
    }
    
    @Test("No keyword matches uses fallback")
    func testNoKeywordMatchesUsesFallback() async throws {
        let strategy = KeywordRoutingStrategy()
        let agents = createTestAgents()
        
        let decision = try await strategy.selectAgent(
            for: "xyz abc def completely unrelated",
            from: agents,
            context: nil
        )
        
        // Should fallback to first agent
        #expect(decision.selectedAgentName == agents[0].name)
        #expect(decision.confidence == 0.0)
        #expect(decision.reasoning?.contains("No keyword matches") == true)
    }
    
    @Test("Empty input string")
    func testEmptyInputString() async throws {
        let strategy = KeywordRoutingStrategy()
        let agents = createTestAgents()
        
        let decision = try await strategy.selectAgent(
            for: "",
            from: agents,
            context: nil
        )
        
        // Should fallback to first agent
        #expect(decision.selectedAgentName == agents[0].name)
        #expect(decision.confidence == 0.0)
    }
    
    @Test("Whitespace-only input")
    func testWhitespaceOnlyInput() async throws {
        let strategy = KeywordRoutingStrategy()
        let agents = createTestAgents()
        
        let decision = try await strategy.selectAgent(
            for: "   \n\t  ",
            from: agents,
            context: nil
        )
        
        // Should fallback to first agent
        #expect(decision.selectedAgentName == agents[0].name)
        #expect(decision.confidence == 0.0)
    }
    
    @Test("Partial keyword matches")
    func testPartialKeywordMatches() async throws {
        let strategy = KeywordRoutingStrategy()
        let agents = createTestAgents()
        
        // "calculating" contains "calculate"
        let decision = try await strategy.selectAgent(
            for: "I am calculating something",
            from: agents,
            context: nil
        )
        
        #expect(decision.selectedAgentName == "calculator")
    }
    
    @Test("Confidence calculation with maximum score")
    func testConfidenceCalculationMaxScore() async throws {
        let strategy = KeywordRoutingStrategy()
        
        let agents = [
            AgentDescription(
                name: "perfect_match",
                description: "Test",
                capabilities: ["cap1", "cap2"],
                keywords: ["key1", "key2"]
            )
        ]
        
        // Match all keywords, all capabilities, and name
        let decision = try await strategy.selectAgent(
            for: "perfect_match key1 key2 cap1 cap2",
            from: agents,
            context: nil
        )
        
        #expect(decision.selectedAgentName == "perfect_match")
        // Max score = 2*10 (keywords) + 2*5 (capabilities) + 3 (name) = 33
        // Confidence should be close to 1.0
        #expect(decision.confidence > 0.9)
    }
    
    // MARK: - Context Parameter Tests
    
    @Test("Context parameter is optional and unused")
    func testContextParameterUnused() async throws {
        let strategy = KeywordRoutingStrategy()
        let agents = createTestAgents()
        
        // Context is passed but currently unused by KeywordRoutingStrategy
        let decision = try await strategy.selectAgent(
            for: "weather forecast",
            from: agents,
            context: nil
        )
        
        #expect(decision.selectedAgentName == "weather")
    }
}

// MARK: - RoutingStrategy Protocol Tests

@Suite("RoutingStrategy Protocol Tests")
struct RoutingStrategyProtocolTests {
    
    @Test("KeywordRoutingStrategy conforms to RoutingStrategy")
    func testKeywordStrategyConformsToProtocol() {
        let strategy: any RoutingStrategy = KeywordRoutingStrategy()
        
        #expect(strategy is KeywordRoutingStrategy)
    }
    
    @Test("RoutingStrategy is Sendable")
    func testRoutingStrategyIsSendable() async throws {
        let strategy = KeywordRoutingStrategy()
        
        // Can be captured in async context
        let task = Task {
            let agents = [
                AgentDescription(name: "test", description: "Test agent")
            ]
            return try await strategy.selectAgent(
                for: "test",
                from: agents,
                context: nil
            )
        }
        
        let decision = try await task.value
        #expect(decision.selectedAgentName == "test")
    }
}
