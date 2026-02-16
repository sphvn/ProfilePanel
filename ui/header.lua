-- ProfilePanel: Character header — web armory style
-- Layout:
--   Row 1: [Faction Icon]  Title (small, gold)              [Tab icons] [X]
--   Row 2: [            ]  Character Name (large, class-colored)
--   Row 3: [            ]  AchPts  |  iLvl ILVL  |  Level Race Spec Class <Guild> Realm
local _, PP = ...

local header

local ICON_SIZE    = 46
local ICON_PADDING = 8

local FACTION_ATLAS = {
    Horde    = "MountJournalIcons-Horde",
    Alliance = "MountJournalIcons-Alliance",
}

--------------------------------------------------------------------------------
-- Header creation
--------------------------------------------------------------------------------
local function CreateHeader(parent)
    header = parent

    -- Faction icon (Horde/Alliance emblem, vertically centered)
    header.factionIcon = header:CreateTexture(nil, "ARTWORK")
    header.factionIcon:SetSize(ICON_SIZE, ICON_SIZE)
    header.factionIcon:SetPoint("LEFT", 4, 0)

    local faction = UnitFactionGroup("player")
    if faction and FACTION_ATLAS[faction] then
        header.factionIcon:SetAtlas(FACTION_ATLAS[faction])
    end

    local textLeft = 4 + ICON_SIZE + ICON_PADDING

    -- Title (above name, smaller text, gold-dim)
    header.title = header:CreateFontString(nil, "OVERLAY")
    header.title:SetPoint("TOPLEFT", textLeft, -4)
    header.title:SetFont(STANDARD_TEXT_FONT, 10)
    header.title:SetTextColor(0.80, 0.78, 0.58)

    -- Character name (large, class-colored)
    header.name = header:CreateFontString(nil, "OVERLAY")
    header.name:SetPoint("TOPLEFT", header.title, "BOTTOMLEFT", 0, -1)
    header.name:SetFont(STANDARD_TEXT_FONT, 20, "OUTLINE")
    header.name:SetTextColor(PP:ClassColor())

    -- Info line: achievements | ilvl | subtitle (single row, left-aligned)
    header.infoLine = header:CreateFontString(nil, "OVERLAY")
    header.infoLine:SetPoint("TOPLEFT", header.name, "BOTTOMLEFT", 0, -3)
    header.infoLine:SetPoint("RIGHT", header, "RIGHT", -4, 0)
    header.infoLine:SetFont(STANDARD_TEXT_FONT, 10)
    header.infoLine:SetJustifyH("LEFT")
    header.infoLine:SetTextColor(0.60, 0.60, 0.60)

end

--------------------------------------------------------------------------------
-- Header data refresh
--------------------------------------------------------------------------------
local function UpdateHeader()
    if not header then return end

    -- Title (active character title, e.g. "Battlemaster")
    local titleText = ""
    local currentTitle = PP.pendingTitleID or (GetCurrentTitle and GetCurrentTitle() or 0)
    if currentTitle and currentTitle > 0 then
        local rawTitle = GetTitleName and GetTitleName(currentTitle) or ""
        if rawTitle and rawTitle ~= "" then
            titleText = rawTitle:gsub("%%s", ""):gsub("^%s+", ""):gsub("%s+$", "")
        end
    end
    header.title:SetText(titleText)

    -- Adjust name position based on title presence
    header.name:ClearAllPoints()
    if titleText == "" then
        header.name:SetPoint("TOPLEFT", header.title, "TOPLEFT", 0, 0)
    else
        header.name:SetPoint("TOPLEFT", header.title, "BOTTOMLEFT", 0, -1)
    end

    -- Character name
    local name = UnitName("player")
    header.name:SetText(name)
    header.name:SetTextColor(PP:ClassColor())

    -- Faction icon refresh (in case it wasn't ready at creation time)
    local faction = UnitFactionGroup("player")
    if faction and FACTION_ATLAS[faction] then
        header.factionIcon:SetAtlas(FACTION_ATLAS[faction])
    end

    -- Build info line: achv | ilvl | level race spec class <guild> realm
    local infoParts = {}

    -- Achievement points (gold)
    local achvPts = GetTotalAchievementPoints and GetTotalAchievementPoints() or 0
    table.insert(infoParts, "|cffFFD700" .. BreakUpLargeNumbers(achvPts) .. "|r")

    -- Item level (gold, or green with diff if bag-best is higher)
    local avgBest, avgEquipped = GetAverageItemLevel()
    local equippedIlvl = PP:Round(avgEquipped)
    local bestIlvl = PP:Round(avgBest)
    if bestIlvl > equippedIlvl then
        local diff = bestIlvl - equippedIlvl
        table.insert(infoParts, "|cff00FF00" .. equippedIlvl .. " ILVL (+" .. diff .. ")|r")
    else
        table.insert(infoParts, "|cffFFD700" .. equippedIlvl .. " ILVL|r")
    end

    -- Subtitle portion: level race spec class <guild> realm
    local level = UnitLevel("player")
    local raceName = UnitRace("player") or ""
    local className = UnitClass("player") or ""
    local specName = ""
    local spec = GetSpecialization()
    if spec then
        local _, sName = GetSpecializationInfo(spec)
        specName = sName or ""
    end

    local subParts = {}
    table.insert(subParts, tostring(level))
    table.insert(subParts, raceName)
    if specName ~= "" then table.insert(subParts, specName) end
    table.insert(subParts, className)
    local subtitleStr = table.concat(subParts, " ")

    -- Guild name in distinctive green
    local guildName = GetGuildInfo("player")
    if guildName and guildName ~= "" then
        subtitleStr = subtitleStr .. "  |cff78c846<" .. guildName .. ">|r"
    end

    local realmName = GetRealmName() or ""
    subtitleStr = subtitleStr .. "  " .. realmName

    table.insert(infoParts, subtitleStr)

    -- Join with gray pipe separators  (|| renders as literal | in WoW text)
    local sep = "  |cff666666|||r  "
    header.infoLine:SetText(table.concat(infoParts, sep))
end

--------------------------------------------------------------------------------
-- Hooks
--------------------------------------------------------------------------------
PP:RegisterEvent("PP_FRAME_CREATED", function()
    CreateHeader(PP.MainFrame.header)
end)

PP:RegisterEvent("PP_STATS_UPDATE", function()
    UpdateHeader()
end)
