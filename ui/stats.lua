-- ProfilePanel: Stat card panel — single vertical column, 3-tier layout
local _, PP = ...

local CARD_WIDTH   = 126
local CARD_HEIGHT  = 44
local CARD_GAP     = 5
local ICON_SIZE    = 30
local TIER_GAP     = 10

local cardPool = {}
local activeCards = {}

--------------------------------------------------------------------------------
-- Card creation
-- Each card:  [ colored-square icon ]  value
--                                      label
--------------------------------------------------------------------------------
local function CreateCard(parent)
    local card = CreateFrame("Frame", nil, parent)
    card:SetSize(CARD_WIDTH, CARD_HEIGHT)

    -- Card background
    card.bg = card:CreateTexture(nil, "BACKGROUND")
    card.bg:SetAllPoints()
    card.bg:SetColorTexture(unpack(PP.CardBgColor))

    -- Left accent bar (colored per stat)
    card.accent = card:CreateTexture(nil, "BORDER")
    card.accent:SetPoint("TOPLEFT")
    card.accent:SetPoint("BOTTOMLEFT")
    card.accent:SetWidth(3)

    -- Icon background (colored square, placeholder for future diamond TGA)
    card.icon = card:CreateTexture(nil, "ARTWORK")
    card.icon:SetSize(ICON_SIZE, ICON_SIZE)
    card.icon:SetPoint("LEFT", card.accent, "RIGHT", 5, 0)
    card.icon:SetColorTexture(1, 1, 1, 0.15)

    -- Icon letter (abbreviation inside the square)
    card.iconText = card:CreateFontString(nil, "OVERLAY")
    card.iconText:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    card.iconText:SetPoint("CENTER", card.icon, "CENTER")
    card.iconText:SetTextColor(1, 1, 1, 0.9)

    -- Value (large, right of icon)
    card.value = card:CreateFontString(nil, "OVERLAY")
    card.value:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
    card.value:SetPoint("TOPLEFT", card.icon, "TOPRIGHT", 5, -1)
    card.value:SetPoint("RIGHT", card, "RIGHT", -3, 0)
    card.value:SetJustifyH("LEFT")
    card.value:SetTextColor(1, 1, 1)

    -- Label (small, below value)
    card.label = card:CreateFontString(nil, "OVERLAY")
    card.label:SetFont(STANDARD_TEXT_FONT, 8)
    card.label:SetPoint("BOTTOMLEFT", card.icon, "BOTTOMRIGHT", 5, 1)
    card.label:SetPoint("RIGHT", card, "RIGHT", -3, 0)
    card.label:SetJustifyH("LEFT")
    card.label:SetTextColor(0.55, 0.55, 0.55)

    card:Hide()
    return card
end

--------------------------------------------------------------------------------
-- Get or recycle a card from the pool
--------------------------------------------------------------------------------
local function AcquireCard(parent)
    local card = table.remove(cardPool)
    if not card then
        card = CreateCard(parent)
    end
    card:SetParent(parent)
    return card
end

local function ReleaseCards()
    for _, card in ipairs(activeCards) do
        card:Hide()
        card:ClearAllPoints()
        table.insert(cardPool, card)
    end
    wipe(activeCards)
end

--------------------------------------------------------------------------------
-- Icon abbreviation from stat key
--------------------------------------------------------------------------------
local ABBREVS = {
    PRIMARY     = function(label) return label and label:sub(1, 3):upper() or "PRI" end,
    STAMINA     = "STA",
    CRIT        = "CRT",
    HASTE       = "HST",
    MASTERY     = "MST",
    VERSATILITY = "VRS",
    LEECH       = "LCH",
    AVOIDANCE   = "AVD",
    SPEED       = "SPD",
    MOVESPEED   = "MOV",
    ARMOR       = "ARM",
    DODGE       = "DDG",
    PARRY       = "PRY",
    BLOCK       = "BLK",
    ATTACKPOWER = "AP",
    SPELLPOWER  = "SP",
    ATTACKSPEED = "AS",
    GCD         = "GCD",
}

local function GetAbbrev(key, label)
    local a = ABBREVS[key]
    if type(a) == "function" then return a(label) end
    return a or key:sub(1, 3):upper()
end

