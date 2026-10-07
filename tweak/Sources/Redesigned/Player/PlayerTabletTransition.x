// Spotify 9.1.78 UUID c712370b44cd35c8a0584fbed1ad0758:
// MainUIContainer traitCollectionDidChange: 0x108788a84 -> 0x102cb116c:
// Compact/Regular migration dismisses, replaces barAnimator, then reopens expanded UI
// at 0x102cb13a4-0x102cb13b4. A rotation completion cannot prevent that reopen.
// setExpandedUIVisibility:navigationReason:completion: 0x106843568 -> 0x10158da80:
// value 1 dismisses the expanded overlay; value 0 constructs/presents it.
// setReducedUIMode:navigationReason:completion: 0x107bb9c90 -> 0x1042061d4:
// value 1 calls 0x107a027f0 -> presentSideAttachmentWithtransitionStyle:completion:.
// The two original completions preserve state/interaction and finish the native transitions.
// RegularAnimator horizontalSizeClass ivar 0x10d308dd8 holds NSInteger;
// 0x104206208-0x104206220 requires Regular (2) and nowPlayingUIMode 0 for Split.
#import "Core/SGCore.h"

@protocol SGRTabletAnimator <NSObject>
- (NSInteger)expandedUIVisibility;
- (NSInteger)nowPlayingUIMode;
- (void)setExpandedUIVisibility:(NSInteger)value navigationReason:(id)reason completion:(dispatch_block_t)completion;
- (void)setReducedUIMode:(NSInteger)value navigationReason:(id)reason completion:(dispatch_block_t)completion;
@end

static ptrdiff_t SGRTabletSizeClassOffset;

%hook _TtC19MainUI_TabBarUIImpl25NowPlayingRegularAnimator
- (void)setExpandedUIVisibility:(NSInteger)value navigationReason:(id)reason completion:(dispatch_block_t)completion {
    id<SGRTabletAnimator> animator = (id)self;
    NSInteger sizeClass = *(const NSInteger *)((const uint8_t *)(__bridge const void *)self + SGRTabletSizeClassOffset);
    SGLog(@"redesign tablet: expanded request %ld, size class %ld, UI mode %ld", (long)value, (long)sizeClass, (long)[animator nowPlayingUIMode]);
    if (value != 0 || sizeClass != UIUserInterfaceSizeClassRegular || [animator nowPlayingUIMode] != 0) {
        %orig;
        return;
    }
    // Redirect the request on the owning animator, including the native migration's
    // reopen. Finish the original completion only after its side attachment is ready.
    if ([animator expandedUIVisibility] != 0) {
        [animator setReducedUIMode:1 navigationReason:reason completion:completion];
        return;
    }
    __weak id<SGRTabletAnimator> weakAnimator = animator;
    dispatch_block_t showSplit = ^{
        [weakAnimator setReducedUIMode:1 navigationReason:reason completion:completion];
    };
    %orig(1, reason, showSplit);
}
%end

%ctor {
    if (!SGRedesignedUI() || UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPad) return;
    if (![NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"] isEqualToString:@"9.1.78"]) return;
    Class cls = NSClassFromString(@"_TtC19MainUI_TabBarUIImpl25NowPlayingRegularAnimator");
    SGRTabletSizeClassOffset = ivar_getOffset(class_getInstanceVariable(cls, "horizontalSizeClass"));
    %init;
    SGRequireClasses(@[@"_TtC19MainUI_TabBarUIImpl25NowPlayingRegularAnimator"]);
}
