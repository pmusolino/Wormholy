// Copyright (c) 2026 Wormholy contributors
// SPDX-License-Identifier: MIT

import XCTest
@testable import WormholySwift

final class WebSocketMessageRingBufferTests: XCTestCase {

    // MARK: - Tests

    func testPreservesFIFOOrderWhenGrowingAfterWrapAround() {
        var buffer = WebSocketMessageRingBuffer()

        for index in 0..<5 {
            buffer.append(message("message-\(index)"), limit: nil)
        }
        buffer.append(message("message-5"), limit: 3)

        for index in 6...11 {
            buffer.append(message("message-\(index)"), limit: nil)
        }

        XCTAssertEqual(buffer.drain().map(\.text), (3...11).map { "message-\($0)" })
    }

    func testApplyingLowerLimitEvictsOldestMessages() {
        var buffer = WebSocketMessageRingBuffer()

        for index in 0..<6 {
            buffer.append(message("message-\(index)"), limit: nil)
        }
        buffer.append(message("message-6"), limit: 2)

        XCTAssertEqual(buffer.drain().map(\.text), ["message-5", "message-6"])
    }

    func testZeroLimitClearsPendingMessagesAndBufferCanBeReused() {
        var buffer = WebSocketMessageRingBuffer()
        buffer.append(message("first"), limit: nil)
        buffer.append(message("second"), limit: 0)

        XCTAssertTrue(buffer.drain().isEmpty)

        buffer.append(message("third"), limit: nil)
        XCTAssertEqual(buffer.drain().map(\.text), ["third"])
    }

    func testNegativeLimitClearsPendingMessagesAndBufferCanBeReused() {
        var buffer = WebSocketMessageRingBuffer()
        buffer.append(message("first"), limit: nil)
        buffer.append(message("second"), limit: -1)

        XCTAssertTrue(buffer.drain().isEmpty)

        buffer.append(message("third"), limit: nil)
        XCTAssertEqual(buffer.drain().map(\.text), ["third"])
    }

    func testDrainResetsBufferForNextBatch() {
        var buffer = WebSocketMessageRingBuffer()
        buffer.append(message("first"), limit: nil)
        buffer.append(message("second"), limit: nil)

        XCTAssertEqual(buffer.drain().map(\.text), ["first", "second"])
        XCTAssertTrue(buffer.drain().isEmpty)

        buffer.append(message("third"), limit: nil)
        buffer.append(message("fourth"), limit: nil)
        XCTAssertEqual(buffer.drain().map(\.text), ["third", "fourth"])
    }

    // MARK: - Private

    private func message(_ text: String) -> WebSocketMessage {
        WebSocketMessage(direction: .sent,
                         occurredAt: Date(timeIntervalSinceReferenceDate: 1_000),
                         message: .string(text))
    }
}
