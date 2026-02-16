-- ProfilePanel: Stat card panel — primary/secondary with diamond icons, tertiary compact 2-column
local _, PP = ...

local CARD_WIDTH   = 180
local CARD_HEIGHT  = 44
local CARD_GAP     = 5
local ICON_SIZE    = 34
local TIER_GAP     = 10

-- Compact card dimensions (tertiary, 2-column, no icon)
local COMPACT_WIDTH  = 87
local COMPACT_HEIGHT = 34
local COMPACT_GAP    = 6

local cardPool = {}
local compactPool = {}
local activeCards = {}

--------------------------------------------------------------------------------
-- Stat icon texture paths (diamond icons from WoW Armory website)
--------------------------------------------------------------------------------
local ICON_BASE = "Interface\\AddOns\\ProfilePanel\\Media\\Textures\\"

local STAT_ICONS = {
    STRENGTH    = ICON_BASE .. "stat_strength.png",
    AGILITY     = ICON_BASE .. "stat_agility.png",
    INTELLECT   = ICON_BASE .. "stat_intellect.png",
    STAMINA     = ICON_BASE .. "stat_stamina.png",
    CRIT        = ICON_BASE .. "stat_crit.png",
    HASTE       = ICON_BASE .. "stat_haste.png",
    MASTERY     = ICON_BASE .. "stat_mastery.png",
    VERSATILITY = ICON_BASE .. "stat_versatility.png",
}

--------------------------------------------------------------------------------
-- Full card creation (primary/secondary)
-- [ diamond-icon ]  value
--                   label
--------------------------------------------------------------------------------
local function CreateCard(parent)
    local card = CreateFrame("Frame", nil, parent)
    card:SetSize(CARD_WIDTH, CARD_HEIGHT)
    card.isCompact = false

    -- Card background
    card.bg = card:CreateTexture(nil, "BACKGROUND")
    card.bg:SetAllPoints()
    card.bg:SetColorTexture(unpack(PP.CardBgColor))

    -- Diamond icon texture (replaces colored square + abbreviation)
    card.icon = card:CreateTexture(nil, "ARTWORK")
    card.icon:SetSize(ICON_SIZE, ICON_SIZE)
    card.icon:SetPoint("LEFT", 5, 0)

    -- Value (large, right of icon)
    card.value = card:CreateFontString(nil, "OVERLAY")
    card.value:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
    card.value:SetPoint("TOPLEFT", card.icon, "TOPRIGHT", 5, -1)
    card.value:SetPoint("RIGHT", card, "RIGHT", -3, 0)
    card.value:SetJustifyH("LEFT")
    card.value:SetTextColor(1, 1, 1)

    -- Label (small, below value)
    card.label = card:CreateFontString(nil, "OVERLAY")
    card.label:SetFont(STANDARD_TEXT_FONT, 9)
    card.label:SetPoint("BOTTOMLEFT", card.icon, "BOTTOMRIGHT", 5, 1)
    card.label:SetPoint("RIGHT", card, "RIGHT", -3, 0)
    card.label:SetJustifyH("LEFT")
    card.label:SetTextColor(0.55, 0.55, 0.55)

    card:Hide()
    return card
end

--------------------------------------------------------------------------------
-- Compact card creation (tertiary, no icon)
-- [ accent ]  value
--             label
--------------------------------------------------------------------------------
local function CreateCompactCard(parent)
    local card = CreateFrame("Frame", nil, parent)
    card:SetSize(COMPACT_WIDTH, COMPACT_HEIGHT)
    card.isCompact = true

    -- Card background
    card.bg = card:CreateTexture(nil, "BACKGROUND")
    card.bg:SetAllPoints()
    card.bg:SetColorTexture(unpack(PP.CardBgColor))

    -- Left accent bar
    card.accent = card:CreateTexture(nil, "BORDER")
    card.accent:SetPoint("TOPLEFT")
    card.accent:SetPoint("BOTTOMLEFT")
    card.accent:SetWidth(3)

    -- Value (right of accent)
    card.value = card:CreateFontString(nil, "OVERLAY")
    card.value:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    card.value:SetPoint("TOPLEFT", card.accent, "TOPRIGHT", 5, -3)
    card.value:SetPoint("RIGHT", card, "RIGHT", -3, 0)
    card.value:SetJustifyH("LEFT")
    card.value:SetTextColor(1, 1, 1)

    -- Label (small, below value)
    card.label = card:CreateFontString(nil, "OVERLAY")
    card.label:SetFont(STANDARD_TEXT_FONT, 8)
    card.label:SetPoint("TOPLEFT", card.value, "BOTTOMLEFT", 0, -1)
    card.label:SetPoint("RIGHT", card, "RIGHT", -3, 0)
    card.label:SetJustifyH("LEFT")
    card.label:SetTextColor(0.55, 0.55, 0.55)

    card:Hide()
    return card
