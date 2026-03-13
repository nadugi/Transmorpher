#include <windows.h>
#include <cstdio>
#include <atomic>
#include "Logger.h"
#include "Proxy.h"
#include "Hooks.h"
#include "Morpher.h"
#include "Utils.h"
#include "WoWOffsets.h"

// ================================================================
// Timer & Threading
// ================================================================
static std::atomic<bool> g_running{true};
static HWND    g_wowHwnd = nullptr;
static UINT_PTR MORPH_TIMER_ID = 0xDEAD;
static uint64_t g_lastPlayerGuid = 0;

static bool g_luaLoadedSent = false;
static bool g_wasInWorld = false;
static int  g_worldStabilityTicks = 0;

static VOID CALLBACK MorphTimerProc(HWND hwnd, UINT uMsg, UINT_PTR idEvent, DWORD dwTime) {
    if (!g_running) return;
    if (!g_wowHwnd) return;
    
    // Only run if we are in World
    if (!IsInWorld()) {
        g_luaLoadedSent = false; 
        g_worldStabilityTicks = 0;
        if (g_wasInWorld) {
            Log("Left world (Teleport/Reload/Logout) - Force clearing state");
            ResetAllMorphs(true); // forceClearOnly = true
            extern DWORD g_playerDescBase;
            g_playerDescBase = 0; // Invalidate descriptor base immediately
            g_wasInWorld = false;
        }
        return;
    }

    __try {
        WowObject* player = GetPlayer();

        // Debug logging for display ID writes
        extern uint32_t g_debugLastDisplayID;
        static uint32_t s_lastLoggedID = 0;
        if (g_debugLastDisplayID != 0 && g_debugLastDisplayID != s_lastLoggedID) {
            Log("Game attempted to write DisplayID: %u", g_debugLastDisplayID);
            s_lastLoggedID = g_debugLastDisplayID;
        }

        // Character change detection
        uint64_t currentGuid = GetPlayerGuid();
        
        // Only run morph logic if we have a valid player and GUID
        if (currentGuid != 0 && player && player->descriptors) {
            if (currentGuid != g_lastPlayerGuid) {
                if (g_lastPlayerGuid != 0) {
                    Log("Character change detected, clearing morph state");
                    ResetAllMorphs(true); // forceClearOnly = true
                }
                g_lastPlayerGuid = currentGuid;
            }
        } else {
            // Player is not valid (loading screen, logging out, etc.)
            // Do NOT reset morphs here, just skip logic
            return;
        }

        // UPDATE PLAYER BASE
        if (player && player->descriptors) {
            extern DWORD g_playerDescBase;
            g_playerDescBase = (DWORD)(uintptr_t)player->descriptors;
        }

        // Debounce IsInWorld flicker ONLY for Lua calls (prevents "beeps")
        bool stable = false;
        if (!g_wasInWorld) {
            g_worldStabilityTicks++;
            if (g_worldStabilityTicks >= 1) {
                Log("Entered world (Login/Teleport/Reload complete)");
                ResetAllMorphs(true); // Reset login/TP grace period and state
                g_wasInWorld = true;
                stable = true;
            }
        } else {
            stable = true;
        }

        // Run MorphGuard handles local player, RemoteMorphGuard handles others
        if (player) {
            MorphGuard(player);
        }
        RemoteMorphGuard();

        // Only process Lua commands and initialization if stable
        if (stable) {
            void* L = GetLuaState();
            if (L) {
                // Check if we need to initialize (Reload detection)
                bool needInit = false;
                if (wow_lua_getfield && wow_lua_tolstring && wow_lua_settop) {
                    wow_lua_getfield(L, LUA_GLOBALSINDEX, "TRANSMORPHER_DLL_LOADED");
                    size_t len = 0;
                    const char* val = wow_lua_tolstring(L, -1, &len);
                    // If it's nil/false or not "TRUE", we need to re-init
                    if (!val || strcmp(val, "TRUE") != 0) {
                        needInit = true;
                    }
                    wow_lua_settop(L, -2); // Pop the value
                } else if (!g_luaLoadedSent) {
                    // Fallback if Lua functions missing (shouldn't happen)
                    needInit = true;
                }

                if (FrameScript_Execute && needInit) {
                    FrameScript_Execute("TRANSMORPHER_DLL_LOADED = 'TRUE'", "Transmorpher", 0);
                    FrameScript_Execute("if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage('|cffffff00StealthMorpher|r initialized. Features: |cff00ff00ACTIVE|r') end", "Transmorpher", 0);
                    g_luaLoadedSent = true;
                    Log("Sent DLL_LOADED flag and welcome message to Lua");
                }

                if (wow_lua_getfield && wow_lua_tolstring && wow_lua_settop) {
                    wow_lua_getfield(L, LUA_GLOBALSINDEX, "TRANSMORPHER_CMD");
                    size_t len = 0;
                    const char* val = wow_lua_tolstring(L, -1, &len);

                    if (val && len > 0) {
                        char buffer[4096];
                        strncpy_s(buffer, sizeof(buffer), val, _TRUNCATE);
                        wow_lua_settop(L, -2); // Pop string

                        if (FrameScript_Execute) {
                            FrameScript_Execute("TRANSMORPHER_CMD = ''", "Transmorpher", 0);
                        }

                        char* next_token = nullptr;
                        char* token = strtok_s(buffer, "|", &next_token);
                        bool needsVisualUpdate = false;

                        while (token) {
                            if (DoMorph(token, player)) needsVisualUpdate = true;
                            token = strtok_s(nullptr, "|", &next_token);
                        }

                        if (needsVisualUpdate && player) {
                            if (CGUnit_UpdateDisplayInfo) {
                                __try { CGUnit_UpdateDisplayInfo(player, 1); } __except(1) {}
                            }
                            ReStampWeapons(player);
                        }
                    } else {
                        wow_lua_settop(L, -2); // Pop nil/empty
                    }
                    
                    // Handle Logging from Lua
                    wow_lua_getfield(L, LUA_GLOBALSINDEX, "TRANSMORPHER_LOG");
                    size_t logLen = 0;
                    const char* logVal = wow_lua_tolstring(L, -1, &logLen);
                    if (logVal && logLen > 0) {
                        // We safely copy and log each line
                        char logBuffer[8192];
                        strncpy_s(logBuffer, sizeof(logBuffer), logVal, _TRUNCATE);
                        wow_lua_settop(L, -2); // pop string
                        
                        if (FrameScript_Execute) {
                            FrameScript_Execute("TRANSMORPHER_LOG = ''", "Transmorpher", 0);
                        }
                        
                        char* next_log_token = nullptr;
                        char* log_token = strtok_s(logBuffer, "\n", &next_log_token);
                        while (log_token) {
                            if (strlen(log_token) > 0) {
                                Log("[Lua] %s", log_token);
                            }
                            log_token = strtok_s(nullptr, "\n", &next_log_token);
                        }
                    } else {
                        wow_lua_settop(L, -2); // pop nil/empty
                    }
                    
                    // Periodically export nearby players (every 1 second = 20 ticks of 50ms)
                    static int s_nearbyPlayerTicks = 0;
                    s_nearbyPlayerTicks++;
                    if (s_nearbyPlayerTicks >= 20) {
                        s_nearbyPlayerTicks = 0;
                        if (g_lastPlayerGuid != 0) {
                            char nearby[4096] = {0};
                            GetNearbyPlayers(g_lastPlayerGuid, nearby, sizeof(nearby));
                            char luaCmd[4096];
                            sprintf_s(luaCmd, sizeof(luaCmd), "TRANSMORPHER_NEARBY = \"%s\"", nearby);
                            if (FrameScript_Execute) {
                                __try {
                                    FrameScript_Execute(luaCmd, "Transmorpher", 0);
                                } __except(1) {}
                            }
                        }
                    }
                }
            }
        }
    } __except(EXCEPTION_EXECUTE_HANDLER) {
        Log("Exception in MorphTimerProc");
    }
}

