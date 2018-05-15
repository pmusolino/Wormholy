//
//  RequestModelBeautifier.swift
//  Wormholy-iOS
//
//  Created by Paolo Musolino on 18/04/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import UIKit

class RequestModelBeautifier: NSObject {
    
    static func overview(request: RequestModel) -> NSMutableAttributedString{
        let url = NSMutableAttributedString().bold("URL ").normal(request.url + "\n")
        let method = NSMutableAttributedString().bold("Method ").normal(request.method + "\n")
        let responseCode = NSMutableAttributedString().bold("Response Code ").normal((request.code != 0 ? "\(request.code)" : "-") + "\n")
        let requestStartTime = NSMutableAttributedString().bold("Request Start Time ").normal((request.date.stringWithFormat(dateFormat: "MMM d yyyy - HH:mm:ss") ?? "-") + "\n")
        let duration = NSMutableAttributedString().bold("Duration ").normal(request.duration?.formattedMilliseconds() ?? "-" + "\n")
        let final = NSMutableAttributedString()
        for attr in [url, method, responseCode, requestStartTime, duration]{
            final.append(attr)
        }
        return final
    }
    
    static func header(request: RequestModel) -> NSMutableAttributedString{
        guard request.headers != nil else {
            return NSMutableAttributedString(string: "-")
        }
        let final = NSMutableAttributedString()
        for key in request.headers!.keys {
            final.append(NSMutableAttributedString().bold(key).normal(" " + (request.headers![key] ?? "-") + "\n"))
        }
        return final
    }
    
    static func body(request: RequestModel) -> NSMutableAttributedString{
        guard request.httpBody != nil else {
            return NSMutableAttributedString(string: "-")
        }
        
        if let data = String(data: request.httpBody!, encoding: .utf8){
            return NSMutableAttributedString().normal(data)
        }
        return NSMutableAttributedString(string: "-")
    }
    
    static func responseBody(request: RequestModel) -> NSMutableAttributedString{
        
        
        guard request.dataResponse != nil else {
            return NSMutableAttributedString(string: "-")
        }
        
        if let data = String(data: request.dataResponse!, encoding: .utf8){
            if let highlightr = Highlightr(){
                highlightr.setTheme(to: "paraiso-dark")
                
                if let highlightedCode = highlightr.highlight(data){
                    return NSMutableAttributedString(attributedString: highlightedCode)
                }
            }
        }
        return NSMutableAttributedString(string: "-")
    }
    
}

extension NSMutableAttributedString {
    @discardableResult func bold(_ text: String) -> NSMutableAttributedString {
        let attrs: [NSAttributedStringKey: Any] = [.font: UIFont.boldSystemFont(ofSize: 15)]
        let boldString = NSMutableAttributedString(string:text, attributes: attrs)
        append(boldString)
        return self
    }
    
    @discardableResult func normal(_ text: String) -> NSMutableAttributedString {
        let attrs: [NSAttributedStringKey: Any] = [.font: UIFont.systemFont(ofSize: 14)]
        let normal = NSMutableAttributedString(string:text, attributes: attrs)
        append(normal)
        return self
    }
}
