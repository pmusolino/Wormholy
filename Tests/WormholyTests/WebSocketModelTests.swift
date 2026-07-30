// Copyright (c) 2026 Wormholy contributors
// SPDX-License-Identifier: MIT

import XCTest
@testable import WormholySwift

@MainActor
final class WebSocketModelTests: XCTestCase {
    private let baseDate = Date(timeIntervalSinceReferenceDate: 1_000)
    private let minute: TimeInterval = 60

    override func tearDown() async throws {
        Wormholy.webSocketMessageLimit = nil
        try await super.tearDown()
    }

    func testInitialStateIsConnecting() {
        let model = WebSocketModel(url: "wss://example.com/socket", startDate: baseDate)
        XCTAssertEqual(model.state, .connecting)
        XCTAssertNil(model.openedAt)
        XCTAssertTrue(model.messages.isEmpty)
    }

    func testMarkOpenedRecordsNegotiatedProtocol() {
        let model = WebSocketModel(url: "wss://example.com/socket", startDate: baseDate)

        model.markOpened(protocol: "chat", at: baseDate.addingTimeInterval(minute))

        XCTAssertEqual(model.state, .open)
        XCTAssertNotNil(model.openedAt)
        XCTAssertEqual(model.negotiatedProtocol, "chat")
    }

    func testAddMessageAppendsWithoutMarkingOpen() {
        let model = WebSocketModel(url: "wss://example.com/socket", startDate: baseDate)

        model.addMessage(direction: .sent, message: .string("hello"), at: baseDate.addingTimeInterval(minute))

        XCTAssertEqual(model.state, .connecting)
        XCTAssertNil(model.openedAt)
        XCTAssertEqual(model.messages.count, 1)
        XCTAssertEqual(model.messages.first?.direction, .sent)
        XCTAssertEqual(model.messages.first?.text, "hello")

        model.addMessage(direction: .received,
                         message: .data(Data("world".utf8)),
                         at: baseDate.addingTimeInterval(minute * 2))

        XCTAssertEqual(model.messages.count, 2)
        XCTAssertEqual(model.messages.last?.direction, .received)
        XCTAssertEqual(model.messages.last?.text, "world")
    }

    func testPublicWebSocketMessageLimitIsAppliedImmediately() {
        Wormholy.webSocketMessageLimit = 2
        XCTAssertEqual(Wormholy.webSocketMessageLimit?.intValue, 2)

        let model = WebSocketModel(url: "wss://example.com/socket", startDate: baseDate)

        model.addMessage(direction: .sent, message: .string("first"), at: baseDate.addingTimeInterval(minute))
        model.addMessage(direction: .received, message: .string("second"), at: baseDate.addingTimeInterval(minute * 2))
        model.addMessage(direction: .sent, message: .string("third"), at: baseDate.addingTimeInterval(minute * 3))

        XCTAssertEqual(model.messages.map(\.text), ["second", "third"])
        XCTAssertEqual(model.sentMessageCount, 1)
        XCTAssertEqual(model.receivedMessageCount, 1)
    }

    func testNilWebSocketMessageLimitKeepsCompleteHistory() {
        Wormholy.webSocketMessageLimit = nil
        XCTAssertNil(Wormholy.webSocketMessageLimit)
        let model = WebSocketModel(url: "wss://example.com/socket", startDate: baseDate)

        for index in 0..<3 {
            model.addMessage(direction: .sent,
                             message: .string("\(index)"),
                             at: baseDate.addingTimeInterval(minute * TimeInterval(index)))
        }

        XCTAssertEqual(model.messages.map(\.text), ["0", "1", "2"])
    }

