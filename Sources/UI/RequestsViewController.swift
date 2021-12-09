//
//  RequestsViewController.swift
//  Wormholy-iOS
//
//  Created by Paolo Musolino on 13/04/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import UIKit

class RequestsViewController: WHBaseViewController {
    
    @IBOutlet weak var collectionView: WHCollectionView!
    var filteredRequests: [RequestModel] = []
    var searchController: UISearchController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addSearchController()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "More", style: .plain, target: self, action: #selector(openActionSheet(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        
        collectionView?.register(UINib(nibName: "RequestCell", bundle:WHBundle.getBundle()), forCellWithReuseIdentifier: "RequestCell")
        
        filteredRequests = Storage.shared.requests
        NotificationCenter.default.addObserver(forName: newRequestNotification, object: nil, queue: nil) { [weak self] (notification) in
            DispatchQueue.main.sync { [weak self] in
                self?.filteredRequests = self?.filterRequests(text: self?.searchController?.searchBar.text) ?? []
                self?.collectionView.reloadData()
            }
        }
        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (context) in
            //Place code here to perform animations during the rotation.
            
        }) { (completionContext) in
            //Code here will execute after the rotation has finished.
            (self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize = CGSize(width: UIScreen.main.bounds.width, height: 76)
            self.collectionView.reloadData()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //  MARK: - Search
    func addSearchController(){
        searchController = UISearchController(searchResultsController: nil)
        searchController?.searchResultsUpdater = self
        if #available(iOS 9.1, *) {
            searchController?.obscuresBackgroundDuringPresentation = false
        } else {
            // Fallback
        }
        searchController?.searchBar.placeholder = "Search URL"
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
        } else {
            navigationItem.titleView = searchController?.searchBar
        }
        definesPresentationContext = true
    }
    
    func filterRequests(text: String?) -> [RequestModel]{
        guard text != nil && text != "" else {
            return Storage.shared.requests
        }
        
        return Storage.shared.requests.filter { (request) -> Bool in
            return (request.url.range(of: text!, options: .caseInsensitive) != nil || request.headers["X-APOLLO-OPERATION-NAME"]?.range(of: text!, options: .caseInsensitive) != nil) ? true : false
        }
    }
    
    // MARK: - Actions
    @objc func openActionSheet(_ sender: UIBarButtonItem){
        let ac = UIAlertController(title: "Wormholy", message: "Choose an option", preferredStyle: .actionSheet)
        
        ac.addAction(UIAlertAction(title: "Clear", style: .default) { [weak self] (action) in
            self?.clearRequests()
        })
        ac.addAction(UIAlertAction(title: "Share", style: .default) { [weak self] (action) in
            self?.shareContent(sender)
        })
        
        ac.addAction(UIAlertAction(title: "Share as cURL", style: .default) { [weak self] (action) in
            self?.shareContent(sender, requestExportOption: .curl)
        })
        ac.addAction(UIAlertAction(title: "Share as Postman Collection", style: .default) { [weak self] (action) in
            self?.shareContent(sender, requestExportOption: .postman)
        })
        ac.addAction(UIAlertAction(title: "Change server", style: .default) { [weak self] (action) in
            self?.replaceServer()
        })
        ac.addAction(UIAlertAction(title: "Change locale", style: .default) { [weak self] (action) in
            self?.changeLocale()
        })
        ac.addAction(UIAlertAction(title: "ChangeMode", style: .default, handler: { [weak self] (action) in
            NotificationCenter.default.post(name: NSNotification.Name("kWormholyRequestChangeMode"), object: nil, userInfo: nil)
        }))
        ac.addAction(UIAlertAction(title: "Close", style: .cancel) { (action) in
        })
        if UIDevice.current.userInterfaceIdiom == .pad {
            ac.popoverPresentationController?.barButtonItem = sender
        }
        present(ac, animated: true, completion: nil)
    }
    
    func replaceServer() {
        navigationController?.pushViewController(ChangeServerViewController(), animated: true)
    }
    
    func changeLocale() {
        NotificationCenter.default.post(name: NSNotification.Name("kWormholyRequestChangeLocale"), object: nil, userInfo: nil)
    }
    
    func clearRequests() {
        Storage.shared.clearRequests()
        filteredRequests = Storage.shared.requests
        collectionView.reloadData()
    }
    
    func shareContent(_ sender: UIBarButtonItem, requestExportOption: RequestResponseExportOption = .flat){
        ShareUtils.shareRequests(presentingViewController: self, sender: sender, requests: filteredRequests, requestExportOption: requestExportOption)
    }
    
    // MARK: - Navigation
    @objc func done(){
        self.dismiss(animated: true, completion: nil)
    }
    
    func openRequestDetailVC(request: RequestModel){
        let storyboard = UIStoryboard(name: "Flow", bundle: WHBundle.getBundle())
        if let requestDetailVC = storyboard.instantiateViewController(withIdentifier: "RequestDetailViewController") as? RequestDetailViewController{
            requestDetailVC.request = request
            self.show(requestDetailVC, sender: self)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: newRequestNotification, object: nil)
    }
}

extension RequestsViewController: UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredRequests.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RequestCell", for: indexPath) as! RequestCell
        
        cell.populate(request: filteredRequests[indexPath.item])
        return cell
    }
}

extension RequestsViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        openRequestDetailVC(request: filteredRequests[indexPath.item])
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 76)
    }
}

// MARK: - UISearchResultsUpdating Delegate
extension RequestsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filteredRequests = filterRequests(text: searchController.searchBar.text)
        collectionView.reloadData()
    }
}
