#include "Utils.h"
#include "WoWOffsets.h"
#include "Hooks.h"
#include "Logger.h"
#include <cstdio>
#include <vector>

// Define global function pointers
FrameScript_Execute_fn FrameScript_Execute = nullptr;
lua_getfield_fn wow_lua_getfield = nullptr;
lua_tolstring_fn wow_lua_tolstring = nullptr;
lua_settop_fn wow_lua_settop = nullptr;
UpdateDisplayInfo_fn CGUnit_UpdateDisplayInfo = nullptr;

// Internal helpers for object manager
typedef void* (__cdecl* GetLuaState_fn)();
static auto _GetLuaState = (GetLuaState_fn)0x00817DB0;

typedef WowObject* (__cdecl* GetObjectPtr_fn)(uint64_t guid, uint32_t typemask, const char* file, uint32_t line);
static auto _GetObjectPtr = (GetObjectPtr_fn)0x004D4DB0;

void* GetLuaState() {
    return _GetLuaState();
}

WowObject* GetObjectPtr(uint64_t guid, uint32_t typemask, const char* file, uint32_t line) {
    return _GetObjectPtr(guid, typemask, file, line);
}

// Memory scanning
bool PatternScan(DWORD start, DWORD size, const char* pattern, const char* mask, DWORD* result) {
    DWORD patternLen = strlen(mask);
    for (DWORD i = 0; i < size; i++) {
        bool found = true;
        for (DWORD j = 0; j < patternLen; j++) {
            if (mask[j] != '?' && pattern[j] != *(char*)(start + i + j)) {
                found = false;
                break;
            }
        }
        if (found) {
            *result = start + i;
            return true;
        }
    }
    return false;
}

DWORD FindDescriptorWriteHook(DWORD base) {
    // Looking for: 89 0C 90 (mov [eax+edx*4], ecx)
    // This is inside CGObject_C::SetDescriptor
    // Usually at base + 0x343BAC
    DWORD result = 0;
    if (PatternScan(base + 0x300000, 0x100000, "\x89\x0C\x90", "xxx", &result)) {
        return result;
    }
    return 0;
}

DWORD FindUpdateDisplayInfoHook(DWORD base) {
    // Looking for the start of CGUnit_UpdateDisplayInfo
    // Signature: 55 8B EC 81 EC 88 00 00 00 53 56 8B F1 8B 0D ? ? ? ? 57 8B
    DWORD result = 0;
    if (PatternScan(base + 0x300000, 0x100000, 
        "\x55\x8B\xEC\x81\xEC\x88\x00\x00\x00\x53\x56\x8B\xF1\x8B\x0D\x00\x00\x00\x00\x57\x8B", 
        "xxxxxxxxxxxxxxx????xx", &result)) {
        return result;
    }
    return 0;
}

uint64_t GetPlayerGuid() {
    __try {
        uint32_t clientConnection = *(uint32_t*)P_CLIENT_CONNECTION;
        if (clientConnection) {
            uint32_t objectManager = *(uint32_t*)(clientConnection + 0x2ED0);
            if (objectManager) {
                return *(uint64_t*)(objectManager + 0xC0);
            }
        }
    } __except(1) {}
    return 0;
}

WowObject* GetPlayer() {
    __try {
        uint32_t clientConnection = *(uint32_t*)P_CLIENT_CONNECTION;
        if (clientConnection) {
            uint32_t objectManager = *(uint32_t*)(clientConnection + 0x2ED0);
            if (objectManager) {
                uint32_t playerObj = *(uint32_t*)(objectManager + 0x24);
                if (playerObj) {
                    WowObject* player = (WowObject*)playerObj;
                    if (player->descriptors) return player;
                }
            }
        }
    } __except(1) {}

    // Fallback
    uint64_t guid = GetPlayerGuid();
    if (guid == 0) return nullptr;
    return GetObjectPtr(guid, 16, __FILE__, __LINE__);
}

uint32_t ReadVisibleEnchant(WowObject* unit, int slot) {
    if (!unit || !unit->descriptors) return 0;
    uint32_t field = GetVisibleEnchantField(slot);
    if (field == 0) return 0;
    return *(uint32_t*)((uint8_t*)unit->descriptors + field);
}

