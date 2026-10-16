#pragma once

#include "../core/types.h"
#include <vector>
#include <string>

namespace l4d2 {

struct WeaponSlotUI {
    WeaponSlot slot;
    std::string title;
    std::string subtext;
    float x = 0.0f;
    float y = 0.0f;
    float width = 68.0f;
    float height = 48.0f;
    bool isSelected = false;

    bool contains(float px, float py) const {
        return px >= x && px <= (x + width) && py >= y && py <= (y + height);
    }
};

class WeaponSwitcher {
public:
    WeaponSwitcher();
    ~WeaponSwitcher();

    void initializeLayout(float screenWidth, float screenHeight);
    bool handleTouchBegan(uintptr_t touchId, float x, float y);
    
    int getSelectedSlot() const { return static_cast<int>(m_selectedSlot); }
    void setSelectedSlot(WeaponSlot slot);

    int consumePendingSlotSwitch();
    const std::vector<WeaponSlotUI>& getSlots() const { return m_slots; }

private:
    std::vector<WeaponSlotUI> m_slots;
    WeaponSlot m_selectedSlot = WeaponSlot::SLOT_PRIMARY;
    int m_pendingSlotSwitch = 0;
};

} // namespace l4d2
