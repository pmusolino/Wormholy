//
//  RequestsViewController.swift
//  Wormholy-iOS
//
//  Created by Paolo Musolino on 13/04/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import UIKit

class RequestsViewController: BaseViewController {
    
    @IBOutlet weak var collectionView: WHCollectionView!
    var filteredRequests: [RequestModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addSearchController()
        
        navigationItem.rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))]
        
        collectionView?.register(UINib(nibName: "RequestCell", bundle:WHBundle.getBundle()), forCellWithReuseIdentifier: "RequestCell")
        if let flowLayout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout{
            flowLayout.itemSize = CGSize(width: UIScreen.main.bounds.size.width, height: 76)
        }
        
        filteredRequests = Storage.shared.requests
        NotificationCenter.default.addObserver(forName: newRequestNotification, object: nil, queue: nil) { [weak self] (notification) in
            DispatchQueue.main.sync {
                self?.filteredRequests = Storage.shared.requests
                self?.collectionView.reloadData()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //  MARK: - Search
    func addSearchController(){
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        if #available(iOS 9.1, *) {
            searchController.obscuresBackgroundDuringPresentation = false
        } else {
            // Fallback
        }
        searchController.searchBar.placeholder = "Search inside requests content"
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
        } else {
            navigationItem.titleView = searchController.searchBar
        }
        definesPresentationContext = true
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

extension RequestsViewController: UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        openRequestDetailVC(request: filteredRequests[indexPath.item])
    }
}

// MARK: - UISearchResultsUpdating Delegate
extension RequestsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        // TODO
    }
}
