//
//  RequestModel.swift
//  Wormholy-SDK-iOS
//
//  Created by Paolo Musolino on 29/01/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//
import Foundation

class RequestModel: Codable {
    let id: String
    let url: String
    let date: Date
    let method: String
    let headers: [String: String]?
    var httpBody: Data?
    var code: Int
    var dataResponse: Data?
    var errorClientDescription: String?
    var duration: Double?
    
    init(request: NSURLRequest) {
        id = UUID().uuidString
        url = request.url?.absoluteString ?? ""
        date = Date()
        method = request.httpMethod ?? "N/A"
        headers = request.allHTTPHeaderFields
        httpBody = request.httpBody
        code = 0
    }
    
    func initResponse(response: URLResponse) {
        guard let responseHttp = response as? HTTPURLResponse else {return}
        code = responseHttp.statusCode
    }
}

