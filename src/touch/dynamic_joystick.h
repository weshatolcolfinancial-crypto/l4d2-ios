#pragma once

#include "../core/types.h"

#if defined(__APPLE__)
#import <UIKit/UIKit.h>
#endif

namespace l4d2 {

class DynamicJoystick {
public:
    DynamicJoystick();
    ~DynamicJoystick();

    void reset();
    bool handleTouchBegan(uintptr_t touchId, float x, float y);
    bool handleTouchMoved(uintptr_t touchId, float x, float y);
    bool handleTouchEnded(uintptr_t touchId);

    bool isActive() const { return m_active; }
    Vector2D getNormalizedVector() const { return m_outputVector; }

    float getBaseX() const { return m_baseX; }
    float getBaseY() const { return m_baseY; }
    float getThumbX() const { return m_thumbX; }
    float getThumbY() const { return m_thumbY; }
    float getRadius() const { return m_radius; }

    void setRadius(float radius) { m_radius = radius; }
    void setDeadzone(float deadzone) { m_deadzone = deadzone; }

private:
    uintptr_t m_touchId = 0;
    bool m_active = false;
    float m_baseX = 0.0f;
    float m_baseY = 0.0f;
    float m_thumbX = 0.0f;
    float m_thumbY = 0.0f;
    float m_radius = 70.0f;       // Joystick drag radius in points
    float m_deadzone = 0.12f;     // Deadzone threshold (0.0 to 1.0)
    Vector2D m_outputVector;
};

} // namespace l4d2
