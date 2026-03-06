// unified dinput8.dll proxy & stealth morpher v4
// Uses window subclassing to execute on WoW's main thread
// NO hooks on game functions, NO memory patches, NO registered Lua functions
//
// v4 changes:
// - DLL-side morph state tracking for automatic single-shot restoration
// - Detects displayId / weapon field changes and restores ONCE per tick
// - No burst loops, no repeated restore attempts — pure descriptor guard
// - Weapon persistence across sheathe/unsheathe/combat/swap
// - Shapeshift / Deathbringer's Will suspend/resume via addon signals

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <atomic>

extern "C" {
    FARPROC p[17] = {0};
}

void SetupProxy();

// ================================================================
// Logging
// ================================================================
static void Log(const char* fmt, ...) {
    /* Logging disabled for release
    FILE* f;
    if (fopen_s(&f, "Transmorpher.log", "a") == 0) {
        SYSTEMTIME st;
        GetLocalTime(&st);
        fprintf(f, "[%02d:%02d:%02d.%03d] ", st.wHour, st.wMinute, st.wSecond, st.wMilliseconds);
        va_list args;
        va_start(args, fmt);
        vfprintf(f, fmt, args);
        va_end(args);
        fprintf(f, "\n");
        fclose(f);
    }
    */
}

// ================================================================
// WoW Known Offsets (3.3.5a 12340)
// ================================================================
typedef void* (__cdecl* GetLuaState_fn)();
static auto GetLuaState = (GetLuaState_fn)0x00817DB0;

// FrameScript_ExecuteBuffer(code, filename, unused)
typedef int  (__cdecl* FrameScript_Execute_fn)(const char*, const char*, int);
static auto FrameScript_Execute = (FrameScript_Execute_fn)0x00819210;

// Lua 5.1 C API functions (embedded in Wow.exe)
typedef void (__cdecl* lua_getfield_fn)(void* L, int idx, const char* k);
static auto wow_lua_getfield = (lua_getfield_fn)0x0084E590;

typedef const char* (__cdecl* lua_tolstring_fn)(void* L, int idx, size_t* len);
static auto wow_lua_tolstring = (lua_tolstring_fn)0x0084E0E0;

typedef void (__cdecl* lua_settop_fn)(void* L, int idx);
static auto wow_lua_settop = (lua_settop_fn)0x0084DBF0;

#define LUA_GLOBALSINDEX (-10002)

// Object Manager
enum { TYPEMASK_PLAYER = 0x0010 };
static const uint32_t UNIT_FIELD_DISPLAYID       = 0x43 * 4;
static const uint32_t UNIT_FIELD_NATIVEDISPLAYID = 0x44 * 4;

static uint32_t GetVisibleItemField(int slot) {
    if (slot < 1 || slot > 19) return 0;
    return (0x11B + (slot - 1) * 2) * 4;
}

struct WowObject {
    uint32_t vtable;
    uint32_t unk04;
    uint32_t* descriptors;
};

typedef WowObject* (__cdecl* GetObjectPtr_fn)(uint64_t guid, uint32_t typemask, const char* file, uint32_t line);
static auto GetObjectPtr = (GetObjectPtr_fn)0x004D4DB0;

typedef void(__thiscall* UpdateDisplayInfo_fn)(void* thisPtr, uint32_t unk);
static auto CGUnit_UpdateDisplayInfo = (UpdateDisplayInfo_fn)0x0073E410;

static uint64_t GetPlayerGuid() {
    __try {
        uint32_t clientConnection = *(uint32_t*)0x00C79CE0;
        if (clientConnection) {
            uint32_t objectManager = *(uint32_t*)(clientConnection + 0x2ED0);
            if (objectManager) {
                return *(uint64_t*)(objectManager + 0xC0);
            }
        }
    } __except(EXCEPTION_EXECUTE_HANDLER) {}
    return 0;
}

