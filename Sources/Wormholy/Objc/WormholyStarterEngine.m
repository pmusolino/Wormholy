#import <UIKit/UIKit.h>

@interface WormholyStarterEngine : NSObject

@end

/**
 The solution was implemented is similar to this https://stackoverflow.com/questions/49029515/is-there-an-alternative-to-initialize-in-macos-now-that-swift-has-deprecated-i/49078874#49078874
This method works like a starter engine for Wormholy. We will call `appWillLaunch()` method in Swift (under the `StarterEngine` class), when didFinishLaunchingWithOptions is fired.
This is the flow:
1) App Start
2) StarterEngine receive a `UIApplicationDidFinishLaunchingNotification`
3) The notification fire the `appWillLaunch()` method under `SwiftySelfAwareHelper`
*/
@implementation WormholyStarterEngine

static void __attribute__ ((constructor)) Initer() {

    Class class = NSClassFromString(@"Wormholy.StarterEngine");
    SEL selector = NSSelectorFromString(@"appWillLaunch:");

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

    [center addObserver:class
               selector:selector
                   name:UIApplicationDidFinishLaunchingNotification
                 object:nil];
}

@end
