local addon, ns = ...

local mainFrameTitle = "|cffF5C842Transmorpher|r  |cff6a6050v1.0.3|r"

local sex = UnitSex("player")
local _, raceFileName = UnitRace("player")
local _, classFileName = UnitClass("player")

local previewSetupVersion = "classic"

local armorSlots = {"Head", "Shoulder", "Chest", "Wrist", "Hands", "Waist", "Legs", "Feet"}
local backSlot = "Back"
local miscellaneousSlots = {"Tabard", "Shirt"}
local mainHandSlot = "Main Hand"
local offHandSlot = "Off-hand"
local rangedSlot = "Ranged"

local chestSlots = {"Chest", "Tabard", "Shirt"}

local addonMessagePrefix = "Transmorpher"
local slotOrder = { "Head", "Shoulder", "Back", "Chest", "Shirt", "Tabard", "Wrist", "Hands", "Waist", "Legs", "Feet", "Main Hand", "Off-hand", "Ranged",}

-- WoW equipment slot IDs for DLL morph calls
local slotToEquipSlotId = {
    ["Head"] = 1, ["Shoulder"] = 3, ["Back"] = 15, ["Chest"] = 5,
    ["Shirt"] = 4, ["Tabard"] = 19, ["Wrist"] = 9, ["Hands"] = 10,
    ["Waist"] = 6, ["Legs"] = 7, ["Feet"] = 8,
    ["Main Hand"] = 16, ["Off-hand"] = 17, ["Ranged"] = 18,
}

local slotTextures = {
    ["Head"] =      "Interface\\Paperdoll\\ui-paperdoll-slot-head",
    ["Shoulder"] =  "Interface\\Paperdoll\\ui-paperdoll-slot-shoulder",
    ["Back"] =      "Interface\\Paperdoll\\ui-paperdoll-slot-chest",
    ["Chest"] =     "Interface\\Paperdoll\\ui-paperdoll-slot-chest",
    ["Shirt"] =     "Interface\\Paperdoll\\ui-paperdoll-slot-shirt",
    ["Tabard"] =    "Interface\\Paperdoll\\ui-paperdoll-slot-tabard",
    ["Wrist"] =     "Interface\\Paperdoll\\ui-paperdoll-slot-wrists",
    ["Hands"] =     "Interface\\Paperdoll\\ui-paperdoll-slot-hands",
    ["Waist"] =     "Interface\\Paperdoll\\ui-paperdoll-slot-waist",
    ["Legs"] =      "Interface\\Paperdoll\\ui-paperdoll-slot-legs",
    ["Feet"] =      "Interface\\Paperdoll\\ui-paperdoll-slot-feet",
    ["Main Hand"] = "Interface\\Paperdoll\\ui-paperdoll-slot-mainhand",
    ["Off-hand"] =  "Interface\\Paperdoll\\ui-paperdoll-slot-secondaryhand",
    ["Ranged"] =    "Interface\\Paperdoll\\ui-paperdoll-slot-ranged",
}

local slotSubclasses = {}

do
    for i, slot in ipairs(armorSlots) do slotSubclasses[slot] = {"Cloth", "Leather", "Mail", "Plate"} end
    for i, slot in ipairs(miscellaneousSlots) do slotSubclasses[slot] = {"Miscellaneous", } end
    slotSubclasses[backSlot] = {"Cloth", }
    -- All weapon types available in all weapon slots (fully unrestricted)
    -- GetSubclassRecords has cross-slot fallback so items from any slot are found
    local allMeleeTypes = {
        "1H Axe", "1H Mace", "1H Sword", "1H Dagger", "1H Fist",
        "MH Axe", "MH Mace", "MH Sword", "MH Dagger", "MH Fist",
        "OH Axe", "OH Mace", "OH Sword", "OH Dagger", "OH Fist",
        "2H Axe", "2H Mace", "2H Sword", "Polearm", "Staff",
        "Shield", "Held in Off-hand",
        "Bow", "Crossbow", "Gun", "Wand", "Thrown",
    }
    slotSubclasses[mainHandSlot] = allMeleeTypes
    slotSubclasses[offHandSlot]  = allMeleeTypes
    slotSubclasses[rangedSlot]   = allMeleeTypes
end

local defaultSlot = "Head"

local defaultArmorSubclass = {
    ["MAGE"] = "Cloth", ["PRIEST"] = "Cloth", ["WARLOCK"] = "Cloth",
    ["DRUID"] = "Leather", ["ROGUE"] = "Leather",
    ["HUNTER"] = "Mail", ["SHAMAN"] = "Mail",
    ["PALADIN"] = "Plate", ["WARRIOR"] = "Plate", ["DEATHKNIGHT"] = "Plate"
}

local defaultSettings = {
    dressingRoomBackgroundColor = {0.6, 0.6, 0.6, 1},
    dressingRoomBackgroundTexture = {
        [GetRealmName()] = {
            [GetUnitName("player")] = classFileName == "DEATHKNIGHT" and classFileName or raceFileName,
        },
    },
    previewSetup = "classic",
    showDressMeButton = true,
    useServerTimeInReceivedAppearances = false,
    ignoreUIScaling = false,
    saveMorphState = true,
    saveMountMorph = true,
    savePetMorph = true,
    saveHunterPetMorph = true,
    saveCombatPetMorph = true,
    showDBWProc = true,
    morphInShapeshift = false,
}

local function GetSettings()
    local function copyTable(tableFrom)
        local result = {}
        for k, v in pairs(tableFrom) do
            if type(v) == "table" then result[k] = copyTable(v)
            else result[k] = v end
        end
        return result
    end
    if _G["TransmorpherSettings"] == nil then
        _G["TransmorpherSettings"] = copyTable(defaultSettings)
    else
        for k, v in pairs(defaultSettings) do
            if _G["TransmorpherSettings"][k] == nil then
                _G["TransmorpherSettings"][k] = type(v) == "table" and copyTable(v) or v
            end
        end
        if _G["TransmorpherSettings"].dressingRoomBackgroundTexture[GetRealmName()] == nil then
            _G["TransmorpherSettings"].dressingRoomBackgroundTexture[GetRealmName()] = {}
        end
        if _G["TransmorpherSettings"].dressingRoomBackgroundTexture[GetRealmName()][GetUnitName("player")] == nil then
            _G["TransmorpherSettings"].dressingRoomBackgroundTexture[GetRealmName()][GetUnitName("player")] = defaultSettings.dressingRoomBackgroundTexture[GetRealmName()][GetUnitName("player")]
        end
    end
    return _G["TransmorpherSettings"]
end

local function arrayHasValue(array, value)
    for i, v in ipairs(array) do
        if v == value then return true end
    end
    return false
end

---------------- MORPHER BRIDGE (STEALTH MODE) ----------------
-- Commands are sent via a global Lua variable that the C++ DLL
-- reads every 20ms. The DLL handles automatic morph persistence
-- via its MorphGuard system — no Lua-side burst loops needed.

TRANSMORPHER_CMD = ""  -- Global variable the DLL reads

-- Track whether the DLL has been told to suspend (model-changing form active)
local morphSuspended = false

local function IsModelChangingForm()
    -- If user wants morph to persist in shapeshift forms, never suspend
    if GetSettings().morphInShapeshift then return false end

    local form = GetShapeshiftForm()
    if form == 0 then return false end
    
    -- Only druid forms change the character model in a way that conflicts
    -- with display morphs.  Shaman Ghost Wolf and Warlock Metamorphosis
    -- are treated as normal display overrides — the morph display will
    -- persist through them so e.g. a morphed-to-orc player stays orc.
    if classFileName == "DRUID" then
        return true -- All druid forms (Bear, Cat, Travel, Moonkin, Tree, Aquatic)
    end
    
    return false
end

-- Deathbringer's Will proc spell IDs (Normal + Heroic)
-- These procs transform the player model; we suspend morph to show the proc form
local dbwProcIds = {
    [71484] = true, -- Strength of the Taunka (N)
    [71561] = true, -- Strength of the Taunka (H)
    [71486] = true, -- Power of the Taunka (N)
    [71558] = true, -- Power of the Taunka (H)
    [71485] = true, -- Agility of the Vrykul (N)
    [71556] = true, -- Agility of the Vrykul (H)
    [71492] = true, -- Speed of the Vrykul (N)
    [71560] = true, -- Speed of the Vrykul (H)
    [71491] = true, -- Aim of the Iron Dwarves (N)
    [71559] = true, -- Aim of the Iron Dwarves (H)
    [71487] = true, -- Precision of the Iron Dwarves (N)
    [71557] = true, -- Precision of the Iron Dwarves (H)
}

local dbwSuspended = false

local function HasDBWProc()
    for i = 1, 40 do
        local _, _, _, _, _, _, _, _, _, _, spellId = UnitBuff("player", i)
        if not spellId then break end
        if dbwProcIds[spellId] then return true end
    end
    return false
end

local function TrackMorphCommand(cmd)
    if not GetSettings().saveMorphState then return end
    if not TransmorpherCharacterState then TransmorpherCharacterState = {Items={}, Morph=nil, Scale=nil, MountDisplay=nil, PetDisplay=nil, HunterPetDisplay=nil, HunterPetScale=nil} end
    if not TransmorpherCharacterState.Items then TransmorpherCharacterState.Items = {} end

    for singleCmd in cmd:gmatch("[^|]+") do
        local parts = {strsplit(":", singleCmd)}
        local prefix = parts[1]
        
        if prefix == "ITEM" and parts[2] and parts[3] then
            TransmorpherCharacterState.Items[tonumber(parts[2])] = tonumber(parts[3])
        elseif prefix == "MORPH" and parts[2] then
            local val = tonumber(parts[2])
            if val and val > 0 then
                TransmorpherCharacterState.Morph = val
            end
        elseif prefix == "SCALE" and parts[2] then
            TransmorpherCharacterState.Scale = tonumber(parts[2])
        elseif prefix == "MOUNT_MORPH" and parts[2] then
            if GetSettings().saveMountMorph then
                TransmorpherCharacterState.MountDisplay = tonumber(parts[2])
            end
        elseif prefix == "MOUNT_RESET" then
            TransmorpherCharacterState.MountDisplay = nil
        elseif prefix == "PET_MORPH" and parts[2] then
            if GetSettings().savePetMorph then
                TransmorpherCharacterState.PetDisplay = tonumber(parts[2])
            end
        elseif prefix == "PET_RESET" then
            TransmorpherCharacterState.PetDisplay = nil
        elseif prefix == "HPET_MORPH" and parts[2] then
            if GetSettings().saveCombatPetMorph or GetSettings().saveHunterPetMorph then
                TransmorpherCharacterState.HunterPetDisplay = tonumber(parts[2])
            end
        elseif prefix == "HPET_SCALE" and parts[2] then
            if GetSettings().saveCombatPetMorph or GetSettings().saveHunterPetMorph then
                TransmorpherCharacterState.HunterPetScale = tonumber(parts[2])
            end
        elseif prefix == "HPET_RESET" then
            TransmorpherCharacterState.HunterPetDisplay = nil
            TransmorpherCharacterState.HunterPetScale = nil
        elseif prefix == "RESET" and parts[2] then
            if parts[2] == "ALL" then
                TransmorpherCharacterState = {Items={}, Morph=nil, Scale=nil, MountDisplay=nil, PetDisplay=nil, HunterPetDisplay=nil, HunterPetScale=nil}
            else
                TransmorpherCharacterState.Items[tonumber(parts[2])] = nil
            end
        end
    end
end

local function SendMorphCommand(cmd)
    TrackMorphCommand(cmd)
    if TRANSMORPHER_CMD == "" then
        TRANSMORPHER_CMD = cmd
    else
        TRANSMORPHER_CMD = TRANSMORPHER_CMD .. "|" .. cmd
    end
end

-- Send a raw signal to the DLL (SUSPEND/RESUME) without tracking state
local function SendRawMorphCommand(cmd)
    if TRANSMORPHER_CMD == "" then
        TRANSMORPHER_CMD = cmd
    else
        TRANSMORPHER_CMD = TRANSMORPHER_CMD .. "|" .. cmd
    end
end

-- ================================================================
-- Creature ID lookup tables for textured 3D model preview
-- ================================================================
-- ================================================================
-- Icon helper — returns a spell icon texture path for a given spellID.
-- Falls back to a generic question-mark icon if the spell is unknown.
-- ================================================================
local FALLBACK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local function GetSpellIcon(spellID)
    if spellID and spellID > 0 then
        local _, _, icon = GetSpellInfo(spellID)
        if icon then return icon end
    end
    return FALLBACK_ICON
end

-- Flag: when true, the next SendFullMorphState prepends RESET:ALL so the
-- DLL wipe + restore happen in ONE atomic batch (single 20 ms poll).
-- Set on PLAYER_LOGIN so character-switch state bleed is impossible.
local needsCharacterReset = false

-- Send all current morph state to the DLL (used on login/zone change).
-- If needsCharacterReset is set, RESET:ALL is prepended so the whole
-- operation is one pipe-delimited string the DLL processes atomically.
-- Uses SendRawMorphCommand (not SendMorphCommand) because we are restoring
-- already-persisted state — no need to re-track into SavedVariables.
local function SendFullMorphState()
    -- ALWAYS send RESET:ALL on character login to clear DLL state from
    -- any previous character, even if saveMorphState is off.
    if needsCharacterReset then
        SendRawMorphCommand("RESET:ALL")
        needsCharacterReset = false
    end

    if not GetSettings().saveMorphState then
        return
    end
    if not TransmorpherCharacterState then
        return
    end
    if IsModelChangingForm() or dbwSuspended then return end

    local cmdQueue = {}
    if TransmorpherCharacterState.Scale then table.insert(cmdQueue, "SCALE:"..TransmorpherCharacterState.Scale) end
    if TransmorpherCharacterState.Morph then table.insert(cmdQueue, "MORPH:"..TransmorpherCharacterState.Morph) end
    if TransmorpherCharacterState.MountDisplay and GetSettings().saveMountMorph then
        table.insert(cmdQueue, "MOUNT_MORPH:"..TransmorpherCharacterState.MountDisplay)
    end
    if TransmorpherCharacterState.PetDisplay and GetSettings().savePetMorph then
        table.insert(cmdQueue, "PET_MORPH:"..TransmorpherCharacterState.PetDisplay)
    end
    if TransmorpherCharacterState.HunterPetDisplay and (GetSettings().saveCombatPetMorph or GetSettings().saveHunterPetMorph) then
        table.insert(cmdQueue, "HPET_MORPH:"..TransmorpherCharacterState.HunterPetDisplay)
    end
    if TransmorpherCharacterState.HunterPetScale and (GetSettings().saveCombatPetMorph or GetSettings().saveHunterPetMorph) then
        table.insert(cmdQueue, "HPET_SCALE:"..TransmorpherCharacterState.HunterPetScale)
    end
    if TransmorpherCharacterState.Items then
        for slot, item in pairs(TransmorpherCharacterState.Items) do
            table.insert(cmdQueue, "ITEM:"..slot..":"..item)
        end
    end
    if #cmdQueue > 0 then
        SendRawMorphCommand(table.concat(cmdQueue, "|"))
    end
end

local function IsMorpherReady()
    return true
end

local dressingRoomBorderBackdrop = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\AddOns\\Transmorpher\\images\\mirror-border",
    tile = false, tileSize = 16, edgeSize = 32,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
}

---------------- MAIN FRAME ----------------

local mainFrame = CreateFrame("Frame", addon, UIParent)
table.insert(UISpecialFrames, mainFrame:GetName())
do
    mainFrame:SetWidth(1045)
    mainFrame:SetHeight(505)
    mainFrame:SetPoint("CENTER")
    mainFrame:Hide()
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
    mainFrame:SetScript("OnShow", function() PlaySound("igCharacterInfoOpen") end)
    mainFrame:SetScript("OnHide", function() PlaySound("igCharacterInfoClose") end)

    local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -8)
    title:SetText(mainFrameTitle)
    title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    title:SetShadowColor(0, 0, 0, 0.8)
    title:SetShadowOffset(1, -1)

    local titleBg = mainFrame:CreateTexture(nil, "BACKGROUND")
    titleBg:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Title-Background")
    titleBg:SetPoint("TOPLEFT", 10, -7)
    titleBg:SetPoint("BOTTOMRIGHT", mainFrame, "TOPRIGHT", -28, -24)
    titleBg:SetVertexColor(0.14, 0.11, 0.04, 1)

    local menuBg = mainFrame:CreateTexture(nil, "BACKGROUND")
    menuBg:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-TopBackground")
    menuBg:SetTexCoord(0, 1, 0, 0.8125)
    menuBg:SetPoint("TOPLEFT", 10, -26)
    menuBg:SetPoint("RIGHT", -6, 0)
    menuBg:SetHeight(48)
    menuBg:SetVertexColor(0.10, 0.08, 0.03, 1)

    local frameBg = mainFrame:CreateTexture(nil, "BACKGROUND")
    frameBg:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-TopBackground")
    frameBg:SetTexCoord(0, 0.5, 0, 0.8125)
    frameBg:SetPoint("TOPLEFT", menuBg, "BOTTOMLEFT")
    frameBg:SetPoint("TOPRIGHT", menuBg, "BOTTOMRIGHT")
    frameBg:SetPoint("BOTTOM", 0, 5)
    frameBg:SetVertexColor(0.07, 0.06, 0.03, 1)

    local topLeft = mainFrame:CreateTexture(nil, "BORDER")
    topLeft:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
    topLeft:SetTexCoord(0.5, 0.625, 0, 1)
    topLeft:SetWidth(64) topLeft:SetHeight(64) topLeft:SetPoint("TOPLEFT")
    topLeft:SetVertexColor(0.85, 0.70, 0.25, 1)

    local topRight = mainFrame:CreateTexture(nil, "BORDER")
    topRight:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
    topRight:SetTexCoord(0.625, 0.75, 0, 1)
    topRight:SetWidth(64) topRight:SetHeight(64) topRight:SetPoint("TOPRIGHT")
    topRight:SetVertexColor(0.85, 0.70, 0.25, 1)

    local top = mainFrame:CreateTexture(nil, "BORDER")
    top:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
    top:SetTexCoord(0.25, 0.37, 0, 1)
    top:SetPoint("TOPLEFT", topLeft, "TOPRIGHT")
    top:SetPoint("TOPRIGHT", topRight, "TOPLEFT")
    top:SetVertexColor(0.85, 0.70, 0.25, 1)

    local menuSepL = mainFrame:CreateTexture(nil, "BORDER")
    menuSepL:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
    menuSepL:SetTexCoord(0.5, 0.5546875, 0.25, 0.53125)
    menuSepL:SetPoint("TOPLEFT", topLeft, "BOTTOMLEFT")
    menuSepL:SetWidth(28) menuSepL:SetHeight(18)
    menuSepL:SetVertexColor(0.85, 0.70, 0.25, 1)

    local menuSepR = mainFrame:CreateTexture(nil, "BORDER")
    menuSepR:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
    menuSepR:SetTexCoord(0.7109375, 0.75, 0.25, 0.53125)
    menuSepR:SetPoint("TOPRIGHT", topRight, "BOTTOMRIGHT")
    menuSepR:SetWidth(20) menuSepR:SetHeight(18)
    menuSepR:SetVertexColor(0.85, 0.70, 0.25, 1)

    local menuSepC = mainFrame:CreateTexture(nil, "BORDER")
    menuSepC:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
    menuSepC:SetTexCoord(0.564453125, 0.671875, 0.25, 0.53125)
    menuSepC:SetPoint("TOPLEFT", menuSepL, "TOPRIGHT")
    menuSepC:SetPoint("BOTTOMRIGHT", menuSepR, "BOTTOMLEFT")
    menuSepC:SetVertexColor(0.85, 0.70, 0.25, 1)

    local botLeft = mainFrame:CreateTexture(nil, "BORDER")
    botLeft:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
    botLeft:SetTexCoord(0.75, 0.875, 0, 1)
    botLeft:SetPoint("BOTTOMLEFT") botLeft:SetWidth(64) botLeft:SetHeight(64)
    botLeft:SetVertexColor(0.85, 0.70, 0.25, 1)

    local left = mainFrame:CreateTexture(nil, "BORDER")
    left:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
    left:SetTexCoord(0, 0.125, 0, 1)
    left:SetPoint("TOPLEFT", menuSepL, "BOTTOMLEFT")
    left:SetPoint("BOTTOMRIGHT", botLeft, "TOPRIGHT")
    left:SetVertexColor(0.85, 0.70, 0.25, 1)

    local botRight = mainFrame:CreateTexture(nil, "BORDER")
    botRight:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
    botRight:SetTexCoord(0.875, 1, 0, 1)
    botRight:SetPoint("BOTTOMRIGHT") botRight:SetWidth(64) botRight:SetHeight(64)
    botRight:SetVertexColor(0.85, 0.70, 0.25, 1)

    local right = mainFrame:CreateTexture(nil, "BORDER")
    right:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
    right:SetTexCoord(0.125, 0.25, 0, 1)
    right:SetPoint("TOPRIGHT", menuSepR, "BOTTOMRIGHT", 4, 0)
    right:SetPoint("BOTTOMLEFT", botRight, "TOPLEFT", 4, 0)
    right:SetVertexColor(0.85, 0.70, 0.25, 1)

    local bot = mainFrame:CreateTexture(nil, "BORDER")
    bot:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
    bot:SetTexCoord(0.38, 0.45, 0, 1)
    bot:SetPoint("BOTTOMLEFT", botLeft, "BOTTOMRIGHT")
    bot:SetPoint("TOPRIGHT", botRight, "TOPLEFT")
    bot:SetVertexColor(0.85, 0.70, 0.25, 1)

    local separatorV = mainFrame:CreateTexture(nil, "BORDER")
    separatorV:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
    separatorV:SetTexCoord(0.23046875, 0.236328125, 0, 1)
    separatorV:SetPoint("TOPLEFT", 410, -72)
    separatorV:SetPoint("BOTTOM", 0, 32)
    separatorV:SetWidth(3)
    separatorV:SetVertexColor(0.85, 0.70, 0.25, 0.7)

    mainFrame.stats = CreateFrame("Frame", nil, mainFrame)
    local stats = mainFrame.stats
    stats:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 3, right = 3, top = 5, bottom = 3 }
    })
    stats:SetBackdropColor(0.05, 0.04, 0.02, 0.95)
    stats:SetBackdropBorderColor(0.80, 0.65, 0.22, 0.85)
    stats:SetPoint("BOTTOMLEFT", 410, 8)
    stats:SetPoint("BOTTOMRIGHT", -6, 8)
    stats:SetHeight(24)

    -- Morph status text
    mainFrame.morphStatus = stats:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mainFrame.morphStatus:SetPoint("CENTER")
    mainFrame.morphStatus:SetText("")
    mainFrame.morphStatus:SetTextColor(1.0, 0.84, 0.40, 1)

    mainFrame.buttons = {}

    local close = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 2, 1)
    close:SetScript("OnClick", function(self) self:GetParent():Hide() end)
    mainFrame.buttons.close = close
