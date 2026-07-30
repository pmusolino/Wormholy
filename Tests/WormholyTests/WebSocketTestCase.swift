// Copyright (c) 2026 Wormholy contributors
// SPDX-License-Identifier: MIT

import Combine
import XCTest
@testable import WormholySwift

@MainActor
class WebSocketTestCase: XCTestCase {
    var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    override func tearDown() async throws {
        cancellables.removeAll()
        Wormholy.setWebSocketEnabled(false)
        Wormholy.webSocketMessageLimit = nil
        Wormholy.ignoredHosts = []
        Storage.shared.clearWebSocketConnections()
        try await super.tearDown()
    }

    // MARK: - Expectations

    func modelAttachedExpectation(for task: URLSessionWebSocketTask) -> XCTestExpectation {
        let expectation = expectation(description: "WebSocket model attached")
        if task.wormholyModel != nil {
            expectation.fulfill()
        } else {
            Storage.shared.$webSocketConnections
                .dropFirst()
                .filter { _ in task.wormholyModel != nil }
                .prefix(1)
                .sink { _ in expectation.fulfill() }
                .store(in: &cancellables)
        }
        return expectation
    }

    func openedExpectation(in model: WebSocketModel) -> XCTestExpectation {
        let expectation = expectation(description: "recorded didOpen")
        if model.openedAt != nil {
            expectation.fulfill()
        } else {
            model.$openedAt
                .compactMap { $0 }
                .prefix(1)
                .sink { _ in expectation.fulfill() }
                .store(in: &cancellables)
        }
        return expectation
    }

    func closedExpectation(in model: WebSocketModel) -> XCTestExpectation {
        let expectation = expectation(description: "recorded didClose")
        if model.closedAt != nil {
            expectation.fulfill()
        } else {
            model.$closedAt
                .compactMap { $0 }
                .prefix(1)
                .sink { _ in expectation.fulfill() }
                .store(in: &cancellables)
        }
        return expectation
    }
}

// MARK: - WebSocketLifecycleDelegate

final class WebSocketLifecycleDelegate: NSObject, URLSessionWebSocketDelegate, @unchecked Sendable {
    private let onOpen: () -> Void
    private let onClose: () -> Void

    init(onOpen: @escaping () -> Void = {}, onClose: @escaping () -> Void = {}) {
        self.onOpen = onOpen
        self.onClose = onClose
    }

    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {
        onOpen()
    }

    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                    reason: Data?) {
        onClose()
    }
}
