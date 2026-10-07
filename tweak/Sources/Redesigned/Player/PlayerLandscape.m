// Landscape content is owned by the redesign. Native units stay in their original layout,
// masked while this panel is visible; Spotify's actions and playback service remain authoritative.
#import <MediaPlayer/MediaPlayer.h>
#import "Core/SGCore.h"
#import "Redesigned/Kit/SGRKit.h"
#import "Redesigned/NowPlayingBar/NowPlayingBar.h"
#import "Shared/Player/PlayerState.h"
#import "Shared/Player/SpeedPitch.h"
#import "Shared/Lyrics/Lyrics.h"
#import "Player.h"
#import "PlayerLandscape.h"
#import "PlayerDismiss.h"

static char kPanelKey, kMaskKey, kAccessKey, kTouchKey;
static char kMoreKey, kSaveKey, kConnectKey, kQueueKey, kMoreGlassKey, kSaveGlassKey;

BOOL SGRPlayerLandscape(UIView *host) {
    return host.window && host.bounds.size.width > host.bounds.size.height &&
        host.bounds.size.width >= host.window.bounds.size.width - 8;
}

typedef struct { CGRect cover, lyrics; CGFloat left, width, bottom; BOOL compact; } SGRLandscapeGeometry;
static SGRLandscapeGeometry geometry(UIView *host, BOOL lyrics) {
    UIEdgeInsets safe = host.safeAreaInsets;
    CGFloat width = host.bounds.size.width, height = host.bounds.size.height;
    BOOL compact = height < 500;
    CGFloat margin = compact ? 24 : MAX(48, width * 0.065);
    CGFloat top = safe.top + (compact ? 44 : 56);
    CGFloat bottom = height - safe.bottom - 44;
    CGFloat column = MIN(420, lyrics ? (width - safe.left - safe.right - margin * 3) * 0.40 : width * 0.5);
    CGFloat side = MIN(column, MAX(80, bottom - top - (compact ? 168 : 250)));
    // Short phone windows need a smaller cover but five separate 44pt transport targets.
    CGFloat controlsWidth = MAX(220, side);
    CGFloat left = lyrics ? safe.left + margin : (width - controlsWidth) / 2;
    CGRect cover = CGRectMake(left + (controlsWidth - side) / 2, top, side, side);
    CGFloat lyricsLeft = left + controlsWidth + margin;
    CGRect lines = CGRectMake(lyricsLeft, top, MAX(0, width - safe.right - margin - lyricsLeft), bottom - top);
    return (SGRLandscapeGeometry){cover, lines, left, controlsWidth, bottom, compact};
}
CGRect SGRPlayerLandscapeLyricsRect(UIView *host) { return geometry(host, YES).lyrics; }

@interface SGRLandscapeSlider : UISlider
@end
@implementation SGRLandscapeSlider
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return CGRectContainsPoint(CGRectInset(self.bounds, 0, -10), point);
}
@end

@interface SGRLandscapePanel : UIView <SGPlayerStateObserver>
@property (nonatomic, weak) UIView *host;
@property (nonatomic, strong) NSHashTable<UIView *> *units;
@end

