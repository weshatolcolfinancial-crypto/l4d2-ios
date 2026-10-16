#include "AppDelegate.h"
#include "GameViewController.h"
#include "../../src/core/engine_bridge.h"
#include "../../src/logging/logger.h"

#if defined(__APPLE__)
#import <AVFoundation/AVFoundation.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // 1. Prevent screen sleep during gameplay
    application.idleTimerDisabled = YES;

    // 2. Configure audio session for low latency and background resilience
    NSError* audioError = nil;
    AVAudioSession* audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryAmbient error:&audioError];
    [audioSession setActive:YES error:&audioError];

    // 3. Initialize window and root view controller
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    GameViewController* gameVC = [[GameViewController alloc] init];
    self.window.rootViewController = gameVC;
    [self.window makeKeyAndVisible];

    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    l4d2::EngineBridge::getInstance().pause();
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    l4d2::EngineBridge::getInstance().resume();
}

- (void)applicationWillTerminate:(UIApplication *)application {
    l4d2::EngineBridge::getInstance().shutdown();
}

@end
#endif
