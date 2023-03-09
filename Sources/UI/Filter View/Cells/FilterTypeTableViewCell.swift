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
    @IBOutlet weak var indicatorView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.indicatorContainerView.layer.borderColor = UIColor.black.cgColor
        self.indicatorContainerView.layer.borderWidth = 1
        self.indicatorContainerView.layer.cornerRadius =
        self.indicatorContainerView.layer.bounds.width / 1.5
        self.indicatorContainerView.clipsToBounds = true
        
        self.indicatorView.layer.cornerRadius = self.indicatorView.layer.bounds.width / 1.5
        self.indicatorView.clipsToBounds = true
        
        self.selectionStyle = .none
    }

    
    func populate(title: String, quantity: Int, selectionStatus: FilterSelectionStatus){
        self.titleLabel.text = title
        self.quantityLabel.text = "(\(quantity))"
        
        switch selectionStatus {
        case .selected:
            self.indicatorView.backgroundColor = .gray
        case .noneSelected, .new:
            self.indicatorView.backgroundColor = .clear
        }
        
    }
    
    func setSelectionStatusWithAnimation(with selectionStatus: FilterSelectionStatus){
        
        switch selectionStatus {
        case .selected:
            UIView.animate(withDuration: 0.2, delay: 0){
                self.indicatorView.backgroundColor = .gray
            }
        case .noneSelected, .new:
            UIView.animate(withDuration: 0.2, delay: 0){
                self.indicatorView.backgroundColor = .clear
            }
        }
    }

}
