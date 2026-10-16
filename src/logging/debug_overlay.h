#pragma once

#if defined(__APPLE__)
#import <UIKit/UIKit.h>
#endif

namespace l4d2 {

class DebugOverlay {
public:
    static DebugOverlay& getInstance();

    void initialize();
    void toggleConsole();
    void setVisible(bool visible);
    bool isVisible() const { return m_visible; }

#if defined(__APPLE__)
    UIView* getOverlayView();
#endif

private:
    DebugOverlay();
    ~DebugOverlay();

    bool m_visible = false;
    void* m_uiView = nullptr;
};

} // namespace l4d2
