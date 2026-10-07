// Liked Songs has a procedural cover rather than an ordinary playlist UIImageView.
// Give the full-bleed hero the same blue/purple field and white heart, once per launch.
#import "LikedSongsArtwork.h"

UIImage *SGRLikedSongsArtwork(void) {
    static UIImage *artwork;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        CGSize size = CGSizeMake(512, 512);
        UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
        format.scale = 1;
        format.opaque = YES;
        artwork = [[[UIGraphicsImageRenderer alloc] initWithSize:size format:format] imageWithActions:^(UIGraphicsImageRendererContext *renderer) {
            CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
            CGFloat colors[] = {0.28, 0.08, 0.92, 1, 0.57, 0.68, 0.68, 1};
            CGGradientRef gradient = CGGradientCreateWithColorComponents(space, colors, NULL, 2);
            CGContextDrawLinearGradient(renderer.CGContext, gradient, CGPointZero, CGPointMake(512, 512), 0);
            CGGradientRelease(gradient);
            CGColorSpaceRelease(space);
            UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:176 weight:UIImageSymbolWeightRegular];
            UIImage *heart = [[UIImage systemImageNamed:@"heart.fill" withConfiguration:config] imageWithTintColor:UIColor.whiteColor renderingMode:UIImageRenderingModeAlwaysOriginal];
            CGRect rect = CGRectMake((512 - heart.size.width) / 2, (512 - heart.size.height) / 2, heart.size.width, heart.size.height);
            [heart drawInRect:rect];
        }];
    });
    return artwork;
}
