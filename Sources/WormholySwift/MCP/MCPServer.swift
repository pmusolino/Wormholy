#if canImport(MCP)
import MCP
import Foundation

internal class MCPServer {
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
                            "type": .string("string"),
                            "description": .string("Substring to match in the request URL (case-insensitive). Optional.")
                        ]),
                        "method_is": .object([
                            "type": .string("string"),
                            "description": .string("HTTP method to match (e.g., GET, POST). Case-insensitive. Optional.")
                        ]),
                        "status_code_is": .object([
                            "type": .string("integer"),
                            "description": .string("HTTP status code to match (e.g., 200, 404). Optional.")
                        ]),
                        "has_error": .object([
                            "type": .string("boolean"),
                            "description": .string("Set to true to find requests with client errors. Optional.")
                        ]),
                        "host_contains": .object([
                            "type": .string("string"),
                            "description": .string("Substring to match in the request host (case-insensitive). Optional.")
                        ]),
                        "scheme_is": .object([
                            "type": .string("string"),
                            "description": .string("Scheme to match (e.g., http, https). Case-insensitive. Optional.")
                        ]),
                        "port_is": .object([
                            "type": .string("integer"),
                            "description": .string("Port number to match. Optional.")
                        ]),
                        "has_cookies": .object([
                            "type": .string("boolean"),
                            "description": .string("Set to true to find requests that have cookies, false for no cookies. Optional.")
                        ]),
                        "has_http_body": .object([
                            "type": .string("boolean"),
                            "description": .string("Set to true to find requests that have an HTTP body, false for no body. Optional.")
                        ]),
                        "request_header_contains_key": .object([
                            "type": .string("string"),
                            "description": .string("Check if a specific key exists in request headers (case-insensitive key search). Optional.")
                        ]),
                        "request_header_value_for_key_contains": .object([
                            "type": .string("object"),
                            "description": .string("Check if a specific request header key has a value containing a substring. Optional."),
                            "properties": .object([
                                "key": .object(["type": .string("string"), "description": .string("The request header key to check (case-insensitive).")]),
                                "value_contains": .object(["type": .string("string"), "description": .string("The substring to search for in the header's value (case-insensitive).")])
                            ]),
                            "required": .array([.string("key"), .string("value_contains")])
                        ]),
                        "response_header_contains_key": .object([
                            "type": .string("string"),
                            "description": .string("Check if a specific key exists in response headers (case-insensitive key search). Optional.")
                        ]),
                        "response_header_value_for_key_contains": .object([
                            "type": .string("object"),
                            "description": .string("Check if a specific response header key has a value containing a substring. Optional."),
                            "properties": .object([
                                "key": .object(["type": .string("string"), "description": .string("The response header key to check (case-insensitive).")]),
                                "value_contains": .object(["type": .string("string"), "description": .string("The substring to search for in the header's value (case-insensitive).")])
                            ]),
                            "required": .array([.string("key"), .string("value_contains")])
                        ]),
                        "duration_greater_than_ms": .object([
                            "type": .string("integer"),
                            "description": .string("Filter requests with duration greater than specified milliseconds. Optional.")
                        ]),
                        "duration_less_than_ms": .object([
                            "type": .string("integer"),
                            "description": .string("Filter requests with duration less than specified milliseconds. Optional.")
                        ]),
                        "request_body_contains": .object([
                            "type": .string("string"),
                            "description": .string("Substring to match in the request body (UTF-8 decoded, case-insensitive). Optional.")
                        ]),
                        "response_body_contains": .object([
                            "type": .string("string"),
                            "description": .string("Substring to match in the response body (UTF-8 decoded, case-insensitive). Optional.")
                        ]),
                        "start_date_after": .object([
                            "type": .string("string"),
                            "description": .string("Filter requests starting after this ISO8601 date (e.g., \"2025-05-09T10:00:00Z\"). Optional.")
                        ]),
                        "start_date_before": .object([
                            "type": .string("string"),
                            "description": .string("Filter requests starting before this ISO8601 date (e.g., \"2025-05-09T10:00:00Z\"). Optional.")
                        ]),
                        "request_size_bytes_greater_than": .object([
                            "type": .string("integer"),
                            "description": .string("Filter by total request bytes sent (header + body) greater than specified value. Optional.")
                        ]),
                        "response_size_bytes_greater_than": .object([
                            "type": .string("integer"),
                            "description": .string("Filter by total response bytes received (header + body) greater than specified value. Optional.")
                        ])
                    ])
                )
            ]
            return .init(tools: tools)
        }

        let dateFormatter = ISO8601DateFormatter()

        // Register a tool call handler
        await server.withMethodHandler(CallTool.self) { params in
            switch params.name {
            case "search_network_requests":
                let arguments = params.arguments ?? [:]
                
                let urlContains = arguments["url_contains"]?.stringValue?.lowercased()
                let methodIs = arguments["method_is"]?.stringValue?.uppercased()
                let statusCodeIs = arguments["status_code_is"]?.intValue
                let hasError = arguments["has_error"]?.boolValue
                let hostContains = arguments["host_contains"]?.stringValue?.lowercased()
                let schemeIs = arguments["scheme_is"]?.stringValue?.lowercased()
                let portIs = arguments["port_is"]?.intValue
                let hasCookies = arguments["has_cookies"]?.boolValue
                let hasHttpBody = arguments["has_http_body"]?.boolValue
                let reqHeaderContainsKey = arguments["request_header_contains_key"]?.stringValue?.lowercased()
                var reqHeaderValueForKey: (key: String, valueContains: String)? = nil
                if let reqHeaderValueObj = arguments["request_header_value_for_key_contains"]?.objectValue,
                   let key = reqHeaderValueObj["key"]?.stringValue?.lowercased(),
                   let valueContains = reqHeaderValueObj["value_contains"]?.stringValue?.lowercased() {
                    reqHeaderValueForKey = (key: key, valueContains: valueContains)
                }
                let respHeaderContainsKey = arguments["response_header_contains_key"]?.stringValue?.lowercased()
                var respHeaderValueForKey: (key: String, valueContains: String)? = nil
                if let respHeaderValueObj = arguments["response_header_value_for_key_contains"]?.objectValue,
                   let key = respHeaderValueObj["key"]?.stringValue?.lowercased(),
                   let valueContains = respHeaderValueObj["value_contains"]?.stringValue?.lowercased() {
                    respHeaderValueForKey = (key: key, valueContains: valueContains)
                }
                let durationGreaterThanMs = arguments["duration_greater_than_ms"]?.intValue
                let durationLessThanMs = arguments["duration_less_than_ms"]?.intValue
                let requestBodyContains = arguments["request_body_contains"]?.stringValue?.lowercased()
                let responseBodyContains = arguments["response_body_contains"]?.stringValue?.lowercased()
                var startDateAfter: Date? = nil
                if let dateStr = arguments["start_date_after"]?.stringValue {
                    startDateAfter = dateFormatter.date(from: dateStr)
                }
                var startDateBefore: Date? = nil
                if let dateStr = arguments["start_date_before"]?.stringValue {
                    startDateBefore = dateFormatter.date(from: dateStr)
                }
                let requestSizeBytesGreaterThan = arguments["request_size_bytes_greater_than"]?.intValue
                let responseSizeBytesGreaterThan = arguments["response_size_bytes_greater_than"]?.intValue


                var filteredRequests = await MainActor.run { Storage.shared.requests }

                // Apply existing filters
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

                // Apply new filters
                if let hostSearch = hostContains {
                    filteredRequests = filteredRequests.filter { $0.host?.lowercased().contains(hostSearch) ?? false }
                }
                if let schemeSearch = schemeIs {
                    filteredRequests = filteredRequests.filter { $0.scheme?.lowercased() == schemeSearch }
                }
                if let portSearch = portIs {
                    filteredRequests = filteredRequests.filter { $0.port == portSearch }
                }
                if let cookiesSearch = hasCookies {
                    if cookiesSearch {
                        filteredRequests = filteredRequests.filter { $0.cookies != nil && !$0.cookies!.isEmpty }
                    } else {
                        filteredRequests = filteredRequests.filter { $0.cookies == nil || $0.cookies!.isEmpty }
                    }
                }
                if let bodySearch = hasHttpBody {
                    if bodySearch {
                        filteredRequests = filteredRequests.filter { $0.httpBody != nil && !$0.httpBody!.isEmpty }
                    } else {
                        filteredRequests = filteredRequests.filter { $0.httpBody == nil || $0.httpBody!.isEmpty }
                    }
                }

                if let keySearch = reqHeaderContainsKey {
                    filteredRequests = filteredRequests.filter { request in
                        request.headers.keys.contains { $0.lowercased() == keySearch }
                    }
                }
                if let searchCriteria = reqHeaderValueForKey {
                    filteredRequests = filteredRequests.filter { request in
                        request.headers.contains { (key, value) in
                            key.lowercased() == searchCriteria.key && value.lowercased().contains(searchCriteria.valueContains)
                        }
                    }
                }

                if let keySearch = respHeaderContainsKey {
                    filteredRequests = filteredRequests.filter { request in
                        request.responseHeaders?.keys.contains { $0.lowercased() == keySearch } ?? false
                    }
                }
                if let searchCriteria = respHeaderValueForKey {
                    filteredRequests = filteredRequests.filter { request in
                        request.responseHeaders?.contains { (key, value) in
                            key.lowercased() == searchCriteria.key && value.lowercased().contains(searchCriteria.valueContains)
                        } ?? false
                    }
                }

                if let durationSearch = durationGreaterThanMs {
                    filteredRequests = filteredRequests.filter { ($0.duration ?? -1.0) * 1000 > Double(durationSearch) }
                }
                if let durationSearch = durationLessThanMs {
                    filteredRequests = filteredRequests.filter { ($0.duration ?? Double.greatestFiniteMagnitude) * 1000 < Double(durationSearch) }
                }

                if let searchStr = requestBodyContains {
                    filteredRequests = filteredRequests.filter {
                        guard let bodyData = $0.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) else { return false }
                        return bodyString.lowercased().contains(searchStr)
                    }
                }
                if let searchStr = responseBodyContains {
                    filteredRequests = filteredRequests.filter {
                        guard let responseData = $0.dataResponse, let responseString = String(data: responseData, encoding: .utf8) else { return false }
                        return responseString.lowercased().contains(searchStr)
                    }
                }
                
                if let afterDate = startDateAfter {
                    filteredRequests = filteredRequests.filter { $0.startDate > afterDate }
                }
                if let beforeDate = startDateBefore {
                    filteredRequests = filteredRequests.filter { $0.startDate < beforeDate }
                }

                if let sizeSearch = requestSizeBytesGreaterThan {
                    filteredRequests = filteredRequests.filter {
                        let headerBytes = $0.countOfRequestHeaderBytesSent ?? 0
                        let bodyBytes = $0.countOfRequestBodyBytesSent ?? 0
                        return (headerBytes + bodyBytes) > Int64(sizeSearch)
                    }
                }
                if let sizeSearch = responseSizeBytesGreaterThan {
                    filteredRequests = filteredRequests.filter {
                        let headerBytes = $0.countOfResponseHeaderBytesReceived ?? 0
                        let bodyBytes = $0.countOfResponseBodyBytesReceived ?? 0
                        return (headerBytes + bodyBytes) > Int64(sizeSearch)
                    }
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
