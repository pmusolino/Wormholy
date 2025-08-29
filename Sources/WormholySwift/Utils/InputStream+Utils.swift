//
//  InputStream+Utils.swift
//  Wormholy-iOS
//
//  Created by Paolo Musolino on 14/12/2020.
//  Copyright © 2020 Wormholy. All rights reserved.
//

import Foundation

extension InputStream {
    func readfully() -> Data {
        var result = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        
        open()
        
        var amount = 0
        repeat {
            amount = read(&buffer, maxLength: buffer.count)
            if amount > 0 {
                result.append(buffer, count: amount)
            }
        } while amount > 0
        
        close()
        
        return result
    }
}
