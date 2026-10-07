// Spotify 9.1.78 UUID c712370b44cd35c8a0584fbed1ad0758:
// RegularAnimator rootContentPresenter:willTransitionTo:with: 0x101e2b698 (v48@0:8@16CGSize24@40).
// setExpandedUIVisibility:navigationReason:completion: 0x106843568 -> 0x10158da80:
// value 1 dismisses the expanded overlay; value 0 constructs/presents it.
// setReducedUIMode:navigationReason:completion: 0x107bb9c90 -> 0x1042061d4:
// value 1 calls 0x107a027f0 -> presentSideAttachmentWithtransitionStyle:completion:.
// The two original completions preserve state/interaction and finish the native transitions.
#import "Core/SGCore.h"

@protocol SGRTabletAnimator <NSObject>
- (NSInteger)expandedUIVisibility;
- (void)setExpandedUIVisibility:(NSInteger)value navigationReason:(id)reason completion:(dispatch_block_t)completion;
- (void)setReducedUIMode:(NSInteger)value navigationReason:(id)reason completion:(dispatch_block_t)completion;
@end

%hook _TtC19MainUI_TabBarUIImpl25NowPlayingRegularAnimator
- (void)rootContentPresenter:(id)presenter willTransitionTo:(CGSize)size with:(id<UIViewControllerTransitionCoordinator>)coordinator {
    %orig;
    if (size.width <= size.height) return;
    __weak id<SGRTabletAnimator> animator = (id)self;
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        id<SGRTabletAnimator> current = animator;
        if (context.isCancelled || !current || [current expandedUIVisibility] != 0) return;
        // SPTUBINavigationReason +passthrough @16@0:8 at 0x108130028.
        id reason = ((id (*)(id, SEL))objc_msgSend)(NSClassFromString(@"SPTUBINavigationReason"), NSSelectorFromString(@"passthrough"));
        [current setExpandedUIVisibility:1 navigationReason:reason completion:^{
            [animator setReducedUIMode:1 navigationReason:reason completion:nil];
        }];
    }];
}
%end

%ctor {
    if (!SGRedesignedUI() || UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPad) return;
    if (![NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"] isEqualToString:@"9.1.78"]) return;
    %init;
    SGRequireClasses(@[@"_TtC19MainUI_TabBarUIImpl25NowPlayingRegularAnimator", @"SPTUBINavigationReason"]);
}
