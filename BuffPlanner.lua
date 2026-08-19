-- =============================================================================
-- BuffPlanner.lua
-- Haupt-Code für das Buff Planner Addon.
-- =============================================================================

BuffPlanner = LibStub('AceAddon-3.0'):NewAddon('BuffPlanner', 'AceEvent-3.0', 'AceConsole-3.0')

-- Runtime data
BuffPlanner.RemoteKnownBuffs = {}
BuffPlanner.WishesFromOthers = {} -- [CleanName] = buffKey
BuffPlanner.HasAddon = {} -- [CleanName] = true
local SYNC_PREFIX = "BP_SYNC"
BuffPlanner_PlayerRows = {};

local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub("LibDBIcon-1.0", true)

-- Helper: Remove realm name and normalize
local function GetCleanName(name)
    if not name then return nil end
    local clean = name:match("([^%-]+)")
    return clean:gsub("^%s*(.-)%s*$", "%1") -- Trim spaces
end

local function createLDBLauncher()
    local LDBObj = LibStub("LibDataBroker-1.1"):NewDataObject("BuffPlanner", {
        type = "launcher",
        label = "Buff Planner",
        OnClick = function() BuffPlanner_ToggleConfigWindow() end,
        icon = "Interface\\Icons\\spell_arcane_arcaneresilience",
        OnTooltipShow = function(tooltip)
            if not tooltip or not tooltip.AddLine then return end
            tooltip:AddLine("Buff Planner")
            tooltip:AddLine("|cffffff00Left click to open Buff Planner.")
            tooltip:AddLine("|cffffff00Alt + Left click & drag to move BUFF button.")
        end,
    })
    if LDBIcon then LDBIcon:Register("BuffPlanner", LDBObj, BuffPlannerDB.minimap) end
end

function BuffPlanner_OnLoad(self)
    BuffPlanner_InitializeDB();
    if LDB then createLDBLauncher() end

    if BuffPlanner_DragButton then
        -- Clear all legacy attributes to prevent accidental self-buffing
        BuffPlanner_DragButton:SetAttribute("type", "macro")
        BuffPlanner_DragButton:SetAttribute("unit", nil)
        BuffPlanner_DragButton:SetAttribute("spell", nil)

        -- Apply character-specific settings
        local settings = BuffPlanner_GetCharSettings()
        BuffPlanner_ApplyButtonSize(settings.buttonSize)
        BuffPlanner_RefreshButtonVisibility()
    end

    -- BuffPlanner_Print("Buff Planner geladen. /buffplanner zum Öffnen.");
    SLASH_BUFFPLANNER1, SLASH_BUFFPLANNER2, SLASH_BUFFPLANNER3 = "/buffplanner", "/bp", "/buffplanner";
    SlashCmdList["BUFFPLANNER"] = BuffPlanner_OnSlashCommand;
    table.insert(UISpecialFrames, "BuffPlanner_ConfigFrame");
end

local EventFrame = CreateFrame("Frame", "BuffPlanner_EventFrame", UIParent);
EventFrame:RegisterEvent("ADDON_LOADED");
EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
EventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
EventFrame:RegisterEvent("CHAT_MSG_ADDON")
EventFrame:RegisterEvent("PLAYER_TARGET_CHANGED") -- Update instantly when targeting

EventFrame:SetScript("OnEvent", function(self, event, ...)
    local arg1, arg2, _, arg4 = ...
    if event == "ADDON_LOADED" and arg1 == "BuffPlanner" then BuffPlanner_OnLoad(self)
    elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_TARGET_CHANGED" then
        if BuffPlanner_DragButton then
            if event == "PLAYER_ENTERING_WORLD" then BuffPlanner_LoadButtonPosition(BuffPlanner_DragButton) end
            BuffPlanner_RefreshButtonVisibility()
            BuffPlanner_UpdateBuffButton()
        end
        if event == "PLAYER_ENTERING_WORLD" then BuffPlanner_RequestSync() end
    elseif event == "PARTY_MEMBERS_CHANGED" then
        BuffPlanner_RefreshButtonVisibility()
        BuffPlanner_RequestSync()
        if BuffPlanner_ConfigFrame and BuffPlanner_ConfigFrame:IsVisible() then BuffPlanner_OnConfigShow() end
    elseif event == "CHAT_MSG_ADDON" and arg1 == SYNC_PREFIX then
        BuffPlanner_HandleSync(arg2, arg4)
    end
end);

