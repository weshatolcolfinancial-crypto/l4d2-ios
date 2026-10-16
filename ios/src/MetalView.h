#pragma once

#if defined(__APPLE__)
#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

@interface L4D2MetalView : UIView
@property (nonatomic, readonly) CAMetalLayer* metalLayer;
@property (nonatomic, readonly) id<MTLDevice> device;
@end
#endif
