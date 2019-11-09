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
        
        UINavigationBar.appearance(whenContainedInInstancesOf: [WHBaseViewController.self, WHNavigationController.self]).backgroundColor = nil
        UINavigationBar.appearance(whenContainedInInstancesOf: [WHBaseViewController.self, WHNavigationController.self]).tintColor = nil
        UINavigationBar.appearance(whenContainedInInstancesOf: [WHBaseViewController.self, WHNavigationController.self]).isTranslucent = false
        
        // Always adopt a light interface style.
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        if #available(iOS 11.0, *) {
            navigationBar.prefersLargeTitles = true
            navigationItem.largeTitleDisplayMode = .automatic
        }
        //navigationBar.isTranslucent = true
        //navigationBar.backgroundColor = .white
        
       // navigationBar.tintColor = .black
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
