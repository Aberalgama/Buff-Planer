-- =============================================================================
-- BuffPlaner.lua
-- Haupt-Code für das Buff Planer Addon.
-- =============================================================================

BuffPlaner = LibStub('AceAddon-3.0'):NewAddon('BuffPlaner', 'AceEvent-3.0', 'AceConsole-3.0')

-- Runtime data
BuffPlaner.RemoteKnownBuffs = {}
BuffPlaner.WishesFromOthers = {} -- [CleanName] = buffKey
local SYNC_PREFIX = "BP_SYNC"
BuffPlaner_PlayerRows = {};

-- Register default locale
local L = LibStub("AceLocale-3.0"):NewLocale("BuffPlaner", "enUS", true)
if L then
    L["Buff Planer"] = true
    L["Minimap Icon geklickt!"] = true
    L["Rechtsklick zum Öffnen der Konfiguration"] = true
    L["Linksklick zum Öffnen der Konfiguration"] = true
end
L = LibStub("AceLocale-3.0"):GetLocale("BuffPlaner")

local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub("LibDBIcon-1.0", true)

-- Helper: Remove realm name and normalize
local function GetCleanName(name)
    if not name then return nil end
    local clean = name:match("([^%-]+)")
    return clean:gsub("^%s*(.-)%s*$", "%1") -- Trim spaces
end

local function createLDBLauncher()
    local LDBObj = LibStub("LibDataBroker-1.1"):NewDataObject("BuffPlaner", {
        type = "launcher",
        label = L["Buff Planer"],
        OnClick = function() BuffPlaner_ToggleConfigWindow() end,
        icon = "Interface\\Icons\\spell_arcane_arcaneresilience",
        OnTooltipShow = function(tooltip)
            if not tooltip or not tooltip.AddLine then return end
            tooltip:AddLine(L["Buff Planer"])
            tooltip:AddLine("|cffffff00" .. L["Linksklick zum Öffnen der Konfiguration"])
        end,
    })
    if LDBIcon then LDBIcon:Register("BuffPlaner", LDBObj, BuffPlanerDB.minimap) end
end

function BuffPlaner_OnLoad(self)
    BuffPlaner_InitializeDB();
    if LDB then createLDBLauncher() end

    if BuffPlaner_DragButton then
        -- Clear all legacy attributes to prevent accidental self-buffing
        BuffPlaner_DragButton:SetAttribute("type", "macro")
        BuffPlaner_DragButton:SetAttribute("unit", nil)
        BuffPlaner_DragButton:SetAttribute("spell", nil)
    end

    BuffPlaner_Print("Buff Planer geladen. /buffplaner zum Öffnen.");
    SLASH_BUFFPLANNER1, SLASH_BUFFPLANNER2 = "/buffplaner", "/bp";
    SlashCmdList["BUFFPLANNER"] = BuffPlaner_OnSlashCommand;
    table.insert(UISpecialFrames, "BuffPlaner_ConfigFrame");
end

local EventFrame = CreateFrame("Frame", "BuffPlaner_EventFrame", UIParent);
EventFrame:RegisterEvent("ADDON_LOADED");
EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
EventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
EventFrame:RegisterEvent("CHAT_MSG_ADDON")
EventFrame:RegisterEvent("PLAYER_TARGET_CHANGED") -- Update instantly when targeting

EventFrame:SetScript("OnEvent", function(self, event, ...)
    local arg1, arg2, _, arg4 = ...
    if event == "ADDON_LOADED" and arg1 == "BuffPlaner" then BuffPlaner_OnLoad(self)
    elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_TARGET_CHANGED" then
        if BuffPlaner_DragButton then
            if event == "PLAYER_ENTERING_WORLD" then BuffPlaner_LoadButtonPosition(BuffPlaner_DragButton) end
            BuffPlaner_UpdateBuffButton()
        end
        if event == "PLAYER_ENTERING_WORLD" then BuffPlaner_RequestSync() end
    elseif event == "PARTY_MEMBERS_CHANGED" then
        BuffPlaner_RequestSync()
        if BuffPlaner_ConfigFrame and BuffPlaner_ConfigFrame:IsVisible() then BuffPlaner_OnConfigShow() end
    elseif event == "CHAT_MSG_ADDON" and arg1 == SYNC_PREFIX then
        BuffPlaner_HandleSync(arg2, arg4)
    end
end);