end

---------------- DRESSING ROOM ----------------

mainFrame.dressingRoom = ns.CreateDressingRoom(nil, mainFrame)

do
    local dr = mainFrame.dressingRoom
    dr:SetPoint("TOPLEFT", 10, -74)
    dr:SetSize(400, 400)

    local border = CreateFrame("Frame", nil, dr)
    border:SetAllPoints()
    border:SetBackdrop(dressingRoomBorderBackdrop)
    border:SetBackdropColor(0, 0, 0, 0)
    border:SetBackdropBorderColor(0.80, 0.65, 0.22, 0.9)

    -- Race-specific background textures (from images/ folder)
    dr.backgroundTextures = {}
    local bgKeys = "human,nightelf,dwarf,gnome,draenei,orc,scourge,tauren,troll,bloodelf,deathknight,highelf"
    for s in bgKeys:gmatch("%w+") do
        dr.backgroundTextures[s] = dr:CreateTexture(nil, "BACKGROUND")
        dr.backgroundTextures[s]:SetTexture("Interface\\AddOns\\Transmorpher\\images\\"..s)
        dr.backgroundTextures[s]:SetAllPoints()
        dr.backgroundTextures[s]:Hide()
    end
    dr.backgroundTextures["color"] = dr:CreateTexture(nil, "BACKGROUND")
    dr.backgroundTextures["color"]:SetAllPoints()
    dr.backgroundTextures["color"]:SetTexture(1, 1, 1)
    dr.backgroundTextures["color"]:Hide()

    -- Map raceFileName → background texture key
    local raceToBgKey = {
        Human    = "human",
        NightElf = "nightelf",
        Dwarf    = "dwarf",
        Gnome    = "gnome",
        Draenei  = "draenei",
        Orc      = "orc",
        Scourge  = "scourge",
        Tauren   = "tauren",
        Troll    = "troll",
        BloodElf = "bloodelf",
    }

    -- Show the correct race background for the current character
    function dr:ShowRaceBackground()
        -- Hide all backgrounds first
        for key, tex in pairs(self.backgroundTextures) do
            tex:Hide()
        end
        -- Determine which background to use
        local settings = GetSettings()
        local bgKey = settings.dressingRoomBackgroundTexture[GetRealmName()]
            and settings.dressingRoomBackgroundTexture[GetRealmName()][GetUnitName("player")]
        -- If setting says DEATHKNIGHT, use deathknight bg
        if bgKey == "DEATHKNIGHT" then
            bgKey = "deathknight"
        else
            -- Map race filename to our texture key
            bgKey = raceToBgKey[bgKey] or raceToBgKey[raceFileName] or "human"
        end
        if self.backgroundTextures[bgKey] then
            self.backgroundTextures[bgKey]:Show()
            self.backgroundTextures[bgKey]:SetAlpha(0.4)
        end
    end

    -- Show background on dressing room show
    dr:HookScript("OnShow", function(self) self:ShowRaceBackground() end)

    local tip = dr:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tip:SetPoint("BOTTOM", dr, "TOP", 0, 12)
    tip:SetWidth(dr:GetWidth())  -- Constrain to dressing room width
    tip:SetJustifyH("CENTER") tip:SetJustifyV("BOTTOM")
    tip:SetText("\124cffC8AA6ELeft Mouse:\124r rotate \124 \124cffC8AA6ERight Mouse:\124r pan\124n\124cffC8AA6EWheel\124r or \124cffC8AA6EAlt + Right Mouse:\124r zoom")
    tip:SetTextColor(0.75, 0.7, 0.6, 0.9)
    tip:SetShadowColor(0, 0, 0, 1)
    tip:SetShadowOffset(1, -1)

    local defaultLight = {1, 0, 0, 1, 0, 1, 0.7, 0.7, 0.7, 1, 0.8, 0.8, 0.64}
    local shadowformLight = {1, 0, 0, 1, 0, 1, 0.16, 0, 0.23, 0}
    dr.shadowformEnabled = false
    dr.EnableShadowform = function(self)
        self:SetLight(unpack(shadowformLight))
        self:SetModelAlpha(0.75)
        self.shadowformEnabled = true
    end
    dr.DisableShadowform = function(self)
        self:SetLight(unpack(defaultLight))
        self:SetModelAlpha(1)
        self.shadowformEnabled = false
    end
end

---------------- BOTTOM BUTTONS ----------------

-- Apply All button (NEW - morphs all equipped preview items)
mainFrame.buttons.applyAll = CreateFrame("Button", "$parentButtonApplyAll", mainFrame, "UIPanelButtonTemplate2")
do
    local btn = mainFrame.buttons.applyAll
    btn:SetPoint("TOPLEFT", mainFrame.dressingRoom, "BOTTOMLEFT")
    btn:SetPoint("BOTTOM", mainFrame.stats, "BOTTOM", 0, 1)
    btn:SetWidth(mainFrame.dressingRoom:GetWidth()/4)
    btn:SetText("|cffF5C842Apply All|r")
    
    -- Modern button styling
    btn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, tileSize = 16, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    btn:SetBackdropColor(0.12, 0.22, 0.10, 0.9)
    btn:SetBackdropBorderColor(0.4, 0.6, 0.25, 1)
    
    btn:SetScript("OnClick", function()
        if not IsMorpherReady() then
            SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: |cffff0000Morpher DLL not loaded! Place wow_morpher.dll in your WoW folder.|r")
            return
        end
        for _, slotName in pairs(slotOrder) do
            local slot = mainFrame.slots[slotName]
            if slot.itemId ~= nil and slotToEquipSlotId[slotName] then
                SendMorphCommand("ITEM:" .. slotToEquipSlotId[slotName] .. ":" .. slot.itemId)
            end
        end
        SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: All slots morphed!")
        PlaySound("gsTitleOptionOK")
    end)
    btn:HookScript("OnEnter", function(self)
        self:SetBackdropColor(0.18, 0.30, 0.14, 0.95)
        self:SetBackdropBorderColor(0.55, 0.75, 0.35, 1)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("|cffF5C842Apply All|r", 1, 1, 1)
        GameTooltip:AddLine("Apply all previewed items as morph to your character.", 0.7, 0.9, 1, 1, true)
        GameTooltip:AddLine("Requires wow_morpher.dll in your WoW folder.", 0.6, 0.6, 0.6, 1, true)
        GameTooltip:Show()
    end)
    btn:HookScript("OnLeave", function(self)
        self:SetBackdropColor(0.12, 0.22, 0.10, 0.9)
        self:SetBackdropBorderColor(0.4, 0.6, 0.25, 1)
        GameTooltip:Hide()
    end)
end

-- Reset Morph button (NEW)
mainFrame.buttons.resetMorph = CreateFrame("Button", "$parentButtonResetMorph", mainFrame, "UIPanelButtonTemplate2")
do
    local btn = mainFrame.buttons.resetMorph
    btn:SetPoint("TOPLEFT", mainFrame.buttons.applyAll, "TOPRIGHT")
    btn:SetPoint("BOTTOM", mainFrame.buttons.applyAll, "BOTTOM")
    btn:SetWidth(mainFrame.buttons.applyAll:GetWidth())
    btn:SetText("|cffD4A44EReset Morph|r")
    
    -- Modern button styling
    btn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, tileSize = 16, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    btn:SetBackdropColor(0.20, 0.15, 0.05, 0.9)
    btn:SetBackdropBorderColor(0.55, 0.42, 0.15, 1)
    
    btn:SetScript("OnClick", function()
        if IsMorpherReady() then
            SendMorphCommand("RESET:ALL")
            SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: All morphs reset!")
        end
        PlaySound("gsTitleOptionOK")
    end)
    btn:HookScript("OnEnter", function(self)
        self:SetBackdropColor(0.28, 0.22, 0.08, 0.95)
        self:SetBackdropBorderColor(0.75, 0.58, 0.22, 1)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("|cffD4A44EReset Morph|r", 1, 1, 1)
        GameTooltip:AddLine("Revert all morphed slots back to your real equipped gear.", 0.7, 0.9, 1, 1, true)
        GameTooltip:Show()
    end)
    btn:HookScript("OnLeave", function(self)
        self:SetBackdropColor(0.20, 0.15, 0.05, 0.9)
        self:SetBackdropBorderColor(0.55, 0.42, 0.15, 1)
        GameTooltip:Hide()
    end)
end

-- Reset Preview button
mainFrame.buttons.reset = CreateFrame("Button", "$parentButtonReset", mainFrame, "UIPanelButtonTemplate2")
do
    local btn = mainFrame.buttons.reset
    btn:SetPoint("TOPLEFT", mainFrame.buttons.resetMorph, "TOPRIGHT")
    btn:SetPoint("BOTTOM", mainFrame.buttons.applyAll, "BOTTOM")
    btn:SetWidth(mainFrame.buttons.applyAll:GetWidth())
    btn:SetText("|cff8CB4D8Reset Preview|r")
    
    -- Modern button styling
    btn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, tileSize = 16, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    btn:SetBackdropColor(0.08, 0.12, 0.20, 0.9)
    btn:SetBackdropBorderColor(0.3, 0.42, 0.6, 1)
    
    btn:SetScript("OnClick", function()
        mainFrame.dressingRoom:Reset()
        PlaySound("gsTitleOptionOK")
    end)
    btn:HookScript("OnEnter", function(self)
        self:SetBackdropColor(0.12, 0.18, 0.28, 0.95)
        self:SetBackdropBorderColor(0.4, 0.55, 0.8, 1)
    end)
    btn:HookScript("OnLeave", function(self)
        self:SetBackdropColor(0.08, 0.12, 0.20, 0.9)
        self:SetBackdropBorderColor(0.3, 0.42, 0.6, 1)
    end)
end

-- Undress button
mainFrame.buttons.undress = CreateFrame("Button", "$parentButtonUndress", mainFrame, "UIPanelButtonTemplate2")
do
    local btn = mainFrame.buttons.undress
    btn:SetPoint("TOPLEFT", mainFrame.buttons.reset, "TOPRIGHT")
    btn:SetPoint("TOPRIGHT", mainFrame.dressingRoom, "BOTTOMRIGHT")
    btn:SetPoint("BOTTOM", mainFrame.buttons.applyAll, "BOTTOM")
    btn:SetText("|cffD4A44EUndress|r")
    
    -- Modern button styling
    btn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, tileSize = 16, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    btn:SetBackdropColor(0.18, 0.13, 0.06, 0.9)
    btn:SetBackdropBorderColor(0.55, 0.45, 0.2, 1)
    
    btn:SetScript("OnClick", function()
        mainFrame.dressingRoom:Undress()
        PlaySound("gsTitleOptionOK")
    end)
    btn:HookScript("OnEnter", function(self)
        self:SetBackdropColor(0.25, 0.18, 0.08, 0.95)
        self:SetBackdropBorderColor(0.7, 0.58, 0.3, 1)
    end)
    btn:HookScript("OnLeave", function(self)
        self:SetBackdropColor(0.18, 0.13, 0.06, 0.9)
        self:SetBackdropBorderColor(0.55, 0.45, 0.2, 1)
    end)
end

---------------- SHADOWFORM ----------------

mainFrame.buttons.shadowform = CreateFrame("Button", "$parentShadowformButton", mainFrame, "ItemButtonTemplate")
do
    local enableTex = "Interface\\Icons\\spell_shadow_shadowform"
    local disableTex = "Interface\\Icons\\spell_nature_wispsplode"
    local btn = mainFrame.buttons.shadowform
    btn:SetSize(28, 28)
    _G[btn:GetName().."NormalTexture"]:SetAllPoints()
    _G[btn:GetName().."NormalTexture"]:SetTexCoord(0.1875, 0.796875, 0.1875, 0.796875)
    btn:SetPoint("RIGHT", mainFrame.dressingRoom, "BOTTOMRIGHT", -16, 54)
    btn:SetFrameLevel(mainFrame.dressingRoom:GetFrameLevel() + 1)
    local texture = btn:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints() texture:SetTexture(enableTex)
    btn:RegisterForClicks("LeftButtonUp")
    btn:SetScript("OnClick", function(self)
        PlaySound("gsTitleOptionOK")
        if not mainFrame.dressingRoom.shadowformEnabled then
            mainFrame.dressingRoom:EnableShadowform()
            texture:SetTexture(disableTex) self:LockHighlight()
        else
            mainFrame.dressingRoom:DisableShadowform()
            texture:SetTexture(enableTex) self:UnlockHighlight()
        end
    end)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:ClearLines() GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:AddLine("Shadowform")
        GameTooltip:AddLine("A poor simulation that relies on the model's light setup.", 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:ClearLines() GameTooltip:Hide() end)
end

---------------- TABS ----------------

local TAB_NAMES = {"Items Preview", "Appearances", "Mounts", "Pets", "Combat Pets", "Morph", "Settings"}
mainFrame.tabs = {}

do
    local tabs = {}
    local selectedTabIdx = 1

    -- Compute total width available for tabs (right side of the frame)
    local TAB_AREA_LEFT = 412    -- where tabs start (matches separator)
    local TAB_AREA_RIGHT = 1045 - 10  -- mainFrame width minus right padding
    local TAB_AREA_WIDTH = TAB_AREA_RIGHT - TAB_AREA_LEFT
    local TAB_COUNT = #TAB_NAMES
    local TAB_H = 26
    local TAB_GAP = 0  -- no gap — tabs sit flush against each other
    local TAB_W = math.floor(TAB_AREA_WIDTH / TAB_COUNT)
    local TAB_TOP = -30  -- vertical position from mainFrame top

    local function UpdateTabAppearance()
        for i = 1, TAB_COUNT do
            local tabBtn = mainFrame.buttons["tab"..i]
            if i == selectedTabIdx then
                tabBtn.bg:SetTexture(0.12, 0.10, 0.07, 1)
                tabBtn.topLine:SetTexture(0.96, 0.78, 0.26, 1)
                tabBtn.topLine:Show()
                tabBtn.botLine:Hide()
                tabBtn:GetFontString():SetTextColor(0.96, 0.78, 0.26, 1)
            else
                tabBtn.bg:SetTexture(0.06, 0.05, 0.04, 0.95)
                tabBtn.topLine:Hide()
                tabBtn.botLine:SetTexture(0.35, 0.28, 0.14, 0.6)
                tabBtn.botLine:Show()
                tabBtn:GetFontString():SetTextColor(0.55, 0.50, 0.40, 1)
            end
        end
    end

    local function tab_OnClick(self)
        local prevTab = tabs[selectedTabIdx]
        if prevTab then prevTab:Hide() end
        selectedTabIdx = self:GetID()
        tabs[selectedTabIdx]:Show()
        PlaySound("gsTitleOptionOK")
        UpdateTabAppearance()
    end

    for i = 1, TAB_COUNT do
        local btn = CreateFrame("Button", "$parentTab"..i, mainFrame)
        mainFrame.buttons["tab"..i] = btn
        btn:SetID(i)
        btn:SetSize(TAB_W, TAB_H)

        if i == 1 then
            btn:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", TAB_AREA_LEFT, TAB_TOP)
        else
            btn:SetPoint("LEFT", mainFrame.buttons["tab"..(i - 1)], "RIGHT", TAB_GAP, 0)
        end
        -- Last tab stretches to fill remaining space
        if i == TAB_COUNT then
            btn:SetPoint("RIGHT", mainFrame, "RIGHT", -10, 0)
        end

        -- Solid background
        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture(0.06, 0.05, 0.04, 0.95)
        btn.bg = bg

        -- Gold top line (active indicator, 2px)
        local topLine = btn:CreateTexture(nil, "OVERLAY")
        topLine:SetHeight(2)
        topLine:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
        topLine:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
        topLine:SetTexture(0.96, 0.78, 0.26, 1)
        topLine:Hide()
        btn.topLine = topLine

        -- Subtle bottom border (inactive indicator, 1px)
        local botLine = btn:CreateTexture(nil, "OVERLAY")
        botLine:SetHeight(1)
        botLine:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
        botLine:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
        botLine:SetTexture(0.35, 0.28, 0.14, 0.6)
        btn.botLine = botLine

        -- Left edge separator (skip first tab)
        if i > 1 then
            local sep = btn:CreateTexture(nil, "OVERLAY")
            sep:SetWidth(1)
            sep:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, -3)
            sep:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 3)
            sep:SetTexture(0.3, 0.25, 0.15, 0.4)
        end

        -- Highlight on hover
        local htex = btn:CreateTexture(nil, "HIGHLIGHT")
        htex:SetAllPoints()
        htex:SetTexture(1, 1, 1, 0.06)
        btn:SetHighlightTexture(htex)

        -- Label
        local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("CENTER", 0, 0)
        fs:SetText(TAB_NAMES[i])
        fs:SetTextColor(0.55, 0.50, 0.40, 1)
        btn:SetFontString(fs)

        btn:SetScript("OnClick", tab_OnClick)

        -- Content frame for this tab (positioned below the tab row)
        local frame = CreateFrame("Frame", "$parentTab"..i.."Content", mainFrame)
        frame:SetPoint("TOPLEFT", TAB_AREA_LEFT, TAB_TOP - TAB_H - 2)
        frame:SetPoint("BOTTOMRIGHT", -8, 36)
        frame:Hide()
        table.insert(tabs, frame)
    end

    -- Select first tab
    tab_OnClick(mainFrame.buttons["tab1"])
    mainFrame.tabs.preview = tabs[1]
    mainFrame.tabs.appearances = tabs[2]
    mainFrame.tabs.mounts = tabs[3]
    mainFrame.tabs.pets = tabs[4]
    mainFrame.tabs.combatPets = tabs[5]
    mainFrame.tabs.morph = tabs[6]
    mainFrame.tabs.settings = tabs[7]
end

---------------- SLOTS ----------------

mainFrame.slots = {}
mainFrame.selectedSlot = nil

local function getIndex(array, value)
    for i = 1, 10 do if array[i] == value then return i end end
    return nil
end

local function slot_OnShiftLeftClick(self)
    if self.itemId ~= nil then
        local _, link = GetItemInfo(self.itemId)
        if link then SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: "..link.." ("..self.itemId..")")
        else SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Item cannot be used for transmogrification.") end
    end
end

local function slot_OnControlLeftClick(self)
    if self.itemId ~= nil then ns.ShowWowheadURLDialog(self.itemId) end
end

local function slot_OnLeftClick(self)
    local selectedSlot = mainFrame.selectedSlot
    if selectedSlot ~= nil then selectedSlot:UnlockHighlight() end
    mainFrame.selectedSlot = self
    mainFrame.tabs.preview.subclassMenu:Update(self.slotName)
    if self.itemId ~= nil and getIndex({mainHandSlot, offHandSlot, rangedSlot}, self.slotName) then
        mainFrame.dressingRoom:TryOn(self.itemId)
    end
    self:LockHighlight()
