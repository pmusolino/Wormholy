//
//  ShakeDetectionViewController.swift
//  Wormholy
//
//  Created by Paolo Musolino on 4/12/24.
//

import UIKit

extension UIViewController {
    
    open override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        //Shake shake
        if motion == .motionShake && Wormholy.shakeEnabled {
            NotificationCenter.default.post(name: fireWormholy, object: nil)
        }
        
        next?.motionBegan(motion, with: event)
    }
}
