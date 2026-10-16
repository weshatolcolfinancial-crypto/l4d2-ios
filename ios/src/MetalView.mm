#include "MetalView.h"

#if defined(__APPLE__)
@implementation L4D2MetalView

+ (Class)layerClass {
    return [CAMetalLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _device = MTLCreateSystemDefaultDevice();
        
        CAMetalLayer* layer = (CAMetalLayer*)self.layer;
        layer.device = _device;
        layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
        layer.framebufferOnly = YES;
        layer.presentsWithTransaction = NO;
        
        // Low latency and native Retina scaling
        self.contentScaleFactor = [UIScreen mainScreen].scale;
        layer.contentsScale = self.contentScaleFactor;
    }
    return self;
}

- (CAMetalLayer *)metalLayer {
    return (CAMetalLayer*)self.layer;
}

@end
#endif
