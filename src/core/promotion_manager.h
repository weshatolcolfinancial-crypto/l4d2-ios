#pragma once

#include <functional>
#include <string>

namespace l4d2 {

class ProMotionManager {
public:
    static ProMotionManager& getInstance();

    // Initialize display link targeting up to 120Hz ProMotion
    void initialize(std::function<void(double deltaTime, double targetFPS)> frameCallback);
    void start();
    void stop();
    void setTargetFPS(float fps);

    bool isProMotionSupported() const { return m_proMotionSupported; }
    float getCurrentFPS() const { return m_currentFPS; }
    float getAverageFrameTimeMs() const { return m_frameTimeMs; }
    std::string getDisplayStatus() const;

private:
    ProMotionManager();
    ~ProMotionManager();

    bool m_proMotionSupported = false;
    float m_targetFPS = 120.0f;
    float m_currentFPS = 0.0f;
    float m_frameTimeMs = 0.0f;
    void* m_displayLink = nullptr; // Objective-C CADisplayLink pointer
    std::function<void(double, double)> m_frameCallback;
};

} // namespace l4d2
