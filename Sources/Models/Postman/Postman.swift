import Foundation

struct PostmanCollection: Codable {
    let info: PMInfo
    let item: [PMItem]
}

struct PMInfo: Codable {
    let postmanID, name: String
    let schema: String
}

struct PMItem: Codable {
    let name: String
    let item: [PMItem]?
    let request: PMRequest?
    let response: [PMResponse]?
}

struct PMRequest: Codable {
    let method: String
    let header: [PMHeader]
    let body: PMBody
    let url: PMURL
    let description: String?
}

struct PMBody: Codable {
    let mode: String
    let raw: String
}

struct PMHeader: Codable {
    let key: String
    let value: String
}

struct PMURL: Codable {
    let raw: String
    let urlProtocol: String
    let host: [String]
    let path: [String]
    let query: [PMQuery]?
    
    enum CodingKeys: String, CodingKey {
        case raw, host, path, query
        case urlProtocol = "protocol"
    }
}

struct PMQuery: Codable {
    let key: String
    let value: String
}

struct PMResponse: Codable {
    let name: String
    let originalRequest: PMRequest
    let status: String
    let code: Int
    let postmanPreviewlanguage: String
    let header: [PMHeader]
    let cookie: [String]
    let body: String
    
    enum CodingKeys: String, CodingKey {
        case name, originalRequest, status, code, header, cookie, body
        case postmanPreviewlanguage = "_postman_previewlanguage"
    }
}
