//
//  Colors.swift
//  Wormholy-iOS
//
//  Created by Paolo Musolino on 14/04/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import UIKit

struct Colors {
    
    struct Brand{
    }
    
    struct UI{
        static public let wordsInEvidence = UIColor(hexString: "#dadfe1")
        static public let wordFocus = UIColor(hexString: "#f7ca18")
    }
    
    struct Gray{
        static public let darkestGray = UIColor(hexString: "#666666")
        static public let darkerGray = UIColor(hexString: "#888888")
        static public let darkGray = UIColor(hexString: "#999999")
        static public let midGray = UIColor(hexString: "#BBBBBB")
        static public let lightGray = UIColor(hexString: "#CCCCCC")
        static public let lighestGray = UIColor(hexString: "#E7E7E7")
    }
    
    struct HTTPCode{
        static public let Success = UIColor(hexString: "#297E4C") //2xx
        static public let Redirect = UIColor(hexString: "#3D4140") //3xx
        static public let ClientError = UIColor(hexString: "#D97853") //4xx
        static public let ServerError = UIColor(hexString: "#D32C58") //5xx
        static public let Generic = UIColor(hexString: "#999999") //Others
    }
}

extension UIColor{
    
    convenience init(hexString:String) {
        let hexString:String = hexString.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines) as String
        let scanner = Scanner(string: hexString)
        if (hexString.hasPrefix("#")) {
            scanner.scanLocation = 1
        }
        
        var color:UInt32 = 0
        scanner.scanHexInt32(&color)
        
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        self.init(red:red, green:green, blue:blue, alpha:1)
    }
    
    func toHexString() -> String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        return NSString(format:"#%06x", rgb) as String
    }
    
    func randomGreyColor() -> String{
        let value = arc4random_uniform(255)
        let grayscale = (value << 16) | (value << 8) | value;
        let color = "#" + String(grayscale, radix: 16);
        
        return color
    }
}
