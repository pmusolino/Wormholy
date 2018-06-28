//
//  ViewController.swift
//  WormholyDemo
//
//  Created by Paolo Musolino on 11/04/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import UIKit
import Foundation

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 10.0, *) {
            let timer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { (timer) in
                DataFetcher.sharedInstance.getPost(id: Utils.random(max: 128), completion: {
                    print("API: Get post")
                }) { (error) in
                    print("ERROR: api Get post")
                }
            }
            timer.fire()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK: - Actions
    @IBAction func getPostsButtonPressed(_ sender: Any) {
        DataFetcher.sharedInstance.getPost(id: 1, completion: {
            print("API: Get post")
        }) { (error) in
            print("ERROR: api Get post")
        }
    }
    
    @IBAction func newRandomPostButtonPressed(_ sender: Any) {
        DataFetcher.sharedInstance.newPost(userId: Utils.random(max: 5000), title: Utils.random(128), body: Utils.random(5000), completion: {
            print("API: New post")
        }) { (error) in
            print("ERROR: api New post")
        }
    }
    
    @IBAction func getWrongURLButtonPressed(_ sender: Any) {
        DataFetcher.sharedInstance.getWrongURL( completion: {
            print("API: Wrong URL")
        }) { (error) in
            print("ERROR: api Wrong URL")
        }
    }

    @IBAction func getPhotosButtonPressed(_ sender: Any) {
        DataFetcher.sharedInstance.getPhotosList(completion: {
            print("API: Get photos")
        }) { (error) in
            print("ERROR: api Get photos")
        }
    }
}

