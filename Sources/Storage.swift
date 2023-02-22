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

    public static var defaultFilter: String? = nil
    
    open var requests: [RequestModel] = []
    open var filters: [FilterModel] = []
    
    func saveRequest(request: RequestModel?){
        guard request != nil else {
            return
        }
        
        if let index = requests.firstIndex(where: { (req) -> Bool in
            return request?.id == req.id ? true : false
        }){
            requests[index] = request!
        }else{
            requests.insert(request!, at: 0)
        }

        if let limit = Self.limit?.intValue {
            requests = Array(requests.prefix(limit))
        }
        NotificationCenter.default.post(name: newRequestNotification, object: nil)
    }
    
    func saveFilter(filter: FilterModel){
        if let index = filters.firstIndex(where: {(filt) -> Bool in
            return filter == filt
        }){
            // Filter might be selected before.
            let previousSelectionStatus = self.filters[index].selectionStatus
            self.filters[index] = filter
            if filter.selectionStatus == .new{
                self.filters[index].selectionStatus = previousSelectionStatus
            }
            
        } else {
            self.filters.insert(filter, at: 0)
        }
        
        NotificationCenter.default.post(name: filterChangeNotification, object: nil)
        
    }
    

    func clearFilters(){
        self.filters = filters.map{ filter in
                .init(filterCategory: filter.filterCategory, value: filter.value)
        }
    }
    
    func clearRequests() {
        requests.removeAll()
    }
}
