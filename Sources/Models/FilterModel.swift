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

/// Selection status of new ``FilterModel`` can be "selected" and "noneSelected" for previously existing ones and "new" for newly introduced ``FilterModel``.
enum FilterSelectionStatus{
    case selected, noneSelected, new
}

open class FilterModel: Comparable{
    public static func < (lhs: FilterModel, rhs: FilterModel) -> Bool {
        lhs.name < rhs.name
    }
    
    public static func == (lhs: FilterModel, rhs: FilterModel) -> Bool {
        lhs.name == rhs.name && lhs.filterCategory == rhs.filterCategory
    }
    var name: String
    var value: any Equatable
    var filterCategory: FilterCategory
    var count: Int = 1
    var selectionStatus: FilterSelectionStatus
    
    init(name: String? = nil, filterCategory: FilterCategory, value: any Equatable, count: Int = 1, selectionStatus: FilterSelectionStatus = .new) {
        self.name = name ?? String(describing: value)
        self.filterCategory = filterCategory
        self.value = value
        self.count = count
        self.selectionStatus = selectionStatus
    }
}

open class FilterCollectionModel{
    var filterCollection: [FilterModel]
    
    var selectedFilterCollection: [FilterModel]{
        filterCollection.filter{ filterModel -> Bool in
            filterModel.selectionStatus == .selected
        }
    }
    
    var selectedMethodFilterCollection: [String]{
        getSelectedFilterCollection(by: .method) as! [String]
    }
    
    var selectedCodeFilterCollection: [Int]{
        getSelectedFilterCollection(by: .code) as! [Int]
    }
    
    init(filterCollection: [FilterModel]) {
        self.filterCollection = filterCollection
    }
    
    /// Returns collection of any Equatable from current filter collection that matches with given filter category.
    /// - Parameter filterCategory: ``FilterCategory`` type that filter collection element must conform.
    /// - Returns: Filtered filter colelction values as array.
    func getFilterCollection(by filterCategory: FilterCategory) -> [any Equatable]{
        return filterCollection.filter{ filterModel -> Bool in
            filterModel.filterCategory == filterCategory
        }.map{ filterModel -> any Equatable in
            filterModel.value
        }
    }
    
    /// Returns collection of any Equatable from current filter collection that matches with given filter category and selected status.
    /// - Parameter filterCategory: ``FilterCategory`` type that filter collection element must conform.
    /// - Returns: Filtered filter colelction values as array.
    private func getSelectedFilterCollection(by filterCategory: FilterCategory) -> [any Equatable]{
        return filterCollection.filter{ filterModel -> Bool in
            filterModel.filterCategory == filterCategory && filterModel.selectionStatus == .selected
        }.map{ filterModel -> any Equatable in
            filterModel.value
        }
    }
}
