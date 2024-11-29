//
//  ShareUtils.swift
//  Wormholy
//
//  Created by Paolo Musolino on 29/11/24.
//

import Foundation
import SwiftUI

internal final class ShareUtils {

    internal static func shareRequests(requests: [RequestModel], requestExportOption: RequestResponseExportOption = .flat) -> ActivityView {
        var text: String
        switch requestExportOption {
        case .flat:
            text = getTxtText(requests: requests)
        case .curl:
            text = getCurlText(requests: requests)
        case .postman:
            text = getPostmanCollection(requests: requests) ?? "{}"
            text = text.replacingOccurrences(of: "\\/", with: "/")
        }
        
        let textShare = [text]
        let customItem = CustomActivity(title: "Save to the desktop", image: UIImage(named: "activity_icon", in: WHBundle.getBundle(), compatibleWith: nil)) { (sharedItems) in
            guard let sharedStrings = sharedItems as? [String] else { return }
            
            let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
            
            let dateFormatterGet = DateFormatter()
            dateFormatterGet.dateFormat = "yyyyMMdd_HHmmss_SSS"
            
            let suffix: String
            switch requestExportOption {
            case .flat:
                suffix = "-wormholy.txt"
            case .curl:
                suffix = "-wormholy.txt"
            case .postman:
                suffix = "-postman_collection.json"
            }
            
            let filename = "\(appName)_\(dateFormatterGet.string(from: Date()))\(suffix)"
            
            for string in sharedStrings {
                FileHandler.writeTxtFileOnDesktop(text: string, fileName: filename)
            }
        }
        
        return ActivityView(activityItems: textShare, applicationActivities: [customItem])
    }
    
    private static func getTxtText(requests: [RequestModel]) -> String {
        var text: String = ""
        for request in requests {
            text += RequestModelBeautifier.txtExport(request: request)
        }
        return text
    }
    
    private static func getCurlText(requests: [RequestModel]) -> String {
        var text: String = ""
        for request in requests {
            text += RequestModelBeautifier.curlExport(request: request)
        }
        return text
    }
    
    private static func getPostmanCollection(requests: [RequestModel]) -> String? {
        var items: [PMItem] = []
        
        for request in requests {
            guard let postmanItem = request.postmanItem else { continue }
            items.append(postmanItem)
        }
        
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyyMMdd_HHmmss_SSS"
        
        let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        
        let collectionName = "\(appName) \(dateFormatterGet.string(from: Date()))"
        
        let info = PMInfo(postmanID: collectionName, name: collectionName, schema: "https://schema.getpostman.com/json/collection/v2.1.0/collection.json")
        
        let postmanCollectionItem = PMItem(name: collectionName, item: items, request: nil, response: nil)
        
        let postmanCollection = PostmanCollection(info: info, item: [postmanCollectionItem])
        
        let encoder = JSONEncoder()
        
        if let data = try? encoder.encode(postmanCollection), let string = String(data: data, encoding: .utf8) {
            return string
        } else {
            return nil
        }
    }
}
