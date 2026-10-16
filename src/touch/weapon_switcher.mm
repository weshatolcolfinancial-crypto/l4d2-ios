#include "weapon_switcher.h"

#if defined(__APPLE__)
#import <UIKit/UIKit.h>
#endif

namespace l4d2 {

WeaponSwitcher::WeaponSwitcher() = default;
WeaponSwitcher::~WeaponSwitcher() = default;

void WeaponSwitcher::initializeLayout(float screenWidth, float screenHeight) {
    m_slots.clear();

    const float slotWidth = 72.0f;
    const float slotHeight = 44.0f;
    const float spacing = 8.0f;
    const int totalSlots = 5;
    const float totalWidth = (slotWidth * totalSlots) + (spacing * (totalSlots - 1));
    const float startX = (screenWidth - totalWidth) * 0.5f;
    const float startY = screenHeight - slotHeight - 14.0f;

    const struct {
        WeaponSlot slot;
        const char* title;
        const char* subtext;
    } slotDefs[5] = {
        { WeaponSlot::SLOT_PRIMARY,   "1: PRIMARY",   "Rifle/Shotgun" },
        { WeaponSlot::SLOT_SECONDARY, "2: PISTOL",    "Melee/Magnum"  },
        { WeaponSlot::SLOT_THROWABLE, "3: GRENADE",   "Pipe/Molotov"  },
        { WeaponSlot::SLOT_MEDKIT,    "4: MEDKIT",    "Kit/Defib"     },
        { WeaponSlot::SLOT_PILLS,     "5: PILLS",     "Pills/Shot"    }
    };

    for (int i = 0; i < totalSlots; ++i) {
        WeaponSlotUI ui;
        ui.slot = slotDefs[i].slot;
        ui.title = slotDefs[i].title;
        ui.subtext = slotDefs[i].subtext;
        ui.width = slotWidth;
        ui.height = slotHeight;
        ui.x = startX + i * (slotWidth + spacing);
        ui.y = startY;
        ui.isSelected = (ui.slot == m_selectedSlot);
        m_slots.push_back(ui);
    }
}

bool WeaponSwitcher::handleTouchBegan(uintptr_t touchId, float x, float y) {
    for (auto& slotUI : m_slots) {
        if (slotUI.contains(x, y)) {
            setSelectedSlot(slotUI.slot);
            m_pendingSlotSwitch = static_cast<int>(slotUI.slot);

#if defined(__APPLE__)
            UIImpactFeedbackGenerator* generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
            [generator impactOccurred];
#endif
            return true;
        }
    }
    return false;
}

void WeaponSwitcher::setSelectedSlot(WeaponSlot slot) {
    m_selectedSlot = slot;
    for (auto& slotUI : m_slots) {
        slotUI.isSelected = (slotUI.slot == slot);
    }
}

int WeaponSwitcher::consumePendingSlotSwitch() {
    int val = m_pendingSlotSwitch;
    m_pendingSlotSwitch = 0;
    return val;
}

} // namespace l4d2
