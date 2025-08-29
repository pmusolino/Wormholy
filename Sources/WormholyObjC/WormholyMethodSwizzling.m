//
//  WormholyMethodSwizzling.m
//  Wormholy-SDK
//
//  Created by Paolo Musolino on 18/01/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

#import "WormholyMethodSwizzling.h"

#pragma mark - Method Swizzling Helpers

IMP WormholyReplaceMethod(SEL selector,
                             IMP newImpl,
                             Class affectedClass,
                             BOOL isClassMethod)
{
    Method origMethod = isClassMethod ? class_getClassMethod(affectedClass, selector) : class_getInstanceMethod(affectedClass, selector);
    IMP origImpl = method_getImplementation(origMethod);
    
    if (!class_addMethod(isClassMethod ? object_getClass(affectedClass) : affectedClass, selector, newImpl, method_getTypeEncoding(origMethod)))
    {
        method_setImplementation(origMethod, newImpl);
    }
    
    return origImpl;
}
