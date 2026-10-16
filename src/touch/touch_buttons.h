#pragma once

#include "../core/types.h"
#include <vector>
#include <string>

namespace l4d2 {

struct TouchButton {
    std::string id;
    std::string label;
    Command command;
    float x = 0.0f;
    float y = 0.0f;
    float width = 64.0f;
    float height = 64.0f;
    bool isCircle = true;
    bool isPressed = false;
    uintptr_t touchId = 0;
    bool isToggle = false;
    bool toggleState = false;

    bool contains(float px, float py) const {
        if (isCircle) {
            float radius = width * 0.5f;
            float cx = x + radius;
            float cy = y + radius;
            float dx = px - cx;
            float dy = py - cy;
            return (dx * dx + dy * dy) <= (radius * radius);
        } else {
            return px >= x && px <= (x + width) && py >= y && py <= (y + height);
        }
    }
};

class TouchButtons {
public:
    TouchButtons();
    ~TouchButtons();

    void initializeDefaultLayout(float screenWidth, float screenHeight);
    bool handleTouchBegan(uintptr_t touchId, float x, float y);
    bool handleTouchMoved(uintptr_t touchId, float x, float y);
    bool handleTouchEnded(uintptr_t touchId, float x, float y);

    uint32_t getActiveCommandMask() const;
    bool isCommandActive(Command cmd) const;
    bool consumeFlashlightToggle();
    bool consumeConsoleToggle();

    const std::vector<TouchButton>& getButtons() const { return m_buttons; }
    void setButtonPosition(const std::string& id, float x, float y, float size);

private:
    std::vector<TouchButton> m_buttons;
    bool m_pendingFlashlight = false;
    bool m_pendingConsoleToggle = false;
};

} // namespace l4d2
