// C interface for the original AbsentMotion easing algorithm on iOS.
// Built with shared/cpp/easing.cpp; does not substitute a new easing engine.
#pragma once
#ifdef __cplusplus
extern "C" {
#endif

/// Evaluate one of AbsentMotion's original easing curves (e.g. "cubicBezier 0.42 0.0 0.58 1.0").
float am_ios_ease(const char *curve, float t);

/// Evaluate the speed curve from the same speed-map knot representation used by AbsentMotion.
/// Point easing belongs to the segment that ENDS at the point, as in SpeedCurve.kt.
/// Inputs: times and speeds of count increasing points, curve strings per point; returns 1 for invalid inputs.
float am_ios_speed_at(const float *times, const float *speeds, const char *const *easings,
                      int count, float t);

#ifdef __cplusplus
}
#endif