bool WriteVisibleEnchant(WowObject* unit, int slot, uint32_t enchantId) {
    if (!unit || !unit->descriptors) return false;
    uint32_t field = GetVisibleEnchantField(slot);
    if (field == 0) return false;
    
    uint32_t* ptr = (uint32_t*)((uint8_t*)unit->descriptors + field);
    if (*ptr != enchantId) {
        *ptr = enchantId;
        return true;
    }
    return false;
}

bool IsRaceDisplayID(uint32_t displayId) {
    // Verified working race display IDs
    if (displayId == 2222) return true; // Night Elf Female
    if (displayId == 4358) return true; // Troll Female
    if (displayId == 6785) return true; // Orc Male
    if (displayId == 13250) return true; // Dwarf Female
    if (displayId == 17155) return true; // Draenei Male
    if (displayId >= 19723 && displayId <= 19724) return true; // Human
    if (displayId >= 20316 && displayId <= 20318) return true; // Orc Female, Dwarf Male, Night Elf Male
    if (displayId == 20321) return true; // Troll Male
    if (displayId == 20323) return true; // Draenei Female
    if (displayId >= 20578 && displayId <= 20579) return true; // Blood Elf
    if (displayId >= 20580 && displayId <= 20581) return true; // Gnome
    if (displayId >= 20584 && displayId <= 20585) return true; // Tauren
    if (displayId == 23112) return true; // Undead Female
    if (displayId == 28193) return true; // Undead Male
    
    // Legacy naked base models
    if (displayId >= 49 && displayId <= 60) return true;
    if (displayId >= 1563 && displayId <= 1564) return true;
    if (displayId >= 1478 && displayId <= 1479) return true;
    if (displayId >= 15475 && displayId <= 15476) return true;
    if (displayId >= 16125 && displayId <= 16126) return true;
    
    return false;
}

// Title Helpers
bool IsTitleKnown(WowObject* player, uint32_t titleId) {
    if (!player || !player->descriptors || titleId == 0 || titleId > 180) return false;
    uint32_t* knownTitles = (uint32_t*)((uint8_t*)player->descriptors + PLAYER_FIELD_KNOWN_TITLES);
    int index = titleId / 32;
    int bit = titleId % 32;
    return (knownTitles[index] & (1 << bit)) != 0;
}

void SetTitleKnown(WowObject* player, uint32_t titleId, bool known) {
    if (!player || !player->descriptors || titleId == 0 || titleId > 180) return;
    uint32_t* knownTitles = (uint32_t*)((uint8_t*)player->descriptors + PLAYER_FIELD_KNOWN_TITLES);
    int index = titleId / 32;
    int bit = titleId % 32;
    if (known)
        knownTitles[index] |= (1 << bit);
    else
        knownTitles[index] &= ~(1 << bit);
}

void ForEachPlayerGuardian(uint64_t playerGuid, GuardianCallback cb, void* ctx) {
    __try {
        uint32_t clientConnection = *(uint32_t*)P_CLIENT_CONNECTION;
        if (!clientConnection) return;
        uint32_t objMgr = *(uint32_t*)(clientConnection + 0x2ED0);
        if (!objMgr) return;
        
        uint32_t objPtr = *(uint32_t*)(objMgr + 0xAC);
        while (objPtr != 0 && objPtr % 2 == 0) {
            WowObject* current = (WowObject*)objPtr;
            // Only process units (type 3), skip players (type 4)
            if (current->objType == 3 && current->descriptors) {
                uint8_t* desc = (uint8_t*)current->descriptors;
                uint64_t summonedBy = *(uint64_t*)(desc + UNIT_FIELD_SUMMONEDBY);
                uint64_t createdBy  = *(uint64_t*)(desc + UNIT_FIELD_CREATEDBY);
                
                if (summonedBy == playerGuid || createdBy == playerGuid) {
                    cb(current, desc, ctx);
                }
            }
            objPtr = (uint32_t)current->nextObject;
        }
    } __except(1) {}
}

bool IsInWorld() {
    __try {
        uint32_t clientConnection = *(uint32_t*)P_CLIENT_CONNECTION;
        if (clientConnection) {
            uint32_t objectManager = *(uint32_t*)(clientConnection + 0x2ED0);
            if (objectManager) {
                // If ObjectManager exists, we are likely in world
                // Double check by looking for local player
                uint64_t guid = *(uint64_t*)(objectManager + 0xC0);
                if (guid != 0) return true;
            }
        }
    } __except(1) {}
    return false;
}

