-- ProfilePanel: WoW API wrappers for stats, equipment, and enchant/gem detection
local _, PP = ...

--------------------------------------------------------------------------------
-- Stat definitions: { key, label, tier, getValue(), format }
-- getValue() returns: value, label, colorKey [, rating [, extra]]
-- Tier 1 = primary (always shown), 2 = secondary (always), 3 = tertiary (if > 0)
--------------------------------------------------------------------------------
PP.StatDefinitions = {}

local function AddStat(key, label, tier, getValue, fmt)
    table.insert(PP.StatDefinitions, {
        key      = key,
        label    = label,
        tier     = tier,
        getValue = getValue,
        format   = fmt or "%.0f",
    })
end

-- Tier 1: Primary ----------------------------------------------------------------

AddStat("PRIMARY", nil, 1, function()
    local spec = GetSpecialization()
    if not spec then return 0, SPELL_STAT1_NAME, "STRENGTH" end
    local _, _, _, _, _, primaryStat = GetSpecializationInfo(spec)
    local statIndex, label, colorKey
    if primaryStat == LE_UNIT_STAT_INTELLECT then
        statIndex, label, colorKey = 4, SPELL_STAT4_NAME, "INTELLECT"
    elseif primaryStat == LE_UNIT_STAT_AGILITY then
        statIndex, label, colorKey = 2, SPELL_STAT2_NAME, "AGILITY"
    else
        statIndex, label, colorKey = 1, SPELL_STAT1_NAME, "STRENGTH"
    end
    local _, effective = UnitStat("player", statIndex)
    return effective or 0, label, colorKey
end, "%s")

AddStat("STAMINA", SPELL_STAT3_NAME, 1, function()
    local _, effective = UnitStat("player", 3)
    return effective or 0, SPELL_STAT3_NAME, "STAMINA"
end, "%s")

-- ILVL moved to header bar (no longer a stat card)

-- Tier 2: Secondary ---------------------------------------------------------------

AddStat("CRIT", STAT_CRITICAL_STRIKE, 2, function()
    local pct = max(GetSpellCritChance(), GetRangedCritChance(), GetCritChance())
    local rating = GetCombatRating(CR_CRIT_SPELL)
    return PP:Round(pct, 1), STAT_CRITICAL_STRIKE, "CRIT", rating
end, "%s%%")

AddStat("HASTE", STAT_HASTE, 2, function()
    local pct = UnitSpellHaste("player")
    local rating = GetCombatRating(CR_HASTE_SPELL)
    return PP:Round(pct, 1), STAT_HASTE, "HASTE", rating
end, "%s%%")

AddStat("MASTERY", STAT_MASTERY, 2, function()
    local masteryEffect = GetMasteryEffect()
    local rating = GetCombatRating(CR_MASTERY)
    return PP:Round(masteryEffect, 1), STAT_MASTERY, "MASTERY", rating
end, "%s%%")

AddStat("VERSATILITY", STAT_VERSATILITY, 2, function()
    local rating = GetCombatRating(CR_VERSATILITY_DAMAGE_DONE)
    local dmgBonus = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE)
                   + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE)
    local dmgReduction = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_TAKEN)
                       + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_TAKEN)
    return PP:Round(dmgBonus, 1), STAT_VERSATILITY, "VERSATILITY", rating, PP:Round(dmgReduction, 1)
end, "%s%%")

-- Tier 3: Tertiary (shown only when > 0) -------------------------------------------

AddStat("LEECH", STAT_LIFESTEAL, 3, function()
    local pct = GetLifesteal()
    local rating = GetCombatRating(CR_LIFESTEAL)
    return PP:Round(pct, 2), STAT_LIFESTEAL, "LEECH", rating
end, "%s%%")

AddStat("AVOIDANCE", STAT_AVOIDANCE, 3, function()
    local pct = GetAvoidance()
    local rating = GetCombatRating(CR_AVOIDANCE)
    return PP:Round(pct, 2), STAT_AVOIDANCE, "AVOIDANCE", rating
end, "%s%%")

AddStat("SPEED", STAT_SPEED, 3, function()
    local pct = GetSpeed()
    local rating = GetCombatRating(CR_SPEED)
    return PP:Round(pct, 2), STAT_SPEED, "SPEED", rating
end, "%s%%")

AddStat("MOVESPEED", "Move Speed", 3, function()
    local currentSpeed, runSpeed, flightSpeed, swimSpeed = GetUnitSpeed("player")
    local pct = runSpeed / BASE_MOVEMENT_SPEED * 100
    if IsSwimming("player") then
        pct = swimSpeed / BASE_MOVEMENT_SPEED * 100
    elseif IsFlying("player") then
        pct = flightSpeed / BASE_MOVEMENT_SPEED * 100
    elseif UnitInVehicle("player") then
        pct = GetUnitSpeed("Vehicle") / BASE_MOVEMENT_SPEED * 100
    end
    return PP:Round(pct, 0), "Move Speed", "MOVESPEED"
end, "%s%%")

AddStat("ARMOR", ARMOR, 3, function()
    local _, effectiveArmor, armor = UnitArmor("player")
    local reduction = PaperDollFrame_GetArmorReduction(effectiveArmor, UnitEffectiveLevel("player"))
    return armor or 0, ARMOR, "ARMOR", nil, PP:Round(reduction, 1)
end, "%s")

AddStat("DODGE", STAT_DODGE, 3, function()
    local pct = GetDodgeChance()
    return PP:Round(pct, 2), STAT_DODGE, "DODGE"
end, "%s%%")

