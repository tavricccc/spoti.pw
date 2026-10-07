// Spotify 9.1.78, UUID c712370b-44cd-35c8-a058-4fbed1ad0758: the native expand/condense
// element uses "expand_collapse_button" (cstring 0x10a45cbc0, refs 0x1014fb32c,
// 0x105bbff38, 0x1079f02d8). Keep its action; do not spoof the side attachment's isActive state.
#import "Core/SGCore.h"
#import "Redesigned/Kit/SGRKit.h"
#import "Settings/SGModPage.h"
#import "Player.h"
#import "PlayerTablet.h"

static char kPolicyKey, kAppliedKey, kPanKey, kExpandKey, kCloseKey;
static BOOL sg_portraitFull, sg_landscapeFull;

static BOOL tablet(UIView *view) {
    return view.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad;
}

static BOOL fullPane(UIView *view) {
    UIWindow *window = view.window;
    return window && view.bounds.size.width >= window.bounds.size.width - 8 &&
        view.bounds.size.height >= window.bounds.size.height * 0.65;
}

NSArray<SGModSection *> *SGRPlayerTabletSections(void) {
    if (UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPad) return @[];
    return @[SGNotedSection(@"iPad player", @[
        SGOptionRow(@"Full screen in portrait", @"Skip the split player when the window is tall", SGRKeyTabletPortraitFullscreen),
        SGOptionRow(@"Full screen in landscape", @"Skip the split player when the window is wide", SGRKeyTabletLandscapeFullscreen),
    ], @"Restart Spotify after changing these settings. Each window uses its own available size.")];
}

void SGRPlayerTabletHeaderLaidOut(UIViewController *unit) {
    UIView *header = unit.viewIfLoaded;
    if (!tablet(header) || !header.window) return;
    UIViewController *player = unit;
    Class playerClass = NSClassFromString(@"_TtC19NowPlaying_ViewImpl24NowPlayingViewController");
    while (player && ![player isKindOfClass:playerClass]) player = player.parentViewController;
    if (!player) return;
    UIView *host = player.viewIfLoaded;
    UIWindow *window = host.window;
    if (!window) return;
    BOOL portrait = window.bounds.size.height >= window.bounds.size.width;
    BOOL wanted = portrait ? sg_portraitFull : sg_landscapeFull;
    NSInteger policy = (portrait ? 2 : 4) | wanted;
    NSNumber *previous = objc_getAssociatedObject(window, &kPolicyKey);
    UIView *expand = SGRFindByIdentifier(header, @"expand_collapse_button", &kExpandKey);
    if (!expand) return;
    // Full-screen-only mode offers no way back to the split pane in this orientation.
    expand.alpha = wanted && fullPane(host) ? 0 : 1;
    expand.userInteractionEnabled = expand.alpha > 0;
    expand.accessibilityElementsHidden = expand.alpha == 0;
    NSNumber *applied = objc_getAssociatedObject(host, &kAppliedKey);
    if (applied.integerValue == policy) return;
    objc_setAssociatedObject(host, &kAppliedKey, @(policy), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(window, &kPolicyKey, @(policy), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    BOOL change = wanted ? !fullPane(host) : previous && (previous.integerValue & 1) && fullPane(host);
    if (!change) return;
    __weak UIView *weak = expand;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIView *button = weak;
        if (button.window == window && [objc_getAssociatedObject(window, &kPolicyKey) integerValue] == policy)
            SGRActivate(button);
    });
}

@interface SGRTabletDismissPan : UIPanGestureRecognizer <UIGestureRecognizerDelegate>
@end

@implementation SGRTabletDismissPan
- (instancetype)init {
    if (!(self = [super initWithTarget:nil action:NULL])) return nil;
    [self addTarget:self action:@selector(pulled:)];
    self.delegate = self;
    self.cancelsTouchesInView = NO;
    self.maximumNumberOfTouches = 1;
    return self;
}
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gesture {
    CGPoint velocity = [self velocityInView:self.view];
    return fullPane(self.view) && !UIAccessibilityIsVoiceOverRunning() &&
        velocity.y > 0 && velocity.y > fabs(velocity.x) * 1.5;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldReceiveTouch:(UITouch *)touch {
    for (UIView *view = touch.view; view && view != self.view; view = view.superview)
        if ([view isKindOfClass:UIControl.class]) return NO;
    // Browsing the lyrics remains their scroll view's gesture; the header can still dismiss them.
    return !SGRPlayerLyricsOpen() || [touch locationInView:self.view].y < self.view.safeAreaInsets.top + 80;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)other {
    return YES;
}
- (void)pulled:(UIPanGestureRecognizer *)pan {
    if (pan.state != UIGestureRecognizerStateEnded || !fullPane(self.view) || SGRPlayerIsTransitioning()) return;
    CGPoint distance = [pan translationInView:self.view], speed = [pan velocityInView:self.view];
    if (distance.y < 100 && !(distance.y > 24 && speed.y > 900)) return;
    UIView *close = SGRFindByIdentifier(self.view, @"now-playing-minimize-button", &kCloseKey);
    if (close) SGRActivate(close);
}
@end

%hook _TtC19NowPlaying_ViewImpl24NowPlayingViewController
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    objc_setAssociatedObject(((UIViewController *)self).viewIfLoaded, &kAppliedKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (void)viewDidLayoutSubviews {
    %orig;
    UIView *view = ((UIViewController *)self).viewIfLoaded;
    if (!tablet(view) || objc_getAssociatedObject(view, &kPanKey)) return;
    SGRTabletDismissPan *pan = [SGRTabletDismissPan new];
    [view addGestureRecognizer:pan];
    objc_setAssociatedObject(view, &kPanKey, pan, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%end

%ctor {
    if (!SGRedesignedUI() || UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPad) return;
    sg_portraitFull = SGHidden(SGRKeyTabletPortraitFullscreen);
    sg_landscapeFull = SGHidden(SGRKeyTabletLandscapeFullscreen);
    %init;
    SGRequireClasses(@[@"_TtC19NowPlaying_ViewImpl24NowPlayingViewController"]);
}
