//
//  RequestCell.swift
//  Wormholy-iOS
//
//  Created by Paolo Musolino on 13/04/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import UIKit

class RequestCell: UICollectionViewCell {
    
    @IBOutlet weak var methodLabel: WHLabel!
    @IBOutlet weak var codeLabel: WHLabel!
    @IBOutlet weak var urlLabel: WHLabel!
    @IBOutlet weak var durationLabel: WHLabel!
    
    func populate(request: RequestModel?){
        guard request != nil else {
            return
        }
        
        methodLabel.text = request?.method.uppercased()
        codeLabel.text = request?.code != nil ? String(request!.code) : ""
        urlLabel.text = request?.url
        durationLabel.text = request?.duration != nil ? String(request!.duration!) : ""
    }
}
