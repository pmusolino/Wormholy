//
//  Wormholy.h
//  Wormholy-iOS
//
//  Created by Paolo Musolino on 08/05/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//
#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif


#import "NSURLSessionConfiguration+Wormholy.h"
#import "WormholyMethodSwizzling.h"


FOUNDATION_EXPORT double WormholyVersionNumber;
FOUNDATION_EXPORT const unsigned char WormholyVersionString[];

