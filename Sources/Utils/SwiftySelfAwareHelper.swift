//
//  SwiftySelfAwareHelper.swift
//  Wormholy
//
//  Created by Kealdish on 2019/2/28.
//  Copyright © 2019 Wormholy. All rights reserved.
//

import Foundation
import UIKit

protocol SelfAware: class {
    static func awake()
}

struct CustomSelfAwareHelper {
    
    static func harmlessFunction() {
        
        // Get all class list through runtime
        let typeCount = Int(objc_getClassList(nil, 0))
        let types = UnsafeMutablePointer<AnyClass>.allocate(capacity: typeCount)
        let autoreleasingTypes = AutoreleasingUnsafeMutablePointer<AnyClass>(types)
        objc_getClassList(autoreleasingTypes, Int32(typeCount))
        
        for index in 0 ..< typeCount {
            (types[index] as? SelfAware.Type)?.awake()
        }
        
        types.deallocate()
    }
}

// The class used by StarterEnginer (objc) to start all the process.
class StarterEngine: NSObject {
    @objc static func appWillLaunch(_: Notification) {
        CustomSelfAwareHelper.harmlessFunction()
    }
}