AddStat("PARRY", STAT_PARRY, 3, function()
    local pct = GetParryChance()
    return PP:Round(pct, 2), STAT_PARRY, "PARRY"
end, "%s%%")

AddStat("BLOCK", BLOCK, 3, function()
    local pct = GetBlockChance()
    return PP:Round(pct, 2), BLOCK, "BLOCK"
end, "%s%%")

AddStat("ATTACKPOWER", STAT_ATTACK_POWER, 3, function()
    local base, posBuff, negBuff
    if IsRangedWeapon then
        base, posBuff, negBuff = UnitRangedAttackPower("player")
    else
        base, posBuff, negBuff = UnitAttackPower("player")
    end
    base = base or 0; posBuff = posBuff or 0; negBuff = negBuff or 0
    local total = base + posBuff + negBuff
    return total, STAT_ATTACK_POWER, "ATTACKPOWER"
end, "%s")

AddStat("SPELLPOWER", STAT_SPELLPOWER, 3, function()
    local sp = GetSpellBonusDamage(2)
    return sp or 0, STAT_SPELLPOWER, "SPELLPOWER"
end, "%s")

AddStat("ATTACKSPEED", STAT_ATTACK_SPEED, 3, function()
    local speed, offhandSpeed = UnitAttackSpeed("player")
    return PP:Round(speed, 2), STAT_ATTACK_SPEED, "ATTACKSPEED", nil, offhandSpeed and PP:Round(offhandSpeed, 2)
end, "%.2fs")

AddStat("GCD", "GCD", 3, function()
    local haste = GetHaste()
    local gcd = max(0.75, 1.5 * 100 / (100 + haste))
    local spec = GetSpecialization()
    if spec then
        local _, _, _, _, _, primaryStat = GetSpecializationInfo(spec)
        local _, class = UnitClass("player")
        if class == "DRUID" and GetShapeshiftFormID() == 1 then
            gcd = 1
        elseif class == "ROGUE" or class == "MONK" then
            gcd = 1
        end
    end
    return PP:Round(gcd, 2), "GCD", "GCD"
end, "%.2fs")

--------------------------------------------------------------------------------
-- Aggregate stat reader
--------------------------------------------------------------------------------
function PP:GetAllStats()
    local stats = { primary = {}, secondary = {}, tertiary = {} }

    for _, def in ipairs(self.StatDefinitions) do
        local ok, value, label, colorKey, rating, extra = pcall(def.getValue)
        if not ok then
            value, label, colorKey, rating, extra = 0, def.label or def.key, def.key, nil, nil
        end

        local statData = {
            key      = def.key,
            label    = label or def.label or def.key,
            value    = value or 0,
            colorKey = colorKey or def.key,
            rating   = rating,
            extra    = extra,
            format   = def.format,
            tier     = def.tier,
        }

        if def.tier == 1 then
            table.insert(stats.primary, statData)
        elseif def.tier == 2 then
            table.insert(stats.secondary, statData)
        else
            if (tonumber(value) or 0) > 0 then
                table.insert(stats.tertiary, statData)
            end
        end
    end

    return stats
end

--------------------------------------------------------------------------------
-- Equipment info for a single slot
--------------------------------------------------------------------------------
function PP:GetSlotInfo(slotID)
    local itemLink = GetInventoryItemLink("player", slotID)
    if not itemLink then return nil end

    local itemLoc = ItemLocation:CreateFromEquipmentSlot(slotID)
    if not C_Item.DoesItemExist(itemLoc) then return nil end

    local info = {
        link       = itemLink,
        name       = C_Item.GetItemName(itemLoc) or "",
        quality    = C_Item.GetItemQualityByID(itemLink) or 1,
        ilvl       = C_Item.GetCurrentItemLevel(itemLoc) or 0,
        enchant    = nil,
        missingEnchant = false,
        gems       = {},
        missingGem = false,
    }

    -- Enchant detection via tooltip data
    local tooltipData = C_TooltipInfo.GetInventoryItem("player", slotID)
    if tooltipData and tooltipData.lines then
        for _, line in ipairs(tooltipData.lines) do
            local text = line.leftText
            if text then
                local pattern = ENCHANTED_TOOLTIP_LINE:gsub("%%s", "(.+)")
                local enchant = text:match(pattern)
                if enchant then
                    info.enchant = enchant
                end
            end
        end
    end

    -- Gem detection
    for i = 1, 3 do
        local _, gemLink = C_Item.GetItemGem(itemLink, i)
        if gemLink then
            info.gems[i] = gemLink
        end
    end

    info.missingEnchant = (PP.EnchantableSlots[slotID] == true) and (info.enchant == nil)
    info.missingGem     = PP:SlotShouldHaveGem(slotID, info.gems)

    return info
end

--------------------------------------------------------------------------------
-- Gem socket rules (The War Within)
--------------------------------------------------------------------------------
function PP:SlotShouldHaveGem(slotID, gems)
    -- TWW: Head, Wrist, Waist get 1 socket; Neck, Ring1, Ring2 get 2 sockets
    if slotID == INVSLOT_HEAD or slotID == INVSLOT_WRIST or slotID == INVSLOT_WAIST then
        if not gems[1] then return true end
    elseif slotID == INVSLOT_NECK or slotID == INVSLOT_FINGER1 or slotID == INVSLOT_FINGER2 then
        if not gems[1] or not gems[2] then return true end
    end
    return false
end
