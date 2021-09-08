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
  
    public static var limit: NSNumber? = nil
    
    open var requests: [RequestModel] = []
    
    private let queue: DispatchQueue = .init(label: "wormholy.storage")

    func saveRequest(request: RequestModel?){
        queue.async { [weak self] in
            guard let request = request,
                  var requests = self?.requests else {
                return
            }
            
            if let index = requests.firstIndex(where: { (req) -> Bool in
                return request.id == req.id ? true : false
            }){
                requests[index] = request
            }else{
                requests.insert(request, at: 0)
            }

            if let limit = Self.limit?.intValue {
                requests = Array(requests.prefix(limit))
            }
            self?.requests = requests
            NotificationCenter.default.post(name: newRequestNotification, object: nil)
        }

    }

    func clearRequests() {
        queue.async { [weak self] in
            self?.requests.removeAll()
        }
    }
}
