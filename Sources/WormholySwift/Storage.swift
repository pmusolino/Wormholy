//
//  Storage.swift
//  Wormholy-SDK-iOS
//
//  Created by Paolo Musolino on 04/02/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import Foundation

open class Storage: NSObject, ObservableObject {

    public static let shared: Storage = Storage()
  
    public static var limit: NSNumber? = nil

    public static var defaultFilter: String? = nil
    
    // The requests array is published to notify SwiftUI views of changes.
    @Published open private(set) var requests: [RequestModel] = []
    
    func saveRequest(request: RequestModel?) {
        guard let request = request else {
            return
        }
        
        var updatedRequests = self.requests
        
        if let index = updatedRequests.firstIndex(where: { $0.id == request.id }) {
            // Update the existing request if it already exists.
            updatedRequests[index] = request
        } else {
            // Insert the new request at the beginning of the array.
            updatedRequests.insert(request, at: 0)
        }

        // Enforce a limit on the number of stored requests, if specified.
        if let limit = Self.limit?.intValue, updatedRequests.count > limit {
            updatedRequests = Array(updatedRequests.prefix(limit))
        }
        
        // Update the requests array on the main thread.
        DispatchQueue.main.async {
            self.requests = updatedRequests
        }
    }

    func clearRequests() {
        // Clear requests array on the main thread.
        DispatchQueue.main.async {
            self.requests.removeAll()
        }
    }
}