@implementation SGRLandscapePanel {
    UIImageView *_cover;
    UILabel *_title, *_artist, *_elapsed, *_remaining;
    UISlider *_progress;
    MPVolumeView *_volume;
    SGRGlyphButton *_previous, *_play, *_next, *_shuffle, *_repeat;
    SGRGlyphButton *_more, *_save, *_connect, *_lyrics, *_queue, *_close;
    NSTimer *_timer;
    NSMutableArray *_notifications;
}
- (SGRGlyphButton *)button:(NSString *)symbol size:(CGFloat)size title:(NSString *)title action:(void (^)(void))action {
    SGRGlyphButton *button = [SGRGlyphButton buttonWithSymbol:symbol pointSize:size title:title];
    button.glyph.tintColor = SGRPrimary();
    button.onTap = action;
    [self addSubview:button];
    return button;
}
- (UILabel *)label:(CGFloat)size weight:(UIFontWeight)weight color:(UIColor *)color {
    UILabel *label = [UILabel new];
    label.font = [UIFont systemFontOfSize:size weight:weight];
    label.textColor = color;
    label.lineBreakMode = NSLineBreakByTruncatingTail;
    [self addSubview:label];
    return label;
}
- (instancetype)initWithFrame:(CGRect)frame {
    if (!(self = [super initWithFrame:frame])) return nil;
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    _units = [NSHashTable weakObjectsHashTable];
    _notifications = [NSMutableArray array];
    _cover = [UIImageView new];
    _cover.contentMode = UIViewContentModeScaleAspectFill;
    _cover.clipsToBounds = YES;
    _cover.layer.cornerRadius = SGRRadiusArtwork;
    [self addSubview:_cover];
    _title = [self label:20 weight:UIFontWeightSemibold color:SGRPrimary()];
    _artist = [self label:17 weight:UIFontWeightRegular color:SGRSecondary()];
    _elapsed = [self label:11 weight:UIFontWeightRegular color:SGRSecondary()];
    _remaining = [self label:11 weight:UIFontWeightRegular color:SGRSecondary()];
    _remaining.textAlignment = NSTextAlignmentRight;
    _progress = [SGRLandscapeSlider new];
    _progress.minimumTrackTintColor = SGRPrimary();
    _progress.maximumTrackTintColor = [UIColor colorWithWhite:1 alpha:0.25];
    [_progress addTarget:self action:@selector(seek:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    _progress.accessibilityLabel = @"Playback position";
    [self addSubview:_progress];
    _volume = [MPVolumeView new];
    _volume.tintColor = SGRSecondary();
    _volume.showsRouteButton = NO;
    [self addSubview:_volume];
    __weak typeof(self) weak = self;
    _previous = [self button:@"backward.end.fill" size:32 title:@"Previous" action:^{ [(id<SPTPlayer>)SGKaraokePlayer() skipToPreviousTrackWithOptions:nil]; }];
    _play = [self button:@"play.fill" size:44 title:@"Play" action:^{
        id<SPTPlayer> player = SGKaraokePlayer();
        if (SGPlayerState().isPaused) [player resume:nil]; else [player pause:nil];
    }];
    _next = [self button:@"forward.end.fill" size:32 title:@"Next" action:^{ [(id<SPTPlayer>)SGKaraokePlayer() skipToNextTrackWithOptions:nil]; }];
    _shuffle = [self button:@"shuffle" size:22 title:@"Shuffle" action:^{ [(id<SPTPlayer>)SGKaraokePlayer() setShufflingContext:!SGPlayerState().options.shufflingContext]; }];
    _repeat = [self button:@"repeat" size:22 title:@"Repeat" action:^{
        id<SPTPlayer> player = SGKaraokePlayer();
        SPTPlayerOptions *options = SGPlayerState().options;
        if (options.repeatingTrack) { [player setRepeatingTrack:NO]; [player setRepeatingContext:NO]; }
        else if (options.repeatingContext) [player setRepeatingTrack:YES];
        else [player setRepeatingContext:YES];
    }];
    _more = [self button:@"ellipsis" size:20 title:@"More" action:^{ [weak activate:@"Context menu" key:&kMoreKey]; }];
    SGPlayerMenuWatchMoreButton(_more);
    SGRPlayerMenuWatchMoreButton(_more);
    _save = [self button:@"plus.circle" size:24 title:@"Add to library" action:^{ [weak activate:@"AddButtonNowPlaying" key:&kSaveKey]; }];
    _connect = [self button:@"airplay.audio" size:22 title:@"Devices" action:^{ [weak activate:@"Components.ConnectButtonOutputSwitcher" key:&kConnectKey]; }];
    _lyrics = [self button:@"quote.bubble" size:22 title:@"Lyrics" action:^{ SGRPlayerToggleLyrics(); [weak refresh]; [weak setNeedsLayout]; }];
    _queue = [self button:@"list.bullet" size:22 title:@"Queue" action:^{ [weak activate:@"QueueButtonNowPlaying" key:&kQueueKey]; }];
    _close = [self button:@"chevron.down" size:20 title:@"Close player" action:^{ SGRPlayerDismiss(weak.host); }];
    SGAddPlayerStateObserver(self);
    for (NSNotificationName name in @[SGRNowPlayingArtworkDidChangeNotification, SGKaraokeLinesDidChangeNotification, UIApplicationDidBecomeActiveNotification]) {
        [_notifications addObject:[NSNotificationCenter.defaultCenter addObserverForName:name object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
            [weak refresh]; [weak startTimer];
        }]];
    }
    [_notifications addObject:[NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) { [weak stopTimer]; }]];
    return self;
}
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    return hit == self ? nil : hit;
}
- (void)activate:(NSString *)identifier key:(const void *)key {
    UIView *source = SGRFindByIdentifier(self.host, identifier, key);
    if (source) SGRActivate(source);
}
- (void)seek:(UISlider *)slider { SGKaraokeSeek((NSInteger)round(slider.value * 1000)); }
- (void)playerStateDidChange:(SPTPlayerState *)state { [self refresh]; }
- (void)refresh {
    SPTPlayerState *state = SGPlayerState();
    _title.text = state.track.trackTitle;
    _artist.text = state.track.artistName;
    UIImage *image = SGRNowPlayingArtwork(NULL, NULL);
    if (_cover.image != image) _cover.image = image;
    [_play.glyph setSymbol:state.isPaused ? @"play.fill" : @"pause.fill" animated:NO];
    _play.accessibilityLabel = state.isPaused ? @"Play" : @"Pause";
    _shuffle.glyph.tintColor = state.options.shufflingContext ? SGRAccent() : SGRSecondary();
    static char previousKey, nextKey;
    UIView *previous = SGRFindByIdentifier(self.host, @"SPTNowPlayingPreviousTrackButton", &previousKey);
    UIView *next = SGRFindByIdentifier(self.host, @"SPTNowPlayingNextTrackButton", &nextKey);
    _previous.enabled = [previous isKindOfClass:UIControl.class] ? ((UIControl *)previous).enabled : previous != nil;
    _next.enabled = [next isKindOfClass:UIControl.class] ? ((UIControl *)next).enabled : next != nil;
    [_repeat.glyph setSymbol:state.options.repeatingTrack ? @"repeat.1" : @"repeat" animated:NO];
    _repeat.glyph.tintColor = state.options.repeatingContext || state.options.repeatingTrack ? SGRAccent() : SGRSecondary();
    _lyrics.enabled = SGRPlayerLyricsAvailable() || SGRPlayerLyricsOpen();
    [_lyrics.glyph setSymbol:SGRPlayerLyricsOpen() ? @"quote.bubble.fill" : @"quote.bubble" animated:NO];
    UIView *save = SGRFindByIdentifier(self.host, @"AddButtonNowPlaying", &kSaveKey);
    _save.enabled = save != nil;
    if (save.accessibilityLabel.length) _save.accessibilityLabel = save.accessibilityLabel;
    BOOL added = [save isKindOfClass:UIControl.class] && ((UIControl *)save).selected;
    [_save.glyph setSymbol:added ? @"checkmark.circle.fill" : @"plus.circle" animated:NO];
    [self tick];
}
- (void)tick {
    double duration = MAX(0, SGPlayerState().duration), position = MAX(0, SGKaraokePositionMs() / 1000.0);
    _progress.maximumValue = duration;
    _progress.enabled = duration > 0;
    if (!_progress.tracking) _progress.value = MIN(duration, position);
    NSInteger elapsed = (NSInteger)position, remaining = (NSInteger)MAX(0, duration - position);
    _elapsed.text = [NSString stringWithFormat:@"%ld:%02ld", (long)(elapsed / 60), (long)(elapsed % 60)];
    _remaining.text = [NSString stringWithFormat:@"−%ld:%02ld", (long)(remaining / 60), (long)(remaining % 60)];
}
- (void)startTimer {
    if (_timer || !self.window || UIApplication.sharedApplication.applicationState != UIApplicationStateActive) return;
    __weak typeof(self) weak = self;
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer *timer) { [weak tick]; }];
}
- (void)stopTimer { [_timer invalidate]; _timer = nil; }
- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self.window) { [self refresh]; [self startTimer]; } else [self stopTimer];
}
- (void)dealloc {
    [_timer invalidate];
    for (id token in _notifications) [NSNotificationCenter.defaultCenter removeObserver:token];
}
- (void)layoutSubviews {
    [super layoutSubviews];
    SGRLandscapeGeometry g = geometry(self.host, SGRPlayerLyricsOpen());
    _cover.frame = g.cover;
    CGFloat gap = g.compact ? 6 : 20;
    CGFloat y = CGRectGetMaxY(g.cover) + gap;
    _title.font = [UIFont systemFontOfSize:g.compact ? 15 : 20 weight:UIFontWeightSemibold];
    _artist.font = [UIFont systemFontOfSize:g.compact ? 13 : 17];
    _title.frame = CGRectMake(g.left, y, MAX(0, g.width - 92), g.compact ? 20 : 26);
    _artist.frame = CGRectMake(g.left, CGRectGetMaxY(_title.frame), MAX(0, g.width - 92), g.compact ? 18 : 24);
    _save.frame = CGRectMake(g.left + g.width - 88, y, 44, 44);
    _more.frame = CGRectMake(g.left + g.width - 44, y, 44, 44);
    SGRGlassInside(_save, &kSaveGlassKey, 32);
    SGRGlassInside(_more, &kMoreGlassKey, 32);
    y += g.compact ? 40 : 62;
    _progress.frame = CGRectMake(g.left, y, g.width, 24);
    _elapsed.frame = CGRectMake(g.left, y + 22, g.width / 2, 16);
    _remaining.frame = CGRectMake(g.left + g.width / 2, y + 22, g.width / 2, 16);
    y += g.compact ? 38 : 54;
    NSArray<SGRGlyphButton *> *controls = @[_shuffle, _previous, _play, _next, _repeat];
    for (NSUInteger i = 0; i < controls.count; i++) {
        controls[i].frame = CGRectMake(g.left + (g.width - 44) * i / 4, y, 44, g.compact ? 44 : 64);
    }
    _volume.frame = CGRectMake(g.left, y + (g.compact ? 46 : 90), g.width, 30);
    CGFloat bottom = self.bounds.size.height - self.safeAreaInsets.bottom - 44;
    _connect.frame = CGRectMake(self.safeAreaInsets.left + 24, bottom, 44, 44);
    _queue.frame = CGRectMake(self.bounds.size.width - self.safeAreaInsets.right - 68, bottom, 44, 44);
    _lyrics.frame = CGRectOffset(_queue.frame, -64, 0);
    _close.frame = CGRectMake((self.bounds.size.width - 44) / 2, self.safeAreaInsets.top, 44, 44);
}
@end

