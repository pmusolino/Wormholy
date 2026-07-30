// Copyright (c) 2026 Wormholy contributors
// SPDX-License-Identifier: MIT
import Foundation
import ObjectiveC

private typealias WebSocketTaskWithURLFactory = (URLSession) -> (URL) -> URLSessionWebSocketTask
private typealias WebSocketTaskWithRequestFactory = (URLSession) -> (URLRequest) -> URLSessionWebSocketTask

internal enum WebSocketConfiguration {
    private static let lock = NSLock()
    private static var storedIsEnabled = false
    private static var storedMessageLimit: NSNumber?

    internal static var isEnabled: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return storedIsEnabled
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            storedIsEnabled = newValue
        }
    }

    internal static var messageLimit: NSNumber? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return storedMessageLimit
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            storedMessageLimit = newValue
        }
    }
}

/// Swizzles URLSession's WebSocket factory methods and URLSessionWebSocketTask's
/// send/receive/cancel methods to capture WebSocket traffic without requiring
/// any change in the host app's code.
///
/// Swizzling `send(_:completionHandler:)` and `receive(completionHandler:)` also covers
/// their `async throws` counterparts, since Foundation's async overlay for these APIs
/// calls straight into the completion-handler based implementations under the hood.
internal enum WebSocketInterceptor {
    /// Controls whether swizzled methods actually record traffic. The swizzle itself,
    /// once installed, is never removed - this mirrors how HTTP tracking is toggled
    /// elsewhere in Wormholy (see `Wormholy.setEnabled`).
    internal static var isEnabled: Bool {
        get { WebSocketConfiguration.isEnabled }
        set { WebSocketConfiguration.isEnabled = newValue }
    }

    private static var isInstalled = false
    private static var swizzledConcreteClasses = Set<ObjectIdentifier>()
    private static let swizzleLock = NSLock()