function BuffPlaner_Print(msg)
    -- DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Buff Planer]|r " .. msg, 0, 1, 0.5);
end

function BuffPlaner_GetPartyMembers()
    local members = {};
    local myName = GetCleanName(UnitName("player"))

    -- Always put self FIRST in the scanning priority
    table.insert(members, { name = myName, unit = "player" })

    local nr = GetNumRaidMembers()
    if nr > 0 then
        for i = 1, nr do
            local name = UnitName("raid"..i)
            if name and GetCleanName(name) ~= myName then
                table.insert(members, { name = GetCleanName(name), unit = "raid"..i })
            end
        end
    else
        local np = GetNumPartyMembers()
        for i = 1, np do
            local name = UnitName("party"..i)
            if name and GetCleanName(name) ~= myName then
                table.insert(members, { name = GetCleanName(name), unit = "party"..i })
            end
        end
    end

    return members;
end

-- =============================================================================
-- Sync & Knowledge
-- =============================================================================

function BuffPlaner_RequestSync()
    local mode = GetNumRaidMembers() > 0 and "RAID" or (GetNumPartyMembers() > 0 and "PARTY" or nil)
    if mode then
        SendAddonMessage(SYNC_PREFIX, "REQ", mode)
        BuffPlaner_BroadcastWishes()
    end
end

function BuffPlaner_BroadcastWishes()
    local mode = GetNumRaidMembers() > 0 and "RAID" or (GetNumPartyMembers() > 0 and "PARTY" or nil)
    if not mode then return end
    local wishStr = ""
    for provider, key in pairs(BuffPlanerDB.selections) do
        wishStr = wishStr .. provider .. ":" .. key .. ";"
    end
    if wishStr ~= "" then SendAddonMessage(SYNC_PREFIX, "WISH:" .. wishStr, mode) end
end

function BuffPlaner_HandleSync(message, sender)
    local cleanSender = GetCleanName(sender)
    if cleanSender == GetCleanName(UnitName("player")) then return end
    local mode = GetNumRaidMembers() > 0 and "RAID" or "PARTY"

    if message == "REQ" then
        local known = ""
        for _, b in ipairs(BuffPlaner_GetBuffs()) do
            local cast = type(b.spellName) == "table" and b.spellName[1] or b.spellName
            if GetSpellInfo(cast) then known = known .. b.key .. "," end
        end
        if known ~= "" then SendAddonMessage(SYNC_PREFIX, "DATA:" .. known, mode) end
        BuffPlaner_BroadcastWishes()
    elseif message:find("^DATA:") then
        local keys = {}
        for k in message:sub(6):gmatch("([^,]+)") do keys[k] = true end
        BuffPlaner.RemoteKnownBuffs[cleanSender] = keys
        if BuffPlaner_ConfigFrame and BuffPlaner_ConfigFrame:IsVisible() then BuffPlaner_OnConfigShow() end
    elseif message:find("^WISH:") then
        local myName = GetCleanName(UnitName("player"))
        for entry in message:sub(6):gmatch("([^;]+)") do
            local provider, key = entry:match("([^:]+):([^:]+)")
            if provider and GetCleanName(provider) == myName then
                BuffPlaner.WishesFromOthers[cleanSender] = key
            end
        end
    end
end

-- =============================================================================
-- Config UI
-- =============================================================================

function BuffPlaner_ToggleConfigWindow()
    if BuffPlaner_ConfigFrame:IsVisible() then
        BuffPlaner_ConfigFrame:Hide()
    else
        local _, token = UnitClass("player")
        BuffPlaner_Print("Detected your class as: |cff00ffff" .. (token or "UNKNOWN") .. "|r")
        BuffPlaner_RequestSync()
        BuffPlaner_ConfigFrame:Show()
    end
