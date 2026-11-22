// Playback-time mapping for AbsentMotion iOS speedMap. Uses original easing.cpp via AMEasingBridge.
#pragma once
#ifdef __cplusplus
extern "C" {
#endif
typedef struct AMIOSTimeline AMIOSTimeline;
/// joinedCurves: one original AbsentMotion easing string per point separated by newlines.
AMIOSTimeline *am_ios_timeline_create(const float *u, const float *speed, const char *joinedCurves,
                                      int count, double mediaDurationSeconds);
double am_ios_timeline_duration(const AMIOSTimeline *timeline);
double am_ios_timeline_output_seconds(const AMIOSTimeline *timeline, double sourceSeconds);
double am_ios_timeline_source_seconds(const AMIOSTimeline *timeline, double outputSeconds);
void am_ios_timeline_destroy(AMIOSTimeline *timeline);
#ifdef __cplusplus
}
#endif
