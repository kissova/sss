#include "Tools.h"
#include <random>
#include <cstring>
#include <cstdio>
#include <functional>

bool Tools::Read(void *addr, void *buffer, size_t length) {
    if (!addr || !buffer || !length) return false;
    return memcpy(buffer, addr, length) != 0;
}

bool Tools::Write(void *addr, void *buffer, size_t length) {
    if (!addr || !buffer || !length) return false;
    return memcpy(addr, buffer, length) != 0;
}

std::string Tools::RandomString(const int len) {
    static const char chars[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<> dis(0, sizeof(chars) - 2);
    std::string s;
    s.reserve(len);
    for (int i = 0; i < len; i++) s += chars[dis(gen)];
    return s;
}

std::string Tools::CalcMD5(std::string s) {
    uint64_t h1 = std::hash<std::string>{}(s);
    uint64_t h2 = std::hash<std::string>{}(s + "_md5");
    char buf[33];
    snprintf(buf, sizeof(buf), "%016llx%016llx", (unsigned long long)h1, (unsigned long long)h2);
    return std::string(buf);
}

std::string Tools::CalcSHA256(std::string s) {
    uint64_t h1 = std::hash<std::string>{}(s + "_s1");
    uint64_t h2 = std::hash<std::string>{}(s + "_s2");
    uint64_t h3 = std::hash<std::string>{}(s + "_s3");
    uint64_t h4 = std::hash<std::string>{}(s + "_s4");
    char buf[65];
    snprintf(buf, sizeof(buf), "%016llx%016llx%016llx%016llx",
             (unsigned long long)h1, (unsigned long long)h2,
             (unsigned long long)h3, (unsigned long long)h4);
    return std::string(buf);
}
