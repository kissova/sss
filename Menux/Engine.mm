#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#include <cstdint>
#include <cstring>
#include <vector>
#include <mutex>
#include <mach/vm_map.h>
extern "C" kern_return_t mach_vm_region(vm_map_t target_task, mach_vm_address_t *address, mach_vm_size_t *size, vm_region_flavor_t flavor, vm_region_info_t info, mach_msg_type_number_t *infoCnt, mach_port_t *object_name);


// Dobby / hook başlığını öz layihənə uyğun qoş:
// #include "Dobby/dobby.h"

namespace Engine {

struct Vec2 {
    float x = 0.0f;
    float y = 0.0f;
};

struct Vec3 {
    float x = 0.0f;
    float y = 0.0f;
    float z = 0.0f;
};

struct PlayerESP {
    bool valid = false;
    bool isBot = false;
    bool isVisible = false;
    int teamId = 0;
    float health = 0.0f;
    float maxHealth = 100.0f;
    float distance = 0.0f;
    Vec3 worldPos{};
    Vec2 screenPos{};
};

struct Config {
    bool enableESP = true;
    bool drawBox = true;
    bool drawLine = true;
    bool drawHealth = true;
    bool drawDistance = true;
    bool drawRadar = true;
    float maxDistance = 400.0f;
};

static Config g_Config;
static std::mutex g_DataMutex;
static std::vector<PlayerESP> g_Players;
static uintptr_t g_BaseAddr = 0;

// Ünvanın oxunaqlı olub-olmadığını yoxlayır (SIGSEGV / crash qarşısını alır)
static bool IsValidPtr(uintptr_t addr) {
    if (addr < 0x100000000ULL || addr > 0x2000000000ULL) {
        return false;
    }
    vm_size_t size = 0;
#if defined(__LP64__)
    mach_vm_address_t address = static_cast<mach_vm_address_t>(addr);
    mach_vm_size_t vmsize = 0;
    mach_msg_type_number_t count = VM_REGION_BASIC_INFO_COUNT_64;
    vm_region_basic_info_data_64_t info;
    mach_port_t object_name = MACH_PORT_NULL;
    kern_return_t kr = mach_vm_region(mach_task_self(), &address, &vmsize,
                                      VM_REGION_BASIC_INFO_64,
                                      reinterpret_cast<vm_region_info_t>(&info),
                                      &count, &object_name);
    size = static_cast<vm_size_t>(vmsize);
    if (kr != KERN_SUCCESS || size == 0) {
        return false;
    }
    return (info.protection & VM_PROT_READ) != 0;
#else
    return false;
#endif
}

template <typename T>
static bool SafeRead(uintptr_t addr, T &outValue) {
    if (!IsValidPtr(addr) || !IsValidPtr(addr + sizeof(T) - 1)) {
        return false;
    }
    std::memcpy(&outValue, reinterpret_cast<const void *>(addr), sizeof(T));
    return true;
}

static uintptr_t GetImageBase(const char *imageName = nullptr) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (!name) continue;
        if (!imageName) {
            return reinterpret_cast<uintptr_t>(_dyld_get_image_header(i));
        }
        if (std::strstr(name, imageName) != nullptr) {
            return reinterpret_cast<uintptr_t>(_dyld_get_image_header(i));
        }
    }
    return 0;
}

static inline uintptr_t RealOffset(uintptr_t offset) {
    if (g_BaseAddr == 0) {
        g_BaseAddr = GetImageBase(nullptr);
    }
    if (g_BaseAddr == 0 || offset == 0) {
        return 0;
    }
    return g_BaseAddr + offset;
}

