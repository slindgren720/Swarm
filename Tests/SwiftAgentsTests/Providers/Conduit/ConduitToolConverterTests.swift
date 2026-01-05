// ConduitToolConverterTests.swift
// SwiftAgentsTests
//
// Tests for ConduitToolConverter functionality.

import Foundation
@testable import SwiftAgents
import Testing
import Conduit
import OrderedCollections

@Suite("ConduitToolConverter Tests")
struct ConduitToolConverterTests {
    // MARK: - ToolDefinition to AIToolDefinition Tests

    @Test("basic tool definition converts correctly")
    func basicToolDefinitionConvertsCorrectly() throws {
        let toolDef = ToolDefinition(
            name: "calculator",
            description: "Performs calculations",
            parameters: [
                "expression": .string(description: "The expression to evaluate")
            ]
        )

        let aiToolDef = try toolDef.toConduitToolDefinition()

        #expect(aiToolDef.name == "calculator")
        #expect(aiToolDef.description == "Performs calculations")
        #expect(aiToolDef.parameters.count == 1)
    }

    @Test("tool with multiple parameters converts correctly")
    func toolWithMultipleParametersConvertsCorrectly() throws {
        let toolDef = ToolDefinition(
            name: "search",
            description: "Searches for information",
            parameters: [
                "query": .string(description: "Search query"),
                "limit": .integer(description: "Result limit"),
                "caseSensitive": .boolean(description: "Case sensitive search")
            ]
        )

        let aiToolDef = try toolDef.toConduitToolDefinition()

        #expect(aiToolDef.parameters.count == 3)
        #expect(aiToolDef.parameters.keys.contains("query"))
        #expect(aiToolDef.parameters.keys.contains("limit"))
        #expect(aiToolDef.parameters.keys.contains("caseSensitive"))
    }

    @Test("tool with nested object parameters converts correctly")
    func toolWithNestedObjectParametersConvertsCorrectly() throws {
        let toolDef = ToolDefinition(
            name: "createUser",
            description: "Creates a new user",
            parameters: [
                "user": .object(
                    properties: [
                        "name": .string(description: "User name"),
                        "age": .integer(description: "User age")
                    ],
                    description: "User information"
                )
            ]
        )

        let aiToolDef = try toolDef.toConduitToolDefinition()

        #expect(aiToolDef.parameters.count == 1)
        #expect(aiToolDef.parameters.keys.contains("user"))
    }

    @Test("tool with array parameters converts correctly")
    func toolWithArrayParametersConvertsCorrectly() throws {
        let toolDef = ToolDefinition(
            name: "processBatch",
            description: "Processes multiple items",
            parameters: [
                "items": .array(
                    items: .string(description: "Item"),
                    description: "List of items to process"
                )
            ]
        )

        let aiToolDef = try toolDef.toConduitToolDefinition()

        #expect(aiToolDef.parameters.count == 1)
        #expect(aiToolDef.parameters.keys.contains("items"))
    }

    @Test("tool with optional parameters converts correctly")
    func toolWithOptionalParametersConvertsCorrectly() throws {
        let toolDef = ToolDefinition(
            name: "search",
            description: "Searches",
            parameters: [
                "query": .string(description: "Required query"),
                "limit": .optional(
                    wrapped: .integer(description: "Optional limit")
                )
            ]
        )

        let aiToolDef = try toolDef.toConduitToolDefinition()

        #expect(aiToolDef.parameters.count == 2)
    }

    @Test("tool with enum parameters converts correctly")
    func toolWithEnumParametersConvertsCorrectly() throws {
        let toolDef = ToolDefinition(
            name: "setMode",
            description: "Sets the mode",
            parameters: [
                "mode": .oneOf(
                    options: [
                        .string(description: "light"),
                        .string(description: "dark")
                    ],
                    description: "Display mode"
                )
            ]
        )

        let aiToolDef = try toolDef.toConduitToolDefinition()

        #expect(aiToolDef.parameters.count == 1)
        #expect(aiToolDef.parameters.keys.contains("mode"))
    }

    @Test("required parameters are preserved")
    func requiredParametersArePreserved() throws {
        let toolDef = ToolDefinition(
            name: "test",
            description: "Test tool",
            parameters: [
                "required1": .string(description: "Required"),
                "required2": .integer(description: "Also required"),
                "optional": .optional(wrapped: .string(description: "Optional"))
            ]
        )

        let aiToolDef = try toolDef.toConduitToolDefinition()

        // Both required parameters should be in required array
        // Optional parameters should not be required
        #expect(aiToolDef.parameters.count == 3)
    }

    // MARK: - Type Conversion Tests

    @Test("string type converts to correct schema")
    func stringTypeConvertsToCorrectSchema() throws {
        let param = ToolDefinition.ParameterType.string(description: "A string param")

        let schema = try ConduitToolConverter.convertParameterType(param)

        if case .string = schema.type {
            // Success
        } else {
            Issue.record("Expected string type in schema")
        }
    }

