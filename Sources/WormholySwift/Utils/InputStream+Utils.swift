//
//  InputStream+Utils.swift
//  Wormholy-iOS
//
//  Created by Paolo Musolino on 14/12/2020.
//  Copyright © 2020 Wormholy. All rights reserved.
//

import Foundation

extension InputStream {
    /// Reads all available data from the InputStream and returns it as a Data object.
    /// This method is utilized in CustomHTTPProtocol.swift to extract the HTTP body
    /// from a request when the body is provided as a stream rather than direct data.
    internal func readfully() -> Data {
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
