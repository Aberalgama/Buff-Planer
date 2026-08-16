-- =============================================================================
-- BuffPlaner.lua
-- Haupt-Code für das Buff Planer Addon.
-- =============================================================================

BuffPlaner = LibStub('AceAddon-3.0'):NewAddon('BuffPlaner', 'AceEvent-3.0', 'AceConsole-3.0')

-- Global variables
BuffPlaner_PlayerRows = {};

-- Register default locale
local L = LibStub("AceLocale-3.0"):NewLocale("BuffPlaner", "enUS", true)
if L then
    L["Buff Planer"] = true
    L["Minimap Icon geklickt!"] = true
    L["Rechtsklick auf Minimap Icon!"] = true
    L["Linksklick zum Öffnen der Konfiguration"] = true
    L["Rechtsklick für Log-Nachricht"] = true
end
L = LibStub("AceLocale-3.0"):GetLocale("BuffPlaner")

local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub("LibDBIcon-1.0", true)

-- Helper for 3.3.5 group members
local function GetGroupSize()
    local n = GetNumRaidMembers()
    if n > 0 then return n end
    n = GetNumPartyMembers()
    if n > 0 then return n + 1 end
    return 1
end

local function createLDBLauncher()
    local LDBObj = LibStub("LibDataBroker-1.1"):NewDataObject("BuffPlaner", {
        type = "launcher",
        label = L["Buff Planer"],
        OnClick = function(_, msg)
            BuffPlaner_ToggleConfigWindow()
        end,
        icon = "Interface\\Icons\\spell_arcane_arcaneresilience",
        OnTooltipShow = function(tooltip)
            if not tooltip or not tooltip.AddLine then return end
            tooltip:AddLine(L["Buff Planer"])
            tooltip:AddLine("|cffffff00" .. L["Linksklick zum Öffnen der Konfiguration"])
        end,
    })

    if LDBIcon then
        LDBIcon:Register("BuffPlaner", LDBObj, BuffPlanerDB.minimap)
    end
end

function BuffPlaner_OnLoad(self)
    BuffPlaner_InitializeDB();
    if LDB then createLDBLauncher() end

    if BuffPlaner_DragButton then
        BuffPlaner_DragButton:SetAttribute("type", "spell")
        BuffPlaner_DragButton:SetAttribute("spell", "Devotion of Grace")
        BuffPlaner_DragButton:SetAttribute("unit", "player")
    end

    BuffPlaner_Print("Buff Planer geladen. /buffplaner zum Öffnen.");
    SLASH_BUFFPLANNER1, SLASH_BUFFPLANNER2 = "/buffplaner", "/bp";
    SlashCmdList["BUFFPLANNER"] = BuffPlaner_OnSlashCommand;
    table.insert(UISpecialFrames, "BuffPlaner_ConfigFrame");
end

local EventFrame = CreateFrame("Frame", "BuffPlaner_EventFrame", UIParent);
EventFrame:RegisterEvent("ADDON_LOADED");
EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
EventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED");
EventFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "BuffPlaner" then BuffPlaner_OnLoad(self)
    elseif event == "PLAYER_ENTERING_WORLD" then
        if BuffPlaner_DragButton then BuffPlaner_LoadButtonPosition(BuffPlaner_DragButton) end
    elseif event == "PARTY_MEMBERS_CHANGED" then
        if BuffPlaner_ConfigFrame and BuffPlaner_ConfigFrame:IsVisible() then BuffPlaner_OnConfigShow() end
    end
end);

function BuffPlaner_Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Buff Planer]|r " .. msg, 0, 1, 0.5);
end

function BuffPlaner_GetPartyMembers()
    local members = {};
    local n = GetNumRaidMembers()
    if n > 0 then
        for i = 1, n do
            local name = UnitName("raid"..i)
            if name then table.insert(members, { name = name, unit = "raid"..i }) end
        end
    else
        local np = GetNumPartyMembers()
        if np > 0 then
            for i = 1, np do
                local name = UnitName("party"..i)
                if name then table.insert(members, { name = name, unit = "party"..i }) end
            end
        end
        table.insert(members, { name = UnitName("player"), unit = "player" })
    end
    return members;
end

