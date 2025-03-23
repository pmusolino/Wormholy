//
//  Wormholy.swift
//  Wormholy
//
//  Created by Alex Kovalov.
//  Copyright © 2025 Wormholy. All rights reserved.
//

import UIKit
import SwiftUI

extension UIViewController {

    static func currentViewController(_ viewController: UIViewController? = UIApplication.shared.windows.filter(\.isKeyWindow).first?.rootViewController) -> UIViewController? {
        guard let viewController else { return nil }

        if let viewController = viewController as? UINavigationController {
            // In the navigation controller, the visible view controller can be at the top of the navigation stack
            // or that was presented modally on top of the navigation controller itself
            if let viewController = viewController.visibleViewController {
                return currentViewController(viewController)
            } else {
                return currentViewController(viewController.topViewController)
            }

        } else if let viewController = viewController as? UITabBarController {
            // In the tab bar controller, the visible view controller can be selected in the tab bar
            // or that was presented modally on top of the tab bar controller itself using more tab
            if let viewControllers = viewController.viewControllers, viewControllers.count > 5, viewController.selectedIndex >= 4 {
                return currentViewController(viewController.moreNavigationController)
            } else {
                return currentViewController(viewController.selectedViewController)
            }

        } else if let viewController = viewController.presentedViewController {
            // Presented view controller is the view controller that was presented modally on top of the current view controller
            // It can be any of the subclass types of UIViewController
            return currentViewController(viewController)

        } else if viewController.isHosting {
            // UIKit uses UIHostingController to manage a SwiftUI view hierarchy
            return viewController

        } else if viewController.children.count > 0 {
            // When a view controller is a container for other child view controllers
            return currentViewController(viewController.children.first)

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
