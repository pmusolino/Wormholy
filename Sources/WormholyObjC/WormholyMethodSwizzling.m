//
//  WormholyMethodSwizzling.m
//  Wormholy-SDK
//
//  Created by Paolo Musolino on 18/01/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

#import "WormholyMethodSwizzling.h"

#pragma mark - Method Swizzling Helpers

static IMP WHReplaceMethod(SEL selector,
                           IMP newImpl,
                           Class affectedClass,
                           BOOL isClassMethod,
                           void (^storeOriginal)(IMP originalImpl),
                           dispatch_block_t didReplace)
{
    Method origMethod = isClassMethod ? class_getClassMethod(affectedClass, selector) : class_getInstanceMethod(affectedClass, selector);
    IMP origImpl = method_getImplementation(origMethod);

    if (storeOriginal) {
        storeOriginal(origImpl);
    }

    if (!class_addMethod(isClassMethod ? object_getClass(affectedClass) : affectedClass, selector, newImpl, method_getTypeEncoding(origMethod)))
    {
        method_setImplementation(origMethod, newImpl);
    }

    if (didReplace) {
        didReplace();
    }

    return origImpl;
}

IMP WormholyReplaceMethod(SEL selector,
                          IMP newImpl,
                          Class affectedClass,
                          BOOL isClassMethod)
{
    return WHReplaceMethod(selector, newImpl, affectedClass, isClassMethod, nil, nil);
}

void WormholyReplaceMethodStoringOriginal(SEL selector,
                                          IMP newImpl,
                                          Class affectedClass,
                                          BOOL isClassMethod,
                                          void (^storeOriginal)(IMP originalImpl))
{
    WHReplaceMethod(selector, newImpl, affectedClass, isClassMethod, storeOriginal, nil);
}

#if DEBUG
void WormholyReplaceMethodStoringOriginalForTesting(SEL selector,
                                                     IMP newImpl,
                                                     Class affectedClass,
                                                     BOOL isClassMethod,
                                                     void (^storeOriginal)(IMP originalImpl),
                                                     dispatch_block_t didReplace)
{
    WHReplaceMethod(selector, newImpl, affectedClass, isClassMethod, storeOriginal, didReplace);
}
#endif
