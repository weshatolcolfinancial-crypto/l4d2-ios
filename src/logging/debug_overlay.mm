#include "debug_overlay.h"
#include "logger.h"
#include "../core/promotion_manager.h"

#if defined(__APPLE__)
#import <UIKit/UIKit.h>
#import <mach/mach.h>

@interface L4D2DebugConsoleView : UIView
@property (nonatomic, strong) UILabel* statsLabel;
@property (nonatomic, strong) UITextView* consoleTextView;
@property (nonatomic, strong) UIButton* closeButton;
@property (nonatomic, strong) UIButton* exportButton;
@property (nonatomic, strong) UIButton* clearButton;
@property (nonatomic, strong) NSTimer* refreshTimer;
- (void)refreshLogs;
@end

@implementation L4D2DebugConsoleView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor colorWithRed:0.05f green:0.06f blue:0.08f alpha:0.92f];
        self.layer.cornerRadius = 12.0f;
        self.layer.borderWidth = 1.0f;
        self.layer.borderColor = [UIColor colorWithRed:0.25f green:0.3f blue:0.38f alpha:0.8f].CGColor;
        self.clipsToBounds = YES;

        // 1. Stats Bar (FPS / Frame Time / Memory)
        _statsLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 10, frame.size.width - 160, 26)];
        _statsLabel.font = [UIFont monospacedDigitSystemFontOfSize:12.0f weight:UIFontWeightBold];
        _statsLabel.textColor = [UIColor colorWithRed:0.4f green:0.9f blue:1.0f alpha:1.0f];
        _statsLabel.text = @"Initializing diagnostics...";
        [self addSubview:_statsLabel];

        // 2. Action buttons
        CGFloat btnW = 60.0f;
        CGFloat btnH = 28.0f;
        CGFloat rightX = frame.size.width - 12.0f;

        // Close button
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _closeButton.frame = CGRectMake(rightX - btnW, 10, btnW, btnH);
        [_closeButton setTitle:@"CLOSE" forState:UIControlStateNormal];
        _closeButton.titleLabel.font = [UIFont systemFontOfSize:11.0f weight:UIFontWeightBold];
        _closeButton.backgroundColor = [UIColor colorWithRed:0.8f green:0.2f blue:0.2f alpha:0.8f];
        _closeButton.layer.cornerRadius = 6.0f;
        [_closeButton addTarget:self action:@selector(onClosePressed) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_closeButton];

        // Export button
        _exportButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _exportButton.frame = CGRectMake(rightX - btnW * 2 - 8, 10, btnW, btnH);
        [_exportButton setTitle:@"EXPORT" forState:UIControlStateNormal];
        _exportButton.titleLabel.font = [UIFont systemFontOfSize:11.0f weight:UIFontWeightBold];
        _exportButton.backgroundColor = [UIColor colorWithRed:0.2f green:0.5f blue:0.8f alpha:0.8f];
        _exportButton.layer.cornerRadius = 6.0f;
        [_exportButton addTarget:self action:@selector(onExportPressed) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_exportButton];

        // Clear button
        _clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _clearButton.frame = CGRectMake(rightX - btnW * 3 - 16, 10, btnW, btnH);
        [_clearButton setTitle:@"CLEAR" forState:UIControlStateNormal];
        _clearButton.titleLabel.font = [UIFont systemFontOfSize:11.0f weight:UIFontWeightBold];
        _clearButton.backgroundColor = [UIColor colorWithWhite:0.25f alpha:0.8f];
        _clearButton.layer.cornerRadius = 6.0f;
        [_clearButton addTarget:self action:@selector(onClearPressed) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_clearButton];

        // 3. Console Log Output
        _consoleTextView = [[UITextView alloc] initWithFrame:CGRectMake(12, 46, frame.size.width - 24, frame.size.height - 56)];
        _consoleTextView.backgroundColor = [UIColor colorWithRed:0.02f green:0.03f blue:0.04f alpha:0.9f];
        _consoleTextView.font = [UIFont fontWithName:@"Courier" size:10.5f];
        _consoleTextView.textColor = [UIColor colorWithWhite:0.92f alpha:1.0f];
        _consoleTextView.editable = NO;
        _consoleTextView.layer.cornerRadius = 8.0f;
        [self addSubview:_consoleTextView];

        _refreshTimer = [NSTimer scheduledTimerWithTimeInterval:0.4 target:self selector:@selector(refreshLogs) userInfo:nil repeats:YES];
    }
    return self;
}

