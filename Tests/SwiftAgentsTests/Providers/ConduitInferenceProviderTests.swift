import Conduit
import Testing
@testable import SwiftAgents

@Suite("Conduit Inference Provider Bridge")
struct ConduitInferenceProviderBridgeTests {
    @Test("Converts ToolSchema into Conduit GenerationSchema")
    func convertsToolSchema() throws {
        let schema = ToolSchema(
            name: "weather",
            description: "Gets current weather",
            parameters: [
                ToolParameter(name: "location", description: "City name", type: .string),
                ToolParameter(name: "units", description: "Units", type: .oneOf(["c", "f"]), isRequired: false)
            ]
        )

        let generationSchema = try ConduitToolSchemaConverter.generationSchema(for: schema)
        let jsonSchema = generationSchema.toJSONSchema()

        let defs = jsonSchema["$defs"] as? [String: Any]
        #expect(defs != nil)
        guard let defs else { return }

        let ref = jsonSchema["$ref"] as? String
        #expect(ref != nil)
        guard let ref else { return }

        let rootName = ref.replacingOccurrences(of: "#/$defs/", with: "")
        let root = defs[rootName] as? [String: Any]
        #expect(root != nil)
        guard let root else { return }

        let properties = root["properties"] as? [String: Any]
        #expect(properties != nil)
        guard let properties else { return }

        let location = properties["location"] as? [String: Any]
        #expect(location?["type"] as? String == "string")

        let units = properties["units"] as? [String: Any]
        #expect(units?["enum"] as? [String] == ["c", "f"])

        let required = root["required"] as? [String]
        #expect(required?.contains("location") == true)
        #expect(required?.contains("units") == false)
    }

    @Test("Converts Conduit tool calls into SwiftAgents parsed tool calls")
    func convertsToolCall() throws {
        let arguments = try GeneratedContent(json: #"{"query":"swift","limit":3}"#)
        let call = Conduit.Transcript.ToolCall(id: "call_1", toolName: "search", arguments: arguments)

        let parsed = try ConduitToolCallConverter.toParsedToolCall(call)

        #expect(parsed.id == "call_1")
        #expect(parsed.name == "search")
        #expect(parsed.arguments["query"]?.stringValue == "swift")
        #expect(parsed.arguments["limit"]?.intValue == 3)
    }
}
