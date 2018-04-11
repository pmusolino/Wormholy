//
//  Utils.swift
//  WormholyDemo
//
//  Created by Paolo Musolino on 11/04/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import UIKit

class Utils: NSObject {
    
    static func random(max maxNumber: Int) -> Int {
        return Int(arc4random_uniform(UInt32(maxNumber)))
    }
    
    static func random(_ maxLenght: Int) -> String{
        let pswdChars = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890 ")
        let rndPswd = String((0..<maxLenght).map{ _ in pswdChars[Int(arc4random_uniform(UInt32(pswdChars.count)))]})
        return rndPswd
    }
}
