import Foundation

internal struct PostmanCollection: Codable {
    internal let info: PMInfo
    internal let item: [PMItem]
}

internal struct PMInfo: Codable {
    internal let postmanID, name: String
    internal let schema: String
}

internal struct PMItem: Codable {
    internal let name: String
    internal let item: [PMItem]?
    internal let request: PMRequest?
    internal let response: [PMResponse]?
}

internal struct PMRequest: Codable {
    internal let method: String
    internal let header: [PMHeader]
    internal let body: PMBody
    internal let url: PMURL
    internal let description: String?
}

internal struct PMBody: Codable {
    internal let mode: String
    internal let raw: String
}

internal struct PMHeader: Codable {
    internal let key: String
    internal let value: String
}

internal struct PMURL: Codable {
    internal let raw: String
    internal let urlProtocol: String
    internal let host: [String]
    internal let path: [String]
    internal let query: [PMQuery]?
    
    enum CodingKeys: String, CodingKey {
        case raw, host, path, query
        case urlProtocol = "protocol"
    }
}

internal struct PMQuery: Codable {
    internal let key: String
    internal let value: String
}

internal struct PMResponse: Codable {
    internal let name: String
    internal let originalRequest: PMRequest
    internal let status: String
    internal let code: Int
    internal let postmanPreviewlanguage: String
    internal let header: [PMHeader]
    internal let cookie: [String]
    internal let body: String
    
    enum CodingKeys: String, CodingKey {
        case name, originalRequest, status, code, header, cookie, body
        case postmanPreviewlanguage = "_postman_previewlanguage"
    }
}
