#if defined(__APPLE__)
#import <UIKit/UIKit.h>
#import "AppDelegate.h"

int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
#else
#include <iostream>

int main(int argc, char* argv[]) {
    std::cout << "Left 4 Dead 2 iOS host build target." << std::endl;
    return 0;
}
#endif
