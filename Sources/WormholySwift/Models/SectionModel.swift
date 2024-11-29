//
//  SectionModel.swift
//  Wormholy-iOS
//
//  Created by Paolo Musolino on 18/04/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import UIKit

internal struct SectionModel {
    var name: String
    var type: SectionType
    
    init(name: String, type: SectionType) {
        self.name = name
        self.type = type
    }
}

internal enum SectionType {
    case overview
    case requestHeader
    case requestBody
    case responseHeader
    case responseBody
}