    func testZeroWebSocketMessageLimitClearsExistingAndNewMessages() {
        let model = WebSocketModel(url: "wss://example.com/socket", startDate: baseDate)
        Wormholy.webSocketMessageLimit = nil
        model.addMessage(direction: .sent, message: .string("first"), at: baseDate)
        model.addMessage(direction: .received, message: .string("second"), at: baseDate.addingTimeInterval(minute))

        Wormholy.webSocketMessageLimit = 0
        model.addMessages([])
        model.addMessage(direction: .sent, message: .string("third"), at: baseDate.addingTimeInterval(minute * 2))

        XCTAssertEqual(Wormholy.webSocketMessageLimit?.intValue, 0)
        XCTAssertTrue(model.messages.isEmpty)
        XCTAssertEqual(model.sentMessageCount, 0)
        XCTAssertEqual(model.receivedMessageCount, 0)
    }

    func testNegativeWebSocketMessageLimitIsTreatedAsUnlimited() {
        Wormholy.webSocketMessageLimit = -1
        let model = WebSocketModel(url: "wss://example.com/socket", startDate: baseDate)

        model.addMessage(direction: .sent, message: .string("first"), at: baseDate)
        model.addMessage(direction: .received, message: .string("second"), at: baseDate.addingTimeInterval(minute))

        XCTAssertNil(Wormholy.webSocketMessageLimit)
        XCTAssertEqual(model.messages.map(\.text), ["first", "second"])
    }

    func testOutOfRangeWebSocketMessageLimitIsClampedToIntMax() {
        Wormholy.webSocketMessageLimit = NSNumber(value: UInt64.max)

        XCTAssertEqual(Wormholy.webSocketMessageLimit?.intValue, Int.max)
    }

    func testIntMaxWebSocketMessageLimitIsRetained() {
        Wormholy.webSocketMessageLimit = NSNumber(value: Int.max)

        XCTAssertEqual(Wormholy.webSocketMessageLimit?.intValue, Int.max)
    }

    func testFiniteDoubleAboveUInt64MaxIsClampedToIntMax() {
        Wormholy.webSocketMessageLimit = NSNumber(value: 1e20)

        XCTAssertEqual(Wormholy.webSocketMessageLimit?.intValue, Int.max)
    }

    func testGreatestFiniteDoubleWebSocketMessageLimitIsClampedToIntMax() {
        Wormholy.webSocketMessageLimit = NSNumber(value: Double.greatestFiniteMagnitude)

        XCTAssertEqual(Wormholy.webSocketMessageLimit?.intValue, Int.max)
    }

    func testDecimalWebSocketMessageLimitAboveIntMaxIsClamped() {
        Wormholy.webSocketMessageLimit = NSDecimalNumber(string: "9223372036854775808")

        XCTAssertEqual(Wormholy.webSocketMessageLimit?.intValue, Int.max)
    }

    func testDecimalWebSocketMessageLimitBelowIntMaxIsTruncatedWithoutRoundingUp() {
        Wormholy.webSocketMessageLimit = NSDecimalNumber(string: "9223372036854775806.5")

        XCTAssertEqual(Wormholy.webSocketMessageLimit?.intValue, Int.max - 1)
    }

    func testInvalidWebSocketMessageLimitsAreTreatedAsUnlimited() {
        for value in [Double.nan, Double.infinity, -Double.infinity, -Double.greatestFiniteMagnitude] {
            Wormholy.webSocketMessageLimit = NSNumber(value: value)

            XCTAssertNil(Wormholy.webSocketMessageLimit)
        }
    }

    func testFractionalWebSocketMessageLimitIsNormalizedToInteger() {
        Wormholy.webSocketMessageLimit = 0.5
        let model = WebSocketModel(url: "wss://example.com/socket", startDate: baseDate)

        model.addMessage(direction: .sent, message: .string("message"), at: baseDate)

        XCTAssertEqual(Wormholy.webSocketMessageLimit?.intValue, 0)
        XCTAssertTrue(model.messages.isEmpty)
    }

