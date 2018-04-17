//
//  TextTableViewCell.swift
//  Wormholy-iOS
//
//  Created by Paolo Musolino on 17/04/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import UIKit

class TextTableViewCell: UITableViewCell {

    @IBOutlet weak var textView: WHTextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
