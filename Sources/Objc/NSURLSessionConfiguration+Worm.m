//
//  NSURLSessionConfiguration+Worm.m
//  Wormholy-iOS
//
//  Created by Paolo Musolino on 28/05/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

#import "NSURLSessionConfiguration+Worm.h"
#import "WormholyMethodSwizzling.h"
#import <Wormholy/Wormholy-Swift.h>

typedef NSURLSessionConfiguration*(*SessionConfigConstructor)(id,SEL);
static SessionConfigConstructor orig_defaultSessionConfiguration;

static NSURLSessionConfiguration* Wormholy_defaultSessionConfiguration(id self, SEL _cmd)
{
    NSURLSessionConfiguration* config = orig_defaultSessionConfiguration(self,_cmd); // call original method
    
    [Wormholy enable:YES sessionConfiguration:config];
    return config;
}

@implementation NSURLSessionConfiguration (Worm)

+(void)load
{
    orig_defaultSessionConfiguration = (SessionConfigConstructor)WormholyReplaceMethod(@selector(defaultSessionConfiguration),
                                                                                       (IMP)Wormholy_defaultSessionConfiguration,
                                                                                       [NSURLSessionConfiguration class],
                                                                                       YES);
}


@end