function BuffPlanner_Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Buff Planner]|r " .. msg);
end

function BuffPlanner_GetPartyMembers()
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

function BuffPlanner_RequestSync()
    local mode = GetNumRaidMembers() > 0 and "RAID" or (GetNumPartyMembers() > 0 and "PARTY" or nil)
    if mode then
        SendAddonMessage(SYNC_PREFIX, "REQ", mode)
        BuffPlanner_BroadcastWishes()
    end
end

function BuffPlanner_BroadcastWishes()
    local mode = GetNumRaidMembers() > 0 and "RAID" or (GetNumPartyMembers() > 0 and "PARTY" or nil)
    if not mode then return end
    local wishStr = ""
    for provider, key in pairs(BuffPlannerDB.selections) do
        wishStr = wishStr .. provider .. ":" .. key .. ";"
    end
    if wishStr ~= "" then SendAddonMessage(SYNC_PREFIX, "WISH:" .. wishStr, mode) end
end

function BuffPlanner_HandleSync(message, sender)
    local cleanSender = GetCleanName(sender)
    if cleanSender == GetCleanName(UnitName("player")) then return end

    -- Anyone who sends a message has the addon
    BuffPlanner.HasAddon[cleanSender] = true

    local mode = GetNumRaidMembers() > 0 and "RAID" or "PARTY"

    if message == "REQ" then
        local known = ""
        for _, b in ipairs(BuffPlanner_GetBuffs()) do
            local cast = type(b.spellName) == "table" and b.spellName[1] or b.spellName
            if GetSpellInfo(cast) then known = known .. b.key .. "," end
        end
        if known ~= "" then SendAddonMessage(SYNC_PREFIX, "DATA:" .. known, mode) end
        BuffPlanner_BroadcastWishes()
    elseif message:find("^DATA:") then
        local keys = {}
        for k in message:sub(6):gmatch("([^,]+)") do keys[k] = true end
        BuffPlanner.RemoteKnownBuffs[cleanSender] = keys
        if BuffPlanner_ConfigFrame and BuffPlanner_ConfigFrame:IsVisible() then BuffPlanner_OnConfigShow() end
    elseif message:find("^WISH:") then
        local myName = GetCleanName(UnitName("player"))
        for entry in message:sub(6):gmatch("([^;]+)") do
            local provider, key = entry:match("([^:]+):([^:]+)")
            if provider and GetCleanName(provider) == myName then
                BuffPlanner.WishesFromOthers[cleanSender] = key
            end
        end
    end
end

-- =============================================================================
-- Config UI
-- =============================================================================

function BuffPlanner_SetTab(id)
    local frame = BuffPlanner_ConfigFrame
    frame.numTabs = 2
    PanelTemplates_SetTab(frame, id)

    if id == 1 then
        BuffPlanner_PlannerPage:Show()
        BuffPlanner_SettingsPage:Hide()
        BuffPlanner_OnConfigShow()
    else
        BuffPlanner_PlannerPage:Hide()
        BuffPlanner_SettingsPage:Show()

        local settings = BuffPlanner_GetCharSettings()
        if BuffPlanner_SettingsButtonSizeSlider then
            BuffPlanner_SettingsButtonSizeSlider:SetValue(settings.buttonSize)
        end
        if BuffPlanner_SettingsShowSoloCheckbox then
            BuffPlanner_SettingsShowSoloCheckbox:SetChecked(settings.showSolo and 1 or nil)
        end
    end
end

function BuffPlanner_ToggleConfigWindow()
    if BuffPlanner_ConfigFrame:IsVisible() then
        BuffPlanner_ConfigFrame:Hide()
    else
        BuffPlanner_RequestSync()
        BuffPlanner_ConfigFrame:Show()
    end
end

