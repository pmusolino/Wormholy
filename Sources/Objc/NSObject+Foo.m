//
//  NSObject+Foo.m
//  Wormholy-iOS
//
//  Created by Paolo Musolino on 28/05/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

#import "NSObject+Foo.h"
#import <Wormholy/Wormholy-Swift.h>

@implementation NSObject (Foo)
+ (void)load { [Wormholy swiftyLoad];}
+ (void)initialize { [Wormholy swiftyInitialize]; }
@end