end

--------------------------------------------------------------------------------
-- Pool management
--------------------------------------------------------------------------------
local function AcquireCard(parent)
    local card = table.remove(cardPool)
    if not card then
        card = CreateCard(parent)
    end
    card:SetParent(parent)
    return card
end

local function AcquireCompactCard(parent)
    local card = table.remove(compactPool)
    if not card then
        card = CreateCompactCard(parent)
    end
    card:SetParent(parent)
    return card
end

local function ReleaseCards()
    for _, card in ipairs(activeCards) do
        card:Hide()
        card:ClearAllPoints()
        if card.isCompact then
            table.insert(compactPool, card)
        else
            table.insert(cardPool, card)
        end
    end
    wipe(activeCards)
end

--------------------------------------------------------------------------------
-- Format a stat value for display (primary value only, details on hover)
--------------------------------------------------------------------------------
local function FormatStatValue(stat)
    local val = stat.value
    local fmt = stat.format

    -- Versatility: show damage % only
    if stat.key == "VERSATILITY" then
        return string.format("%s%%", val)
    end

    -- Attack speed: show MH only
    if stat.key == "ATTACKSPEED" then
        return string.format("%.2fs", val)
    end

    -- Armor: show value only
    if stat.key == "ARMOR" then
        return PP:FormatNumber(val)
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
-- Build tooltip lines for stats with extra detail
--------------------------------------------------------------------------------
local function ShowStatTooltip(card, stat)
    GameTooltip:SetOwner(card, "ANCHOR_LEFT")
    GameTooltip:ClearLines()

    local c = PP.Colors[stat.colorKey] or { 0.8, 0.8, 0.8 }
    GameTooltip:AddLine(stat.label, c[1], c[2], c[3])

    if stat.key == "VERSATILITY" and stat.extra then
        GameTooltip:AddLine(string.format("%s%% Damage / Healing", stat.value), 1, 1, 1)
        GameTooltip:AddLine(string.format("%s%% Damage Reduction", stat.extra), 1, 1, 1)
    elseif stat.key == "ARMOR" and stat.extra then
        GameTooltip:AddLine(string.format("%s Armor", PP:FormatNumber(stat.value)), 1, 1, 1)
        GameTooltip:AddLine(string.format("%s%% Damage Reduction", stat.extra), 1, 1, 1)
    elseif stat.key == "ATTACKSPEED" and stat.extra then
        GameTooltip:AddLine(string.format("Main Hand: %.2fs", stat.value), 1, 1, 1)
        GameTooltip:AddLine(string.format("Off Hand: %.2fs", stat.extra), 1, 1, 1)
    elseif stat.rating then
        GameTooltip:AddLine(string.format("%s from %s rating", FormatStatValue(stat), PP:FormatNumber(stat.rating)), 1, 1, 1)
    else
        GameTooltip:AddLine(FormatStatValue(stat), 1, 1, 1)
    end

    GameTooltip:Show()
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
-- Resolve the icon texture for a stat key
-- PRIMARY dynamically maps to STRENGTH/AGILITY/INTELLECT via colorKey
--------------------------------------------------------------------------------
local function GetStatIcon(stat)
    local key = stat.colorKey or stat.key
    return STAT_ICONS[key]
end

--------------------------------------------------------------------------------
-- Layout: single column (primary / secondary)
--------------------------------------------------------------------------------
local function LayoutSingleColumn(statList, parent, startY)
    local count = #statList
    if count == 0 then return startY end

    for i, stat in ipairs(statList) do
        local card = AcquireCard(parent)
        local y = startY - (i - 1) * (CARD_HEIGHT + CARD_GAP)

        card:ClearAllPoints()
        card:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)

        -- Set diamond icon texture (pre-colored PNGs, no vertex tinting needed)
        local iconPath = GetStatIcon(stat)
        if iconPath then
            card.icon:SetTexture(iconPath)
            card.icon:SetVertexColor(1, 1, 1)
        else
            card.icon:SetColorTexture(0.15, 0.15, 0.20, 0.5)
        end

        -- Text
        card.value:SetText(FormatStatValue(stat))
        card.label:SetText(stat.label)

        -- Hover tooltip
        card.statData = stat
        card:EnableMouse(true)
        card:SetScript("OnEnter", function(self)
            ShowStatTooltip(self, self.statData)
        end)
        card:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        card:Show()
        table.insert(activeCards, card)
    end

    return startY - count * (CARD_HEIGHT + CARD_GAP)
