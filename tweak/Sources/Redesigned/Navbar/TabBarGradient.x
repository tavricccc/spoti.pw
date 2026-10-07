// iPad's floating navbar needs no full-width dark scrim behind it.
// Spotify 9.1.78 UUID c712370b44cd35c8a0584fbed1ad0758:
// TabBarGradientView initWithFrame: @48@0:8CGRect16 at 0x107bc242c.
// UIKit's window callback also covers creation through Swift or initWithCoder:.
// Keeping alpha at zero covers native re-layouts without changing arranged-view visibility.
#import "Core/SGCore.h"

%hook _TtC23NavigationUI_TabBarImpl18TabBarGradientView
- (void)didMoveToWindow {
    %orig;
    ((UIView *)self).alpha = 0;
}
- (void)setAlpha:(CGFloat)alpha {
    %orig(0);
}
%end

%ctor {
    if (!SGRedesignedUI() || UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPad) return;
    %init;
    SGRequireClasses(@[@"_TtC23NavigationUI_TabBarImpl18TabBarGradientView"]);
}
