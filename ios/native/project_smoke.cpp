#include "AMProjectBridge.h"
#include <cassert>
#include <cstring>
#include <string>
#include <cstdio>
int main() {
  const char *scene = "<scene title=\"Hello\" width=\"1080\" height=\"1920\" fps=\"60\" totalTime=\"5000\"><shape id=\"1\" name=\"Video\" startTime=\"0\" endTime=\"5000\"/><text id=\"2\" name=\"Title\" startTime=\"500\" endTime=\"3000\"/></scene>";
  char *parsed = am_ios_scene_summary(scene);
  assert(parsed && std::strstr(parsed, "\"layers\"") && std::strstr(parsed, "\"name\":\"Video\""));
  assert(std::strstr(parsed, "\"fps\":\"60\"") && std::strstr(parsed, "\"type\":\"text\""));
  am_ios_free(parsed);
  char *bad=am_ios_scene_summary("<broken");
  assert(bad && std::strstr(bad, "\"error\""));
  am_ios_free(bad);
  std::puts("Original AbsentMotion scene parser: passed");
}
