// Spotify 9.1.78 UUID c712370b44cd35c8a0584fbed1ad0758.
// Properties initializer 0x1055a1944 reads this enum with default "Collapsed".
// String-switch table 0x10d11f218 / 0x10d11f228 is Expanded=0, Collapsed=1.
// Swift getter 0x10636cf90 reads the properties' one-byte nowPlayingViewInitialMode ivar.
// Updating the properties reaches Swift callers too; swizzling the ObjC getter would not.
#import "Core/SGCore.h"
#import "PlayerTablet.h"

static NSString *const kInitialMode = @"ios-adaptivelayout-experimentationmanager.now_playing_view_initial_mode";
static NSMapTable *sg_modes;
static BOOL sg_portrait, sg_landscape;

static void applyMode(id properties, BOOL portrait) {
    Ivar ivar = class_getInstanceVariable(object_getClass(properties), "nowPlayingViewInitialMode");
    uint8_t *value = (uint8_t *)(__bridge void *)properties + ivar_getOffset(ivar);
    *value = (portrait ? sg_portrait : sg_landscape) ? 0 : [[sg_modes objectForKey:properties] unsignedCharValue];
}

%hook _TtC41AdaptiveLayout_ExperimentationManagerImpl54SPTAdaptiveLayout_ExperimentationManagerImplProperties
- (id)initWithConfigurationProvider:(id)provider {
    id result = %orig;
    Ivar ivar = class_getInstanceVariable(object_getClass(result), "nowPlayingViewInitialMode");
    uint8_t baseline = *((uint8_t *)(__bridge void *)result + ivar_getOffset(ivar));
    dispatch_async(dispatch_get_main_queue(), ^{
        [sg_modes setObject:@(baseline) forKey:result];
        for (UIWindowScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (![scene isKindOfClass:UIWindowScene.class] || scene.activationState != UISceneActivationStateForegroundActive) continue;
            for (UIWindow *window in scene.windows) if (window.isKeyWindow)
                applyMode(result, window.bounds.size.height >= window.bounds.size.width);
        }
    });
    return result;
}
%end

%hook _TtC23NavigationUI_TabBarImpl19TabBarContainerImpl
- (void)viewDidLayoutSubviews {
    %orig;
    UIWindow *window = ((UIViewController *)self).viewIfLoaded.window;
    if (!window) return;
    BOOL portrait = window.bounds.size.height >= window.bounds.size.width;
    for (id properties in sg_modes.keyEnumerator) applyMode(properties, portrait);
}
%end

%ctor {
    if (!SGRedesignedUI() || UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPad) return;
    if (![NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"] isEqualToString:@"9.1.78"]) return;
    sg_portrait = SGHidden(SGRKeyTabletPortraitFullscreen);
    sg_landscape = SGHidden(SGRKeyTabletLandscapeFullscreen);
    sg_modes = [NSMapTable weakToStrongObjectsMapTable];
    if (sg_portrait && sg_landscape) SGRegisterFlagForcer(YES, ^id(NSString *key) {
        return [key isEqualToString:kInitialMode] ? @"Expanded" : nil;
    }, nil);
    %init;
    SGRequireClasses(@[@"_TtC41AdaptiveLayout_ExperimentationManagerImpl54SPTAdaptiveLayout_ExperimentationManagerImplProperties"]);
}
