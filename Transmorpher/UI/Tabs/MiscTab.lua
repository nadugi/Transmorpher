local addon, ns = ...

-- ============================================================
-- MISC TAB — Environment (Time Control) & Titles sub-tabs
-- ============================================================

local mainFrame = ns.mainFrame
local miscTab = mainFrame.tabs.env

local subTabBar = CreateFrame("Frame", nil, miscTab)
subTabBar:SetSize(220, 30); subTabBar:SetPoint("TOPLEFT", 0, -20)

local envPanel = CreateFrame("Frame", "$parentEnvPanel", miscTab)
envPanel:SetPoint("TOPLEFT", 0, -50); envPanel:SetPoint("BOTTOMRIGHT")

local titlesPanel = CreateFrame("Frame", "$parentTitlesPanel", miscTab)
titlesPanel:SetPoint("TOPLEFT", 0, -50); titlesPanel:SetPoint("BOTTOMRIGHT"); titlesPanel:Hide()

local function CreateMiscSubTabBtn(id, text)
    local btn = CreateFrame("Button", nil, subTabBar)
    btn:SetID(id); btn:SetSize(110, 30)
    local bg = btn:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(); bg:SetTexture(1,1,1,0); btn.bg = bg
    local line = btn:CreateTexture(nil, "OVERLAY"); line:SetHeight(2)
    line:SetPoint("BOTTOMLEFT", 15, 0); line:SetPoint("BOTTOMRIGHT", -15, 0)
    line:SetTexture(1, 0.82, 0); line:Hide(); btn.line = line
    local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("CENTER"); fs:SetText(text); fs:SetTextColor(0.5,0.5,0.5); btn.fs = fs
    btn.SetActive = function(self, active)
        self.isActive = active
        if active then self.line:Show(); self.fs:SetTextColor(1,1,1); self.bg:SetTexture(1,1,1,0.05)
        else self.line:Hide(); self.fs:SetTextColor(0.5,0.5,0.5); self.bg:SetTexture(0,0,0,0) end
    end
    btn:SetScript("OnEnter", function(self) if not self.isActive then self.fs:SetTextColor(0.9,0.9,0.9); self.bg:SetTexture(1,1,1,0.03) end end)
    btn:SetScript("OnLeave", function(self) if not self.isActive then self.fs:SetTextColor(0.5,0.5,0.5); self.bg:SetTexture(0,0,0,0) end end)
    return btn
end

local btnEnv = CreateMiscSubTabBtn(1, "Environment"); btnEnv:SetPoint("LEFT", 0, 0); btnEnv:SetWidth(85)
local btnTitles = CreateMiscSubTabBtn(2, "Titles"); btnTitles:SetPoint("LEFT", btnEnv, "RIGHT", 0, 0); btnTitles:SetWidth(85)
local btnOpt = CreateMiscSubTabBtn(3, "Optimization"); btnOpt:SetPoint("LEFT", btnTitles, "RIGHT", 0, 0); btnOpt:SetWidth(100)

local function ShowMiscSubTab(id)
    envPanel[id == 1 and "Show" or "Hide"](envPanel)
    titlesPanel[id == 2 and "Show" or "Hide"](titlesPanel)
    if optimizationPanel then optimizationPanel[id == 3 and "Show" or "Hide"](optimizationPanel) end
    btnEnv:SetActive(id == 1); btnTitles:SetActive(id == 2); btnOpt:SetActive(id == 3)
    PlaySound("gsTitleOptionOK")
end

btnEnv:SetScript("OnClick", function() ShowMiscSubTab(1) end)
btnTitles:SetScript("OnClick", function() ShowMiscSubTab(2) end)
btnOpt:SetScript("OnClick", function() ShowMiscSubTab(3) end)
ShowMiscSubTab(1)

-- ============================================================
-- OPTIMIZATION PANEL
-- ============================================================
local optPanel = CreateFrame("Frame", "$parentOptPanel", miscTab)
optPanel:SetPoint("TOPLEFT", 0, -50); optPanel:SetPoint("BOTTOMRIGHT"); optPanel:Hide()
optimizationPanel = optPanel

local optCard = CreateFrame("Frame", nil, optPanel)
optCard:SetPoint("TOPLEFT", 8, -8); optCard:SetPoint("TOPRIGHT", -8, -8); optCard:SetHeight(400)
optCard:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", tile=true, tileSize=8, edgeSize=1, insets={left=1,right=1,top=1,bottom=1}})
optCard:SetBackdropColor(0.05, 0.055, 0.07, 0.93); optCard:SetBackdropBorderColor(0.56, 0.47, 0.20, 0.78)

