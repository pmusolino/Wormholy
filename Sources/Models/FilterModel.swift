//
//  FilterModel.swift
//  Wormholy-iOS
//
//  Created by Mert Tecimen on 16.02.2023.
//  Copyright © 2023 Wormholy. All rights reserved.
//

import Foundation

struct FilterModel{
    var categories: [FilterCategory]
}


struct FilterCategory{
    var name: String
    var filterType: [FilterType]
}

struct FilterType{
    var name: String
    var value: any Equatable
    var count: Int
    
    init(name: String? = nil, value: any Equatable, count: Int) {
        self.name = name ?? String(describing: value)
        self.value = value
        self.count = count
    }
    
}
