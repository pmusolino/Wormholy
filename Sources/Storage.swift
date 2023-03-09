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
    
    open var requests: [RequestModel] = []{
        didSet{
            self.createFilterModel(from: requests)
        }
    }
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
    
    /// Adds or updates given ``FilterModel`` to storage and posts notification.
    /// - Parameter filter: ``FilterModel``to save.
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

private extension Storage{
    
    /// Creates and saves ``FilterModel``s created by parsing given collection of ``RequestModel``.
    /// Loops through requests while creating dictionaries that corresponds to known filter categories. Dictionaries stores request values as  types that corresonds to category as keys and number of requests that corresponds to type as value. Then creates indivisual ``FilterModel``for category types and saves them to storage.
    /// - Parameter requests: Array of filter requests to parse through.
    func createFilterModel(from requests: [RequestModel]){
        
        var codeDict: [Int: Int] = [:]
        var methodDict: [String: Int] = [:]
        var filterArray: [FilterModel] = []
        
        for request in requests {
            
            if request.code == 0{
                continue
            }
            
            if codeDict[request.code] != nil{
                codeDict[request.code]! += 1
            } else {
                codeDict[request.code] = 1
            }
            if methodDict[request.method] != nil {
                methodDict[request.method]! += 1
            } else {
                methodDict[request.method] = 1
            }
        }
        
        for codeKey in codeDict.keys{
            filterArray.append(.init(filterCategory: .code, value: codeKey, count: codeDict[codeKey] ?? 1))
        }
        
        for methodKey in methodDict.keys{
            filterArray.append(.init(filterCategory: .method, value: methodKey, count: methodDict[methodKey] ?? 1))
        }
        
        for filter in filterArray{
            Storage.shared.saveFilter(filter: filter)
        }
    }
    
}
