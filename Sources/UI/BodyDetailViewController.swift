//
//  BodyDetailViewController.swift
//  Wormholy-iOS
//
//  Created by Paolo Musolino on 10/07/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import UIKit

class BodyDetailViewController: WHBaseViewController {

    @IBOutlet weak var textView: WHTextView!
    var data: Data?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareContent))
        navigationItem.rightBarButtonItems = [shareButton]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let hud = showLoader(view: view)
        RequestModelBeautifier.body(data) { [weak self] (stringData) in
            DispatchQueue.main.sync {
                self?.textView.text = stringData
                self?.hideLoader(loaderView: hud)
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func shareContent(){
        if let text = textView.text{
        let textShare = [text]
        let activityViewController = UIActivityViewController(activityItems: textShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        self.present(activityViewController, animated: true, completion: nil)
        }
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
