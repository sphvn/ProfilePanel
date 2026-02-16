-- ProfilePanel: Core namespace, constants, and utilities
local addonName, PP = ...
ProfilePanel = PP

PP.version = "0.1.0"
PP.addonName = addonName

--------------------------------------------------------------------------------
-- Saved variable defaults
--------------------------------------------------------------------------------
PP.defaults = {
    enabled = true,
    fontSize = 12,
}

--------------------------------------------------------------------------------
-- Stat colors (inspired by WoW Armory website palette)
--------------------------------------------------------------------------------
PP.Colors = {
    STRENGTH    = { 0.78, 0.13, 0.13 },
    AGILITY     = { 1.00, 0.78, 0.24 },
    INTELLECT   = { 0.96, 0.55, 0.10 },
    STAMINA     = { 0.78, 0.61, 0.20 },
    ILVL        = { 1.00, 0.84, 0.00 },

    CRIT        = { 0.87, 0.24, 0.20 },
    HASTE       = { 0.20, 0.65, 0.50 },
    MASTERY     = { 0.58, 0.25, 0.72 },
    VERSATILITY = { 0.55, 0.55, 0.55 },

    LEECH       = { 0.55, 0.82, 0.40 },
    AVOIDANCE   = { 0.35, 0.58, 0.80 },
    SPEED       = { 0.30, 0.69, 0.31 },
    MOVESPEED   = { 0.30, 0.69, 0.31 },
    ARMOR       = { 0.65, 0.65, 0.65 },
    DODGE       = { 0.35, 0.58, 0.80 },
    PARRY       = { 0.80, 0.35, 0.35 },
    BLOCK       = { 0.58, 0.51, 0.30 },
    ATTACKPOWER = { 0.80, 0.30, 0.20 },
    SPELLPOWER  = { 0.40, 0.30, 0.80 },
    ATTACKSPEED = { 0.80, 0.60, 0.20 },
    GCD         = { 0.60, 0.60, 0.60 },
}

PP.BgColor       = { 0.04, 0.04, 0.07, 0.97 }
PP.CardBgColor   = { 0.10, 0.10, 0.14, 0.90 }
PP.AccentAlpha   = 0.85

--------------------------------------------------------------------------------
-- Equipment slot map
--------------------------------------------------------------------------------
PP.SlotLayout = {
    LEFT = {
        "CharacterHeadSlot",
        "CharacterNeckSlot",
        "CharacterShoulderSlot",
        "CharacterBackSlot",
        "CharacterChestSlot",
        "CharacterWristSlot",
        "CharacterShirtSlot",
        "CharacterTabardSlot",
    },
    RIGHT = {
        "CharacterHandsSlot",
        "CharacterWaistSlot",
        "CharacterLegsSlot",
        "CharacterFeetSlot",
        "CharacterFinger0Slot",
        "CharacterFinger1Slot",
        "CharacterTrinket0Slot",
        "CharacterTrinket1Slot",
    },
    BOTTOM = {
        "CharacterMainHandSlot",
        "CharacterSecondaryHandSlot",
    },
}

-- Map global button name → inventory slot ID
PP.SlotIDs = {
    CharacterHeadSlot           = INVSLOT_HEAD,
    CharacterNeckSlot           = INVSLOT_NECK,
    CharacterShoulderSlot       = INVSLOT_SHOULDER,
    CharacterBackSlot           = INVSLOT_BACK,
    CharacterChestSlot          = INVSLOT_CHEST,
    CharacterShirtSlot          = INVSLOT_BODY,
    CharacterTabardSlot         = INVSLOT_TABARD,
    CharacterWristSlot          = INVSLOT_WRIST,
    CharacterHandsSlot          = INVSLOT_HAND,
    CharacterWaistSlot          = INVSLOT_WAIST,
    CharacterLegsSlot           = INVSLOT_LEGS,
    CharacterFeetSlot           = INVSLOT_FEET,
    CharacterFinger0Slot        = INVSLOT_FINGER1,
    CharacterFinger1Slot        = INVSLOT_FINGER2,
    CharacterTrinket0Slot       = INVSLOT_TRINKET1,
    CharacterTrinket1Slot       = INVSLOT_TRINKET2,
    CharacterMainHandSlot       = INVSLOT_MAINHAND,
    CharacterSecondaryHandSlot  = INVSLOT_OFFHAND,
}

-- Slots that should have an enchant (TWW)
PP.EnchantableSlots = {
    [INVSLOT_BACK]     = true,
    [INVSLOT_CHEST]    = true,
    [INVSLOT_WRIST]    = true,
    [INVSLOT_LEGS]     = true,
    [INVSLOT_FEET]     = true,
    [INVSLOT_FINGER1]  = true,
    [INVSLOT_FINGER2]  = true,
    [INVSLOT_MAINHAND] = true,
}

--------------------------------------------------------------------------------
-- Utility helpers
--------------------------------------------------------------------------------
function PP:Round(num, decimals)
    if not num then return 0 end
    decimals = decimals or 0
    local mult = 10 ^ decimals
    return math.floor(num * mult + 0.5) / mult
end

function PP:ColorText(text, colorKey)
    local c = self.Colors[colorKey]
    if not c then return tostring(text) end
    return string.format("|cff%02x%02x%02x%s|r", c[1]*255, c[2]*255, c[3]*255, tostring(text))
end

function PP:FormatNumber(n)
    if not n then return "0" end
    if n >= 10000 then
        return BreakUpLargeNumbers(math.floor(n))
    end
    return tostring(n)
end

function PP:ClassColor()
    local _, class = UnitClass("player")
    local cc = RAID_CLASS_COLORS[class]
    if cc then return cc.r, cc.g, cc.b end
    return 1, 1, 1
end