static WowObject* GetPlayer() {
    __try {
        uint64_t guid = GetPlayerGuid();
        if (!guid) return nullptr;
        WowObject* o = (WowObject*)GetObjectPtr(guid, TYPEMASK_PLAYER, "", 0);
        if (o && o->descriptors) return o;
    } __except(EXCEPTION_EXECUTE_HANDLER) {}
    return nullptr;
}

// ================================================================
// Morph State Tracking (DLL-side)
// ================================================================

// Original values saved from the player's real data (before any morph)
static uint32_t g_origDisplay = 0;
static uint32_t g_origItems[20] = {0};
static float g_origScale = 1.0f;
static bool g_saved = false;

// Active morph state — what the addon has requested
// 0 means "no morph for this field, use native value"
static uint32_t g_morphDisplay = 0;
static uint32_t g_morphItems[20] = {0};
static float g_morphScale = 0.0f;
static bool g_hasMorph = false;

// Suspension: true when addon signals a model-changing form is active
static bool g_suspended = false;

// Weapon refresh: after weapon morphs, force extra visual updates for
// a few ticks to ensure the render pipeline picks up our values.
// Counts down from 3 to 0. While > 0, each tick re-stamps + updates.
static int g_weaponRefreshTicks = 0;

// ================================================================
// Helper: Recompute g_hasMorph
// ================================================================
static void UpdateHasMorph() {
    g_hasMorph = false;
    if (g_morphDisplay > 0) { g_hasMorph = true; return; }
    if (g_morphScale > 0.0f) { g_hasMorph = true; return; }
    for (int s = 1; s <= 19; s++) {
        if (g_morphItems[s] > 0) { g_hasMorph = true; return; }
    }
}

// ================================================================
// Save originals (once, on first morph)
// ================================================================
static void SaveOriginals(WowObject* p) {
    if (!p || !p->descriptors || g_saved) return;
    uint8_t* desc = (uint8_t*)p->descriptors;
    g_origDisplay = *(uint32_t*)(desc + UNIT_FIELD_DISPLAYID);
    g_origScale = *(float*)(desc + 0x10);
    for (int s = 1; s <= 19; s++) {
        uint32_t off = GetVisibleItemField(s);
        if (off) g_origItems[s] = *(uint32_t*)(desc + off);
    }
    g_saved = true;
    Log("Originals saved (display=%u, scale=%.2f)", g_origDisplay, g_origScale);
}

// ================================================================
// Refresh originals for non-morphed slots
// Called periodically so that RESET works correctly after gear changes.
// Only updates slots that are NOT currently morphed.
// ================================================================
static void RefreshOriginals(WowObject* p) {
    if (!p || !p->descriptors || !g_saved) return;
    uint8_t* desc = (uint8_t*)p->descriptors;

    // Update native display ID if we're not morphing it
    if (g_morphDisplay == 0) {
        g_origDisplay = *(uint32_t*)(desc + UNIT_FIELD_DISPLAYID);
    }
    // Update scale if not morphed
    if (g_morphScale <= 0.0f) {
        g_origScale = *(float*)(desc + 0x10);
    }
    // Update item slots that aren't morphed
    for (int s = 1; s <= 19; s++) {
        if (g_morphItems[s] == 0) {
            uint32_t off = GetVisibleItemField(s);
            if (off) g_origItems[s] = *(uint32_t*)(desc + off);
        }
    }
}

// ================================================================
// Re-stamp weapon descriptors after UpdateDisplayInfo
// UpdateDisplayInfo may internally overwrite weapon visible item
// fields from the real inventory. We re-write our morphed values
// immediately so the render pipeline (which reads descriptors
// asynchronously) sees our values, not the real ones.
// ================================================================
static void ReStampWeapons(WowObject* player) {
    if (!player || !player->descriptors) return;
    uint8_t* desc = (uint8_t*)player->descriptors;
    for (int s = 16; s <= 18; s++) {
        if (g_morphItems[s] > 0) {
            uint32_t off = GetVisibleItemField(s);
            if (off) {
                *(uint32_t*)(desc + off) = g_morphItems[s];
            }
        }
    }
}

