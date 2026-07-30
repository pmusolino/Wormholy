// Copyright (c) 2026 Wormholy contributors
// SPDX-License-Identifier: MIT
import Foundation
import SwiftUI

internal enum WebSocketMessageDirection: Equatable {
    case sent
    case received

    internal var title: String {
        switch self {
        case .sent: return "Sent"
        case .received: return "Received"
        }
    }

    internal var color: Color {
        Colors.WebSocket.Direction.getDirectionColor(self)
    }
}

internal struct WebSocketMessage: Identifiable {
    internal let id: String = UUID().uuidString
    internal let direction: WebSocketMessageDirection
    internal let occurredAt: Date
    internal let message: URLSessionWebSocketTask.Message

    internal var text: String? {
        switch message {
        case .string(let string): return string
        case .data(let data): return String(data: data, encoding: .utf8)
        @unknown default: return nil
        }
    }

    internal var data: Data? {
        switch message {
        case .data(let data): return data
        case .string(let string): return string.data(using: .utf8)
        @unknown default: return nil
        }
    }

    internal var byteCount: Int {
        switch message {
        case .string(let string): return string.utf8.count
        case .data(let data): return data.count
        @unknown default: return 0
        }
    }
}

internal enum WebSocketConnectionState: Equatable {
    case connecting
    case open
    case closed
    case failed

    internal var title: String {
        switch self {
        case .connecting: return "Connecting"
        case .open: return "Open"
        case .closed: return "Closed"
        case .failed: return "Failed"
        }
    }
}

@MainActor
internal class WebSocketModel: Identifiable, ObservableObject, Equatable {
    internal let id: String
    @Published internal private(set) var url: String
    @Published internal private(set) var host: String?
    @Published internal private(set) var scheme: String?
    @Published internal private(set) var requestHeaders: [String: String]
    @Published internal private(set) var responseHeaders: [String: String]
    @Published internal private(set) var requestedProtocols: [String]
    internal let startDate: Date

    @Published internal private(set) var messages: [WebSocketMessage] = []
    internal private(set) var sentMessageCount = 0
    internal private(set) var receivedMessageCount = 0
    @Published internal private(set) var openedAt: Date?
    @Published internal private(set) var negotiatedProtocol: String?
    @Published internal private(set) var closedAt: Date?
    @Published internal private(set) var closeCode: URLSessionWebSocketTask.CloseCode?
    @Published internal private(set) var closeReason: String?
    @Published internal private(set) var errorDescription: String?
    @Published internal private(set) var failedAt: Date?

    internal var state: WebSocketConnectionState {
        if closedAt != nil { return .closed }
        if errorDescription != nil { return .failed }
        if openedAt != nil { return .open }
        return .connecting
    }

    internal init(id: String = UUID().uuidString,
                  url: String,
                  host: String? = nil,
                  scheme: String? = nil,
                  requestHeaders: [String: String] = [:],
                  responseHeaders: [String: String] = [:],
                  requestedProtocols: [String] = [],
                  startDate: Date = Date()) {
        self.id = id
        self.url = url
        self.host = host
        self.scheme = scheme
        self.requestHeaders = requestHeaders
        self.responseHeaders = responseHeaders
        self.requestedProtocols = requestedProtocols
        self.startDate = startDate
    }

    /// `URLSession`'s WebSocket factory overloads are implemented internally in terms of
    /// one another (e.g. the `URL`-based one delegates to the `URLRequest`-based one, which
    /// normalizes the `ws`/`wss` scheme to `http`/`https`). Since all factory overloads are
    /// swizzled, the same task can get attached more than once; this refines the already
    /// -attached model instead of creating a second, orphaned one.
    internal func refineConnectionMetadataIfNeeded(url candidate: URL, headers: [String: String], protocols: [String]) {
        let candidateIsWebSocketScheme = ["ws", "wss"].contains(candidate.scheme?.lowercased() ?? "")
        let currentIsWebSocketScheme = ["ws", "wss"].contains(self.scheme?.lowercased() ?? "")
        if candidateIsWebSocketScheme && !currentIsWebSocketScheme {
            self.url = candidate.absoluteString
            self.host = candidate.host
            self.scheme = candidate.scheme
        }
        if self.requestHeaders.isEmpty && !headers.isEmpty {
            self.requestHeaders = headers
        }
        if self.requestedProtocols.isEmpty && !protocols.isEmpty {
            self.requestedProtocols = protocols
        }
    }

    internal func markOpened(protocol negotiatedProtocol: String? = nil, at date: Date) {
        if self.openedAt == nil {
            self.openedAt = date
        }
        if let negotiatedProtocol = negotiatedProtocol {
            self.negotiatedProtocol = negotiatedProtocol
        }
    }

    internal func addMessage(direction: WebSocketMessageDirection,
                             message: URLSessionWebSocketTask.Message,
                             at date: Date) {
        addMessages([WebSocketMessage(direction: direction, occurredAt: date, message: message)])
    }

    internal func addMessages(_ newMessages: [WebSocketMessage]) {
        guard let limit = WebSocketConfiguration.messageLimit?.intValue else {
            updateMessageCounts(for: newMessages, by: 1)
            self.messages.append(contentsOf: newMessages)
            return
        }

        guard limit > 0 else {
            sentMessageCount = 0
            receivedMessageCount = 0
            self.messages.removeAll(keepingCapacity: true)
            return
        }

        updateMessageCounts(for: newMessages, by: 1)
        self.messages.append(contentsOf: newMessages)
        if self.messages.count > limit {
            let removedCount = self.messages.count - limit
            updateMessageCounts(for: self.messages.prefix(removedCount), by: -1)
            self.messages.removeFirst(removedCount)
        }
    }

    private func updateMessageCounts<S: Sequence>(for messages: S, by value: Int) where S.Element == WebSocketMessage {
        for message in messages {
            switch message.direction {
            case .sent:
                sentMessageCount += value
            case .received:
                receivedMessageCount += value
            }
        }
    }

    internal func updateResponseHeaders(_ headers: [String: String]) {
        guard !headers.isEmpty else { return }
        self.responseHeaders = headers
    }

    internal func markClosed(code: URLSessionWebSocketTask.CloseCode,
                             reason: Data?,
                             at date: Date) {
        self.closedAt = date
        self.closeCode = code
        if let reason = reason {
            self.closeReason = String(data: reason, encoding: .utf8)
        }
    }

    internal func markError(_ error: Error, at date: Date) {
        guard self.closedAt == nil else { return }
        self.errorDescription = error.localizedDescription
        self.failedAt = date
    }

    internal static func == (lhs: WebSocketModel, rhs: WebSocketModel) -> Bool {
        return lhs.id == rhs.id
    }
}
