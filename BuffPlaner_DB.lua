-- =============================================================================
-- BuffPlaner_DB.lua
-- Default buff database. Hier können später CoA-spezifische Buffs hinzugefügt
-- werden. Pro Buff wird ein Schlüsselname (für die DB) und ein Anzeigename
-- gespeichert.
-- =============================================================================

BuffPlaner_DefaultConfig = {
    -- Master list of all available buffs
    buffs = {
        -- spellName: { "Cast Name", "Alias 1", ... }
        -- raidSpellName: (Optional) The group/raid version of the spell
        -- range: (Optional) Buff range in yards (default 40)

        -- Sun Cleric Specifics
        { key = "sun_mp5_cost_reduction",   name = "MP5 +\nCost Reduction",         spellName = { "Devotion of Grace" }, icon = "spell_holy_mindvision", range = 40 },
        { key = "sun_ap",    name = "AP",          spellName = { "Devotion of Dawn" },  icon = "spell_holy_auramagister", range = 40 },
        { key = "sun_stats", name = "All\nStats",  spellName = { "Devotion of Emperors" }, icon = "spell_holy_greaterheal", range = 40 },
        { key = "sun_sp",    name = "SP",          spellName = { "Devotion of Radiance" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "cul_sp",    name = "SP",          spellName = { "Whispers of C'thun" }, icon = "spell_holy_divineillumination", range = 30 },
        { key = "cul_mp5",    name = "MP5",          spellName = { "Whispers of Y'shaarj" }, icon = "spell_holy_divineillumination", range = 30 },
        { key = "cul_stats",    name = "All\nStats",          spellName = { "Whispers of N'Zoth" }, icon = "spell_holy_divineillumination", range = 30 },
        { key = "cul_reduce_spell_damage_taken_and_heal",    name = "Reduce Spell DMG +\nReduce Heal",          spellName = { "Whispers of Yogg-Saron" }, icon = "spell_holy_divineillumination", range = 30 },
    },

    -- Mapping of which buffs belong to which class
    -- Use uppercase class tokens: PRIEST, PALADIN, MAGE, WARRIOR, DRUID, HUNTER, ROGUE, SHAMAN, WARLOCK, DEATHKNIGHT
    -- Ascension custom classes can be added here too
    classBuffs = {
        ["SUNCLERIC"] = { "sun_mp5_cost_reduction", "sun_ap", "sun_stats", "sun_sp" },
        ["CULTIST"] = { "cul_sp", "cul_mp5", "cul_stats", "cul_reduce_spell_damage_taken_and_heal" },
        -- Add more classes and their buff keys here
    }
}

-- =============================================================================
-- BuffPlanerDB
-- Wird von SavedVariables initialisiert. Enthält die Buff-Auswahl pro Spieler.
-- Format:
--   BuffPlanerDB = {
--     selections = {
--       ["PlayerA"] = "spirit",
--       ["PlayerB"] = nil,
--     },
--     enabled = true,
--   }
-- =============================================================================
BuffPlanerDB = BuffPlanerDB or {
    selections = {},
    enabled = true,
    minimap = {},
    buttonPos = {}, -- Stored per character: ["CharacterName - Realm"] = { point, x, y }
}

-- Merge DB with defaults on first load
function BuffPlaner_InitializeDB()
    if not BuffPlanerDB then
        BuffPlanerDB = {
            selections = {},
            enabled = true,
            minimap = {},
            buttonPos = {},
        }
    end
    if not BuffPlanerDB.selections then
        BuffPlanerDB.selections = {}
    end
    if not BuffPlanerDB.minimap then
        BuffPlanerDB.minimap = {}
    end
    if not BuffPlanerDB.buttonPos then
        BuffPlanerDB.buttonPos = {}
    end
end

-- Get the list of available buffs (from DB or default)
function BuffPlaner_GetBuffs()
    return BuffPlaner_DefaultConfig.buffs
end

-- Get a buff by key
function BuffPlaner_GetBuffByKey(key)
    local buffs = BuffPlaner_GetBuffs()
    for _, buff in ipairs(buffs) do
        if buff.key == key then
            return buff
        end
    end
    return nil
end