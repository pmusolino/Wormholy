//
//  FilterModel.swift
//  Wormholy-iOS
//
//  Created by Mert Tecimen on 16.02.2023.
//  Copyright © 2023 Wormholy. All rights reserved.
//

import Foundation


enum FilterCategory: CaseIterable{
    case code, method
    
    var description: String{
        switch self {
        case .code:
            return "Code"
        case .method:
            return "Method"
        }
    }
}

struct FilterModel{
    var name: String
    var value: any Equatable
    var filterCategory: FilterCategory
    var count: Int = 1
    var isSelected: Bool = false
    
    init(name: String? = nil, filterCategory: FilterCategory, value: any Equatable, count: Int = 1) {
        self.name = name ?? String(describing: value)
        self.filterCategory = filterCategory
        self.value = value
        self.count = count
    }
    
}
