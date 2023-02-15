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
    
    private var filterModel: [Any] = []
    
    
    private lazy var tableView: WHTableView = {
       let tableView = WHTableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        let tableViewcell = UINib(nibName: "FilterCategoryTableViewCell", bundle: nil)
        tableView.register(tableViewcell, forCellReuseIdentifier: FilterCategoryTableViewCell.reuseIdentifier)
        self.view.addSubview(self.tableView)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.separatorStyle = .singleLine
        self.tableView.separatorInset = .zero
        return tableView
    }()
    
    override func viewWillLayoutSubviews() {
        self.preferredContentSize = .init(width: 200, height: filterModel.count * Int(FilterViewController.cellHeight))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
}

extension FilterViewController: UITableViewDelegate{
    
}

extension FilterViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filterModel.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FilterCategoryTableViewCell.reuseIdentifier, for: indexPath) as! FilterCategoryTableViewCell
        
        cell.populate(title: "Name")
        return cell
    }
}