end

function BuffPlaner_OnConfigShow()
    BuffPlaner_ConfigFrameTitle:SetText("Buff Planer");

    local _, myToken = UnitClass("player")
    -- Use standard print for debug to ensure it's seen
    -- print("|cff00ff00[Buff Planer]|r DEBUG: Your Class Token is: |cff00ffff" .. (myToken or "NIL") .. "|r")

    if not BuffPlaner_PlayerRows then BuffPlaner_PlayerRows = {} end
    for i, row in ipairs(BuffPlaner_PlayerRows) do row:Hide(); BuffPlaner_PlayerRows[i] = nil end

    local members, buffs = BuffPlaner_GetPartyMembers(), BuffPlaner_GetBuffs()
    local classBuffMap, scrollChild = BuffPlaner_DefaultConfig.classBuffs, BuffPlaner_ConfigFrameScrollChild
    local startY, rowHeight = 0, 95

    for _, info in ipairs(members) do
        local playerName, unit = info.name, info.unit
        local _, classToken = UnitClass(unit)
        local allowedBuffs = classToken and (classBuffMap[classToken] or classBuffMap[classToken:upper()]) or {}
        local classColor = (classToken and RAID_CLASS_COLORS[classToken:upper()]) or { r=1, g=1, b=1 }

        local rowFrame = CreateFrame("Frame", nil, scrollChild)
        rowFrame:SetSize(520, rowHeight); rowFrame:SetPoint("TOPLEFT", 10, -startY)

        local classIcon = rowFrame:CreateTexture(nil, "OVERLAY")
        classIcon:SetSize(24, 24); classIcon:SetPoint("LEFT", 5, 10)
        local coords = CLASS_ICON_TCOORDS[classToken]
        if coords then classIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"); classIcon:SetTexCoord(unpack(coords)) end

        local nameText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        nameText:SetSize(120, rowHeight); nameText:SetPoint("LEFT", classIcon, "RIGHT", 5, 10); nameText:SetJustifyH("LEFT")
        nameText:SetText(playerName); nameText:SetTextColor(classColor.r, classColor.g, classColor.b)

        local selectedKey, renderIdx = BuffPlanerDB.selections[playerName], 1
        for _, buffKey in ipairs(allowedBuffs) do
            local buff = nil
            for _, b in ipairs(buffs) do if b.key == buffKey then buff = b; break end end
            if buff then
                local castName = type(buff.spellName) == "table" and buff.spellName[1] or buff.spellName
                local knows = (unit == "player") and GetSpellInfo(castName) or (BuffPlaner.RemoteKnownBuffs[playerName] and BuffPlaner.RemoteKnownBuffs[playerName][buff.key])

                if knows then
                    local btn = CreateFrame("Button", nil, rowFrame)
                    btn:SetSize(36, 36); btn:SetPoint("LEFT", nameText, "RIGHT", 10 + (renderIdx-1)*55, 15)
                    local _, _, spellIcon = GetSpellInfo(castName)
                    local icon = btn:CreateTexture(nil, "BACKGROUND"); icon:SetAllPoints(btn); icon:SetTexture(spellIcon or "Interface\\Icons\\" .. (buff.icon or "INV_Misc_QuestionMark"))
                    btn:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=16, edgeSize=12, insets={left=2,right=2,top=2,bottom=2}})
                    if selectedKey == buff.key then btn:SetBackdropBorderColor(0, 1, 0, 1); icon:SetVertexColor(1, 1, 1, 1)
                    else btn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1); icon:SetVertexColor(0.4, 0.4, 0.4, 1) end

                    local label = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    label:SetPoint("TOP", btn, "BOTTOM", 0, -2); label:SetText(buff.name); label:SetWidth(48); label:SetJustifyH("CENTER")

                    btn.buffKey, btn.playerName = buff.key, playerName
                    btn:SetScript("OnClick", function(s)
                        local cur = BuffPlanerDB.selections[s.playerName]
                        if cur == s.buffKey then BuffPlanerDB.selections[s.playerName] = nil else BuffPlanerDB.selections[s.playerName] = s.buffKey end
                        BuffPlaner_BroadcastWishes()
                        BuffPlaner_OnConfigShow()
                    end)
                    btn:SetScript("OnEnter", function(s) GameTooltip:SetOwner(s, "ANCHOR_RIGHT"); GameTooltip:SetText(buff.name, 1, 1, 1); GameTooltip:AddLine(castName, 0.7, 0.7, 0.7); GameTooltip:Show() end)
                    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
                    renderIdx = renderIdx + 1
                end
            end
        end
        BuffPlaner_PlayerRows[#BuffPlaner_PlayerRows+1] = rowFrame; startY = startY + rowHeight
    end
    scrollChild:SetHeight(startY + 10)
end

-- =============================================================================
-- Buff Button Core Logic
-- =============================================================================

local function UnitHasBuff(unit, spellInput)
    if not unit then return false, 0 end
    local searchList = type(spellInput) == "table" and spellInput or { spellInput }
    for i = 1, 40 do
        local name, _, _, _, _, _, expires = UnitBuff(unit, i)
        if not name then break end
        for _, searchName in ipairs(searchList) do if name == searchName then return true, expires end end
    end
    return false, 0
end

local function UnitIsInRange(unit, buff)
    if not unit or not buff then return false end
    if unit == "player" then return true end
    local castName = type(buff.spellName) == "table" and buff.spellName[1] or buff.spellName
    -- 1. Try spell range (dynamic)
    local inRange = IsSpellInRange(castName, unit)
    if inRange ~= nil then return inRange == 1 end
    -- 2. Try unit check (WotLK 40yd)
    if UnitInRange(unit) then return true end
    -- 3. Last fallback (Interact 30yd)
    return CheckInteractDistance(unit, 4)
end

function BuffPlaner_UpdateBuffButton()
    local text, btn = BuffPlaner_DragButtonText, BuffPlaner_DragButton
    if not text or not btn then return end

    local members = BuffPlaner_GetPartyMembers()
    local someoneNeedsBuff, minExp, any = false, 999999, false
    local myName = GetCleanName(UnitName("player"))
    local targetUnitToken, targetName, castSpellName = nil, nil, nil

    local recipients = {}
    for name, key in pairs(BuffPlaner.WishesFromOthers) do recipients[name] = key end
    if BuffPlanerDB.selections[myName] then recipients[myName] = BuffPlanerDB.selections[myName] end

    -- Pass 1: Check Current Target (if valid player)
    if UnitExists("target") and UnitIsPlayer("target") and not UnitIsDeadOrGhost("target") then
        local tName = GetCleanName(UnitName("target"))
        local desiredKey = recipients[tName]
        if desiredKey then
            local b = BuffPlaner_GetBuffByKey(desiredKey)
            if b and UnitIsInRange("target", b) then
                local has, exp = UnitHasBuff("target", b.spellName)
                local spellToCast = type(b.spellName) == "table" and b.spellName[1] or b.spellName
                if not has then
                    someoneNeedsBuff, targetUnitToken, targetName, castSpellName = true, (UnitIsUnit("target", "player") and "player" or "target"), tName, spellToCast
                else
                    any, minExp = true, (exp - GetTime())
                    targetUnitToken, targetName, castSpellName = (UnitIsUnit("target", "player") and "player" or "target"), tName, spellToCast
                end
            end
        end
    end

    -- Pass 2: Check Party/Raid Members
    if not someoneNeedsBuff then
        for _, info in ipairs(members) do
            local recipientName, unit = info.name, info.unit
            local desiredKey = recipients[recipientName]
            if desiredKey and unit and not UnitIsDeadOrGhost(unit) then
                local b = BuffPlaner_GetBuffByKey(desiredKey)
                if b and UnitIsInRange(unit, b) then
                    any = true;
                    local has, exp = UnitHasBuff(unit, b.spellName)
                    local spellToCast = type(b.spellName) == "table" and b.spellName[1] or b.spellName

                    if not has then
                        someoneNeedsBuff = true;
                        if not targetUnitToken then targetUnitToken, targetName, castSpellName = unit, recipientName, spellToCast end
                    elseif exp and exp > 0 then
                        local rem = exp - GetTime();
                        if rem < minExp then
                            minExp = rem
                            if not targetUnitToken or not someoneNeedsBuff then
                                targetUnitToken, targetName, castSpellName = unit, recipientName, spellToCast
                            end
                        end
                    end
                end
            end
        end
    end

    -- PRE-ARM the button (only out of combat)
    if not InCombatLockdown() then
        if targetUnitToken and castSpellName then
            btn:SetAttribute("type", "spell")
            btn:SetAttribute("unit", targetUnitToken)
            btn:SetAttribute("spell", castSpellName)
            btn.armedName, btn.armedSpell = targetName, castSpellName
        else
            btn:SetAttribute("unit", nil)
            btn:SetAttribute("spell", nil)
            btn.armedName, btn.armedSpell = nil, nil
        end
    end

    if someoneNeedsBuff then
        text:SetFontObject("GameFontNormalLarge")
        text:SetText("BUFF");
        btn:SetBackdropColor(0.8, 0, 0, 1)
    elseif any then
        text:SetFontObject("GameFontNormalLarge")
        if minExp < 999999 then
            local m, s = math.floor(minExp/60), math.floor(minExp%60)
            text:SetText(string.format("%d:%02d", m, s))
        else text:SetText("OK") end
        btn:SetBackdropColor(0, 0.6, 0, 1)
    else
        text:SetFontObject("GameFontNormalSmall")
        text:SetText("Select\nBuff");
        btn:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
    end
end

function BuffPlaner_OnBuffButtonClicked(self)
    if self.armedName and self.armedSpell then
        BuffPlaner_Print("Buffing: |cff00ffff" .. self.armedName .. "|r with " .. self.armedSpell)
    else
        -- If no buff is selected or armed, open the config window
        BuffPlaner_ToggleConfigWindow()
    end
end

-- =============================================================================
-- Button Persistence
-- =============================================================================

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

function BuffPlaner_ToggleBuffButton()
    local k = UnitName("player") .. " - " .. GetRealmName()
    if not BuffPlanerDB.buttonPos[k] then BuffPlanerDB.buttonPos[k] = {} end
    if BuffPlaner_DragButton:IsVisible() then BuffPlaner_DragButton:Hide(); BuffPlanerDB.buttonPos[k].show = false
    else BuffPlaner_DragButton:Show(); BuffPlanerDB.buttonPos[k].show = true end
end

local updateTimer = 0;
EventFrame:SetScript("OnUpdate", function(self, elapsed)
    updateTimer = updateTimer + elapsed;
    if updateTimer >= 1 then updateTimer = 0; if BuffPlaner_DragButton and BuffPlaner_DragButton:IsVisible() then BuffPlaner_UpdateBuffButton() end end
end);

function BuffPlaner_OnSlashCommand(msg)
    if msg == "config" then BuffPlaner_ToggleConfigWindow()
    elseif msg == "buffbutton" then BuffPlaner_ToggleBuffButton()
    elseif msg == "check" then
        for _, b in ipairs(BuffPlaner_GetBuffs()) do
            local c = type(b.spellName) == "table" and b.spellName[1] or b.spellName
            local n, _, t = GetSpellInfo(c)
            if n then BuffPlaner_Print(string.format("|T%s:16|t %s -> |cff00ffff%s|r", t, n, t:match("([^%\\]+)$") or t))
            else BuffPlaner_Print("|cffff0000Error:|r Spell '"..c.."' not found!") end
        end
    else BuffPlaner_Print("/bp config, /bp buffbutton, or /bp check") end
end
