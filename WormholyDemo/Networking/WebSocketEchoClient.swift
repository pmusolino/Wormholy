// Copyright (c) 2026 Wormholy contributors
// SPDX-License-Identifier: MIT
import Foundation

@MainActor
final class WebSocketEchoClient: NSObject {
    static let sharedInstance = WebSocketEchoClient()

    enum Event {
        case connected(URL)
        case sent(String)
        case received(String)
        case closed(URLSessionWebSocketTask.CloseCode, String?)
        case failed(String)

        var text: String {
            switch self {
            case .connected(let url):
                return "Connected: \(url.absoluteString)"
            case .sent(let message):
                return "Sent: \(message)"
            case .received(let message):
                return "Received: \(message)"
            case .closed(let code, let reason):
                return "Closed: \(code.rawValue)\(reason.map { " (\($0))" } ?? "")"
            case .failed(let message):
                return "Error: \(message)"
            }
        }
    }

    var onEvent: ((Event) -> Void)?
    var onConnectionStateChanged: ((Bool) -> Void)?

    private var session: URLSession?
    private var task: URLSessionWebSocketTask?
    private var isConnected = false {
        didSet {
            guard isConnected != oldValue else { return }
            onConnectionStateChanged?(isConnected)
        }
    }

    func connect(to url: URL, includesTestHeaders: Bool) {
        close(code: .goingAway, reason: "Opening a new WebSocket")

        var request = URLRequest(url: url)
        if includesTestHeaders {
            request.setValue("WormholyDemo", forHTTPHeaderField: "X-Wormholy-Client")
            request.setValue("websocket-demo", forHTTPHeaderField: "X-Wormholy-Feature")
        }

        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let task = session.webSocketTask(with: request)
        self.session = session
        self.task = task

        task.resume()
        listen(on: task)
    }

    func send(_ message: String) {
        guard let task else {
            emit(.failed("No active WebSocket"))
            return
        }

        task.send(.string(message)) { [weak self] error in
            Task { @MainActor [weak self] in
                guard let self, self.task === task else { return }

                if let error {
                    self.emit(.failed(error.localizedDescription))
                } else {
                    self.emit(.sent(message))
                }
            }
        }
    }

    func close(code: URLSessionWebSocketTask.CloseCode = .normalClosure, reason: String? = "Closed from demo") {
        guard task != nil || session != nil else { return }

        task?.cancel(with: code, reason: reason?.data(using: .utf8))
        task = nil
        session?.finishTasksAndInvalidate()
        session = nil
        isConnected = false
    }

    private func listen(on task: URLSessionWebSocketTask) {
        task.receive { [weak self, weak task] result in
            Task { @MainActor [weak self, weak task] in
                guard let self, let task, self.task === task else { return }

                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        self.emit(.received(text))
                    case .data(let data):
                        self.emit(.received("<binary \(data.count) bytes>"))
                    @unknown default:
                        break
                    }
                    self.listen(on: task)
                case .failure(let error):
                    self.emit(.failed(error.localizedDescription))
                    self.isConnected = false
                }
            }
        }
    }

    private func emit(_ event: Event) {
        onEvent?(event)
    }
}

extension WebSocketEchoClient: URLSessionWebSocketDelegate {
    nonisolated func urlSession(_ session: URLSession,
                                webSocketTask: URLSessionWebSocketTask,
                                didOpenWithProtocol protocol: String?) {
        Task { @MainActor [weak self] in
            self?.handleOpened(webSocketTask)
        }
    }

    nonisolated func urlSession(_ session: URLSession,
                                webSocketTask: URLSessionWebSocketTask,
                                didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                                reason: Data?) {
        Task { @MainActor [weak self] in
            self?.handleClosed(webSocketTask, code: closeCode, reason: reason)
        }
    }

    private func handleOpened(_ task: URLSessionWebSocketTask) {
        guard self.task === task else { return }

        isConnected = true
        let url = task.currentRequest?.url ?? task.originalRequest?.url ?? URL(string: "wss://unknown")!
        emit(.connected(url))
    }

    private func handleClosed(_ task: URLSessionWebSocketTask,
                              code: URLSessionWebSocketTask.CloseCode,
                              reason: Data?) {
        guard self.task === task else { return }

        isConnected = false
        emit(.closed(code, reason.flatMap { String(data: $0, encoding: .utf8) }))
    }
}
