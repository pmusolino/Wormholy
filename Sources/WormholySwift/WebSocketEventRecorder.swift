// Copyright (c) 2026 Wormholy contributors
// SPDX-License-Identifier: MIT

import Foundation

private final class MessageBatch {
    let task: URLSessionWebSocketTask
    private var messages = WebSocketMessageRingBuffer()

    init(task: URLSessionWebSocketTask) {
        self.task = task
    }

    func append(_ message: WebSocketMessage, limit: Int?) {
        messages.append(message, limit: limit)
    }

    func drain() -> [WebSocketMessage] {
        messages.drain()
    }
}

private final class WebSocketEventRecorder {
    fileprivate enum Event {
        case prepare(URLSessionWebSocketTask, URL, [String: String], [String], Date)
        case message(URLSessionWebSocketTask, WebSocketMessageDirection, URLSessionWebSocketTask.Message, Date)
        case messages(MessageBatch)
        case opened(URLSessionWebSocketTask, String?, Date)
        case closed(URLSessionWebSocketTask, URLSessionWebSocketTask.CloseCode, Data?, Date)
        case error(URLSessionWebSocketTask, Error, Date)

        @MainActor
        func apply() {
            switch self {
            case let .prepare(task, url, headers, protocols, date):
                // Factory overloads can create the same task more than once internally.
                if let model = task.wormholyModel {
                    model.refineConnectionMetadataIfNeeded(url: url, headers: headers, protocols: protocols)
                } else {
                    let model = WebSocketModel(url: url.absoluteString,
                                               host: url.host,
                                               scheme: url.scheme,
                                               requestHeaders: headers,
                                               requestedProtocols: protocols,
                                               startDate: date)
                    task.wormholyModel = model
                    Storage.shared.saveWebSocketConnection(model)
                }
            case .message:
                return
            case let .messages(batch):
                batch.task.wormholyModel?.addMessages(batch.drain())
            case let .opened(task, negotiatedProtocol, date):
                task.wormholyModel?.markOpened(protocol: negotiatedProtocol, at: date)

                if let httpResponse = task.response as? HTTPURLResponse {
                    let headers = httpResponse.allHeaderFields.reduce(into: [String: String]()) { result, entry in
                        if let key = entry.key as? String, let value = entry.value as? String {
                            result[key] = value
                        }
                    }
                    task.wormholyModel?.updateResponseHeaders(headers)
                }
            case let .closed(task, closeCode, reason, date):
                task.wormholyModel?.markClosed(code: closeCode, reason: reason, at: date)
            case let .error(task, error, date):
                task.wormholyModel?.markError(error, at: date)
            }
        }
    }

    private let queue = DispatchQueue(label: "com.wormholy.websocket-recorder")
    private var messageBatches: [ObjectIdentifier: MessageBatch] = [:]
    private var pendingEvents: [Event] = []
    private var flushScheduled = false

    func record(_ event: Event) {
        queue.async { [weak self] in
            guard let self else { return }
            self.append(event)

            guard !self.flushScheduled else { return }
            self.flushScheduled = true
            DispatchQueue.main.async { [weak self] in
                self?.flushOnMainActor()
            }
        }
    }

    private func append(_ event: Event) {
        switch event {
        case .prepare:
            pendingEvents.append(event)
        case let .message(task, direction, message, date):
            let taskID = ObjectIdentifier(task)
            let batch = messageBatches[taskID] ?? makeMessageBatch(for: task, taskID: taskID)
            let capturedMessage = WebSocketMessage(direction: direction, occurredAt: date, message: message)
            batch.append(capturedMessage, limit: WebSocketConfiguration.messageLimit?.intValue)
        case .messages:
            return
        case let .opened(task, _, _),
             let .closed(task, _, _, _),
             let .error(task, _, _):
            messageBatches.removeValue(forKey: ObjectIdentifier(task))
            pendingEvents.append(event)
        }
    }

    private func makeMessageBatch(for task: URLSessionWebSocketTask,
                                  taskID: ObjectIdentifier) -> MessageBatch {
        let batch = MessageBatch(task: task)
        messageBatches[taskID] = batch
        pendingEvents.append(.messages(batch))
        return batch
    }

    private func flushOnMainActor() {
        let events = queue.sync {
            let events = pendingEvents
            messageBatches.removeAll(keepingCapacity: true)
            pendingEvents.removeAll(keepingCapacity: true)
            flushScheduled = false
            return events
        }

        MainActor.assumeIsolated {
            events.forEach { $0.apply() }
        }
    }
}

/// Bridge called from the Objective-C swizzling of `send(_:completionHandler:)` and
/// `receive(completionHandler:)` (see URLSessionWebSocketTask+Wormholy.m), where the
/// message payload has already been unwrapped into plain Foundation types because
/// `URLSessionWebSocketTask.Message` isn't representable in `@objc`.
@objc(WHWebSocketRecorder)
public final class WHWebSocketRecorder: NSObject {
    private static let eventRecorder = WebSocketEventRecorder()

    @objc public static var isEnabled: Bool { WebSocketInterceptor.isEnabled }

    @objc public static func recordSentText(_ task: URLSessionWebSocketTask, text: String) {
        record(.message(task, .sent, .string(text), Date()))
    }

    @objc public static func recordSentData(_ task: URLSessionWebSocketTask, data: Data) {
        record(.message(task, .sent, .data(data), Date()))
    }

    @objc public static func recordReceivedText(_ task: URLSessionWebSocketTask, text: String) {
        record(.message(task, .received, .string(text), Date()))
    }

    @objc public static func recordReceivedData(_ task: URLSessionWebSocketTask, data: Data) {
        record(.message(task, .received, .data(data), Date()))
    }

    @objc public static func recordOpened(_ task: URLSessionWebSocketTask, protocol negotiatedProtocol: String?) {
        record(.opened(task, negotiatedProtocol, Date()))
    }

    @objc public static func recordClosed(_ task: URLSessionWebSocketTask,
                                          closeCode: URLSessionWebSocketTask.CloseCode,
                                          reason: Data?) {
        record(.closed(task, closeCode, reason, Date()))
    }

    @objc public static func recordError(_ task: URLSessionWebSocketTask, error: Error) {
        record(.error(task, error, Date()))
    }

    internal static func prepare(_ task: URLSessionWebSocketTask,
                                 url: URL,
                                 headers: [String: String],
                                 protocols: [String],
                                 at date: Date) {
        eventRecorder.record(.prepare(task, url, headers, protocols, date))
    }

    private static func record(_ event: WebSocketEventRecorder.Event) {
        guard isEnabled else { return }
        eventRecorder.record(event)
    }
}
