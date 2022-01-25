//
//  ChangeServerViewController.swift
//  Wormholy-iOS
//
//  Created by MIKHAIL CHEPELEV on 26.07.2021.
//  Copyright © 2021 Wormholy. All rights reserved.
//

import UIKit

class InsettedTextField: UITextField {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.layer.borderWidth = 2
        self.layer.cornerRadius = 12
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return super.textRect(forBounds: bounds).inset(by: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12))
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return super.editingRect(forBounds: bounds).inset(by: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class BorderedButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 12
    }
    
    override var isHighlighted: Bool {
        get { return super.isHighlighted }
        set {
            super.isHighlighted = newValue
            self.backgroundColor = mBackgroundcolor?.withAlphaComponent(newValue ? 0.6 : 1.0)
        }
    }
    
    override var isEnabled: Bool {
        get { return super.isEnabled }
        set {
            super.isEnabled = newValue
            self.backgroundColor = mBackgroundcolor?.withAlphaComponent(newValue ? 1.0 : 0.6)
        }
    }
    
    var mBackgroundcolor: UIColor? {
        didSet {
            self.backgroundColor = mBackgroundcolor
        }
    }
    
    func setTitle(_ title: String?, for state: UIControl.State, with titleColor: UIColor?, on backgroundColor: UIColor?) {
        super.setTitle(title, for: state)
        super.setTitleColor(titleColor, for: state)
        self.mBackgroundcolor = backgroundColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ChangeServerViewController: UIViewController {
    let currentServerLabel = UILabel()
    let firstDivider = UIView()
    let prodServerButton = BorderedButton()
    let demoServerButton = BorderedButton()
    let secondDivider = UIView()
    let commonServerLabel = UILabel()
    let commonUrlTextfield = InsettedTextField()
    let epsServerLabel = UILabel()
    let epsUrlTextfield = InsettedTextField()
    let customServerButton = BorderedButton()
    
    let prodCommonUrlString = "https://v1.doma.ai/admin/api"
    let prodEpsUrlString = "https://eps.doma.ai/admin/api"
    let demoCommonUrlString = "https://condo.d.doma.ai/admin/api"
    let demoEpsUrlString = "https://eps.d.doma.ai/admin/api"
    
    let mainColor: UIColor = UIColor(red: 0.286, green: 0.490, blue: 0.998, alpha: 1)
    let secondaryColor: UIColor = .lightGray
    
    enum SwitchTo {
        case prod
        case demo
        case custom
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        placeSubviews()

        view.backgroundColor = UIColor.white
        title = "Change server"
        
        //dividers
        firstDivider.backgroundColor = secondaryColor
        secondDivider.backgroundColor = secondaryColor
        
        //current label
        currentServerLabel.numberOfLines = 0
        currentServerLabel.text = getCurrentServer()
        currentServerLabel.textColor = secondaryColor
        
        //prod button
        configureProdButton()
        
        //demo button
        configureDemoButton()
        
        //common label
        commonServerLabel.text = "Common server:"
        commonServerLabel.textColor = secondaryColor
        
        //common textfield
        commonUrlTextfield.autocapitalizationType = .none
        if #available(iOS 10.0, *) { commonUrlTextfield.textContentType = .URL }
        commonUrlTextfield.keyboardType = .URL
        commonUrlTextfield.layer.borderColor = secondaryColor.cgColor
        commonUrlTextfield.placeholder = "https://www.common_server_url.com"
        
        //EPS label
        epsServerLabel.text = "EPS server:"
        epsServerLabel.textColor = secondaryColor
        
        //EPS textfield
        epsUrlTextfield.autocapitalizationType = .none
        if #available(iOS 10.0, *) { epsUrlTextfield.textContentType = .URL }
        epsUrlTextfield.keyboardType = .URL
        epsUrlTextfield.layer.borderColor = secondaryColor.cgColor
        epsUrlTextfield.placeholder = "https://www.eps_server_url.com"
        
        //custon button
        customServerButton.setTitle("Save", for: .normal, with: .white, on: secondaryColor)
        customServerButton.addTarget(self, action: #selector(switchToCustom), for: .touchUpInside)
    }
    
    func configureProdButton() {
        if  let commonUrl = URL(string: prodCommonUrlString),
            let epsUrl = URL(string: prodEpsUrlString),
            ServerInfoStorage.shared.commonUrl?.absoluteString == commonUrl.absoluteString &&
            ServerInfoStorage.shared.epsUrl?.absoluteString == epsUrl.absoluteString
        {
            prodServerButton.setTitle("Currently at prod", for: .normal, with: .white, on: mainColor)
            prodServerButton.isEnabled = false
        } else {
            prodServerButton.setTitle("Prod server", for: .normal, with: .white, on: mainColor)
            prodServerButton.addTarget(self, action: #selector(switchToProd), for: .touchUpInside)
        }
    }
    
    func configureDemoButton() {
        if  let commonUrl = URL(string: demoCommonUrlString),
            let epsUrl = URL(string: demoEpsUrlString),
            ServerInfoStorage.shared.commonUrl?.absoluteString == commonUrl.absoluteString &&
            ServerInfoStorage.shared.epsUrl?.absoluteString == epsUrl.absoluteString
        {
            demoServerButton.setTitle("Currently at demo", for: .normal, with: .white, on: mainColor)
            demoServerButton.isEnabled = false
        } else {
            demoServerButton.setTitle("Demo server", for: .normal, with: .white, on: mainColor)
            demoServerButton.addTarget(self, action: #selector(switchToDemo), for: .touchUpInside)
        }
    }
    
    @objc func switchToProd() {
        if let commonUrl = URL(string: prodCommonUrlString), let epsUrl = URL(string: prodEpsUrlString) {
            swichTo(common: commonUrl, eps: epsUrl)
        } else {
            failedToSwitch(to: .prod)
        }
    }
    
    @objc func switchToDemo() {
        if let demoUrl = URL(string: demoCommonUrlString), let epsUrl = URL(string: demoEpsUrlString) {
            swichTo(common: demoUrl, eps: epsUrl)
        } else {
            failedToSwitch(to: .demo)
        }
    }
    
    @objc func switchToCustom() {
        if commonIsValid() && epsIsEmptyOrValid() {
            if let epsText = epsUrlTextfield.text?.lowercased(), !epsText.isEmpty {
                if let commonUrl = URL(string: commonUrlTextfield.text ?? ""), let epsUrl = URL(string: epsUrlTextfield.text?.lowercased() ?? "") {
                    if commonUrl.absoluteString == ServerInfoStorage.shared.commonUrl?.absoluteString && epsUrl.absoluteString == ServerInfoStorage.shared.epsUrl?.absoluteString {
                        failedToSwitch(to: .custom)
                    } else {
                        swichTo(common: commonUrl, eps: epsUrl)
                    }
                } else {
                    failedToSwitch(to: .custom)
                }
            } else if let commonUrl = URL(string: commonUrlTextfield.text?.lowercased() ?? ""), let demoEpsUrl = URL(string: demoEpsUrlString) {
                swichTo(common: commonUrl, eps: demoEpsUrl)
            } else {
                failedToSwitch(to: .custom)
            }
        } else {
            failedToSwitch(to: .custom)
        }
    }
    
    func commonIsValid() -> Bool {
        if let commonText = commonUrlTextfield.text, !commonText.isEmpty, commonText.isValidUrl {
            return true
        }
        return false
    }
    
    func epsIsEmptyOrValid() -> Bool {
        if let epsText = epsUrlTextfield.text, epsText.isEmpty || epsText.isValidUrl {
            return true
        }
        return false
    }
    
    func swichTo(common commonUrl: URL, eps epsUrl: URL) {
        UIView.animate(withDuration: 0.15) { [weak self] in
            self?.view.subviews.forEach {
                $0.alpha = 0.0
            }
        } completion: { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
            self?.parent?.dismiss(animated: false, completion: {
                NotificationCenter.default.post(name: NSNotification.Name("kWormholyRequestChangeServer"),
                                                object: nil,
                                                userInfo: ["commonUrl": commonUrl, "epsUrl": epsUrl])
            })
        }
    }
    
    func failedToSwitch(to server: SwitchTo) {
        let errorColor = UIColor.red
        
        switch server {
        case .prod:
            UIView.animate(withDuration: 0.1) { [weak self] in
                self?.prodServerButton.backgroundColor = errorColor
            } completion: { [weak self] _ in
                UIView.animate(withDuration: 0.1) { [weak self] in
                    self?.prodServerButton.backgroundColor = self?.mainColor
                }
            }
        case .demo:
            UIView.animate(withDuration: 0.1) { [weak self] in
                self?.demoServerButton.backgroundColor = errorColor
            } completion: { [weak self] _ in
                UIView.animate(withDuration: 0.1) { [weak self] in
                    self?.demoServerButton.backgroundColor = self?.mainColor
                }
            }
        case .custom:
            if !commonIsValid() {
                UIView.animate(withDuration: 0.1) { [weak self] in
                    self?.commonServerLabel.textColor = errorColor
                    self?.commonUrlTextfield.layer.borderColor = errorColor.cgColor
                    
                    self?.customServerButton.backgroundColor = errorColor
                } completion: { [weak self] _ in
                    UIView.animate(withDuration: 0.1) { [weak self] in
                        self?.commonServerLabel.textColor = self?.secondaryColor
                        self?.commonUrlTextfield.layer.borderColor = self?.secondaryColor.cgColor
                        
                        self?.customServerButton.backgroundColor = self?.secondaryColor
                    }
                }
            }
            if !epsIsEmptyOrValid() {
                UIView.animate(withDuration: 0.1) { [weak self] in
                    self?.epsServerLabel.textColor = errorColor
                    self?.epsUrlTextfield.layer.borderColor = errorColor.cgColor
                    
                    self?.customServerButton.backgroundColor = errorColor
                } completion: { [weak self] _ in
                    UIView.animate(withDuration: 0.1) { [weak self] in
                        self?.epsServerLabel.textColor = self?.secondaryColor
                        self?.epsUrlTextfield.layer.borderColor = self?.secondaryColor.cgColor
                        
                        self?.customServerButton.backgroundColor = self?.secondaryColor
                    }
                }
            }
        }
    }
    
    func getCurrentServer() -> String {
        let defaultString = "not determined"
        let serverString = ServerInfoStorage.shared.commonUrl?.absoluteString ?? defaultString
        let epsString = ServerInfoStorage.shared.epsUrl?.absoluteString ?? defaultString
        return "Common: \(serverString)\nEPS: \(epsString)"
    }
    
    func placeSubviews() {
        currentServerLabel.translatesAutoresizingMaskIntoConstraints = false
        firstDivider.translatesAutoresizingMaskIntoConstraints = false
        prodServerButton.translatesAutoresizingMaskIntoConstraints = false
        demoServerButton.translatesAutoresizingMaskIntoConstraints = false
        secondDivider.translatesAutoresizingMaskIntoConstraints = false
        commonServerLabel.translatesAutoresizingMaskIntoConstraints = false
        commonUrlTextfield.translatesAutoresizingMaskIntoConstraints = false
        epsServerLabel.translatesAutoresizingMaskIntoConstraints = false
        epsUrlTextfield.translatesAutoresizingMaskIntoConstraints = false
        customServerButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(currentServerLabel)
        view.addSubview(firstDivider)
        view.addSubview(prodServerButton)
        view.addSubview(demoServerButton)
        view.addSubview(secondDivider)
        view.addSubview(commonServerLabel)
        view.addSubview(commonUrlTextfield)
        view.addSubview(epsServerLabel)
        view.addSubview(epsUrlTextfield)
        view.addSubview(customServerButton)
        
        NSLayoutConstraint.activate([
            currentServerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            firstDivider.topAnchor.constraint(equalTo: currentServerLabel.bottomAnchor, constant: 20),
            prodServerButton.topAnchor.constraint(equalTo: firstDivider.bottomAnchor, constant: 20),
            demoServerButton.topAnchor.constraint(equalTo: prodServerButton.bottomAnchor, constant: 20),
            secondDivider.topAnchor.constraint(equalTo: demoServerButton.bottomAnchor, constant: 20),
            commonServerLabel.topAnchor.constraint(equalTo: secondDivider.bottomAnchor, constant: 20),
            commonUrlTextfield.topAnchor.constraint(equalTo: commonServerLabel.bottomAnchor, constant: 4),
            epsServerLabel.topAnchor.constraint(equalTo: commonUrlTextfield.bottomAnchor, constant: 12),
            epsUrlTextfield.topAnchor.constraint(equalTo: epsServerLabel.bottomAnchor, constant: 4),
            customServerButton.topAnchor.constraint(equalTo: epsUrlTextfield.bottomAnchor, constant: 20),
            
            currentServerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            currentServerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            firstDivider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            firstDivider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            prodServerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            prodServerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            demoServerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            demoServerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            secondDivider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            secondDivider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            commonServerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            commonServerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            commonUrlTextfield.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            commonUrlTextfield.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            epsServerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            epsServerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            epsUrlTextfield.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            epsUrlTextfield.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            customServerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            customServerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            firstDivider.heightAnchor.constraint(equalToConstant: 1),
            prodServerButton.heightAnchor.constraint(equalToConstant: 44),
            demoServerButton.heightAnchor.constraint(equalToConstant: 44),
            secondDivider.heightAnchor.constraint(equalToConstant: 1),
            commonUrlTextfield.heightAnchor.constraint(equalToConstant: 44),
            epsUrlTextfield.heightAnchor.constraint(equalToConstant: 44),
            customServerButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
}

fileprivate extension String {
    var isValidUrl: Bool {
        get {
            let regEx = "((?:http|https)://)?(?:www\\.)?[\\w\\d\\-_]+\\.\\w{2,3}(\\.\\w{2})?(/(?<=/)(?:[\\w\\d\\-./_]+)?)?"
            let predicate = NSPredicate(format: "SELF MATCHES %@", argumentArray: [regEx])
            return predicate.evaluate(with: self)
        }
    }
}

open class ServerInfoStorage {
    public static let shared = ServerInfoStorage()
    
    public var commonUrl: URL?
    public var epsUrl: URL?
    
    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(setNewValues),
                                               name: Notification.Name(rawValue: "kServerSideSetNewServer"),
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func setNewValues(notification: Notification) {
        if let commonUrl = notification.userInfo?["commonUrl"] as? URL, let epsUrl = notification.userInfo?["epsUrl"] as? URL {
            self.commonUrl = commonUrl
            self.epsUrl = epsUrl
        }
    }
}
