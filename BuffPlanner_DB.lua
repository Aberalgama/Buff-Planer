-- =============================================================================
-- BuffPlanner_DB.lua
-- Default buff database. Hier können später CoA-spezifische Buffs hinzugefügt
-- werden. Pro Buff wird ein Schlüsselname (für die DB) und ein Anzeigename
-- gespeichert.
-- =============================================================================

BuffPlanner_DefaultConfig = {
    -- Master list of all available buffs
    buffs = {
        -- spellName: { "Cast Name", "Alias 1", ... }
        -- raidSpellName: (Optional) The group/raid version of the spell
        -- range: (Optional) Buff range in yards (default 40)
        { key = "sun_mp5_cost_reduction",   name = "MP5 + Cost Reduction",         spellName = { "Devotion of Grace" }, icon = "Devotion_of_Grace", range = 40 },
        { key = "sun_ap",    name = "AP",          spellName = { "Devotion of Dawn" },  icon = "Devotion_of_Radiance", range = 40 },
        { key = "sun_stats", name = "All Stats %",  spellName = { "Devotion of Emperors", "Devotion of Emperrors" }, icon = "Devotion_of_Emperors", range = 40 },
        { key = "sun_sp",    name = "SP",          spellName = { "Devotion of Radiance" }, icon = "Devotion_of_Dawnbreak", range = 40 },
        { key = "cul_sp",    name = "SP",          spellName = { "Whispers of C'thun" }, icon = "inv_knife_1h_artifactcthun_d_06", range = 30 },
        { key = "cul_mp5",    name = "MP5",          spellName = { "Whispers of Y'shaarj" }, icon = "ability_garrosh_touch_of_yshaarj", range = 30 },
        { key = "cul_stats",    name = "All Stats %",          spellName = { "Whispers of N'Zoth" }, icon = "achievement_nzothraid_nzoth", range = 30 },
        { key = "cul_reduce_spell_damage_taken_and_heal",    name = "Reduce Spell DMG taken and Heal",          spellName = { "Whispers of Yogg-Saron" }, icon = "void_tinged_trinket", range = 30 },
        { key = "nec_stamina",    name = "Stamina",          spellName = { "Foul Mandate" }, icon = "inv_mawratgreen", range = 30 },
        { key = "nec_sp",    name = "SP",          spellName = { "Grim Mandate" }, icon = "inv_mawratblue", range = 30 },
        { key = "pyr_int",    name = "INT",          spellName = { "Seal of Alysrazor" }, icon = "pyro_scroll", range = 40 },
        { key = "pyr_mp5",    name = "MP5",          spellName = { "Seal of Al'ar" }, icon = "inv_trinket_firelands_01", range = 40 },
        { key = "star_int",    name = "INT",          spellName = { "Celestial Mind" }, icon = "Spell_Shadow_Brainwash", range = 40 },
        { key = "tin_mp5",    name = "MP5",          spellName = { "Mana Module" }, icon = "inv_engineering_reavesbattery", range = 40 },
        { key = "tin_ap",    name = "AP",          spellName = { "Power Module" }, icon = "inv_gizmo_khoriumpowercore", range = 40 },
        { key = "run_stats",    name = "All Stats %",          spellName = { "Etching of the Leylines" }, icon = "inv_glyph_minorhunter", range = 40 },
        { key = "run_agi",    name = "AGI",          spellName = { "Etching of the Dextrous" }, icon = "inv_glyph_minordruid", range = 40 },
        { key = "run_cost_reduction",    name = "Cost Reduction",          spellName = { "Etching of the Magi" }, icon = "inv_glyph_minorpaladin", range = 40 },
        { key = "pri_mp5",    name = "MP5",          spellName = { "Grove Instinct" }, icon = "Grove_Instinct_Primalist", range = 40 },
        { key = "pri_ap",    name = "AP",          spellName = { "Primal Instinct" }, icon = "Ability_Hunter_Pet_Raptor", range = 40 },
        { key = "rea_stamina",    name = "Stamina",          spellName = { "Rite of Resolve" }, icon = "ui_sigil_venthyr", range = 40 },
        { key = "rea_str",    name = "STR",          spellName = { "Rite of Power" }, icon = "ui_sigil_necrolord", range = 40 },
        { key = "rea_res",    name = "Resistances",          spellName = { "Rite of Perseverance" }, icon = "ui_sigil_nightfae", range = 40 },
        { key = "ven_arm_stats",    name = "Armour + All Stats flat",          spellName = { "Beetle Pheromones" }, icon = "inv_progenitorbeetlegreen", range = 40 },
        { key = "ven_sp",    name = "SP",          spellName = { "Toxic Pheromones" }, icon = "epic_rpg_icon_pack_poison_icon_0003s_0000_cloud_Border", range = 40 },
        { key = "ven_agi",    name = "AGI",          spellName = { "Spider Pheromones" }, icon = "nhi_spiderweb_Border", range = 40 },
        { key = "chr_int",    name = "INT",          spellName = { "Nozdormu's Wisdom" }, icon = "Nozdormu_Wisdom", range = 40 },
        { key = "chr_spirit",    name = "Spirit",          spellName = { "Chromie's Wisdom" }, icon = "Chromies_Wisdom", range = 40 },
        { key = "blo_stamina",    name = "Stamina",          spellName = { "Sanguinary Offering" }, icon = "ability_deathwing_bloodcorruption_death", range = 40 },
        { key = "blo_spirit",    name = "Spirit",          spellName = { "Bloodsoaked Offering" }, icon = "inv_armor_bloodtroll_c_01_helm", range = 40 },
        { key = "blo_inc_spell_dmg_taken_heal",    name = "Increase Spell DMG Taken and Heal",          spellName = { "Slaughterhouse Offering" }, icon = "ability_deathknight_deathchain", range = 40 },
        { key = "gua_str",    name = "STR",          spellName = { "Honor" }, icon = "novart_physical_ability_(45)_Border", range = 40 },
        { key = "sto_int",    name = "INT",          spellName = { "Call of the Storm" }, icon = "spell_nature_callstorm", range = 40 },
        { key = "sto_mp5",    name = "MP5",          spellName = { "Call of the Wind" }, icon = "novart_magicspell_(21)_Border", range = 40 },
        { key = "fel_agi",    name = "AGI",          spellName = { "Illidari Intuition" }, icon = "Ability_Warlock_DemonicPower", range = 40 },
        { key = "fel_arm_stats",    name = "Armour + All Stats flat",          spellName = { "Man'ari Intuition" }, icon = "ability_demonhunter_demonictrample", range = 40 },
        { key = "wit_spirit",    name = "Spirit",          spellName = { "Spirit Wuju" }, icon = "inv_misc_tournaments_symbol_troll", range = 40 },
        { key = "wit_ap",    name = "AP",          spellName = { "Power Wuju" }, icon = "shaman_pvp_skyfurytotem", range = 30 },
        { key = "wit_cost_reduction",    name = "Cost Reduction",          spellName = { "Resourceful Wuju" }, icon = "custom_T_Nhance_RPG_Icons_ShadowPotion_Border", range = 30 },
        { key = "wit_doc_arm_stats",    name = "Armour + All Stats flat",          spellName = { "Knight's Edict" }, icon = "WH_Knight_Edict", range = 40 },
        { key = "wit_doc_agi",    name = "AGI",          spellName = { "Inquisitor's Edict" }, icon = "WH_Inquis_Edict", range = 40 },
        { key = "wit_doc_sp",    name = "SP",          spellName = { "Witching Edict" }, icon = "WH_Witching_Edict", range = 40 },
        { key = "kox_stamina_frost",    name = "Stamina + Frost Resi",          spellName = { "Mark of Rivendare" }, icon = "Spell_DeathKnight_SummonDeathCharger", range = 40 },
        { key = "kox_cost_reduction_arcane",    name = "Cost Reduction + Arcane Resi",          spellName = { "Mark of Zeliek" }, icon = "ability_deathknight_asphixiate", range = 40 },
        { key = "kox_sp_shadow",    name = "SP + Shadow Resi",          spellName = { "Mark of Blaumeux" }, icon = "inv_helm_mail_raidshamanprimalist_d_01_fire", range = 40 },
        { key = "kox_str_fire",    name = "STR + Fire Resi",          spellName = { "Mark of Korth'azz" }, icon = "novart_magicspell_(31)_Border", range = 40 },
        { key = "tem_stats",    name = "All Stats %",          spellName = { "Gift of Fervor" }, icon = "Templar_Buff_4", range = 40 },
        { key = "tem_agi",    name = "AGI",          spellName = { "Gift of Zeal" }, icon = "Templar_Buff_3", range = 40 },
        { key = "ran_arm_stats",    name = "Armour + All Stats flat",          spellName = { "Footpad's Adaptation" }, icon = "ability_rogue_thiefsbargain", range = 40 },
        { key = "ran_ap",    name = "AP",          spellName = { "Woodsman's Adaptation" }, icon = "misc_legionfall_hunter", range = 40 },
    },

    -- Mapping of which buffs belong to which class
    -- Use uppercase class tokens: NECROMANCER, PYROMANCER, ...
    classBuffs = {
        ["NECROMANCER"] = { "nec_stamina", "nec_sp" },
        ["PYROMANCER"] = { "pyr_int", "pyr_mp5" },
        ["STARCALLER"] = { "star_int" },
        ["TINKER"] = { "tin_mp5", "tin_ap" },
        ["SPIRITMAGE"] = { "run_stats", "run_agi", "run_cost_reduction" },
        ["WILDWALKER"] = { "pri_mp5", "pri_ap" },
        ["SUNCLERIC"] = { "sun_mp5_cost_reduction", "sun_ap", "sun_stats", "sun_sp" },
        ["CULTIST"] = { "cul_sp", "cul_mp5", "cul_stats", "cul_reduce_spell_damage_taken_and_heal" },
        ["REAPER"] = { "rea_stamina", "rea_str", "rea_res" },
        ["PROPHET"] = { "ven_arm_stats", "ven_sp", "ven_agi" },
        ["CHRONOMANCER"] = { "chr_int", "chr_spirit" },
        ["SONOFARUGAL"] = { "blo_stamina", "blo_spirit", "blo_inc_spell_dmg_taken_heal" },
        ["GUARDIAN"] = { "gua_str" },
        ["STORMBRINGER"] = { "sto_int", "sto_mp5" },
        ["DEMONHUNTER"] = { "fel_agi", "fel_arm_stats" },
        ["WITCHDOCTOR"] = { "wit_spirit", "wit_ap", "wit_cost_reduction" },
        ["WITCHHUNTER"] = { "wit_doc_arm_stats", "wit_doc_agi", "wit_doc_sp" },
        ["FLESHWARDEN"] = { "kox_stamina_frost", "kox_cost_reduction_arcane", "kox_sp_shadow", "kox_str_fire" },
        ["MONK"] = { "tem_stats", "tem_agi" },
        ["RANGER"] = { "ran_arm_stats", "ran_ap" },
    }
}

