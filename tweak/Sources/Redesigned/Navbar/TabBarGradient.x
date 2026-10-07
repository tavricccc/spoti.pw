// iPad's floating navbar needs no full-width dark scrim behind it.
// Spotify 9.1.78 UUID c712370b44cd35c8a0584fbed1ad0758:
// TabBarGradientView initWithFrame: @48@0:8CGRect16 at 0x107bc242c.
// setAlpha: is inherited UIKit API. Keeping alpha at zero also covers native re-layouts.
#import "Core/SGCore.h"

%hook _TtC23NavigationUI_TabBarImpl18TabBarGradientView
- (id)initWithFrame:(CGRect)frame {
    UIView *view = %orig;
    view.alpha = 0;
    return view;
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