    internal static func install() {
        swizzleLock.lock()
        defer { swizzleLock.unlock() }
        guard !isInstalled else { return }

        wormholySwizzleInstanceMethod(URLSession.self,
                                       #selector(URLSession.webSocketTask(with:) as WebSocketTaskWithURLFactory),
                                       #selector(URLSession.wormholy_webSocketTaskWithURL(_:)))

        wormholySwizzleInstanceMethod(URLSession.self,
                                       #selector(URLSession.webSocketTask(with:protocols:)),
                                       #selector(URLSession.wormholy_webSocketTaskWithURL(_:protocols:)))

        wormholySwizzleInstanceMethod(URLSession.self,
                                       #selector(URLSession.webSocketTask(with:) as WebSocketTaskWithRequestFactory),
                                       #selector(URLSession.wormholy_webSocketTaskWithRequest(_:)))

        // `send`, `receive`, and `cancel(with:reason:)` aren't swizzled here: `URLSession`'s
        // WebSocket factories return an instance of a private concrete subclass that actually
        // implements them, not the public `URLSessionWebSocketTask` class - swizzling the
        // public class's method table would have no effect on those instances. They're
        // swizzled lazily per real class instead, see `ensureSwizzledForActualClass`.
        isInstalled = true
    }

    internal static func installSessionDelegateProxy() {
        guard let swizzlerClass = NSClassFromString("WHWebSocketSessionSwizzler") as? NSObject.Type else { return }
        let selector = NSSelectorFromString("wormholy_installWebSocketDelegateProxy")
        guard swizzlerClass.responds(to: selector) else { return }
        _ = swizzlerClass.perform(selector)
    }

    fileprivate static func attachModel(to task: URLSessionWebSocketTask,
                                        url: URL?,
                                        headers: [String: String],
                                        protocols: [String]) {
        guard isEnabled, let url = url else { return }
        guard let host = url.host,
              CustomHTTPProtocol.ignoredHosts.filter({ host.hasSuffix($0) }).isEmpty else {
            return
        }

        ensureSwizzledForActualClass(of: task)
        WHWebSocketRecorder.prepare(task,
                                    url: url,
                                    headers: headers,
                                    protocols: protocols,
                                    at: Date())
    }

    /// Swizzles `cancel(with:reason:)` (Swift side) and triggers the Objective-C swizzle of
    /// `send`/`receive` (see URLSessionWebSocketTask+Wormholy.m) on the task's actual runtime
    /// class, the first time that class is seen. Idempotent per class.
    internal static func ensureSwizzledForActualClass(of task: URLSessionWebSocketTask) {
        guard let concreteClass = object_getClass(task) else { return }
        ensureSwizzled(for: concreteClass)
    }

    internal static func ensureSwizzled(for concreteClass: AnyClass) {
        let key = ObjectIdentifier(concreteClass)

        swizzleLock.lock()
        defer { swizzleLock.unlock() }
        guard !swizzledConcreteClasses.contains(key) else { return }

        let cancelSelector = #selector(URLSessionWebSocketTask.cancel(with:reason:))
        if classDirectlyImplements(cancelSelector, on: concreteClass) ||
            !inheritsSwizzledMethod(cancelSelector,
                                    from: concreteClass,
                                    swizzledClasses: swizzledConcreteClasses) {
            wormholySwizzleInstanceMethod(concreteClass,
                                           cancelSelector,
                                           #selector(URLSessionWebSocketTask.wormholy_cancel(with:reason:)),
                                           swizzledOwner: URLSessionWebSocketTask.self)
        }

        installMessageOperationSwizzles(for: concreteClass)

        swizzledConcreteClasses.insert(key)
    }

    internal static func classDirectlyImplements(_ selector: Selector, on cls: AnyClass) -> Bool {
        guard let method = class_getInstanceMethod(cls, selector) else { return false }
        guard let superclass = class_getSuperclass(cls),
              let inheritedMethod = class_getInstanceMethod(superclass, selector) else {
            return true
        }
        return method != inheritedMethod
    }

    internal static func inheritsSwizzledMethod(_ selector: Selector,
                                                from cls: AnyClass,
                                                swizzledClasses: Set<ObjectIdentifier>) -> Bool {
        var superclass = class_getSuperclass(cls)
        while let currentClass = superclass {
            if classDirectlyImplements(selector, on: currentClass) {
                return swizzledClasses.contains(ObjectIdentifier(currentClass))
            }
            superclass = class_getSuperclass(currentClass)
        }
        return false
    }

    private static func installMessageOperationSwizzles(for concreteClass: AnyClass) {
        guard let swizzlerClass = NSClassFromString("WHWebSocketTaskSwizzler") as? NSObject.Type else { return }
        let selector = NSSelectorFromString("wormholy_ensureSwizzledForClass:")
        guard swizzlerClass.responds(to: selector) else { return }
        _ = swizzlerClass.perform(selector, with: concreteClass)
    }
}

private func wormholySwizzleInstanceMethod(_ affectedClass: AnyClass,
                                           _ original: Selector,
                                           _ swizzled: Selector,
                                           swizzledOwner: AnyClass? = nil) {
    guard let originalMethod = class_getInstanceMethod(affectedClass, original),
          let swizzledMethod = class_getInstanceMethod(swizzledOwner ?? affectedClass, swizzled) else {
        return
    }

    let originalImplementation = method_getImplementation(originalMethod)
    let swizzledImplementation = method_getImplementation(swizzledMethod)
    let didAddMethod = class_addMethod(affectedClass,
                                        original,
                                        swizzledImplementation,
                                        method_getTypeEncoding(swizzledMethod))
    if didAddMethod {
        class_replaceMethod(affectedClass,
                             swizzled,
                             originalImplementation,
                             method_getTypeEncoding(originalMethod))
    } else if class_addMethod(affectedClass,
                               swizzled,
                               originalImplementation,
                               method_getTypeEncoding(originalMethod)) {
        method_setImplementation(originalMethod, swizzledImplementation)
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

extension URLSession {
    @objc dynamic func wormholy_webSocketTaskWithURL(_ url: URL) -> URLSessionWebSocketTask {
        let task = wormholy_webSocketTaskWithURL(url)
        WebSocketInterceptor.attachModel(to: task, url: url, headers: [:], protocols: [])
        return task
    }

    @objc dynamic func wormholy_webSocketTaskWithURL(_ url: URL, protocols: [String]) -> URLSessionWebSocketTask {
        let task = wormholy_webSocketTaskWithURL(url, protocols: protocols)
        WebSocketInterceptor.attachModel(to: task, url: url, headers: [:], protocols: protocols)
        return task
    }

    @objc dynamic func wormholy_webSocketTaskWithRequest(_ request: URLRequest) -> URLSessionWebSocketTask {
        let task = wormholy_webSocketTaskWithRequest(request)
        WebSocketInterceptor.attachModel(to: task,
                                         url: request.url,
                                         headers: request.allHTTPHeaderFields ?? [:],
                                         protocols: [])
        return task
    }
}

extension URLSessionWebSocketTask {
    private static var wormholyModelKey: UInt8 = 0

    internal var wormholyModel: WebSocketModel? {
        get { objc_getAssociatedObject(self, &Self.wormholyModelKey) as? WebSocketModel }
        set { objc_setAssociatedObject(self, &Self.wormholyModelKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    @objc dynamic func wormholy_cancel(with closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        if WebSocketInterceptor.isEnabled {
            WHWebSocketRecorder.recordClosed(self, closeCode: closeCode, reason: reason)
        }
        wormholy_cancel(with: closeCode, reason: reason)
    }
}
