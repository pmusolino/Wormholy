//
//  NavigationController.swift
//  Wormholy-iOS
//
//  Created by Paolo Musolino on 13/04/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import UIKit

class WHNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Always adopt a light interface style.
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        //Large titles
        if #available(iOS 11.0, *) {
            navigationBar.prefersLargeTitles = true
            navigationItem.largeTitleDisplayMode = .automatic
        }
        
        // Appearance
        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.black]
            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
            navBarAppearance.backgroundColor = Colors.Gray.lighestGray
            navigationBar.standardAppearance = navBarAppearance
            navigationBar.scrollEdgeAppearance = navBarAppearance
            navigationBar.tintColor = .blue
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