end

local function slot_OnRightClick(self)
    self:RemoveItem()
end

local function slot_OnClick(self, button)
    if button == "LeftButton" then
        if IsShiftKeyDown() then slot_OnShiftLeftClick(self)
        elseif IsControlKeyDown() then slot_OnControlLeftClick(self)
        else slot_OnLeftClick(self) end
        PlaySound("gsTitleOptionOK")
    elseif button == "RightButton" then slot_OnRightClick(self) end
end

local function slot_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if self.itemId == nil then
        GameTooltip:AddLine(self.slotName)
    else
        local _, link = GetItemInfo(self.itemId)
        GameTooltip:SetHyperlink(link)
    end
    GameTooltip:Show()
end

local function slot_OnLeave(self) GameTooltip:Hide() end

local function slot_Reset(self)
    local characterSlotName = self.slotName
    if characterSlotName == mainHandSlot then characterSlotName = "MainHand" end
    if characterSlotName == offHandSlot then characterSlotName = "SecondaryHand" end
    if characterSlotName == rangedSlot then characterSlotName = "Ranged" end
    if characterSlotName == backSlot then characterSlotName = "Back" end
    local slotId = GetInventorySlotInfo(characterSlotName.."Slot")
    local itemId = GetInventoryItemID("player", slotId)
    local name = GetItemInfo(itemId ~= nil and itemId or 0)
    if name ~= nil then self:SetItem(itemId) else self:RemoveItem() end
end

local function slot_RemoveItem(self)
    if self.itemId ~= nil then
        self.itemId = nil
        self.textures.empty:Show() self.textures.item:Hide()
        self:GetScript("OnEnter")(self)
        mainFrame.dressingRoom:Undress()
        for _, slot in pairs(mainFrame.slots) do
            if slot.itemId ~= nil then mainFrame.dressingRoom:TryOn(slot.itemId) end
        end
    end
end

local function slot_SetItem(self, itemId)
    self.itemId = itemId
    ns.QueryItem(itemId, function(queriedItemId, success)
        if queriedItemId == self.itemId and success then
            local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(queriedItemId)
            self.textures.empty:Hide()
            self.textures.item:SetTexture(texture)
            self.textures.item:Show()
            mainFrame.dressingRoom:TryOn(queriedItemId)
        end
    end)
end

-- Build slots
do
    for slotName, texturePath in pairs(slotTextures) do
        local slot = CreateFrame("Button", "$parentSlot"..slotName, mainFrame, "ItemButtonTemplate")
        slot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        slot:SetFrameLevel(mainFrame.dressingRoom:GetFrameLevel() + 1)
        slot:SetScript("OnClick", function(self, button)
            -- Alt+click = apply morph for this slot
            if button == "LeftButton" and IsAltKeyDown() and self.itemId and slotToEquipSlotId[self.slotName] then
                if IsMorpherReady() then
                    SendMorphCommand("ITEM:" .. slotToEquipSlotId[self.slotName] .. ":" .. self.itemId)
                    SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Morphed "..self.slotName.."!")
                else
                    SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: |cffff0000DLL not loaded!|r")
                end
                PlaySound("gsTitleOptionOK")
                return
            end
            slot_OnClick(self, button)
        end)
        slot:SetScript("OnEnter", slot_OnEnter)
        slot:SetScript("OnLeave", slot_OnLeave)
        slot.slotName = slotName
        mainFrame.slots[slotName] = slot
        slot.textures = {}
        slot.textures.empty = slot:CreateTexture(nil, "BACKGROUND")
        slot.textures.empty:SetTexture(texturePath) slot.textures.empty:SetAllPoints()
        slot.textures.item = slot:CreateTexture(nil, "BACKGROUND")
        slot.textures.item:SetAllPoints() slot.textures.item:Hide()
        slot.Reset = slot_Reset
        slot.SetItem = slot_SetItem
        slot.RemoveItem = slot_RemoveItem
    end

    local slots = mainFrame.slots
    slots["Head"]:SetPoint("TOPLEFT", mainFrame.dressingRoom, "TOPLEFT", 16, -16)
    slots["Shoulder"]:SetPoint("TOP", slots["Head"], "BOTTOM", 0, -4)
    slots["Back"]:SetPoint("TOP", slots["Shoulder"], "BOTTOM", 0, -4)
    slots["Chest"]:SetPoint("TOP", slots["Back"], "BOTTOM", 0, -4)
    slots["Shirt"]:SetPoint("TOP", slots["Chest"], "BOTTOM", 0, -36)
    slots["Tabard"]:SetPoint("TOP", slots["Shirt"], "BOTTOM", 0, -4)
    slots["Wrist"]:SetPoint("TOP", slots["Tabard"], "BOTTOM", 0, -36)
    slots["Hands"]:SetPoint("TOPRIGHT", mainFrame.dressingRoom, "TOPRIGHT", -16, -16)
    slots["Waist"]:SetPoint("TOP", slots["Hands"], "BOTTOM", 0, -4)
    slots["Legs"]:SetPoint("TOP", slots["Waist"], "BOTTOM", 0, -4)
    slots["Feet"]:SetPoint("TOP", slots["Legs"], "BOTTOM", 0, -4)
    slots["Off-hand"]:SetPoint("BOTTOM", mainFrame.dressingRoom, "BOTTOM", 0, 16)
    slots["Main Hand"]:SetPoint("RIGHT", slots["Off-hand"], "LEFT", -4, 0)
    slots["Ranged"]:SetPoint("LEFT", slots["Off-hand"], "RIGHT", 4, 0)
end

------- Hooks for slots and dressing room -------

local function btnReset_Hook()
    mainFrame.dressingRoom:Undress()
    for _, slot in pairs(mainFrame.slots) do
        if slot.slotName == rangedSlot and ("DRUIDSHAMANPALADINDEATHKNIGHT"):find(classFileName) then
            slot:RemoveItem()
        else slot:Reset() end
    end
    if mainFrame.dressingRoom.shadowformEnabled then mainFrame.dressingRoom:EnableShadowform() end
end

local function btnUndress_Hook()
    for _, slot in pairs(mainFrame.slots) do
        slot.itemId = nil
        slot.textures.empty:Show() slot.textures.item:Hide()
    end
end

local function tryOnFromSlots(dressUpModel)
    for _, slot in pairs(mainFrame.slots) do
        if slot.itemId ~= nil then dressUpModel:TryOn(slot.itemId) end
    end
end

local function dressingRoom_OnShow(self)
    self:Reset() self:Undress() tryOnFromSlots(self)
    if self.shadowformEnabled then self:EnableShadowform() end
end

mainFrame.slots[defaultSlot]:SetScript("OnShow", function(self)
    self:SetScript("OnShow", nil)
    mainFrame.buttons.reset:HookScript("OnClick", btnReset_Hook)
    mainFrame.dressingRoom:HookScript("OnShow", dressingRoom_OnShow)
    dressingRoom_OnShow(mainFrame.dressingRoom)
    btnReset_Hook()
    mainFrame.buttons.undress:HookScript("OnClick", btnUndress_Hook)
    self:Click("LeftButton")
end)

---------------- PREVIEW TAB ----------------

mainFrame.tabs.preview.list = ns.CreatePreviewList(mainFrame.tabs.preview)
mainFrame.tabs.preview.slider = CreateFrame("Slider", "$parentSlider", mainFrame.tabs.preview, "UIPanelScrollBarTemplateLightBorder")

do
    local previewTab = mainFrame.tabs.preview
    local list = mainFrame.tabs.preview.list
    local slider = mainFrame.tabs.preview.slider

    -- ======== TOP TOOLBAR: Search bar (left) + Custom dropdown (right) ========

    -- Dropdown container (right side, fixed width)
    local dropContainer = CreateFrame("Frame", nil, previewTab)
    previewTab.dropContainer = dropContainer
    dropContainer:SetSize(170, 26)
    dropContainer:SetPoint("TOPRIGHT", -6, -6)
    dropContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    dropContainer:SetBackdropColor(0.06, 0.05, 0.03, 0.95)
    dropContainer:SetBackdropBorderColor(0.60, 0.50, 0.18, 0.8)

    -- Dropdown button (the clickable label + arrow inside the container)
    local dropBtn = CreateFrame("Button", "$parentSubDropBtn", dropContainer)
    previewTab.dropBtn = dropBtn
    dropBtn:SetAllPoints()
    dropBtn:EnableMouse(true)

    local dropText = dropBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    previewTab.dropText = dropText
    dropText:SetPoint("LEFT", 8, 0)
    dropText:SetPoint("RIGHT", -20, 0)
    dropText:SetJustifyH("LEFT")
    dropText:SetTextColor(0.95, 0.88, 0.65)
    dropText:SetText("Mail")

    local dropArrow = dropBtn:CreateTexture(nil, "OVERLAY")
    previewTab.dropArrow = dropArrow
    dropArrow:SetSize(14, 14)
    dropArrow:SetPoint("RIGHT", -4, 0)
    dropArrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
    dropArrow:SetVertexColor(0.80, 0.65, 0.22)

    -- Hover highlight on dropdown
    dropBtn:SetScript("OnEnter", function(self)
        dropContainer:SetBackdropBorderColor(0.80, 0.65, 0.22, 1)
    end)
    dropBtn:SetScript("OnLeave", function(self)
        dropContainer:SetBackdropBorderColor(0.60, 0.50, 0.18, 0.8)
    end)

    -- Dropdown list (shown on click)
    local dropList = CreateFrame("Frame", "$parentSubDropList", previewTab)
    previewTab.dropList = dropList
    dropList:SetPoint("TOPLEFT", dropContainer, "BOTTOMLEFT", 0, 2)
    dropList:SetPoint("TOPRIGHT", dropContainer, "BOTTOMRIGHT", 0, 2)
    dropList:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    dropList:SetBackdropColor(0.06, 0.05, 0.03, 0.97)
    dropList:SetBackdropBorderColor(0.80, 0.65, 0.22, 0.9)
    dropList:SetFrameStrata("DIALOG")
    dropList:Hide()

    local DROP_ROW_H = 20
    previewTab.DROP_ROW_H = DROP_ROW_H
    local dropListButtons = {}
    previewTab.dropListButtons = dropListButtons

    -- Search bar container (left side, flexible width)
    local searchContainer = CreateFrame("Frame", nil, previewTab)
    searchContainer:SetPoint("TOPLEFT", 6, -6)
    searchContainer:SetPoint("RIGHT", dropContainer, "LEFT", -6, 0)
    searchContainer:SetHeight(26)
    searchContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    searchContainer:SetBackdropColor(0.06, 0.05, 0.03, 0.95)
    searchContainer:SetBackdropBorderColor(0.60, 0.50, 0.18, 0.8)

    local searchIcon = searchContainer:CreateTexture(nil, "OVERLAY")
    searchIcon:SetSize(14, 14)
    searchIcon:SetPoint("LEFT", 6, 0)
    searchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
    searchIcon:SetVertexColor(0.80, 0.65, 0.22)

    local searchBox = CreateFrame("EditBox", "$parentPreviewSearch", searchContainer)
    searchBox:SetPoint("LEFT", searchIcon, "RIGHT", 4, 0)
    searchBox:SetPoint("RIGHT", -24, 0)
    searchBox:SetHeight(18)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(60)
    searchBox:SetFont("Fonts\\FRIZQT__.TTF", 11)
    searchBox:SetTextColor(0.95, 0.88, 0.65)
    searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    local searchPlaceholder = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    searchPlaceholder:SetPoint("LEFT", 2, 0)
    searchPlaceholder:SetText("Search by name or item ID...")
    searchBox:SetScript("OnEditFocusGained", function() searchPlaceholder:Hide() end)
    searchBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then searchPlaceholder:Show() end
    end)

    local searchClear = CreateFrame("Button", nil, searchContainer)
    searchClear:SetSize(14, 14)
    searchClear:SetPoint("RIGHT", -4, 0)
    searchClear:SetNormalTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
    searchClear:SetAlpha(0.5)
    searchClear:Hide()
    searchClear:SetScript("OnEnter", function(self) self:SetAlpha(1) end)
    searchClear:SetScript("OnLeave", function(self) self:SetAlpha(0.5) end)
    searchClear:SetScript("OnClick", function()
        searchBox:SetText("")
        searchBox:ClearFocus()
        searchPlaceholder:Show()
        searchClear:Hide()
        previewTab.searchQuery = ""
    end)

    -- Search state
    previewTab.searchQuery = ""
    previewTab.searchResults = nil  -- nil = no filter active

    list:SetPoint("TOPLEFT", 0, -34) list:SetSize(601, 367)

    local label = list:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOP", list, "BOTTOM", 0, -5)
    label:SetJustifyH("CENTER") label:SetHeight(10)
    label:SetTextColor(0.85, 0.70, 0.40)

    slider:SetPoint("TOPRIGHT", -6, -21) slider:SetPoint("BOTTOMRIGHT", -6, 21)
    slider:EnableMouseWheel(true)
    slider:SetScript("OnMouseWheel", function(self, delta) self:SetValue(self:GetValue() - delta) end)
    slider:SetScript("OnMinMaxChanged", function(self, min, max)
        label:SetText(("Page: %s/%s"):format(self:GetValue(), max))
    end)

    slider.buttons = {}
    slider.buttons.up = _G[slider:GetName() .. "ScrollUpButton"]
    slider.buttons.down = _G[slider:GetName() .. "ScrollDownButton"]
    slider.buttons.up:SetScript("OnClick", function() slider:SetValue(slider:GetValue() - 1) PlaySound("gsTitleOptionOK") end)
    slider.buttons.down:SetScript("OnClick", function() slider:SetValue(slider:GetValue() + 1) PlaySound("gsTitleOptionOK") end)

    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(self, delta) slider:SetValue(slider:GetValue() - delta) end)

    slider:SetScript("OnValueChanged", function(self, value)
        local _, max = self:GetMinMaxValues()
        label:SetText(("Page: %s/%s"):format(value, max))
    end)

    slider:SetMinMaxValues(0, 0) slider:SetValueStep(1)

---------------- Preview list logic ----------------

    local slotSubclassPage = {}
    for slot, _ in pairs(mainFrame.slots) do slotSubclassPage[slot] = {} end

    local currSlot, currSubclass = defaultSlot, defaultArmorSubclass[classFileName]
    local records

    -- Hair hiding functionality removed

    -- Core update function (with search filtering support)
    previewTab.Update = function(self, slot, subclass)
        slotSubclassPage[currSlot][currSubclass] = slider:GetValue() > 0 and slider:GetValue() or 1
        currSlot = slot currSubclass = subclass
        records = ns.GetSubclassRecords(slot, subclass)
        if not records then records = {} end

        -- Build filtered records based on search
        local query = previewTab.searchQuery or ""
        local filteredRecords = {}
        local filteredItemIds = {}
        local selectedItemId

        if query ~= "" then
            local lowerQ = query:lower()
            local numQ = tonumber(query)
            for i = 1, #records do
                local ids = records[i][1]
                local names = records[i][2]
                local match = false
                for j = 1, #ids do
                    if numQ and ids[j] == numQ then match = true; break end
                    if names[j] and names[j]:lower():find(lowerQ, 1, true) then match = true; break end
                end
                if match then
                    table.insert(filteredRecords, records[i])
                    table.insert(filteredItemIds, ids[1])
                    if selectedItemId == nil and mainFrame.slots[slot].itemId ~= nil and arrayHasValue(ids, mainFrame.slots[slot].itemId) then
                        selectedItemId = ids[1]
                    end
                end
            end
            -- Replace records reference for tooltip/click handlers
            records = filteredRecords
        else
            for i = 1, #records do
                local ids = records[i][1]
                table.insert(filteredItemIds, ids[1])
                if selectedItemId == nil and mainFrame.slots[slot].itemId ~= nil and arrayHasValue(ids, mainFrame.slots[slot].itemId) then
                    selectedItemId = ids[1]
                end
            end
        end

        list:SetItems(filteredItemIds)
        if selectedItemId ~= nil then list:SelectByItemId(selectedItemId) end

        -- Only setup model + paginate if there are items to show
        if #filteredItemIds > 0 then
            local setup = ns.GetPreviewSetup(previewSetupVersion, raceFileName, sex, slot, subclass)
            list:SetupModel(setup.width, setup.height, setup.x, setup.y, setup.z, setup.facing, setup.sequence)

            list:TryOn(nil)
            local page = 1
            if query == "" then
                page = slotSubclassPage[slot][subclass] ~= nil and slotSubclassPage[slot][subclass] or 1
            end
            local pageCount = list:GetPageCount()
            if pageCount < 1 then pageCount = 1 end
            if page > pageCount then page = pageCount end
            slider:SetMinMaxValues(1, pageCount)
            if slider:GetValue() ~= page then slider:SetValue(page)
            else list:SetPage(page) list:Update() end
        else
            slider:SetMinMaxValues(1, 1)
            slider:SetValue(1)
        end
    end

    previewTab:SetScript("OnShow", function(self) self:Update(currSlot, currSubclass) end)

    -- Search bar event handlers
    local searchTimer = CreateFrame("Frame")
    searchTimer:Hide()
    searchTimer.elapsed = 0
    searchTimer:SetScript("OnUpdate", function(self, dt)
        self.elapsed = self.elapsed + dt
        if self.elapsed >= 0.3 then
            self:Hide()
            previewTab:Update(currSlot, currSubclass)
        end
    end)

    searchBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        previewTab.searchQuery = text
        if text ~= "" then searchClear:Show(); searchPlaceholder:Hide()
        else searchClear:Hide() end
        -- Debounce: wait 0.3s after last keystroke
        searchTimer.elapsed = 0
        searchTimer:Show()
    end)
    searchBox:SetScript("OnEnterPressed", function(self)
        searchTimer:Hide()
        previewTab:Update(currSlot, currSubclass)
        self:ClearFocus()
    end)

    slider:HookScript("OnValueChanged", function(self, value)
        list:SetPage(value)
        if #list.itemIds > 0 then list:Update() end
    end)

    local selectedInRecord = {}
    local enteredButton
    local tabDummy = CreateFrame("Button", addon.."PreviewListTabDummy", previewTab)

    list.onEnter = function(self)
        local recordIndex = self:GetParent().itemIndex
        if not records or not records[recordIndex] then return end
        local ids = records[recordIndex][1]
        local names = records[recordIndex][2]
        GameTooltip:Hide() GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT") GameTooltip:ClearLines()
        GameTooltip:AddLine("This appearance is provided by:", 1, 1, 1) GameTooltip:AddLine(" ")
        local selectedIndex = selectedInRecord[ids[1]] ~= nil and selectedInRecord[ids[1]] or 1
        for i, id in ipairs(ids) do
            GameTooltip:AddLine((i == selectedIndex and "> " or "- ")..names[i]..(id == mainFrame.selectedSlot.itemId and " *"or ""))
        end
        GameTooltip:Show()
        SetOverrideBindingClick(tabDummy, true, "TAB", tabDummy:GetName(), "RightButton")
        enteredButton = self
    end

    list.onLeave = function(self)
        ClearOverrideBindings(tabDummy)
        GameTooltip:ClearLines() GameTooltip:Hide() enteredButton = nil
    end

    tabDummy:SetScript("OnClick", function()
        if enteredButton ~= nil then
            local recordIndex = enteredButton:GetParent().itemIndex
            local ids = records[recordIndex][1]
            if #ids > 1 then
                if selectedInRecord[ids[1]] == nil then selectedInRecord[ids[1]] = 2
                else selectedInRecord[ids[1]] = selectedInRecord[ids[1]] < #ids and selectedInRecord[ids[1]] + 1 or 1 end
            end
            list.onEnter(enteredButton)
        end
    end)

    list.onItemClick = function(self, button)
        local recordIndex = self:GetParent().itemIndex
        if not records or not records[recordIndex] then return end
        local ids = records[recordIndex][1]
        local selectedIndex = selectedInRecord[ids[1]] ~= nil and selectedInRecord[ids[1]] or 1
        local itemId = ids[selectedIndex]
        if IsShiftKeyDown() then
            local names = records[recordIndex][2]
            local color = names[selectedIndex]:sub(1, 10)
            local name = names[selectedIndex]:sub(11, -3)
            SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: "..color.."\124Hitem:"..itemId..":::::::|h["..name.."]\124h\124r".." ("..itemId..")")
        elseif IsControlKeyDown() then
            ns.ShowWowheadURLDialog(itemId)
        else
            mainFrame.selectedSlot:SetItem(itemId)
        end
        list.onEnter(self)
    end
end

---------------- SUBCLASS MENU (Custom Golden Dropdown) ----------------

