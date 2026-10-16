#include "touch_controller.h"

#if defined(__APPLE__)
#import <UIKit/UIKit.h>

@interface L4D2TouchOverlayView : UIView
@property (nonatomic, assign) l4d2::TouchController* controller;
- (void)refreshDisplay;
@end

@implementation L4D2TouchOverlayView

- (instancetype)initWithFrame:(CGRect)frame controller:(l4d2::TouchController*)ctrl {
    if (self = [super initWithFrame:frame]) {
        _controller = ctrl;
        self.backgroundColor = [UIColor clearColor];
        self.multipleTouchEnabled = YES;
        self.userInteractionEnabled = YES;
    }
    return self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!_controller) return;
    for (UITouch* t in touches) {
        CGPoint pt = [t locationInView:self];
        _controller->onTouchBegan((uintptr_t)t, pt.x, pt.y);
    }
    [self setNeedsDisplay];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!_controller) return;
    for (UITouch* t in touches) {
        CGPoint pt = [t locationInView:self];
        _controller->onTouchMoved((uintptr_t)t, pt.x, pt.y);
    }
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!_controller) return;
    for (UITouch* t in touches) {
        CGPoint pt = [t locationInView:self];
        _controller->onTouchEnded((uintptr_t)t, pt.x, pt.y);
    }
    [self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!_controller) return;
    for (UITouch* t in touches) {
        _controller->onTouchCancelled((uintptr_t)t);
    }
    [self setNeedsDisplay];
}

- (void)refreshDisplay {
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    if (!_controller) return;
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    // 1. Draw Dynamic Joystick if active
    const auto& joy = _controller->getJoystick();
    if (joy.isActive()) {
        // Base circle
        CGRect baseRect = CGRectMake(joy.getBaseX() - joy.getRadius(),
                                     joy.getBaseY() - joy.getRadius(),
                                     joy.getRadius() * 2.0f,
                                     joy.getRadius() * 2.0f);
        CGContextSetRGBFillColor(ctx, 0.1f, 0.1f, 0.1f, 0.35f);
        CGContextFillEllipseInRect(ctx, baseRect);
        CGContextSetRGBStrokeColor(ctx, 0.4f, 0.8f, 1.0f, 0.6f);
        CGContextSetLineWidth(ctx, 2.0f);
        CGContextStrokeEllipseInRect(ctx, baseRect);

        // Thumb knob
        float thumbRadius = joy.getRadius() * 0.45f;
        CGRect thumbRect = CGRectMake(joy.getThumbX() - thumbRadius,
                                      joy.getThumbY() - thumbRadius,
                                      thumbRadius * 2.0f,
                                      thumbRadius * 2.0f);
        CGContextSetRGBFillColor(ctx, 0.2f, 0.7f, 1.0f, 0.7f);
        CGContextFillEllipseInRect(ctx, thumbRect);
        CGContextSetRGBStrokeColor(ctx, 1.0f, 1.0f, 1.0f, 0.9f);
        CGContextStrokeEllipseInRect(ctx, thumbRect);
    }

    // 2. Draw Touch Buttons
    const auto& buttons = _controller->getButtons().getButtons();
    for (const auto& btn : buttons) {
        CGRect btnRect = CGRectMake(btn.x, btn.y, btn.width, btn.height);
        
        // Colors: special Infected combat red for Shove/Fire, neutral slate for others
        float r = 0.2f, g = 0.25f, b = 0.3f, a = 0.45f;
        if (btn.id == "btn_attack") {
            r = 0.85f; g = 0.2f; b = 0.2f; a = btn.isPressed ? 0.85f : 0.55f;
        } else if (btn.id == "btn_shove") {
            r = 0.95f; g = 0.55f; b = 0.1f; a = btn.isPressed ? 0.85f : 0.55f;
        } else if (btn.id == "btn_use") {
            r = 0.15f; g = 0.75f; b = 0.35f; a = btn.isPressed ? 0.85f : 0.50f;
        } else if (btn.isPressed) {
            a = 0.75f;
        }

        CGContextSetRGBFillColor(ctx, r, g, b, a);
        if (btn.isCircle) {
            CGContextFillEllipseInRect(ctx, btnRect);
            CGContextSetRGBStrokeColor(ctx, 1.0f, 1.0f, 1.0f, btn.isPressed ? 0.9f : 0.4f);
            CGContextSetLineWidth(ctx, 1.5f);
            CGContextStrokeEllipseInRect(ctx, btnRect);
        } else {
            UIBezierPath* path = [UIBezierPath bezierPathWithRoundedRect:btnRect cornerRadius:6.0f];
            [path fill];
            CGContextSetRGBStrokeColor(ctx, 1.0f, 1.0f, 1.0f, 0.4f);
            [path stroke];
        }

        // Draw button text
        NSString* text = [NSString stringWithUTF8String:btn.label.c_str()];
        UIFont* font = [UIFont systemFontOfSize:11.0f weight:UIFontWeightBold];
        NSDictionary* attrs = @{
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: [UIColor whiteColor]
        };
        CGSize textSize = [text sizeWithAttributes:attrs];
        CGPoint textPos = CGPointMake(btn.x + (btn.width - textSize.width) * 0.5f,
                                      btn.y + (btn.height - textSize.height) * 0.5f);
        [text drawAtPoint:textPos withAttributes:attrs];
    }

    // 3. Draw 5-Slot Weapon Switcher Bar
    const auto& slots = _controller->getWeaponSwitcher().getSlots();
    for (const auto& slot : slots) {
        CGRect slotRect = CGRectMake(slot.x, slot.y, slot.width, slot.height);
        UIBezierPath* path = [UIBezierPath bezierPathWithRoundedRect:slotRect cornerRadius:8.0f];
        
        if (slot.isSelected) {
            CGContextSetRGBFillColor(ctx, 0.85f, 0.45f, 0.1f, 0.85f);
            CGContextSetRGBStrokeColor(ctx, 1.0f, 0.9f, 0.3f, 1.0f);
            CGContextSetLineWidth(ctx, 2.0f);
        } else {
            CGContextSetRGBFillColor(ctx, 0.15f, 0.18f, 0.22f, 0.55f);
            CGContextSetRGBStrokeColor(ctx, 0.6f, 0.7f, 0.8f, 0.35f);
            CGContextSetLineWidth(ctx, 1.0f);
        }
        [path fill];
        [path stroke];

        // Slot title
        NSString* title = [NSString stringWithUTF8String:slot.title.c_str()];
        UIFont* titleFont = [UIFont systemFontOfSize:10.0f weight:UIFontWeightHeavy];
        NSDictionary* titleAttrs = @{
            NSFontAttributeName: titleFont,
            NSForegroundColorAttributeName: slot.isSelected ? [UIColor whiteColor] : [UIColor lightGrayColor]
        };
        CGSize titleSize = [title sizeWithAttributes:titleAttrs];
        [title drawAtPoint:CGPointMake(slot.x + (slot.width - titleSize.width) * 0.5f, slot.y + 6.0f)
            withAttributes:titleAttrs];

        // Slot subtext
        NSString* sub = [NSString stringWithUTF8String:slot.subtext.c_str()];
        UIFont* subFont = [UIFont systemFontOfSize:8.0f weight:UIFontWeightRegular];
        NSDictionary* subAttrs = @{
            NSFontAttributeName: subFont,
            NSForegroundColorAttributeName: [UIColor colorWithWhite:0.8f alpha:0.8f]
        };
        CGSize subSize = [sub sizeWithAttributes:subAttrs];
        [sub drawAtPoint:CGPointMake(slot.x + (slot.width - subSize.width) * 0.5f, slot.y + 24.0f)
          withAttributes:subAttrs];
    }
}

