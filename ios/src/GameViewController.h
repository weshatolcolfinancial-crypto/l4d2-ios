#pragma once

#if defined(__APPLE__)
#import <UIKit/UIKit.h>

@interface GameViewController : UIViewController
- (void)checkAndInitializeEngine;
@end
#endif