-- Replaces UIDropDownMenuTemplate with a custom themed dropdown
-- Uses dropContainer, dropBtn, dropText, dropArrow, dropList, dropListButtons
-- created in the preview tab block above.
mainFrame.tabs.preview.subclassMenu = {}
do
    local previewTab = mainFrame.tabs.preview
    local menu = mainFrame.tabs.preview.subclassMenu

    -- Pull references from the preview tab scope
    local dropContainer = previewTab.dropContainer
    local dropBtn = previewTab.dropBtn
    local dropText = previewTab.dropText
    local dropArrow = previewTab.dropArrow
    local dropList = previewTab.dropList
    local dropListButtons = previewTab.dropListButtons
    local DROP_ROW_H = previewTab.DROP_ROW_H

    local slotSelectedSubclass = {}
    for i, slot in ipairs(armorSlots) do slotSelectedSubclass[slot] = defaultArmorSubclass[classFileName] end
    for i, slot in ipairs(miscellaneousSlots) do slotSelectedSubclass[slot] = "Miscellaneous" end
    slotSelectedSubclass[backSlot] = slotSubclasses[backSlot][1]
    slotSelectedSubclass[mainHandSlot] = slotSubclasses[mainHandSlot][1]
    slotSelectedSubclass[offHandSlot] = slotSubclasses[offHandSlot][1]
    slotSelectedSubclass[rangedSlot] = slotSubclasses[rangedSlot][1]

    menu.currentSlot = nil

    local function BuildDropList(slot)
        -- Hide any previous buttons
        for _, b in ipairs(dropListButtons) do b:Hide() end

        local subclasses = slotSubclasses[slot]
        if not subclasses then return end

        local totalH = 0
        for i, subclass in ipairs(subclasses) do
            local btn = dropListButtons[i]
            if not btn then
                btn = CreateFrame("Button", nil, dropList)
                btn:SetHeight(DROP_ROW_H)
                btn:SetPoint("TOPLEFT", 4, -4 - (i - 1) * DROP_ROW_H)
                btn:SetPoint("TOPRIGHT", -4, -4 - (i - 1) * DROP_ROW_H)
                btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
                btn:GetHighlightTexture():SetVertexColor(0.80, 0.65, 0.22, 0.3)
                btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                btn.text:SetPoint("LEFT", 6, 0)
                btn.text:SetJustifyH("LEFT")
                btn.check = btn:CreateTexture(nil, "OVERLAY")
                btn.check:SetSize(12, 12)
                btn.check:SetPoint("RIGHT", -4, 0)
                btn.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
                btn.check:SetVertexColor(0.95, 0.80, 0.30)
                dropListButtons[i] = btn
            end

            local isSelected = (subclass == slotSelectedSubclass[slot])
            btn.text:SetText(subclass)
            if isSelected then
                btn.text:SetTextColor(1.0, 0.84, 0.40)
                btn.check:Show()
            else
                btn.text:SetTextColor(0.85, 0.78, 0.55)
                btn.check:Hide()
            end

            btn:SetScript("OnClick", function()
                slotSelectedSubclass[slot] = subclass
                dropText:SetText(subclass)
                dropList:Hide()
                previewTab:Update(slot, subclass)
            end)
            btn:Show()
            totalH = totalH + DROP_ROW_H
        end
        dropList:SetHeight(totalH + 8)
    end

    -- Toggle dropdown on click
    dropBtn:SetScript("OnClick", function()
        if dropList:IsShown() then
            dropList:Hide()
        else
            if menu.currentSlot then
                BuildDropList(menu.currentSlot)
            end
            dropList:Show()
        end
    end)

    -- Auto-close dropdown when mouse leaves both the button and the list
    dropList:SetScript("OnUpdate", function(self)
        if not self:IsShown() then return end
        if dropBtn:IsMouseOver() or self:IsMouseOver() then return end
        -- Check if hovering a row button
        for _, b in ipairs(dropListButtons) do
            if b:IsShown() and b:IsMouseOver() then return end
        end
        -- Not hovering anything — hide after a tiny grace period
        if not self.leaveTimer then self.leaveTimer = 0 end
        self.leaveTimer = self.leaveTimer + 0.02
        if self.leaveTimer > 0.35 then
            self:Hide()
            self.leaveTimer = nil
        end
    end)

    -- Reset timer when mouse re-enters
    dropList:HookScript("OnShow", function(self) self.leaveTimer = nil end)
    dropBtn:HookScript("OnEnter", function() dropList.leaveTimer = nil end)
    dropList:HookScript("OnEnter", function(self) self.leaveTimer = nil end)

    -- Update function called by slot_OnLeftClick
    menu.Update = function(self, slot)
        self.currentSlot = slot
        local subclass = slotSelectedSubclass[slot]
        dropText:SetText(subclass)
        dropList:Hide()

        -- Enable/disable appearance
        if #slotSubclasses[slot] > 1 then
            dropArrow:SetVertexColor(0.80, 0.65, 0.22)
            dropText:SetTextColor(0.95, 0.88, 0.65)
            dropBtn:Enable()
        else
            dropArrow:SetVertexColor(0.40, 0.35, 0.20)
            dropText:SetTextColor(0.50, 0.45, 0.30)
            dropBtn:Disable()
        end

        previewTab:Update(slot, subclass)
    end
end

---------------- APPEARANCES TAB ----------------

mainFrame.tabs.appearances.saved = CreateFrame("Frame", "$parentSaved", mainFrame.tabs.appearances)
do
    local appearancesTab = mainFrame.tabs.appearances
    local frame = appearancesTab.saved

    -- List panel on the left side (narrower to make room for preview)
    frame:SetPoint("TOPLEFT", 0, -30) frame:SetPoint("BOTTOMLEFT", 0, 30) frame:SetWidth(320)
    frame:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }})
    frame:SetBackdropColor(0.04, 0.03, 0.03, 0.95)
    frame:SetBackdropBorderColor(0.80, 0.65, 0.22, 0.85)

    local scrollFrame = CreateFrame("ScrollFrame", "$parentScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 8, -8) scrollFrame:SetPoint("BOTTOMLEFT", 8, 8)
    scrollFrame:SetWidth(frame:GetWidth() - 25)

    -- ============================================================
    -- Preview model on the right side
    -- ============================================================
    local previewFrame = CreateFrame("Frame", "$parentLookPreview", appearancesTab)
    previewFrame:SetPoint("TOPLEFT", frame, "TOPRIGHT", 8, 0)
    previewFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", 8, 0)
    previewFrame:SetWidth(290)
    previewFrame:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }})
    previewFrame:SetBackdropColor(0.04, 0.03, 0.03, 0.95)
    previewFrame:SetBackdropBorderColor(0.80, 0.65, 0.22, 0.85)

    local previewModel = CreateFrame("DressUpModel", "$parentPreviewModel", previewFrame)
    previewModel:SetPoint("TOPLEFT", 6, -6)
    previewModel:SetPoint("BOTTOMRIGHT", -6, 30)
    previewModel:SetUnit("player")
    previewModel:SetFacing(-0.4)
    previewModel:SetPosition(0, 0, 0)

    -- Mouse rotation on the preview model
    local previewRotating = false
    previewModel:EnableMouse(true)
    previewModel:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then previewRotating = true end
    end)
    previewModel:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then previewRotating = false end
    end)
    previewModel:SetScript("OnUpdate", function(self, dt)
        if previewRotating and IsMouseButtonDown("LeftButton") then
            local x, y = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            x = x / scale
            if self.lastX then
                local dx = x - self.lastX
                self:SetFacing(self:GetFacing() + dx * 0.02)
            end
            self.lastX = x
        else
            self.lastX = nil
        end
    end)
    previewModel:EnableMouseWheel(true)
    previewModel:SetScript("OnMouseWheel", function(self, delta)
        local x, y, z = self:GetPosition()
        x = x + delta * 0.3
        if x < -2 then x = -2 end
        if x > 4 then x = 4 end
        self:SetPosition(x, y, z)
    end)

    -- Label under the preview
    local previewLabel = previewFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    previewLabel:SetPoint("BOTTOM", previewFrame, "BOTTOM", 0, 10)
    previewLabel:SetText("|cff8a7d6aSelect a look to preview|r")

    -- "No preview" text when empty
    local noPreviewText = previewFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    noPreviewText:SetPoint("CENTER", previewModel, "CENTER")
    noPreviewText:SetText("|cff4a4540No Look Selected|r")

    -- Function to update the preview model with a saved look's items
    -- Uses item caching to fix weapons not showing in preview
    local lookPreviewTimer = CreateFrame("Frame")
    lookPreviewTimer:Hide()

    local function UpdateLookPreview(lookItems, lookName)
        lookPreviewTimer:Hide()
        lookPreviewTimer:SetScript("OnUpdate", nil)

        if not lookItems then
            noPreviewText:Show()
            previewLabel:SetText("|cff8a7d6aSelect a look to preview|r")
            previewModel:SetUnit("player")
            previewModel:Undress()
            return
        end
        noPreviewText:Hide()
        previewLabel:SetText("|cffffd700" .. (lookName or "Preview") .. "|r")

        -- Collect all valid item IDs from the look
        local pendingItems = {}
        for index, slotName in pairs(slotOrder) do
            local itemId = lookItems[index]
            if itemId and itemId ~= 0 then
                table.insert(pendingItems, itemId)
            end
        end

        -- Pre-cache all items, then dress the model once all are ready
        local function DressModel()
            previewModel:SetUnit("player")
            previewModel:Undress()
            for _, itemId in ipairs(pendingItems) do
                previewModel:TryOn(itemId)
            end
        end

        -- First pass: trigger cache for all items
        local uncached = 0
        for _, itemId in ipairs(pendingItems) do
            local _, itemLink = GetItemInfo(itemId)
            if not itemLink then
                uncached = uncached + 1
                ns.QueryItem(itemId, nil)
            end
        end

        -- If all cached, dress immediately
        if uncached == 0 then
            DressModel()
            return
        end

        -- Otherwise dress now (partial), then retry after items load
        DressModel()
        local retryCount = 0
        local retryMax = 15  -- ~1.5 seconds of retries
        lookPreviewTimer.elapsed = 0
        lookPreviewTimer:SetScript("OnUpdate", function(self, dt)
            self.elapsed = self.elapsed + dt
            if self.elapsed >= 0.1 then
                self.elapsed = 0
                retryCount = retryCount + 1

                -- Check if all items are now cached
                local allCached = true
                for _, itemId in ipairs(pendingItems) do
                    local _, itemLink = GetItemInfo(itemId)
                    if not itemLink then allCached = false; break end
                end

                if allCached or retryCount >= retryMax then
                    DressModel()
                    self:Hide()
                    self:SetScript("OnUpdate", nil)
                end
            end
        end)
        lookPreviewTimer:Show()
    end

    -- ============================================================
    -- Top buttons
    -- ============================================================
    local btnSave = CreateFrame("Button", "$parentButtonSave", frame, "UIPanelButtonTemplate2")
    btnSave:SetSize(80, 22) btnSave:SetPoint("TOP", frame, "TOP", 0, 28)
    btnSave:SetText("Save") btnSave:SetScript("OnClick", function() PlaySound("gsTitleOptionOK") end) btnSave:Disable()

    local btnSaveAs = CreateFrame("Button", "$parentButtonSaveAs", frame, "UIPanelButtonTemplate2")
    btnSaveAs:SetSize(100, 22) btnSaveAs:SetPoint("RIGHT", btnSave, "LEFT", -10, 0)
    btnSaveAs:SetText("Save As...") btnSaveAs:SetScript("OnClick", function() PlaySound("gsTitleOptionOK") end)

    local btnRemove = CreateFrame("Button", "$parentButtonRemove", frame, "UIPanelButtonTemplate2")
    btnRemove:SetSize(80, 22) btnRemove:SetPoint("LEFT", btnSave, "RIGHT", 10, 0)
    btnRemove:SetText("Remove") btnRemove:SetScript("OnClick", function() PlaySound("gsTitleOptionOK") end) btnRemove:Disable()

    local btnTryOn = CreateFrame("Button", "$parentButtonTryOn", frame, "UIPanelButtonTemplate2")
    btnTryOn:SetSize(110, 22) btnTryOn:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", -5, -28)
    btnTryOn:SetText("Preview Look") btnTryOn:SetScript("OnClick", function() PlaySound("gsTitleOptionOK") end) btnTryOn:Disable()

    -- NEW: Apply Look button
    local btnApplyLook = CreateFrame("Button", "$parentButtonApplyLook", frame, "UIPanelButtonTemplate2")
    btnApplyLook:SetSize(110, 22) btnApplyLook:SetPoint("BOTTOMLEFT", frame, "BOTTOM", 5, -28)
    btnApplyLook:SetText("|cffF5C842Apply Morph|r")
    btnApplyLook:SetScript("OnClick", function() PlaySound("gsTitleOptionOK") end) btnApplyLook:Disable()

    local listFrame = ns.CreateListFrame("$parentSavedLooks", nil, scrollFrame)
    listFrame:SetWidth(scrollFrame:GetWidth())
    listFrame:SetScript("OnShow", function(self)
        if self.selected == nil then
            btnTryOn:Disable() btnRemove:Disable() btnSave:Disable() btnApplyLook:Disable()
            UpdateLookPreview(nil, nil)
        else
            btnTryOn:Enable() btnRemove:Enable() btnSave:Enable() btnApplyLook:Enable()
        end
    end)
    listFrame.onSelect = function()
        btnTryOn:Enable() btnRemove:Enable() btnSave:Enable() btnApplyLook:Enable()
        -- Update the preview model with the selected look
        if listFrame:GetSelected() and _G["TransmorpherSavedLooks"] then
            local id = listFrame.buttons[listFrame:GetSelected()]:GetID()
            local look = _G["TransmorpherSavedLooks"][id]
            if look then
                UpdateLookPreview(look.items, look.name)
            end
        end
    end

    local function slots2ItemList()
        local items = {}
        for _, slotName in pairs(slotOrder) do
            if mainFrame.slots[slotName].itemId ~= nil then table.insert(items, mainFrame.slots[slotName].itemId)
            else table.insert(items, 0) end
        end
        return items
    end

    local function buildList()
        local savedLooks = _G["TransmorpherSavedLooks"]
        _G["TransmorpherSavedLooks"] = {}
        local names, items = {}, {}
        for _, look in pairs(savedLooks) do
            table.insert(names, look.name) items[look.name] = look.items
        end
        table.sort(names)
        for _, name in ipairs(names) do
            listFrame:AddItem(name)
            table.insert(_G["TransmorpherSavedLooks"], {["name"] = name, ["items"] = items[name]})
        end
    end

    listFrame:RegisterEvent("ADDON_LOADED")
    listFrame:SetScript("OnEvent", function(self, event, addonName)
        if addonName == addon and event == "ADDON_LOADED" then
            if _G["TransmorpherSavedLooks"] == nil then _G["TransmorpherSavedLooks"] = {} end
            if _G["TransmorpherMorphFavorites"] == nil then _G["TransmorpherMorphFavorites"] = {} end
            buildList()
            scrollFrame:SetScrollChild(listFrame)
        end
    end)

    btnTryOn:HookScript("OnClick", function()
        local savedLooks = _G["TransmorpherSavedLooks"]
        local id = listFrame.buttons[listFrame:GetSelected()]:GetID()
        for index, slotName in pairs(slotOrder) do
            local itemId = savedLooks[id].items[index]
            if itemId ~= nil and itemId ~= 0 then
                mainFrame.slots[slotName]:SetItem(itemId)
            else mainFrame.slots[slotName]:RemoveItem() end
        end
    end)

    -- Apply saved look as morph
    btnApplyLook:HookScript("OnClick", function()
        if not IsMorpherReady() then
            SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: |cffff0000DLL not loaded!|r")
            return
        end
        local savedLooks = _G["TransmorpherSavedLooks"]
        local id = listFrame.buttons[listFrame:GetSelected()]:GetID()
        for index, slotName in pairs(slotOrder) do
            local itemId = savedLooks[id].items[index]
            if itemId ~= nil and itemId ~= 0 and slotToEquipSlotId[slotName] then
                    SendMorphCommand("ITEM:" .. slotToEquipSlotId[slotName] .. ":" .. itemId)
            end
        end
        SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Look applied as morph!")
    end)

    StaticPopupDialogs["Transmorpher_SAVE_DIALOG"] = {
        text = "|cffffd700Enter look name:",
        button1 = "Save", button2 = CLOSE,
        timeout = 0, whileDead = true, hasEditBox = true, preferredIndex = 3,
        OnAccept = function(self)
            local lookName = self.editBox:GetText()
            if lookName ~= "" then
                table.insert(_G["TransmorpherSavedLooks"], {["name"] = lookName, ["items"] = slots2ItemList()})
                listFrame:AddItem(lookName)
                SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Look '"..lookName.."' saved!")
            end
        end,
        OnShow = function(self) self.editBox:SetText("") end,
    }

    btnSaveAs:HookScript("OnClick", function() StaticPopup_Show("Transmorpher_SAVE_DIALOG") end)

    btnSave:HookScript("OnClick", function()
        if listFrame:GetSelected() then
            local id = listFrame.buttons[listFrame:GetSelected()]:GetID()
            _G["TransmorpherSavedLooks"][id].items = slots2ItemList()
            SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Look updated!")
        end
    end)

    btnRemove:HookScript("OnClick", function()
        if listFrame:GetSelected() then
            local id = listFrame.buttons[listFrame:GetSelected()]:GetID()
            table.remove(_G["TransmorpherSavedLooks"], id)
            listFrame:RemoveItem(listFrame:GetSelected())
            btnTryOn:Disable() btnRemove:Disable() btnSave:Disable() btnApplyLook:Disable()
            UpdateLookPreview(nil, nil)
        end
    end)

    -- Also update preview after saving/overwriting
    btnSave:HookScript("OnClick", function()
        if listFrame:GetSelected() and _G["TransmorpherSavedLooks"] then
            local id = listFrame.buttons[listFrame:GetSelected()]:GetID()
            local look = _G["TransmorpherSavedLooks"][id]
            if look then UpdateLookPreview(look.items, look.name) end
        end
    end)
end

---------------- MORPH TAB (Race/Display ID) ----------------

local function UpdatePreviewModel()
    local f = CreateFrame("Frame")
    f.timer = 0.2
    f:SetScript("OnUpdate", function(self, elapsed)
        self.timer = self.timer - elapsed
        if self.timer <= 0 then
            if mainFrame and mainFrame.dressingRoom then
                mainFrame.dressingRoom:SetUnit("player")
            end
            self:Hide()
            self:SetScript("OnUpdate", nil)
        end
    end)
end

