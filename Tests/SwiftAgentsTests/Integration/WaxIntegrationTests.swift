// WaxIntegrationTests.swift
// SwiftAgentsTests
//
// Tests for Wax integration being available as a core dependency.

@testable import SwiftAgents
import Testing

@Suite("Wax Integration Tests")
struct WaxIntegrationTests {
    @Test("Wax integration is enabled by default")
    func waxIntegrationIsEnabled() {
        let integration = WaxIntegration()

        #expect(integration.isEnabled == true)
        #expect(WaxIntegration.debugDescription == "Wax integration is enabled")
    }
}
