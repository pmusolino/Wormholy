//
//  RequestDetailViewController.swift
//  Wormholy-iOS
//
//  Created by Paolo Musolino on 15/04/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import UIKit

class RequestDetailViewController: BaseViewController {

    @IBOutlet weak var tableView: WHTableView!
    
    var request: RequestModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
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

extension RequestDetailViewController: UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
    }
   
}

extension RequestDetailViewController: UITableViewDelegate{
    
}