function BuffPlanner_OnConfigShow()
    -- Initialize Tab System for the frame
    BuffPlanner_ConfigFrame.numTabs = 2
    PanelTemplates_UpdateTabs(BuffPlanner_ConfigFrame)

    if not BuffPlanner_PlannerPage:IsVisible() then return end
    BuffPlanner_ConfigFrameTitle:SetText("Buff Planner");

    local _, myToken = UnitClass("player")
    -- Use standard print for debug to ensure it's seen
    -- print("|cff00ff00[Buff Planner]|r DEBUG: Your Class Token is: |cff00ffff" .. (myToken or "NIL") .. "|r")

    if not BuffPlanner_PlayerRows then BuffPlanner_PlayerRows = {} end
    for i, row in ipairs(BuffPlanner_PlayerRows) do row:Hide(); BuffPlanner_PlayerRows[i] = nil end

    local members, buffs = BuffPlanner_GetPartyMembers(), BuffPlanner_GetBuffs()
    local classBuffMap, scrollChild = BuffPlanner_DefaultConfig.classBuffs, BuffPlanner_ConfigFrameScrollChild

    local startY = 2 -- Initial padding from top
    local rowPadding = 4 -- Padding between rows
    local hPadding = 2
    local rowWidth = 518

    for _, info in ipairs(members) do
        local playerName, unit = info.name, info.unit
        local _, classToken = UnitClass(unit)
        local allowedBuffs = classToken and (classBuffMap[classToken] or classBuffMap[classToken:upper()]) or {}
        local classColor = (classToken and RAID_CLASS_COLORS[classToken:upper()]) or { r=1, g=1, b=1 }

        local rowFrame = CreateFrame("Frame", nil, scrollChild)
        rowFrame:SetWidth(rowWidth) -- Slightly smaller for padding
        rowFrame:SetPoint("TOPLEFT", hPadding, -startY) -- 10px padding from left

        -- Add Border and Background to Row
        rowFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        rowFrame:SetBackdropColor(0, 0, 0, 0.4)

        -- Class Icon (Centered Vertically)
        local classIcon = rowFrame:CreateTexture(nil, "OVERLAY")
        classIcon:SetSize(24, 24); classIcon:SetPoint("LEFT", 10, 0)
        local coords = CLASS_ICON_TCOORDS[classToken]
        if coords then classIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"); classIcon:SetTexCoord(unpack(coords)) end

        -- Player Name (Centered Vertically)
        local nameText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        nameText:SetSize(110, 24); nameText:SetPoint("LEFT", classIcon, "RIGHT", 5, 0)
        nameText:SetJustifyH("LEFT"); nameText:SetJustifyV("MIDDLE")
        nameText:SetText(playerName); nameText:SetTextColor(classColor.r, classColor.g, classColor.b)

        local selectedKey, renderIdx = BuffPlannerDB.selections[playerName], 1
        local rowHeight = 46 -- Compact fixed height without labels
        rowFrame:SetHeight(rowHeight)

        for _, buffKey in ipairs(allowedBuffs) do
            local buff = nil
            for _, b in ipairs(buffs) do if b.key == buffKey then buff = b; break end end
            if buff then
                local castName = type(buff.spellName) == "table" and buff.spellName[1] or buff.spellName

                local hasAddon = (unit == "player") or BuffPlanner.HasAddon[playerName]
                local knows = (unit == "player") and GetSpellInfo(castName) or (BuffPlanner.RemoteKnownBuffs[playerName] and BuffPlanner.RemoteKnownBuffs[playerName][buff.key])

                local btn = CreateFrame("Button", nil, rowFrame)
                btn:SetSize(34, 34);
                btn:SetPoint("LEFT", nameText, "RIGHT", 10 + (renderIdx-1)*42, 0) -- Compact spacing

                -- Spell Icon Texture
                local _, _, spellIcon = GetSpellInfo(castName)
                local icon = btn:CreateTexture(nil, "BACKGROUND"); icon:SetAllPoints(btn)
                icon:SetTexture(spellIcon or "Interface\\Icons\\" .. (buff.icon or "INV_Misc_QuestionMark"))
                btn.icon = icon

                btn:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=16, edgeSize=12, insets={left=2,right=2,top=2,bottom=2}})

                if not hasAddon or not knows then
                    btn:SetBackdropBorderColor(1, 0, 0, 1) -- Red border for unknown/no addon
                    icon:SetVertexColor(0.2, 0.2, 0.2, 0.8) -- Dimmed icon
                    icon:SetDesaturated(true)
                elseif selectedKey == buff.key then
                    btn:SetBackdropBorderColor(0, 1, 0, 1) -- Green border for selected
                    icon:SetVertexColor(1, 1, 1, 1)
                    icon:SetDesaturated(false)
                else
                    btn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1) -- Grey border for unselected known
                    icon:SetVertexColor(0.4, 0.4, 0.4, 1)
                    icon:SetDesaturated(false)
                end

                if hasAddon and knows then
                    btn.buffKey, btn.playerName = buff.key, playerName
                    btn:SetScript("OnClick", function(s)
                        local cur = BuffPlannerDB.selections[s.playerName]
                        if cur == s.buffKey then BuffPlannerDB.selections[s.playerName] = nil else BuffPlannerDB.selections[s.playerName] = s.buffKey end
                        BuffPlanner_BroadcastWishes()
                        BuffPlanner_OnConfigShow()
                    end)
                end

                btn:SetScript("OnEnter", function(s)
                    GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
                    local header = buff.name
                    if not hasAddon then
                        header = header .. " |cffff0000(addon not available)|r"
                    elseif not knows then
                        header = header .. " |cffff0000(not available)|r"
                    end
                    GameTooltip:SetText(header, 1, 1, 1)
                    GameTooltip:AddLine(castName, 0.7, 0.7, 0.7)
                    GameTooltip:Show()
                end)
                btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

                renderIdx = renderIdx + 1
            end
        end

        BuffPlanner_PlayerRows[#BuffPlanner_PlayerRows+1] = rowFrame
        startY = startY + rowHeight + rowPadding
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

function BuffPlanner_ApplyButtonSize(size)
    if not BuffPlanner_DragButton then return end
    BuffPlanner_DragButton:SetSize(size, size)

    local settings = BuffPlanner_GetCharSettings()
    settings.buttonSize = size

    BuffPlanner_UpdateBuffButton() -- Refresh text scaling
end

function BuffPlanner_OnButtonSizeChanged(value)
    BuffPlanner_ApplyButtonSize(value)
end

function BuffPlanner_OnShowSoloChanged(value)
    local settings = BuffPlanner_GetCharSettings()
    settings.showSolo = (value == 1 or value == true)
    BuffPlanner_RefreshButtonVisibility()
end

function BuffPlanner_RefreshButtonVisibility()
    local btn = BuffPlanner_DragButton
    if not btn then return end

    local inGroup = (UnitExists("party1") or UnitExists("raid1") or GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0)

    local settings = BuffPlanner_GetCharSettings()
    local userShow = (settings.buttonPos.show ~= false)

    if userShow and (inGroup or settings.showSolo) then
        btn:Show()
    else
        btn:Hide()
    end
end

function BuffPlanner_UpdateBuffButton()
    local text, btn = BuffPlanner_DragButtonText, BuffPlanner_DragButton
    if not text or not btn then return end

    local settings = BuffPlanner_GetCharSettings()
    local size = settings.buttonSize or 60
    local font, _, flags = text:GetFont()

    local members = BuffPlanner_GetPartyMembers()
    local someoneNeedsBuff, minExp, any = false, 999999, false
    local myName = GetCleanName(UnitName("player"))
    local targetUnitToken, targetName, castSpellName = nil, nil, nil

    local recipients = {}
    for name, key in pairs(BuffPlanner.WishesFromOthers) do recipients[name] = key end
    if BuffPlannerDB.selections[myName] then recipients[myName] = BuffPlannerDB.selections[myName] end

    -- Pass 1: URGENT PASS - Find someone who is MISSING a buff
    -- Priority 1.1: Current Target
    if UnitExists("target") and UnitIsPlayer("target") and not UnitIsDeadOrGhost("target") then
        local tName = GetCleanName(UnitName("target"))
        local desiredKey = recipients[tName]
        if desiredKey then
            local b = BuffPlanner_GetBuffByKey(desiredKey)
            if b and UnitIsInRange("target", b) then
                local has = UnitHasBuff("target", b.spellName)
                if not has then
                    someoneNeedsBuff, targetUnitToken, targetName, castSpellName = true, (UnitIsUnit("target", "player") and "player" or "target"), tName, (type(b.spellName) == "table" and b.spellName[1] or b.spellName)
                end
            end
        end
    end

    -- Priority 1.2: Anyone else in group
    if not someoneNeedsBuff then
        for _, info in ipairs(members) do
            local recipientName, unit = info.name, info.unit
            local desiredKey = recipients[recipientName]
            if desiredKey and unit and not UnitIsDeadOrGhost(unit) then
                local b = BuffPlanner_GetBuffByKey(desiredKey)
                if b and UnitIsInRange(unit, b) then
                    local has, exp = UnitHasBuff(unit, b.spellName)
                    if not has then
                        someoneNeedsBuff, targetUnitToken, targetName, castSpellName = true, unit, recipientName, (type(b.spellName) == "table" and b.spellName[1] or b.spellName)
                        break -- Found someone who needs it, stop looking
                    end
                end
            end
        end
    end

    -- Pass 2: MAINTENANCE PASS - If everyone is buffed, find shortest timer
    if not someoneNeedsBuff then
        -- 2.1 Check Current Target first
        if UnitExists("target") and UnitIsPlayer("target") and not UnitIsDeadOrGhost("target") then
            local tName = GetCleanName(UnitName("target"))
            local desiredKey = recipients[tName]
            if desiredKey then
                local b = BuffPlanner_GetBuffByKey(desiredKey)
                if b and UnitIsInRange("target", b) then
                    local has, exp = UnitHasBuff("target", b.spellName)
                    if has and exp and exp > 0 then
                        any, minExp = true, (exp - GetTime())
                        targetUnitToken, targetName, castSpellName = (UnitIsUnit("target", "player") and "player" or "target"), tName, (type(b.spellName) == "table" and b.spellName[1] or b.spellName)
                    end
                end
            end
        end

        -- 2.2 Check everyone else
        for _, info in ipairs(members) do
            local recipientName, unit = info.name, info.unit
            local desiredKey = recipients[recipientName]
            if desiredKey and unit and not UnitIsDeadOrGhost(unit) then
                local b = BuffPlanner_GetBuffByKey(desiredKey)
                if b and UnitIsInRange(unit, b) then
                    local has, exp = UnitHasBuff(unit, b.spellName)
                    if has and exp and exp > 0 then
                        any = true
                        local rem = exp - GetTime()
                        if rem < minExp then
                            minExp = rem
                            targetUnitToken, targetName, castSpellName = unit, recipientName, (type(b.spellName) == "table" and b.spellName[1] or b.spellName)
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

            -- Explicitly disable Alt+LeftClick action to prevent drag-clicks
            btn:SetAttribute("alt-type1", "macro")
            btn:SetAttribute("alt-macrotext1", "/run")
        else
            btn:SetAttribute("unit", nil)
            btn:SetAttribute("spell", nil)
            btn:SetAttribute("alt-type1", nil)
            btn.armedName, btn.armedSpell = nil, nil
        end
    end

    if someoneNeedsBuff then
        text:SetFont(font, size * 0.28, flags)
        text:SetText("BUFF");
        btn:SetBackdropColor(0.8, 0, 0, 1)
    elseif any then
        text:SetFont(font, size * 0.28, flags)
        if minExp < 999999 then
            local m, s = math.floor(minExp/60), math.floor(minExp%60)
            text:SetText(string.format("%d:%02d", m, s))
        else text:SetText("OK") end
        btn:SetBackdropColor(0, 0.6, 0, 1)
    else
        text:SetFont(font, size * 0.18, flags)
        text:SetText("Select\nBuff");
        btn:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
    end
end

function BuffPlanner_OnBuffButtonClicked(self)
    if IsAltKeyDown() then return end -- Ignore if we were likely dragging

    if self.armedName and self.armedSpell then
        BuffPlanner_Print("Buffing: |cff00ffff" .. self.armedName .. "|r with " .. self.armedSpell)
    else
        -- If no buff is selected or armed, open the config window
        BuffPlanner_ToggleConfigWindow()
    end
end

-- =============================================================================
-- Button Persistence
-- =============================================================================

function BuffPlanner_SaveButtonPosition(frame)
    local p, _, rp, x, y = frame:GetPoint()
    local settings = BuffPlanner_GetCharSettings()

    settings.buttonPos.point = p
    settings.buttonPos.relativePoint = rp
    settings.buttonPos.xOfs = x
    settings.buttonPos.yOfs = y
end

function BuffPlanner_LoadButtonPosition(frame)
    local settings = BuffPlanner_GetCharSettings()
    local pos = settings.buttonPos

    if pos and pos.point then
        frame:ClearAllPoints()
        frame:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.xOfs or 0, pos.yOfs or 0)
    else
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

