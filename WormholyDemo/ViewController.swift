//
//  ViewController.swift
//  WormholyDemo
//
//  Created by Paolo Musolino on 11/04/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import UIKit
import Foundation
import WormholySwift
class ViewController: UIViewController {
    @IBOutlet private weak var webSocketURLField: UITextField!
    @IBOutlet private weak var webSocketMessageField: UITextField!
    @IBOutlet private weak var webSocketLogView: UITextView!
    @IBOutlet private weak var connectWebSocketButton: UIButton!
    @IBOutlet private weak var newWebSocketButton: UIButton!
    @IBOutlet private weak var sendWebSocketButton: UIButton!
    @IBOutlet private weak var sendJSONWebSocketButton: UIButton!
    @IBOutlet private weak var closeWebSocketButton: UIButton!
    @IBOutlet private weak var webSocketHeadersSwitch: UISwitch!
    private let webSocketLogLimit = 40
    private var webSocketLog: [String] = []
    private var isWebSocketConnected = false
    private lazy var webSocketLogDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    private var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureWebSocketConsole()

        guard !isRunningTests else { return }
        
        let timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { [weak self] (timer) in
            
            DataFetcher.sharedInstance.getPost(id: Utils.random(max: 128), completion: {
                print("API: Get random post")
            }) { (error) in
                print("ERROR: api Get post")
            }
            
            if let strongSelf = self {
                strongSelf.getPhotosButtonPressed(strongSelf)
            }
        }
        timer.fire()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK: - Actions
    @IBAction func getPostsButtonPressed(_ sender: Any) {
        DataFetcher.sharedInstance.getPost(id: 1, completion: {
            print("API: Get post")
        }) { (error) in
            print("ERROR: api Get post")
        }
    }
    
    @IBAction func newRandomPostButtonPressed(_ sender: Any) {
        DataFetcher.sharedInstance.newPost(userId: Utils.random(max: 5000), title: Utils.random(128), body: Utils.random(5000), completion: {
            print("API: New post")
        }) { (error) in
            print("ERROR: api New post")
        }
    }
    
    @IBAction func getWrongURLButtonPressed(_ sender: Any) {
        DataFetcher.sharedInstance.getWrongURL( completion: {
            print("API: Wrong URL")
        }) { (error) in
            print("ERROR: api Wrong URL")
        }
    }
    
    @IBAction func getPhotosButtonPressed(_ sender: Any) {
        DataFetcher.sharedInstance.getPhotosList(completion: {
            print("API: Get photos")
        }) { (error) in
            print("ERROR: api Get photos")
        }
    }

    @IBAction func testWebSocketEchoButtonPressed(_ sender: Any) {
        connectWebSocket()
    }

    @IBAction private func connectWebSocketButtonPressed(_ sender: Any) {
        connectWebSocket()
    }

    @IBAction private func newWebSocketButtonPressed(_ sender: Any) {
        connectWebSocket()
    }

    @IBAction private func sendWebSocketButtonPressed(_ sender: Any) {
        guard let message = webSocketMessageField.text, !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            updateWebSocketButtons(isConnected: isWebSocketConnected)
            return
        }
        WebSocketEchoClient.sharedInstance.send(message)
        webSocketMessageField.text = ""
        updateWebSocketButtons(isConnected: isWebSocketConnected)
    }

    @IBAction private func sendJSONWebSocketButtonPressed(_ sender: Any) {
        WebSocketEchoClient.sharedInstance.send(sampleJSONMessage())
    }

    @IBAction private func closeWebSocketButtonPressed(_ sender: Any) {
        WebSocketEchoClient.sharedInstance.close()
    }

    @IBAction private func webSocketMessageFieldEditingChanged(_ sender: UITextField) {
        updateWebSocketButtons(isConnected: isWebSocketConnected)
    }

    @IBAction private func webSocketHeadersSwitchChanged(_ sender: UISwitch) {
        appendWebSocketLog("Test headers: \(sender.isOn ? "enabled" : "disabled")")
    }

    private func connectWebSocket() {
        guard let text = webSocketURLField.text, let url = URL(string: text) else {
            appendWebSocketLog("Error: invalid WebSocket URL")
            return
        }
        appendWebSocketLog("Opening: \(url.absoluteString)")
        appendWebSocketLog("Test headers: \(webSocketHeadersSwitch.isOn ? "enabled" : "disabled")")
        WebSocketEchoClient.sharedInstance.connect(to: url, includesTestHeaders: webSocketHeadersSwitch.isOn)
    }

    private func configureWebSocketConsole() {
        webSocketURLField.textContentType = .URL
        webSocketURLField.keyboardType = .URL
        webSocketURLField.autocapitalizationType = .none
        webSocketURLField.autocorrectionType = .no

        webSocketMessageField.autocapitalizationType = .sentences
        webSocketHeadersSwitch.isOn = true

        webSocketLogView.font = .preferredFont(forTextStyle: .caption1)
        webSocketLogView.layer.borderColor = UIColor.separator.cgColor
        webSocketLogView.layer.borderWidth = 0.5
        webSocketLogView.layer.cornerRadius = 8

        updateWebSocketButtons(isConnected: false)

        WebSocketEchoClient.sharedInstance.onEvent = { [weak self] event in
            self?.appendWebSocketLog(event.text)
        }
        WebSocketEchoClient.sharedInstance.onConnectionStateChanged = { [weak self] isConnected in
            self?.updateWebSocketButtons(isConnected: isConnected)
        }
    }

    private func updateWebSocketButtons(isConnected: Bool) {
        isWebSocketConnected = isConnected
        let hasMessage = webSocketMessageField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        connectWebSocketButton.isEnabled = !isConnected
        newWebSocketButton.isEnabled = true
        sendWebSocketButton.isEnabled = isConnected && hasMessage
        sendJSONWebSocketButton.isEnabled = isConnected
        closeWebSocketButton.isEnabled = isConnected
    }

    private func sampleJSONMessage() -> String {
        let formatter = ISO8601DateFormatter()
        return """
        {"type":"wormholy.demo","sentAt":"\(formatter.string(from: Date()))","payload":{"message":"Hello from Wormholy","sequence":\(webSocketLog.count + 1)}}
        """
    }

    private func appendWebSocketLog(_ message: String) {
        let timestamp = webSocketLogDateFormatter.string(from: Date())
        webSocketLog.append("[\(timestamp)] \(message)")

        if webSocketLog.count > webSocketLogLimit {
            webSocketLog = Array(webSocketLog.suffix(webSocketLogLimit))
        }

        var visibleLog = webSocketLog
        if visibleLog.count == webSocketLogLimit {
            visibleLog.insert("... earlier log entries removed, limited to \(webSocketLogLimit) ...", at: 0)
        }
        webSocketLogView.text = visibleLog.joined(separator: "\n")

        let bottom = NSRange(location: max(webSocketLogView.text.count - 1, 0), length: 1)
        webSocketLogView.scrollRangeToVisible(bottom)
    }
}
