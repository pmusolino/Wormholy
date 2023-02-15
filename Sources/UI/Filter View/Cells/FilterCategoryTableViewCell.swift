//
//  FilterCategoryTableViewCell.swift
//  Wormholy-iOS
//
//  Created by Mert Tecimen on 15.02.2023.
//  Copyright © 2023 Wormholy. All rights reserved.
//

import UIKit

class FilterCategoryTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: WHLabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func populate(title: String){
        self.titleLabel.text = title
    }
    
}
