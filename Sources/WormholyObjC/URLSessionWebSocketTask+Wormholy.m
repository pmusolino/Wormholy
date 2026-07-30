// Copyright (c) 2026 Wormholy contributors
// SPDX-License-Identifier: MIT
//
//  Swizzles NSURLSessionWebSocketTask's send/receive methods directly in Objective-C.
//  Their message payload (`NSURLSessionWebSocketMessage *`) isn't representable in Swift's
//  `@objc`, so this can't be done via a Swift extension the way the rest of Wormholy's
//  swizzling is - see WebSocketInterceptor.swift for the counterpart handling the
//  WebSocket factory methods and `cancel(with:reason:)`.
//
//  `-[NSURLSessionWebSocketTask sendMessage:completionHandler:]` and
//  `receiveMessageWithCompletionHandler:` aren't actually implemented on the public
//  NSURLSessionWebSocketTask class - `[session webSocketTaskWithURL:]` returns an instance
//  of a private concrete subclass that provides the real implementation. Swizzling the
//  public class's method table has no effect on those instances, so this swizzles the
//  *actual* runtime class of each task instead, the first time one is seen.

#import "URLSessionWebSocketTask+Wormholy.h"
#import "WormholyMethodSwizzling.h"
#import <objc/runtime.h>

#if SWIFT_PACKAGE
@import WormholySwift;
#else
#import <Wormholy/Wormholy-Swift.h>
#endif

typedef void (^WHSendCompletion)(NSError * _Nullable);
typedef void (^WHReceiveCompletion)(NSURLSessionWebSocketMessage * _Nullable, NSError * _Nullable);

typedef void (*WHSendIMP)(id, SEL, NSURLSessionWebSocketMessage *, WHSendCompletion);
typedef void (*WHReceiveIMP)(id, SEL, WHReceiveCompletion);

static NSMutableSet<NSValue *> *wormholySwizzledClasses;
static NSMutableDictionary<NSValue *, NSValue *> *wormholyOrigSendIMPs;
static NSMutableDictionary<NSValue *, NSValue *> *wormholyOrigReceiveIMPs;

static BOOL WHClassDirectlyImplementsSelector(Class cls, SEL selector) {
    Method method = class_getInstanceMethod(cls, selector);
    Class superclass = class_getSuperclass(cls);
    Method inheritedMethod = superclass ? class_getInstanceMethod(superclass, selector) : NULL;
    return method && method != inheritedMethod;
}

static IMP WHOriginalIMPForClass(NSDictionary<NSValue *, NSValue *> *originalIMPs, Class cls) {
    @synchronized (originalIMPs) {
        for (Class currentClass = cls; currentClass != Nil; currentClass = class_getSuperclass(currentClass)) {
            NSValue *classKey = [NSValue valueWithNonretainedObject:currentClass];
            NSValue *originalIMP = originalIMPs[classKey];
            if (originalIMP) {
                return originalIMP.pointerValue;
            }
        }
    }
    return NULL;
}

static IMP WHInheritedOriginalIMP(NSDictionary<NSValue *, NSValue *> *originalIMPs, Class cls, SEL selector) {
    for (Class currentClass = class_getSuperclass(cls); currentClass != Nil; currentClass = class_getSuperclass(currentClass)) {
        if (WHClassDirectlyImplementsSelector(currentClass, selector)) {
            NSValue *classKey = [NSValue valueWithNonretainedObject:currentClass];
            @synchronized (originalIMPs) {
                return [originalIMPs[classKey] pointerValue];
            }
        }
    }
    return NULL;
}

static void recordSentOrErrored(NSURLSessionWebSocketTask *task, NSURLSessionWebSocketMessage *message, NSError * _Nullable error) {
    if (![WHWebSocketRecorder isEnabled]) return;

    if (error) {
        [WHWebSocketRecorder recordError:task error:error];
    } else if (message.type == NSURLSessionWebSocketMessageTypeString) {
        [WHWebSocketRecorder recordSentText:task text:message.string ?: @""];
    } else {
        [WHWebSocketRecorder recordSentData:task data:message.data ?: [NSData data]];
    }
}

static void recordReceivedOrErrored(NSURLSessionWebSocketTask *task, NSURLSessionWebSocketMessage * _Nullable message, NSError * _Nullable error) {
    if (![WHWebSocketRecorder isEnabled]) return;

    if (error) {
        [WHWebSocketRecorder recordError:task error:error];
    } else if (message.type == NSURLSessionWebSocketMessageTypeString) {
        [WHWebSocketRecorder recordReceivedText:task text:message.string ?: @""];
    } else if (message) {
        [WHWebSocketRecorder recordReceivedData:task data:message.data ?: [NSData data]];
    }
}

