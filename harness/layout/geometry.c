// Compile as C11. Tests the production geometry directly, without a UIKit mock.
#include <assert.h>
#include <stdio.h>
#include "../../tweak/Sources/Redesigned/Kit/SGRAdaptiveLayout.h"

int main(void) {
    const double widths[] = {280, 320, 375, 390, 402, 430, 480, 584, 744, 820, 1024, 1180, 1366};
    const double words[] = {148, 200, 320, 480};
    unsigned cases = 0;
    for (unsigned tablet = 0; tablet < 2; tablet++) {
        for (unsigned w = 0; w < sizeof widths / sizeof widths[0]; w++) {
            double width = widths[w];
            SGRPageMetrics metrics = SGRPageMetricsFor(width, tablet != 0);
            assert(metrics.textX >= metrics.margin);
            assert(metrics.textX + metrics.textWidth <= width - metrics.margin + 0.01);
            assert(fabs(metrics.textX + metrics.textWidth / 2 - width / 2) < 0.01);
            if (tablet) assert(metrics.textWidth <= 640);
            for (unsigned flags = 0; flags < 4; flags++) {
                for (unsigned word = 0; word < sizeof words / sizeof words[0]; word++) {
                    bool shuffle = (flags & 1) != 0, trailing = (flags & 2) != 0;
                    SGRHeaderActionsLayout row = SGRHeaderActionsFor(width, words[word], tablet != 0, shuffle, trailing);
                    assert(row.playWidth >= 68); // 44pt glyph canvas + internal padding
                    assert(fabs(row.playX + row.playWidth / 2 - width / 2) < 0.01);
                    assert(row.playX >= metrics.margin - 0.01);
                    assert(row.playX + row.playWidth <= width - metrics.margin + 0.01);
                    if (shuffle) {
                        assert(row.shuffleX >= metrics.margin - 0.01);
                        assert(row.shuffleX + 48 + 16 <= row.playX + 0.01);
                    }
                    if (trailing) {
                        assert(row.trailingX >= row.playX + row.playWidth + 16 - 0.01);
                        assert(row.trailingX + 48 <= width - metrics.margin + 0.01);
                    }
                    double capsule = SGRHomeCapsuleWidth(width, words[word], 96, tablet != 0);
                    assert(capsule > 0 && capsule <= width - 32);
                    cases++;
                }
            }
        }
    }
    assert(SGRHomeCapsuleWidth(820, 45, 32, true) > SGRHomeCapsuleWidth(402, 45, 32, false));
    printf("Phone/tablet geometry: %u cases passed\n", cases);
    return 0;
}