local optTitle = optCard:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
optTitle:SetPoint("TOPLEFT", 12, -12); optTitle:SetText("|cffF5C842Spell Visibility & Optimization|r")

local optDesc = optCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
optDesc:SetPoint("TOPLEFT", optTitle, "BOTTOMLEFT", 0, -4); optDesc:SetText("Toggle specific spell effects globally to maximize performance."); optDesc:SetTextColor(0.7, 0.7, 0.7)

local optimizationCheckboxes = {}

local function CreateOptCheckbox(name, label, tooltip, settingKey, cmdPrefix)
    local cb = CreateFrame("CheckButton", "$parent"..name, optCard, "ChatConfigCheckButtonTemplate")
    cb:SetSize(22, 22)
    local text = _G[cb:GetName().."Text"]
    text:SetText(label); text:SetFontObject("GameFontNormalSmall"); text:SetPoint("LEFT", cb, "RIGHT", 4, 1)
    
    cb:SetScript("OnShow", function(self)
        self:SetChecked(ns.GetSettings()[settingKey])
    end)
    
    cb:SetScript("OnClick", function(self)
        local settings = ns.GetSettings()
        local checked = self:GetChecked()
        settings[settingKey] = checked
        if ns.IsMorpherReady() then
            ns.SendMorphCommand("SET:"..cmdPrefix..":"..(checked and "1" or "0"))
        end
        PlaySound(checked and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
    end)
    
    cb:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(label, 1, 0.82, 0)
        GameTooltip:AddLine(tooltip, 0.8, 0.8, 0.8, true)
        GameTooltip:AddLine("\n|cffF5C842Note:|r Affects all units globally.", 0.6, 0.6, 0.6, true)
        GameTooltip:Show()
    end)
    cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    optimizationCheckboxes[settingKey] = cb
    return cb
end




local cbHideAll = CreateOptCheckbox("HideAll", "|cffFF4444[MASTER] Hide ALL Spells|r", "Completely disables all spell visuals globally for peak FPS.", "hideAllSpells", "HIDE_ALL")
cbHideAll:SetPoint("TOPLEFT", 16, -52)

local sep1 = optCard:CreateTexture(nil, "ARTWORK")
sep1:SetSize(400, 1); sep1:SetPoint("TOPLEFT", 16, -86); sep1:SetTexture(1, 1, 1, 0.08)

-- Column 1
local col1X = 22
local yPos1 = -98
local rowH = 22
local secGap = 32

local sub1 = optCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
sub1:SetPoint("TOPLEFT", 18, yPos1); sub1:SetText("|cffA3A3A3Casting & Auras|r")
yPos1 = yPos1 - 18

CreateOptCheckbox("HidePre", "Pre-Cast Hand Glows", "Hides hand glows before a spell launches.", "hidePrecast", "HIDE_PRECAST"):SetPoint("TOPLEFT", col1X, yPos1); yPos1 = yPos1 - rowH
CreateOptCheckbox("HideCast", "Casting Animations", "Hides main character casting visuals.", "hideCast", "HIDE_CAST"):SetPoint("TOPLEFT", col1X, yPos1); yPos1 = yPos1 - rowH
CreateOptCheckbox("HideChan", "Channeled Beams", "Hides beams like Mind Flay or Drain Life.", "hideChannel", "HIDE_CHANNEL"):SetPoint("TOPLEFT", col1X, yPos1); yPos1 = yPos1 - secGap

local sub2 = optCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
sub2:SetPoint("TOPLEFT", 18, yPos1); sub2:SetText("|cffA3A3A3Aura Application|r")
yPos1 = yPos1 - 18

CreateOptCheckbox("HideAuraS", "Aura Apply (Start)", "Hides visuals triggered when an aura is applied.", "hideAuraStart", "HIDE_AURA_START"):SetPoint("TOPLEFT", col1X, yPos1); yPos1 = yPos1 - rowH
CreateOptCheckbox("HideAuraE", "Aura Remove (End)", "Hides visuals triggered when an aura expires.", "hideAuraEnd", "HIDE_AURA_END"):SetPoint("TOPLEFT", col1X, yPos1); yPos1 = yPos1 - secGap

local sub3 = optCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
sub3:SetPoint("TOPLEFT", 18, yPos1); sub3:SetText("|cffA3A3A3Impacts (Self)|r")
yPos1 = yPos1 - 18