static DWORD WINAPI StealthThread(LPVOID lpParam) {
    Log("Stealth thread started. Waiting for WoW window...");
    Sleep(8000);

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

    // Initialize offsets via pattern scanning
    ScanOffsets();

    if (InstallMountHook()) {
        Log("Mount display hook installed successfully");
    } else {
        Log("WARNING: Failed to install mount display hook!");
    }

    if (InstallUpdateDisplayInfoHook()) {
        Log("UpdateDisplayInfo hook installed successfully");
    } else {
        Log("WARNING: Failed to install UpdateDisplayInfo hook!");
    }

    // Install Timer on Main Thread (Fast 50ms interval for smooth visual updates)
    SetTimer(g_wowHwnd, MORPH_TIMER_ID, 50, MorphTimerProc);
    Log("Timer installed. Morpher active!");
    
    while (g_running) {
        Sleep(1000);
    }

    return 0;
}

BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved) {
    switch (ul_reason_for_call) {
    case DLL_PROCESS_ATTACH: {
        extern HMODULE g_hThisModule;
        g_hThisModule = hModule;
        DisableThreadLibraryCalls(hModule);
        SetupProxy();
        CreateThread(nullptr, 0, StealthThread, nullptr, 0, nullptr);
        break;
    }
    case DLL_PROCESS_DETACH:
        g_running = false;
        if (g_wowHwnd) {
            KillTimer(g_wowHwnd, MORPH_TIMER_ID);
            g_wowHwnd = nullptr;
        }
        UninstallMountHook();
        UninstallTimeHook();
        
        Sleep(50);
        
        // Clear all pointers to prevent access violations
        extern DWORD g_playerDescBase;
        g_playerDescBase = 0;
        
        Log("DLL detached cleanly");
        break;
    }
    return TRUE;
}

// Global HMODULE storage for Proxy
HMODULE g_hThisModule = nullptr;
