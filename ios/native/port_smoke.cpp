#include "AMEasingBridge.h"
#include <cassert>
#include <cmath>
#include <cstdio>

int main() {
    assert(std::fabs(am_ios_ease("linear", 0.5f) - 0.5f) < 1e-5f);
    assert(std::fabs(am_ios_ease("cubicBezier 0.42 0.0 0.58 1.0", 0.5f) - 0.5f) < 1e-4f);
    assert(am_ios_ease("cubicBezier 0.42 0.0 1.0 1.0", 0.3f) < 0.3f);
    const float t[] = {0.0f, 0.5f, 1.0f};
    const float speeds[] = {1.0f, 3.0f, 1.0f};
    const char *ease[] = {nullptr, "linear", "linear"};
    assert(std::fabs(am_ios_speed_at(t, speeds, ease, 3, 0.0f) - 1.0f) < 1e-5f);
    assert(std::fabs(am_ios_speed_at(t, speeds, ease, 3, 0.25f) - 2.0f) < 1e-5f);
    assert(std::fabs(am_ios_speed_at(t, speeds, ease, 3, 0.75f) - 2.0f) < 1e-5f);
    assert(std::fabs(am_ios_speed_at(t, speeds, ease, 3, 1.0f) - 1.0f) < 1e-5f);
    assert(am_ios_speed_at(nullptr, nullptr, nullptr, 0, 0.4f) == 1.0f);
    std::puts("Native AbsentMotion easing core: all smoke tests passed");
}
