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
    var filterCollectionModel: FilterCollectionModel = .init(filterCollection: [])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addSearchController()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "More", style: .plain, target: self, action: #selector(openActionSheet(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        
        collectionView?.register(UINib(nibName: "RequestCell", bundle:WHBundle.getBundle()), forCellWithReuseIdentifier: "RequestCell")
        
        filteredRequests = Storage.shared.requests
        NotificationCenter.default.addObserver(forName: newRequestNotification, object: nil, queue: nil) { [weak self] (notification) in
            DispatchQueue.main.sync { [weak self] in
                self?.filteredRequests = self?.filterRequests(text: self?.searchController?.searchBar.text, filterCollection: self?.filterCollectionModel) ?? []
                self?.collectionView.reloadData()
                
            }
        }
        
        NotificationCenter.default.addObserver(forName: filterChangeNotification, object: nil, queue: nil){ [weak self] (notification) in
            DispatchQueue.main.async{ [weak self] in
                self?.filterCollectionModel = .init(filterCollection: Storage.shared.filters)
                self?.filteredRequests = self?.filterRequests(text: self?.searchController?.searchBar.text, filterCollection: self?.filterCollectionModel) ?? []
                self?.collectionView.reloadData()
            }
        }
        

        /// Handling keyboard notifications
        ///
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                    name: UIResponder.keyboardWillHideNotification, object: nil)
        
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
        if let filter = Storage.defaultFilter {
            searchController?.searchBar.text = filter
        }
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
        } else {
            navigationItem.titleView = searchController?.searchBar
        }
        definesPresentationContext = true
        
        searchController?.searchBar.showsBookmarkButton = true
        if #available(iOS 13.0, *) {
            searchController?.searchBar.setImage(UIImage(systemName: "line.3.horizontal.decrease.circle"), for: .bookmark, state: .normal)
        } else {
            searchController?.searchBar.setImage(UIImage(named: "line.3.horizontal.decrease.circle"), for: .bookmark, state: .normal)
        }
        searchController?.searchBar.delegate = self
        
    }
    
    /// Filters given ``RequestModel``s by given text and ``FilterCollectionModel`` and returns filtered ``RequestModel``s
    /// - Parameters:
    ///   - text: Text evaluate URL strings in ``RequestModel``s.
    ///   - filterCollection: collection of ``FilterModel``s to filter matching variables in ``RequestModel``s.
    /// - Returns: Filtered array of ``RequestModel``s
    func filterRequests(text: String?, filterCollection: FilterCollectionModel?) -> [RequestModel]{
        
        let requests = Storage.shared.requests
        
        var filteredRequests = filterBySearch(text: text, requests: requests)
        filteredRequests = filterByFilterModels(filterCollection: filterCollection, requests: filteredRequests)
        
        return filteredRequests
    }
    
    
    func filterBySearch(text: String?, requests: [RequestModel]) -> [RequestModel]{
        guard text != nil && text != "" else {
            return requests
        }
        return requests.filter { (request) -> Bool in
            return request.url.range(of: text!, options: .caseInsensitive) != nil ? true : false
        }
    }
    
    func filterByFilterModels(filterCollection: FilterCollectionModel?, requests: [RequestModel]) -> [RequestModel]{
        
        guard let filterCollection = filterCollection else{
            return requests
        }
        
        if filterCollection.selectedFilterCollection.isEmpty{
            return requests
        }
        
        // If no selected filter exists for category, contain all of the category filters.
        let codeArray: [Int] = filterCollection.selectedCodeFilterCollection.isEmpty ? filterCollection.getFilterCollection(by: .code) as! [Int] : filterCollection.selectedCodeFilterCollection
        
        let methodArray: [String] = filterCollection.selectedMethodFilterCollection.isEmpty ? filterCollection.getFilterCollection(by: .method) as! [String] : filterCollection.selectedMethodFilterCollection
        
        return requests.filter{ request -> Bool in
            methodArray.contains(request.method) && codeArray.contains(request.code)
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
        ac.addAction(UIAlertAction(title: "Close", style: .cancel) { (action) in
        })
        if UIDevice.current.userInterfaceIdiom == .pad {
            ac.popoverPresentationController?.barButtonItem = sender
        }
        present(ac, animated: true, completion: nil)
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

    // MARK: - Keyboard management
    @objc
    func keyboardWillShow(_ notification: NSNotification) {
        let userInfo = notification.userInfo
        guard let keyboardFrame = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        let contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardFrame.height, right: 0.0)
        collectionView.contentInset = contentInset
        collectionView.scrollIndicatorInsets = contentInset
    }

    @objc
    func keyboardWillHide(_ notification: NSNotification) {
        collectionView.contentInset = .zero
        collectionView.scrollIndicatorInsets = .zero
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
        filteredRequests = filterRequests(text: searchController.searchBar.text, filterCollection: self.filterCollectionModel)
        collectionView.reloadData()
        
        // Hide filter button on search
        searchController.searchBar.showsBookmarkButton = !searchController.isActive
        
    }
}
// MARK: - UISearchBarDelegate Delegate
extension RequestsViewController: UISearchBarDelegate{
    func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar) {
        
        let filterViewController = FilterViewController(with: self.filterCollectionModel.filterCollection)
        
        let filterNavigationController = UINavigationController(rootViewController: filterViewController)
        
        filterNavigationController.modalPresentationStyle = .popover
        let popoverPresentationController = filterNavigationController.popoverPresentationController
        
        popoverPresentationController?.delegate = self
        if #available(iOS 13.0, *) {
            popoverPresentationController?.sourceView = self.searchController?.searchBar.searchTextField.rightView
        } else {
            popoverPresentationController?.sourceView = self.searchController?.searchBar
        }
        self.present(filterNavigationController, animated: true)
       
        print("Bookmark button pressed!")
    }
}

extension RequestsViewController: UIPopoverPresentationControllerDelegate{
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