// ================================================================
// Apply all active morphs to descriptors
// Returns true if any descriptor was actually changed
// ================================================================
static bool ApplyMorphState(WowObject* player) {
    if (!player || !player->descriptors) return false;
    uint8_t* desc = (uint8_t*)player->descriptors;
    bool changed = false;

    if (g_morphDisplay > 0) {
        uint32_t current = *(uint32_t*)(desc + UNIT_FIELD_DISPLAYID);
        if (current != g_morphDisplay) {
            *(uint32_t*)(desc + UNIT_FIELD_DISPLAYID) = g_morphDisplay;
            changed = true;
        }
    }

    if (g_morphScale > 0.0f) {
        float current = *(float*)(desc + 0x10);
        if (current < g_morphScale - 0.001f || current > g_morphScale + 0.001f) {
            *(float*)(desc + 0x10) = g_morphScale;
            changed = true;
        }
    }

    for (int s = 1; s <= 19; s++) {
        if (g_morphItems[s] > 0) {
            uint32_t off = GetVisibleItemField(s);
            if (off) {
                uint32_t current = *(uint32_t*)(desc + off);
                if (current != g_morphItems[s]) {
                    *(uint32_t*)(desc + off) = g_morphItems[s];
                    changed = true;
                }
            }
        }
    }

    return changed;
}

// ================================================================
// Process a single command from the addon
// ================================================================
static bool DoMorph(const char* cmd, WowObject* player) {
    if (!player) { Log("No player object"); return false; }
    SaveOriginals(player);

    uint8_t* desc = (uint8_t*)player->descriptors;
    bool update = false;

    if (strncmp(cmd, "MORPH:", 6) == 0) {
        uint32_t id = (uint32_t)atoi(cmd + 6);
        if (id > 0) {
            *(uint32_t*)(desc + UNIT_FIELD_DISPLAYID) = id;
            g_morphDisplay = id;
            update = true;
            Log("Morphed displayId=%u", id);
        }
    }
    else if (strncmp(cmd, "SCALE:", 6) == 0) {
        float scale = (float)atof(cmd + 6);
        if (scale > 0.05f && scale <= 20.0f) {
            *(float*)(desc + 0x10) = scale;
            g_morphScale = scale;
            update = true;
            Log("Scaled to %.2f", scale);
        }
    }
    else if (strncmp(cmd, "ITEM:", 5) == 0) {
        int slot = 0; uint32_t itemId = 0;
        sscanf_s(cmd + 5, "%d:%u", &slot, &itemId);
        if (slot >= 1 && slot <= 19) {
            uint32_t off = GetVisibleItemField(slot);
            if (off) {
                *(uint32_t*)(desc + off) = itemId;
                g_morphItems[slot] = itemId;
                update = true;
                Log("Set slot %d = item %u", slot, itemId);
                // Weapon slots need extra refresh ticks because
                // UpdateDisplayInfo may overwrite weapon descriptors
                if (slot >= 16 && slot <= 18) {
                    g_weaponRefreshTicks = 5;
                }
            }
        }
    }
    else if (strncmp(cmd, "SUSPEND", 7) == 0) {
        // Addon signals: model-changing form active, stop overriding
        g_suspended = true;
        Log("Morph suspended (shapeshift/proc)");
        return false;
    }
    else if (strncmp(cmd, "RESUME", 6) == 0) {
        // Addon signals: form ended, restore morphs once
        g_suspended = false;
        Log("Morph resumed — restoring");
        if (g_hasMorph) {
            bool changed = ApplyMorphState(player);
            if (changed) {
                __try { CGUnit_UpdateDisplayInfo(player, 1); }
                __except(EXCEPTION_EXECUTE_HANDLER) {}
                ReStampWeapons(player);
                g_weaponRefreshTicks = 5;
            }
        }
        return false; // Already handled visual update
    }
    else if (strncmp(cmd, "RESET:ALL", 9) == 0 && g_saved) {
        *(uint32_t*)(desc + UNIT_FIELD_DISPLAYID) = g_origDisplay;
        *(float*)(desc + 0x10) = g_origScale;
        for (int s = 1; s <= 19; s++) {
            uint32_t off = GetVisibleItemField(s);
            if (off) *(uint32_t*)(desc + off) = g_origItems[s];
        }
        // Clear all morph state
        g_morphDisplay = 0;
        g_morphScale = 0.0f;
        memset(g_morphItems, 0, sizeof(g_morphItems));
        g_hasMorph = false;
        g_suspended = false;
        update = true;
        Log("Reset all");
    }
    else if (strncmp(cmd, "RESET:", 6) == 0 && g_saved) {
        int slot = atoi(cmd + 6);
        if (slot >= 1 && slot <= 19) {
            uint32_t off = GetVisibleItemField(slot);
            if (off) {
                *(uint32_t*)(desc + off) = g_origItems[slot];
                g_morphItems[slot] = 0;
                update = true;
                Log("Reset slot %d", slot);
            }
        }
    }

    UpdateHasMorph();
    return update;
}

