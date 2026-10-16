#include "dynamic_joystick.h"
#include <cmath>

namespace l4d2 {

DynamicJoystick::DynamicJoystick() {
    reset();
}

DynamicJoystick::~DynamicJoystick() = default;

void DynamicJoystick::reset() {
    m_touchId = 0;
    m_active = false;
    m_baseX = 0.0f;
    m_baseY = 0.0f;
    m_thumbX = 0.0f;
    m_thumbY = 0.0f;
    m_outputVector = Vector2D(0.0f, 0.0f);
}

bool DynamicJoystick::handleTouchBegan(uintptr_t touchId, float x, float y) {
    if (m_active) return false;

    m_touchId = touchId;
    m_active = true;
    m_baseX = x;
    m_baseY = y;
    m_thumbX = x;
    m_thumbY = y;
    m_outputVector = Vector2D(0.0f, 0.0f);
    return true;
}

bool DynamicJoystick::handleTouchMoved(uintptr_t touchId, float x, float y) {
    if (!m_active || m_touchId != touchId) return false;

    float dx = x - m_baseX;
    float dy = y - m_baseY;
    float dist = std::sqrt(dx * dx + dy * dy);

    if (dist > m_radius && dist > 0.0001f) {
        float scale = m_radius / dist;
        dx *= scale;
        dy *= scale;
        m_thumbX = m_baseX + dx;
        m_thumbY = m_baseY + dy;
    } else {
        m_thumbX = x;
        m_thumbY = y;
    }

    // Normalized vector calculation with deadzone
    float normalizedDist = dist / m_radius;
    if (normalizedDist < m_deadzone) {
        m_outputVector = Vector2D(0.0f, 0.0f);
    } else {
        float remappedDist = (normalizedDist - m_deadzone) / (1.0f - m_deadzone);
        if (remappedDist > 1.0f) remappedDist = 1.0f;
        float angle = std::atan2(dy, dx);
        m_outputVector.x = std::cos(angle) * remappedDist;
        m_outputVector.y = std::sin(angle) * remappedDist;
    }

    return true;
}

bool DynamicJoystick::handleTouchEnded(uintptr_t touchId) {
    if (m_active && m_touchId == touchId) {
        reset();
        return true;
    }
    return false;
}

} // namespace l4d2