-- =============================================================================
-- Config Window
-- =============================================================================

function BuffPlaner_ToggleConfigWindow()
    if BuffPlaner_ConfigFrame:IsVisible() then
        BuffPlaner_ConfigFrame:Hide()
    else
        local _, token = UnitClass("player")
        BuffPlaner_Print("Detected your class as: |cff00ffff" .. (token or "UNKNOWN") .. "|r")
        BuffPlaner_ConfigFrame:Show()
    end
end

function BuffPlaner_OnConfigShow()
    BuffPlaner_ConfigFrameTitle:SetText("Buff Planer");
    BuffPlaner_ConfigFrameInfoText:SetText("Select Buffs that you would like to have:");

    if not BuffPlaner_PlayerRows then BuffPlaner_PlayerRows = {} end
    for i, row in ipairs(BuffPlaner_PlayerRows) do row:Hide(); BuffPlaner_PlayerRows[i] = nil end

    local members, buffs = BuffPlaner_GetPartyMembers(), BuffPlaner_GetBuffs()
    local classBuffMap, scrollChild = BuffPlaner_DefaultConfig.classBuffs, BuffPlaner_ConfigFrameScrollChild
    local startY, rowHeight = 0, 70

    for _, info in ipairs(members) do
        local playerName, unit = info.name, info.unit
        local _, classToken = UnitClass(unit)
        local allowedBuffs = classBuffMap[classToken] or {}
        local classColor = RAID_CLASS_COLORS[classToken] or { r=1, g=1, b=1 }

        local rowFrame = CreateFrame("Frame", nil, scrollChild)
        rowFrame:SetSize(520, rowHeight); rowFrame:SetPoint("TOPLEFT", 10, -startY)

        -- Class Icon
        local classIcon = rowFrame:CreateTexture(nil, "OVERLAY")
        classIcon:SetSize(24, 24); classIcon:SetPoint("LEFT", 5, 0)
        local coords = CLASS_ICON_TCOORDS[classToken]
        if coords then
            classIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
            classIcon:SetTexCoord(unpack(coords))
        end

        -- Player Name
        local nameText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        nameText:SetSize(120, rowHeight); nameText:SetPoint("LEFT", classIcon, "RIGHT", 5, 0)
        nameText:SetJustifyH("LEFT");
        nameText:SetText(playerName)
        nameText:SetTextColor(classColor.r, classColor.g, classColor.b)

        local selectedKey = BuffPlanerDB.selections[playerName]
        for idx, buffKey in ipairs(allowedBuffs) do
            local buff = nil
            for _, b in ipairs(buffs) do if b.key == buffKey then buff = b; break end end

            if buff then
                local btn = CreateFrame("Button", nil, rowFrame)
                btn:SetSize(36, 36);
                btn:SetPoint("LEFT", nameText, "RIGHT", 10 + (idx-1)*50, 8) -- Moved up to make room for text

                -- Spell Icon Texture
                local castName = type(buff.spellName) == "table" and buff.spellName[1] or buff.spellName
                local _, _, spellIcon = GetSpellInfo(castName)

                local icon = btn:CreateTexture(nil, "BACKGROUND")
                icon:SetAllPoints(btn)
                icon:SetTexture(spellIcon or "Interface\\Icons\\" .. (buff.icon or "INV_Misc_QuestionMark"))
                btn.icon = icon

                -- Label Text Below Icon
                local label = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                label:SetPoint("TOP", btn, "BOTTOM", 0, -2)
                label:SetText(buff.name)
                label:SetWidth(48)
                label:SetJustifyH("CENTER")

                btn:SetBackdrop({
                    edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
                    tile=true, tileSize=16, edgeSize=12,
                    insets={left=2,right=2,top=2,bottom=2}
                })

                if selectedKey == buff.key then
                    btn:SetBackdropBorderColor(0, 1, 0, 1)
                    icon:SetVertexColor(1, 1, 1, 1)
                else
                    btn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
                    icon:SetVertexColor(0.4, 0.4, 0.4, 1)
                end

                btn.buffKey, btn.playerName = buff.key, playerName
                btn:SetScript("OnClick", function(s)
                    BuffPlanerDB.selections[s.playerName] = (BuffPlanerDB.selections[s.playerName] == s.buffKey) and nil or s.buffKey
                    BuffPlaner_OnConfigShow()
                end)

                btn:SetScript("OnEnter", function(s)
                    GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
                    GameTooltip:SetText(buff.name, 1, 1, 1)
                    GameTooltip:AddLine(castName, 0.7, 0.7, 0.7)
                    GameTooltip:Show()
                end)
                btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            end
        end
        BuffPlaner_PlayerRows[#BuffPlaner_PlayerRows+1] = rowFrame; startY = startY + rowHeight
    end
    scrollChild:SetHeight(startY + 10)
end

-- Helper to check if unit has any of the spells
local function UnitHasBuff(unit, spellInput)
    if not unit or not spellInput then return false, 0 end
    local searchList = type(spellInput) == "table" and spellInput or { spellInput }

    for i = 1, 40 do
        local name, _, _, _, _, _, expires = UnitBuff(unit, i)
        if not name then break end
        for _, searchName in ipairs(searchList) do
            if name == searchName then return true, expires end
        end
    end
    return false, 0
end

function BuffPlaner_ToggleBuffButton()
    local k = UnitName("player") .. " - " .. GetRealmName()
    if not BuffPlanerDB.buttonPos[k] then BuffPlanerDB.buttonPos[k] = {} end
    if BuffPlaner_DragButton:IsVisible() then BuffPlaner_DragButton:Hide(); BuffPlanerDB.buttonPos[k].show = false
    else BuffPlaner_DragButton:Show(); BuffPlanerDB.buttonPos[k].show = true end
end

-- Helper to check if unit is in range for a buff
local function UnitIsInRange(unit, buff)
    if unit == "player" then return true end
    if not unit or not buff then return false end

    local castName = type(buff.spellName) == "table" and buff.spellName[1] or buff.spellName
    -- 1. Try most accurate check: IsSpellInRange
    local inRange = IsSpellInRange(castName, unit)
    if inRange ~= nil then return inRange == 1 end

    -- 2. Fallback to hardcoded yard estimation if spell check fails (e.g., spell not known)
    local range = buff.range or 40
    if range >= 40 then return CheckInteractDistance(unit, 4) -- ~28-30yd fallback
    elseif range >= 10 then return CheckInteractDistance(unit, 3) -- ~10yd fallback
    else return CheckInteractDistance(unit, 2) end -- ~7yd fallback
end

function BuffPlaner_OnBuffButtonClicked(self)
    if InCombatLockdown() then return end
    local members, target, cast = BuffPlaner_GetPartyMembers(), "player", "Devotion of Grace"
    local minExp, found = 999999, false

    -- Check for "Big Buff" (Raid version)
    local groupWantsSame = nil
    local allSame = true
    local anySeletionForMe = false

    for _, info in ipairs(members) do
        local selKey = BuffPlanerDB.selections[info.name]
        if selKey then
            if not groupWantsSame then groupWantsSame = selKey end
            if groupWantsSame ~= selKey then allSame = false end
            anySeletionForMe = true
        end
    end

    local raidSpell = nil
    if anySeletionForMe and allSame then
        local b = BuffPlaner_GetBuffByKey(groupWantsSame)
        if b and b.raidSpellName then raidSpell = b.raidSpellName end
    end

    if raidSpell then
        BuffPlaner_Print("Mode: RAID BUFF -> " .. raidSpell);
        self:SetAttribute("unit", "player");
        self:SetAttribute("spell", raidSpell);
        return
    end

    -- Regular Single Target Logic
    for _, info in ipairs(members) do
        local unit = info.unit
        if unit and not UnitIsDeadOrGhost(unit) then
            local sel = BuffPlanerDB.selections[info.name]
            if sel then
                local b = BuffPlaner_GetBuffByKey(sel)
                if b and UnitIsInRange(unit, b) then
                    local has, exp = UnitHasBuff(unit, b.spellName)
                    local spellToCast = type(b.spellName) == "table" and b.spellName[1] or b.spellName

                    if not has then
                        target, cast, found = unit, spellToCast, true; break
                    elseif not found and exp and exp > 0 then
                        local rem = exp - GetTime(); if rem < minExp then minExp, target, cast = rem, unit, spellToCast end
                    end
                end
            end
        end
    end
    BuffPlaner_Print("Targeting " .. (UnitName(target) or "self") .. " for " .. cast);
    self:SetAttribute("unit", target); self:SetAttribute("spell", cast)
end

function BuffPlaner_UpdateBuffButton()
    local text, btn = BuffPlaner_DragButtonText, BuffPlaner_DragButton
    if not text or not btn then return end
    local members, need, minExp, any = BuffPlaner_GetPartyMembers(), false, 999999, false

    for _, info in ipairs(members) do
        local unit = info.unit
        if unit and not UnitIsDeadOrGhost(unit) then
            local sel = BuffPlanerDB.selections[info.name]
            if sel then
                any = true;
                local b = BuffPlaner_GetBuffByKey(sel)
                if b and UnitIsInRange(unit, b) then
                    local has, exp = UnitHasBuff(unit, b.spellName)
                    if not has then
                        need = true;
                    else
                        if exp and exp > 0 then
                            local rem = exp - GetTime();
                            if rem < minExp then minExp = rem end
                        end
                    end
                end
            end
        end
    end
    if need then text:SetText("BUFF"); btn:SetBackdropColor(0.8, 0, 0, 1); btn:SetBackdropBorderColor(1, 1, 1, 0.5)
    elseif any then
        if minExp < 999999 then text:SetText(string.format("%d:%02d", math.floor(minExp / 60), math.floor(minExp % 60))) else text:SetText("OK") end
        btn:SetBackdropColor(0, 0.6, 0, 1); btn:SetBackdropBorderColor(1, 1, 1, 0.5)
    else text:SetText("WAIT"); btn:SetBackdropColor(0.2, 0.2, 0.2, 0.8); btn:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.5) end