// ================================================================
// Morph Guard — automatic single-shot restoration
// Runs every tick. Detects when the game has overwritten our morphed
// descriptors (shapeshift end, trinket proc end, equipment swap,
// weapon sheathe/unsheathe) and restores them ONCE.
// No loops, no burst frames, no repeated attempts.
// ================================================================
static void MorphGuard(WowObject* player) {
    if (!player || !player->descriptors) return;
    if (!g_hasMorph) return;
    if (g_suspended) return;

    uint8_t* desc = (uint8_t*)player->descriptors;
    bool needsRestore = false;

    // Check display ID
    if (g_morphDisplay > 0) {
        uint32_t cur = *(uint32_t*)(desc + UNIT_FIELD_DISPLAYID);
        if (cur != g_morphDisplay) {
            needsRestore = true;
        }
    }

    // Check item slots (weapons, armor — all persistent)
    if (!needsRestore) {
        for (int s = 1; s <= 19; s++) {
            if (g_morphItems[s] > 0) {
                uint32_t off = GetVisibleItemField(s);
                if (off) {
                    uint32_t cur = *(uint32_t*)(desc + off);
                    if (cur != g_morphItems[s]) {
                        needsRestore = true;
                        break;
                    }
                }
            }
        }
    }

    // Check scale
    if (!needsRestore && g_morphScale > 0.0f) {
        float cur = *(float*)(desc + 0x10);
        if (cur < g_morphScale - 0.001f || cur > g_morphScale + 0.001f) {
            needsRestore = true;
        }
    }

    // Single-shot restore: write all morph values back & update once
    if (needsRestore) {
        bool changed = ApplyMorphState(player);
        if (changed) {
            __try {
                CGUnit_UpdateDisplayInfo(player, 1);
            } __except(EXCEPTION_EXECUTE_HANDLER) {
                Log("Guard: UpdateDisplayInfo exception");
            }
            // Re-stamp weapons immediately — UpdateDisplayInfo may have
            // overwritten weapon descriptors from real inventory
            ReStampWeapons(player);
            Log("Guard: Restored morph (single-shot)");
        }
    }
}

// ================================================================
// Timer callback — runs on WoW's main thread every 20ms
// ================================================================
static WNDPROC g_origWndProc = nullptr;
static HWND    g_wowHwnd = nullptr;
static UINT_PTR MORPH_TIMER_ID = 0xDEAD;

