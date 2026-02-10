// RegexConditionTests.swift
// SwarmTests
//
// Tests for Swift Regex conditions and variadic combinators on RouteCondition.

import Foundation
@testable import Swarm
import Testing

// MARK: - Regex Condition Tests

@Suite("RouteCondition - Swift Regex Conditions")
struct RegexConditionTests {
    // MARK: - matching()

    @Test("matching() returns true when regex matches input")
    func matchingMatchesInput() async {
        let condition = RouteCondition.matching(/\d{3}-\d{4}/)

        #expect(await condition.matches(input: "Call 555-1234 now", context: nil))
    }

    @Test("matching() returns false when regex does not match input")
    func matchingDoesNotMatchInput() async {
        let condition = RouteCondition.matching(/\d{3}-\d{4}/)

        #expect(await !condition.matches(input: "No phone number here", context: nil))
    }

    @Test("matching() works with complex regex patterns")
    func matchingComplexPattern() async {
        let condition = RouteCondition.matching(/[A-Z]{2,3}-\d+/)

        #expect(await condition.matches(input: "Ticket AB-123 assigned", context: nil))
        #expect(await condition.matches(input: "Issue XYZ-9999", context: nil))
        #expect(await !condition.matches(input: "No ticket reference", context: nil))
    }

    @Test("matching() with case-insensitive regex")
    func matchingCaseInsensitive() async {
        let condition = RouteCondition.matching(/hello/
            .ignoresCase())

        #expect(await condition.matches(input: "HELLO world", context: nil))
        #expect(await condition.matches(input: "Hello World", context: nil))
    }

    // MARK: - extracting()

    @Test("extracting() sets context key on match")
    func extractingSetsContextKey() async {
        let condition = RouteCondition.extracting(/\d{3}-\d{4}/)
        let context = AgentContext(input: "Call 555-1234")

        let result = await condition.matches(input: "Call 555-1234", context: context)

        #expect(result)
        let stored = await context.get("regex_match")
        #expect(stored != nil)
    }

    @Test("extracting() uses custom context key")
    func extractingCustomKey() async {
        let condition = RouteCondition.extracting(/\d{3}-\d{4}/, into: "phone_number")
        let context = AgentContext(input: "Call 555-1234")

        let result = await condition.matches(input: "Call 555-1234", context: context)

        #expect(result)
        let stored = await context.get("phone_number")
        #expect(stored != nil)
    }

    @Test("extracting() returns false on non-match")
    func extractingReturnsFalseOnNonMatch() async {
        let condition = RouteCondition.extracting(/\d{3}-\d{4}/)
        let context = AgentContext(input: "No match")

        let result = await condition.matches(input: "No match here", context: context)

        #expect(!result)
        let stored = await context.get("regex_match")
        #expect(stored == nil)
    }

    @Test("extracting() works without context (nil context)")
    func extractingNilContext() async {
        let condition = RouteCondition.extracting(/\d{3}-\d{4}/)

        let result = await condition.matches(input: "Call 555-1234", context: nil)

        #expect(result)
    }
}

// MARK: - Variadic Combinator Tests

@Suite("RouteCondition - Variadic Combinators")
struct VariadicCombinatorTests {
    // MARK: - all()

    @Test("all() requires all conditions to match")
    func allRequiresAllMatch() async {
        let condition = RouteCondition.all(
            .contains("weather"),
            .lengthInRange(10...100),
            .endsWith("?")
        )

        #expect(await condition.matches(input: "What is the weather today?", context: nil))
    }

    @Test("all() fails if any condition fails")
    func allFailsIfAnyFails() async {
        let condition = RouteCondition.all(
            .contains("weather"),
            .contains("nonexistent"),
            .endsWith("?")
        )

        #expect(await !condition.matches(input: "What is the weather?", context: nil))
    }

    @Test("all() with single condition behaves like the condition itself")
    func allSingleCondition() async {
        let condition = RouteCondition.all(
            .contains("hello")
        )

        #expect(await condition.matches(input: "hello world", context: nil))
        #expect(await !condition.matches(input: "goodbye", context: nil))
    }

