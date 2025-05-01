//
//  Storage.swift
//  Wormholy-SDK-iOS
//
//  Created by Paolo Musolino on 04/02/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import Foundation

@MainActor
internal class Storage: NSObject, ObservableObject {

    internal static let shared: Storage = Storage()
  
    internal static var limit: NSNumber? = nil

    internal static var defaultFilter: String? = nil
    
    // The requests array is published to notify SwiftUI views of changes.
    @Published internal private(set) var requests: [RequestModel] = []
    
    // Method to save a request
    internal func saveRequest(_ request: RequestModel?) {
        guard let request = request else { return }
        
        // Check if the request already exists and update it
        if let index = requests.firstIndex(where: { $0.id == request.id }) {
            requests[index] = request
        } else {
            // Add the new request
            requests.insert(request, at: 0)
            
            // Enforce the limit if set
            if let limit = Storage.limit?.intValue, requests.count > limit {
                requests.removeLast()
            }
        }
    }
    
    // Method to clear all requests
    internal func clearRequests() {
        requests.removeAll()
    }
}
