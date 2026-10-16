#include "GameViewController.h"
#include "MetalView.h"
#include "../../src/core/engine_bridge.h"
#include "../../src/core/promotion_manager.h"
#include "../../src/touch/touch_controller.h"
#include "../../src/logging/debug_overlay.h"
#include "../../src/logging/logger.h"

#if defined(__APPLE__)
#import <UIKit/UIKit.h>

@interface L4D2TouchOverlayView : UIView
- (instancetype)initWithFrame:(CGRect)frame controller:(l4d2::TouchController*)ctrl;
- (void)refreshDisplay;
@end

@interface GameViewController () {
    l4d2::TouchController _touchController;
}
@property (nonatomic, strong) L4D2MetalView* metalView;
@property (nonatomic, strong) L4D2TouchOverlayView* touchOverlay;
@property (nonatomic, strong) UIView* setupPromptView;
@end

@implementation GameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];

    CGRect bounds = [UIScreen mainScreen].bounds;

    // 1. Metal rendering view
    _metalView = [[L4D2MetalView alloc] initWithFrame:bounds];
    _metalView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_metalView];

    // 2. Dynamic Touch Controls Overlay
    _touchController.initialize(bounds.size.width, bounds.size.height);
    _touchOverlay = [[L4D2TouchOverlayView alloc] initWithFrame:bounds controller:&_touchController];
    _touchOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_touchOverlay];

    // 3. Debug Overlay
    l4d2::DebugOverlay::getInstance().initialize();
    UIView* debugView = l4d2::DebugOverlay::getInstance().getOverlayView();
    if (debugView) {
        [self.view addSubview:debugView];
    }

    // 4. Check assets and initialize engine
    [self checkAndInitializeEngine];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    CGRect bounds = self.view.bounds;
    _touchController.updateScreenSize(bounds.size.width, bounds.size.height);
    [_touchOverlay refreshDisplay];
}

- (void)checkAndInitializeEngine {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths firstObject];
    std::string docPath = [documentsDirectory UTF8String];

    bool ready = l4d2::EngineBridge::getInstance().initialize(docPath);
    if (ready) {
        if (_setupPromptView) {
            [_setupPromptView removeFromSuperview];
            _setupPromptView = nil;
        }
        [self startEngineLoop];
    } else {
        [self showSetupPromptView];
    }
}

- (void)showSetupPromptView {
    if (_setupPromptView) return;

    CGRect bounds = self.view.bounds;
    _setupPromptView = [[UIView alloc] initWithFrame:bounds];
    _setupPromptView.backgroundColor = [UIColor colorWithRed:0.05f green:0.06f blue:0.08f alpha:0.95f];
    _setupPromptView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    CGFloat cardW = MIN(bounds.size.width - 60.0f, 620.0f);
    CGFloat cardH = MIN(bounds.size.height - 40.0f, 320.0f);
    CGFloat cardX = (bounds.size.width - cardW) * 0.5f;
    CGFloat cardY = (bounds.size.height - cardH) * 0.5f;

    UIView* card = [[UIView alloc] initWithFrame:CGRectMake(cardX, cardY, cardW, cardH)];
    card.backgroundColor = [UIColor colorWithRed:0.1f green:0.12f blue:0.16f alpha:0.95f];
    card.layer.cornerRadius = 14.0f;
    card.layer.borderWidth = 1.5f;
    card.layer.borderColor = [UIColor colorWithRed:0.85f green:0.25f blue:0.25f alpha:0.8f].CGColor;
    card.clipsToBounds = YES;
    [_setupPromptView addSubview:card];

    // Title
    UILabel* title = [[UILabel alloc] initWithFrame:CGRectMake(20, 16, cardW - 40, 28)];
    title.text = @"LEFT 4 DEAD 2 - GAME CONTENT REQUIRED";
    title.font = [UIFont systemFontOfSize:16.0f weight:UIFontWeightHeavy];
    title.textColor = [UIColor colorWithRed:1.0f green:0.35f blue:0.35f alpha:1.0f];
    title.textAlignment = NSTextAlignmentCenter;
    [card addSubview:title];

    // Description text
    auto status = l4d2::EngineBridge::getInstance().getAssetStatus();
    std::string guide = l4d2::AssetValidator::getTroubleshootingGuide(status);
    UITextView* infoText = [[UITextView alloc] initWithFrame:CGRectMake(20, 52, cardW - 40, cardH - 120)];
    infoText.backgroundColor = [UIColor colorWithRed:0.04f green:0.05f blue:0.07f alpha:0.8f];
    infoText.font = [UIFont fontWithName:@"Courier" size:11.0f];
    infoText.textColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
    infoText.editable = NO;
    infoText.layer.cornerRadius = 8.0f;
    infoText.text = [NSString stringWithUTF8String:guide.c_str()];
    [card addSubview:infoText];

    // Recheck Button
    UIButton* recheckBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    recheckBtn.frame = CGRectMake(cardW * 0.5f - 145.0f, cardH - 54.0f, 135.0f, 38.0f);
    recheckBtn.backgroundColor = [UIColor colorWithRed:0.2f green:0.6f blue:0.3f alpha:0.9f];
    recheckBtn.layer.cornerRadius = 8.0f;
    [recheckBtn setTitle:@"RECHECK FILES" forState:UIControlStateNormal];
    recheckBtn.titleLabel.font = [UIFont systemFontOfSize:12.0f weight:UIFontWeightBold];
    [recheckBtn addTarget:self action:@selector(onRecheckPressed) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:recheckBtn];

    // Logs Button
    UIButton* logsBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    logsBtn.frame = CGRectMake(cardW * 0.5f + 10.0f, cardH - 54.0f, 135.0f, 38.0f);
    logsBtn.backgroundColor = [UIColor colorWithRed:0.3f green:0.4f blue:0.5f alpha:0.9f];
    logsBtn.layer.cornerRadius = 8.0f;
    [logsBtn setTitle:@"VIEW LOGS" forState:UIControlStateNormal];
    logsBtn.titleLabel.font = [UIFont systemFontOfSize:12.0f weight:UIFontWeightBold];
    [logsBtn addTarget:self action:@selector(onLogsPressed) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:logsBtn];

    [self.view addSubview:_setupPromptView];
}

- (void)onRecheckPressed {
    [self checkAndInitializeEngine];
}

- (void)onLogsPressed {
    l4d2::DebugOverlay::getInstance().toggleConsole();
}

- (void)startEngineLoop {
    l4d2::ProMotionManager::getInstance().initialize([self](double deltaTime, double targetFPS) {
        // 1. Check if user tapped console button on touch overlay
        if (self->_touchController.isConsoleRequested()) {
            l4d2::DebugOverlay::getInstance().toggleConsole();
        }

        // 2. Poll touch inputs
        l4d2::InputFrameState input = self->_touchController.pollInputState();
        l4d2::EngineBridge::getInstance().processInput(input);

        // 3. Tick engine frame
        l4d2::EngineBridge::getInstance().onFrameTick(deltaTime, targetFPS);
    });

    l4d2::ProMotionManager::getInstance().start();
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

@end
#endif