end

--------------------------------------------------------------------------------
-- Layout: two-column compact (tertiary)
--------------------------------------------------------------------------------
local function LayoutTwoColumn(statList, parent, startY)
    local count = #statList
    if count == 0 then return startY end

    local col2X = COMPACT_WIDTH + COMPACT_GAP
    local row = 0

    for i, stat in ipairs(statList) do
        local card = AcquireCompactCard(parent)
        local col = (i - 1) % 2  -- 0 = left, 1 = right
        row = math.floor((i - 1) / 2)

        local x = col * col2X
        local y = startY - row * (COMPACT_HEIGHT + CARD_GAP)

        card:ClearAllPoints()
        card:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

        -- Color
        local c = PP.Colors[stat.colorKey] or { 0.6, 0.6, 0.6 }
        card.accent:SetColorTexture(c[1], c[2], c[3], PP.AccentAlpha)

        -- Text
        card.value:SetText(FormatStatValue(stat))
        card.label:SetText(stat.label)

        -- Hover tooltip
        card.statData = stat
        card:EnableMouse(true)
        card:SetScript("OnEnter", function(self)
            ShowStatTooltip(self, self.statData)
        end)
        card:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        card:Show()
        table.insert(activeCards, card)
    end

    local totalRows = math.ceil(count / 2)
    return startY - totalRows * (COMPACT_HEIGHT + CARD_GAP)
end

--------------------------------------------------------------------------------
-- Full update
--------------------------------------------------------------------------------
local separators = {}

local function UpdateStats()
    if not PP.MainFrame or not PP.MainFrame.statsArea then return end
    if not PP.MainFrame:IsShown() then return end
    if PP.activeTab and PP.activeTab ~= "stats" then return end

    local parent = PP.MainFrame.statsArea
    ReleaseCards()

    -- Clear old separators
    for _, sep in ipairs(separators) do
        sep:Hide()
    end
    wipe(separators)

    local stats = PP:GetAllStats()
    local y = -4

    -- Primary stats (full-width with diamond icons)
    y = LayoutSingleColumn(stats.primary, parent, y)

    -- Separator + secondary stats (full-width with diamond icons)
    if #stats.secondary > 0 then
        y = y - (TIER_GAP / 2)
        table.insert(separators, CreateTierSeparator(parent, y))
        y = y - (TIER_GAP / 2)
        y = LayoutSingleColumn(stats.secondary, parent, y)
    end

    -- Separator + tertiary stats (compact 2-column, no icons)
    if #stats.tertiary > 0 then
        y = y - (TIER_GAP / 2)
        table.insert(separators, CreateTierSeparator(parent, y))
        y = y - (TIER_GAP / 2)
        y = LayoutTwoColumn(stats.tertiary, parent, y)
    end

    -- Update scroll child height so ScrollFrame knows the content size
    local totalHeight = math.abs(y) + 8
    parent:SetHeight(totalHeight)
end

--------------------------------------------------------------------------------
-- Init
--------------------------------------------------------------------------------
PP:RegisterEvent("PP_FRAME_CREATED", function()
    local parent = PP.MainFrame.statsArea
    if parent then
        for _ = 1, 10 do
            table.insert(cardPool, CreateCard(parent))
        end
        for _ = 1, 12 do
            table.insert(compactPool, CreateCompactCard(parent))
        end
    end
end)

PP:RegisterEvent("PP_STATS_UPDATE", function()
    UpdateStats()
end)

PP:RegisterEvent("PP_TAB_CHANGED", function(event, tabID)
    if not PP.MainFrame then return end
    local scroll = PP.MainFrame.statsScrollFrame
    if not scroll then return end
    if tabID == "stats" then
        scroll:Show()
        UpdateStats()
    else
        scroll:Hide()
    end
end)
