#include "AMEasingBridge.h"
#include "easing.h"
#include <cmath>

float am_ios_ease(const char *curve, float t) {
    if (!std::isfinite(t)) return 0.0f;
    const am::Easing parsed = am::ParseEasing(curve ? curve : "linear");
    return am::Ease(parsed, t);
}

float am_ios_speed_at(const float *times, const float *speeds, const char *const *easings,
                      int count, float t) {
    if (!times || !speeds || count <= 0 || !std::isfinite(t)) return 1.0f;
    for (int i = 0; i < count; ++i) {
        if (!std::isfinite(times[i]) || !std::isfinite(speeds[i])) return 1.0f;
        if (i > 0 && !(times[i] > times[i - 1])) return 1.0f;
    }
    if (t <= times[0]) return speeds[0];
    if (t >= times[count - 1]) return speeds[count - 1];
    for (int i = 1; i < count; ++i) {
        if (t < times[i]) {
            const float u = (t - times[i - 1]) / (times[i] - times[i - 1]);
            const char *curve = easings ? easings[i] : nullptr;
            const float eased = am_ios_ease(curve, u);
            return speeds[i - 1] + (speeds[i] - speeds[i - 1]) * eased;
        }
    }
    return speeds[count - 1];
}