CreateOptCheckbox("HideImpG", "Hit (Hand Effect)", "Hides generic hit effects usually attached to hands.", "hideImpact", "HIDE_IMPACT"):SetPoint("TOPLEFT", col1X, yPos1); yPos1 = yPos1 - rowH
CreateOptCheckbox("HideImpC", "Impact (Caster)", "Hides caster-side impact visuals.", "hideImpactCaster", "HIDE_IMPACT_CASTER"):SetPoint("TOPLEFT", col1X, yPos1)


-- Column 2
local col2X = 240
local yPos2 = -98

local sub4 = optCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
sub4:SetPoint("TOPLEFT", col2X - 4, yPos2); sub4:SetText("|cffA3A3A3World & Target Impacts|r")
yPos2 = yPos2 - 18

CreateOptCheckbox("HideImpT", "Impact (Target)", "Hides hit visuals on the target character.", "hideTargetImpact", "HIDE_IMPACT_TARGET"):SetPoint("TOPLEFT", col2X, yPos2); yPos2 = yPos2 - rowH
CreateOptCheckbox("HideAreaI", "Area (Instant Kit)", "Hides instant area-of-effect visuals.", "hideAreaInstant", "HIDE_AREA_INSTANT"):SetPoint("TOPLEFT", col2X, yPos2); yPos2 = yPos2 - rowH
CreateOptCheckbox("HideAreaM", "Area (Impact Kit)", "Hides area visuals triggered on impact.", "hideAreaImpact", "HIDE_AREA_IMPACT"):SetPoint("TOPLEFT", col2X, yPos2); yPos2 = yPos2 - rowH
CreateOptCheckbox("HideAreaP", "Area (Persistent)", "Hides persistent ground effects like Consecration.", "hideAreaPersistent", "HIDE_AREA_PERSISTENT"):SetPoint("TOPLEFT", col2X, yPos2); yPos2 = yPos2 - secGap

local sub5 = optCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
sub5:SetPoint("TOPLEFT", col2X - 4, yPos2); sub5:SetText("|cffA3A3A3Missiles & Markers|r")
yPos2 = yPos2 - 18

CreateOptCheckbox("HideMiss", "Missile Projectiles", "Hides traveling bolts (Fireball, Frostbolt) and arrows.", "hideMissile", "HIDE_MISSILE"):SetPoint("TOPLEFT", col2X, yPos2); yPos2 = yPos2 - rowH
CreateOptCheckbox("HideMissM", "Missile Markers", "Hides markers where missiles land.", "hideMissileMarker", "HIDE_MISSILE_MARKER"):SetPoint("TOPLEFT", col2X, yPos2); yPos2 = yPos2 - secGap

local sub6 = optCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
sub6:SetPoint("TOPLEFT", col2X - 4, yPos2); sub6:SetText("|cffA3A3A3Audio Suppression|r")
yPos2 = yPos2 - 18

CreateOptCheckbox("HideSndM", "Missile Sounds", "Suppresses sounds of traveling projectiles.", "hideSoundMissile", "HIDE_SOUND_MISSILE"):SetPoint("TOPLEFT", col2X, yPos2); yPos2 = yPos2 - rowH
CreateOptCheckbox("HideSndE", "Impact & Event Sounds", "Suppresses sounds triggered by impacts or events.", "hideSoundEvent", "HIDE_SOUND_EVENT"):SetPoint("TOPLEFT", col2X, yPos2)

-- ============================================================
-- ENVIRONMENT PANEL (Existing)
-- ============================================================
local timeCard = CreateFrame("Frame", nil, envPanel)
timeCard:SetPoint("TOPLEFT", 8, -8)
timeCard:SetPoint("TOPRIGHT", -8, -8)
timeCard:SetHeight(150)
timeCard:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", tile=true, tileSize=8, edgeSize=1, insets={left=1,right=1,top=1,bottom=1}})
timeCard:SetBackdropColor(0.05, 0.055, 0.07, 0.93)
timeCard:SetBackdropBorderColor(0.56, 0.47, 0.20, 0.78)

local timeTitle = timeCard:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
timeTitle:SetPoint("TOPLEFT", 12, -12); timeTitle:SetText("|cffF5C842Time Control|r")

local timeDesc = timeCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
timeDesc:SetPoint("TOPLEFT", timeTitle, "BOTTOMLEFT", 0, -4); timeDesc:SetText("Override the client-side time of day."); timeDesc:SetTextColor(0.7, 0.7, 0.7)

local slider = CreateFrame("Slider", "$parentTimeSlider", timeCard, "OptionsSliderTemplate")
slider:SetPoint("TOPLEFT", 20, -74); slider:SetPoint("RIGHT", -120, 0); slider:SetHeight(18)
slider:SetMinMaxValues(0.0, 24.0); slider:SetValueStep(0.5); slider:EnableMouse(true)

