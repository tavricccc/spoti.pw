// Spotify 9.1.78 UUID c712370b44cd35c8a0584fbed1ad0758.
// The initial-mode enum at 0x1055a1944 accepts "Collapsed" (table 0x10d11f228).
// SPTBarOverlayPresentationTransition reads horizontalSizeClass at 0x109814d64
// and 0x1098153c4: Regular uses tablet geometry, Compact uses the phone transition.
// NowPlayingOverlayContainer.expand is v16@0:8 at 0x1012ebce8.
#import "Core/SGCore.h"

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
- (void)expand {
    if (wideWindow(((UIViewController *)self).viewIfLoaded.window)) return;
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
    SGRequireClasses(@[@"_TtC23NavigationUI_TabBarImpl19TabBarContainerImpl",
                       @"_TtC23NowPlaying_ViewPageImpl26NowPlayingOverlayContainer"]);
}
