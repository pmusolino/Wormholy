//
//  RequestModelBeautifier.swift
//  Wormholy-iOS
//
//  Created by Paolo Musolino on 18/04/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import UIKit
import SwiftUI

class RequestModelBeautifier {
    
    static func overview(request: RequestModel) -> LocalizedStringKey {
        let url = "**URL:** \(request.url)\n"
        let method = "**Method:** \(request.method)\n"
        let responseCode = "**Response Code:** \(request.code != 0 ? "\(request.code)" : "-")\n"
        let requestStartTime = "**Request Start Time:** \(request.date.stringWithFormat(dateFormat: "MMM d yyyy - HH:mm:ss") ?? "-")\n"
        let duration = "**Duration:** \(request.duration?.formattedMilliseconds() ?? "-")"
        return LocalizedStringKey([url, method, responseCode, requestStartTime, duration].joined())
    }
    
    static func header(_ headers: [String: String]?) -> LocalizedStringKey {
        guard let headerDictionary = headers else {
            return LocalizedStringKey("-")
        }
        return LocalizedStringKey(headerDictionary.map { "**\($0.key):** \($0.value)" }.joined(separator: "\n"))
    }
    
    static func body(_ body: Data?, splitLength: Int? = nil) -> LocalizedStringKey {
        guard let body = body else {
            return LocalizedStringKey("-")
        }
        
        if let data = splitLength != nil ? String(data: body, encoding: .utf8)?.characters(n: splitLength!) : String(data: body, encoding: .utf8) {
            return LocalizedStringKey(data.prettyPrintedJSON ?? data)
        }
        
        return LocalizedStringKey("-")
    }
    
    static func txtExport(request: RequestModel) -> LocalizedStringKey {
        var txt: String = ""
        txt += "*** Overview *** \n"
        txt += "\(overview(request: request))\n\n"
        txt += "*** Request Header *** \n"
        txt += "\(header(request.headers))\n\n"
        txt += "*** Request Body *** \n"
        txt += "\(body(request.httpBody))\n\n"
        txt += "*** Response Header *** \n"
        txt += "\(header(request.responseHeaders))\n\n"
        txt += "*** Response Body *** \n"
        txt += "\(body(request.dataResponse))\n\n"
        txt += "------------------------------------------------------------------------\n"
        txt += "------------------------------------------------------------------------\n"
        txt += "------------------------------------------------------------------------\n\n\n\n"
        return LocalizedStringKey(txt)
    }
    
    static func curlExport(request: RequestModel) -> LocalizedStringKey {
        var txt: String = ""
        txt += "*** Overview *** \n"
        txt += "\(overview(request: request))\n\n"
        txt += "*** curl Request *** \n"
        txt += "\(LocalizedStringKey(request.curlRequest))\n\n"
        txt += "*** Response Header *** \n"
        txt += "\(header(request.responseHeaders))\n\n"
        txt += "*** Response Body *** \n"
        txt += "\(body(request.dataResponse))\n\n"
        txt += "------------------------------------------------------------------------\n"
        txt += "------------------------------------------------------------------------\n"
        txt += "------------------------------------------------------------------------\n\n\n\n"
        return LocalizedStringKey(txt)
    }
}

extension String {
    var prettyPrintedJSON: String? {
        guard let stringData = self.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: stringData, options: []),
              let jsonData = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let formattedJSON = String(data: jsonData, encoding: .utf8) else { return nil }

        return formattedJSON.replacingOccurrences(of: "\\/", with: "/")
    }
}
