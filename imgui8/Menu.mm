#import <UIKit/UIKit.h>
#import "DrawView.h"

extern bool menu_open;
extern bool show_4e_menu;
extern bool show_neverlose_menu;

@interface ImGuiLoad : NSObject
@property (nonatomic, strong) ImGuiDrawView *vna;
@property (nonatomic, strong) UIButton *gearButton;
@property (nonatomic, strong) UIButton *btn4E;
@property (nonatomic, strong) UIButton *btnNeverlose;
@property (nonatomic, assign) BOOL subButtonsVisible;
+ (instancetype)share;
- (void)initMenu;
- (void)syncOverlayState;
@end

@implementation ImGuiLoad

+ (void)load {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[ImGuiLoad share] initMenu];
    });
}

+ (instancetype)share {
    static ImGuiLoad *tool = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tool = [[ImGuiLoad alloc] init];
    });
    return tool;
}

- (UIWindow *)findActiveWindow {
    UIApplication *app = [UIApplication sharedApplication];
    for (UIScene *scene in app.connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive) {
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            for (UIWindow *win in windowScene.windows) {
                if (win.isKeyWindow) return win;
            }
            if (windowScene.windows.count > 0) {
                return windowScene.windows.firstObject;
            }
        }
    }
    return app.windows.firstObject;
}

- (void)initMenu {
    UIWindow *keyWindow = [self findActiveWindow];
    if (!keyWindow) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self initMenu];
        });
        return;
    }

    if (!_vna) {
        _vna = [[ImGuiDrawView alloc] init];
        _vna.view.frame = keyWindow.bounds;
        _vna.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _vna.view.backgroundColor = [UIColor clearColor];
        _vna.view.hidden = YES;
        [_vna.view setUserInteractionEnabled:NO];
        menu_open = false;
        show_4e_menu = false;
        show_neverlose_menu = false;
        [keyWindow addSubview:_vna.view];
    }

    if (!_gearButton) {
        _gearButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _gearButton.frame = CGRectMake(16, 130, 44, 44);
        _gearButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.88f];
        _gearButton.layer.cornerRadius = 22.0f;
        _gearButton.layer.borderWidth = 1.2f;
        _gearButton.layer.borderColor = [UIColor whiteColor].CGColor;
        [_gearButton setTitle:@"⚙" forState:UIControlStateNormal];
        [_gearButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _gearButton.titleLabel.font = [UIFont systemFontOfSize:20.0f];
        [_gearButton addTarget:self action:@selector(onGearTapped) forControlEvents:UIControlEventTouchUpInside];

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [_gearButton addGestureRecognizer:pan];
        [keyWindow addSubview:_gearButton];
    }

    if (!_btn4E) {
        _btn4E = [UIButton buttonWithType:UIButtonTypeCustom];
        _btn4E.frame = CGRectMake(68, 132, 74, 38);
        _btn4E.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.9f];
        _btn4E.layer.cornerRadius = 8.0f;
        _btn4E.layer.borderWidth = 1.0f;
        _btn4E.layer.borderColor = [UIColor whiteColor].CGColor;
        [_btn4E setTitle:@"4E?" forState:UIControlStateNormal];
        [_btn4E setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _btn4E.titleLabel.font = [UIFont boldSystemFontOfSize:13.0f];
        _btn4E.hidden = YES;
        [_btn4E addTarget:self action:@selector(on4ETapped) forControlEvents:UIControlEventTouchUpInside];
        [keyWindow addSubview:_btn4E];
    }

    if (!_btnNeverlose) {
        _btnNeverlose = [UIButton buttonWithType:UIButtonTypeCustom];
        _btnNeverlose.frame = CGRectMake(148, 132, 106, 38);
        _btnNeverlose.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.9f];
        _btnNeverlose.layer.cornerRadius = 8.0f;
        _btnNeverlose.layer.borderWidth = 1.0f;
        _btnNeverlose.layer.borderColor = [UIColor whiteColor].CGColor;
        [_btnNeverlose setTitle:@"NEVERLOSE" forState:UIControlStateNormal];
        [_btnNeverlose setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _btnNeverlose.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
        _btnNeverlose.hidden = YES;
        [_btnNeverlose addTarget:self action:@selector(onNeverloseTapped) forControlEvents:UIControlEventTouchUpInside];
        [keyWindow addSubview:_btnNeverlose];
    }
}

