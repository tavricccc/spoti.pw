// Spotify 9.1.78 UUID c712370b44cd35c8a0584fbed1ad0758.
// ToggleButtonElementUI's view getter 0x104b0e604 calls constructor 0x1023d1c78.
// The constructor assigns "now-playing-toggle-button" (0x10a6835b0) via
// 0x10306a548 -> setAccessibilityIdentifier: (selref 0x10cdf1bc8), then binds
// UIControlEventTouchUpInside (0x40). Hide this actual control, not similarly named resources.
#import "Core/SGCore.h"

static BOOL expansionControl(UIControl *control) {
    return [control.accessibilityIdentifier isEqualToString:@"now-playing-toggle-button"];
}

%hook UIControl
- (void)setAccessibilityIdentifier:(NSString *)identifier {
    %orig;
    if (expansionControl((UIControl *)self)) {
        ((UIControl *)self).alpha = 0;
        ((UIControl *)self).userInteractionEnabled = NO;
        ((UIControl *)self).accessibilityElementsHidden = YES;
        ((UIControl *)self).isAccessibilityElement = NO;
    }
}
- (void)setAlpha:(CGFloat)alpha {
    if (expansionControl((UIControl *)self)) alpha = 0;
    %orig(alpha);
}
- (void)setUserInteractionEnabled:(BOOL)enabled {
    if (expansionControl((UIControl *)self)) enabled = NO;
    %orig(enabled);
}
- (void)setAccessibilityElementsHidden:(BOOL)hidden {
    if (expansionControl((UIControl *)self)) hidden = YES;
    %orig(hidden);
}
- (void)setIsAccessibilityElement:(BOOL)element {
    if (expansionControl((UIControl *)self)) element = NO;
    %orig(element);
}
%end

%ctor {
    if (!SGRedesignedUI() || UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPad) return;
    if (![NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"] isEqualToString:@"9.1.78"]) return;
    %init;
}
