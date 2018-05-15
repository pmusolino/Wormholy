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
    var sections: [Section] = [
        Section(name: "Overview", type: .overview),
        Section(name: "Header", type: .header),
        Section(name: "Request Body", type: .requestBody),
        Section(name: "Response Body", type: .responseBody)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let urlString = request?.url{
            title = URL(string: urlString)?.path
        }
        
        tableView.estimatedRowHeight = 100.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(UINib(nibName: "TextTableViewCell", bundle:WHBundle.getBundle()), forCellReuseIdentifier: "TextTableViewCell")
        tableView.register(UINib(nibName: "RequestTitleSectionView", bundle:WHBundle.getBundle()), forHeaderFooterViewReuseIdentifier: "RequestTitleSectionView")
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
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "RequestTitleSectionView") as! RequestTitleSectionView
        header.contentView.backgroundColor = Colors.Gray.lighestGray
        header.titleLabel.text = sections[section].name
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TextTableViewCell", for: indexPath) as! TextTableViewCell
        
        let section = sections[indexPath.section]
        if let req = request{
            switch section.type {
            case .overview:
                cell.textView.attributedText = RequestModelBeautifier.overview(request: req)
                break
            case .header:
                cell.textView.attributedText = RequestModelBeautifier.header(request: req)
            case .requestBody:
                cell.textView.attributedText = RequestModelBeautifier.body(request: req)
            case .responseBody:
                cell.textView.attributedText = RequestModelBeautifier.responseBody(request: req)
            }
        }
        else{
            cell.textView.text = "-"
        }
        
        return cell
    }
   
}

extension RequestDetailViewController: UITableViewDelegate{
    
}
