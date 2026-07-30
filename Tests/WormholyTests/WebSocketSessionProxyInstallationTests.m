// Copyright (c) 2026 Wormholy contributors
// SPDX-License-Identifier: MIT

@import XCTest;
@import WormholyObjC;

#import <stdatomic.h>

#if DEBUG

typedef NSString *(*WHExampleFactoryIMP)(id, SEL);

static _Atomic(IMP) whExampleOriginalFactory;
static _Atomic(NSInteger) whExampleForwardedCallCount;

@interface WHSessionFactoryExample : NSObject
+ (NSString *)makeSession;
@end

static NSString *WHExampleFactoryWrapper(id self, SEL _cmd) {
    WHExampleFactoryIMP originalImplementation = (WHExampleFactoryIMP)atomic_load_explicit(&whExampleOriginalFactory,
                                                                                              memory_order_acquire);
    if (!originalImplementation) {
        return @"missing original implementation";
    }
    return originalImplementation(self, _cmd);
}

@implementation WHSessionFactoryExample

+ (NSString *)makeSession {
    return @"original factory";
}

@end

@interface WebSocketSessionProxyInstallationTests : XCTestCase
@end

@implementation WebSocketSessionProxyInstallationTests

- (void)testConcurrentFirstInstallationPublishesOriginalBeforeWrapperIsReachable {
    dispatch_semaphore_t replacementCompleted = dispatch_semaphore_create(0);
    dispatch_semaphore_t allowInstallationToFinish = dispatch_semaphore_create(0);
    dispatch_semaphore_t installationFinished = dispatch_semaphore_create(0);
    dispatch_semaphore_t startCallers = dispatch_semaphore_create(0);
    dispatch_group_t readyCallers = dispatch_group_create();
    dispatch_group_t callers = dispatch_group_create();
    atomic_store_explicit(&whExampleOriginalFactory, NULL, memory_order_relaxed);
    atomic_store_explicit(&whExampleForwardedCallCount, 0, memory_order_relaxed);

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        WormholyReplaceMethodStoringOriginalForTesting(@selector(makeSession),
                                                       (IMP)WHExampleFactoryWrapper,
                                                       WHSessionFactoryExample.class,
                                                       YES,
                                                       ^(IMP originalImplementation) {
                                                           atomic_store_explicit(&whExampleOriginalFactory,
                                                                                 originalImplementation,
                                                                                 memory_order_release);
                                                       },
                                                       ^{
                                                           dispatch_semaphore_signal(replacementCompleted);
                                                           dispatch_semaphore_wait(allowInstallationToFinish, DISPATCH_TIME_FOREVER);
                                                       });
        dispatch_semaphore_signal(installationFinished);
    });

    XCTAssertEqual(dispatch_semaphore_wait(replacementCompleted, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC)), 0);

    for (NSInteger index = 0; index < 32; index++) {
        dispatch_group_enter(readyCallers);
        dispatch_group_enter(callers);
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            dispatch_group_leave(readyCallers);
            dispatch_semaphore_wait(startCallers, DISPATCH_TIME_FOREVER);
            if ([[WHSessionFactoryExample makeSession] isEqualToString:@"original factory"]) {
                atomic_fetch_add_explicit(&whExampleForwardedCallCount, 1, memory_order_relaxed);
            }
            dispatch_group_leave(callers);
        });
    }

    XCTAssertEqual(dispatch_group_wait(readyCallers, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC)), 0);
    for (NSInteger index = 0; index < 32; index++) {
        dispatch_semaphore_signal(startCallers);
    }
    XCTAssertEqual(dispatch_group_wait(callers, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC)), 0);
    XCTAssertEqual(atomic_load_explicit(&whExampleForwardedCallCount, memory_order_relaxed), 32);
    dispatch_semaphore_signal(allowInstallationToFinish);
    XCTAssertEqual(dispatch_semaphore_wait(installationFinished, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC)), 0);

    Method method = class_getClassMethod(WHSessionFactoryExample.class, @selector(makeSession));
    method_setImplementation(method, atomic_load_explicit(&whExampleOriginalFactory, memory_order_acquire));
    atomic_store_explicit(&whExampleOriginalFactory, NULL, memory_order_relaxed);
}

@end

#endif