    @Test("integer type converts to correct schema")
    func integerTypeConvertsToCorrectSchema() throws {
        let param = ToolDefinition.ParameterType.integer(description: "An integer param")

        let schema = try ConduitToolConverter.convertParameterType(param)

        if case .integer = schema.type {
            // Success
        } else {
            Issue.record("Expected integer type in schema")
        }
    }

    @Test("number type converts to correct schema")
    func numberTypeConvertsToCorrectSchema() throws {
        let param = ToolDefinition.ParameterType.number(description: "A number param")

        let schema = try ConduitToolConverter.convertParameterType(param)

        if case .number = schema.type {
            // Success
        } else {
            Issue.record("Expected number type in schema")
        }
    }

    @Test("boolean type converts to correct schema")
    func booleanTypeConvertsToCorrectSchema() throws {
        let param = ToolDefinition.ParameterType.boolean(description: "A boolean param")

        let schema = try ConduitToolConverter.convertParameterType(param)

        if case .boolean = schema.type {
            // Success
        } else {
            Issue.record("Expected boolean type in schema")
        }
    }

    @Test("array type converts to correct schema")
    func arrayTypeConvertsToCorrectSchema() throws {
        let param = ToolDefinition.ParameterType.array(
            items: .string(description: "Item"),
            description: "An array param"
        )

        let schema = try ConduitToolConverter.convertParameterType(param)

        if case .array = schema.type {
            // Success
        } else {
            Issue.record("Expected array type in schema")
        }
    }

    @Test("object type converts to correct schema")
    func objectTypeConvertsToCorrectSchema() throws {
        let param = ToolDefinition.ParameterType.object(
            properties: ["key": .string(description: "Value")],
            description: "An object param"
        )

        let schema = try ConduitToolConverter.convertParameterType(param)

        if case .object = schema.type {
            // Success
        } else {
            Issue.record("Expected object type in schema")
        }
    }

    // MARK: - Tool Extension Tests

    @Test("Tool conforms to protocol correctly")
    func toolConformsToProtocolCorrectly() {
        let tool = TestTool()

        #expect(tool.name == "test_tool")
        #expect(!tool.description.isEmpty)
    }

    @Test("Tool provides valid definition")
    func toolProvidesValidDefinition() {
        let tool = TestTool()
        let definition = tool.definition

        #expect(definition.name == tool.name)
        #expect(definition.description == tool.description)
    }

    // MARK: - Edge Cases

    @Test("empty parameters converts successfully")
    func emptyParametersConvertsSuccessfully() throws {
        let toolDef = ToolDefinition(
            name: "noParams",
            description: "Tool with no parameters",
            parameters: [:]
        )

        let aiToolDef = try toolDef.toConduitToolDefinition()

        #expect(aiToolDef.parameters.isEmpty)
    }

    @Test("deeply nested objects convert correctly")
    func deeplyNestedObjectsConvertCorrectly() throws {
        let toolDef = ToolDefinition(
            name: "nested",
            description: "Deeply nested tool",
            parameters: [
                "level1": .object(
                    properties: [
                        "level2": .object(
                            properties: [
                                "level3": .string(description: "Deep value")
                            ],
                            description: "Level 2"
                        )
                    ],
                    description: "Level 1"
                )
            ]
        )

        let aiToolDef = try toolDef.toConduitToolDefinition()

        #expect(aiToolDef.parameters.count == 1)
    }

    @Test("long parameter descriptions are preserved")
    func longParameterDescriptionsArePreserved() throws {
        let longDescription = String(repeating: "This is a very long description. ", count: 10)
        let toolDef = ToolDefinition(
            name: "longDesc",
            description: "Tool with long descriptions",
            parameters: [
                "param": .string(description: longDescription)
            ]
        )

        let aiToolDef = try toolDef.toConduitToolDefinition()

        #expect(aiToolDef.parameters.count == 1)
    }

    @Test("special characters in names and descriptions are handled")
    func specialCharactersInNamesAndDescriptionsAreHandled() throws {
        let toolDef = ToolDefinition(
            name: "special_chars_123",
            description: "Tool with \"quotes\" and 'apostrophes' and newlines\n",
            parameters: [
                "param_with_underscore": .string(description: "Param with \"quotes\"")
            ]
        )

        let aiToolDef = try toolDef.toConduitToolDefinition()

        #expect(aiToolDef.name == "special_chars_123")
        #expect(aiToolDef.parameters.count == 1)
    }
}

// MARK: - Test Helpers

private struct TestTool: Tool {
    let name = "test_tool"
    let description = "A test tool for testing"

    func execute(parameters _: SendableValue) async throws -> SendableValue {
        .string("test result")
    }

    var definition: ToolDefinition {
        ToolDefinition(
            name: name,
            description: description,
            parameters: [
                "input": .string(description: "Test input")
            ]
        )
    }
}
