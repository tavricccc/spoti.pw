#import "Navbar.h"

static NSString *const kLabelsMode = @"spotifyglass.redesign.navbar.labelsMode";

SGRNavbarLabelsMode SGRNavbarLabels(void) {
    NSUserDefaults *prefs = NSUserDefaults.standardUserDefaults;
    if (![prefs objectForKey:kLabelsMode]) {
        [prefs setInteger:[prefs boolForKey:SGRKeyNavbarHideLabels] ? SGRNavbarLabelsHide : SGRNavbarLabelsShow forKey:kLabelsMode];
        [prefs removeObjectForKey:SGRKeyNavbarHideLabels];
    }
    return [prefs integerForKey:kLabelsMode];
}

void SGRSetNavbarLabels(SGRNavbarLabelsMode mode) {
    [NSUserDefaults.standardUserDefaults setInteger:mode forKey:kLabelsMode];
}

NSString *SGRNavbarLabelsTitle(void) {
    return @[@"Show", @"Hide", @"Auto"][(NSUInteger)SGRNavbarLabels()];
}

BOOL SGRNavbarLabelsFit(NSArray<NSString *> *titles, CGFloat width) {
    SGRNavbarLabelsMode mode = SGRNavbarLabels();
    if (mode != SGRNavbarLabelsAuto) return mode == SGRNavbarLabelsShow;
    // iPad's floating bar places the glyph beside its title. Measure that wider layout so
    // a narrow split pane drops labels before UIKit clips them. Dynamic Type participates.
    UIFont *font = [UIFontMetrics.defaultMetrics scaledFontForFont:[UIFont systemFontOfSize:15 weight:UIFontWeightSemibold]];
    CGFloat needed = 32;
    for (NSString *title in titles)
        needed += MAX(64, ceil([title sizeWithAttributes:@{NSFontAttributeName:font}].width) + 56);
    return needed <= width;
}
