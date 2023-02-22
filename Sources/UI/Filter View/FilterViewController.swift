//
//  FilterViewController.swift
//  Wormholy-iOS
//
//  Created by Mert Tecimen on 15.02.2023.
//  Copyright © 2023 Wormholy. All rights reserved.
//

import UIKit

class FilterViewController: UIViewController {

    private static var cellHeight: CGFloat = 50
    
    private var filterModel: [FilterModel] = []
    private var filterCategories: [FilterCategory] = [.code, .method]

    
    
    private lazy var tableView: WHTableView = {
       let tableView = WHTableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        let tableViewcell = UINib(nibName: "FilterCategoryTableViewCell", bundle: WHBundle.getBundle())
        tableView.register(tableViewcell, forCellReuseIdentifier: FilterCategoryTableViewCell.reuseIdentifier)
        return tableView
    }()
    
    override func viewWillLayoutSubviews() {
        self.preferredContentSize = .init(width: 200, height: FilterCategory.allCases.count * Int(FilterViewController.cellHeight))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupTableView()
        self.navigationItem.title = "Filters"
        self.navigationController?.isNavigationBarHidden = false
    }
    
    private func setupTableView(){
        self.view.addSubview(self.tableView)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.separatorStyle = .singleLine
        self.tableView.separatorInset = .zero
    
        self.registerTableViewConstraints()
        
        self.tableView.reloadData()
    }
    
    private func registerTableViewConstraints(){
        NSLayoutConstraint.activate([
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.tableView.widthAnchor.constraint(equalTo: self.view.widthAnchor),
        ])
        
    }
    
    // MARK: - Object lifecycle -
    init(with filterModel: [FilterModel]) {
        self.filterModel = filterModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
}

extension FilterViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        FilterViewController.cellHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = FilterTypeViewController(with: self.filterCategories[indexPath.item])
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension FilterViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        FilterCategory.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FilterCategoryTableViewCell.reuseIdentifier, for: indexPath) as! FilterCategoryTableViewCell
        cell.populate(title: self.filterCategories[indexPath.item].description)
        return cell
    }
}
