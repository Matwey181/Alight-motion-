#include "AMVideoTiming.h"
#include "AMEasingBridge.h"
#include <algorithm>
#include <cmath>
#include <sstream>
#include <string>
#include <vector>

struct AMIOSTimeline {
    double sourceDuration = 0;
    std::vector<double> playbackAtSource;
};
extern "C" AMIOSTimeline *am_ios_timeline_create(const float *u, const float *speed,
                                                  const char *joinedCurves, int count,
                                                  double mediaDurationSeconds) {
    if (!u || !speed || count < 2 || count > 1000 || !std::isfinite(mediaDurationSeconds) ||
        mediaDurationSeconds <= 0) return nullptr;
    for (int i = 0; i < count; ++i) {
        if (!std::isfinite(u[i]) || !std::isfinite(speed[i]) || speed[i] <= 0 ||
            (i > 0 && u[i] <= u[i - 1])) return nullptr;
    }
    if (u[0] != 0.0f || u[count - 1] != 1.0f) return nullptr;
    std::vector<std::string> curves(count, "linear");
    if (joinedCurves) {
        std::istringstream input(joinedCurves);
        for (int i = 0; i < count; ++i) {
            if (!std::getline(input, curves[i])) break;
            if (curves[i].empty()) curves[i] = "linear";
        }
    }
    std::vector<const char *> curvePtrs;
    curvePtrs.reserve(curves.size());
    for (auto &curve : curves) curvePtrs.push_back(curve.c_str());
    constexpr int kSteps = 2048;
    auto *timeline = new AMIOSTimeline();
    timeline->sourceDuration = mediaDurationSeconds;
    timeline->playbackAtSource.assign(kSteps + 1, 0.0);
    double previous = std::max(0.00001f, am_ios_speed_at(u, speed, curvePtrs.data(), count, 0.0f));
    for (int i = 1; i <= kSteps; ++i) {
        const float at = static_cast<float>(i) / kSteps;
        const double current = std::max(0.00001f, am_ios_speed_at(u, speed, curvePtrs.data(), count, at));
        const double elapsed = mediaDurationSeconds / kSteps * 0.5 * (1.0 / previous + 1.0 / current);
        timeline->playbackAtSource[i] = timeline->playbackAtSource[i - 1] + elapsed;
        previous = current;
    }
    return timeline;
}
extern "C" double am_ios_timeline_duration(const AMIOSTimeline *timeline) {
    return timeline ? timeline->playbackAtSource.back() : 0.0;
}
extern "C" double am_ios_timeline_output_seconds(const AMIOSTimeline *timeline, double sourceSeconds) {
    if (!timeline) return 0.0;
    constexpr int kSteps = 2048;
    const double x = std::clamp(sourceSeconds / timeline->sourceDuration, 0.0, 1.0) * kSteps;
    const int i = std::min(kSteps - 1, static_cast<int>(std::floor(x)));
    const double f = x - i;
    return timeline->playbackAtSource[i] * (1.0 - f) + timeline->playbackAtSource[i + 1] * f;
}
extern "C" double am_ios_timeline_source_seconds(const AMIOSTimeline *timeline, double outputSeconds) {
    if (!timeline) return 0.0;
    const auto &samples = timeline->playbackAtSource;
    auto hi = std::lower_bound(samples.begin(), samples.end(),
                              std::clamp(outputSeconds, 0.0, samples.back()));
    if (hi == samples.begin()) return 0.0;
    if (hi == samples.end()) return timeline->sourceDuration;
    const int i = static_cast<int>(hi - samples.begin());
    const double gap = samples[i] - samples[i - 1];
    const double f = gap > 0 ? (outputSeconds - samples[i - 1]) / gap : 0.0;
    return (i - 1 + std::clamp(f, 0.0, 1.0)) * timeline->sourceDuration / (samples.size() - 1);
}
extern "C" void am_ios_timeline_destroy(AMIOSTimeline *timeline) { delete timeline; }
