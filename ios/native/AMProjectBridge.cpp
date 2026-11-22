#include "AMProjectBridge.h"
#include "xml.h"
#include <cstdlib>
#include <cstring>
#include <sstream>
#include <string>

namespace {
void jsonString(std::ostringstream &out, const char *value) {
    out << '"';
    for (const unsigned char c : std::string(value ? value : "")) {
        switch (c) {
            case '"': out << "\\\""; break;
            case '\\': out << "\\\\"; break;
            case '\n': out << "\\n"; break;
            case '\r': out << "\\r"; break;
            case '\t': out << "\\t"; break;
            default:
                if (c < 0x20) {
                    const char *digits = "0123456789abcdef";
                    out << "\\u00" << digits[c >> 4] << digits[c & 15];
                } else out << c;
        }
    }
    out << '"';
}
void field(std::ostringstream &out, const char *key, const char *value) {
    jsonString(out, key); out << ':'; jsonString(out, value);
}
bool isLayer(const std::string &name) {
    return name == "shape" || name == "text" || name == "drawing" || name == "embedScene" ||
           name == "camera" || name == "audio" || name == "nullobj" || name == "model" || name == "light";
}
char *duplicate(const std::string &value) {
    char *buf = static_cast<char *>(std::malloc(value.size() + 1));
    if (!buf) return nullptr;
    std::memcpy(buf, value.c_str(), value.size() + 1);
    return buf;
}
}
extern "C" char *am_ios_scene_summary(const char *sceneXml) {
    if (!sceneXml) return duplicate("{\"error\":\"Empty XML input\"}");
    std::string error;
    const auto root = am::ParseXml(sceneXml, &error);
    if (!root || root->name != "scene") {
        std::ostringstream out;
        out << "{\"error\":";
        jsonString(out, error.empty() ? "Not an AbsentMotion scene XML" : error.c_str());
        out << '}';
        return duplicate(out.str());
    }
    std::ostringstream out;
    out << '{';
    field(out,"title", root->attr("title"));out << ',';
    field(out,"width",root->attr("width"));out << ',';
    field(out,"height",root->attr("height"));out << ',';
    field(out,"fps",root->attr("fps"));out << ',';
    field(out,"durationMs",root->attr("totalTime"));out << ',';
    field(out,"version",root->attr("amver"));out << ',';
    out << "\"layers\":[";
    bool first = true;
    for (const auto &child : root->children) {
        if (!isLayer(child->name)) continue;
        if (!first) out << ',';first = false;
        out << '{';
        field(out,"type", child->name.c_str());out << ',';
        field(out,"name", child->attr("name"));out << ',';
        field(out,"id", child->attr("id"));out << ',';
        field(out,"startMs", child->attr("startTime"));out << ',';
        field(out,"endMs", child->attr("endTime"));
        out << '}';
    }
    out << "]}";
    return duplicate(out.str());
}
extern "C" void am_ios_free(void *value) { std::free(value); }
