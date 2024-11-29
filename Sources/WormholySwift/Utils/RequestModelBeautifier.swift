//
//  RequestModelBeautifier.swift
//  Wormholy-iOS
//
//  Created by Paolo Musolino on 18/04/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import UIKit
import SwiftUI

internal class RequestModelBeautifier {
    
    static func overview(request: RequestModel) -> (LocalizedStringKey, String) {
        let url = "**URL:** \(request.url)\n"
        let method = "**Method:** \(request.method)\n"
        let responseCode = "**Response Code:** \(request.code != 0 ? "\(request.code)" : "-")\n"
        let requestStartTime = "**Request Start Time:** \(request.date.stringWithFormat(dateFormat: "MMM d yyyy - HH:mm:ss") ?? "-")\n"
        let duration = "**Duration:** \(request.duration?.formattedMilliseconds() ?? "-")"
        let combinedString = [url, method, responseCode, requestStartTime, duration].joined()
        return (LocalizedStringKey(combinedString), combinedString)
    }
    
    static func header(_ headers: [String: String]?) -> (LocalizedStringKey, String) {
        guard let headerDictionary = headers else {
            return (LocalizedStringKey("-"), "-")
        }
        let combinedString = headerDictionary.map { "**\($0.key):** \($0.value)" }.joined(separator: "\n")
        return (LocalizedStringKey(combinedString), combinedString)
    }
    
    static func body(_ body: Data?, splitLength: Int? = nil) -> (LocalizedStringKey, String) {
        guard let body = body else {
            return (LocalizedStringKey("-"), "-")
        }
        
        if let data = splitLength != nil ? String(data: body, encoding: .utf8)?.characters(n: splitLength!) : String(data: body, encoding: .utf8) {
            let prettyData = data.prettyPrintedJSON ?? data
            return (LocalizedStringKey(prettyData), prettyData)
        }
        
        return (LocalizedStringKey("-"), "-")
    }
    
    static func txtExport(request: RequestModel) -> String {
        var txt: String = ""
        txt += "*** Overview *** \n"
        txt += "\(String(describing: overview(request: request).1))\n\n"
        txt += "*** Request Header *** \n"
        txt += "\(String(describing: header(request.headers).1))\n\n"
        txt += "*** Request Body *** \n"
        txt += "\(String(describing: body(request.httpBody).1))\n\n"
        txt += "*** Response Header *** \n"
        txt += "\(String(describing: header(request.responseHeaders).1))\n\n"
        txt += "*** Response Body *** \n"
        txt += "\(String(describing: body(request.dataResponse).1))\n\n"
        txt += "------------------------------------------------------------------------\n"
        txt += "------------------------------------------------------------------------\n"
        txt += "------------------------------------------------------------------------\n\n\n\n"
        return txt
    }
    
    static func curlExport(request: RequestModel) -> String {
        var txt: String = ""
        txt += "*** Overview *** \n"
        txt += "\(String(describing: overview(request: request).1))\n\n"
        txt += "*** curl Request *** \n"
        txt += "\(request.curlRequest)\n\n"
        txt += "*** Response Header *** \n"
        txt += "\(String(describing: header(request.responseHeaders).1))\n\n"
        txt += "*** Response Body *** \n"
        txt += "\(String(describing: body(request.dataResponse).1))\n\n"
        txt += "------------------------------------------------------------------------\n"
        txt += "------------------------------------------------------------------------\n"
        txt += "------------------------------------------------------------------------\n\n\n\n"
        return txt
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
