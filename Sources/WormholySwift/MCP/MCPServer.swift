#if canImport(MCP)
import MCP
import Foundation

class MCPServer {
    func start() async throws {
        // Initialize the server with capabilities
        let server = Server(
            name: "Wormholy",
            version: "2.2.0",
            capabilities: .init(
                prompts: .init(listChanged: false),
                resources: .init(subscribe: false, listChanged: false),
                tools: .init(listChanged: true)
            )
        )

        // Register tool handlers
        await registerToolHandlers(on: server)

        // Create transport and start server
        let transport = StdioTransport()
        try await server.start(transport: transport)
    }

    private func registerToolHandlers(on server: Server) async {
        // Register a tool list handler
        await server.withMethodHandler(ListTools.self) { _ in
            let tools = [
                Tool(
                    name: "search_network_requests",
                    description: "Search and filter recorded network requests from Wormholy.",
                    inputSchema: .object([
                        "url_contains": .object([
                            "type": "string",
                            "description": "Substring to match in the request URL (case-insensitive). Optional."
                        ]),
                        "method_is": .object([
                            "type": "string",
                            "description": "HTTP method to match (e.g., GET, POST). Case-insensitive. Optional."
                        ]),
                        "status_code_is": .object([
                            "type": "int",
                            "description": "HTTP status code to match (e.g., 200, 404). Optional."
                        ]),
                        "has_error": .object([
                            "type": "bool",
                            "description": "Whether to include requests that encountered an error. Optional."
                        ])
                    ])
                )
            ]
            return .init(tools: tools)
        }

        // Register a tool call handler
        await server.withMethodHandler(CallTool.self) { params in
            switch params.name {
            case "search_network_requests":
                let arguments = params.arguments ?? [:]
                let urlContains = arguments["url_contains"]?.stringValue?.lowercased()
                let methodIs = arguments["method_is"]?.stringValue?.uppercased()
                let statusCodeIs = arguments["status_code_is"]?.intValue
                let hasError = arguments["has_error"]?.boolValue

                var filteredRequests = await MainActor.run { Storage.shared.requests }

                if let urlSearch = urlContains {
                    filteredRequests = filteredRequests.filter { $0.url.lowercased().contains(urlSearch) }
                }
                if let methodSearch = methodIs {
                    filteredRequests = filteredRequests.filter { $0.method.uppercased() == methodSearch }
                }
                if let codeSearch = statusCodeIs {
                    filteredRequests = filteredRequests.filter { $0.code == codeSearch }
                }
                if let errorSearch = hasError, errorSearch == true {
                    filteredRequests = filteredRequests.filter { $0.errorClientDescription != nil && !$0.errorClientDescription!.isEmpty }
                }

                if filteredRequests.isEmpty {
                    return .init(content: [.text("[Wormholy MCP] No network requests found matching your criteria.")], isError: false)
                } else {
                    let responseLines = filteredRequests.map { req -> String in
                        var line = "[\(req.method)] \(req.url) - Status: \(req.code)"
                        if let errorDesc = req.errorClientDescription, !errorDesc.isEmpty {
                            line += " (Error: \(errorDesc))"
                        }
                        return line
                    }
                    let responseText = "Found \(filteredRequests.count) request(s):\n" + responseLines.joined(separator: "\n")
                    return .init(content: [.text(responseText)], isError: false)
                }

            default:
                return .init(content: [.text("Unknown tool: \(params.name)")], isError: true)
            }
        }
    }
}

#endif
