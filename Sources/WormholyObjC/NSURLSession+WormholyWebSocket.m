// Copyright (c) 2026 Wormholy contributors
// SPDX-License-Identifier: MIT

#import "WormholyMethodSwizzling.h"
#import <objc/runtime.h>
#import <stdatomic.h>

#if SWIFT_PACKAGE
@import WormholySwift;
#else
#import <Wormholy/Wormholy-Swift.h>
#endif

typedef NSURLSession * _Nonnull (*WHSessionWithDelegateIMP)(id, SEL, NSURLSessionConfiguration *, id<NSURLSessionDelegate>, NSOperationQueue *);

static _Atomic(IMP) wormholyOrigSessionWithConfigurationDelegateQueue;
static BOOL wormholySessionSwizzleInstalled = NO;
static const void *WHOriginalDelegateKey = &WHOriginalDelegateKey;

@interface WHWebSocketSessionDelegateProxy : NSObject <NSURLSessionWebSocketDelegate>
@property (nonatomic, strong, readonly) id<NSURLSessionDelegate> originalDelegate;
- (instancetype)initWithDelegate:(id<NSURLSessionDelegate>)delegate;
@end

@implementation WHWebSocketSessionDelegateProxy

- (instancetype)initWithDelegate:(id<NSURLSessionDelegate>)delegate {
    self = [super init];
    if (self) {
        _originalDelegate = delegate;
    }
    return self;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [super respondsToSelector:aSelector] || [self.originalDelegate respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    if ([self.originalDelegate respondsToSelector:aSelector]) {
        return self.originalDelegate;
    }
    return [super forwardingTargetForSelector:aSelector];
}

- (void)URLSession:(NSURLSession *)session
     webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask
didOpenWithProtocol:(NSString *)protocol {
    if ([WHWebSocketRecorder isEnabled]) {
        [WHWebSocketRecorder recordOpened:webSocketTask protocol:protocol];
    }

    id<NSURLSessionDelegate> delegate = self.originalDelegate;
    if ([delegate respondsToSelector:_cmd]) {
        [(id<NSURLSessionWebSocketDelegate>)delegate URLSession:session webSocketTask:webSocketTask didOpenWithProtocol:protocol];
    }
}

- (void)URLSession:(NSURLSession *)session
     webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask
  didCloseWithCode:(NSURLSessionWebSocketCloseCode)closeCode
            reason:(NSData *)reason {
    if ([WHWebSocketRecorder isEnabled]) {
        [WHWebSocketRecorder recordClosed:webSocketTask closeCode:(NSInteger)closeCode reason:reason];
    }

    id<NSURLSessionDelegate> delegate = self.originalDelegate;
    if ([delegate respondsToSelector:_cmd]) {
        [(id<NSURLSessionWebSocketDelegate>)delegate URLSession:session webSocketTask:webSocketTask didCloseWithCode:closeCode reason:reason];
    }
}

@end

static NSURLSession *Wormholy_sessionWithConfigurationDelegateQueue(id self,
                                                                    SEL _cmd,
                                                                    NSURLSessionConfiguration *configuration,
                                                                    id<NSURLSessionDelegate> delegate,
                                                                    NSOperationQueue *queue)
{
    id effectiveDelegate = delegate;
    WHWebSocketSessionDelegateProxy *proxy = nil;

    if ([WHWebSocketRecorder isEnabled] && delegate && ![delegate isKindOfClass:[WHWebSocketSessionDelegateProxy class]]) {
        proxy = [[WHWebSocketSessionDelegateProxy alloc] initWithDelegate:delegate];
        effectiveDelegate = proxy;
    }

    WHSessionWithDelegateIMP originalImplementation = (WHSessionWithDelegateIMP)atomic_load_explicit(&wormholyOrigSessionWithConfigurationDelegateQueue,
                                                                                                        memory_order_acquire);
    NSURLSession *session = originalImplementation(self, _cmd, configuration, effectiveDelegate, queue);
    if (proxy) {
        objc_setAssociatedObject(session, WHOriginalDelegateKey, proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return session;
}

@interface WHWebSocketSessionSwizzler : NSObject
@end

@implementation WHWebSocketSessionSwizzler

+ (void)wormholy_installWebSocketDelegateProxy {
    @synchronized (self) {
        if (wormholySessionSwizzleInstalled) return;

        WormholyReplaceMethodStoringOriginal(@selector(sessionWithConfiguration:delegate:delegateQueue:),
                                             (IMP)Wormholy_sessionWithConfigurationDelegateQueue,
                                             [NSURLSession class],
                                             YES,
                                             ^(IMP originalImplementation) {
                                                 atomic_store_explicit(&wormholyOrigSessionWithConfigurationDelegateQueue,
                                                                       originalImplementation,
                                                                       memory_order_release);
                                             });
        wormholySessionSwizzleInstalled = YES;
    }
}

@end
