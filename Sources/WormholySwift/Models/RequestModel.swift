//
//  RequestModel.swift
//  Wormholy-SDK-iOS
//
//  Created by Paolo Musolino on 29/01/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//
import Foundation
import UIKit

internal class RequestModel: Hashable, Decodable, ObservableObject {
    internal let id: String
    internal let url: String
    internal let host: String?
    internal let port: Int?
    internal let scheme: String?
    internal let startDate: Date
    internal let method: String
    internal let headers: [String: String]
    @Published internal private(set) var credentials: [String : String]
    @Published internal private(set) var cookies: String?
    @Published internal private(set) var httpBody: Data?
    @Published internal private(set) var code: Int
    @Published internal private(set) var responseHeaders: [String: String]?
    @Published internal private(set) var dataResponse: Data?
    @Published internal private(set) var errorClientDescription: String?
    @Published internal private(set) var duration: Double?
    
    // Variables for network statistics
    @Published public private(set) var requestStartDate: Date?
    @Published public private(set) var requestEndDate: Date?
    @Published public private(set) var responseStartDate: Date?
    @Published public private(set) var responseEndDate: Date?
    @Published public private(set) var countOfRequestBodyBytesBeforeEncoding: Int64?
    @Published public private(set) var countOfRequestBodyBytesSent: Int64?
    @Published public private(set) var countOfRequestHeaderBytesSent: Int64?
    @Published public private(set) var countOfResponseBodyBytesAfterDecoding: Int64?
    @Published public private(set) var countOfResponseBodyBytesReceived: Int64?
    @Published public private(set) var countOfResponseHeaderBytesReceived: Int64?

    enum CodingKeys: String, CodingKey {
        case id, url, host, port, scheme, startDate, method, headers, credentials, cookies, httpBody, code, responseHeaders, dataResponse, errorClientDescription, duration
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        url = try container.decode(String.self, forKey: .url)
        host = try container.decodeIfPresent(String.self, forKey: .host)
        port = try container.decodeIfPresent(Int.self, forKey: .port)
        scheme = try container.decodeIfPresent(String.self, forKey: .scheme)
        startDate = try container.decode(Date.self, forKey: .startDate)
        method = try container.decode(String.self, forKey: .method)
        headers = try container.decode([String: String].self, forKey: .headers)
        credentials = try container.decode([String: String].self, forKey: .credentials)
        cookies = try container.decodeIfPresent(String.self, forKey: .cookies)
        httpBody = try container.decodeIfPresent(Data.self, forKey: .httpBody)
        code = try container.decode(Int.self, forKey: .code)
        responseHeaders = try container.decodeIfPresent([String: String].self, forKey: .responseHeaders)
        dataResponse = try container.decodeIfPresent(Data.self, forKey: .dataResponse)
        errorClientDescription = try container.decodeIfPresent(String.self, forKey: .errorClientDescription)
        duration = try container.decodeIfPresent(Double.self, forKey: .duration)
    }
    
    init(request: NSURLRequest, session: URLSession?) {
        id = UUID().uuidString
        url = request.url?.absoluteString ?? ""
        host = request.url?.host
        port = request.url?.port
        scheme = request.url?.scheme
        startDate = Date()
        method = request.httpMethod ?? "GET"
        credentials = [:]
        var headers = request.allHTTPHeaderFields ?? [:]
        httpBody = request.httpBody
        code = 0
        
        // collect all HTTP Request headers except the "Cookie" header. Many request representations treat cookies with special parameters or structures. For cookie collection, refer to the bottom part of this method
        session?.configuration.httpAdditionalHeaders?
            .filter {  $0.0 != AnyHashable("Cookie") }
            .forEach { element in
                guard let key = element.0 as? String, let value = element.1 as? String else { return }
                headers[key] = value
        }
        self.headers = headers
        
        // if the target server uses HTTP Basic Authentication, collect username and password
        if let credentialStorage = session?.configuration.urlCredentialStorage,
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
        
        //  collect cookies associated with the target host
        //  TODO: Add the else branch.
        /*  With the condition below, it is handled only the case where session.configuration.httpShouldSetCookies == true.
            Some developers could opt to handle cookie manually using the "Cookie" header stored in httpAdditionalHeaders
            and disabling the handling provided by URLSessionConfiguration (httpShouldSetCookies == false).
            See: https://developer.apple.com/documentation/foundation/nsurlsessionconfiguration/1411589-httpshouldsetcookies?language=objc
        */
        if let session = session, let url = request.url, session.configuration.httpShouldSetCookies {
            if let cookieStorage = session.configuration.httpCookieStorage,
                let cookies = cookieStorage.cookies(for: url), !cookies.isEmpty {
                DispatchQueue.main.async {
                    self.cookies = cookies.reduce("") { $0 + "\($1.name)=\($1.value);" }
                }
            }
        }
    }
    
