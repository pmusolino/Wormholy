//
//  NSURLSessionConfiguration+Wormholy.m
//  Wormholy-SDK
//
//  Created by Paolo Musolino on 18/01/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

#import "NSURLSessionConfiguration+Wormholy.h"
#import "WormholyMethodSwizzling.h"
#if __has_include(<Wormholy/Wormholy-Swift.h>)
#import <Wormholy/Wormholy-Swift.h>
#else
#import "Wormholy-Swift.h"
#endif

typedef NSURLSessionConfiguration*(*SessionConfigConstructor)(id,SEL);
static SessionConfigConstructor orig_defaultSessionConfiguration;
static SessionConfigConstructor orig_ephemeralSessionConfiguration;

static NSURLSessionConfiguration* Wormholy_defaultSessionConfiguration(id self, SEL _cmd)
{
    NSURLSessionConfiguration* config = orig_defaultSessionConfiguration(self,_cmd); // call original method
    
    [Wormholy enable:YES sessionConfiguration:config];
    return config;
}

static NSURLSessionConfiguration* Wormholy_ephemeralSessionConfiguration(id self, SEL _cmd)
{
    NSURLSessionConfiguration* config = orig_ephemeralSessionConfiguration(self,_cmd); // call original method
    
    [Wormholy enable:YES sessionConfiguration:config];
    return config;
}

__attribute__((constructor)) static void sessionConfigurationInjectEntry(void) {
    
    orig_defaultSessionConfiguration = (SessionConfigConstructor)WormholyReplaceMethod(@selector(defaultSessionConfiguration),
                                                                                       (IMP)Wormholy_defaultSessionConfiguration,
                                                                                       [NSURLSessionConfiguration class],
                                                                                       YES);
    
    orig_ephemeralSessionConfiguration = (SessionConfigConstructor)WormholyReplaceMethod(@selector(ephemeralSessionConfiguration),
                                                                                         (IMP)Wormholy_ephemeralSessionConfiguration,
                                                                                         [NSURLSessionConfiguration class],
                                                                                         YES);
}

