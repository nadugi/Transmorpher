# Transmorpher Changelog

## Version 1.0.4

### Major Changes
- **Complete UI overhaul** with improved layout and spacing
- **Loadout system improvements** - Fixed equipment slot synchronization when applying loadouts
- **Enchant icon updates** - Enchant icons now properly update when loading loadouts
- **Removed Effect System** - Completely removed the unstable effect system that was causing crashes

### UI Improvements
- Fixed loadout preview character model positioning (moved left for better visibility)
- Fixed "Remove" button positioning and centering in loadout panel
- Removed scrollbar from loadout list (mouse wheel scrolling still works)
- Fixed overlapping UI elements in loadout panel
- Improved spacing for "Character Morph" and "Persistence Settings" headers
- Fixed Combat Pet tab "Display ID" input positioning
- Fixed left border visual artifacts
- Better frame clamping to prevent off-screen positioning

### Bug Fixes
- **Fixed shutdown crash** (ACCESS_VIOLATION) - Added proper cleanup and safety checks in DLL
- Fixed enchant icons not updating when loading a loadout
- Fixed equipment slots not visually updating when applying a loadout
- Fixed loadout preview slots overlapping with buttons
- Improved item caching and texture loading in loadout preview

### Code Cleanup
- Removed ~300 lines of unused spell visual code
- Removed duplicate texture files (Textures/Textures folder)
- Removed unused `ApplyEffectBySlashCommand` function
- Deleted EffectsDB.lua (no longer needed)
- Updated build messages to remove outdated references

### Technical Improvements
- Added `g_running` flag to prevent timer from accessing memory during shutdown
- Improved DLL_PROCESS_DETACH cleanup sequence
- Better error handling in MorphTimerProc
- Moved `g_running` declaration before MorphTimerProc for proper initialization
- Added `SetClampedToScreen(true)` to main frame

### Download
Download the latest release (v1.0.4) here:
https://github.com/Kirazul/Transmorpher/releases/tag/1.0.4

---

## Version 1.0.3

### Features
- Complete overhaul of the Dressing Room slots
- Added visual glow indicator when a slot is morphed
- Added option to hide equipment slots
- Added enchant morphing
- Added loadout system to save and load full presets
- Major UI improvements
- Added several quality-of-life improvements to the Dressing Room
- Fixed the majority of mount IDs
- Fixed the majority of pet IDs
- Fixed some weapon transmog issues

---

## Version 1.0.2 and Earlier
See previous release notes for older versions.