_G[slider:GetName().."Low"]:SetText("00:00"); _G[slider:GetName().."High"]:SetText("24:00")
local sliderText = _G[slider:GetName().."Text"]; sliderText:SetText("Noon"); sliderText:SetTextColor(1, 0.82, 0)

slider:SetScript("OnValueChanged", function(self, value)
    local hour = math.floor(value); local minute = math.floor((value - hour)*60)
    sliderText:SetText(string.format("%02d:%02d", hour, minute))
end)
slider:SetScript("OnShow", function(self)
    if TransmorpherCharacterState and TransmorpherCharacterState.WorldTime then self:SetValue(TransmorpherCharacterState.WorldTime * 24.0) else self:SetValue(12.0) end
end)

local btnApplyTime = ns.CreateGoldenButton("$parentApplyTime", timeCard)
btnApplyTime:SetPoint("LEFT", slider, "RIGHT", 12, 0); btnApplyTime:SetSize(86, 24); btnApplyTime:SetText("Set Time")
btnApplyTime:SetScript("OnClick", function()
    local val = slider:GetValue() / 24.0
    if ns.IsMorpherReady() then
        ns.SendMorphCommand("TIME:"..val)
        if not TransmorpherCharacterState then TransmorpherCharacterState = {} end
        TransmorpherCharacterState.WorldTime = val
        SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Time updated.")
    end; PlaySound("gsTitleOptionOK")
end)

local btnResetTime = ns.CreateGoldenButton("$parentResetTime", timeCard)
btnResetTime:SetPoint("TOPRIGHT", timeCard, "TOPRIGHT", -12, -10); btnResetTime:SetSize(82, 20); btnResetTime:SetText("Reset")
btnResetTime:SetScript("OnClick", function()
    if ns.IsMorpherReady() then
        ns.SendMorphCommand("TIME:-1")
        if TransmorpherCharacterState then TransmorpherCharacterState.WorldTime = nil end
        slider:SetValue(12.0)
        SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Time reset to server default.")
    end; PlaySound("gsTitleOptionOK")
end)

local titleTopBar = CreateFrame("Frame", nil, titlesPanel)
titleTopBar:SetPoint("TOPLEFT", 8, -8)
titleTopBar:SetPoint("TOPRIGHT", -8, -8)
titleTopBar:SetHeight(30)
titleTopBar:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", tile=true, tileSize=8, edgeSize=1, insets={left=1,right=1,top=1,bottom=1}})
titleTopBar:SetBackdropColor(0.05, 0.055, 0.07, 0.93)
titleTopBar:SetBackdropBorderColor(0.56, 0.47, 0.20, 0.78)

local titleSearchShell = CreateFrame("Frame", nil, titleTopBar)
titleSearchShell:SetPoint("TOPLEFT", 8, -4)
titleSearchShell:SetPoint("BOTTOMRIGHT", -94, 4)
titleSearchShell:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", tile=true, tileSize=8, edgeSize=1, insets={left=1,right=1,top=1,bottom=1}})
titleSearchShell:SetBackdropColor(0.03, 0.03, 0.04, 0.9)
titleSearchShell:SetBackdropBorderColor(0.30, 0.28, 0.24, 0.7)

local titleSearchIcon = titleSearchShell:CreateTexture(nil, "OVERLAY")
titleSearchIcon:SetSize(14, 14); titleSearchIcon:SetPoint("LEFT", 6, 0)
titleSearchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon"); titleSearchIcon:SetVertexColor(0.96, 0.82, 0.30)

local titleSearch = CreateFrame("EditBox", "$parentTitleSearch", titleSearchShell)
titleSearch:SetPoint("LEFT", titleSearchIcon, "RIGHT", 4, 0); titleSearch:SetPoint("BOTTOMRIGHT", -22, 1)
titleSearch:SetAutoFocus(false); titleSearch:SetFontObject("ChatFontNormal"); titleSearch:SetTextInsets(0, 0, 0, 0); titleSearch:SetTextColor(0.95, 0.88, 0.65)

local titleSearchHint = titleSearch:CreateFontString(nil, "ARTWORK", "GameFontDisable")
titleSearchHint:SetPoint("LEFT", 0, 0); titleSearchHint:SetText("Search titles...")
titleSearch:SetScript("OnEditFocusGained", function() titleSearchHint:Hide() end)
titleSearch:SetScript("OnEditFocusLost", function(self) if self:GetText() == "" then titleSearchHint:Show() end end)
titleSearch:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

