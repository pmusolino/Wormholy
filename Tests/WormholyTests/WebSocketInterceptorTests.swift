// Copyright (c) 2026 Wormholy contributors
// SPDX-License-Identifier: MIT

import XCTest
@testable import WormholySwift

private final class LockedTaskBox: @unchecked Sendable {
    private let lock = NSLock()
    private var storedTask: URLSessionWebSocketTask?
    private var storedFactoryDate: Date?

    var task: URLSessionWebSocketTask? {
        lock.lock()
        defer { lock.unlock() }
        return storedTask
    }

    var factoryDate: Date? {
        lock.lock()
        defer { lock.unlock() }
        return storedFactoryDate
    }

    func store(task: URLSessionWebSocketTask, factoryDate: Date) {
        lock.lock()
        defer { lock.unlock() }
        storedTask = task
        storedFactoryDate = factoryDate
    }
}

@MainActor
final class WebSocketInterceptorTests: WebSocketTestCase {

    // MARK: - Tests

    func testWebSocketEnabledStateIsSharedWithObjectiveCBridge() {
        Wormholy.setWebSocketEnabled(true)
        XCTAssertTrue(WHWebSocketRecorder.isEnabled)

        Wormholy.setWebSocketEnabled(false)
        XCTAssertFalse(WHWebSocketRecorder.isEnabled)
    }

    func testDelegateProxyRequiresWebSocketTrackingWhenSessionIsCreated() {
        Wormholy.setWebSocketEnabled(false)
        let disabledDelegate = WebSocketLifecycleDelegate()
        let disabledSession = URLSession(configuration: .ephemeral,
                                         delegate: disabledDelegate,
                                         delegateQueue: nil)
        XCTAssertTrue(disabledSession.delegate === disabledDelegate)

        Wormholy.setWebSocketEnabled(true)
        let enabledDelegate = WebSocketLifecycleDelegate()
        let enabledSession = URLSession(configuration: .ephemeral,
                                        delegate: enabledDelegate,
                                        delegateQueue: nil)
        XCTAssertFalse(enabledSession.delegate === enabledDelegate)
    }

    func testDelegateProxyForwardsAndCapturesLifecycleEvents() async throws {
        Wormholy.setWebSocketEnabled(true)
        let delegateOpened = expectation(description: "original delegate received didOpen")
        let delegateClosed = expectation(description: "original delegate received didClose")
        let delegate = WebSocketLifecycleDelegate(onOpen: { delegateOpened.fulfill() },
                                                  onClose: { delegateClosed.fulfill() })
        let session = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: nil)
        let task = session.webSocketTask(with: URL(string: "wss://example.com/socket/\(UUID().uuidString)")!)
        await fulfillment(of: [modelAttachedExpectation(for: task)], timeout: 1)
        let model = try XCTUnwrap(task.wormholyModel)
        let proxy = try XCTUnwrap(session.delegate as? URLSessionWebSocketDelegate)
        let didOpen = try XCTUnwrap(proxy.urlSession(_:webSocketTask:didOpenWithProtocol:))
        let didClose = try XCTUnwrap(proxy.urlSession(_:webSocketTask:didCloseWith:reason:))

        let modelOpened = openedExpectation(in: model)
        didOpen(session, task, "chat")

        await fulfillment(of: [delegateOpened, modelOpened], timeout: 1)
        XCTAssertEqual(model.negotiatedProtocol, "chat")

        let modelClosed = closedExpectation(in: model)
        didClose(session, task, .normalClosure, Data("done".utf8))