end

function BuffPlaner_SaveButtonPosition(frame)
    local p, _, rp, x, y = frame:GetPoint(); local k = UnitName("player") .. " - " .. GetRealmName()
    if not BuffPlanerDB.buttonPos[k] then BuffPlanerDB.buttonPos[k] = {} end
    BuffPlanerDB.buttonPos[k].point, BuffPlanerDB.buttonPos[k].relativePoint = p, rp
    BuffPlanerDB.buttonPos[k].xOfs, BuffPlanerDB.buttonPos[k].yOfs = x, y
end

function BuffPlaner_LoadButtonPosition(frame)
    local k = UnitName("player") .. " - " .. GetRealmName(); local pos = BuffPlanerDB.buttonPos[k]
    if pos and pos.point then frame:ClearAllPoints(); frame:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.xOfs or 0, pos.yOfs or 0)
    else frame:ClearAllPoints(); frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0) end
    if pos and pos.show ~= nil then if pos.show then frame:Show() else frame:Hide() end else frame:Show() end
end

local updateTimer = 0;
EventFrame:SetScript("OnUpdate", function(self, elapsed)
    updateTimer = updateTimer + elapsed;
    if updateTimer >= 1 then
        updateTimer = 0;
        if BuffPlaner_DragButton and BuffPlaner_DragButton:IsVisible() then BuffPlaner_UpdateBuffButton() end
    end
end);

function BuffPlaner_OnSlashCommand(msg)
    if msg == "config" then BuffPlaner_ToggleConfigWindow()
    elseif msg == "buffbutton" then BuffPlaner_ToggleBuffButton()
    elseif msg == "check" then
        BuffPlaner_Print("Checking Spell Icons in DB:")
        local buffs = BuffPlaner_GetBuffs()
        for _, b in ipairs(buffs) do
            local castName = type(b.spellName) == "table" and b.spellName[1] or b.spellName
            local name, _, tex = GetSpellInfo(castName)
            if name then
                BuffPlaner_Print(string.format("|T%s:16|t %s -> Icon: |cff00ffff%s|r", tex, name, tex:match("([^%\\]+)$") or tex))
            else
                BuffPlaner_Print(string.format("|cffff0000Error:|r Spell '%s' not found in your spellbook!", castName))
            end
        end
    else BuffPlaner_Print("/bp config, /bp buffbutton, or /bp check") end
end
