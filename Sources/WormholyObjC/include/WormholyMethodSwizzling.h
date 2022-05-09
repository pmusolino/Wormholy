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
 */

__attribute__((warn_unused_result)) IMP WormholyReplaceMethod(SEL selector,
                                                                 IMP newImpl,
                                                                 Class affectedClass,
                                                                 BOOL isClassMethod);