void ScanOffsets() {
    DWORD base = (DWORD)GetModuleHandleA(NULL);
    if (!base) return;

    DWORD result = 0;

    // FrameScript_Execute
    // Signature: 55 8B EC 81 EC ? ? ? ? 53 8B 5D 08 56 57 85 DB 74
    if (PatternScan(base, 0x800000, 
        "\x55\x8B\xEC\x81\xEC\x00\x00\x00\x00\x53\x8B\x5D\x08\x56\x57\x85\xDB\x74", 
        "xxxxx????xxxxxxxxx", &result)) {
        FrameScript_Execute = (FrameScript_Execute_fn)result;
        Log("Found FrameScript_Execute at 0x%08X", result);
    } else {
        FrameScript_Execute = (FrameScript_Execute_fn)0x00819210;
        Log("FrameScript_Execute not found, using default 0x00819210");
    }

    // CGUnit_UpdateDisplayInfo
    // Signature: 55 8B EC 81 EC 88 00 00 00 53 56 8B F1 8B 0D ? ? ? ? 57 8B
    if (PatternScan(base, 0x800000, 
        "\x55\x8B\xEC\x81\xEC\x88\x00\x00\x00\x53\x56\x8B\xF1\x8B\x0D\x00\x00\x00\x00\x57\x8B", 
        "xxxxxxxxxxxxxxx????xx", &result)) {
        CGUnit_UpdateDisplayInfo = (UpdateDisplayInfo_fn)result;
        Log("Found CGUnit_UpdateDisplayInfo at 0x%08X", result);
    } else {
        CGUnit_UpdateDisplayInfo = (UpdateDisplayInfo_fn)0x0073E410;
        Log("CGUnit_UpdateDisplayInfo not found, using default 0x0073E410");
    }

    // lua_getfield
    // Signature: 55 8B EC 83 EC 10 53 56 8B 75 08 57 8B 7D 0C 85 F6
    if (PatternScan(base, 0x800000, 
        "\x55\x8B\xEC\x83\xEC\x10\x53\x56\x8B\x75\x08\x57\x8B\x7D\x0C\x85\xF6", 
        "xxxxxxxxxxxxxxxx", &result)) {
        wow_lua_getfield = (lua_getfield_fn)result;
        Log("Found lua_getfield at 0x%08X", result);
    } else {
        wow_lua_getfield = (lua_getfield_fn)0x0084E590;
        Log("lua_getfield not found, using default 0x0084E590");
    }

    // lua_tolstring
    // Signature: 55 8B EC 51 8B 45 0C 53 56 8B 75 08 57 85 C0 75 0C
    if (PatternScan(base, 0x800000, 
        "\x55\x8B\xEC\x51\x8B\x45\x0C\x53\x56\x8B\x75\x08\x57\x85\xC0\x75\x0C", 
        "xxxxxxxxxxxxxxxx", &result)) {
        wow_lua_tolstring = (lua_tolstring_fn)result;
        Log("Found lua_tolstring at 0x%08X", result);
    } else {
        wow_lua_tolstring = (lua_tolstring_fn)0x0084E0E0;
        Log("lua_tolstring not found, using default 0x0084E0E0");
    }

    // lua_settop
    // Signature: 55 8B EC 8B 45 0C 85 C0 78 12 8B 55 08 8B 0A 8D 14 C1 3B 52 08 76 1D
    if (PatternScan(base, 0x800000, 
        "\x55\x8B\xEC\x8B\x45\x0C\x85\xC0\x78\x12\x8B\x55\x08\x8B\x0A\x8D\x14\xC1\x3B\x52\x08\x76\x1D", 
        "xxxxxxxxxxxxxxxxxxxxxxx", &result)) {
        wow_lua_settop = (lua_settop_fn)result;
        Log("Found lua_settop at 0x%08X", result);
    } else {
        wow_lua_settop = (lua_settop_fn)0x0084DBF0;
        Log("lua_settop not found, using default 0x0084DBF0");
    }
}
