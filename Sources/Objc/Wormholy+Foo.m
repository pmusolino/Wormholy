//
//  Wormholy+Foo.m
//  Wormholy-SDK-iOS
//
//  Created by Paolo Musolino on 17/01/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

#if __has_include(<Wormholy/Wormholy-Swift.h>)
#import <Wormholy/Wormholy-Swift.h>
#else
#import "Wormholy-Swift.h"
#endif

@implementation Wormholy (private)
+ (void)load { [self swiftyLoad];}
+ (void)initialize { [self swiftyInitialize]; }

@end