    func testMarkClosedRecordsCodeAndReason() {
        let model = WebSocketModel(url: "wss://example.com/socket", startDate: baseDate)
        model.markOpened(at: baseDate.addingTimeInterval(minute))

        model.markClosed(code: .normalClosure,
                         reason: Data("bye".utf8),
                         at: baseDate.addingTimeInterval(minute * 2))

        XCTAssertEqual(model.state, .closed)
        XCTAssertEqual(model.closeCode, .normalClosure)
        XCTAssertEqual(model.closeReason, "bye")
        XCTAssertNotNil(model.closedAt)
    }

    func testEventDatesUseCaptureTime() {
        let openedAt = baseDate
        let messageAt = baseDate.addingTimeInterval(minute)
        let closedAt = baseDate.addingTimeInterval(minute * 2)
        let failedAt = baseDate.addingTimeInterval(minute * 3)
        let model = WebSocketModel(url: "wss://example.com/socket", startDate: baseDate)
        let failedModel = WebSocketModel(url: "wss://example.com/failed", startDate: baseDate)

        model.markOpened(at: openedAt)
        model.addMessage(direction: .sent, message: .string("hello"), at: messageAt)
        model.markClosed(code: .normalClosure, reason: Data("done".utf8), at: closedAt)
        failedModel.markError(URLError(.notConnectedToInternet), at: failedAt)

        XCTAssertEqual(model.openedAt, openedAt)
        XCTAssertEqual(model.messages.first?.occurredAt, messageAt)
        XCTAssertEqual(model.closedAt, closedAt)
        XCTAssertEqual(failedModel.failedAt, failedAt)
    }

    func testMarkErrorSetsFailedState() {
        let model = WebSocketModel(url: "wss://example.com/socket", startDate: baseDate)
        model.markError(URLError(.notConnectedToInternet), at: baseDate.addingTimeInterval(minute))

        XCTAssertEqual(model.state, .failed)
        XCTAssertNotNil(model.errorDescription)
    }

    func testErrorAfterCloseDoesNotOverrideClosedState() {
        let model = WebSocketModel(url: "wss://example.com/socket", startDate: baseDate)
        model.markClosed(code: .normalClosure,
                         reason: Data("done".utf8),
                         at: baseDate.addingTimeInterval(minute))

        model.markError(URLError(.networkConnectionLost), at: baseDate.addingTimeInterval(minute * 2))

        XCTAssertEqual(model.state, .closed)
        XCTAssertNil(model.errorDescription)
    }

    func testRefineConnectionMetadataUpgradesNormalizedSchemeToWebSocket() {
        // URLSession's `webSocketTask(with: URL)` delegates internally to `webSocketTask(with:
        // URLRequest)`, which normalizes ws/wss to http/https. This is what corrects it back.
        let model = WebSocketModel(url: "https://example.com/socket",
                                   host: "example.com",
                                   scheme: "https",
                                   startDate: baseDate)
        let wssURL = URL(string: "wss://example.com/socket")!

        model.refineConnectionMetadataIfNeeded(url: wssURL, headers: [:], protocols: [])

        XCTAssertEqual(model.url, wssURL.absoluteString)
        XCTAssertEqual(model.scheme, "wss")
    }

    func testRefineConnectionMetadataDoesNotDowngradeWebSocketScheme() {
        let model = WebSocketModel(url: "wss://example.com/socket",
                                   host: "example.com",
                                   scheme: "wss",
                                   startDate: baseDate)

        model.refineConnectionMetadataIfNeeded(url: URL(string: "https://example.com/socket")!,
                                                headers: [:],
                                                protocols: [])

        XCTAssertEqual(model.scheme, "wss")
    }

    func testRefineConnectionMetadataFillsInMissingProtocolsAndHeaders() {
        let model = WebSocketModel(url: "https://example.com/socket",
                                   host: "example.com",
                                   scheme: "https",
                                   startDate: baseDate)

        model.refineConnectionMetadataIfNeeded(url: URL(string: "wss://example.com/socket")!,
                                                headers: ["Authorization": "Bearer token"],
                                                protocols: ["chat"])

        XCTAssertEqual(model.requestHeaders["Authorization"], "Bearer token")
        XCTAssertEqual(model.requestedProtocols, ["chat"])
    }

