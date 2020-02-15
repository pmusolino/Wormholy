//
//  RequestModel.swift
//  Wormholy-SDK-iOS
//
//  Created by Paolo Musolino on 29/01/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//
import Foundation
import UIKit

open class RequestModel: Codable {
    public let id: String
    public let url: String
    public let date: Date
    public let method: String
    public let headers: [String: String]?
    open var httpBody: Data?
    open var code: Int
    open var responseHeaders: [String: String]?
    open var dataResponse: Data?
    open var errorClientDescription: String?
    open var duration: Double?
    
    init(request: NSURLRequest) {
        id = UUID().uuidString
        url = request.url?.absoluteString ?? ""
        date = Date()
        method = request.httpMethod ?? "GET"
        headers = request.allHTTPHeaderFields
        httpBody = request.httpBody
        code = 0
    }
    
    func initResponse(response: URLResponse) {
        guard let responseHttp = response as? HTTPURLResponse else {return}
        code = responseHttp.statusCode
        responseHeaders = responseHttp.allHeaderFields as? [String: String]
    }
    
    var curlRequest: String {
        let methodParam = " -X \(method)"
        var headersParams = ""
        if let headers = self.headers {
            for header in headers {
                headersParams = " -H \"\(header.0): \(header.1)\""
            }
        }
        var bodyParam = ""
        if let httpBody = self.httpBody {
            bodyParam = " -d \"\(httpBody)\""
        }
        let urlParam = " \"\(url)\""
        return "curl\(methodParam)\(headersParams)\(bodyParam)\(urlParam)";
    }
}
