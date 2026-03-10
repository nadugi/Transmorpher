#pragma once
#include <windows.h>
#include <cstdint>
#include "WoWOffsets.h"

// Note: WowObject struct is defined in WoWOffsets.h now

void* GetLuaState();
uint64_t GetPlayerGuid();
WowObject* GetPlayer();
WowObject* GetObjectPtr(uint64_t guid, uint32_t typemask, const char* file, uint32_t line);

// Lua functions
typedef int  (__cdecl* FrameScript_Execute_fn)(const char*, const char*, int);
extern FrameScript_Execute_fn FrameScript_Execute;

typedef void (__cdecl* lua_getfield_fn)(void* L, int idx, const char* k);
extern lua_getfield_fn wow_lua_getfield;

typedef const char* (__cdecl* lua_tolstring_fn)(void* L, int idx, size_t* len);
extern lua_tolstring_fn wow_lua_tolstring;

typedef void (__cdecl* lua_settop_fn)(void* L, int idx);
extern lua_settop_fn wow_lua_settop;

// Update Display Info
typedef void(__thiscall* UpdateDisplayInfo_fn)(void* thisPtr, uint32_t unk);
extern UpdateDisplayInfo_fn CGUnit_UpdateDisplayInfo;

#define LUA_GLOBALSINDEX (-10002)

uint32_t ReadVisibleEnchant(WowObject* unit, int slot);
bool WriteVisibleEnchant(WowObject* unit, int slot, uint32_t enchantId);

bool IsRaceDisplayID(uint32_t displayId);

// Title Helpers
bool IsTitleKnown(WowObject* player, uint32_t titleId);
void SetTitleKnown(WowObject* player, uint32_t titleId, bool known);

// Object Iteration
typedef void(*GuardianCallback)(WowObject* unit, uint8_t* desc, void* ctx);
void ForEachPlayerGuardian(uint64_t playerGuid, GuardianCallback cb, void* ctx);

bool PatternScan(DWORD start, DWORD size, const char* pattern, const char* mask, DWORD* result);
DWORD FindDescriptorWriteHook(DWORD base);
DWORD FindUpdateDisplayInfoHook(DWORD base);

void ScanOffsets();
bool IsInWorld();
