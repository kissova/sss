#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef struct {
    BOOL esp;
    BOOL skeleton;
    BOOL aimbot;
    BOOL memory;
    BOOL skin;
} ModToggles;

static ModToggles g_Toggles = { NO, NO, NO, NO, NO };

@interface GameModMenu : NSObject
@property (nonatomic, strong) UIWindow *overlayWin;
@property (nonatomic, strong) UIView *panel;
@property (nonatomic, strong) UIButton *toggleBtn;
@end

@implementation GameModMenu

+ (instancetype)shared {
    static GameModMenu *obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[GameModMenu alloc] init];
    });
    return obj;
}

- (UIWindow *)keyWin {
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *ws = (UIWindowScene *)scene;
                for (UIWindow *w in ws.windows) {
                    if (w.isKeyWindow) return w;
                }
                if (ws.windows.count > 0) return ws.windows.firstObject;
            }
        }
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return UIApplication.sharedApplication.keyWindow;
#pragma clang diagnostic pop
}

- (void)show {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.overlayWin) return;

        UIWindow *base = [self keyWin];
        CGRect rect = base ? base.bounds : UIScreen.mainScreen.bounds;

        UIWindow *win = [[UIWindow alloc] initWithFrame:rect];
        win.windowLevel = UIWindowLevelAlert + 20;
        win.backgroundColor = UIColor.clearColor;
        win.userInteractionEnabled = YES;

        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]]) {
                    win.windowScene = (UIWindowScene *)scene;
                    break;
                }
            }
        }

        UIViewController *vc = [[UIViewController alloc] init];
        vc.view.backgroundColor = UIColor.clearColor;
        win.rootViewController = vc;
        win.hidden = NO;
        self.overlayWin = win;

        // Açma/bağlama düyməsi
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(18, 80, 92, 32);
        btn.backgroundColor = [UIColor colorWithWhite:0.05f alpha:0.9f];
        btn.layer.borderColor = UIColor.whiteColor.CGColor;
        btn.layer.borderWidth = 1.0f;
        btn.layer.cornerRadius = 7.0f;
        [btn setTitle:@"MENU" forState:UIControlStateNormal];
        [btn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
        [btn addTarget:self action:@selector(togglePanel) forControlEvents:UIControlEventTouchUpInside];
        [vc.view addSubview:btn];
        self.toggleBtn = btn;

        // Menyu paneli
        UIView *p = [[UIView alloc] initWithFrame:CGRectMake(18, 120, 230, 255)];
        p.backgroundColor = [UIColor colorWithWhite:0.06f alpha:0.95f];
        p.layer.borderColor = [UIColor colorWithWhite:0.75f alpha:0.9f].CGColor;
        p.layer.borderWidth = 1.0f;
        p.layer.cornerRadius = 10.0f;
        p.hidden = NO; // Oyuna girəndə açıq görünsün deyə açıq qoydum
        [vc.view addSubview:p];
        self.panel = p;

        UILabel *hdr = [[UILabel alloc] initWithFrame:CGRectMake(12, 8, 206, 22)];
        hdr.text = @"MOD TEST MENU";
        hdr.textColor = UIColor.whiteColor;
        hdr.font = [UIFont monospacedSystemFontOfSize:13.0f weight:UIFontWeightBold];
        [p addSubview:hdr];

        NSArray<NSString *> *items = @[
            @"1. ESP",
            @"2. Skeleton",
            @"3. Aimbot",
            @"4. Memory",
            @"5. Skin"
        ];

        CGFloat y = 38.0f;
        for (NSUInteger i = 0; i < items.count; i++) {
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(12, y, 145, 28)];
            lbl.text = items[i];
            lbl.textColor = UIColor.whiteColor;
            lbl.font = [UIFont systemFontOfSize:13.0f weight:UIFontWeightMedium];
            [p addSubview:lbl];

            UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectZero];
            sw.center = CGPointMake(192, y + 14);
            sw.transform = CGAffineTransformMakeScale(0.78f, 0.78f);
            sw.onTintColor = UIColor.whiteColor;
            sw.thumbTintColor = UIColor.blackColor;
            sw.tag = (NSInteger)i;
            [sw addTarget:self action:@selector(onSwitch:) forControlEvents:UIControlEventValueChanged];
            [p addSubview:sw];

            y += 38.0f;
        }
    });
}

- (void)togglePanel {
    self.panel.hidden = !self.panel.hidden;
}

- (void)onSwitch:(UISwitch *)sw {
    BOOL val = sw.isOn;
    switch (sw.tag) {
        case 0:
            g_Toggles.esp = val;
            break;
        case 1:
            g_Toggles.skeleton = val;
            break;
        case 2:
            g_Toggles.aimbot = val;
            break;
        case 3:
            g_Toggles.memory = val;
            break;
        case 4:
            g_Toggles.skin = val;
            break;
        default:
            break;
    }
}

@end

__attribute__((constructor))
static void StartMenuDylib() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [[GameModMenu shared] show];
    });
}
