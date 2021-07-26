//
//  ChangeServerViewController.swift
//  Wormholy-iOS
//
//  Created by MIKHAIL CHEPELEV on 26.07.2021.
//  Copyright © 2021 Wormholy. All rights reserved.
//

import UIKit

class InsettedTextField: UITextField {
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return super.textRect(forBounds: bounds).inset(by: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12))
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return super.editingRect(forBounds: bounds).inset(by: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12))
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return super.placeholderRect(forBounds: bounds).inset(by: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12))
    }
}

class ChangeServerViewController: UIViewController {
    let textfield = InsettedTextField()
    let confirm = UIButton(type: .roundedRect)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(textfield)
        view.addSubview(confirm)
        view.backgroundColor = UIColor.white
        title = "Change server"
        textfield.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 11.0, *) {
            textfield.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40).isActive = true
        }
        textfield.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        textfield.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        textfield.layer.borderWidth = 2
        textfield.layer.borderColor = UIColor.lightGray.cgColor
        textfield.layer.cornerRadius = 12
        textfield.keyboardType = .URL
        textfield.placeholder = "https://www.server_url.com"
        textfield.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        confirm.translatesAutoresizingMaskIntoConstraints = false
        confirm.topAnchor.constraint(equalTo: textfield.bottomAnchor, constant: 20).isActive = true
        confirm.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        confirm.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        confirm.heightAnchor.constraint(equalToConstant: 44).isActive = true
        confirm.setTitleColor(.darkText, for: .normal)
        confirm.setTitle("Save", for: .normal)
        confirm.addTarget(self, action: #selector(ChangeServerViewController.confirmMethod), for: .touchUpInside)
    }
    
    @objc func confirmMethod() {
        if let text = textfield.text, text.count > 0, let url = URL(string: text) {
            NotificationCenter.default.post(name: NSNotification.Name("kWormholyRequestChangeServer"), object: nil, userInfo: ["url" : url])
        } else {
            textfield.layer.borderColor = UIColor.red.cgColor
        }
    }
}
