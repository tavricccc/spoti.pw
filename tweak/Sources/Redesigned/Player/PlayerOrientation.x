// Spotify 9.1.78 binary proof: AppDelegate application:supportedInterfaceOrientationsForWindow:
// 0x106ccb640; SPNavigationController supportedInterfaceOrientations 0x1010921a4,
// shouldAutorotate 0x10851a084; NowPlayingViewController shouldAutorotate 0x10750deb0.
#import "Core/SGCore.h"
#import "Player.h"

%hook _TtC24MusicApp_ContainerWiring18SpotifyAppDelegate
- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return %orig | UIInterfaceOrientationMaskLandscape;
}
%end

%hook SPNavigationController
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return %orig | UIInterfaceOrientationMaskLandscape;
}
- (BOOL)shouldAutorotate { return !SGRPlayerIsTransitioning(); }
%end

%hook _TtC19NowPlaying_ViewImpl24NowPlayingViewController
- (BOOL)shouldAutorotate { return !SGRPlayerIsTransitioning(); }
- (UIInterfaceOrientationMask)supportedInterfaceOrientations { return UIInterfaceOrientationMaskAllButUpsideDown; }
%end

%hook _TtC23NowPlaying_ViewPageImpl26NowPlayingOverlayContainer
- (UIInterfaceOrientationMask)supportedInterfaceOrientations { return %orig | UIInterfaceOrientationMaskLandscape; }
%end

%ctor {
    if (!SGRedesignedUI()) return;
    %init;
    SGRequireClasses(@[@"_TtC24MusicApp_ContainerWiring18SpotifyAppDelegate", @"SPNavigationController", @"_TtC19NowPlaying_ViewImpl24NowPlayingViewController", @"_TtC23NowPlaying_ViewPageImpl26NowPlayingOverlayContainer"]);
}
