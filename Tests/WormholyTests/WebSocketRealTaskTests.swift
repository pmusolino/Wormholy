// Copyright (c) 2026 Wormholy contributors
// SPDX-License-Identifier: MIT

import XCTest
@testable import WormholySwift

@MainActor
final class WebSocketRealTaskTests: WebSocketTestCase {

    override func setUpWithError() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["WORMHOLY_RUN_NETWORK_TESTS"] == "1",
            "Set WORMHOLY_RUN_NETWORK_TESTS=1 to run WebSocket network integration tests."
        )
        try super.setUpWithError()
    }

    // MARK: - Tests

    func testRealTaskSendCapturesCompletionHandlerAndAsyncMessages() async throws {
        Wormholy.setWebSocketEnabled(true)
        let completionPayload = "completion-send-\(UUID().uuidString)"
        let asyncPayload = "async-send-\(UUID().uuidString)"

        let task = URLSession.shared.webSocketTask(with: Self.remoteEchoURL())
        addTeardownBlock { task.cancel(with: .goingAway, reason: nil) }
        await fulfillment(of: [modelAttachedExpectation(for: task)], timeout: 1)
        task.resume()
        let model = try XCTUnwrap(task.wormholyModel)

        let sendCompletion = expectation(description: "completion send finished")
        task.send(.string(completionPayload)) { error in
            XCTAssertNil(error)
            sendCompletion.fulfill()
        }
        await fulfillment(of: [sendCompletion], timeout: 10)

        try await task.send(.string(asyncPayload))

        await fulfillment(of: [
            messageRecordedExpectation(in: model, direction: .sent, text: completionPayload),
            messageRecordedExpectation(in: model, direction: .sent, text: asyncPayload)
        ], timeout: 5)
    }

    func testRealTaskReceiveCapturesCompletionHandlerAndAsyncMessages() async throws {
        Wormholy.setWebSocketEnabled(true)
        let completionPayload = "completion-receive-\(UUID().uuidString)"
        let asyncPayload = "async-receive-\(UUID().uuidString)"

        let task = URLSession.shared.webSocketTask(with: Self.remoteEchoURL())
        addTeardownBlock { task.cancel(with: .goingAway, reason: nil) }
        await fulfillment(of: [modelAttachedExpectation(for: task)], timeout: 1)
        task.resume()
        let model = try XCTUnwrap(task.wormholyModel)

        try await task.send(.string(completionPayload))

        let receiveCompletion = expectation(description: "completion receive finished")
        task.receive { result in
            switch result {
            case .success(.string(let text)):
                XCTAssertEqual(text, completionPayload)
            case .success:
                XCTFail("Expected a text WebSocket message.")
            case .failure(let error):
                XCTFail("Expected a received message, got error: \(error)")
            }
            receiveCompletion.fulfill()
        }
        await fulfillment(of: [receiveCompletion], timeout: 5)

        try await task.send(.string(asyncPayload))
        let asyncMessage = try await task.receive()
        guard case .string(let asyncText) = asyncMessage else {
            return XCTFail("Expected a text WebSocket message.")
        }
        XCTAssertEqual(asyncText, asyncPayload)

        await fulfillment(of: [
            messageRecordedExpectation(in: model, direction: .received, text: completionPayload),
            messageRecordedExpectation(in: model, direction: .received, text: asyncPayload)
        ], timeout: 5)
    }

    func testRealDelegateSessionForwardsAndCapturesLifecycleEvents() async throws {
        Wormholy.setWebSocketEnabled(true)
        let delegateOpened = expectation(description: "delegate received didOpen")
        let delegateClosed = expectation(description: "delegate received didClose")
        let delegate = WebSocketLifecycleDelegate(onOpen: { delegateOpened.fulfill() },
                                                  onClose: { delegateClosed.fulfill() })
        let session = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: nil)
        let task = session.webSocketTask(with: Self.remoteEchoURL())
        addTeardownBlock {
            task.cancel(with: .goingAway, reason: nil)
            session.invalidateAndCancel()
        }
        await fulfillment(of: [modelAttachedExpectation(for: task)], timeout: 1)
        let model = try XCTUnwrap(task.wormholyModel)

        let modelOpened = openedExpectation(in: model)

        task.resume()

        await fulfillment(of: [delegateOpened, modelOpened], timeout: 10)
        XCTAssertNotNil(model.openedAt)

        let modelClosed = closedExpectation(in: model)

        task.cancel(with: .normalClosure, reason: Data("done".utf8))

        await fulfillment(of: [delegateClosed, modelClosed], timeout: 10)
        XCTAssertNotNil(model.closedAt)
        XCTAssertEqual(model.closeCode, .normalClosure)
        XCTAssertEqual(model.closeReason, "done")
    }

    func testRealTaskSmokeCapturesLifecycleAndTraffic() async throws {
        Wormholy.setWebSocketEnabled(true)
        let payload = "smoke-\(UUID().uuidString)"
        let delegateOpened = expectation(description: "delegate received didOpen")
        let delegateClosed = expectation(description: "delegate received didClose")
        let delegate = WebSocketLifecycleDelegate(onOpen: { delegateOpened.fulfill() },
                                                  onClose: { delegateClosed.fulfill() })
        let session = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: nil)
        let task = session.webSocketTask(with: Self.remoteEchoURL())
        addTeardownBlock {
            task.cancel(with: .goingAway, reason: nil)
            session.invalidateAndCancel()
        }
        await fulfillment(of: [modelAttachedExpectation(for: task)], timeout: 1)
        let model = try XCTUnwrap(task.wormholyModel)
        let modelOpened = openedExpectation(in: model)

        task.resume()

        await fulfillment(of: [delegateOpened, modelOpened], timeout: 10)
        try await task.send(.string(payload))
        let receivedMessage = try await task.receive()
        guard case .string(let receivedPayload) = receivedMessage else {
            return XCTFail("Expected a text WebSocket message.")
        }
        XCTAssertEqual(receivedPayload, payload)

        await fulfillment(of: [
            messageRecordedExpectation(in: model, direction: .sent, text: payload),
            messageRecordedExpectation(in: model, direction: .received, text: payload)
        ], timeout: 5)

        let modelClosed = closedExpectation(in: model)
        task.cancel(with: .normalClosure, reason: Data("smoke".utf8))

        await fulfillment(of: [delegateClosed, modelClosed], timeout: 10)
        XCTAssertEqual(model.closeCode, .normalClosure)
        XCTAssertEqual(model.closeReason, "smoke")
    }

    // MARK: - Private

    private static func remoteEchoURL() -> URL {
        URL(string: "wss://ws.postman-echo.com/raw")!
    }

    private func messageRecordedExpectation(in model: WebSocketModel,
                                            direction: WebSocketMessageDirection,
                                            text: String) -> XCTestExpectation {
        let expectation = expectation(description: "recorded \(direction.title) message")
        let matches: ([WebSocketMessage]) -> Bool = { messages in
            messages.contains { $0.direction == direction && $0.text == text }
        }

        if matches(model.messages) {
            expectation.fulfill()
        } else {
            model.$messages
                .filter(matches)
                .prefix(1)
                .sink { _ in expectation.fulfill() }
                .store(in: &cancellables)
        }
        return expectation
    }

}
