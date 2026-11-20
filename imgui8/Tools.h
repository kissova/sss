#pragma once
#include <iostream>
#include <stdio.h>
#include <string>
#include <unistd.h>
#include <stdint.h>
#include <sys/stat.h>

namespace Tools {
    bool Read(void *addr, void *buffer, size_t length);
    bool Write(void *addr, void *buffer, size_t length);
    std::string RandomString(const int len);
    std::string CalcMD5(std::string s);
    std::string CalcSHA256(std::string s);
}