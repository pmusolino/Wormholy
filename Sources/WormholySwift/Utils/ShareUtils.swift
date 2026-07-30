//
//  ShareUtils.swift
//  Wormholy
//
//  Created by Paolo Musolino on 29/11/24.
//

import Foundation
import SwiftUI

internal final class ShareUtils {
    private static let timestampDateFormat = "yyyyMMdd_HHmmss_SSS"

    internal static func shareRequests(requests: [RequestModel], requestExportOption: RequestResponseExportOption = .flat) -> ActivityView {
        var text: String
        let suffix: String
        switch requestExportOption {
        case .flat:
            text = getTxtText(requests: requests)
            suffix = "-wormholy.txt"
        case .curl:
            text = getCurlText(requests: requests)
            suffix = "-wormholy.sh"
        case .postman:
            text = getPostmanCollection(requests: requests) ?? "{}"
            text = text.replacingOccurrences(of: "\\/", with: "/")
            suffix = "-postman_collection.json"
        }

        return shareText(text, fileSuffix: suffix)
    }

    @MainActor
    internal static func shareWebSocket(connection: WebSocketModel) -> ActivityView {
        shareWebSockets(connections: [connection])
    }

    @MainActor
    internal static func shareWebSockets(connections: [WebSocketModel]) -> ActivityView {
        shareText(connections.map(WebSocketModelBeautifier.txtExport).joined(), fileSuffix: "-wormholy-websocket.txt")
    }

    private static func shareText(_ text: String, fileSuffix: String) -> ActivityView {
        let textShare = [text]
        let customItem = CustomActivity(title: "Save to the desktop", image: UIImage(named: "activity_icon", in: WHBundle.getBundle(), compatibleWith: nil)) { sharedItems in
            guard let sharedStrings = sharedItems as? [String] else { return }

            let filename = "\(appName)_\(timestamp())\(fileSuffix)"

            for string in sharedStrings {
                FileHandler.writeTxtFileOnDesktop(text: string, fileName: filename)
            }
        }

        return ActivityView(activityItems: textShare, applicationActivities: [customItem])
    }

    private static var appName: String {
        Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? "Wormholy"
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = timestampDateFormat
        return formatter.string(from: Date())
    }
    
    private static func getTxtText(requests: [RequestModel]) -> String {
        var text: String = ""
        for request in requests {
            text += RequestModelBeautifier.txtExport(request: request)
        }
        return text
    }
    
    private static func getCurlText(requests: [RequestModel]) -> String {
        requests
            .map(RequestModelBeautifier.curlExport)
            .joined(separator: "\n\n")
    }
    
    private static func getPostmanCollection(requests: [RequestModel]) -> String? {
        var items: [PMItem] = []
        
        for request in requests {
            guard let postmanItem = request.postmanItem else { continue }
            items.append(postmanItem)
        }
        
        let collectionName = "\(appName) \(timestamp())"
        
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