static VOID CALLBACK MorphTimerProc(HWND hwnd, UINT uMsg, UINT_PTR idEvent, DWORD dwTime) {
    __try {
        WowObject* player = GetPlayer();

        // --- Phase 1: Process addon commands from Lua global ---
        void* L = GetLuaState();
        if (L) {
            wow_lua_getfield(L, LUA_GLOBALSINDEX, "TRANSMORPHER_CMD");
            size_t len = 0;
            const char* val = wow_lua_tolstring(L, -1, &len);
            wow_lua_settop(L, -2);

            if (val && len > 0) {
                char buffer[4096];
                strncpy_s(buffer, sizeof(buffer), val, _TRUNCATE);
                FrameScript_Execute("TRANSMORPHER_CMD = ''", "Transmorpher", 0);

                char* next_token = nullptr;
                char* token = strtok_s(buffer, "|", &next_token);
                bool needsVisualUpdate = false;

                while (token) {
                    if (DoMorph(token, player)) {
                        needsVisualUpdate = true;
                    }
                    token = strtok_s(nullptr, "|", &next_token);
                }

                if (needsVisualUpdate && player) {
                    __try {
                        CGUnit_UpdateDisplayInfo(player, 1);
                    } __except(EXCEPTION_EXECUTE_HANDLER) {
                        Log("UpdateDisplayInfo exception");
                    }
                    // Re-stamp weapons after UpdateDisplayInfo
                    ReStampWeapons(player);
                }
            }
        }

        // --- Phase 2: Morph Guard — detect & restore external changes ---
        if (player) {
            SaveOriginals(player);
            RefreshOriginals(player);
            MorphGuard(player);
        }

        // --- Phase 3: Weapon refresh — extra update ticks after weapon morphs ---
        // Forces the render pipeline to pick up weapon changes that
        // UpdateDisplayInfo may have clobbered.
        if (player && g_weaponRefreshTicks > 0 && !g_suspended) {
            g_weaponRefreshTicks--;
            ApplyMorphState(player);
            __try {
                CGUnit_UpdateDisplayInfo(player, 1);
            } __except(EXCEPTION_EXECUTE_HANDLER) {}
            ReStampWeapons(player);
        }

    } __except(EXCEPTION_EXECUTE_HANDLER) {
        Log("Exception in MorphTimerProc");
    }
}

// ================================================================
// Background thread — finds WoW's window and installs timer
// ================================================================
static std::atomic<bool> g_running{true};

static DWORD WINAPI StealthThread(LPVOID lpParam) {
    SetupProxy();
    Log("Stealth thread started. Waiting for WoW window...");
    Sleep(8000);

    // Find WoW's main window
    while (g_running) {
        g_wowHwnd = FindWindowA("GxWindowClass", NULL);
        if (g_wowHwnd) break;
        g_wowHwnd = FindWindowA("GxWindowClassD3d", NULL);
        if (g_wowHwnd) break;
        Sleep(1000);
    }

    if (!g_wowHwnd) {
        Log("Could not find WoW window!");
        return 0;
    }
    Log("Found WoW window: 0x%p", g_wowHwnd);

    // Install a timer on WoW's main thread — fires every 20ms
    // SetTimer with a callback ensures it runs on the window's thread
    SetTimer(g_wowHwnd, MORPH_TIMER_ID, 20, MorphTimerProc);
    Log("Timer installed. Morpher active!");

    // Keep thread alive
    while (g_running) {
        Sleep(1000);
    }

    KillTimer(g_wowHwnd, MORPH_TIMER_ID);
    return 0;
}

// ================================================================
// dinput8.dll proxy
// ================================================================
void SetupProxy() {
    char sysDir[MAX_PATH];
    GetSystemDirectoryA(sysDir, MAX_PATH);
    strcat_s(sysDir, "\\dinput8.dll");

    HMODULE hMod = LoadLibraryA(sysDir);
    if (!hMod) return;

    p[0] = GetProcAddress(hMod, "DirectInput8Create");
    p[1] = GetProcAddress(hMod, "GetdfDIJoystick");
    p[2] = GetProcAddress(hMod, "GetdfDIKeyboard");
    p[3] = GetProcAddress(hMod, "GetdfDIMouse");
    p[4] = GetProcAddress(hMod, "GetdfDIMouse2");
}

BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved) {
    switch (ul_reason_for_call) {
    case DLL_PROCESS_ATTACH: {
        DisableThreadLibraryCalls(hModule);
        CreateThread(nullptr, 0, StealthThread, nullptr, 0, nullptr);
        break;
    }
    case DLL_PROCESS_DETACH:
        g_running = false;
        if (g_wowHwnd) KillTimer(g_wowHwnd, MORPH_TIMER_ID);
        break;
    }
    return TRUE;
}