    // Initializer for mocking purposes
    init(id: String = UUID().uuidString,
         url: String,
         host: String? = nil,
         port: Int? = nil,
         scheme: String? = nil,
         startDate: Date = Date(),
         method: String = "GET",
         headers: [String: String] = [:],
         credentials: [String: String] = [:],
         cookies: String? = nil,
         httpBody: Data? = nil,
         code: Int = 0,
         responseHeaders: [String: String]? = nil,
         dataResponse: Data? = nil,
         errorClientDescription: String? = nil,
         duration: Double? = nil) {
        self.id = id
        self.url = url
        self.host = host
        self.port = port
        self.scheme = scheme
        self.startDate = startDate
        self.method = method
        self.headers = headers
        self.credentials = credentials
        self.cookies = cookies
        self.httpBody = httpBody
        self.code = code
        self.responseHeaders = responseHeaders
        self.dataResponse = dataResponse
        self.errorClientDescription = errorClientDescription
        self.duration = duration
    }
    
    func initResponse(response: URLResponse) {
        guard let responseHttp = response as? HTTPURLResponse else {return}
        DispatchQueue.main.async {
            self.code = responseHttp.statusCode
            self.responseHeaders = responseHttp.allHeaderFields as? [String: String]
        }
    }
    
    // This method is used to update the properties of the RequestModel instance.
    // It ensures that changes are published from the main thread, which is necessary
    // because publishing changes from background threads is not allowed.
    func copy(credentials: [String: String]? = nil,
              cookies: String? = nil,
              httpBody: Data? = nil,
              code: Int? = nil,
              responseHeaders: [String: String]? = nil,
              dataResponse: Data? = nil,
              errorClientDescription: String? = nil,
              duration: Double? = nil,
              requestStartDate: Date? = nil,
              requestEndDate: Date? = nil,
              responseStartDate: Date? = nil,
              responseEndDate: Date? = nil,
              countOfRequestBodyBytesBeforeEncoding: Int64? = nil,
              countOfRequestBodyBytesSent: Int64? = nil,
              countOfRequestHeaderBytesSent: Int64? = nil,
              countOfResponseBodyBytesAfterDecoding: Int64? = nil,
              countOfResponseBodyBytesReceived: Int64? = nil,
              countOfResponseHeaderBytesReceived: Int64? = nil) {
        DispatchQueue.main.async {
            if let credentials = credentials {
                self.credentials = credentials
            }
            if let cookies = cookies {
                self.cookies = cookies
            }
            if let httpBody = httpBody {
                self.httpBody = httpBody
            }
            if let code = code {
                self.code = code
            }
            if let responseHeaders = responseHeaders {
                self.responseHeaders = responseHeaders
            }
            if let dataResponse = dataResponse {
                if self.dataResponse != nil {
                    self.dataResponse?.append(dataResponse)
                } else {
                    self.dataResponse = dataResponse
                }
            }
            if let errorClientDescription = errorClientDescription {
                self.errorClientDescription = errorClientDescription
            }
            if let duration = duration {
                self.duration = duration
            }
            if let requestStartDate = requestStartDate {
                self.requestStartDate = requestStartDate
            }
            if let requestEndDate = requestEndDate {
                self.requestEndDate = requestEndDate
            }
            if let responseStartDate = responseStartDate {
                self.responseStartDate = responseStartDate
            }
            if let responseEndDate = responseEndDate {
                self.responseEndDate = responseEndDate
            }
            if let countOfRequestBodyBytesBeforeEncoding = countOfRequestBodyBytesBeforeEncoding {
                self.countOfRequestBodyBytesBeforeEncoding = countOfRequestBodyBytesBeforeEncoding
            }
            if let countOfRequestBodyBytesSent = countOfRequestBodyBytesSent {
                self.countOfRequestBodyBytesSent = countOfRequestBodyBytesSent
            }
            if let countOfRequestHeaderBytesSent = countOfRequestHeaderBytesSent {
                self.countOfRequestHeaderBytesSent = countOfRequestHeaderBytesSent
            }
            if let countOfResponseBodyBytesAfterDecoding = countOfResponseBodyBytesAfterDecoding {
                self.countOfResponseBodyBytesAfterDecoding = countOfResponseBodyBytesAfterDecoding
            }
            if let countOfResponseBodyBytesReceived = countOfResponseBodyBytesReceived {
                self.countOfResponseBodyBytesReceived = countOfResponseBodyBytesReceived
            }
            if let countOfResponseHeaderBytesReceived = countOfResponseHeaderBytesReceived {
                self.countOfResponseHeaderBytesReceived = countOfResponseHeaderBytesReceived
            }
        }
    }
    
    static func == (lhs: RequestModel, rhs: RequestModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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
            // the following replacingOccurrences handles cases where httpBody already contains the escape \ character before the double quotation mark (") character
            var escapedBody = httpBody.replacingOccurrences(of: "\\\"", with: "\\\\\"") // \" -> \\\"
            // the following replacingOccurrences escapes the character double quotation mark (")
            escapedBody = escapedBody.replacingOccurrences(of: "\"", with: "\\\"") // " -> \"

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
        
        let name = "\(dateFormatterGet.string(from: startDate))-\(url)"
        
        var headers: [PMHeader] = []
        let method = self.method
        for header in self.headers {
            headers.append(PMHeader(key: header.0, value: header.1))
        }
        
        var rawBody: String = ""
        if let httpBodyData = httpBody, let httpBody = String(data: httpBodyData, encoding: .utf8) {
            rawBody = httpBody
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
        
        return PMItem(name: name, item: nil, request: request, response: [response])
    }
}
