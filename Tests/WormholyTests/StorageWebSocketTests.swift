// Copyright (c) 2026 Wormholy contributors
// SPDX-License-Identifier: MIT

import XCTest
@testable import WormholySwift

final class StorageWebSocketTests: XCTestCase {
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        Storage.shared.clearWebSocketConnections()
        Storage.limit = nil
    }

    @MainActor
    override func tearDown() async throws {
        Storage.shared.clearWebSocketConnections()
        Storage.limit = nil
        try await super.tearDown()
    }

    @MainActor
    func testSaveWebSocketConnectionInsertsAtFront() {
        let first = WebSocketModel(url: "wss://example.com/first")
        let second = WebSocketModel(url: "wss://example.com/second")

        Storage.shared.saveWebSocketConnection(first)
        Storage.shared.saveWebSocketConnection(second)

        XCTAssertEqual(Storage.shared.webSocketConnections.map { $0.id }, [second.id, first.id])
    }

    @MainActor
    func testSaveWebSocketConnectionRespectsLimit() {
        Storage.limit = 2

        for index in 0..<3 {
            Storage.shared.saveWebSocketConnection(WebSocketModel(url: "wss://example.com/\(index)"))
        }

        XCTAssertEqual(Storage.shared.webSocketConnections.count, 2)
    }

    @MainActor
    func testClearWebSocketConnectionsEmptiesStorage() {
        Storage.shared.saveWebSocketConnection(WebSocketModel(url: "wss://example.com/socket"))
        Storage.shared.clearWebSocketConnections()

        XCTAssertTrue(Storage.shared.webSocketConnections.isEmpty)
    }
}