static void Wormholy_sendMessage(NSURLSessionWebSocketTask *self, SEL _cmd, NSURLSessionWebSocketMessage *message, WHSendCompletion completionHandler) {
    WHSendIMP orig = (WHSendIMP)WHOriginalIMPForClass(wormholyOrigSendIMPs, object_getClass(self));
    if (!orig) {
        if (completionHandler) {
            completionHandler([NSError errorWithDomain:@"WormholyWebSocket"
                                                  code:1
                                              userInfo:@{NSLocalizedDescriptionKey: @"Wormholy could not find the original WebSocket send implementation."}]);
        }
        return;
    }

    orig(self, _cmd, message, ^(NSError * _Nullable error) {
        recordSentOrErrored(self, message, error);
        if (completionHandler) completionHandler(error);
    });
}

static void Wormholy_receiveMessage(NSURLSessionWebSocketTask *self, SEL _cmd, WHReceiveCompletion completionHandler) {
    WHReceiveIMP orig = (WHReceiveIMP)WHOriginalIMPForClass(wormholyOrigReceiveIMPs, object_getClass(self));
    if (!orig) {
        if (completionHandler) {
            completionHandler(nil, [NSError errorWithDomain:@"WormholyWebSocket"
                                                       code:2
                                                   userInfo:@{NSLocalizedDescriptionKey: @"Wormholy could not find the original WebSocket receive implementation."}]);
        }
        return;
    }

    orig(self, _cmd, ^(NSURLSessionWebSocketMessage * _Nullable message, NSError * _Nullable error) {
        recordReceivedOrErrored(self, message, error);
        if (completionHandler) completionHandler(message, error);
    });
}

/// Exposed to Swift via `NSClassFromString` + `perform(_:with:)` (no compile-time dependency
/// from WormholySwift on WormholyObjC), called the first time each WebSocket factory method
/// attaches a model to a task - see `WebSocketInterceptor.ensureSwizzledForActualClass`.
@interface WHWebSocketTaskSwizzler : NSObject
+ (void)wormholy_ensureSwizzledFor:(NSURLSessionWebSocketTask *)task;
+ (void)wormholy_ensureSwizzledForClass:(Class)cls;
@end

@implementation WHWebSocketTaskSwizzler

+ (void)load {
    wormholySwizzledClasses = [NSMutableSet set];
    wormholyOrigSendIMPs = [NSMutableDictionary dictionary];
    wormholyOrigReceiveIMPs = [NSMutableDictionary dictionary];
}

+ (void)wormholy_ensureSwizzledFor:(NSURLSessionWebSocketTask *)task {
    Class cls = object_getClass(task);
    [self wormholy_ensureSwizzledForClass:cls];
}

+ (void)wormholy_ensureSwizzledForClass:(Class)cls {
    if (!cls) return;

    NSValue *classKey = [NSValue valueWithNonretainedObject:cls];

    @synchronized (wormholySwizzledClasses) {
        if ([wormholySwizzledClasses containsObject:classKey]) return;

        SEL sendSelector = @selector(sendMessage:completionHandler:);
        SEL receiveSelector = @selector(receiveMessageWithCompletionHandler:);
        BOOL implementsSendDirectly = WHClassDirectlyImplementsSelector(cls, sendSelector);
        BOOL implementsReceiveDirectly = WHClassDirectlyImplementsSelector(cls, receiveSelector);
        IMP inheritedSend = WHInheritedOriginalIMP(wormholyOrigSendIMPs, cls, sendSelector);
        IMP inheritedReceive = WHInheritedOriginalIMP(wormholyOrigReceiveIMPs, cls, receiveSelector);

        if (implementsSendDirectly || !inheritedSend) {
            Method sendMethod = class_getInstanceMethod(cls, sendSelector);
            IMP origSend = sendMethod ? method_getImplementation(sendMethod) : NULL;
            if (origSend && origSend != (IMP)Wormholy_sendMessage) {
                @synchronized (wormholyOrigSendIMPs) {
                    wormholyOrigSendIMPs[classKey] = [NSValue valueWithPointer:origSend];
                }
                WormholyReplaceMethod(sendSelector, (IMP)Wormholy_sendMessage, cls, NO);
            }
        }

        if (implementsReceiveDirectly || !inheritedReceive) {
            Method receiveMethod = class_getInstanceMethod(cls, receiveSelector);
            IMP origReceive = receiveMethod ? method_getImplementation(receiveMethod) : NULL;
            if (origReceive && origReceive != (IMP)Wormholy_receiveMessage) {
                @synchronized (wormholyOrigReceiveIMPs) {
                    wormholyOrigReceiveIMPs[classKey] = [NSValue valueWithPointer:origReceive];
                }
                WormholyReplaceMethod(receiveSelector, (IMP)Wormholy_receiveMessage, cls, NO);
            }
        }

        [wormholySwizzledClasses addObject:classKey];
    }
}

@end
