#import "Settings/SGModPage.h"
#import "PlayerTablet.h"

NSArray<SGModSection *> *SGRPlayerTabletSections(void) {
    if (UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPad) return @[];
    return @[SGNotedSection(@"iPad player", @[
        SGOptionRow(@"Full screen in portrait", @"Open the player expanded when the window is tall", SGRKeyTabletPortraitFullscreen),
        SGOptionRow(@"Full screen in landscape", @"Open the player expanded when the window is wide", SGRKeyTabletLandscapeFullscreen),
    ], @"Restart Spotify after changing these settings. Controls the initial presentation, not the entire tablet layout. After rotating, close and reopen the player to apply the new orientation's choice.")];
}
