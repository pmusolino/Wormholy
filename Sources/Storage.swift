//
//  Storage.swift
//  Wormholy-SDK-iOS
//
//  Created by Paolo Musolino on 04/02/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import Foundation

open class Storage: NSObject {

    public static let shared: Storage = Storage()
    
    open var requests: [RequestModel] = []
    
    open var hostFilters: [String] = []
    
    func saveRequest(request: RequestModel?) {
        guard let request = request else {
            return
        }
        if let url = URL(string: request.url), let host = url.host {
            if hostFilters.firstIndex(of: host) != nil {
                return
            }
        }
        if let index = requests.firstIndex(where: { (req) -> Bool in
            return request.id == req.id ? true : false
        }){
            requests[index] = request
        }else{
            requests.insert(request, at: 0)
        }
        NotificationCenter.default.post(name: newRequestNotification, object: nil)
    }

    func clearRequests() {
        requests.removeAll()
    }
}
