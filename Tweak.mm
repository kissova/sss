#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach/mach.h>
#import <mach-o/dyld.h>

// Yeni menyunun başlanğıc / render funksiyasını burda elan et (öz funksiyanla əvəz et):
// extern "C" void InitNewMenu();

bool g_ESP = false;
bool g_Skeleton = false; // Hələlik ESP açılanda avtomatik true olmur

@interface NewMenuLauncher : NSObject
@property (nonatomic, strong) UIWindow *menuWindow;
@end

@implementation NewMenuLauncher

+ (instancetype)shared {
    static NewMenuLauncher *inst = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        inst = [[NewMenuLauncher alloc] init];
    });
    return inst;
}

- (UIWindow *)activeWindow {
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

- (void)openMenu {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.menuWindow) return;

        UIWindow *base = [self activeWindow];
        CGRect frame = base ? base.bounds : UIScreen.mainScreen.bounds;

        UIWindow *win = [[UIWindow alloc] initWithFrame:frame];
        win.windowLevel = UIWindowLevelAlert + 15;
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
        self.menuWindow = win;

        // Yeni menyunun öz init/render funksiyasını burdan çağır:
        // InitNewMenu();
    });
}

@end

__attribute__((constructor))
static void LaunchHookInit() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            @try {
                [[NewMenuLauncher shared] openMenu];
            } @catch (__unused NSException *ex) {
            }
        });
    });
}
