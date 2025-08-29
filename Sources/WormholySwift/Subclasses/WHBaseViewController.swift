//
//  BaseViewController.swift
//  Wormholy-iOS
//
//  Created by Paolo Musolino on 13/04/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import UIKit

class WHBaseViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Loader
    func showLoader(view: UIView) -> UIView{
        //LoaderView with view size, with indicator placed on center of loaderView
        let loaderView = UIView(frame: view.bounds)
        loaderView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
        let indicator: UIActivityIndicatorView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
        indicator.center = loaderView.center
        loaderView.addSubview(indicator)
        view.addSubview(loaderView)
        indicator.startAnimating()
        loaderView.bringSubviewToFront(view)
        return loaderView
    }
    
    func hideLoader(loaderView: UIView?){
        loaderView?.removeFromSuperview()
    }
    
}

extension UIViewController{
    static func currentViewController(_ viewController: UIViewController? = UIApplication.shared.windows.filter(\.isKeyWindow).first?.rootViewController) -> UIViewController? {
        guard let viewController = viewController else { return nil }
        
        if let viewController = viewController as? UINavigationController {
            if let viewController = viewController.visibleViewController {
                return currentViewController(viewController)
            } else {
                return currentViewController(viewController.topViewController)
            }
        } else if let viewController = viewController as? UITabBarController {
            if let viewControllers = viewController.viewControllers, viewControllers.count > 5, viewController.selectedIndex >= 4 {
                return currentViewController(viewController.moreNavigationController)
            } else {
                return currentViewController(viewController.selectedViewController)
            }
        } else if let viewController = viewController.presentedViewController {
            return currentViewController(viewController)
        } else if viewController.children.count > 0 {
            return viewController.children[0]
        } else {
            return viewController
        }
    }
    
    open override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        //Shake shake
        if motion == .motionShake && Wormholy.shakeEnabled {
            NotificationCenter.default.post(name: fireWormholy, object: nil)
        }
        
        next?.motionBegan(motion, with: event)
    }
}
