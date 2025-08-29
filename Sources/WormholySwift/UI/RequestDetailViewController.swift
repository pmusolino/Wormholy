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
    
    var labelTextColor: UIColor {
        if #available(iOS 13.0, *) {
            return .label
        } else {
            return .black
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let urlString = request?.url{
            title = URL(string: urlString)?.path
        }
        
        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(openActionSheet(_:)))
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
    
    // MARK: - Actions
    @objc func openActionSheet(_ sender: UIBarButtonItem){
        let ac = UIAlertController(title: "Wormholy", message: "Choose an option", preferredStyle: .actionSheet)
        
        ac.addAction(UIAlertAction(title: "Share", style: .default) { [weak self] (action) in
            self?.shareContent(sender)
        })
        ac.addAction(UIAlertAction(title: "Share (request as cURL)", style: .default) { [weak self] (action) in
            self?.shareContent(sender, requestExportOption: .curl)
        })
        ac.addAction(UIAlertAction(title: "Share as Postman Collection", style: .default) { [weak self] (action) in
            self?.shareContent(sender, requestExportOption: .postman)
        })
        ac.addAction(UIAlertAction(title: "Close", style: .cancel) { (action) in
        })
        if UIDevice.current.userInterfaceIdiom == .pad {
            ac.popoverPresentationController?.barButtonItem = sender
        }
        present(ac, animated: true, completion: nil)
    }
    
    func shareContent(_ sender: UIBarButtonItem, requestExportOption: RequestResponseExportOption = .flat){
        if let request = request{
            ShareUtils.shareRequests(presentingViewController: self, sender: sender, requests: [request], requestExportOption: requestExportOption)
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
                cell.textView.attributedText = RequestModelBeautifier.overview(request: req).chageTextColor(to: labelTextColor)
                return cell
            case .requestHeader:
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextTableViewCell", for: indexPath) as! TextTableViewCell
                cell.textView.attributedText = RequestModelBeautifier.header(req.headers).chageTextColor(to: labelTextColor)
                return cell
            case .requestBody:
                let cell = tableView.dequeueReusableCell(withIdentifier: "ActionableTableViewCell", for: indexPath) as! ActionableTableViewCell
                cell.labelAction?.text = "View body"
                return cell
            case .responseHeader:
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextTableViewCell", for: indexPath) as! TextTableViewCell
                cell.textView.attributedText = RequestModelBeautifier.header(req.responseHeaders).chageTextColor(to: labelTextColor)
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
            openBodyDetailVC(title: "Request Body", body: request?.httpBody)
            break
        case .responseBody:
            openBodyDetailVC(title: "Response Body", body: request?.dataResponse)
            break
        default:
            break
        }
    }
}
