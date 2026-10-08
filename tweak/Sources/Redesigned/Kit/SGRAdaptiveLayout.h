// Geometry only: viewport width and the actual device class, independent of UIKit traits.
#pragma once
#include <stdbool.h>
#include <math.h>

typedef struct {
    double margin, textX, textWidth;
} SGRPageMetrics;

static inline SGRPageMetrics SGRPageMetricsFor(double width, bool tablet) {
    double margin = tablet ? 24 : 20;
    double available = fmax(0, width - margin * 2);
    double text = tablet ? fmin(640, available) : available;
    return (SGRPageMetrics){margin, (width - text) / 2, text};
}

typedef struct {
    double playX, playWidth, shuffleX, trailingX;
} SGRHeaderActionsLayout;

static inline SGRHeaderActionsLayout SGRHeaderActionsFor(double width, double preferred,
                                                        bool tablet, bool shuffle, bool trailing) {
    double margin = SGRPageMetricsFor(width, tablet).margin;
    double reserve = shuffle || trailing ? 64 : 0; // 48pt target + 16pt gap, symmetric around Play
    double play = fmin(preferred, fmax(0, width - margin * 2 - reserve * 2));
    double x = (width - play) / 2;
    return (SGRHeaderActionsLayout){x, play, x - 64, x + play + 16};
}

static inline double SGRHomeCapsuleWidth(double width, double titleWidth, double accountWidth, bool tablet) {
    double preferred = fmax(tablet ? 260 : 220, titleWidth + accountWidth + 64);
    return fmax(0, fmin(width - 32, preferred));
}