static void maskUnit(UIView *view, BOOL mask) {
    id old = objc_getAssociatedObject(view, &kMaskKey);
    if (mask) {
        if (!old) {
            objc_setAssociatedObject(view, &kMaskKey, view.layer.mask ?: NSNull.null, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(view, &kAccessKey, @(view.accessibilityElementsHidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(view, &kTouchKey, @(view.userInteractionEnabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            view.layer.mask = [CALayer layer];
        }
        view.accessibilityElementsHidden = YES;
        view.userInteractionEnabled = NO;
    } else if (old) {
        view.layer.mask = old == NSNull.null ? nil : old;
        view.accessibilityElementsHidden = [objc_getAssociatedObject(view, &kAccessKey) boolValue];
        view.userInteractionEnabled = [objc_getAssociatedObject(view, &kTouchKey) boolValue];
        objc_setAssociatedObject(view, &kMaskKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

void SGRPlayerLandscapeLayout(UIView *host) {
    SGRLandscapePanel *panel = objc_getAssociatedObject(host, &kPanelKey);
    BOOL landscape = SGRPlayerLandscape(host);
    if (landscape && !panel) {
        panel = [SGRLandscapePanel new];
        panel.host = host;
        objc_setAssociatedObject(host, &kPanelKey, panel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        SGForEachView(host, ^(UIView *view) {
            UIResponder *responder = view.nextResponder;
            if (![responder isKindOfClass:UIViewController.class] || ((UIViewController *)responder).viewIfLoaded != view) return;
            NSString *name = NSStringFromClass(responder.class);
            if ([name containsString:@"ElementsUnit"] || [name containsString:@"DurationElementUnit"] || [name containsString:@"ReinventFree"])
                [panel.units addObject:view];
        });
    }
    if (!panel) return;
    for (UIView *unit in panel.units) maskUnit(unit, landscape);
    if (!landscape) { [panel removeFromSuperview]; return; }
    if (panel.superview != host) [host addSubview:panel];
    else if (host.subviews.lastObject != panel) [host bringSubviewToFront:panel];
    if (!CGRectEqualToRect(panel.frame, host.bounds)) panel.frame = host.bounds;
    [panel setNeedsLayout];
}

void SGRPlayerLandscapeUnit(UIViewController *unit) {
    UIView *view = unit.viewIfLoaded;
    UIView *host = nil;
    for (UIResponder *r = view; r; r = r.nextResponder) {
        if ([NSStringFromClass(r.class) isEqualToString:@"_TtC19NowPlaying_ViewImpl24NowPlayingViewController"]) {
            host = ((UIViewController *)r).viewIfLoaded;
            break;
        }
    }
    if (!host) return;
    SGRPlayerLandscapeLayout(host);
    SGRLandscapePanel *panel = objc_getAssociatedObject(host, &kPanelKey);
    [panel.units addObject:view];
    if ([NSStringFromClass(unit.class) containsString:@"Information"] && [view.superview isKindOfClass:UIStackView.class]) {
        [panel.units addObject:view.superview];
        maskUnit(view.superview, SGRPlayerLandscape(host));
    }
    maskUnit(view, SGRPlayerLandscape(host));
}
