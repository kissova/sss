#pragma once
#include <stdio.h>
#include <stdint.h>
#include <string.h>

#if defined(_MSC_VER)
#define ALWAYS_INLINE __forceinline
#else 
#define ALWAYS_INLINE __attribute__((always_inline))
#endif

#ifndef seed
constexpr int seedToInt(char c) { return c - '0'; }
const int seed = seedToInt(__TIME__[7]) +
                 seedToInt(__TIME__[6]) * 10 +
                 seedToInt(__TIME__[4]) * 60 +
                 seedToInt(__TIME__[3]) * 600 +
                 seedToInt(__TIME__[1]) * 3600 +
                 seedToInt(__TIME__[0]) * 36000;
#endif

template <uintptr_t Const> struct vxCplConstantify { enum { Value = Const }; };
constexpr uintptr_t vxCplRandom(uintptr_t Id) {
    return (1013904223 + 1664525 * ((Id > 0) ? (vxCplRandom(Id - 1)) : (seed))) & 0xFFFFFFFF;
}
#define vxRAND() (vxCplConstantify<vxCplRandom(__COUNTER__ + 1)>::Value)

const char vxCplEncryptCharKey = (const char)(vxRAND() & 0xFF);
constexpr char ALWAYS_INLINE vxCplEncryptChar(const char Ch, uintptr_t Idx) { 
    return Ch ^ (char)(vxCplEncryptCharKey + Idx); 
}

template <uintptr_t...> struct vxCplIndexList {};
template <typename IndexList, uintptr_t Right> struct vxCplAppend;
template <uintptr_t... Left, uintptr_t Right> struct vxCplAppend<vxCplIndexList<Left...>, Right> { 
    typedef vxCplIndexList<Left..., Right> Result; 
};
template <uintptr_t N> struct vxCplIndexes { 
    typedef typename vxCplAppend<typename vxCplIndexes<N - 1>::Result, N - 1>::Result Result; 
};
template <> struct vxCplIndexes<0> { typedef vxCplIndexList<> Result; };

template <typename IndexList> struct vxCplEncryptedString;
template <uintptr_t... Idx> struct vxCplEncryptedString<vxCplIndexList<Idx...>> {
    char Value[sizeof...(Idx) + 1];
    const char* cached = nullptr;
    
    constexpr ALWAYS_INLINE vxCplEncryptedString(const char* const Str) 
        : Value{ vxCplEncryptChar(Str[Idx], Idx)... } {}
    
    __attribute__((always_inline))
    inline const char* get() {
        if (cached) return cached;
        for (uintptr_t t = 0; t < sizeof...(Idx); t++) {
            Value[t] = Value[t] ^ (char)(vxCplEncryptCharKey + t);
        }
        Value[sizeof...(Idx)] = '\0';
        cached = Value;
        return cached;
    }
};

#define ENCRYPT(str) \
    ([]() -> const char* { \
        static vxCplEncryptedString<vxCplIndexes<sizeof(str) - 1>::Result> enc(str); \
        return enc.get(); \
    }())

#ifdef __APPLE__
#define NSSENCRYPT(Str) @(ENCRYPT(Str))
#endif