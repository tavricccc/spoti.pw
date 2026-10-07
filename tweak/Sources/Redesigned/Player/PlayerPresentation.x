// Spotify 9.1.78 UUID c712370b44cd35c8a0584fbed1ad0758.
// Initial-mode enum 0x1055a1944 accepts Collapsed (table 0x10d11f228).
// Native transition checks horizontalSizeClass at 0x109814d64 / 0x1098153c4.
#import "Core/SGCore.h"

%hook _TtC23NavigationUI_TabBarImpl19TabBarContainerImpl
- (void)viewWillLayoutSubviews {
    UIWindow *window = ((UIViewController *)self).viewIfLoaded.window;
    if (window) {
        if (@available(iOS 17.0, *)) {
            if (window.bounds.size.width > window.bounds.size.height) {
                if ([window.traitOverrides containsTrait:UITraitHorizontalSizeClass.class])
                    [window.traitOverrides removeTrait:UITraitHorizontalSizeClass.class];
            } else if (window.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassCompact) {
                window.traitOverrides.horizontalSizeClass = UIUserInterfaceSizeClassCompact;
            }
        }
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
    SGRequireClasses(@[@"_TtC23NavigationUI_TabBarImpl19TabBarContainerImpl"]);
}
