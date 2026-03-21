#pragma once
#include <cstdint>
#include <cstddef>
#include <string>

struct SpellMorphPair {
    uint32_t sourceSpellId;
    uint32_t targetSpellId;
};

bool InstallSpellVisualHook();
void UninstallSpellVisualHook();

bool SetSpellMorph(uint32_t sourceSpellId, uint32_t targetSpellId);
void RemoveSpellMorph(uint32_t sourceSpellId);
void ClearSpellMorphs();
bool HasSpellMorphs();

size_t ExportSpellMorphPairs(SpellMorphPair* outPairs, size_t maxPairs);
void ImportSpellMorphPairs(const SpellMorphPair* pairs, size_t count);

std::string SearchSpells(const std::string& query);
extern size_t GetSpellDBCRecordCount();

// Visibility Controls (Global & Ultra-Granular)
void SetHideAllSpells(bool hide);
void SetHidePrecast(bool hide);
void SetHideCast(bool hide);
void SetHideChannel(bool hide);
void SetHideImpactTarget(bool hide);
void SetHideImpactArea(bool hide);
void SetHideGround(bool hide);
void SetHideMissile(bool hide);
void SetHideAura(bool hide);
void SetHideAudio(bool hide);

void SpellMorph_SoftResetCache();

bool GetHideAllSpells();
bool GetHidePrecast();
bool GetHideCast();
bool GetHideChannel();
bool GetHideImpactTarget();
bool GetHideImpactArea();
bool GetHideGround();
bool GetHideMissile();
bool GetHideAura();
bool GetHideAudio();