    func testUpdateResponseHeadersStoresHandshakeHeaders() {
        let model = WebSocketModel(url: "wss://example.com/socket", startDate: baseDate)

        model.updateResponseHeaders(["Upgrade": "websocket"])

        XCTAssertEqual(model.responseHeaders["Upgrade"], "websocket")
    }

    func testWebSocketExportIncludesHeadersAndMessages() {
        let model = WebSocketModel(url: "wss://example.com/socket",
                                   requestHeaders: ["Authorization": "Bearer token"],
                                   responseHeaders: ["Upgrade": "websocket"],
                                   startDate: baseDate)

        model.addMessage(direction: .sent,
                         message: .string("{\"type\":\"ping\"}"),
                         at: baseDate.addingTimeInterval(minute))
        model.addMessage(direction: .received,
                         message: .string("{\"type\":\"pong\"}"),
                         at: baseDate.addingTimeInterval(minute * 2))

        let export = WebSocketModelBeautifier.txtExport(connection: model)

        XCTAssertTrue(export.contains("*** Overview ***"))
        XCTAssertTrue(export.contains("*** Request Header ***"))
        XCTAssertTrue(export.contains("Authorization"))
        XCTAssertTrue(export.contains("*** Response Header ***"))
        XCTAssertTrue(export.contains("Upgrade"))
        XCTAssertTrue(export.contains("*** Messages ***"))
        XCTAssertTrue(export.contains("Sent text"))
        XCTAssertTrue(export.contains("Received text"))
    }

    func testWebSocketBodyTextPreservesPlainTextMessages() {
        let model = WebSocketModel(url: "wss://example.com/socket", startDate: baseDate)

        model.addMessage(direction: .sent,
                         message: .string("plain text message"),
                         at: baseDate.addingTimeInterval(minute))
        XCTAssertEqual(model.messages.first.map(WebSocketModelBeautifier.bodyText), "plain text message")
    }

    func testWebSocketBinaryBodyAndExportUseBase64() throws {
        let binaryData = Data([0xFF, 0x00, 0x01])
        let model = WebSocketModel(url: "wss://example.com/socket", startDate: baseDate)
        model.addMessage(direction: .received, message: .data(binaryData), at: baseDate)

        let message = try XCTUnwrap(model.messages.first)
        let expectedBody = "Base64 (3 bytes): /wAB"
        let export = WebSocketModelBeautifier.txtExport(connection: model)

        XCTAssertEqual(message.byteCount, 3)
        XCTAssertEqual(WebSocketModelBeautifier.bodyText(message), expectedBody)
        XCTAssertTrue(export.contains(expectedBody))
    }

    func testLargeWebSocketBinaryPreviewIsBoundedWhileBodyAndExportRemainComplete() throws {
        let binaryData = Data(repeating: 0xFF, count: 64 * 1_024)
        let model = WebSocketModel(url: "wss://example.com/socket", startDate: baseDate)
        model.addMessage(direction: .received, message: .data(binaryData), at: baseDate)

        let message = try XCTUnwrap(model.messages.first)
        let completeBase64 = binaryData.base64EncodedString()
        let fullBody = WebSocketModelBeautifier.bodyText(message)
        let preview = WebSocketModelBeautifier.messagePreview(message)
        let export = WebSocketModelBeautifier.txtExport(connection: model)
        let expectedPreview = "Base64 (\(binaryData.count) bytes): \(Data(binaryData.prefix(80)).base64EncodedString())..."

        XCTAssertEqual(preview, expectedPreview)
        XCTAssertTrue(fullBody.contains(completeBase64))
        XCTAssertTrue(export.contains(completeBase64))
        XCTAssertTrue(export.contains(fullBody))
    }
}
