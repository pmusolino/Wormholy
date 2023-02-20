//
//  FilterTypeViewController.swift
//  Wormholy-iOS
//
//  Created by Mert Tecimen on 16.02.2023.
//  Copyright © 2023 Wormholy. All rights reserved.
//

import UIKit

class FilterTypeViewController: UIViewController {

    private var cellHeight: CGFloat
    private var filterData: [FilterModel]
    
    
    private lazy var tableView: WHTableView = {
        let tableView = WHTableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        let tableViewcell = UINib(nibName: "FilterTypeTableViewCell", bundle: WHBundle.getBundle())
        tableView.register(tableViewcell, forCellReuseIdentifier: FilterTypeTableViewCell.reuseIdentifier)
        return tableView
    }()
    
    override func viewWillLayoutSubviews() {
        self.preferredContentSize = .init(width: 200, height: filterData.count * Int(self.cellHeight))
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
    init(with FilterData: [FilterModel], _ cellHeight: CGFloat = 50) {
        self.filterData = FilterData
        self.cellHeight = cellHeight
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder, with FilterData: [FilterModel], _ cellHeight: CGFloat = 50) {
        self.filterData = FilterData
        self.cellHeight = cellHeight
        super.init(coder: aDecoder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension FilterTypeViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        self.cellHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

extension FilterTypeViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filterData.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FilterTypeTableViewCell.reuseIdentifier, for: indexPath) as! FilterTypeTableViewCell
        
        let cellData = filterData[indexPath.item]
        
        cell.populate(title: cellData.name, quantity: cellData.count)
        return cell
    }
}
