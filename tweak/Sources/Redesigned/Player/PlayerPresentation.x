// Spotify 9.1.78 UUID c712370b44cd35c8a0584fbed1ad0758.
// The initial-mode enum at 0x1055a1944 accepts "Collapsed" (table 0x10d11f228).
// SPTBarOverlayPresentationTransition reads horizontalSizeClass at 0x109814d64
// and 0x1098153c4: Regular uses tablet geometry, Compact uses the phone transition.
// NowPlayingOverlayContainer.expand is v16@0:8 at 0x1012ebce8.
#import "Core/SGCore.h"

static char kExpandSourcesKey, kExpandMaskKey, kExpandSavedMaskKey;

// Button ids in 9.1.78: expand_toggle_button 0x10a541220 (xref 0x1025c21e8),
// expand_collapse_button 0x10a45cbc0, EmbeddedNPV.expandButton in embedded NPV.
// Search the presentation's full content, not only the modes' HeaderElementsUnit.
static void lockExpand(UIView *root) {
    if (!root.window) return;
    NSHashTable<UIView *> *buttons = objc_getAssociatedObject(root, &kExpandSourcesKey);
    if (!buttons.count) {
        buttons = [NSHashTable weakObjectsHashTable];
        SGForEachView(root, ^(UIView *view) {
            NSString *identifier = view.accessibilityIdentifier;
            if ([identifier isEqualToString:@"expand_toggle_button"] ||
                [identifier isEqualToString:@"expand_collapse_button"] ||
                [identifier isEqualToString:@"EmbeddedNPV.expandButton"]) {
                [buttons addObject:view];
                SGLog(@"iPad player: expansion control %@ in %@", identifier, NSStringFromClass(root.class));
            }
        });
        objc_setAssociatedObject(root, &kExpandSourcesKey, buttons, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    BOOL locked = root.window.bounds.size.width > root.window.bounds.size.height;
    for (UIView *button in buttons) {
        if (![button isDescendantOfView:root]) continue;
        CALayer *mask = objc_getAssociatedObject(button, &kExpandMaskKey);
        if (locked) {
            if (!mask) {
                mask = [CALayer layer];
                mask.frame = CGRectMake(0, 0, 1, 1);
                mask.backgroundColor = UIColor.clearColor.CGColor;
                objc_setAssociatedObject(button, &kExpandSavedMaskKey, button.layer.mask ?: (id)NSNull.null, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                objc_setAssociatedObject(button, &kExpandMaskKey, mask, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            button.layer.mask = mask;
            button.userInteractionEnabled = NO;
            button.accessibilityElementsHidden = YES;
        } else if (mask) {
            id saved = objc_getAssociatedObject(button, &kExpandSavedMaskKey);
            button.layer.mask = saved == NSNull.null ? nil : saved;
            button.userInteractionEnabled = YES;
            button.accessibilityElementsHidden = NO;
            objc_setAssociatedObject(button, &kExpandMaskKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(button, &kExpandSavedMaskKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
}

static BOOL wideWindow(UIWindow *window) {
    return window && window.bounds.size.width > window.bounds.size.height;
}

// The window environment also reaches overlays outside the tab controller's children.
static void updateLayout(UIViewController *controller) {
    UIWindow *window = controller.viewIfLoaded.window;
    if (!window) return;
    if (@available(iOS 17.0, *)) {
        if (wideWindow(window)) {
            if ([window.traitOverrides containsTrait:UITraitHorizontalSizeClass.class])
                [window.traitOverrides removeTrait:UITraitHorizontalSizeClass.class];
        } else if (window.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassCompact) {
            window.traitOverrides.horizontalSizeClass = UIUserInterfaceSizeClassCompact;
        }
    }
}

%hook _TtC23NavigationUI_TabBarImpl19TabBarContainerImpl
- (void)viewWillLayoutSubviews {
    updateLayout((UIViewController *)self);
    %orig;
}
%end

%hook _TtC23NowPlaying_ViewPageImpl26NowPlayingOverlayContainer
- (void)viewDidLayoutSubviews {
    %orig;
    lockExpand(((UIViewController *)self).viewIfLoaded);
}
- (void)expand {
    if (wideWindow(((UIViewController *)self).viewIfLoaded.window)) return;
    %orig;
}
%end

%hook _TtC23NowPlaying_ViewPageImpl29NowPlayingAttachmentContainer
- (void)viewDidLayoutSubviews {
    %orig;
    lockExpand(((UIViewController *)self).viewIfLoaded);
}
%end

%hook _TtC19NowPlaying_ViewImpl24NowPlayingViewController
- (void)viewDidLayoutSubviews {
    %orig;
    lockExpand(((UIViewController *)self).viewIfLoaded);
}
%end

%ctor {
    if (!SGRedesignedUI() || UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPad) return;
    if (![NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"] isEqualToString:@"9.1.78"]) return;
    NSString *key = @"ios-adaptivelayout-experimentationmanager.now_playing_view_initial_mode";
    SGRegisterFlagForcer(YES, ^id(NSString *flag) {
        return [flag isEqualToString:key] ? @"Collapsed" : nil;
    }, ^id(NSString *flag) {
        return SGRedesignedUIStored() && [flag isEqualToString:key] ? @"Collapsed" : nil;
    });
    %init;
    SGRequireClasses(@[@"_TtC23NavigationUI_TabBarImpl19TabBarContainerImpl",
                       @"_TtC23NowPlaying_ViewPageImpl26NowPlayingOverlayContainer",
                       @"_TtC23NowPlaying_ViewPageImpl29NowPlayingAttachmentContainer",
                       @"_TtC19NowPlaying_ViewImpl24NowPlayingViewController"]);
}
