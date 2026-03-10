#pragma once
#include <windows.h>
#include "WoWOffsets.h"

// Global state variables (declared extern here)
extern DWORD g_playerDescBase;
extern uint32_t g_morphMount;
extern uint32_t g_origMount;
extern bool g_suspended;
extern float g_timeOfDay;

bool DoMorph(const char* cmd, WowObject* player);
void MorphGuard(WowObject* player);
bool ApplyMorphState(WowObject* player);
void ReStampWeapons(WowObject* player);
void UpdateHasMorph();
void ResetAllMorphs(bool forceClearOnly = false);
void SetTime(float val);
extern uint32_t g_morphDisplay;
extern uint32_t g_morphItems[20];
extern float g_morphScale;
extern uint32_t g_morphEnchantMH;
extern uint32_t g_morphEnchantOH;

// Behavior Settings (Use uint32_t for safer ASM alignment)
extern uint32_t g_showDBW;
extern uint32_t g_showMeta;
extern uint32_t g_keepShapeshift;

// Debug
extern uint32_t g_debugLastDisplayID;
