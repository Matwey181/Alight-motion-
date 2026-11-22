// An iOS bridge to AbsentMotion's original scene XML parser (shared/cpp/xml.cpp).
#pragma once
#ifdef __cplusplus
extern "C" {
#endif
/// JSON summary of a parsed AbsentMotion scene. Caller frees with am_ios_free().
/// Returns {"error":"..."} for malformed XML; never returns nullptr for valid inputs.
char *am_ios_scene_summary(const char *sceneXml);
void am_ios_free(void *value);
#ifdef __cplusplus
}
#endif