static bool WorldToScreen(const Vec3 &world, Vec2 &outScreen, const float *matrix, int screenW, int screenH) {
    if (!matrix || screenW <= 0 || screenH <= 0) {
        return false;
    }

    float clipW = world.x * matrix[3] + world.y * matrix[7] + world.z * matrix[11] + matrix[15];
    if (clipW < 0.01f) {
        return false;
    }

    float clipX = world.x * matrix[0] + world.y * matrix[4] + world.z * matrix[8] + matrix[12];
    float clipY = world.x * matrix[1] + world.y * matrix[5] + world.z * matrix[9] + matrix[13];

    float ndcX = clipX / clipW;
    float ndcY = clipY / clipW;

    outScreen.x = (screenW * 0.5f) * (ndcX + 1.0f);
    outScreen.y = (screenH * 0.5f) * (1.0f - ndcY);

    return (outScreen.x >= -200.0f && outScreen.x <= screenW + 200.0f &&
            outScreen.y >= -200.0f && outScreen.y <= screenH + 200.0f);
}

// Oyun dövründən təhlükəsiz məlumat toplama nümunəsi
static void UpdateESPData(uintptr_t gWorldAddr, const float *vpMatrix, int screenW, int screenH) {
    std::vector<PlayerESP> tempList;

    uintptr_t worldPtr = 0;
    if (!SafeRead<uintptr_t>(gWorldAddr, worldPtr) || worldPtr == 0) {
        std::lock_guard<std::mutex> lock(g_DataMutex);
        g_Players.swap(tempList);
        return;
    }

    // Nümunə: entity list və sayğac oxunuşu (öz offset-lərinlə əvəz et)
    uintptr_t actorArray = 0;
    int32_t actorCount = 0;
    if (!SafeRead<uintptr_t>(worldPtr + 0xA0, actorArray) ||
        !SafeRead<int32_t>(worldPtr + 0xA8, actorCount)) {
        std::lock_guard<std::mutex> lock(g_DataMutex);
        g_Players.swap(tempList);
        return;
    }

    // Həddindən artıq böyük və ya mənfi sayğaclarda crash olmaması üçün limit
    if (actorCount <= 0 || actorCount > 2048) {
        std::lock_guard<std::mutex> lock(g_DataMutex);
        g_Players.swap(tempList);
        return;
    }

    tempList.reserve(static_cast<size_t>(actorCount));

    for (int32_t i = 0; i < actorCount; i++) {
        uintptr_t actor = 0;
        uintptr_t entryAddr = actorArray + static_cast<uintptr_t>(i) * sizeof(uintptr_t);
        if (!SafeRead<uintptr_t>(entryAddr, actor) || actor == 0) {
            continue;
        }

        float hp = 0.0f;
        Vec3 pos{};
        if (!SafeRead<float>(actor + 0x100, hp) || hp <= 0.0f) {
            continue;
        }
        if (!SafeRead<Vec3>(actor + 0x140, pos)) {
            continue;
        }

        Vec2 scr{};
        if (!WorldToScreen(pos, scr, vpMatrix, screenW, screenH)) {
            continue;
        }

        PlayerESP p;
        p.valid = true;
        p.health = hp;
        p.worldPos = pos;
        p.screenPos = scr;
        tempList.push_back(p);
    }

    std::lock_guard<std::mutex> lock(g_DataMutex);
    g_Players.swap(tempList);
}

// Hook quraşdırma helperi (null və dublikat yoxlaması ilə)
template <typename Fn>
static bool InstallHook(uintptr_t targetOffset, Fn hookFn, Fn *origFn) {
    uintptr_t addr = RealOffset(targetOffset);
    if (addr == 0 || !IsValidPtr(addr)) {
        return false;
    }
    // DobbyHook(reinterpret_cast<void *>(addr), reinterpret_cast<void *>(hookFn), reinterpret_cast<void **>(origFn));
    (void)hookFn;
    (void)origFn;
    return true;
}

static void Init() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_BaseAddr = GetImageBase(nullptr);
        // Lazımi hook-ları buraya əlavə et:
        // InstallHook(0x123456, myHook, &origFn);
    });
}

} // namespace Engine

__attribute__((constructor))
static void EngineEntry() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        Engine::Init();
    });
}
