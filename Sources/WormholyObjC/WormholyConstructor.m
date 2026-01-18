#import <UIKit/UIKit.h>

/// Library constructor to observe `UIApplicationDidFinishLaunchingNotification` immediately on app launch.
/// Calls `applicationDidFinishLaunching` on Wormholy class to initialize Wormholy.
/// This is an alternative to a +initialize in Objective-C.
static void __attribute__ ((constructor)) wormholy_constructor(void) {
#if SWIFT_PACKAGE
    Class class = NSClassFromString(@"WormholySwift.Wormholy");
#else
    Class class = NSClassFromString(@"Wormholy.Wormholy");
#endif
    SEL selector = NSSelectorFromString(@"applicationDidFinishLaunching");
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center addObserver:class
               selector:selector
                   name:UIApplicationDidFinishLaunchingNotification
                 object:nil];
}