- (void)positionSubButtons {
    CGFloat bx = CGRectGetMaxX(_gearButton.frame) + 8.0f;
    CGFloat by = CGRectGetMidY(_gearButton.frame) - 19.0f;
    _btn4E.frame = CGRectMake(bx, by, 74, 38);
    _btnNeverlose.frame = CGRectMake(bx + 82.0f, by, 106, 38);
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    UIView *btn = gesture.view;
    UIView *superview = btn.superview;
    if (!btn || !superview) return;

    CGPoint translation = [gesture translationInView:superview];
    CGPoint newCenter = CGPointMake(btn.center.x + translation.x, btn.center.y + translation.y);

    CGFloat halfW = btn.bounds.size.width / 2.0f + 8.0f;
    CGFloat halfH = btn.bounds.size.height / 2.0f + 8.0f;
    newCenter.x = MIN(MAX(newCenter.x, halfW), superview.bounds.size.width - halfW);
    newCenter.y = MIN(MAX(newCenter.y, halfH), superview.bounds.size.height - halfH);

    btn.center = newCenter;
    [gesture setTranslation:CGPointZero inView:superview];
    [self positionSubButtons];
}

- (void)onGearTapped {
    if (!_vna) [self initMenu];
    _subButtonsVisible = !_subButtonsVisible;
    [self positionSubButtons];
    _btn4E.hidden = !_subButtonsVisible;
    _btnNeverlose.hidden = !_subButtonsVisible;
    [_gearButton.superview bringSubviewToFront:_gearButton];
    [_btn4E.superview bringSubviewToFront:_btn4E];
    [_btnNeverlose.superview bringSubviewToFront:_btnNeverlose];
}

- (void)on4ETapped {
    if (!_vna) [self initMenu];
    BOOL nextState = !show_4e_menu;
    show_4e_menu = nextState;
    show_neverlose_menu = false;
    [self syncOverlayState];
}

- (void)onNeverloseTapped {
    if (!_vna) [self initMenu];
    BOOL nextState = !show_neverlose_menu;
    show_neverlose_menu = nextState;
    show_4e_menu = false;
    [self syncOverlayState];
}

- (void)syncOverlayState {
    BOOL anyOpen = (show_4e_menu || show_neverlose_menu);
    menu_open = anyOpen;
    _vna.view.hidden = !anyOpen;
    [_vna.view setUserInteractionEnabled:anyOpen];

    _btn4E.backgroundColor = show_4e_menu
        ? [[UIColor whiteColor] colorWithAlphaComponent:0.95f]
        : [[UIColor blackColor] colorWithAlphaComponent:0.9f];
    [_btn4E setTitleColor:(show_4e_menu ? [UIColor blackColor] : [UIColor whiteColor]) forState:UIControlStateNormal];

    _btnNeverlose.backgroundColor = show_neverlose_menu
        ? [[UIColor whiteColor] colorWithAlphaComponent:0.95f]
        : [[UIColor blackColor] colorWithAlphaComponent:0.9f];
    [_btnNeverlose setTitleColor:(show_neverlose_menu ? [UIColor blackColor] : [UIColor whiteColor]) forState:UIControlStateNormal];

    [_gearButton.superview bringSubviewToFront:_gearButton];
    [_btn4E.superview bringSubviewToFront:_btn4E];
    [_btnNeverlose.superview bringSubviewToFront:_btnNeverlose];
}

@end
