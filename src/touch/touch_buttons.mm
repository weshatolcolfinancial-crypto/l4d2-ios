#include "touch_buttons.h"

#if defined(__APPLE__)
#import <UIKit/UIKit.h>
#endif

namespace l4d2 {

TouchButtons::TouchButtons() = default;
TouchButtons::~TouchButtons() = default;

void TouchButtons::initializeDefaultLayout(float screenWidth, float screenHeight) {
    m_buttons.clear();

    // 1. Primary Fire (+attack) - Large right combat button
    TouchButton btnAttack;
    btnAttack.id = "btn_attack";
    btnAttack.label = "FIRE";
    btnAttack.command = Command::ATTACK;
    btnAttack.width = 76.0f;
    btnAttack.height = 76.0f;
    btnAttack.x = screenWidth - 110.0f;
    btnAttack.y = screenHeight - 150.0f;
    btnAttack.isCircle = true;
    m_buttons.push_back(btnAttack);

    // 2. Melee / Shove (+attack2) - Essential L4D2 horde clearing
    TouchButton btnShove;
    btnShove.id = "btn_shove";
    btnShove.label = "SHOVE";
    btnShove.command = Command::ATTACK2;
    btnShove.width = 64.0f;
    btnShove.height = 64.0f;
    btnShove.x = screenWidth - 100.0f;
    btnShove.y = screenHeight - 235.0f;
    btnShove.isCircle = true;
    m_buttons.push_back(btnShove);

    // 3. Jump (+jump)
    TouchButton btnJump;
    btnJump.id = "btn_jump";
    btnJump.label = "JUMP";
    btnJump.command = Command::JUMP;
    btnJump.width = 62.0f;
    btnJump.height = 62.0f;
    btnJump.x = screenWidth - 185.0f;
    btnJump.y = screenHeight - 110.0f;
    btnJump.isCircle = true;
    m_buttons.push_back(btnJump);

    // 4. Reload (+reload)
    TouchButton btnReload;
    btnReload.id = "btn_reload";
    btnReload.label = "RELOAD";
    btnReload.command = Command::RELOAD;
    btnReload.width = 56.0f;
    btnReload.height = 56.0f;
    btnReload.x = screenWidth - 175.0f;
    btnReload.y = screenHeight - 195.0f;
    btnReload.isCircle = true;
    m_buttons.push_back(btnReload);

    // 5. Use / Interact (+use) - Revive teammate / open doors / gas cans
    TouchButton btnUse;
    btnUse.id = "btn_use";
    btnUse.label = "USE";
    btnUse.command = Command::USE;
    btnUse.width = 58.0f;
    btnUse.height = 58.0f;
    btnUse.x = screenWidth - 250.0f;
    btnUse.y = screenHeight - 170.0f;
    btnUse.isCircle = true;
    m_buttons.push_back(btnUse);

    // 6. Crouch (+duck) - Toggleable
    TouchButton btnDuck;
    btnDuck.id = "btn_duck";
    btnDuck.label = "CROUCH";
    btnDuck.command = Command::DUCK;
    btnDuck.width = 54.0f;
    btnDuck.height = 54.0f;
    btnDuck.x = screenWidth - 260.0f;
    btnDuck.y = screenHeight - 95.0f;
    btnDuck.isCircle = true;
    btnDuck.isToggle = true;
    m_buttons.push_back(btnDuck);

    // 7. Flashlight (impulse 100) - Top right
    TouchButton btnFlashlight;
    btnFlashlight.id = "btn_flashlight";
    btnFlashlight.label = "LIGHT";
    btnFlashlight.command = Command::FLASHLIGHT;
    btnFlashlight.width = 46.0f;
    btnFlashlight.height = 46.0f;
    btnFlashlight.x = screenWidth - 75.0f;
    btnFlashlight.y = 20.0f;
    btnFlashlight.isCircle = true;
    m_buttons.push_back(btnFlashlight);

    // 8. Debug / Console Toggle - Top left corner
    TouchButton btnConsole;
    btnConsole.id = "btn_console";
    btnConsole.label = "LOGS";
    btnConsole.command = Command::NONE;
    btnConsole.width = 56.0f;
    btnConsole.height = 36.0f;
    btnConsole.x = 24.0f;
    btnConsole.y = 18.0f;
    btnConsole.isCircle = false;
    m_buttons.push_back(btnConsole);
}

bool TouchButtons::handleTouchBegan(uintptr_t touchId, float x, float y) {
    for (auto& btn : m_buttons) {
        if (btn.contains(x, y)) {
            btn.touchId = touchId;
            if (btn.isToggle) {
                btn.toggleState = !btn.toggleState;
                btn.isPressed = btn.toggleState;
            } else {
                btn.isPressed = true;
            }

            if (btn.id == "btn_flashlight") {
                m_pendingFlashlight = true;
            } else if (btn.id == "btn_console") {
                m_pendingConsoleToggle = true;
            }

#if defined(__APPLE__)
            // Trigger light haptic feedback on iOS
            UIImpactFeedbackGenerator* generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
            [generator impactOccurred];
#endif
            return true;
        }
    }
    return false;
}

bool TouchButtons::handleTouchMoved(uintptr_t touchId, float x, float y) {
    for (auto& btn : m_buttons) {
        if (btn.touchId == touchId) {
            // Keep active while dragging within reasonable distance
            return true;
        }
    }
    return false;
}

bool TouchButtons::handleTouchEnded(uintptr_t touchId, float x, float y) {
    for (auto& btn : m_buttons) {
        if (btn.touchId == touchId) {
            btn.touchId = 0;
            if (!btn.isToggle) {
                btn.isPressed = false;
            }
            return true;
        }
    }
    return false;
}

uint32_t TouchButtons::getActiveCommandMask() const {
    uint32_t mask = 0;
    for (const auto& btn : m_buttons) {
        if (btn.isPressed) {
            mask |= static_cast<uint32_t>(btn.command);
        }
    }
    return mask;
}

bool TouchButtons::isCommandActive(Command cmd) const {
    return (getActiveCommandMask() & static_cast<uint32_t>(cmd)) != 0;
}

bool TouchButtons::consumeFlashlightToggle() {
    bool val = m_pendingFlashlight;
    m_pendingFlashlight = false;
    return val;
}

bool TouchButtons::consumeConsoleToggle() {
    bool val = m_pendingConsoleToggle;
    m_pendingConsoleToggle = false;
    return val;
}

void TouchButtons::setButtonPosition(const std::string& id, float x, float y, float size) {
    for (auto& btn : m_buttons) {
        if (btn.id == id) {
            btn.x = x;
            btn.y = y;
            btn.width = size;
            btn.height = size;
            break;
        }
    }
}

} // namespace l4d2
