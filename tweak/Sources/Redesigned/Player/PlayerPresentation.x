// Spotify 9.1.78 UUID c712370b44cd35c8a0584fbed1ad0758.
// Initial-mode enum 0x1055a1944 accepts Collapsed (table 0x10d11f228).
// Native transition checks horizontalSizeClass at 0x109814d64 / 0x1098153c4.
#import "Core/SGCore.h"

static char SGRTabletTransitionSizeKey;

static void SGRApplyTabletSizeClass(UIWindow *window, CGSize size) {
    if (@available(iOS 17.0, *)) {
        if (size.width > size.height) {
            if ([window.traitOverrides containsTrait:UITraitHorizontalSizeClass.class]) {
                SGLog(@"redesign tablet: %.0fx%.0f, restore system size class", size.width, size.height);
                [window.traitOverrides removeTrait:UITraitHorizontalSizeClass.class];
            }
        } else if (window.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassCompact) {
            SGLog(@"redesign tablet: %.0fx%.0f, apply compact size class", size.width, size.height);
            window.traitOverrides.horizontalSizeClass = UIUserInterfaceSizeClassCompact;
        }
    }
}

// MainUIContainer viewWillTransitionToSize:withTransitionCoordinator: 0x1024beb94.
// Update from the target geometry even when the player covers the tab bar.
%hook _TtC19MainUI_TabBarUIImpl15MainUIContainer
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    UIWindow *window = ((UIViewController *)self).viewIfLoaded.window;
    if (window) {
        objc_setAssociatedObject(window, &SGRTabletTransitionSizeKey, [NSValue valueWithCGSize:size], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        SGRApplyTabletSizeClass(window, size);
    }
    %orig;
    __weak UIWindow *weakWindow = window;
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        UIWindow *current = weakWindow;
        if (!current) return;
        objc_setAssociatedObject(current, &SGRTabletTransitionSizeKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        SGRApplyTabletSizeClass(current, current.bounds.size);
    }];
}
%end

%hook _TtC23NavigationUI_TabBarImpl19TabBarContainerImpl
- (void)viewWillLayoutSubviews {
    UIWindow *window = ((UIViewController *)self).viewIfLoaded.window;
    if (window) {
        NSValue *targetSize = objc_getAssociatedObject(window, &SGRTabletTransitionSizeKey);
        SGRApplyTabletSizeClass(window, targetSize ? targetSize.CGSizeValue : window.bounds.size);
    }
    %orig;
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
    SGRequireClasses(@[@"_TtC23NavigationUI_TabBarImpl19TabBarContainerImpl", @"_TtC19MainUI_TabBarUIImpl15MainUIContainer"]);
}