do
    local actualMorphTab = mainFrame.tabs.morph
    local scrollFrame = CreateFrame("ScrollFrame", "$parentScrollFrame", actualMorphTab, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 4)
    
    local morphTab = CreateFrame("Frame", "$parentContent", scrollFrame)
    morphTab:SetSize(actualMorphTab:GetWidth() - 30, 1100) -- extra height for all morph sections
    scrollFrame:SetScrollChild(morphTab)

    -- Update size dynamically just in case
    morphTab:SetScript("OnSizeChanged", function(self, width, height)
        self:SetWidth(width)
    end)

    local yOff = -5

    -- Title
    local titleText = morphTab:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOPLEFT", 10, yOff)
    titleText:SetText("|cffF5C842Character Morph|r")
    yOff = yOff - 22

    local subtitleText = morphTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subtitleText:SetPoint("TOPLEFT", 10, yOff)
    subtitleText:SetText("|cff998866Change your character model. Client-side only.|r")
    yOff = yOff - 20

    -- Race display IDs: [race][gender] = displayId
    -- gender: 1 = neutral/unknown, 2 = male, 3 = female
    local raceDisplayIds = {
        ["Human"]      = { [2] = 49,    [3] = 50 },
        ["Orc"]        = { [2] = 51,    [3] = 52 },
        ["Dwarf"]      = { [2] = 53,    [3] = 54 },
        ["Night Elf"]  = { [2] = 55,    [3] = 56 },
        ["Undead"]     = { [2] = 57,    [3] = 58 },
        ["Tauren"]     = { [2] = 59,    [3] = 60 },
        ["Gnome"]      = { [2] = 1563,  [3] = 1564 },
        ["Troll"]      = { [2] = 1478,  [3] = 1479 },
        ["Blood Elf"]  = { [2] = 15476, [3] = 15475 },
        ["Draenei"]    = { [2] = 16125, [3] = 16126 },
    }
    local raceOrder = {"Human", "Orc", "Dwarf", "Night Elf", "Undead", "Tauren", "Gnome", "Troll", "Blood Elf", "Draenei"}
    local raceIcons = {
        ["Human"]      = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races",
        ["Orc"]        = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races",
        ["Dwarf"]      = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races",
        ["Night Elf"]  = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races",
        ["Undead"]     = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races",
        ["Tauren"]     = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races",
        ["Gnome"]      = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races",
        ["Troll"]      = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races",
        ["Blood Elf"]  = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races",
        ["Draenei"]    = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races",
    }

    -- Section: Race Morph
    local raceLabel = morphTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    raceLabel:SetPoint("TOPLEFT", 10, yOff)
    raceLabel:SetText("|cffF5C842Race Morph|r")
    yOff = yOff - 20

    local btnWidth = 120
    local btnHeight = 22
    local col = 0
    local startY = yOff

    for i, raceName in ipairs(raceOrder) do
        local ids = raceDisplayIds[raceName]
        local safeRaceName = raceName:gsub("%s+", "")

        -- Male button
        local btnM = CreateFrame("Button", "$parentRace"..safeRaceName.."M", morphTab, "UIPanelButtonTemplate2")
        btnM:SetSize(btnWidth, btnHeight)
        local xM = 10 + col * (btnWidth + 5)
        btnM:SetPoint("TOPLEFT", xM, yOff - (math.ceil(i/2) - 1) * (btnHeight + 3))
        btnM:SetText(raceName .. " M")
        btnM:SetScript("OnClick", function()
            if IsMorpherReady() then
                SendMorphCommand("MORPH:" .. ids[2])
                UpdatePreviewModel()
                SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Morphed to " .. raceName .. " Male (" .. ids[2] .. ")")
            end
            PlaySound("gsTitleOptionOK")
        end)
        btnM:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(raceName .. " Male")
            GameTooltip:AddLine("Display ID: " .. ids[2], 1, 1, 1)
            GameTooltip:Show()
        end)
        btnM:SetScript("OnLeave", function() GameTooltip:Hide() end)

        -- Female button
        local btnF = CreateFrame("Button", "$parentRace"..safeRaceName.."F", morphTab, "UIPanelButtonTemplate2")
        btnF:SetSize(btnWidth, btnHeight)
        local xF = 10 + (col + 1) * (btnWidth + 5)
        btnF:SetPoint("TOPLEFT", xF, yOff - (math.ceil(i/2) - 1) * (btnHeight + 3))
        btnF:SetText(raceName .. " F")
        btnF:SetScript("OnClick", function()
            if IsMorpherReady() then
                SendMorphCommand("MORPH:" .. ids[3])
                UpdatePreviewModel()
                SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Morphed to " .. raceName .. " Female (" .. ids[3] .. ")")
            end
            PlaySound("gsTitleOptionOK")
        end)
        btnF:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(raceName .. " Female")
            GameTooltip:AddLine("Display ID: " .. ids[3], 1, 1, 1)
            GameTooltip:Show()
        end)
        btnF:SetScript("OnLeave", function() GameTooltip:Hide() end)

        if i % 2 == 0 then col = 0 else col = 2 end
    end

    local raceSectionHeight = math.ceil(#raceOrder / 2) * (btnHeight + 3) + 10
    yOff = yOff - raceSectionHeight - 10

    -- Separator
    local sep1 = morphTab:CreateTexture(nil, "ARTWORK")
    sep1:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    sep1:SetTexCoord(0.81, 0.94, 0.5, 1)
    sep1:SetPoint("TOPLEFT", 10, yOff)
    sep1:SetPoint("RIGHT", -10, 0)
    sep1:SetHeight(8)
    sep1:SetVertexColor(0.80, 0.65, 0.22)
    yOff = yOff - 14

    -- Section: Custom Display ID (with creature search)
    local customLabel = morphTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    customLabel:SetPoint("TOPLEFT", 10, yOff)
    customLabel:SetText("|cffF5C842Custom Display ID|r")
    yOff = yOff - 18

    local customDesc = morphTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    customDesc:SetPoint("TOPLEFT", 10, yOff)
    customDesc:SetText("|cff998866Search by creature name or enter a display ID directly:|r")
    yOff = yOff - 22

    -- Search bar container (modern dark box with golden accent)
    local searchContainer = CreateFrame("Frame", nil, morphTab)
    searchContainer:SetSize(370, 28)
    searchContainer:SetPoint("TOPLEFT", 10, yOff)
    searchContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    searchContainer:SetBackdropColor(0.06, 0.05, 0.03, 0.95)
    searchContainer:SetBackdropBorderColor(0.60, 0.50, 0.18, 0.8)

    local searchIcon = searchContainer:CreateTexture(nil, "OVERLAY")
    searchIcon:SetSize(14, 14)
    searchIcon:SetPoint("LEFT", 6, 0)
    searchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
    searchIcon:SetVertexColor(0.80, 0.65, 0.22)

    -- Search/ID input (accepts both text and numbers)
    local editBox = CreateFrame("EditBox", "$parentMorphIdInput", searchContainer)
    editBox:SetSize(310, 18)
    editBox:SetPoint("LEFT", searchIcon, "RIGHT", 4, 0)
    editBox:SetAutoFocus(false)
    editBox:SetNumeric(false)
    editBox:SetMaxLetters(40)
    editBox:SetFont("Fonts\\FRIZQT__.TTF", 11)
    editBox:SetTextColor(0.95, 0.88, 0.65)

    local editHint = editBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    editHint:SetPoint("LEFT", 2, 0)
    editHint:SetText("Name or display ID...")

    -- Clear button
    local editClear = CreateFrame("Button", nil, searchContainer)
    editClear:SetSize(14, 14)
    editClear:SetPoint("RIGHT", -4, 0)
    editClear:SetNormalTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
    editClear:SetAlpha(0.5)
    editClear:Hide()
    editClear:SetScript("OnEnter", function(self) self:SetAlpha(1) end)
    editClear:SetScript("OnLeave", function(self) self:SetAlpha(0.5) end)

    -- Selected display from search results
    local selectedSearchID = nil
    local selectedSearchName = nil

    -- Search results dropdown (created BEFORE handlers that reference it)
    local searchDropBg = CreateFrame("Frame", "$parentMorphSearchDrop", actualMorphTab)
    searchDropBg:SetPoint("TOPLEFT", searchContainer, "BOTTOMLEFT", 0, 2)
    searchDropBg:SetSize(370, 1)
    searchDropBg:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    searchDropBg:SetBackdropColor(0.06, 0.05, 0.03, 0.97)
    searchDropBg:SetBackdropBorderColor(0.80, 0.65, 0.22, 0.9)
    searchDropBg:SetFrameStrata("DIALOG")
    searchDropBg:Hide()

    -- Now set up handlers that use searchDropBg
    editBox:SetScript("OnEscapePressed", function(self)
        searchDropBg:Hide()
        self:ClearFocus()
    end)
    editBox:SetScript("OnEditFocusGained", function() editHint:Hide() end)
    editBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then editHint:Show(); editClear:Hide() end
        local hideTimer = CreateFrame("Frame")
        hideTimer.elapsed = 0
        hideTimer:SetScript("OnUpdate", function(f, dt)
            f.elapsed = f.elapsed + dt
            if f.elapsed >= 0.2 then
                f:Hide()
                f:SetScript("OnUpdate", nil)
                if not editBox:HasFocus() then searchDropBg:Hide() end
            end
        end)
    end)
    editClear:SetScript("OnClick", function()
        editBox:SetText("")
        editBox:ClearFocus()
        editHint:Show()
        editClear:Hide()
        searchDropBg:Hide()
        selectedSearchID = nil
        selectedSearchName = nil
    end)

    local btnApplyCustom = CreateFrame("Button", "$parentBtnApplyCustom", morphTab, "UIPanelButtonTemplate2")
    btnApplyCustom:SetSize(90, 22)
    btnApplyCustom:SetPoint("LEFT", searchContainer, "RIGHT", 8, 0)
    btnApplyCustom:SetText("|cffF5C842Apply|r")

    local searchDropScroll = CreateFrame("ScrollFrame", "$parentMorphSearchDropScroll", searchDropBg, "UIPanelScrollFrameTemplate")
    searchDropScroll:SetPoint("TOPLEFT", 4, -4)
    searchDropScroll:SetPoint("BOTTOMRIGHT", -22, 4)

    local searchDropContent = CreateFrame("Frame", "$parentMorphSearchDropContent", searchDropScroll)
    searchDropContent:SetSize(searchDropScroll:GetWidth(), 1)
    searchDropScroll:SetScrollChild(searchDropContent)

    local SEARCH_ROW_H = 20
    local MAX_SEARCH_ROWS = 10
    local searchResultButtons = {}

    -- Pre-build sorted creature list for morph search (reuse combat pet one if exists, else build own)
    local morphCreatureSorted = nil
    local function GetMorphCreatureSorted()
        if morphCreatureSorted then return morphCreatureSorted end
        morphCreatureSorted = {}
        local db = ns.creatureDisplayDB
        if not db then return morphCreatureSorted end
        for did, name in pairs(db) do
            table.insert(morphCreatureSorted, { did = did, name = name, nameLower = name:lower() })
        end
        table.sort(morphCreatureSorted, function(a, b) return a.name < b.name end)
        return morphCreatureSorted
    end

    local function ShowSearchResults(query)
        -- Clear old
        for _, b in ipairs(searchResultButtons) do b:Hide() end
        searchResultButtons = {}
        selectedSearchID = nil
        selectedSearchName = nil

        if not query or #query < 2 then
            searchDropBg:Hide()
            return
        end

        local q = query:lower()
        local results = {}
        local sorted = GetMorphCreatureSorted()
        local count = 0

        -- Check if it's a pure number (display ID search)
        local isNumericQuery = tonumber(query) ~= nil

        for _, entry in ipairs(sorted) do
            local match = false
            if isNumericQuery then
                match = tostring(entry.did):find(q, 1, true) ~= nil
            else
                match = entry.nameLower:find(q, 1, true) ~= nil
            end
            if match then
                table.insert(results, entry)
                count = count + 1
                if count >= MAX_SEARCH_ROWS * 5 then break end -- gather extra for scrolling
            end
        end

        if #results == 0 then
            searchDropBg:Hide()
            return
        end

        local visibleRows = math.min(#results, MAX_SEARCH_ROWS)
        local dropH = visibleRows * (SEARCH_ROW_H + 1) + 10
        searchDropBg:SetHeight(dropH)
        searchDropBg:Show()

        local bY = 0
        for idx, entry in ipairs(results) do
            local row = CreateFrame("Button", nil, searchDropContent)
            row:SetSize(searchDropContent:GetWidth() - 4, SEARCH_ROW_H)
            row:SetPoint("TOPLEFT", 2, -bY)

            local rowBg = row:CreateTexture(nil, "BACKGROUND")
            rowBg:SetAllPoints()
            if idx % 2 == 0 then
                rowBg:SetTexture(1, 1, 1, 0.03)
            else
                rowBg:SetTexture(0, 0, 0, 0)
            end

            local nameStr = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            nameStr:SetPoint("LEFT", 6, 0)
            nameStr:SetText("|cffffd700" .. entry.name .. "|r")
            nameStr:SetWidth(230)
            nameStr:SetJustifyH("LEFT")

            local idStr = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            idStr:SetPoint("RIGHT", -6, 0)
            idStr:SetText("|cff888888" .. entry.did .. "|r")

            row:SetScript("OnClick", function()
                selectedSearchID = entry.did
                selectedSearchName = entry.name
                editBox:SetText(entry.name .. " (" .. entry.did .. ")")
                editBox:SetCursorPosition(0)
                searchDropBg:Hide()
                editBox:ClearFocus()
            end)

            row:SetScript("OnEnter", function()
                rowBg:SetTexture(0.6, 0.48, 0.15, 0.25)
                GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
                GameTooltip:AddLine(entry.name)
                GameTooltip:AddLine("Display ID: " .. entry.did, 1, 1, 1)
                GameTooltip:AddLine("Click to select", 0.5, 0.5, 0.5)
                GameTooltip:Show()
            end)

            row:SetScript("OnLeave", function()
                if idx % 2 == 0 then
                    rowBg:SetTexture(1, 1, 1, 0.03)
                else
                    rowBg:SetTexture(0, 0, 0, 0)
                end
                GameTooltip:Hide()
            end)

            table.insert(searchResultButtons, row)
            bY = bY + SEARCH_ROW_H + 1
        end

        searchDropContent:SetHeight(math.max(1, bY))
    end

    -- Search debounce timer
    local morphSearchTimer = CreateFrame("Frame")
    morphSearchTimer:Hide()
    morphSearchTimer.elapsed = 0
    morphSearchTimer:SetScript("OnUpdate", function(self, dt)
        self.elapsed = self.elapsed + dt
        if self.elapsed >= 0.3 then
            self:Hide()
            local text = editBox:GetText()
            -- Don't search if user selected a result (text contains " (ID)")
            if text:find("%(", 1, true) then return end
            ShowSearchResults(text)
        end
    end)

    editBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            selectedSearchID = nil
            selectedSearchName = nil
            morphSearchTimer.elapsed = 0
            morphSearchTimer:Show()
            if self:GetText() ~= "" then editClear:Show() else editClear:Hide() end
        end
    end)

    editBox:SetScript("OnEnterPressed", function(self)
        -- If a search result was selected, apply it
        if selectedSearchID then
            if IsMorpherReady() then
                SendMorphCommand("MORPH:" .. selectedSearchID)
                UpdatePreviewModel()
                SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Morphed to " .. (selectedSearchName or "creature") .. " (" .. selectedSearchID .. ")")
            end
        else
            -- Try as numeric ID
            local text = self:GetText()
            -- Extract number from text like "Name (12345)"
            local id = tonumber(text:match("%((%d+)%)")) or tonumber(text)
            if id and id > 0 and IsMorpherReady() then
                SendMorphCommand("MORPH:" .. id)
                UpdatePreviewModel()
                SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Morphed to display ID " .. id)
            end
        end
        searchDropBg:Hide()
        self:ClearFocus()
    end)

    -- Apply button
    btnApplyCustom:SetScript("OnClick", function()
        if selectedSearchID then
            if IsMorpherReady() then
                SendMorphCommand("MORPH:" .. selectedSearchID)
                UpdatePreviewModel()
                SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Morphed to " .. (selectedSearchName or "creature") .. " (" .. selectedSearchID .. ")")
                PlaySound("gsTitleOptionOK")
            else
                SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: |cffff0000DLL not loaded!|r")
            end
        else
            local text = editBox:GetText()
            local id = tonumber(text:match("%((%d+)%)")) or tonumber(text)
            if id and id > 0 and IsMorpherReady() then
                SendMorphCommand("MORPH:" .. id)
                UpdatePreviewModel()
                SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Morphed to display ID " .. id)
                PlaySound("gsTitleOptionOK")
            else
                SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Search for a creature or enter a valid display ID.")
            end
        end
        searchDropBg:Hide()
    end)

    -- Close dropdown when clicking elsewhere
    hooksecurefunc("CloseDropDownMenus", function() searchDropBg:Hide() end)

    yOff = yOff - 30

    -- Size (Scale) section
    local sizeLabel = morphTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sizeLabel:SetPoint("TOPLEFT", 10, yOff)
    sizeLabel:SetText("|cffF5C842Character Size|r")
    yOff = yOff - 20

    local sizeEditBox = CreateFrame("EditBox", "$parentMorphSizeInput", morphTab, "InputBoxTemplate")
    sizeEditBox:SetSize(60, 20)
    sizeEditBox:SetPoint("TOPLEFT", 15, yOff)
    sizeEditBox:SetAutoFocus(false)
    sizeEditBox:SetNumeric(false) -- Allow decimals
    sizeEditBox:SetMaxLetters(4)
    sizeEditBox:SetText("1.0")
    sizeEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    local btnApplySize = CreateFrame("Button", "$parentBtnApplySize", morphTab, "UIPanelButtonTemplate2")
    btnApplySize:SetSize(90, 22)
    btnApplySize:SetPoint("LEFT", sizeEditBox, "RIGHT", 10, 0)
    btnApplySize:SetText("|cffF5C842Apply Size|r")
    btnApplySize:SetScript("OnClick", function()
        local scale = tonumber(sizeEditBox:GetText())
        if scale and scale > 0.1 and scale < 10.0 and IsMorpherReady() then
            SendMorphCommand("SCALE:" .. scale)
            SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Scaled character to " .. scale)
            PlaySound("gsTitleOptionOK")
        else
            SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Enter a valid scale (0.1 to 10.0).")
        end
    end)
    
    yOff = yOff - 40

    -- ============================================================
    -- Saved Morph Favorites
    -- ============================================================
    local favSep = morphTab:CreateTexture(nil, "ARTWORK")
    favSep:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    favSep:SetTexCoord(0.81, 0.94, 0.5, 1)
    favSep:SetPoint("TOPLEFT", 10, yOff)
    favSep:SetPoint("RIGHT", -10, 0)
    favSep:SetHeight(8)
    favSep:SetVertexColor(0.80, 0.65, 0.22)
    yOff = yOff - 14

    local favLabel = morphTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    favLabel:SetPoint("TOPLEFT", 10, yOff)
    favLabel:SetText("|cffF5C842Saved Morphs|r")
    yOff = yOff - 18

    local favDesc = morphTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    favDesc:SetPoint("TOPLEFT", 10, yOff)
    favDesc:SetText("|cff998866Save display IDs with a name for quick access. Use the search above to find IDs.|r")
    yOff = yOff - 18

    -- Save controls: [Name input] [ID input] [Save button]
    local favNameInput = CreateFrame("EditBox", "$parentFavNameInput", morphTab, "InputBoxTemplate")
    favNameInput:SetSize(130, 20)
    favNameInput:SetPoint("TOPLEFT", 15, yOff)
    favNameInput:SetAutoFocus(false)
    favNameInput:SetMaxLetters(24)
    favNameInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    local favNameHint = favNameInput:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    favNameHint:SetPoint("LEFT", 4, 0)
    favNameHint:SetText("Name")
    favNameInput:SetScript("OnEditFocusGained", function() favNameHint:Hide() end)
    favNameInput:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then favNameHint:Show() end
    end)

    local favIdInput = CreateFrame("EditBox", "$parentFavIdInput", morphTab, "InputBoxTemplate")
    favIdInput:SetSize(70, 20)
    favIdInput:SetPoint("LEFT", favNameInput, "RIGHT", 8, 0)
    favIdInput:SetAutoFocus(false)
    favIdInput:SetNumeric(true)
    favIdInput:SetMaxLetters(6)
    favIdInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    local favIdHint = favIdInput:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    favIdHint:SetPoint("LEFT", 4, 0)
    favIdHint:SetText("ID")
    favIdInput:SetScript("OnEditFocusGained", function() favIdHint:Hide() end)
    favIdInput:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then favIdHint:Show() end
    end)

    local btnFavSave = CreateFrame("Button", "$parentBtnFavSave", morphTab, "UIPanelButtonTemplate2")
    btnFavSave:SetSize(60, 20)
    btnFavSave:SetPoint("LEFT", favIdInput, "RIGHT", 8, 0)
    btnFavSave:SetText("|cffF5C842Save|r")

    local btnFavRemove = CreateFrame("Button", "$parentBtnFavRemove", morphTab, "UIPanelButtonTemplate2")
    btnFavRemove:SetSize(70, 20)
    btnFavRemove:SetPoint("LEFT", btnFavSave, "RIGHT", 4, 0)
    btnFavRemove:SetText("Remove")
    btnFavRemove:Disable()

    yOff = yOff - 26

    -- Favorites list area (scrollable)
    local favListBg = CreateFrame("Frame", "$parentFavListBg", morphTab)
    favListBg:SetPoint("TOPLEFT", 10, yOff)
    favListBg:SetSize(480, 100)
    favListBg:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    favListBg:SetBackdropColor(0.04, 0.03, 0.03, 0.9)
    favListBg:SetBackdropBorderColor(0.80, 0.65, 0.22, 0.85)

    local favScroll = CreateFrame("ScrollFrame", "$parentFavScroll", favListBg, "UIPanelScrollFrameTemplate")
    favScroll:SetPoint("TOPLEFT", 4, -4)
    favScroll:SetPoint("BOTTOMRIGHT", -22, 4)

    local favContent = CreateFrame("Frame", "$parentFavContent", favScroll)
    favContent:SetSize(favScroll:GetWidth(), 1)
    favScroll:SetScrollChild(favContent)

    local favButtons = {}
    local favSelectedIdx = nil

    local function BuildFavButtons()
        -- Clear old buttons
        for _, b in ipairs(favButtons) do b:Hide() end
        favButtons = {}
        favSelectedIdx = nil
        btnFavRemove:Disable()

        if not _G["TransmorpherMorphFavorites"] then _G["TransmorpherMorphFavorites"] = {} end
        local favs = _G["TransmorpherMorphFavorites"]

        local bY = 0
        for idx, fav in ipairs(favs) do
            local row = CreateFrame("Button", nil, favContent)
            row:SetSize(favContent:GetWidth() - 4, 20)
            row:SetPoint("TOPLEFT", 2, -bY)

            local rowBg = row:CreateTexture(nil, "BACKGROUND")
            rowBg:SetAllPoints()
            rowBg:SetTexture(0, 0, 0, 0)

            local nameStr = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            nameStr:SetPoint("LEFT", 4, 0)
            nameStr:SetText("|cffffd700" .. fav.name .. "|r")
            nameStr:SetWidth(200)
            nameStr:SetJustifyH("LEFT")

            local idStr = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            idStr:SetPoint("LEFT", nameStr, "RIGHT", 8, 0)
            idStr:SetText("|cff8a7d6aID: " .. fav.id .. "|r")

            local useBtn = CreateFrame("Button", "TransmorpherFavUseBtn"..idx, row, "UIPanelButtonTemplate2")
            useBtn:SetSize(50, 18)
            useBtn:SetPoint("RIGHT", -2, 0)
            useBtn:SetText("|cffF5C842Use|r")
            useBtn:SetScript("OnClick", function()
                if IsMorpherReady() then
                    SendMorphCommand("MORPH:" .. fav.id)
                    UpdatePreviewModel()
                    SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Morphed to " .. fav.name .. " (" .. fav.id .. ")")
                end
                PlaySound("gsTitleOptionOK")
            end)

            -- Selection highlight
            row:SetScript("OnClick", function()
                -- Deselect previous
                if favSelectedIdx and favButtons[favSelectedIdx] then
                    favButtons[favSelectedIdx].bg:SetTexture(0, 0, 0, 0)
                end
                favSelectedIdx = idx
                rowBg:SetTexture(0.6, 0.48, 0.15, 0.3)
                btnFavRemove:Enable()
            end)
            row:SetScript("OnEnter", function()
                if favSelectedIdx ~= idx then rowBg:SetTexture(1, 1, 1, 0.05) end
                GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
                GameTooltip:AddLine(fav.name)
                GameTooltip:AddLine("Display ID: " .. fav.id, 1, 1, 1)
                GameTooltip:AddLine("Click to select, Use to morph", 0.5, 0.5, 0.5)
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function()
                if favSelectedIdx ~= idx then rowBg:SetTexture(0, 0, 0, 0) end
                GameTooltip:Hide()
            end)

            row.bg = rowBg
            table.insert(favButtons, row)
            bY = bY + 21
        end

        favContent:SetHeight(math.max(1, bY))
    end

    -- Save favorite
    btnFavSave:SetScript("OnClick", function()
        local name = favNameInput:GetText()
        local id = tonumber(favIdInput:GetText())
        if not name or name == "" then
            SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Enter a name for the morph.")
            return
        end
        if not id or id <= 0 then
            SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Enter a valid display ID.")
            return
        end
        if not _G["TransmorpherMorphFavorites"] then _G["TransmorpherMorphFavorites"] = {} end
        table.insert(_G["TransmorpherMorphFavorites"], { name = name, id = id })
        favNameInput:SetText("") favIdInput:SetText("")
        favNameHint:Show() favIdHint:Show()
        favNameInput:ClearFocus() favIdInput:ClearFocus()
        BuildFavButtons()
        SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Saved morph '" .. name .. "' (ID: " .. id .. ")")
        PlaySound("gsTitleOptionOK")
    end)

    -- Remove favorite
    btnFavRemove:SetScript("OnClick", function()
        if favSelectedIdx and _G["TransmorpherMorphFavorites"] then
            local fav = _G["TransmorpherMorphFavorites"][favSelectedIdx]
            if fav then
                table.remove(_G["TransmorpherMorphFavorites"], favSelectedIdx)
                SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Removed '" .. fav.name .. "'")
            end
            BuildFavButtons()
            PlaySound("gsTitleOptionOK")
        end
    end)

    -- Build on first show
    morphTab:HookScript("OnShow", function() BuildFavButtons() end)

    yOff = yOff - 110

    -- Separator before popular creatures
    local sep2 = morphTab:CreateTexture(nil, "ARTWORK")
    sep2:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    sep2:SetTexCoord(0.81, 0.94, 0.5, 1)
    sep2:SetPoint("TOPLEFT", 10, yOff)
    sep2:SetPoint("RIGHT", -10, 0)
    sep2:SetHeight(8)
    sep2:SetVertexColor(0.80, 0.65, 0.22)
    yOff = yOff - 14

    -- Current display info
    local infoLabel = morphTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoLabel:SetPoint("TOPLEFT", 10, yOff)
    infoLabel:SetText("")
    yOff = yOff - 16

    -- Popular creature morphs section
    local creaturesLabel = morphTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    creaturesLabel:SetPoint("TOPLEFT", 10, yOff)
    creaturesLabel:SetText("|cffF5C842Popular Creatures|r")
    yOff = yOff - 20

    local popularCreatures = {
        { name = "Lich King",     id = 22234 },
        { name = "Illidan",       id = 21135 },
        { name = "Sylvanas",      id = 28213 },
        { name = "Alexstrasza",   id = 28227 },
        
        { name = "Ragnaros",      id = 11121 },
        { name = "Brann Bronzebeard",        id = 22266 },
        { name = "Malygos",       id = 26752 },
        { name = "Tuskarr",    id = 24685 },
        
        { name = "Kel'Thuzad",    id = 15945 },
        { name = "Yogg-Saron",    id = 28817 },
        { name = "Kael'thas",     id = 20023 },
        { name = "Lady Vashj",    id = 20748 },
        
        { name = "Nefarian",      id = 11380 },
        { name = "Onyxia",        id = 8570  },
        { name = "Arthas",        id = 24949 },
        { name = "Uther",         id = 16929 },
        
        { name = "Evil Arthas",           id = 22235 },
        { name = "Velen",        id = 23749 },
        { name = "Dark Valkier",   id = 25517 },
        { name = "Penguin",          id = 24698 },
    }

    col = 0
    local creatureRow = 0
    for i, creature in ipairs(popularCreatures) do
        local btn = CreateFrame("Button", "$parentCreature"..i, morphTab, "UIPanelButtonTemplate2")
        btn:SetSize(btnWidth, btnHeight)
        btn:SetPoint("TOPLEFT", 10 + col * (btnWidth + 5), yOff - creatureRow * (btnHeight + 3))
        btn:SetText(creature.name)
        btn:SetScript("OnClick", function()
            if IsMorpherReady() then
                SendMorphCommand("MORPH:" .. creature.id)
                UpdatePreviewModel()
                SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Morphed to " .. creature.name .. " (" .. creature.id .. ")")
            end
            PlaySound("gsTitleOptionOK")
        end)
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(creature.name)
            GameTooltip:AddLine("Display ID: " .. creature.id, 1, 1, 1)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        col = col + 1
        if col >= 4 then col = 0; creatureRow = creatureRow + 1 end
    end

    local creatureSectionHeight = math.ceil(#popularCreatures / 4) * (btnHeight + 3) + 10
    yOff = yOff - creatureSectionHeight - 10

    -- Reset morph button (big, at bottom)
    local btnResetMorph = CreateFrame("Button", "$parentBtnResetModel", morphTab, "UIPanelButtonTemplate2")
    btnResetMorph:SetSize(200, 28)
    btnResetMorph:SetPoint("TOPLEFT", 10, yOff)
    btnResetMorph:SetText("|cffD4A44EReset Character Model|r")
    btnResetMorph:SetScript("OnClick", function()
        if IsMorpherReady() then
            SendMorphCommand("RESET:ALL")
            mainFrame.dressingRoom:SetUnit("player")
            SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Character model reset!")
        end
        PlaySound("gsTitleOptionOK")
    end)

    -- Update display info on show
    morphTab:SetScript("OnShow", function()
        infoLabel:SetText("|cff8a7d6aDisplay info not available in stealth mode.|r")
    end)
end

---------------- MOUNTS TAB ----------------

do
    local mountTab = mainFrame.tabs.mounts
    local ROW_HEIGHT = 32

    -- Search bar container
    local searchContainer = CreateFrame("Frame", nil, mountTab)
    searchContainer:SetPoint("TOPLEFT", 6, -6)
    searchContainer:SetPoint("RIGHT", -6, 0)
    searchContainer:SetHeight(26)
    searchContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    searchContainer:SetBackdropColor(0.06, 0.05, 0.03, 0.95)
    searchContainer:SetBackdropBorderColor(0.60, 0.50, 0.18, 0.8)

    local searchIcon = searchContainer:CreateTexture(nil, "OVERLAY")
    searchIcon:SetSize(14, 14)
    searchIcon:SetPoint("LEFT", 6, 0)
    searchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
    searchIcon:SetVertexColor(0.80, 0.65, 0.22)

    local searchBox = CreateFrame("EditBox", "$parentMountSearch", searchContainer)
    searchBox:SetSize(480, 18)
    searchBox:SetPoint("LEFT", searchIcon, "RIGHT", 4, 0)
    searchBox:SetPoint("RIGHT", -24, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(40)
    searchBox:SetFont("Fonts\\FRIZQT__.TTF", 11)
    searchBox:SetTextColor(0.95, 0.88, 0.65)
    searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    local searchHint = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    searchHint:SetPoint("LEFT", 2, 0)
    searchHint:SetText("Search mounts...")
    searchBox:SetScript("OnEditFocusGained", function() searchHint:Hide() end)
    searchBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then searchHint:Show() end
    end)

    local searchClear = CreateFrame("Button", nil, searchContainer)
    searchClear:SetSize(14, 14)
    searchClear:SetPoint("RIGHT", -4, 0)
    searchClear:SetNormalTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
    searchClear:SetAlpha(0.5)
    searchClear:Hide()
    searchClear:SetScript("OnEnter", function(self) self:SetAlpha(1) end)
    searchClear:SetScript("OnLeave", function(self) self:SetAlpha(0.5) end)
    searchClear:SetScript("OnClick", function()
        searchBox:SetText("")
        searchBox:ClearFocus()
        searchHint:Show()
        searchClear:Hide()
    end)

    -- List background (full width)
    local listBg = CreateFrame("Frame", "$parentMountListBg", mountTab)
    listBg:SetPoint("TOPLEFT", 6, -32)
    listBg:SetPoint("BOTTOMRIGHT", -6, 38)
    listBg:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    listBg:SetBackdropColor(0.04, 0.03, 0.03, 0.9)
    listBg:SetBackdropBorderColor(0.80, 0.65, 0.22, 0.85)

    local listScroll = CreateFrame("ScrollFrame", "$parentMountListScroll", listBg, "UIPanelScrollFrameTemplate")
    listScroll:SetPoint("TOPLEFT", 4, -4)
    listScroll:SetPoint("BOTTOMRIGHT", -22, 4)

    local listContent = CreateFrame("Frame", "$parentMountListContent", listScroll)
    listContent:SetSize(listScroll:GetWidth(), 1)
    listScroll:SetScrollChild(listContent)

    -- Bottom buttons
    local btnApplyMount = CreateFrame("Button", "$parentBtnApplyMount", mountTab, "UIPanelButtonTemplate2")
    btnApplyMount:SetSize(140, 26)
    btnApplyMount:SetPoint("BOTTOMLEFT", 10, 4)
    btnApplyMount:SetText("|cffF5C842Apply Mount Morph|r")
    btnApplyMount:Disable()

    local btnResetMount = CreateFrame("Button", "$parentBtnResetMount", mountTab, "UIPanelButtonTemplate2")
    btnResetMount:SetSize(120, 26)
    btnResetMount:SetPoint("LEFT", btnApplyMount, "RIGHT", 8, 0)
    btnResetMount:SetText("|cffD4A44EReset Mount|r")

    -- State
    local mountButtons = {}
    local mountSelectedIdx = nil
    local mountFilteredList = {}

    local function FilterMounts(query)
        mountFilteredList = {}
        local db = ns.mountsDB or {}
        if not query or query == "" then
            for i, entry in ipairs(db) do
                table.insert(mountFilteredList, { idx = i, name = entry[1], spellID = entry[2], displayID = entry[3], modelPath = entry[4] })
            end
        else
            local q = query:lower()
            for i, entry in ipairs(db) do
                if entry[1]:lower():find(q, 1, true) then
                    table.insert(mountFilteredList, { idx = i, name = entry[1], spellID = entry[2], displayID = entry[3], modelPath = entry[4] })
                end
            end
        end
        return mountFilteredList
    end

    local function BuildMountList()
        for _, b in ipairs(mountButtons) do b:Hide() end
        mountButtons = {}
        mountSelectedIdx = nil
        btnApplyMount:Disable()

        local bY = 0
        for idx, entry in ipairs(mountFilteredList) do
            local row = CreateFrame("Button", nil, listContent)
            row:SetSize(listContent:GetWidth() - 4, ROW_HEIGHT)
            row:SetPoint("TOPLEFT", 2, -bY)

            local rowBg = row:CreateTexture(nil, "BACKGROUND")
            rowBg:SetAllPoints()
            rowBg:SetTexture(0, 0, 0, 0)

            -- Icon
            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetSize(ROW_HEIGHT - 4, ROW_HEIGHT - 4)
            icon:SetPoint("LEFT", 4, 0)
            icon:SetTexture(GetSpellIcon(entry.spellID))
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            -- Icon border
            local iconBorder = row:CreateTexture(nil, "OVERLAY")
            iconBorder:SetSize(ROW_HEIGHT - 2, ROW_HEIGHT - 2)
            iconBorder:SetPoint("CENTER", icon, "CENTER", 0, 0)
            iconBorder:SetTexture("Interface\\Buttons\\UI-Quickslot2")
            iconBorder:SetTexCoord(0.2, 0.8, 0.2, 0.8)

            -- Name
            local nameStr = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameStr:SetPoint("LEFT", icon, "RIGHT", 8, 0)
            nameStr:SetText("|cffffd700" .. entry.name .. "|r")
            nameStr:SetJustifyH("LEFT")

            -- Display ID on the right
            local idStr = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            idStr:SetPoint("RIGHT", -8, 0)
            idStr:SetText("|cff6a6050" .. entry.displayID .. "|r")

            row:SetScript("OnClick", function()
                if mountSelectedIdx and mountButtons[mountSelectedIdx] then
                    mountButtons[mountSelectedIdx].bg:SetTexture(0, 0, 0, 0)
                end
                mountSelectedIdx = idx
                rowBg:SetTexture(0.6, 0.48, 0.15, 0.3)
                btnApplyMount:Enable()
            end)

            row:SetScript("OnEnter", function()
                if mountSelectedIdx ~= idx then rowBg:SetTexture(1, 1, 1, 0.05) end
                GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
                GameTooltip:AddLine(entry.name)
                GameTooltip:AddLine("Display ID: " .. entry.displayID, 1, 1, 1)
                if entry.spellID > 0 then
                    GameTooltip:AddLine("Spell ID: " .. entry.spellID, 0.7, 0.7, 0.7)
                end
                GameTooltip:AddLine("Click to select, then Apply", 0.5, 0.5, 0.5)
                GameTooltip:Show()
            end)

            row:SetScript("OnLeave", function()
                if mountSelectedIdx ~= idx then rowBg:SetTexture(0, 0, 0, 0) end
                GameTooltip:Hide()
            end)

            row.bg = rowBg
            table.insert(mountButtons, row)
            bY = bY + ROW_HEIGHT + 1
        end

        listContent:SetHeight(math.max(1, bY))
    end

    -- Search debounce
    local mountSearchTimer = CreateFrame("Frame")
    mountSearchTimer:Hide()
    mountSearchTimer.elapsed = 0
    mountSearchTimer:SetScript("OnUpdate", function(self, dt)
        self.elapsed = self.elapsed + dt
        if self.elapsed >= 0.3 then
            self:Hide()
            FilterMounts(searchBox:GetText())
            BuildMountList()
        end
    end)
    searchBox:SetScript("OnTextChanged", function(self)
        mountSearchTimer.elapsed = 0
        mountSearchTimer:Show()
        if self:GetText() ~= "" then searchClear:Show() else searchClear:Hide() end
    end)

    -- Apply mount morph
    btnApplyMount:SetScript("OnClick", function()
        if mountSelectedIdx and mountFilteredList[mountSelectedIdx] then
            local entry = mountFilteredList[mountSelectedIdx]
            if IsMorpherReady() then
                SendMorphCommand("MOUNT_MORPH:" .. entry.displayID)
                SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Mount morphed to " .. entry.name .. " (" .. entry.displayID .. ")")
            else
                SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: |cffff0000DLL not loaded!|r")
            end
            PlaySound("gsTitleOptionOK")
        end
    end)

    -- Reset mount morph
    btnResetMount:SetScript("OnClick", function()
        if IsMorpherReady() then
            SendMorphCommand("MOUNT_RESET")
            SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Mount appearance reset!")
        end
        PlaySound("gsTitleOptionOK")
    end)

    -- Initialize on show
    mountTab:SetScript("OnShow", function()
        if #mountFilteredList == 0 then
            FilterMounts("")
            BuildMountList()
        end
    end)
end

---------------- PETS TAB ----------------

do
    local petTab = mainFrame.tabs.pets
    local ROW_HEIGHT = 32

    -- Search bar container
    local searchContainer = CreateFrame("Frame", nil, petTab)
    searchContainer:SetPoint("TOPLEFT", 6, -6)
    searchContainer:SetPoint("RIGHT", -6, 0)
    searchContainer:SetHeight(26)
    searchContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    searchContainer:SetBackdropColor(0.06, 0.05, 0.03, 0.95)
    searchContainer:SetBackdropBorderColor(0.60, 0.50, 0.18, 0.8)

    local searchIcon = searchContainer:CreateTexture(nil, "OVERLAY")
    searchIcon:SetSize(14, 14)
    searchIcon:SetPoint("LEFT", 6, 0)
    searchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
    searchIcon:SetVertexColor(0.80, 0.65, 0.22)

    local searchBox = CreateFrame("EditBox", "$parentPetSearch", searchContainer)
    searchBox:SetSize(480, 18)
    searchBox:SetPoint("LEFT", searchIcon, "RIGHT", 4, 0)
    searchBox:SetPoint("RIGHT", -24, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(40)
    searchBox:SetFont("Fonts\\FRIZQT__.TTF", 11)
    searchBox:SetTextColor(0.95, 0.88, 0.65)
    searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    local searchHint = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    searchHint:SetPoint("LEFT", 2, 0)
    searchHint:SetText("Search pets...")
    searchBox:SetScript("OnEditFocusGained", function() searchHint:Hide() end)
    searchBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then searchHint:Show() end
    end)

    local searchClear = CreateFrame("Button", nil, searchContainer)
    searchClear:SetSize(14, 14)
    searchClear:SetPoint("RIGHT", -4, 0)
    searchClear:SetNormalTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
    searchClear:SetAlpha(0.5)
    searchClear:Hide()
    searchClear:SetScript("OnEnter", function(self) self:SetAlpha(1) end)
    searchClear:SetScript("OnLeave", function(self) self:SetAlpha(0.5) end)
    searchClear:SetScript("OnClick", function()
        searchBox:SetText("")
        searchBox:ClearFocus()
        searchHint:Show()
        searchClear:Hide()
    end)

    -- List background (full width)
    local listBg = CreateFrame("Frame", "$parentPetListBg", petTab)
    listBg:SetPoint("TOPLEFT", 6, -32)
    listBg:SetPoint("BOTTOMRIGHT", -6, 38)
    listBg:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    listBg:SetBackdropColor(0.04, 0.03, 0.03, 0.9)
    listBg:SetBackdropBorderColor(0.80, 0.65, 0.22, 0.85)

    local listScroll = CreateFrame("ScrollFrame", "$parentPetListScroll", listBg, "UIPanelScrollFrameTemplate")
    listScroll:SetPoint("TOPLEFT", 4, -4)
    listScroll:SetPoint("BOTTOMRIGHT", -22, 4)

    local listContent = CreateFrame("Frame", "$parentPetListContent", listScroll)
    listContent:SetSize(listScroll:GetWidth(), 1)
    listScroll:SetScrollChild(listContent)

    -- Bottom buttons
    local btnApplyPet = CreateFrame("Button", "$parentBtnApplyPet", petTab, "UIPanelButtonTemplate2")
    btnApplyPet:SetSize(130, 26)
    btnApplyPet:SetPoint("BOTTOMLEFT", 10, 4)
    btnApplyPet:SetText("|cffF5C842Apply Pet Morph|r")
    btnApplyPet:Disable()

    local btnResetPet = CreateFrame("Button", "$parentBtnResetPet", petTab, "UIPanelButtonTemplate2")
    btnResetPet:SetSize(110, 26)
    btnResetPet:SetPoint("LEFT", btnApplyPet, "RIGHT", 8, 0)
    btnResetPet:SetText("|cffD4A44EReset Pet|r")

    -- State
    local petButtons = {}
    local petSelectedIdx = nil
    local petFilteredList = {}

    local function FilterPets(query)
        petFilteredList = {}
        local db = ns.petsDB or {}
        if not query or query == "" then
            for i, entry in ipairs(db) do
                table.insert(petFilteredList, { idx = i, name = entry[1], spellID = entry[2], displayID = entry[3], modelPath = entry[4] })
            end
        else
            local q = query:lower()
            for i, entry in ipairs(db) do
                if entry[1]:lower():find(q, 1, true) then
                    table.insert(petFilteredList, { idx = i, name = entry[1], spellID = entry[2], displayID = entry[3], modelPath = entry[4] })
                end
            end
        end
        return petFilteredList
    end

    local function BuildPetList()
        for _, b in ipairs(petButtons) do b:Hide() end
        petButtons = {}
        petSelectedIdx = nil
        btnApplyPet:Disable()

        local bY = 0
        for idx, entry in ipairs(petFilteredList) do
            local row = CreateFrame("Button", nil, listContent)
            row:SetSize(listContent:GetWidth() - 4, ROW_HEIGHT)
            row:SetPoint("TOPLEFT", 2, -bY)

            local rowBg = row:CreateTexture(nil, "BACKGROUND")
            rowBg:SetAllPoints()
            rowBg:SetTexture(0, 0, 0, 0)

            -- Icon
            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetSize(ROW_HEIGHT - 4, ROW_HEIGHT - 4)
            icon:SetPoint("LEFT", 4, 0)
            icon:SetTexture(GetSpellIcon(entry.spellID))
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            -- Icon border
            local iconBorder = row:CreateTexture(nil, "OVERLAY")
            iconBorder:SetSize(ROW_HEIGHT - 2, ROW_HEIGHT - 2)
            iconBorder:SetPoint("CENTER", icon, "CENTER", 0, 0)
            iconBorder:SetTexture("Interface\\Buttons\\UI-Quickslot2")
            iconBorder:SetTexCoord(0.2, 0.8, 0.2, 0.8)

            -- Name
            local nameStr = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameStr:SetPoint("LEFT", icon, "RIGHT", 8, 0)
            nameStr:SetText("|cffffd700" .. entry.name .. "|r")
            nameStr:SetJustifyH("LEFT")

            -- Display ID on the right
            local idStr = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            idStr:SetPoint("RIGHT", -8, 0)
            idStr:SetText("|cff6a6050" .. entry.displayID .. "|r")

            row:SetScript("OnClick", function()
                if petSelectedIdx and petButtons[petSelectedIdx] then
                    petButtons[petSelectedIdx].bg:SetTexture(0, 0, 0, 0)
                end
                petSelectedIdx = idx
                rowBg:SetTexture(0.6, 0.48, 0.15, 0.3)
                btnApplyPet:Enable()
            end)

            row:SetScript("OnEnter", function()
                if petSelectedIdx ~= idx then rowBg:SetTexture(1, 1, 1, 0.05) end
                GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
                GameTooltip:AddLine(entry.name)
                GameTooltip:AddLine("Display ID: " .. entry.displayID, 1, 1, 1)
                if entry.spellID > 0 then
                    GameTooltip:AddLine("Spell ID: " .. entry.spellID, 0.7, 0.7, 0.7)
                end
                GameTooltip:AddLine("Click to select, then Apply", 0.5, 0.5, 0.5)
                GameTooltip:Show()
            end)

            row:SetScript("OnLeave", function()
                if petSelectedIdx ~= idx then rowBg:SetTexture(0, 0, 0, 0) end
                GameTooltip:Hide()
            end)

            row.bg = rowBg
            table.insert(petButtons, row)
            bY = bY + ROW_HEIGHT + 1
        end

        listContent:SetHeight(math.max(1, bY))
    end

    -- Search debounce
    local petSearchTimer = CreateFrame("Frame")
    petSearchTimer:Hide()
    petSearchTimer.elapsed = 0
    petSearchTimer:SetScript("OnUpdate", function(self, dt)
        self.elapsed = self.elapsed + dt
        if self.elapsed >= 0.3 then
            self:Hide()
            FilterPets(searchBox:GetText())
            BuildPetList()
        end
    end)
    searchBox:SetScript("OnTextChanged", function(self)
        petSearchTimer.elapsed = 0
        petSearchTimer:Show()
        if self:GetText() ~= "" then searchClear:Show() else searchClear:Hide() end
    end)

    -- Apply pet morph
    btnApplyPet:SetScript("OnClick", function()
        if petSelectedIdx and petFilteredList[petSelectedIdx] then
            local entry = petFilteredList[petSelectedIdx]
            if IsMorpherReady() then
                SendMorphCommand("PET_MORPH:" .. entry.displayID)
                SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Pet morphed to " .. entry.name .. " (" .. entry.displayID .. ")")
            else
                SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: |cffff0000DLL not loaded!|r")
            end
            PlaySound("gsTitleOptionOK")
        end
    end)

    -- Reset pet morph
    btnResetPet:SetScript("OnClick", function()
        if IsMorpherReady() then
            SendMorphCommand("PET_RESET")
            SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Pet appearance reset!")
        end
        PlaySound("gsTitleOptionOK")
    end)

    -- Initialize on show
    petTab:SetScript("OnShow", function()
        if #petFilteredList == 0 then
            FilterPets("")
            BuildPetList()
        end
    end)
end

---------------- COMBAT PETS TAB ----------------

do
    local hpetTab = mainFrame.tabs.combatPets
    local ROW_HEIGHT = 32

    -- ========== MODE TOGGLE (Curated / All Creatures) ==========
    local MODE_CURATED = 1
    local MODE_ALL = 2
    local currentMode = MODE_CURATED

    -- Row 1: Mode buttons + Display ID input
    local topBar = CreateFrame("Frame", nil, hpetTab)
    topBar:SetPoint("TOPLEFT", 6, -4)
    topBar:SetPoint("RIGHT", -6, 0)
    topBar:SetHeight(24)
    topBar:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    topBar:SetBackdropColor(0.08, 0.06, 0.03, 0.9)
    topBar:SetBackdropBorderColor(0.60, 0.50, 0.18, 0.7)

    local btnModeCurated = CreateFrame("Button", "$parentHPetModeCurated", topBar, "UIPanelButtonTemplate2")
    btnModeCurated:SetSize(120, 20)
    btnModeCurated:SetPoint("LEFT", 4, 0)

    local btnModeAll = CreateFrame("Button", "$parentHPetModeAll", topBar, "UIPanelButtonTemplate2")
    btnModeAll:SetSize(120, 20)
    btnModeAll:SetPoint("LEFT", btnModeCurated, "RIGHT", 4, 0)

    -- Display ID input on the right
    local directIDLabel = topBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    directIDLabel:SetPoint("RIGHT", topBar, "RIGHT", -70, 0)
    directIDLabel:SetText("|cffC8AA6EDisplay ID:|r")

    local directIDBox = CreateFrame("EditBox", "$parentHPetDirectID", topBar)
    directIDBox:SetSize(56, 16)
    directIDBox:SetPoint("LEFT", directIDLabel, "RIGHT", 4, 0)
    directIDBox:SetAutoFocus(false)
    directIDBox:SetMaxLetters(6)
    directIDBox:SetNumeric(true)
    directIDBox:SetFont("Fonts\\FRIZQT__.TTF", 10)
    directIDBox:SetTextColor(0.95, 0.88, 0.65)
    do
        local idBg = directIDBox:CreateTexture(nil, "BACKGROUND")
        idBg:SetAllPoints()
        idBg:SetTexture(0, 0, 0, 0.5)
        local idBorder = directIDBox:CreateTexture(nil, "BORDER")
        idBorder:SetPoint("TOPLEFT", -1, 1)
        idBorder:SetPoint("BOTTOMRIGHT", 1, -1)
        idBorder:SetTexture(0.50, 0.42, 0.18, 0.6)
    end
    directIDBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    directIDBox:SetScript("OnEnterPressed", function(self)
        local id = tonumber(self:GetText())
        if id and id > 0 then
            if IsMorpherReady() then
                SendMorphCommand("HPET_MORPH:" .. id)
                SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Combat pet morphed to display ID " .. id)
            else
                SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: |cffff0000DLL not loaded!|r")
            end
            PlaySound("gsTitleOptionOK")
        end
        self:ClearFocus()
    end)

    -- Row 2: Search bar (left) + Type filter (right), on the SAME row but separate containers
    local searchContainer = CreateFrame("Frame", nil, hpetTab)
    searchContainer:SetPoint("TOPLEFT", 6, -30)
    searchContainer:SetHeight(24)

    -- Type filter container (right side, fixed width)
    local typeContainer = CreateFrame("Frame", nil, hpetTab)
    typeContainer:SetPoint("TOPRIGHT", -6, -30)
    typeContainer:SetSize(200, 24)
    typeContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    typeContainer:SetBackdropColor(0.06, 0.05, 0.03, 0.95)
    typeContainer:SetBackdropBorderColor(0.60, 0.50, 0.18, 0.8)

    -- Search container fills to the left of type filter
    searchContainer:SetPoint("RIGHT", typeContainer, "LEFT", -4, 0)
    searchContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    searchContainer:SetBackdropColor(0.06, 0.05, 0.03, 0.95)
    searchContainer:SetBackdropBorderColor(0.60, 0.50, 0.18, 0.8)

    local hpSearchIcon = searchContainer:CreateTexture(nil, "OVERLAY")
    hpSearchIcon:SetSize(14, 14)
    hpSearchIcon:SetPoint("LEFT", 6, 0)
    hpSearchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
    hpSearchIcon:SetVertexColor(0.80, 0.65, 0.22)

    local searchBox = CreateFrame("EditBox", "$parentHPetSearch", searchContainer)
    searchBox:SetPoint("LEFT", hpSearchIcon, "RIGHT", 4, 0)
    searchBox:SetPoint("RIGHT", -20, 0)
    searchBox:SetHeight(18)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(40)
    searchBox:SetFont("Fonts\\FRIZQT__.TTF", 11)
    searchBox:SetTextColor(0.95, 0.88, 0.65)
    searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    local searchHint = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    searchHint:SetPoint("LEFT", 2, 0)
    searchHint:SetText("Search combat pets...")
    searchBox:SetScript("OnEditFocusGained", function() searchHint:Hide() end)
    searchBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then searchHint:Show() end
    end)

    local hpSearchClear = CreateFrame("Button", nil, searchContainer)
    hpSearchClear:SetSize(14, 14)
    hpSearchClear:SetPoint("RIGHT", -4, 0)
    hpSearchClear:SetNormalTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
    hpSearchClear:SetAlpha(0.5)
    hpSearchClear:Hide()
    hpSearchClear:SetScript("OnEnter", function(self) self:SetAlpha(1) end)
    hpSearchClear:SetScript("OnLeave", function(self) self:SetAlpha(0.5) end)
    hpSearchClear:SetScript("OnClick", function()
        searchBox:SetText("")
        searchBox:ClearFocus()
        searchHint:Show()
        hpSearchClear:Hide()
    end)

    -- ========== TYPE FILTER (inside typeContainer) ==========
    local familyLabel = typeContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    familyLabel:SetPoint("LEFT", 6, 0)
    familyLabel:SetText("|cffC8AA6EType:|r")

    local allFamilies = {}
    local familySet = {}
    if ns.combatPetsDB then
        for _, entry in ipairs(ns.combatPetsDB) do
            if not familySet[entry[2]] then
                familySet[entry[2]] = true
                table.insert(allFamilies, entry[2])
            end
        end
        table.sort(allFamilies)
    end
    table.insert(allFamilies, 1, "All Types")

    local familyIdx = 1
    local familyBtn = CreateFrame("Button", "$parentHPetFamilyBtn", typeContainer, "UIPanelButtonTemplate2")
    familyBtn:SetSize(130, 18)
    familyBtn:SetPoint("LEFT", familyLabel, "RIGHT", 4, 0)
    familyBtn:SetText("|cffffd700All Types|r")

    -- Result count label (between search and list)
    local countLabel = hpetTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countLabel:SetPoint("TOPRIGHT", -12, -56)
    countLabel:SetText("")

    -- ========== LIST AREA ==========
    local listBg = CreateFrame("Frame", "$parentHPetListBg", hpetTab)
    listBg:SetPoint("TOPLEFT", 6, -58)
    listBg:SetPoint("BOTTOMRIGHT", -6, 38)
    listBg:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    listBg:SetBackdropColor(0.04, 0.03, 0.03, 0.9)
    listBg:SetBackdropBorderColor(0.80, 0.65, 0.22, 0.85)

    local listScroll = CreateFrame("ScrollFrame", "$parentHPetListScroll", listBg, "UIPanelScrollFrameTemplate")
    listScroll:SetPoint("TOPLEFT", 4, -4)
    listScroll:SetPoint("BOTTOMRIGHT", -22, 4)

    local listContent = CreateFrame("Frame", "$parentHPetListContent", listScroll)
    listContent:SetSize(listScroll:GetWidth(), 1)
    listScroll:SetScrollChild(listContent)

    -- ========== BOTTOM BUTTONS ==========
    local bottomBar = CreateFrame("Frame", nil, hpetTab)
    bottomBar:SetPoint("BOTTOMLEFT", 6, 2)
    bottomBar:SetPoint("BOTTOMRIGHT", -6, 2)
    bottomBar:SetHeight(34)
    bottomBar:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    bottomBar:SetBackdropColor(0.08, 0.06, 0.03, 0.9)
    bottomBar:SetBackdropBorderColor(0.60, 0.50, 0.18, 0.7)

    local btnApplyHPet = CreateFrame("Button", "$parentBtnApplyHPet", bottomBar, "UIPanelButtonTemplate2")
    btnApplyHPet:SetSize(130, 24)
    btnApplyHPet:SetPoint("LEFT", 6, 0)
    btnApplyHPet:SetText("|cffF5C842Apply Morph|r")
    btnApplyHPet:Disable()

    local btnResetHPet = CreateFrame("Button", "$parentBtnResetHPet", bottomBar, "UIPanelButtonTemplate2")
    btnResetHPet:SetSize(100, 24)
    btnResetHPet:SetPoint("LEFT", btnApplyHPet, "RIGHT", 4, 0)
    btnResetHPet:SetText("|cffD4A44EReset|r")

    -- Separator line between reset and size
    local bottomSep = bottomBar:CreateTexture(nil, "ARTWORK")
    bottomSep:SetSize(1, 18)
    bottomSep:SetPoint("LEFT", btnResetHPet, "RIGHT", 8, 0)
    bottomSep:SetTexture(0.50, 0.42, 0.18, 0.5)

    -- Pet size controls
    local petSizeLabel = bottomBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    petSizeLabel:SetPoint("LEFT", bottomSep, "RIGHT", 8, 0)
    petSizeLabel:SetText("|cffC8AA6EScale:|r")

    local petSizeBox = CreateFrame("EditBox", "$parentHPetSizeInput", bottomBar)
    petSizeBox:SetSize(36, 16)
    petSizeBox:SetPoint("LEFT", petSizeLabel, "RIGHT", 4, 0)
    petSizeBox:SetAutoFocus(false)
    petSizeBox:SetMaxLetters(4)
    petSizeBox:SetText("1.0")
    petSizeBox:SetFont("Fonts\\FRIZQT__.TTF", 10)
    petSizeBox:SetTextColor(0.95, 0.88, 0.65)
    do
        local szBg = petSizeBox:CreateTexture(nil, "BACKGROUND")
        szBg:SetAllPoints()
        szBg:SetTexture(0, 0, 0, 0.5)
        local szBorder = petSizeBox:CreateTexture(nil, "BORDER")
        szBorder:SetPoint("TOPLEFT", -1, 1)
        szBorder:SetPoint("BOTTOMRIGHT", 1, -1)
        szBorder:SetTexture(0.50, 0.42, 0.18, 0.6)
    end
    petSizeBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    local btnPetSize = CreateFrame("Button", "$parentBtnHPetSize", bottomBar, "UIPanelButtonTemplate2")
    btnPetSize:SetSize(60, 22)
    btnPetSize:SetPoint("LEFT", petSizeBox, "RIGHT", 4, 0)
    btnPetSize:SetText("|cffF5C842Resize|r")
    btnPetSize:SetScript("OnClick", function()
        local scale = tonumber(petSizeBox:GetText())
        if scale and scale >= 0.1 and scale <= 10.0 and IsMorpherReady() then
            SendMorphCommand("HPET_SCALE:" .. scale)
            SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Combat pet scaled to " .. scale)
            PlaySound("gsTitleOptionOK")
        else
            SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Enter a valid size (0.1 - 10.0)")
        end
    end)
    petSizeBox:SetScript("OnEnterPressed", function(self)
        btnPetSize:GetScript("OnClick")()
        self:ClearFocus()
    end)

    -- ========== STATE ==========
    local hpetButtons = {}
    local hpetSelectedIdx = nil
    local hpetFilteredList = {}
    local MAX_RESULTS = 200 -- cap for All Creatures to avoid lag

    -- ========== FILTER: CURATED MODE ==========
    local function FilterCurated(query)
        hpetFilteredList = {}
        local db = ns.combatPetsDB or {}
        local selFamily = allFamilies[familyIdx]
        local filterFamily = (selFamily ~= "All Types")
        if not query or query == "" then
            for i, entry in ipairs(db) do
                if not filterFamily or entry[2] == selFamily then
                    table.insert(hpetFilteredList, { idx = i, name = entry[1], family = entry[2], displayID = entry[3], modelPath = entry[4], npcID = entry[5] })
                end
            end
        else
            local q = query:lower()
            for i, entry in ipairs(db) do
                if (not filterFamily or entry[2] == selFamily) and (entry[1]:lower():find(q, 1, true) or entry[2]:lower():find(q, 1, true) or tostring(entry[3]):find(q, 1, true)) then
                    table.insert(hpetFilteredList, { idx = i, name = entry[1], family = entry[2], displayID = entry[3], modelPath = entry[4], npcID = entry[5] })
                end
            end
        end
    end

    -- ========== FILTER: ALL CREATURES MODE ==========
    -- Pre-build sorted creature list once for performance
    local creatureSortedList = nil
    local function GetCreatureSortedList()
        if creatureSortedList then return creatureSortedList end
        creatureSortedList = {}
        local db = ns.creatureDisplayDB
        if not db then return creatureSortedList end
        for did, name in pairs(db) do
            table.insert(creatureSortedList, { did = did, name = name, nameLower = name:lower() })
        end
        table.sort(creatureSortedList, function(a, b) return a.name < b.name end)
        return creatureSortedList
    end

    local function FilterAllCreatures(query)
        hpetFilteredList = {}
        local sorted = GetCreatureSortedList()
        if not query or query == "" or #query < 2 then
            -- No search query: show first MAX_RESULTS creatures alphabetically
            local count = 0
            for _, entry in ipairs(sorted) do
                table.insert(hpetFilteredList, { idx = entry.did, name = entry.name, family = "Creature", displayID = entry.did })
                count = count + 1
                if count >= MAX_RESULTS then break end
            end
            return
        end
        local q = query:lower()
        local count = 0
        for _, entry in ipairs(sorted) do
            if entry.nameLower:find(q, 1, true) or tostring(entry.did):find(q, 1, true) then
                table.insert(hpetFilteredList, { idx = entry.did, name = entry.name, family = "Creature", displayID = entry.did })
                count = count + 1
                if count >= MAX_RESULTS then break end
            end
        end
    end

    -- ========== BUILD LIST UI ==========
    local function BuildHPetList()
        for _, b in ipairs(hpetButtons) do b:Hide() end
        hpetButtons = {}
        hpetSelectedIdx = nil
        btnApplyHPet:Disable()

        countLabel:SetText("")

        local bY = 0
        for idx, entry in ipairs(hpetFilteredList) do
            local row = CreateFrame("Button", nil, listContent)
            row:SetSize(listContent:GetWidth() - 4, ROW_HEIGHT)
            row:SetPoint("TOPLEFT", 2, -bY)

            local rowBg = row:CreateTexture(nil, "BACKGROUND")
            rowBg:SetAllPoints()
            rowBg:SetTexture(0, 0, 0, 0)

            -- Icon
            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetSize(ROW_HEIGHT - 4, ROW_HEIGHT - 4)
            icon:SetPoint("LEFT", 4, 0)
            -- Different icons per type
            local iconTex = "Interface\\Icons\\Ability_Hunter_BeastCall"
            if entry.family == "Warlock" then
                iconTex = "Interface\\Icons\\Spell_Shadow_SummonImp"
            elseif entry.family == "Mage" then
                iconTex = "Interface\\Icons\\Spell_Frost_SummonWaterElemental_2"
            elseif entry.family == "Creature" then
                iconTex = "Interface\\Icons\\INV_Misc_Head_Dragon_01"
            end
            icon:SetTexture(iconTex)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            local iconBorder = row:CreateTexture(nil, "OVERLAY")
            iconBorder:SetSize(ROW_HEIGHT - 2, ROW_HEIGHT - 2)
            iconBorder:SetPoint("CENTER", icon, "CENTER", 0, 0)
            iconBorder:SetTexture("Interface\\Buttons\\UI-Quickslot2")
            iconBorder:SetTexCoord(0.2, 0.8, 0.2, 0.8)

            -- Name
            local nameStr = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameStr:SetPoint("LEFT", icon, "RIGHT", 8, 0)
            nameStr:SetText("|cffffd700" .. entry.name .. "|r")
            nameStr:SetWidth(250)
            nameStr:SetJustifyH("LEFT")

            -- Type/Family
            local famStr = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            famStr:SetPoint("LEFT", nameStr, "RIGHT", 4, 0)
            famStr:SetText("|cff8a7d6a" .. entry.family .. "|r")
            famStr:SetWidth(100)
            famStr:SetJustifyH("LEFT")

            -- Display ID
            local idStr = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            idStr:SetPoint("RIGHT", -8, 0)
            idStr:SetText("|cff6a6050" .. entry.displayID .. "|r")

            row:SetScript("OnClick", function()
                if hpetSelectedIdx and hpetButtons[hpetSelectedIdx] then
                    hpetButtons[hpetSelectedIdx].bg:SetTexture(0, 0, 0, 0)
                end
                hpetSelectedIdx = idx
                rowBg:SetTexture(0.6, 0.48, 0.15, 0.3)
                btnApplyHPet:Enable()
            end)

            row:SetScript("OnEnter", function()
                if hpetSelectedIdx ~= idx then rowBg:SetTexture(1, 1, 1, 0.05) end
                GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
                GameTooltip:AddLine(entry.name)
                GameTooltip:AddLine("Type: " .. entry.family, 1, 0.82, 0.1)
                GameTooltip:AddLine("Display ID: " .. entry.displayID, 1, 1, 1)
                GameTooltip:AddLine("Click to select, then Apply", 0.5, 0.5, 0.5)
                GameTooltip:Show()
            end)

            row:SetScript("OnLeave", function()
                if hpetSelectedIdx ~= idx then rowBg:SetTexture(0, 0, 0, 0) end
                GameTooltip:Hide()
            end)

            row.bg = rowBg
            table.insert(hpetButtons, row)
            bY = bY + ROW_HEIGHT + 1
        end

        listContent:SetHeight(math.max(1, bY))
    end

    -- ========== REFRESH ==========
    local function RefreshList()
        local query = searchBox:GetText()
        if currentMode == MODE_CURATED then
            FilterCurated(query)
        else
            FilterAllCreatures(query)
        end
        BuildHPetList()
    end

    -- ========== MODE BUTTON VISUALS ==========
    local function UpdateModeButtons()
        if currentMode == MODE_CURATED then
            btnModeCurated:SetText("|cffffd700> Curated Pets|r")
            btnModeAll:SetText("|cff888888All Creatures|r")
            typeContainer:Show()
            -- Shrink search to make room for type filter
            searchContainer:SetPoint("RIGHT", typeContainer, "LEFT", -4, 0)
            searchHint:SetText("Search combat pets...")
        else
            btnModeCurated:SetText("|cff888888Curated Pets|r")
            btnModeAll:SetText("|cffffd700> All Creatures|r")
            typeContainer:Hide()
            -- Expand search to full width
            searchContainer:SetPoint("RIGHT", hpetTab, "RIGHT", -6, 0)
            searchHint:SetText("Search all creatures...")
        end
        if searchBox:GetText() == "" then
            searchHint:Show()
        end
    end

    btnModeCurated:SetScript("OnClick", function()
        currentMode = MODE_CURATED
        UpdateModeButtons()
        RefreshList()
    end)
    btnModeAll:SetScript("OnClick", function()
        currentMode = MODE_ALL
        UpdateModeButtons()
        RefreshList()
    end)

    -- ========== FAMILY FILTER CYCLING ==========
    familyBtn:SetScript("OnClick", function()
        familyIdx = familyIdx + 1
        if familyIdx > #allFamilies then familyIdx = 1 end
        familyBtn:SetText("|cffffd700" .. allFamilies[familyIdx] .. "|r")
        RefreshList()
    end)
    familyBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Click to cycle types")
        GameTooltip:AddLine("Right-click to reset to All", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    familyBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    familyBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    familyBtn:HookScript("OnClick", function(self, button)
        if button == "RightButton" then
            familyIdx = 1
            familyBtn:SetText("|cffffd700All Types|r")
            RefreshList()
        end
    end)

    -- ========== SEARCH DEBOUNCE ==========
    local hpetSearchTimer = CreateFrame("Frame")
    hpetSearchTimer:Hide()
    hpetSearchTimer.elapsed = 0
    hpetSearchTimer:SetScript("OnUpdate", function(self, dt)
        self.elapsed = self.elapsed + dt
        if self.elapsed >= 0.3 then
            self:Hide()
            RefreshList()
        end
    end)
    searchBox:SetScript("OnTextChanged", function(self)
        hpetSearchTimer.elapsed = 0
        hpetSearchTimer:Show()
        if self:GetText() ~= "" then hpSearchClear:Show() else hpSearchClear:Hide() end
    end)

    -- ========== APPLY BUTTON ==========
    btnApplyHPet:SetScript("OnClick", function()
        if hpetSelectedIdx and hpetFilteredList[hpetSelectedIdx] then
            local entry = hpetFilteredList[hpetSelectedIdx]
            if IsMorpherReady() then
                SendMorphCommand("HPET_MORPH:" .. entry.displayID)
                SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Combat pet morphed to " .. entry.name .. " (" .. entry.displayID .. ")")
            else
                SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: |cffff0000DLL not loaded!|r")
            end
            PlaySound("gsTitleOptionOK")
        end
    end)

    -- ========== RESET BUTTON ==========
    btnResetHPet:SetScript("OnClick", function()
        if IsMorpherReady() then
            SendMorphCommand("HPET_RESET")
            SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Combat pet appearance reset!")
        end
        PlaySound("gsTitleOptionOK")
    end)

    -- ========== INIT ON SHOW ==========
    hpetTab:SetScript("OnShow", function()
        UpdateModeButtons()
        if #hpetFilteredList == 0 and currentMode == MODE_CURATED then
            RefreshList()
        end
    end)
end

---------------- SETTINGS TAB ----------------

do
    local settingsTab = mainFrame.tabs.settings
    local yOffset = -10

    local function createCheckbox(parent, label, settingKey, y)
        local cb = CreateFrame("CheckButton", "$parentCB_"..settingKey, parent, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 10, y)
        _G[cb:GetName().."Text"]:SetText(label)
        _G[cb:GetName().."Text"]:SetFontObject("GameFontNormalSmall")
        cb:SetScript("OnClick", function(self)
            GetSettings()[settingKey] = self:GetChecked() == 1
            PlaySound("gsTitleOptionOK")
        end)
        cb:SetScript("OnShow", function(self)
            self:SetChecked(GetSettings()[settingKey])
        end)
        return cb
    end

    -- Persistence settings
    createCheckbox(settingsTab, "Persist morph across sessions", "saveMorphState", yOffset)
    yOffset = yOffset - 28
    createCheckbox(settingsTab, "Save mount morph per character", "saveMountMorph", yOffset)
    yOffset = yOffset - 28
    createCheckbox(settingsTab, "Save pet morph per character", "savePetMorph", yOffset)
    yOffset = yOffset - 28
    createCheckbox(settingsTab, "Save combat pet morph per character", "saveCombatPetMorph", yOffset)
    yOffset = yOffset - 28
    local dbwCheckbox = createCheckbox(settingsTab, "Show Deathbringer's Will proc form", "showDBWProc", yOffset)
    -- When toggling the DBW setting, immediately update the suspend state
    dbwCheckbox:HookScript("OnClick", function(self)
        local enabled = self:GetChecked() == 1
        if not enabled and dbwSuspended then
            -- User turned it off while DBW was suspending: resume immediately
            dbwSuspended = false
            if not morphSuspended then
                SendRawMorphCommand("RESUME")
            end
        elseif enabled and not dbwSuspended and HasDBWProc() then
            -- User turned it on while a DBW proc is active: suspend immediately
            dbwSuspended = true
            if not morphSuspended then
                SendRawMorphCommand("SUSPEND")
            end
        end
    end)
    yOffset = yOffset - 28
    local shapeshiftCheckbox = createCheckbox(settingsTab, "Keep morph in shapeshift forms", "morphInShapeshift", yOffset)
    -- When toggling shapeshift morph setting, immediately update suspend state
    shapeshiftCheckbox:HookScript("OnClick", function(self)
        local enabled = self:GetChecked() == 1
        if enabled and morphSuspended then
            -- User wants morph in shapeshift: resume immediately
            morphSuspended = false
            if not dbwSuspended then
                SendRawMorphCommand("RESUME")
            end
        elseif not enabled and IsModelChangingForm() and not morphSuspended then
            -- User turned it off while in a form: suspend immediately
            morphSuspended = true
            if not dbwSuspended then
                SendRawMorphCommand("SUSPEND")
            end
        end
    end)

    -- DLL status indicator
    yOffset = yOffset - 40
    local statusText = settingsTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusText:SetPoint("TOPLEFT", 14, yOffset)

    settingsTab:SetScript("OnShow", function()
        if IsMorpherReady() then
            statusText:SetText("|cff4ACC4AMorpher DLL: LOADED|r")
        else
            statusText:SetText("|cffff0000Morpher DLL: NOT LOADED|r\nPlace dinput8.dll\nin your WoW folder.")
        end
    end)
end

---------------- EVENT LOOP & PERSISTENCE ----------------
-- Clean event-based system. The DLL's MorphGuard handles automatic
-- restoration of descriptors every 20ms. The addon only needs to:
--   1. Send morph state on login/zone change (once)
--   2. Signal SUSPEND when entering a model-changing form
--   3. Signal RESUME when leaving a model-changing form
-- No burst loops, no repeated CreateFrame, no flickering.

do
    mainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    mainFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    mainFrame:RegisterEvent("UNIT_MODEL_CHANGED")
    mainFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    mainFrame:RegisterEvent("UNIT_AURA")
    mainFrame:RegisterEvent("CHAT_MSG_ADDON")
    mainFrame:RegisterEvent("PLAYER_LOGIN")
    -- Track form state for edge detection (only act on transitions)
    local lastKnownForm = -1
    local lastKnownMounted = false

    -- One-shot delayed send (reusable timer, no CreateFrame spam)
    local delayedSendTimer = CreateFrame("Frame")
    delayedSendTimer:Hide()
    delayedSendTimer:SetScript("OnUpdate", function(self, elapsed)
        self.remaining = self.remaining - elapsed
        if self.remaining <= 0 then
            self:Hide()
            SendFullMorphState()
        end
    end)

    local function ScheduleMorphSend(delay)
        delayedSendTimer.remaining = delay or 0.05
        delayedSendTimer:Show()
    end

    mainFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_LOGIN" then
            -- Initialize per-character SavedVariables
            if not TransmorpherCharacterState then
                TransmorpherCharacterState = {Items={}, Morph=nil, Scale=nil, MountDisplay=nil, PetDisplay=nil, HunterPetDisplay=nil, HunterPetScale=nil}
            end
            if not TransmorpherCharacterState.Items then
                TransmorpherCharacterState.Items = {}
            end

            -- Flag: the next SendFullMorphState will prepend RESET:ALL so
            -- the DLL wipe + character-restore is one atomic batch.
            needsCharacterReset = true

            -- Immediately send RESET:ALL to the DLL so stale state from a
            -- previous character is cleared within the next 20ms tick.
            -- The full morph state will be sent after the delayed schedule.
            SendRawMorphCommand("RESET:ALL")

            -- Evaluate current form/proc state
            lastKnownForm = GetShapeshiftForm()
            lastKnownMounted = IsMounted() or false
            morphSuspended = IsModelChangingForm()
            dbwSuspended = GetSettings().showDBWProc and HasDBWProc() or false
            if morphSuspended or dbwSuspended then
                SendRawMorphCommand("SUSPEND")
            else
                -- PLAYER_ENTERING_WORLD will fire shortly and override this
                -- with a 0.05 s timer, but schedule a 0.4 s fallback just in case.
                ScheduleMorphSend(0.4)
            end

        elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
            -- Zone transition: re-evaluate all suspend reasons from scratch
            lastKnownForm = GetShapeshiftForm()
            lastKnownMounted = IsMounted() or false
            morphSuspended = IsModelChangingForm()
            dbwSuspended = GetSettings().showDBWProc and HasDBWProc() or false
            if morphSuspended or dbwSuspended then
                SendRawMorphCommand("SUSPEND")
            else
                ScheduleMorphSend(0.05)
            end

        elseif event == "UPDATE_SHAPESHIFT_FORM" then
            -- Shapeshift form changed: detect enter/leave transitions
            local currentForm = GetShapeshiftForm()
            if currentForm == lastKnownForm then return end
            lastKnownForm = currentForm

            local inModelForm = IsModelChangingForm()
            if inModelForm and not morphSuspended then
                -- ENTERING a model-changing form
                morphSuspended = true
                if not dbwSuspended then
                    SendRawMorphCommand("SUSPEND")
                end
            elseif not inModelForm and morphSuspended then
                -- LEAVING a model-changing form
                morphSuspended = false
                if not dbwSuspended then
                    SendRawMorphCommand("RESUME")
                end
            end

        elseif event == "UNIT_MODEL_CHANGED" then
            local unit = ...
            if unit ~= "player" then return end
            -- Model changed externally (Deathbringer's Will proc end, etc.)
            -- The DLL's MorphGuard detects descriptor mismatches automatically.
            -- We only need to handle mount state transitions here.
            local currentMounted = IsMounted() or false
            if currentMounted ~= lastKnownMounted then
                lastKnownMounted = currentMounted
                -- Mount/dismount doesn't need suspend/resume —
                -- MorphGuard handles descriptor restoration automatically.
            end
            -- No action needed: DLL MorphGuard restores on next tick.

        elseif event == "UNIT_AURA" then
            local unit = ...
            if unit ~= "player" then return end
            -- Deathbringer's Will proc detection: suspend morph to show proc form
            -- Only active when showDBWProc setting is enabled
            local hasDBW = GetSettings().showDBWProc and HasDBWProc() or false
            if hasDBW and not dbwSuspended then
                -- DBW proc started: suspend morph so player sees the proc form
                dbwSuspended = true
                if not morphSuspended then
                    SendRawMorphCommand("SUSPEND")
                end
            elseif not hasDBW and dbwSuspended then
                -- DBW proc ended: resume morph if shapeshift isn't also suspending
                dbwSuspended = false
                if not morphSuspended then
                    SendRawMorphCommand("RESUME")
                end
            end

        elseif event == "CHAT_MSG_ADDON" then
            local prefix, msg, channel, sender = ...
            if (prefix == addonMessagePrefix or prefix == "DressMe") then
                -- Reserved for future appearance sharing
            end
        end
    end)
end

---------------- SLASH COMMANDS ----------------

SLASH_Transmorpher1 = "/morph"
SLASH_Transmorpher2 = "/vm"
SLASH_Transmorpher3 = "/Transmorpher"

SlashCmdList["Transmorpher"] = function(msg)
    msg = msg:lower():trim()
    if msg == "reset" then
        if IsMorpherReady() then
            SendMorphCommand("RESET:ALL")
            SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: All morphs reset!")
        else
            SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: |cffff0000DLL not loaded!|r")
        end
    elseif msg == "status" then
            SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: |cff00ff00Stealth Mode Active|r\nCommunicating via memory buffer.")
    else
        if mainFrame:IsShown() then mainFrame:Hide() else mainFrame:Show() end
    end
end

---------------- PAPERDOLL BUTTON ----------------

do
    -------------------------------------------------------------------------
    -- Clean icon button embedded inside CharacterModelFrame (top-right).
    -- Uses native WoW textures only — guaranteed to render correctly.
    -------------------------------------------------------------------------
    local SIZE = 32

    local btn = CreateFrame("Button", "TransmorpherPaperDollButton", CharacterModelFrame)
    btn:SetSize(SIZE, SIZE)
    btn:SetPoint("TOPRIGHT", CharacterModelFrame, "TOPRIGHT", -4, -4)
    btn:SetFrameStrata("HIGH")
    btn:SetFrameLevel(CharacterModelFrame:GetFrameLevel() + 15)
    btn:RegisterForClicks("LeftButtonUp")
    btn:SetMovable(true)
    btn:SetClampedToScreen(true)
    btn:RegisterForDrag("RightButton")

    -- Drag handling — right-click drag to freely reposition
    local isDragging = false

    local function SaveButtonPosition()
        local parentL = CharacterModelFrame:GetLeft()
        local parentT = CharacterModelFrame:GetTop()
        local bL = btn:GetLeft()
        local bT = btn:GetTop()
        if not parentL or not parentT or not bL or not bT then return end
        local xOff = bL - parentL
        local yOff = bT - parentT
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", CharacterModelFrame, "TOPLEFT", xOff, yOff)
        -- Save per-character
        if not TransmorpherCharacterState then
            TransmorpherCharacterState = { Items = {}, Morph = nil, Scale = nil, MountDisplay = nil, PetDisplay = nil, HunterPetDisplay = nil }
        end
        TransmorpherCharacterState.paperdollButtonPos = { x = xOff, y = yOff }
    end

    btn:SetScript("OnDragStart", function(self)
        isDragging = true
        self:StartMoving()
    end)
    btn:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveButtonPosition()
        isDragging = false
    end)

    -- Restore saved per-character position
    if TransmorpherCharacterState and TransmorpherCharacterState.paperdollButtonPos then
        local p = TransmorpherCharacterState.paperdollButtonPos
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", CharacterModelFrame, "TOPLEFT", p.x, p.y)
    end

    -- Dark square background
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(0, 0, 0, 0.55)

    -- Icon — INV_Chest_Chain_05 (chestplate = transmog / appearance)
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(SIZE - 4, SIZE - 4)
    icon:SetPoint("CENTER")
    icon:SetTexture("Interface\\Icons\\INV_Chest_Cloth_17")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Thin golden border (1px simulated with 4 edge textures)
    local function MakeEdge(anchor1, rel, anchor2, x, y, w, h)
        local e = btn:CreateTexture(nil, "OVERLAY")
        e:SetTexture(1, 0.82, 0.1, 0.8)
        e:SetSize(w, h)
        e:SetPoint(anchor1, btn, anchor2, x, y)
        return e
    end
    MakeEdge("TOPLEFT",    "TOPLEFT",     "TOPLEFT",     0,  0,  SIZE, 1)  -- top
    MakeEdge("BOTTOMLEFT", "BOTTOMLEFT",  "BOTTOMLEFT",  0,  0,  SIZE, 1)  -- bottom
    MakeEdge("TOPLEFT",    "TOPLEFT",     "TOPLEFT",     0,  0,  1, SIZE)  -- left
    MakeEdge("TOPRIGHT",   "TOPRIGHT",    "TOPRIGHT",    0,  0,  1, SIZE)  -- right

    -- Highlight on hover — additive white overlay
    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(icon)
    hl:SetTexture(1, 1, 1, 0.2)
    hl:SetBlendMode("ADD")

    -- Active indicator — thin golden underline when transmog window is open
    local activeMark = btn:CreateTexture(nil, "OVERLAY")
    activeMark:SetSize(SIZE - 6, 2)
    activeMark:SetPoint("BOTTOM", btn, "BOTTOM", 0, 2)
    activeMark:SetTexture(1, 0.82, 0.1, 1)
    activeMark:Hide()

    ---- State management ----
    local function UpdateState()
        if mainFrame and mainFrame:IsShown() then
            activeMark:Show()
            bg:SetTexture(0.1, 0.06, 0, 0.7)
        else
            activeMark:Hide()
            bg:SetTexture(0, 0, 0, 0.55)
        end
    end

    ---- Tooltip ----
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:AddLine("|cffFFD100Transmogrifier|r")
        GameTooltip:AddLine("Change your appearance", 0.7, 0.7, 0.7, true)
        GameTooltip:AddLine("|cff888888Right-click drag to move|r", 0.5, 0.5, 0.5, true)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    ---- Click ----
    btn:SetScript("OnClick", function()
        if mainFrame:IsShown() then mainFrame:Hide() else mainFrame:Show() end
        PlaySound("igCharacterInfoTab")
        UpdateState()
    end)

    ---- Press feel (only for left-click, skip during right-drag) ----
    btn:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and not isDragging then
            icon:SetPoint("CENTER", 1, -1)
        end
    end)
    btn:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            icon:SetPoint("CENTER", 0, 0)
        end
    end)

    ---- Keep state synced ----
    if mainFrame then
        mainFrame:HookScript("OnShow", UpdateState)
        mainFrame:HookScript("OnHide", UpdateState)
    end
end

-- Print load message
DEFAULT_CHAT_FRAME:AddMessage("|cffF5C842\226\154\148 Transmorpher|r v1.0.3 loaded \226\128\148 |cffC8AA6E/morph|r or click the button on your character model.")
