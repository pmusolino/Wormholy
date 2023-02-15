//
//  Interfaces.swift
//  Wormholy-iOS
//
//  Created by Mert Tecimen on 15.02.2023.
//  Copyright © 2023 Wormholy. All rights reserved.
//

import UIKit

protocol WHReusableView {
    static var reuseIdentifier: String {get}
}

extension WHReusableView{
    static var reuseIdentifier: String{
        return String(describing: self)
    }
}


// MARK: UITableViewCell Extension

extension UITableViewCell: WHReusableView {}

extension UITableViewHeaderFooterView: WHReusableView {}

// MARK: UICollectionViewCell Extension

extension UICollectionReusableView: WHReusableView {}