@end
#endif

namespace l4d2 {

TouchController::TouchController() = default;
TouchController::~TouchController() = default;

void TouchController::initialize(float screenWidth, float screenHeight) {
    updateScreenSize(screenWidth, screenHeight);
}

void TouchController::updateScreenSize(float screenWidth, float screenHeight) {
    m_screenWidth = screenWidth;
    m_screenHeight = screenHeight;
    m_buttons.initializeDefaultLayout(screenWidth, screenHeight);
    m_weaponSwitcher.initializeLayout(screenWidth, screenHeight);
    m_joystick.reset();
}

void TouchController::onTouchBegan(uintptr_t touchId, float x, float y) {
    // 1. Check touch buttons
    if (m_buttons.handleTouchBegan(touchId, x, y)) {
        return;
    }

    // 2. Check weapon switcher
    if (m_weaponSwitcher.handleTouchBegan(touchId, x, y)) {
        return;
    }

    // 3. Left half of screen -> Dynamic Joystick
    if (x < (m_screenWidth * 0.45f) && y > (m_screenHeight * 0.25f)) {
        if (m_joystick.handleTouchBegan(touchId, x, y)) {
            return;
        }
    }

    // 4. Right half of screen -> Camera look swipe area
    if (x >= (m_screenWidth * 0.45f) && m_lookTouchId == 0) {
        m_lookTouchId = touchId;
        m_lastLookX = x;
        m_lastLookY = y;
    }
}

void TouchController::onTouchMoved(uintptr_t touchId, float x, float y) {
    if (m_buttons.handleTouchMoved(touchId, x, y)) {
        return;
    }

    if (m_joystick.handleTouchMoved(touchId, x, y)) {
        return;
    }

    if (m_lookTouchId == touchId) {
        float dx = (x - m_lastLookX) * m_sensX;
        float dy = (y - m_lastLookY) * m_sensY;
        m_lastLookX = x;
        m_lastLookY = y;
        m_accumulatedLookDelta.x += dx;
        m_accumulatedLookDelta.y += dy;
    }
}

void TouchController::onTouchEnded(uintptr_t touchId, float x, float y) {
    if (m_buttons.handleTouchEnded(touchId, x, y)) {
        return;
    }

    if (m_joystick.handleTouchEnded(touchId)) {
        return;
    }

    if (m_lookTouchId == touchId) {
        m_lookTouchId = 0;
    }
}

void TouchController::onTouchCancelled(uintptr_t touchId) {
    m_buttons.handleTouchEnded(touchId, 0, 0);
    m_joystick.handleTouchEnded(touchId);
    if (m_lookTouchId == touchId) {
        m_lookTouchId = 0;
    }
}

InputFrameState TouchController::pollInputState() {
    InputFrameState state;
    state.moveVector = m_joystick.getNormalizedVector();
    state.lookDelta = m_accumulatedLookDelta;
    m_accumulatedLookDelta = Vector2D(0.0f, 0.0f);

    state.buttons = m_buttons.getActiveCommandMask();
    state.toggleFlashlight = m_buttons.consumeFlashlightToggle();
    state.pendingSlot = m_weaponSwitcher.consumePendingSlotSwitch();

    return state;
}

bool TouchController::isConsoleRequested() {
    return m_buttons.consumeConsoleToggle();
}

} // namespace l4d2
