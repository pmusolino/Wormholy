//
//  Wormholy.swift
//  Wormholy
//
//  Created by Paolo Musolino on {TODAY}.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import Foundation
import UIKit

public class Wormholy: NSObject
{
    @objc public static func swiftyLoad() {
        print("Rock 'n' roll!")
        NotificationCenter.default.addObserver(forName: shakeNotification, object: nil, queue: nil) { (notification) in
            Wormholy.presentWormholyFlow()
        }
    }
    
    @objc public static func swiftyInitialize() {
        if self == Wormholy.self{
            Wormholy.enable(true)
        }
    }
    
    static func enable(_ enable: Bool){
        if enable{
            URLProtocol.registerClass(CustomHTTPProtocol.self)
        }
        else{
            URLProtocol.unregisterClass(CustomHTTPProtocol.self)
        }
    }
    
    @objc public static func enable(_ enable: Bool, sessionConfiguration: URLSessionConfiguration){
        
        // Runtime check to make sure the API is available on this version
        if sessionConfiguration.responds(to: #selector(getter: URLSessionConfiguration.protocolClasses)) && sessionConfiguration.responds(to: #selector(setter: URLSessionConfiguration.protocolClasses)){
            var urlProtocolClasses = sessionConfiguration.protocolClasses
            let protoCls = CustomHTTPProtocol.self
            
            guard urlProtocolClasses != nil else{
                return
            }
            
            let index = urlProtocolClasses?.index(where: { (obj) -> Bool in
                if obj == protoCls{
                    return true
                }
                return false
            })
            
            if enable && index == nil{
                urlProtocolClasses!.insert(protoCls, at: 0)
            }
            else if !enable && index != nil{
                urlProtocolClasses!.remove(at: index!)
            }
            sessionConfiguration.protocolClasses = urlProtocolClasses
        }
        else{
            print("[Wormholy] is only available when running on iOS9+")
        }
    }
    
    // MARK: - Navigation
    static func presentWormholyFlow(){
        let storyboard = UIStoryboard(name: "Flow", bundle: WHBundle.getBundle())
        if let initialVC = storyboard.instantiateInitialViewController(){
            UIViewController.currentViewController()?.present(initialVC, animated: true, completion: nil)
        }
    }
}
