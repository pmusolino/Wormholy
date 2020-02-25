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
    public let host: String?
    public let port: Int?
    public let scheme: String?
    public let date: Date
    public let method: String
    public let headers: [String: String]
    public var credentials: [String : String]
    public var cookies: String?
    open var httpBody: Data?
    open var code: Int
    open var responseHeaders: [String: String]?
    open var dataResponse: Data?
    open var errorClientDescription: String?
    open var duration: Double?
    
    init(request: NSURLRequest, session: URLSession?) {
        id = UUID().uuidString
        url = request.url?.absoluteString ?? ""
        host = request.url?.host
        port = request.url?.port
        scheme = request.url?.scheme
        date = Date()
        method = request.httpMethod ?? "GET"
        credentials = [:]
        var headers = request.allHTTPHeaderFields ?? [:]
        httpBody = request.httpBody
        code = 0
        
        session?.configuration.httpAdditionalHeaders?.filter {  $0.0 != AnyHashable("Cookie") }
            .forEach { element in
                guard let key = element.0 as? String, let value = element.1 as? String else { return }
                headers[key] = value }
        self.headers = headers
        
        
        if
            let credentialStorage = session?.configuration.urlCredentialStorage,
            let host = self.host,
            let port = self.port {
            let protectionSpace = URLProtectionSpace(
                host: host,
                port: port,
                protocol: scheme,
                realm: host,
                authenticationMethod: NSURLAuthenticationMethodHTTPBasic
            )

            if let credentials = credentialStorage.credentials(for: protectionSpace)?.values {
                for credential in credentials {
                    guard let user = credential.user, let password = credential.password else { continue }
                    self.credentials[user] = password
                }
            }
        }
        
        if let session = session, let url = request.url, session.configuration.httpShouldSetCookies {
            if
                let cookieStorage = session.configuration.httpCookieStorage,
                let cookies = cookieStorage.cookies(for: url), !cookies.isEmpty
            {
                self.cookies = cookies.reduce("") { $0 + "\($1.name)=\($1.value);" }
            }
        }
    }
    
    func initResponse(response: URLResponse) {
        guard let responseHttp = response as? HTTPURLResponse else {return}
        code = responseHttp.statusCode
        responseHeaders = responseHttp.allHeaderFields as? [String: String]
    }
    
    var curlRequest: String {
        var components = ["$ curl -v"]

        guard
            let _ = self.host
        else {
            return "$ curl command could not be created"
        }

        if method != "GET" {
            components.append("-X \(method)")
        }

        components += headers.map {
            let escapedValue = String(describing: $0.value).replacingOccurrences(of: "\"", with: "\\\"")

            return "-H \"\($0.key): \(escapedValue)\""
        }

        if let httpBodyData = httpBody, let httpBody = String(data: httpBodyData, encoding: .utf8) {
            var escapedBody = httpBody.replacingOccurrences(of: "\\\"", with: "\\\\\"")
            escapedBody = escapedBody.replacingOccurrences(of: "\"", with: "\\\"")

            components.append("-d \"\(escapedBody)\"")
        }
        
        for credential in credentials {
            components.append("-u \(credential.0):\(credential.1)")
        }
        
        if let cookies = cookies {
            components.append("-b \"\(cookies[..<cookies.index(before: cookies.endIndex)])\"")
        }

        components.append("\"\(url)\"")

        return components.joined(separator: " \\\n\t")
    }
    
    var postmanItem: PMItem? {
        guard
            let url = URL(string: self.url),
            let scheme = self.scheme,
            let host = self.host
            else { return nil }
        
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyyMMdd_HHmmss"
        
        let name = "\(dateFormatterGet.string(from: date))-\(url)"
        
        var headers: [PMHeader] = []
        let method = self.method
        for header in self.headers {
            headers.append(PMHeader(key: header.0, value: header.1))
        }
        
        let rawBody: String
        if let httpBodyData = httpBody, let httpBody = String(data: httpBodyData, encoding: .utf8) {
            rawBody = httpBody
        }
        else {
            rawBody = ""
        }
        
        let hostList = host.split(separator: ".")
            .map{ String(describing: $0) }
        
        var pathList = url.pathComponents
        pathList.removeFirst()

        let body = PMBody(mode: "raw", raw: rawBody)
        
        let query: [PMQuery]? = url.query?.split(separator: "&").compactMap{ element in
            let splittedElements = element.split(separator: "=")
            guard splittedElements.count == 2 else { return nil }
            let key = String(splittedElements[0])
            let value = String(splittedElements[1])
            return PMQuery(key: key, value: value)
        }

        let urlPostman = PMURL(raw: url.absoluteString, urlProtocol: scheme, host: hostList, path: pathList, query: query)
        let request = PMRequest(method: method, header: headers, body: body, url: urlPostman, description: "")
        
        // build response
        
        let responseHeaders = self.responseHeaders?.compactMap{ (key, value) in
            return PMHeader(key: key, value: value)
        } ?? []
        
        let responseBody: String
        if let data = dataResponse, let string = String(data: data, encoding: .utf8) {
            responseBody = string
        }
        else {
            responseBody = ""
        }
        
        let response = PMResponse(name: url.absoluteString, originalRequest: request, status: "", code: code, postmanPreviewlanguage: "html", header: responseHeaders, cookie: [], body: responseBody)
        
        return PMItem(name: name, item: nil, protocolProfileBehavior: nil, request: request, response: [response])
    }
}
