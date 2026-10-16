#include "promotion_manager.h"
#include "../logging/logger.h"

#if defined(__APPLE__)
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface L4D2DisplayLinkTarget : NSObject
@property (nonatomic, assign) std::function<void(double, double)>* callback;
@property (nonatomic, assign) float* currentFPS;
@property (nonatomic, assign) float* frameTimeMs;
- (void)onDisplayFrame:(CADisplayLink *)link;
@end

@implementation L4D2DisplayLinkTarget {
    CFTimeInterval _lastTimestamp;
    CFTimeInterval _accumTime;
    int _frameCount;
}

- (instancetype)init {
    if (self = [super init]) {
        _lastTimestamp = 0;
        _accumTime = 0;
        _frameCount = 0;
    }
    return self;
}

- (void)onDisplayFrame:(CADisplayLink *)link {
    CFTimeInterval current = link.timestamp;
    if (_lastTimestamp == 0) {
        _lastTimestamp = current;
        return;
    }

    CFTimeInterval dt = current - _lastTimestamp;
    _lastTimestamp = current;

    _accumTime += dt;
    _frameCount++;
    if (_accumTime >= 0.5) { // Update FPS counter every half second
        if (self.currentFPS) {
            *self.currentFPS = static_cast<float>(_frameCount / _accumTime);
        }
        if (self.frameTimeMs) {
            *self.frameTimeMs = static_cast<float>((_accumTime / _frameCount) * 1000.0);
        }
        _frameCount = 0;
        _accumTime = 0;
    }

    if (self.callback && *(self.callback)) {
        double targetFPS = link.targetTimestamp > link.timestamp ? 
                           (1.0 / (link.targetTimestamp - link.timestamp)) : 60.0;
        (*(self.callback))(dt, targetFPS);
    }
}
@end

#endif

namespace l4d2 {

ProMotionManager& ProMotionManager::getInstance() {
    static ProMotionManager instance;
    return instance;
}

ProMotionManager::ProMotionManager() {
#if defined(__APPLE__)
    NSInteger maxFPS = [UIScreen mainScreen].maximumFramesPerSecond;
    m_proMotionSupported = (maxFPS >= 120);
    m_targetFPS = m_proMotionSupported ? 120.0f : static_cast<float>(maxFPS);
    L4D2_LOG_INFO("Display", "Display max refresh rate: %ld Hz (ProMotion 120Hz %s)", 
                  (long)maxFPS, m_proMotionSupported ? "SUPPORTED" : "UNAVAILABLE");
#else
    m_proMotionSupported = false;
    m_targetFPS = 60.0f;
#endif
}

ProMotionManager::~ProMotionManager() {
    stop();
}

void ProMotionManager::initialize(std::function<void(double deltaTime, double targetFPS)> frameCallback) {
    m_frameCallback = frameCallback;

#if defined(__APPLE__)
    L4D2DisplayLinkTarget* target = [[L4D2DisplayLinkTarget alloc] init];
    target.callback = &m_frameCallback;
    target.currentFPS = &m_currentFPS;
    target.frameTimeMs = &m_frameTimeMs;

    CADisplayLink* link = [CADisplayLink displayLinkWithTarget:target selector:@selector(onDisplayFrame:)];

    // Configure for ProMotion 120Hz display refresh
    if (@available(iOS 15.0, *)) {
        CAFrameRateRange range = CAFrameRateRangeMake(60.0f, 120.0f, 120.0f);
        link.preferredFrameRateRange = range;
        L4D2_LOG_INFO("Display", "Configured CADisplayLink preferredFrameRateRange (60-120 Hz)");
    } else {
        link.preferredFramesPerSecond = 120;
    }

    [link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    m_displayLink = (__bridge_retained void*)link;
#endif
}

void ProMotionManager::start() {
#if defined(__APPLE__)
    if (m_displayLink) {
        CADisplayLink* link = (__bridge CADisplayLink*)m_displayLink;
        link.paused = NO;
        L4D2_LOG_INFO("Display", "Display link started.");
    }
#endif
}

void ProMotionManager::stop() {
#if defined(__APPLE__)
    if (m_displayLink) {
        CADisplayLink* link = (__bridge_transfer CADisplayLink*)m_displayLink;
        [link invalidate];
        m_displayLink = nullptr;
        L4D2_LOG_INFO("Display", "Display link stopped.");
    }
#endif
}

void ProMotionManager::setTargetFPS(float fps) {
    m_targetFPS = fps;
#if defined(__APPLE__)
    if (m_displayLink) {
        CADisplayLink* link = (__bridge CADisplayLink*)m_displayLink;
        if (@available(iOS 15.0, *)) {
            link.preferredFrameRateRange = CAFrameRateRangeMake(30.0f, fps, fps);
        } else {
            link.preferredFramesPerSecond = static_cast<NSInteger>(fps);
        }
    }
#endif
}

std::string ProMotionManager::getDisplayStatus() const {
    char buf[128];
    snprintf(buf, sizeof(buf), "%.1f FPS (%.2f ms) | Mode: %s (Target: %.0f Hz)",
             m_currentFPS, m_frameTimeMs,
             m_proMotionSupported ? "ProMotion 120Hz" : "Standard 60Hz",
             m_targetFPS);
    return std::string(buf);
}

} // namespace l4d2
