#import "Core/SGCore.h"
#import "Redesigned/Kit/SGRKit.h"
#import "Player.h"
#import "PlayerLandscape.h"
#import "PlayerDismiss.h"
#import <objc/message.h>

static char kPanKey, kArrowKey, kNativeCloseKey, kExpandKey, kClosingKey, kPendingKey, kGlassKey;

static BOOL fullscreen(UIView *host) {
    return host.window && host.bounds.size.width >= host.window.bounds.size.width - 8 &&
        host.bounds.size.height >= host.window.bounds.size.height * 0.65;
}

BOOL SGRPlayerDismiss(UIView *host) {
    if (!host.window || SGRPlayerIsTransitioning() || objc_getAssociatedObject(host, &kClosingKey)) return NO;
    UIViewController *player = nil, *attachment = nil, *modal = nil;
    for (UIResponder *r = host; r; r = r.nextResponder) {
        if (![r isKindOfClass:UIViewController.class]) continue;
        UIViewController *vc = (UIViewController *)r;
        NSString *name = NSStringFromClass(vc.class);
        if ([name isEqualToString:@"_TtC19NowPlaying_ViewImpl24NowPlayingViewController"]) player = vc;
        if ([name isEqualToString:@"_TtC23NowPlaying_ViewPageImpl29NowPlayingAttachmentContainer"]) attachment = vc;
        if (vc.presentingViewController) modal = vc;
    }
    // Controllers may be parented without being in the view's responder chain.
    for (UIViewController *vc = player.parentViewController; vc; vc = vc.parentViewController) {
        if ([NSStringFromClass(vc.class) isEqualToString:@"_TtC23NowPlaying_ViewPageImpl29NowPlayingAttachmentContainer"]) attachment = vc;
        if (vc.presentingViewController) modal = vc;
    }
    UIView *close = SGRFindByIdentifier(host, @"now-playing-minimize-button", &kNativeCloseKey);
    UIView *expand = SGRFindByIdentifier(host, @"expand_collapse_button", &kExpandKey);
    if (!close && !attachment && !modal && !expand) {
        SGLog(@"redesign player: no native dismissal owner for %@", NSStringFromClass(player.class));
        return NO;
    }
    NSNumber *operation = @(CACurrentMediaTime());
    objc_setAssociatedObject(host, &kClosingKey, operation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (close) SGRActivate(close);
    else if (attachment) {
        // 9.1.78: @32@0:8q16@?24 at 0x1078706b0. Style 0 is accepted by
        // 0x102cb302c; this removes the side attachment through its own state machine.
        SEL selector = NSSelectorFromString(@"dismissSideAttachmentWithtransitionStyle:completion:");
        id pending = ((id (*)(id, SEL, NSInteger, id))objc_msgSend)(attachment, selector, 0, nil);
        objc_setAssociatedObject(host, &kPendingKey, pending, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else if (modal) [modal dismissViewControllerAnimated:YES completion:nil];
    else SGRActivate(expand);  // native expanded overlay returns to its condensed pane
    __weak UIView *weak = host;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        UIView *view = weak;
        if (objc_getAssociatedObject(view, &kClosingKey) != operation) return;
        objc_setAssociatedObject(view, &kClosingKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(view, &kPendingKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    });
    return YES;
}

@interface SGRDismissPan : UIPanGestureRecognizer <UIGestureRecognizerDelegate>
@end
@implementation SGRDismissPan
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
    return fullscreen(self.view) && !UIAccessibilityIsVoiceOverRunning() &&
        velocity.y > 0 && velocity.y > fabs(velocity.x) * 1.5;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldReceiveTouch:(UITouch *)touch {
    for (UIView *view = touch.view; view && view != self.view; view = view.superview)
        if ([view isKindOfClass:UIControl.class]) return NO;
    // A swipe through the lyrics scrolls them. The top band remains a dismissal gesture.
    return !SGRPlayerLyricsOpen() || [touch locationInView:self.view].y < self.view.safeAreaInsets.top + 80;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)other { return YES; }
- (void)pulled:(UIPanGestureRecognizer *)pan {
    if (pan.state != UIGestureRecognizerStateEnded || !fullscreen(self.view)) return;
    CGPoint distance = [pan translationInView:self.view], speed = [pan velocityInView:self.view];
    if (distance.y >= 100 || (distance.y > 24 && speed.y > 900)) SGRPlayerDismiss(self.view);
}
@end

void SGRPlayerDismissLayout(UIView *host) {
    if (!objc_getAssociatedObject(host, &kPanKey)) {
        SGRDismissPan *pan = [SGRDismissPan new];
        [host addGestureRecognizer:pan];
        objc_setAssociatedObject(host, &kPanKey, pan, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    SGRGlyphButton *arrow = objc_getAssociatedObject(host, &kArrowKey);
    BOOL needsArrow = fullscreen(host) && !SGRPlayerLandscape(host) &&
        !SGRFindByIdentifier(host, @"now-playing-minimize-button", &kNativeCloseKey);
    if (!needsArrow) { [arrow removeFromSuperview]; return; }
    if (!arrow) {
        arrow = [SGRGlyphButton buttonWithSymbol:@"chevron.down" pointSize:20 title:@"Close player"];
        arrow.glyph.tintColor = SGRPrimary();
        __weak UIView *weak = host;
        arrow.onTap = ^{ SGRPlayerDismiss(weak); };
        objc_setAssociatedObject(host, &kArrowKey, arrow, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    UIView *expand = SGRFindByIdentifier(host, @"expand_collapse_button", &kExpandKey);
    CGFloat left = expand && expand.alpha > 0.01 ? 72 : 16;
    arrow.frame = CGRectMake(host.safeAreaInsets.left + left, host.safeAreaInsets.top + 12, 44, 44);
    SGRGlassInside(arrow, &kGlassKey, 44);
    if (arrow.superview != host) [host addSubview:arrow];
    else [host bringSubviewToFront:arrow];
}
