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
    @available(*, deprecated, renamed: "ignoredHosts")
    @objc public static var blacklistedHosts: [String] {
        get { return CustomHTTPProtocol.ignoredHosts }
        set { CustomHTTPProtocol.ignoredHosts = newValue }
    }

    /// Hosts that will be ignored from being recorded
    ///
    @objc public static var ignoredHosts: [String] {
        get { return CustomHTTPProtocol.ignoredHosts }
        set { CustomHTTPProtocol.ignoredHosts = newValue }
    }
  
    /// Limit the logging count
    ///
    @objc public static var limit: NSNumber? {
        get { Storage.limit }
        set { Storage.limit = newValue }
    }

    /// Default filter for the search box
    ///
    @objc public static var defaultFilter: String? {
        get { Storage.defaultFilter }
        set { Storage.defaultFilter = newValue }
    }

    @objc public static func swiftyLoad() {
        NotificationCenter.default.addObserver(forName: fireWormholy, object: nil, queue: nil) { (notification) in
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
            
            let index = urlProtocolClasses?.firstIndex(where: { (obj) -> Bool in
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
        guard UIViewController.currentViewController()?.isKind(of: WHBaseViewController.classForCoder()) == false && UIViewController.currentViewController()?.isKind(of: WHNavigationController.classForCoder()) == false else {
            return
        }
        let storyboard = UIStoryboard(name: "Flow", bundle: WHBundle.getBundle())
        if let initialVC = storyboard.instantiateInitialViewController(){
            initialVC.modalPresentationStyle = .fullScreen
            UIViewController.currentViewController()?.present(initialVC, animated: true, completion: nil)
        }
    }
    
    @objc public static var wormholyFlow: UIViewController? {
        let storyboard = UIStoryboard(name: "Flow", bundle: WHBundle.getBundle())
        return storyboard.instantiateInitialViewController()
    }
    
    @objc public static var shakeEnabled: Bool = {
        let key = "WORMHOLY_SHAKE_ENABLED"
        
        if let environmentVariable = ProcessInfo.processInfo.environment[key] {
            return environmentVariable != "NO"
        }
        
        let arguments = UserDefaults.standard.volatileDomain(forName: UserDefaults.argumentDomain)
        if let arg = arguments[key] {
            switch arg {
            case let boolean as Bool: return boolean
            case let string as NSString: return string.boolValue
            case let number as NSNumber: return number.boolValue
            default: break
            }
        }
        
        return true
    }()
}

/// WormholyConstructor calls this to initialize library
extension Wormholy {
    
    @objc static func applicationDidFinishLaunching() {
        initializeAction
    }
    
    private static let initializeAction: Void = {
        swiftyLoad()
        swiftyInitialize()
    }()
}