local btnClear = CreateFrame("Button", nil, titleSearchShell)
btnClear:SetSize(14, 14); btnClear:SetPoint("RIGHT", -4, 0)
btnClear:SetNormalTexture("Interface\\FriendsFrame\\ClearBroadcastIcon"); btnClear:SetAlpha(0.6)
btnClear:SetScript("OnClick", function() titleSearch:SetText(""); titleSearch:ClearFocus(); titleSearchHint:Show() end)

local btnResetTitle = ns.CreateGoldenButton("$parentResetTitle", titleTopBar)
btnResetTitle:SetPoint("RIGHT", -8, 0); btnResetTitle:SetSize(76, 22); btnResetTitle:SetText("Reset")

local titleResultCount = titleTopBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
titleResultCount:SetPoint("RIGHT", btnResetTitle, "LEFT", -8, 0)
titleResultCount:SetTextColor(0.78, 0.66, 0.40, 0.8)

local titleListBg = CreateFrame("Frame", "$parentTitleListBg", titlesPanel)
titleListBg:SetPoint("TOPLEFT", 8, -42); titleListBg:SetPoint("BOTTOMRIGHT", -8, 8)
titleListBg:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", tile=true, tileSize=8, edgeSize=1, insets={left=1,right=1,top=1,bottom=1}})
titleListBg:SetBackdropColor(0.04, 0.045, 0.06, 0.94); titleListBg:SetBackdropBorderColor(0.45, 0.38, 0.18, 0.72)

local titleListScroll = CreateFrame("ScrollFrame", "$parentTitleListScroll", titleListBg, "UIPanelScrollFrameTemplate")
titleListScroll:SetPoint("TOPLEFT", 4, -4); titleListScroll:SetPoint("BOTTOMRIGHT", -22, 4)
local titleListContent = CreateFrame("Frame", nil, titleListScroll)
titleListContent:SetSize(titleListScroll:GetWidth(), 1); titleListScroll:SetScrollChild(titleListContent)

local titleBtns = {}
local TITLE_ROW_H = 22

local function UpdateTitles()
    local query = titleSearch:GetText():lower()
    local y = 0
    for _, b in ipairs(titleBtns) do b:Hide() end
    if Transmorpher_Titles then
        for _, t in ipairs(Transmorpher_Titles) do
            local name = t.name:gsub("%%s", ""):gsub("^%s+", ""):gsub("%s+$", "")
            if name == "" then name = t.name end
            if query == "" or name:lower():find(query, 1, true) then
                y = y + 1
                local b = titleBtns[y]
                if not b then
                    b = CreateFrame("Button", nil, titleListContent)
                    b:SetSize(titleListContent:GetWidth(), TITLE_ROW_H)
                    b:SetHighlightTexture("Interface\\Buttons\\WHITE8x8")
                    b:GetHighlightTexture():SetVertexColor(1, 0.92, 0.56, 0.12)
                    local rowBg = b:CreateTexture(nil, "BACKGROUND"); rowBg:SetAllPoints(); b.rowBg = rowBg
                    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightLeft"); fs:SetPoint("LEFT", 8, 0); b.text = fs
                    local idFs = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); idFs:SetPoint("RIGHT", -8, 0); b.idText = idFs
                    b:SetScript("OnClick", function(self)
                        ns.SendMorphCommand("TITLE:"..self.titleID)
                        if not TransmorpherCharacterState then TransmorpherCharacterState = {} end
                        TransmorpherCharacterState.TitleID = self.titleID
                        
                        if ns.BroadcastMorphState then ns.BroadcastMorphState(true) end
                        
                        SELECTED_CHAT_FRAME:AddMessage("|cffF5C842<Transmorpher>|r: Title set: "..self.titleName)
                        PlaySound("gsTitleOptionOK")
                    end)
                    titleBtns[y] = b
                end
                b.titleID = t.id; b.titleName = name; b.text:SetText(name); b.idText:SetText(t.id)
                if b.rowBg then
                    if y % 2 == 0 then b.rowBg:SetTexture(1, 1, 1, 0.025) else b.rowBg:SetTexture(0, 0, 0, 0) end
                end
                b:SetPoint("TOPLEFT", 0, -((y-1)*TITLE_ROW_H)); b:Show()
            end
        end
    end
    titleListContent:SetHeight(math.max(1, y * TITLE_ROW_H))
    if titleResultCount then
        if y > 0 then titleResultCount:SetText("|cffC8AA6E" .. y .. " titles|r")
        else titleResultCount:SetText("|cff6a6050No titles found|r") end
    end
end


titleSearch:SetScript("OnTextChanged", UpdateTitles)
