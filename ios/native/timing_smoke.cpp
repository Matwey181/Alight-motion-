#include "AMVideoTiming.h"
#include <cassert>
#include <cmath>
#include <cstdio>
int main() {
    const float times[]={0.f,1.f};
    const float half[]={2.f,2.f};
    const float normal[]={1.f,1.f};
    auto *fast=am_ios_timeline_create(times,half,"linear\nlinear",2,10.0);
    assert(fast && std::fabs(am_ios_timeline_duration(fast)-5.0)<0.001);
    assert(std::fabs(am_ios_timeline_output_seconds(fast,5.0)-2.5)<0.001);
    assert(std::fabs(am_ios_timeline_source_seconds(fast,2.5)-5.0)<0.001);
    am_ios_timeline_destroy(fast);
    auto *flat=am_ios_timeline_create(times,normal,"linear\nlinear",2,10.0);
    assert(flat && std::fabs(am_ios_timeline_duration(flat)-10.0)<0.001);
    am_ios_timeline_destroy(flat);
    const float ramp[]={1.f,3.f};
    auto *eased=am_ios_timeline_create(times,ramp,"linear\ncubicBezier 0.42 0 0.58 1",2,10.0);
    assert(eased && am_ios_timeline_duration(eased)>3.333 &&
           am_ios_timeline_duration(eased)<10.0);
    am_ios_timeline_destroy(eased);
    std::puts("Original-easing iOS timeline: passed");
}
