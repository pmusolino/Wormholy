//
//  Wormholy.swift
//  Wormholy
//
//  Created by Paolo Musolino.
//  Copyright © 2025 Wormholy. All rights reserved.
//

import UIKit
import SwiftUI

extension UIViewController {

    static func currentViewController(_ viewController: UIViewController? = UIApplication.shared.windows.filter(\.isKeyWindow).first?.rootViewController) -> UIViewController? {
        guard let viewController else { return nil }

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
        } else if viewController.isHosting {
            return viewController
        } else if viewController.children.count > 0 {
            return viewController.children[0]
        } else {
            return viewController
        }
    }
}

extension UIViewController {

var isHosting: Bool {
    let className = NSStringFromClass(type(of: self))
    if className.contains("UIHostingController") {
        return true
    }
    
    // Check superclass hierarchy to catch subclasses
    var currentClass: AnyClass? = type(of: self)
    while let superclass = currentClass?.superclass() {
        if NSStringFromClass(superclass).contains("UIHostingController") {
            return true
        }
        currentClass = superclass
    }
    
    return false
}
}
