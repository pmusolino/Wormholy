//
//  FilterTypeTableViewCell.swift
//  Wormholy-iOS
//
//  Created by Mert Tecimen on 16.02.2023.
//  Copyright © 2023 Wormholy. All rights reserved.
//

import UIKit

class FilterTypeTableViewCell: UITableViewCell {

    
    @IBOutlet weak var indicatorContainerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    
    func populate(title: String, quantity: Int){
        self.titleLabel.text = title
        self.quantityLabel.text = "(\(quantity))"
    }
    
    func setSelectionStatus(with selectionStatus: FilterSelectionStatus){
        switch selectionStatus {
        case .selected:
            self.backgroundColor = .blue
        case .noneSelected, .new:
            self.backgroundColor = .white
        }
    }    
}
