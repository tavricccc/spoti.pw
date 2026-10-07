// Conceal only the native content replaced by the lyrics. A mask keeps Spotify's artwork out even
// when its own transition writes a nonzero alpha; neither Spotify's arranged views nor their layout
// are hidden. Each original mask and caption alpha is restored when the lyrics close.
#import "Core/SGCore.h"
#import "Player.h"

static char kCaptionAlpha, kCaptionAccessibility, kCoverMask, kOriginalCoverMask;
static __weak UIView *sg_maskedList;

void SGRPlayerHeaderFollowLyrics(UIView *header, BOOL open) {
    SGForEachView(header, ^(UIView *view) {
        if (![view isKindOfClass:UILabel.class]) return;
        for (UIView *parent = view.superview; parent && parent != header; parent = parent.superview)
            if ([parent isKindOfClass:UIControl.class]) return;
        NSNumber *alpha = objc_getAssociatedObject(view, &kCaptionAlpha);
        if (open) {
            if (!alpha) {
                objc_setAssociatedObject(view, &kCaptionAlpha, @(view.alpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                objc_setAssociatedObject(view, &kCaptionAccessibility, @(view.accessibilityElementsHidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            view.alpha = 0;
            view.accessibilityElementsHidden = YES;
        } else if (alpha) {
            view.alpha = alpha.doubleValue;
            view.accessibilityElementsHidden = [objc_getAssociatedObject(view, &kCaptionAccessibility) boolValue];
            objc_setAssociatedObject(view, &kCaptionAlpha, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(view, &kCaptionAccessibility, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    });
}

static void restoreCoverList(UIView *list) {
    if (!list || !objc_getAssociatedObject(list, &kCoverMask)) return;
    id original = objc_getAssociatedObject(list, &kOriginalCoverMask);
    list.layer.mask = original == NSNull.null ? nil : original;
    list.alpha = 1;
    objc_setAssociatedObject(list, &kCoverMask, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(list, &kOriginalCoverMask, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

void SGRPlayerLyricsCoverHidden(UIView *host, BOOL hidden) {
    UIView *list = hidden ? SGRPlayerCoverListIn(host) : nil;
    if (sg_maskedList != list) {
        restoreCoverList(sg_maskedList);
        sg_maskedList = list;
    }
    if (!list) return;
    CALayer *mask = objc_getAssociatedObject(list, &kCoverMask);
    if (!mask) {
        mask = [CALayer layer];
        mask.frame = CGRectMake(0, 0, 1, 1);
        mask.backgroundColor = UIColor.clearColor.CGColor;
        objc_setAssociatedObject(list, &kOriginalCoverMask, list.layer.mask ?: (id)NSNull.null, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(list, &kCoverMask, mask, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    list.layer.mask = mask;
    list.alpha = 0;
}
