//
//  ActionableTableViewCell.swift
//  Wormholy-iOS
//
//  Created by Paolo Musolino on 10/07/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import UIKit

class ActionableTableViewCell: UITableViewCell {

    @IBOutlet weak var labelAction: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
