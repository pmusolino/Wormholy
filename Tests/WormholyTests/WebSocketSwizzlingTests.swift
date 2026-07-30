// Copyright (c) 2026 Wormholy contributors
// SPDX-License-Identifier: MIT

import XCTest
@testable import WormholySwift

private enum WebSocketTaskExampleState {
    static var operation = ""
}

private class BaseWebSocketTaskExample: NSObject {
    @objc(cancelWithCloseCode:reason:)
    dynamic func cancel(closeCode: Int, reason: Data?) {
        WebSocketTaskExampleState.operation = "base-cancel"
    }

    @objc(sendMessage:completionHandler:)
    dynamic func send(message: NSObject, completionHandler: @escaping (NSError?) -> Void) {
        WebSocketTaskExampleState.operation = "base-send"
        completionHandler(nil)
    }

    @objc(receiveMessageWithCompletionHandler:)
    dynamic func receive(completionHandler: @escaping (NSObject?, NSError?) -> Void) {
        WebSocketTaskExampleState.operation = "base-receive"
        completionHandler(nil, nil)
    }
}

private final class InheritedWebSocketTaskExample: BaseWebSocketTaskExample {}

private class OverridingWebSocketTaskExample: BaseWebSocketTaskExample {
    @objc(cancelWithCloseCode:reason:)
    dynamic override func cancel(closeCode: Int, reason: Data?) {
        WebSocketTaskExampleState.operation = "override-cancel"
    }

    @objc(sendMessage:completionHandler:)
    dynamic override func send(message: NSObject, completionHandler: @escaping (NSError?) -> Void) {
        WebSocketTaskExampleState.operation = "override-send"
        completionHandler(nil)
    }

    @objc(receiveMessageWithCompletionHandler:)
    dynamic override func receive(completionHandler: @escaping (NSObject?, NSError?) -> Void) {
        WebSocketTaskExampleState.operation = "override-receive"
        completionHandler(nil, nil)
    }
}

private final class InheritedOverrideWebSocketTaskExample: OverridingWebSocketTaskExample {}

@MainActor
final class WebSocketSwizzlingTests: WebSocketTestCase {

    // MARK: - URLSession Factory Swizzling

    func testInstallIsIdempotent() {
        WebSocketInterceptor.install()
        WebSocketInterceptor.install()
    }

    func testFactoryURLOverloadAttachesModelWithoutNetworkActivity() async {
        Wormholy.setWebSocketEnabled(true)
        let url = URL(string: "wss://example.com/socket/\(UUID().uuidString)")!
        let task = URLSession.shared.webSocketTask(with: url)
        let modelAttached = modelAttachedExpectation(for: task)

        await fulfillment(of: [modelAttached], timeout: 1)
        XCTAssertEqual(task.wormholyModel?.url, url.absoluteString)
        XCTAssertEqual(task.wormholyModel?.host, url.host)
        XCTAssertTrue(Storage.shared.webSocketConnections.contains { $0.id == task.wormholyModel?.id })
    }