--------------------------------------------------------------------------------
-- Format a stat value for display
--------------------------------------------------------------------------------
local function FormatStatValue(stat)
    local val = stat.value
    local fmt = stat.format

    -- Versatility: show damage / DR
    if stat.key == "VERSATILITY" and stat.extra then
        return string.format("%s%% / %s%%", val, stat.extra)
    end

    -- Attack speed: show MH / OH
    if stat.key == "ATTACKSPEED" and stat.extra then
        return string.format("%.2fs / %.2fs", val, stat.extra)
    end

    -- Armor: show value + DR%
    if stat.key == "ARMOR" and stat.extra then
        return string.format("%s (%s%%)", PP:FormatNumber(val), stat.extra)
    end

    -- Percentage stats
    if fmt:find("%%%%") then
        return string.format("%s%%", val)
    end

    -- Seconds
    if fmt:find("f") then
        return string.format(fmt, val)
    end

    -- Plain number
    return PP:FormatNumber(val)
end

--------------------------------------------------------------------------------
-- Create a thin tier separator line
--------------------------------------------------------------------------------
local function CreateTierSeparator(parent, yOffset)
    local sep = parent:CreateTexture(nil, "ARTWORK")
    sep:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, yOffset)
    sep:SetPoint("RIGHT", parent, "RIGHT", -4, 0)
    sep:SetHeight(1)
    sep:SetColorTexture(1, 1, 1, 0.06)
    return sep
end

--------------------------------------------------------------------------------
-- Populate cards in a single column
--------------------------------------------------------------------------------
local function LayoutColumn(statList, parent, startY)
    local count = #statList
    if count == 0 then return startY end

    for i, stat in ipairs(statList) do
        local card = AcquireCard(parent)
        local y = startY - (i - 1) * (CARD_HEIGHT + CARD_GAP)

        card:ClearAllPoints()
        card:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)

        -- Color
        local c = PP.Colors[stat.colorKey] or { 0.6, 0.6, 0.6 }
        card.accent:SetColorTexture(c[1], c[2], c[3], PP.AccentAlpha)
        card.icon:SetColorTexture(c[1], c[2], c[3], 0.18)
        card.iconText:SetText(GetAbbrev(stat.key, stat.label))
        card.iconText:SetTextColor(c[1], c[2], c[3])

        -- Text
        card.value:SetText(FormatStatValue(stat))
        card.label:SetText(stat.label)

        card:Show()
        table.insert(activeCards, card)
    end

    return startY - count * (CARD_HEIGHT + CARD_GAP)
end

--------------------------------------------------------------------------------
-- Full update
--------------------------------------------------------------------------------
local separators = {}

local function UpdateStats()
    if not PP.MainFrame or not PP.MainFrame.statsArea then return end
    if not PP.MainFrame:IsShown() then return end

    local parent = PP.MainFrame.statsArea
    ReleaseCards()

    -- Clear old separators
    for _, sep in ipairs(separators) do
        sep:Hide()
    end
    wipe(separators)

    local stats = PP:GetAllStats()
    local y = -4

    -- Primary stats
    y = LayoutColumn(stats.primary, parent, y)

    -- Separator + secondary stats
    if #stats.secondary > 0 then
        y = y - (TIER_GAP / 2)
        table.insert(separators, CreateTierSeparator(parent, y))
        y = y - (TIER_GAP / 2)
        y = LayoutColumn(stats.secondary, parent, y)
    end

    -- Separator + tertiary stats (only those > 0)
    if #stats.tertiary > 0 then
        y = y - (TIER_GAP / 2)
        table.insert(separators, CreateTierSeparator(parent, y))
        y = y - (TIER_GAP / 2)
        y = LayoutColumn(stats.tertiary, parent, y)
    end

    -- Update scroll child height so ScrollFrame knows the content size
    local totalHeight = math.abs(y) + 8
    parent:SetHeight(totalHeight)
end

--------------------------------------------------------------------------------
-- Init
--------------------------------------------------------------------------------
PP:RegisterEvent("PP_FRAME_CREATED", function()
    -- Pre-create a pool of cards
    local parent = PP.MainFrame.statsArea
    if parent then
        for _ = 1, 16 do
            table.insert(cardPool, CreateCard(parent))
        end
    end
end)

PP:RegisterEvent("PP_STATS_UPDATE", function()
    UpdateStats()
end)