function BuffPlanner_ToggleBuffButton()
    local settings = BuffPlanner_GetCharSettings()
    if BuffPlanner_DragButton:IsVisible() then
        settings.buttonPos.show = false
    else
        settings.buttonPos.show = true
    end
    BuffPlanner_RefreshButtonVisibility()
end

local updateTimer = 0;
EventFrame:SetScript("OnUpdate", function(self, elapsed)
    updateTimer = updateTimer + elapsed;
    if updateTimer >= 1 then
        updateTimer = 0;
        BuffPlanner_RefreshButtonVisibility()
        if BuffPlanner_DragButton and BuffPlanner_DragButton:IsVisible() then
            BuffPlanner_UpdateBuffButton()
        end
    end
end);

function BuffPlanner_OnSlashCommand(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.*)$")
    cmd = cmd:lower()

    if cmd == "" or cmd == "config" then
        BuffPlanner_ToggleConfigWindow()
    elseif cmd == "buffbutton" then
        BuffPlanner_ToggleBuffButton()
    --[[
    elseif cmd == "find" and arg ~= "" then
        -- Remove quotes if present
        arg = arg:gsub("^%s*[\"'](.-)[\"']%s*$", "%1")
        local searchStr = arg:lower()
        BuffPlanner_Print("Searching for: |cff00ffff" .. arg .. "|r...")

        -- 1. Check direct Spell Info (might work if in cache)
        local sbName, _, sbIcon = GetSpellInfo(arg)
        if sbName then
            local iconName = sbIcon:match("([^%\\]+)$") or sbIcon
            BuffPlanner_Print("Found! |T" .. sbIcon .. ":16|t |cff00ff00" .. sbName .. "|r -> Icon: |cff00ffff" .. iconName .. "|r")
            return
        end

        -- 2. Deep Scan Game Database (Ascension specific needs)
        -- Scanning 1,000,000 IDs might be slow, so we do it in batches or just increase limit
        BuffPlanner_Print("Deep scanning database (IDs 1-1,000,000)... this may take a moment.")
        local foundCount = 0
        local startTime = GetTime()
        for i = 1, 1000000 do
            local n, _, t = GetSpellInfo(i)
            if n then
                local lowN = n:lower()
                if lowN == searchStr or lowN:find(searchStr, 1, true) then
                    local iconName = t:match("([^%\\]+)$") or t
                    BuffPlanner_Print("Found! |T" .. t .. ":16|t |cff00ff00" .. n .. "|r -> Icon: |cff00ffff" .. iconName .. "|r (ID: " .. i .. ")")
                    foundCount = foundCount + 1
                    if foundCount >= 20 then
                        BuffPlanner_Print("...showing first 20 results. Try a more specific name.")
                        break
                    end
                end
            end
        end
        local duration = GetTime() - startTime
        BuffPlanner_Print(string.format("Scan finished in %.2fs. Found %d matches.", duration, foundCount))

        if foundCount == 0 then
            BuffPlanner_Print("|cffff0000Error:|r Could not find any spell matching '|cffffffff" .. arg .. "|r'.")
        end
    ]]
    else
        BuffPlanner_Print("Usage: /bp or /bp config, /bp buffbutton")
    end
end
