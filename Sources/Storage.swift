//
//  Storage.swift
//  Wormholy-SDK-iOS
//
//  Created by Paolo Musolino on 04/02/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import Foundation

class Storage: NSObject {

    static let shared: Storage = Storage()
    
    var requests: [RequestModel] = []
    
    func saveRequest(request: RequestModel?){
        guard request != nil else {
            return
        }
        
        if let index = requests.index(where: { (req) -> Bool in
            return request?.id == req.id ? true : false
        }){
            self.requests[index] = request!
        }else{
            requests.insert(request!, at: 0)
        }
    }
}