    @Test("all() short-circuits on first failure")
    func allShortCircuits() async {
        // .never should prevent subsequent conditions from being evaluated
        // We verify behavior by ensuring the result is false
        let condition = RouteCondition.all(
            .never,
            .always,
            .always
        )

        #expect(await !condition.matches(input: "test", context: nil))
    }

    // MARK: - any()

    @Test("any() matches if any condition matches")
    func anyMatchesIfAnyMatches() async {
        let condition = RouteCondition.any(
            .contains("weather"),
            .contains("forecast"),
            .contains("temperature")
        )

        #expect(await condition.matches(input: "Check the forecast", context: nil))
    }

    @Test("any() returns false if none match")
    func anyReturnsFalseIfNoneMatch() async {
        let condition = RouteCondition.any(
            .contains("weather"),
            .contains("forecast")
        )

        #expect(await !condition.matches(input: "Hello world", context: nil))
    }

    @Test("any() with single condition behaves like the condition itself")
    func anySingleCondition() async {
        let condition = RouteCondition.any(
            .contains("hello")
        )

        #expect(await condition.matches(input: "hello world", context: nil))
        #expect(await !condition.matches(input: "goodbye", context: nil))
    }

    @Test("any() short-circuits on first match")
    func anyShortCircuits() async {
        let condition = RouteCondition.any(
            .always,
            .never,
            .never
        )

        #expect(await condition.matches(input: "test", context: nil))
    }

    // MARK: - exactly()

    @Test("exactly() matches when exactly N conditions match")
    func exactlyMatchesExactCount() async {
        let condition = RouteCondition.exactly(2, of:
            .contains("hello"),
            .contains("world"),
            .contains("missing")
        )

        #expect(await condition.matches(input: "hello world", context: nil))
    }

    @Test("exactly() fails when fewer than N conditions match")
    func exactlyFailsWhenFewer() async {
        let condition = RouteCondition.exactly(2, of:
            .contains("hello"),
            .contains("missing1"),
            .contains("missing2")
        )

        #expect(await !condition.matches(input: "hello world", context: nil))
    }

    @Test("exactly() fails when more than N conditions match")
    func exactlyFailsWhenMore() async {
        let condition = RouteCondition.exactly(1, of:
            .contains("hello"),
            .contains("world"),
            .contains("missing")
        )

        #expect(await !condition.matches(input: "hello world", context: nil))
    }

    @Test("exactly(0) matches when no conditions match")
    func exactlyZeroMatches() async {
        let condition = RouteCondition.exactly(0, of:
            .contains("foo"),
            .contains("bar")
        )

        #expect(await condition.matches(input: "hello world", context: nil))
    }

    // MARK: - Composition with existing combinators

    @Test("Variadic all() composes with existing .and()")
    func allComposesWithAnd() async {
        let variadicPart = RouteCondition.all(
            .contains("weather"),
            .endsWith("?")
        )
        let combined = variadicPart.and(.lengthInRange(10...100))

        #expect(await combined.matches(input: "What is the weather?", context: nil))
        #expect(await !combined.matches(input: "weather?", context: nil)) // too short
    }

    @Test("Variadic any() composes with existing .or()")
    func anyComposesWithOr() async {
        let variadicPart = RouteCondition.any(
            .contains("weather"),
            .contains("forecast")
        )
        let combined = variadicPart.or(.contains("temperature"))

        #expect(await combined.matches(input: "Check temperature", context: nil))
        #expect(await combined.matches(input: "Check forecast", context: nil))
        #expect(await !combined.matches(input: "Hello world", context: nil))
    }

    @Test("Regex matching composes with variadic all()")
    func regexComposesWithAll() async {
        let condition = RouteCondition.all(
            .matching(/\d+/),
            .contains("order"),
            .lengthInRange(5...100)
        )

        #expect(await condition.matches(input: "Process order 12345", context: nil))
        #expect(await !condition.matches(input: "Process order now", context: nil)) // no digits
    }
}