- (void)dealloc {
    [_refreshTimer invalidate];
}

- (double)getResidentMemoryMB {
    struct mach_task_basic_info info;
    mach_msg_type_number_t size = MACH_TASK_BASIC_INFO_COUNT;
    kern_return_t kerr = task_info(mach_task_self(), MACH_TASK_BASIC_INFO, (task_info_t)&info, &size);
    if (kerr == KERN_SUCCESS) {
        return (double)info.resident_size / (1024.0 * 1024.0);
    }
    return 0.0;
}

- (void)refreshLogs {
    // 1. Update stats string
    std::string dispStatus = l4d2::ProMotionManager::getInstance().getDisplayStatus();
    double memMB = [self getResidentMemoryMB];
    self.statsLabel.text = [NSString stringWithFormat:@"%s | RAM: %.1f MB", dispStatus.c_str(), memMB];

    // 2. Fetch recent logs from ring buffer
    auto logs = l4d2::Logger::getInstance().getRecentLogs(150);
    NSMutableString* combined = [NSMutableString string];
    for (const auto& entry : logs) {
        [combined appendFormat:@"[%s] [%s] %s\n", entry.timestamp.c_str(), entry.tag.c_str(), entry.message.c_str()];
    }
    self.consoleTextView.text = combined;
    if (combined.length > 0) {
        [self.consoleTextView scrollRangeToVisible:NSMakeRange(combined.length - 1, 1)];
    }
}

- (void)onClosePressed {
    l4d2::DebugOverlay::getInstance().setVisible(false);
}

- (void)onExportPressed {
    std::string logPath = l4d2::Logger::getInstance().getLogFilePath();
    NSString* nsPath = [NSString stringWithUTF8String:logPath.c_str()];
    NSURL* fileURL = [NSURL fileURLWithPath:nsPath];

    if (![[NSFileManager defaultManager] fileExistsAtPath:nsPath]) {
        return;
    }

    UIActivityViewController* activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[fileURL] applicationActivities:nil];
    UIViewController* rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootVC presentViewController:activityVC animated:YES completion:nil];
}

- (void)onClearPressed {
    l4d2::Logger::getInstance().clearRecentLogs();
    self.consoleTextView.text = @"";
}

@end
#endif

namespace l4d2 {

DebugOverlay& DebugOverlay::getInstance() {
    static DebugOverlay instance;
    return instance;
}

DebugOverlay::DebugOverlay() = default;
DebugOverlay::~DebugOverlay() = default;

void DebugOverlay::initialize() {
#if defined(__APPLE__)
    CGRect screen = [UIScreen mainScreen].bounds;
    CGRect overlayFrame = CGRectMake(20, 30, screen.size.width - 40, screen.size.height - 60);
    L4D2DebugConsoleView* view = [[L4D2DebugConsoleView alloc] initWithFrame:overlayFrame];
    view.hidden = YES;
    m_uiView = (__bridge_retained void*)view;
#endif
}

void DebugOverlay::toggleConsole() {
    setVisible(!m_visible);
}

void DebugOverlay::setVisible(bool visible) {
    m_visible = visible;
#if defined(__APPLE__)
    if (m_uiView) {
        L4D2DebugConsoleView* view = (__bridge L4D2DebugConsoleView*)m_uiView;
        view.hidden = !visible;
        if (visible) {
            [view.superview bringSubviewToFront:view];
            [view refreshLogs];
        }
    }
#endif
}

#if defined(__APPLE__)
UIView* DebugOverlay::getOverlayView() {
    return (__bridge UIView*)m_uiView;
}
#endif

} // namespace l4d2