        await fulfillment(of: [delegateClosed, modelClosed], timeout: 1)
        XCTAssertEqual(model.closeCode, .normalClosure)
        XCTAssertEqual(model.closeReason, "done")
    }

    func testBackgroundFactoryReturnsWhileMainActorIsBlocked() async throws {
        Wormholy.setWebSocketEnabled(true)
        let factoryReturned = expectation(description: "background factory returned")
        let taskBox = LockedTaskBox()

        DispatchQueue.global(qos: .userInitiated).async {
            let url = URL(string: "wss://example.com/socket/\(UUID().uuidString)")!
            let factoryDate = Date()
            let task = URLSession.shared.webSocketTask(with: url)
            taskBox.store(task: task, factoryDate: factoryDate)
            factoryReturned.fulfill()
        }

        XCTAssertEqual(XCTWaiter().wait(for: [factoryReturned], timeout: 0.2), .completed)
        let task = try XCTUnwrap(taskBox.task)
        let factoryDate = try XCTUnwrap(taskBox.factoryDate)
        let mainActorAvailableDate = Date()
        await fulfillment(of: [modelAttachedExpectation(for: task)], timeout: 1)
        let model = try XCTUnwrap(task.wormholyModel)
        XCTAssertGreaterThanOrEqual(model.startDate, factoryDate)
        XCTAssertLessThan(model.startDate, mainActorAvailableDate)
        XCTAssertTrue(Storage.shared.webSocketConnections.contains { $0.id == model.id })
    }

    func testRecorderBuffersEventBeforeModelIsAttached() async throws {
        Wormholy.setWebSocketEnabled(true)
        let task = URLSession.shared.webSocketTask(with: URL(string: "wss://example.com/socket/\(UUID().uuidString)")!)

        WHWebSocketRecorder.recordSentText(task, text: "early message")

        await fulfillment(of: [modelAttachedExpectation(for: task)], timeout: 1)
        let model = try XCTUnwrap(task.wormholyModel)
        XCTAssertEqual(model.messages.map(\.text), ["early message"])
    }

    func testRecorderKeepsLatestPendingMessagesWithinLimit() async throws {
        Wormholy.setWebSocketEnabled(true)
        Wormholy.webSocketMessageLimit = 2
        let task = URLSession.shared.webSocketTask(with: URL(string: "wss://example.com/socket/\(UUID().uuidString)")!)
        await fulfillment(of: [modelAttachedExpectation(for: task)], timeout: 1)
        let model = try XCTUnwrap(task.wormholyModel)
        let messagesRecorded = expectation(description: "latest messages recorded")

        model.$messages
            .dropFirst()
            .filter { $0.map(\.text) == ["second", "third"] }
            .prefix(1)
            .sink { _ in messagesRecorded.fulfill() }
            .store(in: &cancellables)

        WHWebSocketRecorder.recordSentText(task, text: "first")
        WHWebSocketRecorder.recordReceivedText(task, text: "second")
        WHWebSocketRecorder.recordSentText(task, text: "third")

        await fulfillment(of: [messagesRecorded], timeout: 1)
        XCTAssertEqual(model.messages.map(\.text), ["second", "third"])
    }

    func testRecorderZeroLimitClearsPreviouslyPublishedMessages() async throws {
        Wormholy.setWebSocketEnabled(true)
        Wormholy.webSocketMessageLimit = nil
        let task = URLSession.shared.webSocketTask(with: URL(string: "wss://example.com/socket/\(UUID().uuidString)")!)
        await fulfillment(of: [modelAttachedExpectation(for: task)], timeout: 1)
        let model = try XCTUnwrap(task.wormholyModel)
        let firstMessageRecorded = expectation(description: "first message recorded")

        model.$messages
            .dropFirst()
            .filter { $0.map(\.text) == ["first"] }
            .prefix(1)
            .sink { _ in firstMessageRecorded.fulfill() }
            .store(in: &cancellables)
        WHWebSocketRecorder.recordSentText(task, text: "first")
        await fulfillment(of: [firstMessageRecorded], timeout: 1)

        Wormholy.webSocketMessageLimit = 0
        let messagesCleared = expectation(description: "messages cleared")
        model.$messages
            .dropFirst()
            .filter(\.isEmpty)
            .prefix(1)
            .sink { _ in messagesCleared.fulfill() }
            .store(in: &cancellables)
        WHWebSocketRecorder.recordReceivedText(task, text: "second")

        await fulfillment(of: [messagesCleared], timeout: 1)
        XCTAssertTrue(model.messages.isEmpty)
    }

    func testRecorderPublishesMessageBurstOnce() async throws {
        Wormholy.setWebSocketEnabled(true)
        Wormholy.webSocketMessageLimit = nil
        let task = URLSession.shared.webSocketTask(with: URL(string: "wss://example.com/socket/\(UUID().uuidString)")!)
        await fulfillment(of: [modelAttachedExpectation(for: task)], timeout: 1)
        let model = try XCTUnwrap(task.wormholyModel)
        let messagesRecorded = expectation(description: "messages recorded in one publication")
        var publicationCount = 0

        model.$messages
            .dropFirst()
            .sink { messages in
                publicationCount += 1
                if messages.map(\.text) == ["first", "second", "third"] {
                    messagesRecorded.fulfill()
                }
            }
            .store(in: &cancellables)

        WHWebSocketRecorder.recordSentText(task, text: "first")
        WHWebSocketRecorder.recordReceivedText(task, text: "second")
        WHWebSocketRecorder.recordSentText(task, text: "third")

        await fulfillment(of: [messagesRecorded], timeout: 1)
        XCTAssertEqual(publicationCount, 1)
    }

    func testRecorderRetainsLatestMessagesAcrossLargeInterleavedBurst() async throws {
        Wormholy.setWebSocketEnabled(true)
        Wormholy.webSocketMessageLimit = 10
        let firstTaskURL = URL(string: "wss://example.com/first/\(UUID().uuidString)")!
        let secondTaskURL = URL(string: "wss://example.com/second/\(UUID().uuidString)")!
        let firstTask = URLSession.shared.webSocketTask(with: firstTaskURL)
        let secondTask = URLSession.shared.webSocketTask(with: secondTaskURL)
        let firstModelAttached = modelAttachedExpectation(for: firstTask)
        let secondModelAttached = modelAttachedExpectation(for: secondTask)
        await fulfillment(of: [firstModelAttached, secondModelAttached], timeout: 1)
        let firstModel = try XCTUnwrap(firstTask.wormholyModel)
        let secondModel = try XCTUnwrap(secondTask.wormholyModel)
        let firstMessagesRecorded = expectation(description: "first task messages recorded")
        let secondMessagesRecorded = expectation(description: "second task messages recorded")
        let expectedFirstMessages = (990..<1_000).map { "first-\($0)" }
        let expectedSecondMessages = (990..<1_000).map { "second-\($0)" }

        firstModel.$messages
            .dropFirst()
            .filter { $0.map(\.text) == expectedFirstMessages }
            .prefix(1)
            .sink { _ in firstMessagesRecorded.fulfill() }
            .store(in: &cancellables)

        secondModel.$messages
            .dropFirst()
            .filter { $0.map(\.text) == expectedSecondMessages }
            .prefix(1)
            .sink { _ in secondMessagesRecorded.fulfill() }
            .store(in: &cancellables)

        for index in 0..<1_000 {
            WHWebSocketRecorder.recordSentText(firstTask, text: "first-\(index)")
            WHWebSocketRecorder.recordReceivedText(secondTask, text: "second-\(index)")
        }

        await fulfillment(of: [firstMessagesRecorded, secondMessagesRecorded], timeout: 1)
        XCTAssertEqual(firstModel.messages.map(\.text), expectedFirstMessages)
        XCTAssertEqual(secondModel.messages.map(\.text), expectedSecondMessages)
    }

    func testRecorderFlushesMessagesBeforeLifecycleEvent() async throws {
        Wormholy.setWebSocketEnabled(true)
        let task = URLSession.shared.webSocketTask(with: URL(string: "wss://example.com/socket/\(UUID().uuidString)")!)
        await fulfillment(of: [modelAttachedExpectation(for: task)], timeout: 1)
        let model = try XCTUnwrap(task.wormholyModel)
        let connectionClosed = expectation(description: "connection closed after messages are recorded")

        model.$closedAt
            .dropFirst()
            .sink { _ in
                XCTAssertEqual(model.messages.map(\.text), ["before close"])
                connectionClosed.fulfill()
            }
            .store(in: &cancellables)

        WHWebSocketRecorder.recordSentText(task, text: "before close")
        WHWebSocketRecorder.recordClosed(task, closeCode: .normalClosure, reason: nil)

        await fulfillment(of: [connectionClosed], timeout: 1)
    }

    func testDisabledInterceptorDoesNotAttachModel() {
        Wormholy.setWebSocketEnabled(false)

        let url = URL(string: "wss://example.com/socket/\(UUID().uuidString)")!
        let task = URLSession.shared.webSocketTask(with: url)

        XCTAssertNil(task.wormholyModel)
    }

    func testEnablingTrackingDoesNotAttachPreviouslyCreatedTask() {
        Wormholy.setWebSocketEnabled(false)

        let url = URL(string: "wss://example.com/socket/\(UUID().uuidString)")!
        let task = URLSession.shared.webSocketTask(with: url)

        Wormholy.setWebSocketEnabled(true)

        XCTAssertNil(task.wormholyModel)
        XCTAssertTrue(Storage.shared.webSocketConnections.isEmpty)
    }

    func testIgnoredHostDoesNotAttachModel() {
        Wormholy.setWebSocketEnabled(true)
        Wormholy.ignoredHosts = ["example.com"]

        let url = URL(string: "wss://api.example.com/socket/\(UUID().uuidString)")!
        let task = URLSession.shared.webSocketTask(with: url)

        XCTAssertNil(task.wormholyModel)
    }

    func testNonIgnoredHostStillAttachesModel() async {
        Wormholy.setWebSocketEnabled(true)
        Wormholy.ignoredHosts = ["example.com"]

        let url = URL(string: "wss://other.com/socket/\(UUID().uuidString)")!
        let task = URLSession.shared.webSocketTask(with: url)

        await fulfillment(of: [modelAttachedExpectation(for: task)], timeout: 1)
        XCTAssertNotNil(task.wormholyModel)
    }

}
