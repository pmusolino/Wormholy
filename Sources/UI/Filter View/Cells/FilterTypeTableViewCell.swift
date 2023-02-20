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
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
