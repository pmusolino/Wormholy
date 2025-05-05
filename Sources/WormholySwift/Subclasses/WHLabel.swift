//
//  WHLabel.swift
//  Wormholy-iOS
//
//  Created by Paolo Musolino on 13/04/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import UIKit

@IBDesignable
class WHLabel: UILabel {

    @IBInspectable var borderColor : UIColor = UIColor.clear
    @IBInspectable var borderWidth : CGFloat = 0
    @IBInspectable var cornerRadius : CGFloat = 0
    @IBInspectable var padding: CGFloat = 0{
        didSet {
            self.textInsets = UIEdgeInsets(top: self.padding, left: self.padding, bottom: self.padding, right: self.padding)
        }
    }
    
    var textInsets = UIEdgeInsets.zero {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        customize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.customize()
    }
    
    override func prepareForInterfaceBuilder() {
        customize()
    }
    
    func customize(){
        self.layer.masksToBounds = true
        self.layer.borderColor = self.borderColor.cgColor
        self.layer.borderWidth = self.borderWidth
        self.layer.cornerRadius = self.cornerRadius
    }
    
    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect
    {
        var insets = self.textInsets
        let insetRect = bounds.inset(by: insets)
        let textRect = super.textRect(forBounds: insetRect, limitedToNumberOfLines: numberOfLines)
        insets = UIEdgeInsets(top: -insets.top, left: -insets.left, bottom: -insets.bottom, right: -insets.right)
        return textRect.inset(by: insets)
    }
    
    func appendIconToLabel(imageName: String, labelText: String?, bounds_x: Double, bounds_y: Double, boundsWidth: Double, boundsHeight: Double) {
        let attachment = NSTextAttachment()
        attachment.image = UIImage(named: imageName)
        attachment.bounds = CGRect(x: bounds_x, y: bounds_y, width: boundsWidth, height: boundsHeight)
        let attachmentStr = NSAttributedString(attachment: attachment)
        let string = NSMutableAttributedString(string: labelText ?? "")
        string.append(attachmentStr)
        let string2 = NSMutableAttributedString(string: "")
        string.append(string2)
        self.attributedText = string
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: self.textInsets))
    }

}
