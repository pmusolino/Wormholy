// Copyright (c) 2026 Wormholy contributors
// SPDX-License-Identifier: MIT

import XCTest
@testable import WormholySwift

final class CustomHTTPProtocolTests: XCTestCase {
    func testCanInitReturnsFalseForWebSocketUpgradeRequests() {
        Wormholy.isEnabled = true

        var request = URLRequest(url: URL(string: "https://example.com/socket")!)
        request.setValue("websocket", forHTTPHeaderField: "Upgrade")

        XCTAssertFalse(CustomHTTPProtocol.canInit(with: request))
    }

    func testCanInitReturnsTrueForRegularHTTPRequests() {
        Wormholy.isEnabled = true
        CustomHTTPProtocol.ignoredHosts = []

        let request = URLRequest(url: URL(string: "https://example.com/api")!)

        XCTAssertTrue(CustomHTTPProtocol.canInit(with: request))
    }
}
