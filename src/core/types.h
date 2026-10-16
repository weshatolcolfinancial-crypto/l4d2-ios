#pragma once

#include <cstdint>
#include <string>

namespace l4d2 {

// Standard Left 4 Dead 2 input commands mapped to touch controls
enum class Command : uint32_t {
    NONE        = 0,
    ATTACK      = 1 << 0,  // +attack (Primary fire)
    ATTACK2     = 1 << 1,  // +attack2 (Melee / Shove)
    JUMP        = 1 << 2,  // +jump
    DUCK        = 1 << 3,  // +duck (Crouch)
    FORWARD     = 1 << 4,  // +forward
    BACK        = 1 << 5,  // +back
    USE         = 1 << 6,  // +use (Interact / Revive / Open doors)
    CANCEL      = 1 << 7,  // cancel
    LEFT        = 1 << 8,  // +left
    RIGHT       = 1 << 9,  // +right
    MOVELEFT    = 1 << 10, // +moveleft (Strafe left)
    MOVERIGHT   = 1 << 11, // +moveright (Strafe right)
    RELOAD      = 1 << 12, // +reload
    SPEED       = 1 << 13, // +speed (Walk)
    SCORE       = 1 << 14, // +showscores
    ZOOM        = 1 << 15, // +zoom (Sniper scope)
    FLASHLIGHT  = 1 << 16  // impulse 100
};

inline Command operator|(Command a, Command b) {
    return static_cast<Command>(static_cast<uint32_t>(a) | static_cast<uint32_t>(b));
}

inline Command operator&(Command a, Command b) {
    return static_cast<Command>(static_cast<uint32_t>(a) & static_cast<uint32_t>(b));
}

inline Command& operator|=(Command& a, Command b) {
    a = a | b;
    return a;
}

inline Command& operator&=(Command& a, Command b) {
    a = a & static_cast<Command>(~static_cast<uint32_t>(b));
    return a;
}

// 5 L4D2 Inventory slots
enum class WeaponSlot : int {
    SLOT_PRIMARY   = 1, // Primary (Rifle, Shotgun, SMG, Sniper)
    SLOT_SECONDARY = 2, // Secondary (Pistols, Magnum, Melee: Axe, Katana, Bat, etc.)
    SLOT_THROWABLE = 3, // Grenades (Pipe Bomb, Molotov, Vomit Jar)
    SLOT_MEDKIT    = 4, // First Aid Kit, Defibrillator, Incendiary/Explosive Ammo Pack
    SLOT_PILLS     = 5  // Pain Pills, Adrenaline Shot
};

struct Vector2D {
    float x = 0.0f;
    float y = 0.0f;

    Vector2D() = default;
    Vector2D(float _x, float _y) : x(_x), y(_y) {}

    float lengthSquared() const { return x * x + y * y; }
};

struct TouchPoint {
    uintptr_t touchId = 0;
    float x = 0.0f;
    float y = 0.0f;
    float startX = 0.0f;
    float startY = 0.0f;
    bool isActive = false;
};

// Input state snapshot sent to Source engine tick
struct InputFrameState {
    Vector2D moveVector;     // Normalized movement [-1.0 .. 1.0] for joystick
    Vector2D lookDelta;      // Camera look delta (pitch / yaw)
    uint32_t buttons = 0;    // Bitmask of active Commands
    int pendingSlot = 0;     // Non-zero if a slot switch was requested this frame
    bool toggleFlashlight = false;
};

} // namespace l4d2
