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
        { key = "sun_mp5_cost_reduction",   name = "MP5 +\nCost Reduction",         spellName = { "Devotion of Grace" }, icon = "spell_holy_mindvision", range = 40 },
        { key = "sun_ap",    name = "AP",          spellName = { "Devotion of Dawn" },  icon = "spell_holy_auramagister", range = 40 },
        { key = "sun_stats", name = "All\nStats",  spellName = { "Devotion of Emperors", "Devotion of Emperrors" }, icon = "spell_holy_greaterheal", range = 40 },
        { key = "sun_sp",    name = "SP",          spellName = { "Devotion of Radiance" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "cul_sp",    name = "SP",          spellName = { "Whispers of C'thun" }, icon = "spell_holy_divineillumination", range = 30 },
        { key = "cul_mp5",    name = "MP5",          spellName = { "Whispers of Y'shaarj" }, icon = "spell_holy_divineillumination", range = 30 },
        { key = "cul_stats",    name = "All\nStats",          spellName = { "Whispers of N'Zoth" }, icon = "spell_holy_divineillumination", range = 30 },
        { key = "cul_reduce_spell_damage_taken_and_heal",    name = "Reduce Spell DMG taken+\nHeal",          spellName = { "Whispers of Yogg-Saron" }, icon = "spell_holy_divineillumination", range = 30 },
        { key = "nec_stamina",    name = "Stamina",          spellName = { "Foul Mandate" }, icon = "spell_holy_divineillumination", range = 30 },
        { key = "nec_sp",    name = "SP",          spellName = { "Grim Mandate" }, icon = "spell_holy_divineillumination", range = 30 },
        { key = "pyr_int",    name = "INT",          spellName = { "Seal of Alysrazor" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "pyr_mp5",    name = "MP5",          spellName = { "Seal of Al'ar" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "star_int",    name = "INT",          spellName = { "Celestial Mind" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "tin_mp5",    name = "MP5",          spellName = { "Mana Module" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "tin_ap",    name = "AP",          spellName = { "Power Module" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "run_stats",    name = "All\nStats",          spellName = { "Etching of the Leylines" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "run_agi",    name = "AGI",          spellName = { "Etching of the Dextrous" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "run_cost_reduction",    name = "Cost Reduction",          spellName = { "Etching of the Magi" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "pri_mp5",    name = "MP5",          spellName = { "Grove Instinct" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "pri_ap",    name = "AP",          spellName = { "Primal Instinct" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "rea_stamina",    name = "Stamina",          spellName = { "Rite of Resolve" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "rea_str",    name = "STR",          spellName = { "Rite of Power" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "ven_arm_stats",    name = "Armour + \nAll Stats",          spellName = { "Beetle Pheromones" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "ven_sp",    name = "SP",          spellName = { "Toxic Pheromones" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "ven_agi",    name = "AGI",          spellName = { "Spider Pheromones" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "chr_int",    name = "INT",          spellName = { "Nozdormu's Wisdom" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "chr_spirit",    name = "Spirit",          spellName = { "Chromie's Wisdom" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "blo_stamina",    name = "Stamina",          spellName = { "Sanguinary Offering" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "blo_spirit",    name = "Spirit",          spellName = { "Bloodsoaked Offering" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "blo_inc_spell_dmg_taken_heal",    name = "Increase Spell DMG Taken +\nHeal",          spellName = { "Slaughterhouse Offering" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "gua_str",    name = "STR",          spellName = { "Honor" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "sto_int",    name = "INT",          spellName = { "Call of the Storm" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "sto_mp5",    name = "MP5",          spellName = { "Call of the Wind" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "fel_agi",    name = "AGI",          spellName = { "Illidari Intuition" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "fel_arm_stats",    name = "Armour + \nAll Stats",          spellName = { "Man'ari Intuition" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "wit_spirit",    name = "Spirit",          spellName = { "Spirit Wuju" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "wit_ap",    name = "AP",          spellName = { "Power Wuju" }, icon = "spell_holy_divineillumination", range = 30 },
        { key = "wit_cost_reduction",    name = "Cost Reduction",          spellName = { "Resourceful Wuju" }, icon = "spell_holy_divineillumination", range = 30 },
        { key = "wit_doc_arm_stats",    name = "Armour + \nAll Stats",          spellName = { "Knight's Edict" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "wit_doc_agi",    name = "AGI",          spellName = { "Inquisitor's Edict" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "wit_doc_sp",    name = "SP",          spellName = { "Witching Edict" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "kox_stamina_frost",    name = "Stamina +\nFrost Resi",          spellName = { "Mark of Rivendare" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "kox_cost_reduction_arcane",    name = "Cost Reduction +\nArcane Resi",          spellName = { "Mark of Zeliek" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "kox_sp_shadow",    name = "SP +\nShadow Resi",          spellName = { "Mark of Blaumeux" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "kox_str_fire",    name = "STR +\nFire Resi",          spellName = { "Mark of Korth'azz" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "tem_stats",    name = "All\nStats",          spellName = { "Gift of Fervor" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "tem_agi",    name = "AGI",          spellName = { "Gift of Zeal" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "ran_arm_stats",    name = "Armour + \nAll Stats",          spellName = { "Foorpad's Adaptation" }, icon = "spell_holy_divineillumination", range = 40 },
        { key = "ran_ap",    name = "AP",          spellName = { "Woodsman's Adaptation" }, icon = "spell_holy_divineillumination", range = 40 },
    },

    -- Mapping of which buffs belong to which class
    -- Use uppercase class tokens: NECROMANCER, PYROMANCER, ...
    classBuffs = {
        ["NECROMANCER"] = { "nec_stamina", "nec_sp" },
        ["PYROMANCER"] = { "pyr_int", "pyr_mp5" },
        ["STARCALLER"] = { "star_int" },
        ["TINKER"] = { "tin_mp5", "tin_ap" },
        ["RUNEMASTER"] = { "run_stats", "run_agi", "run_cost_reduction" },
        ["PRIMALIST"] = { "pri_mp5", "pri_ap" },
        ["SUNCLERIC"] = { "sun_mp5_cost_reduction", "sun_ap", "sun_stats", "sun_sp" },
        ["CULTIST"] = { "cul_sp", "cul_mp5", "cul_stats", "cul_reduce_spell_damage_taken_and_heal" },
        ["REAPER"] = { "rea_stamina", "rea_str" },
        ["VENOMANCER"] = { "ven_arm_stats", "ven_sp", "ven_agi" },
        ["CHRONOMANCER"] = { "chr_int", "chr_spirit" },
        ["BLOODMAGE"] = { "blo_stamina", "blo_spirit", "blo_inc_spell_dmg_taken_heal" },
        ["GUARDIAN"] = { "gua_str" },
        ["STORMBRINGER"] = { "sto_int", "sto_mp5" },
        ["FELSWORN"] = { "fel_agi", "fel_arm_stats" },
        ["WITCHDOCTOR"] = { "wit_spirit", "wit_ap", "wit_cost_reduction" },
        ["WITCHHUNTER"] = { "wit_doc_arm_stats", "wit_doc_agi", "wit_doc_sp" },
        ["KNIGHTOFXOROTH"] = { "kox_stamina_frost", "kox_cost_reduction_arcane", "kox_sp_shadow", "kox_str_fire" },
        ["TEMPLAR"] = { "tem_stats", "tem_agi" },
        ["RANGER"] = { "ran_arm_stats", "ran_ap" },
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