-- =============================================================================
-- BuffPlannerDB
-- Wird von SavedVariables initialisiert. Enthält die Buff-Auswahl pro Spieler.
-- Format:
--   BuffPlannerDB = {
--     selections = {
--       ["PlayerA"] = "spirit",
--       ["PlayerB"] = nil,
--     },
--     enabled = true,
--   }
-- =============================================================================
BuffPlannerDB = BuffPlannerDB or {
    selections = {},
    enabled = true,
    minimap = {},
    characters = {}, -- Stored per character: ["Name - Realm"] = { buttonPos, buttonSize, showSolo }
}

-- Merge DB with defaults on first load
function BuffPlanner_InitializeDB()
    if not BuffPlannerDB then
        BuffPlannerDB = {
            selections = {},
            enabled = true,
            minimap = {},
            characters = {},
        }
    end
    if not BuffPlannerDB.selections then BuffPlannerDB.selections = {} end
    if not BuffPlannerDB.minimap then BuffPlannerDB.minimap = {} end
    if not BuffPlannerDB.characters then BuffPlannerDB.characters = {} end

    -- Migrate legacy data to character-specific storage
    local k = UnitName("player") .. " - " .. GetRealmName()
    if not BuffPlannerDB.characters[k] then
        BuffPlannerDB.characters[k] = {
            buttonPos = BuffPlannerDB.buttonPos and BuffPlannerDB.buttonPos[k] or { point = "CENTER", xOfs = 0, yOfs = 0 },
            buttonSize = BuffPlannerDB.buttonSize or 60,
            showSolo = (BuffPlannerDB.showSolo ~= nil) and BuffPlannerDB.showSolo or true
        }
    end
end

-- Helper to get current character settings
function BuffPlanner_GetCharSettings()
    local k = UnitName("player") .. " - " .. GetRealmName()
    if not BuffPlannerDB.characters then BuffPlannerDB.characters = {} end
    if not BuffPlannerDB.characters[k] then
        BuffPlannerDB.characters[k] = {
            buttonPos = { point = "CENTER", xOfs = 0, yOfs = 0, show = true },
            buttonSize = 60,
            showSolo = true
        }
    end
    return BuffPlannerDB.characters[k]
end

-- Get the list of available buffs (from DB or default)
function BuffPlanner_GetBuffs()
    return BuffPlanner_DefaultConfig.buffs
end

-- Get a buff by key
function BuffPlanner_GetBuffByKey(key)
    local buffs = BuffPlanner_GetBuffs()
    for _, buff in ipairs(buffs) do
        if buff.key == key then
            return buff
        end
    end
    return nil
end