    func testFactoryRequestOverloadCapturesHeaders() async throws {
        Wormholy.setWebSocketEnabled(true)
        var request = URLRequest(url: URL(string: "wss://example.com/socket/\(UUID().uuidString)")!)
        request.setValue("Bearer token", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.webSocketTask(with: request)
        await fulfillment(of: [modelAttachedExpectation(for: task)], timeout: 1)
        let model = try XCTUnwrap(task.wormholyModel)
        XCTAssertEqual(model.requestHeaders["Authorization"], "Bearer token")
    }

    func testFactoryProtocolsOverloadCapturesRequestedProtocols() async throws {
        Wormholy.setWebSocketEnabled(true)
        let url = URL(string: "wss://example.com/socket/\(UUID().uuidString)")!

        let task = URLSession.shared.webSocketTask(with: url, protocols: ["chat", "superchat"])
        await fulfillment(of: [modelAttachedExpectation(for: task)], timeout: 1)
        let model = try XCTUnwrap(task.wormholyModel)
        XCTAssertEqual(model.requestedProtocols, ["chat", "superchat"])
    }

    // MARK: - Class Inheritance

    func testInheritancePolicyDistinguishesDirectOverrides() {
        for selector in swizzledSelectors {
            XCTAssertTrue(directlyImplements(selector, BaseWebSocketTaskExample.self))
            XCTAssertFalse(directlyImplements(selector, InheritedWebSocketTaskExample.self))
            XCTAssertTrue(directlyImplements(selector, OverridingWebSocketTaskExample.self))
            XCTAssertFalse(directlyImplements(selector, InheritedOverrideWebSocketTaskExample.self))
        }
    }

    func testInheritancePolicyReusesOnlyNearestSwizzledImplementation() {
        let baseSwizzled = Set([ObjectIdentifier(BaseWebSocketTaskExample.self)])
        let overridingSwizzled = Set([ObjectIdentifier(OverridingWebSocketTaskExample.self)])

        for selector in swizzledSelectors {
            XCTAssertTrue(inheritsSwizzledMethod(selector, InheritedWebSocketTaskExample.self, baseSwizzled))
            XCTAssertFalse(inheritsSwizzledMethod(selector, InheritedOverrideWebSocketTaskExample.self, baseSwizzled))
            XCTAssertTrue(inheritsSwizzledMethod(selector,
                                                  InheritedOverrideWebSocketTaskExample.self,
                                                  overridingSwizzled))
        }
    }

    func testMessageSwizzlerForwardsThroughTheNearestOriginalImplementation() {
        Wormholy.setWebSocketEnabled(false)
        let examples: [AnyClass] = [
            BaseWebSocketTaskExample.self,
            InheritedWebSocketTaskExample.self,
            OverridingWebSocketTaskExample.self,
            InheritedOverrideWebSocketTaskExample.self
        ]
        examples.forEach(WebSocketInterceptor.ensureSwizzled)

        assertCancelIsForwarded(BaseWebSocketTaskExample(), expectedOperation: "base-cancel")
        assertCancelIsForwarded(InheritedWebSocketTaskExample(), expectedOperation: "base-cancel")
        assertCancelIsForwarded(OverridingWebSocketTaskExample(), expectedOperation: "override-cancel")
        assertCancelIsForwarded(InheritedOverrideWebSocketTaskExample(), expectedOperation: "override-cancel")

        assertSendIsForwarded(BaseWebSocketTaskExample(), expectedOperation: "base-send")
        assertSendIsForwarded(InheritedWebSocketTaskExample(), expectedOperation: "base-send")
        assertSendIsForwarded(OverridingWebSocketTaskExample(), expectedOperation: "override-send")
        assertSendIsForwarded(InheritedOverrideWebSocketTaskExample(), expectedOperation: "override-send")

        assertReceiveIsForwarded(BaseWebSocketTaskExample(), expectedOperation: "base-receive")
        assertReceiveIsForwarded(InheritedWebSocketTaskExample(), expectedOperation: "base-receive")
        assertReceiveIsForwarded(OverridingWebSocketTaskExample(), expectedOperation: "override-receive")
        assertReceiveIsForwarded(InheritedOverrideWebSocketTaskExample(), expectedOperation: "override-receive")
    }

    // MARK: - Private

    private var swizzledSelectors: [Selector] {
        [
            NSSelectorFromString("cancelWithCloseCode:reason:"),
            NSSelectorFromString("sendMessage:completionHandler:"),
            NSSelectorFromString("receiveMessageWithCompletionHandler:")
        ]
    }

    private func directlyImplements(_ selector: Selector, _ cls: AnyClass) -> Bool {
        WebSocketInterceptor.classDirectlyImplements(selector, on: cls)
    }

    private func inheritsSwizzledMethod(_ selector: Selector,
                                        _ cls: AnyClass,
                                        _ swizzledClasses: Set<ObjectIdentifier>) -> Bool {
        WebSocketInterceptor.inheritsSwizzledMethod(selector, from: cls, swizzledClasses: swizzledClasses)
    }

    private func assertSendIsForwarded(_ task: BaseWebSocketTaskExample, expectedOperation: String) {
        WebSocketTaskExampleState.operation = ""
        task.send(message: NSObject()) { error in
            XCTAssertNil(error)
        }
        XCTAssertEqual(WebSocketTaskExampleState.operation, expectedOperation)
    }

    private func assertCancelIsForwarded(_ task: BaseWebSocketTaskExample, expectedOperation: String) {
        WebSocketTaskExampleState.operation = ""
        task.cancel(closeCode: 1000, reason: nil)
        XCTAssertEqual(WebSocketTaskExampleState.operation, expectedOperation)
    }

    private func assertReceiveIsForwarded(_ task: BaseWebSocketTaskExample, expectedOperation: String) {
        WebSocketTaskExampleState.operation = ""
        task.receive { message, error in
            XCTAssertNil(message)
            XCTAssertNil(error)
        }
        XCTAssertEqual(WebSocketTaskExampleState.operation, expectedOperation)
    }

}
