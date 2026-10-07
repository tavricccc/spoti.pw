// The native footer's bottom stack is recorded in player/01.txt. Move that group, not its
// individual controls, into the unused lower portion of a tall docked iPad player.
#import "Core/SGCore.h"
#import "PlayerTabletLayout.h"

static char kMovedKey, kReachKey;

@interface SGRTabletControlsReach : UIView
@property (nonatomic, weak) UIView *stack;
@end
@implementation SGRTabletControlsReach
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *stack = self.stack;
    for (UIView *v = stack; v && v != self.superview; v = v.superview)
        if (v.hidden || v.alpha < 0.01) return nil;
    UIView *hit = [stack hitTest:[stack convertPoint:point fromView:self] withEvent:event];
    return hit == stack ? nil : hit;
}
@end

void SGRPlayerTabletLayoutFooter(UIView *row) {
    UIView *stack = row.superview;
    if (![stack isKindOfClass:UIStackView.class]) return;
    UIViewController *player = nil;
    for (UIResponder *r = row; r; r = r.nextResponder) {
        if ([r isKindOfClass:UIViewController.class] && [NSStringFromClass(r.class) isEqualToString:@"_TtC19NowPlaying_ViewImpl24NowPlayingViewController"]) {
            player = (UIViewController *)r;
            break;
        }
    }
    UIView *host = player.viewIfLoaded;
    UIWindow *window = host.window;
    BOOL dockedPortrait = window && window.bounds.size.height > window.bounds.size.width && host.bounds.size.width < window.bounds.size.width - 8;
    if (!dockedPortrait) {
        if (objc_getAssociatedObject(stack, &kMovedKey)) {
            stack.transform = CGAffineTransformIdentity;
            objc_setAssociatedObject(stack, &kMovedKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        [(UIView *)objc_getAssociatedObject(stack, &kReachKey) removeFromSuperview];
        return;
    }
    CGFloat middle = [row convertPoint:CGPointMake(CGRectGetMidX(row.bounds), CGRectGetMidY(row.bounds)) toView:host].y - stack.transform.ty;
    CGFloat target = host.bounds.size.height - host.safeAreaInsets.bottom - 44;
    CGFloat move = MAX(0, round(target - middle));
    CGAffineTransform transform = CGAffineTransformMakeTranslation(0, move);
    if (!CGAffineTransformEqualToTransform(stack.transform, transform)) stack.transform = transform;
    objc_setAssociatedObject(stack, &kMovedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    SGRTabletControlsReach *reach = objc_getAssociatedObject(stack, &kReachKey);
    if (!reach) {
        reach = [SGRTabletControlsReach new];
        reach.stack = stack;
        objc_setAssociatedObject(stack, &kReachKey, reach, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if (reach.superview != host) [host addSubview:reach];
    CGRect frame = [stack convertRect:stack.bounds toView:host];
    if (!CGRectEqualToRect(reach.frame, frame)) reach.frame = frame;
}
