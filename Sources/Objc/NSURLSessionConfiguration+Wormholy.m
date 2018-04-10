//
//  NSURLSessionConfiguration+Wormholy.m
//  Wormholy-SDK
//
//  Created by Paolo Musolino on 18/01/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

#import <Wormholy/Wormholy-Swift.h>
#import "NSURLSessionConfiguration+Wormholy.h"
#import "WormholyMethodSwizzling.h"

typedef NSURLSessionConfiguration*(*SessionConfigConstructor)(id,SEL);
static SessionConfigConstructor orig_defaultSessionConfiguration;

static NSURLSessionConfiguration* Wormholy_defaultSessionConfiguration(id self, SEL _cmd)
{
    NSURLSessionConfiguration* config = orig_defaultSessionConfiguration(self,_cmd); // call original method
    
    [Wormholy enable:YES sessionConfiguration:config];
    return config;
}

@implementation NSURLSessionConfiguration (Wormholy)

+(void)load
{
    orig_defaultSessionConfiguration = (SessionConfigConstructor)WormholyReplaceMethod(@selector(defaultSessionConfiguration),
                                                                                          (IMP)Wormholy_defaultSessionConfiguration,
                                                                                          [NSURLSessionConfiguration class],
                                                                                          YES);
}


@end
