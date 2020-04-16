//
//  RequestDetailViewController.swift
//  Wormholy-iOS
//
//  Created by Paolo Musolino on 15/04/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import UIKit

class RequestDetailViewController: WHBaseViewController {
    
    @IBOutlet weak var tableView: WHTableView!
    
    var request: RequestModel?
    var sections: [Section] = [
        Section(name: "Overview", type: .overview),
        Section(name: "Request Header", type: .requestHeader),
        Section(name: "Request Body", type: .requestBody),
        Section(name: "Response Header", type: .responseHeader),
        Section(name: "Response Body", type: .responseBody)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let urlString = request?.url{
            title = URL(string: urlString)?.path
        }
        
        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareContent(_:)))
        navigationItem.rightBarButtonItems = [shareButton]
        
        tableView.estimatedRowHeight = 100.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "TextTableViewCell", bundle:WHBundle.getBundle()), forCellReuseIdentifier: "TextTableViewCell")
        tableView.register(UINib(nibName: "ActionableTableViewCell", bundle:WHBundle.getBundle()), forCellReuseIdentifier: "ActionableTableViewCell")
        tableView.register(UINib(nibName: "RequestTitleSectionView", bundle:WHBundle.getBundle()), forHeaderFooterViewReuseIdentifier: "RequestTitleSectionView")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func shareContent(_ sender: UIBarButtonItem){
        if let request = request{
            let textShare = [RequestModelBeautifier.txtExport(request: request)]
            let customItem = CustomActivity(title: "Save to the desktop", image: UIImage(named: "activity_icon", in: WHBundle.getBundle(), compatibleWith: nil)) { (sharedItems) in
                guard let sharedStrings = sharedItems as? [String] else { return }
                
                for string in sharedStrings {
                    FileHandler.writeTxtFileOnDesktop(text: string, fileName: "\(Int(Date().timeIntervalSince1970))-wormholy.txt")
                }
            }
            let activityViewController = UIActivityViewController(activityItems: textShare, applicationActivities: [customItem])
            activityViewController.popoverPresentationController?.barButtonItem = sender
            self.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Navigation
    func openBodyDetailVC(title: String?, body: Data?){
        let storyboard = UIStoryboard(name: "Flow", bundle: WHBundle.getBundle())
        if let requestDetailVC = storyboard.instantiateViewController(withIdentifier: "BodyDetailViewController") as? BodyDetailViewController{
            requestDetailVC.title = title
            requestDetailVC.data = body
            self.show(requestDetailVC, sender: self)
        }
    }
    
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
        
        let section = sections[indexPath.section]
        if let req = request{
            switch section.type {
            case .overview:
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextTableViewCell", for: indexPath) as! TextTableViewCell
                cell.textView.attributedText = RequestModelBeautifier.overview(request: req)
                return cell
            case .requestHeader:
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextTableViewCell", for: indexPath) as! TextTableViewCell
                cell.textView.attributedText = RequestModelBeautifier.header(req.headers)
                return cell
            case .requestBody:
                let cell = tableView.dequeueReusableCell(withIdentifier: "ActionableTableViewCell", for: indexPath) as! ActionableTableViewCell
                cell.labelAction?.text = "View body"
                return cell
            case .responseHeader:
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextTableViewCell", for: indexPath) as! TextTableViewCell
                cell.textView.attributedText = RequestModelBeautifier.header(req.responseHeaders)
                return cell
            case .responseBody:
                let cell = tableView.dequeueReusableCell(withIdentifier: "ActionableTableViewCell", for: indexPath) as! ActionableTableViewCell
                cell.labelAction?.text = "View body"
                return cell
            }
        }
        
        return UITableViewCell()
    }
    
}

extension RequestDetailViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        
        switch section.type {
        case .requestBody:
            openBodyDetailVC(title: "Request body", body: request?.httpBody)
            break
        case .responseBody:
            openBodyDetailVC(title: "Response body", body: request?.dataResponse)
            break
        default:
            break
        }
    }
}
