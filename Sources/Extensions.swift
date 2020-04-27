//
//  Extensions.swift
//  Wormholy-iOS
//
//  Created by Sagar Dagdu on 4/27/20.
//  Copyright © 2020 Wormholy. All rights reserved.
//

import Foundation

///This file is a centralized place for all the extensions used in the framework.

extension Bundle {
    static var wormholyBundle: Bundle {
        let podBundle = Bundle(for: Wormholy.classForCoder())
        if let bundleURL = podBundle.url(forResource: "Wormholy", withExtension: "bundle"){
            if let bundle = Bundle(url: bundleURL) {
                return bundle
            }
        }
        
        return Bundle(for: Wormholy.classForCoder())
    }
}

extension String {
    //substrings of equal length
    func characters(n: Int) -> String {
        return String(prefix(n))
    }
}

extension Date {
    func stringWithFormat(dateFormat: String, timezone: TimeZone? = nil) -> String?{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        if let timezone = timezone {
            dateFormatter.timeZone = timezone
        }
        return dateFormatter.string(from: self)
    }
}

extension Double {
    func formattedMilliseconds() -> String {
        let rounded = self
        if rounded < 1000 {
            return "\(Int(rounded))ms"
        } else if rounded < 1000 * 60 {
            let seconds = rounded / 1000
            return "\(Int(seconds))s"
        } else if rounded < 1000 * 60 * 60 {
            let secondsTemp = rounded / 1000
            let minutes = secondsTemp / 60
            let seconds = (rounded - minutes * 60 * 1000) / 1000
            return "\(Int(minutes))m \(Int(seconds))s"
        } else if self < 1000 * 60 * 60 * 24 {
            let minutesTemp = rounded / 1000 / 60
            let hours = minutesTemp / 60
            let minutes = (rounded - hours * 60 * 60 * 1000) / 1000 / 60
            let seconds = (rounded - hours * 60 * 60 * 1000 - minutes * 60 * 1000) / 1000
            return "\(Int(hours))h \(Int(minutes))m \(Int(seconds))s"
        } else {
            let hoursTemp = rounded / 1000 / 60 / 60
            let days = hoursTemp / 24
            let hours = (rounded - days * 24 * 60 * 60 * 1000) / 1000 / 60 / 60
            let minutes = (rounded - days * 24 * 60 * 60 * 1000 - hours * 60 * 60 * 1000) / 1000 / 60
            let seconds = (rounded - days * 24 * 60 * 60 * 1000 - hours * 60 * 60 * 1000 - minutes * 60 * 1000) / 1000
            return "\(Int(days))d \(Int(hours))h \(Int(minutes))m \(Int(seconds))s"
        }
    }
}

extension UIStoryboard {
    static var wormholyStoryboard: UIStoryboard {
        return UIStoryboard(name: "Flow", bundle: Bundle.wormholyBundle)
    }
}
