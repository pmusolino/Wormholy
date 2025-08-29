//
//  Section.swift
//  Wormholy-iOS
//
//  Created by Paolo Musolino on 18/04/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import UIKit

struct Section {
    var name: String
    var type: SectionType
    
    init(name: String, type: SectionType) {
        self.name = name
        self.type = type
    }
}

enum SectionType {
    case overview
    case requestHeader
    case requestBody
    case responseHeader
    case responseBody
}
