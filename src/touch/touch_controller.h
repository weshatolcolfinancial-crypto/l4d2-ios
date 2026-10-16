#pragma once

#include "../core/types.h"
#include "dynamic_joystick.h"
#include "touch_buttons.h"
#include "weapon_switcher.h"

#include <memory>
#include <map>

namespace l4d2 {

class TouchController {
public:
    TouchController();
    ~TouchController();

    void initialize(float screenWidth, float screenHeight);
    void updateScreenSize(float screenWidth, float screenHeight);

    // Multi-touch dispatch
    void onTouchBegan(uintptr_t touchId, float x, float y);
    void onTouchMoved(uintptr_t touchId, float x, float y);
    void onTouchEnded(uintptr_t touchId, float x, float y);
    void onTouchCancelled(uintptr_t touchId);

    // Collect all inputs and reset per-frame deltas
    InputFrameState pollInputState();

    // Accessors
    const DynamicJoystick& getJoystick() const { return m_joystick; }
    const TouchButtons& getButtons() const { return m_buttons; }
    const WeaponSwitcher& getWeaponSwitcher() const { return m_weaponSwitcher; }

    void setLookSensitivity(float sensX, float sensY) { m_sensX = sensX; m_sensY = sensY; }
    bool isConsoleRequested();

private:
    float m_screenWidth = 0.0f;
    float m_screenHeight = 0.0f;

    DynamicJoystick m_joystick;
    TouchButtons m_buttons;
    WeaponSwitcher m_weaponSwitcher;

    // Camera look tracking (right screen quadrant)
    uintptr_t m_lookTouchId = 0;
    float m_lastLookX = 0.0f;
    float m_lastLookY = 0.0f;
    Vector2D m_accumulatedLookDelta;
    float m_sensX = 1.25f;
    float m_sensY = 1.0f;
};

} // namespace l4d2
