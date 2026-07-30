//
//  WormholyMethodSwizzling.h
//  Wormholy-SDK
//
//  Created by Paolo Musolino on 18/01/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#pragma mark - Method Swizzling Helpers

/**
 *  Replaces the selector's associated method implementation with the
 *  given implementation (or adds it, if there was no existing one).
 *
 *  @param selector      The selector entry in the dispatch table.
 *  @param newImpl       The implementation that will be associated with
 *                       the given selector.
 *  @param affectedClass The class whose dispatch table will be altered.
 *  @param isClassMethod Set to YES if the selector denotes a class
 *                       method, or NO if it is an instance method.
 *  @return              The previous implementation associated with
 *                       the swizzled selector. You should store the
 *                       implementation and call it when overwriting
 *                       the selector.
 *
 *  Use `WormholyReplaceMethodStoringOriginal` when another thread can
 *  invoke the replacement while installation is still in progress.
 */

__attribute__((warn_unused_result)) IMP _Nonnull WormholyReplaceMethod(SEL _Nonnull selector,
                                                              IMP _Nonnull newImpl,
                                                              Class _Nonnull affectedClass,
                                                              BOOL isClassMethod);

/**
 *  Stores the original implementation before making the replacement visible.
 *
 *  @param selector      The selector entry in the dispatch table.
 *  @param newImpl       The implementation that will replace the selector.
 *  @param affectedClass The class whose dispatch table will be altered.
 *  @param isClassMethod Set to YES if the selector denotes a class method,
 *                       or NO if it is an instance method.
 *  @param storeOriginal Receives the original implementation before the
 *                       replacement is made visible.
 */
void WormholyReplaceMethodStoringOriginal(SEL _Nonnull selector,
                                          IMP _Nonnull newImpl,
                                          Class _Nonnull affectedClass,
                                          BOOL isClassMethod,
                                          void (^ _Nonnull storeOriginal)(IMP _Nonnull originalImpl));

#if DEBUG
/**
 *  Test-only variant of `WormholyReplaceMethodStoringOriginal`.
 *
 *  @param selector      The selector entry in the dispatch table.
 *  @param newImpl       The implementation that will replace the selector.
 *  @param affectedClass The class whose dispatch table will be altered.
 *  @param isClassMethod Set to YES if the selector denotes a class method,
 *                       or NO if it is an instance method.
 *  @param storeOriginal Receives the original implementation before the
 *                       replacement is made visible.
 *  @param didReplace    Optionally observes completion of the replacement.
 */
void WormholyReplaceMethodStoringOriginalForTesting(SEL _Nonnull selector,
                                                     IMP _Nonnull newImpl,
                                                     Class _Nonnull affectedClass,
                                                     BOOL isClassMethod,
                                                     void (^ _Nonnull storeOriginal)(IMP _Nonnull originalImpl),
                                                     dispatch_block_t _Nullable didReplace);
#endif
