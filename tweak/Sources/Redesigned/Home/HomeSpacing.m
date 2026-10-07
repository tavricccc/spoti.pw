// Home's vertical feed holds the nested shortcut grid and horizontal shelves (HomeSections.x).
// Reserve space in that feed, not the header's safe area: moving both leaves the same overlap.
#import "Core/SGCore.h"
#import "HomeSpacing.h"

static char kSpacingKey;
static const CGFloat kToolbarGap = 16;

@interface SGRHomeSpacing : NSObject
@property (nonatomic, weak) UICollectionView *feed;
@property (nonatomic) CGFloat nativeTop, appliedTop;
@end
@implementation SGRHomeSpacing
@end

void SGRHomeReserveToolbarSpace(UIViewController *page) {
    UIView *root = page.viewIfLoaded;
    if (root.traitCollection.userInterfaceIdiom != UIUserInterfaceIdiomPad) return;
    SGRHomeSpacing *spacing = objc_getAssociatedObject(page, &kSpacingKey);
    UICollectionView *feed = spacing.feed;
    if (!feed || ![feed isDescendantOfView:root]) {
        __block UICollectionView *found = nil;
        SGForEachView(root, ^(UIView *view) {
            if (![view isKindOfClass:UICollectionView.class] || view.bounds.size.height < root.bounds.size.height * 0.5) return;
            if (!found || view.bounds.size.height > found.bounds.size.height) found = (UICollectionView *)view;
        });
        feed = found;
        if (!feed) return;
        spacing = [SGRHomeSpacing new];
        spacing.feed = feed;
        spacing.nativeTop = spacing.appliedTop = feed.contentInset.top;
        objc_setAssociatedObject(page, &kSpacingKey, spacing, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    UIEdgeInsets inset = feed.contentInset;
    // Spotify can recompute its own inset on rotation or when its header changes.
    if (fabs(inset.top - spacing.appliedTop) > 0.5) spacing.nativeTop = inset.top;
    CGFloat top = spacing.nativeTop + kToolbarGap;
    if (fabs(inset.top - top) < 0.5) return;
    BOOL atTop = feed.contentOffset.y <= -feed.adjustedContentInset.top + 1 && !feed.isDragging && !feed.isDecelerating;
    inset.top = top;
    spacing.appliedTop = top;
    feed.contentInset = inset;
    if (atTop) feed.contentOffset = CGPointMake(feed.contentOffset.x, -feed.adjustedContentInset.top);
}
