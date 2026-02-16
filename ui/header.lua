-- ProfilePanel: Character header — web armory style
-- Layout:
--   Row 1:  Title (small)                       AchPts   iLvl ILVL
--           Character Name (large, class-colored)
--   Row 2:                            Level Race Spec Class <Guild> Realm
local _, PP = ...

local header

local function CreateHeader(parent)
    header = parent

    -- Title (above name, smaller text, gold-dim)
    header.title = header:CreateFontString(nil, "OVERLAY")
    header.title:SetPoint("TOPLEFT", 4, -4)
    header.title:SetFont(STANDARD_TEXT_FONT, 10)
    header.title:SetTextColor(0.80, 0.78, 0.58)

    -- Character name (large, class-colored)
    header.name = header:CreateFontString(nil, "OVERLAY")
    header.name:SetPoint("TOPLEFT", header.title, "BOTTOMLEFT", 0, -1)
    header.name:SetFont(STANDARD_TEXT_FONT, 20, "OUTLINE")
    header.name:SetTextColor(PP:ClassColor())

    -- Right side: Achievement points + ilvl (must be created BEFORE subtitle)
    -- Item Level (right-aligned)
    header.ilvl = header:CreateFontString(nil, "OVERLAY")
    header.ilvl:SetPoint("TOPRIGHT", -4, -6)
    header.ilvl:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
    header.ilvl:SetJustifyH("RIGHT")
    header.ilvl:SetTextColor(1, 0.84, 0)

    -- Achievement points (left of ilvl)
    header.achvPoints = header:CreateFontString(nil, "OVERLAY")
    header.achvPoints:SetPoint("RIGHT", header.ilvl, "LEFT", -14, 0)
    header.achvPoints:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
    header.achvPoints:SetJustifyH("RIGHT")
    header.achvPoints:SetTextColor(1, 0.84, 0)

    -- Subtitle: Level Race Spec Class <Guild> Realm (right-aligned, under achv/ilvl)
    header.subtitle = header:CreateFontString(nil, "OVERLAY")
    header.subtitle:SetPoint("TOPRIGHT", header.ilvl, "BOTTOMRIGHT", 0, -2)
    header.subtitle:SetPoint("LEFT", header, "LEFT", 4, 0)
    header.subtitle:SetFont(STANDARD_TEXT_FONT, 10)
    header.subtitle:SetJustifyH("RIGHT")
    header.subtitle:SetTextColor(0.60, 0.60, 0.60)
end

local function UpdateHeader()
    if not header then return end

    -- Title (active character title, e.g. "Battlemaster")
    local titleText = ""
    local currentTitle = GetCurrentTitle and GetCurrentTitle() or 0
    if currentTitle and currentTitle > 0 then
        local rawTitle = GetTitleName and GetTitleName(currentTitle) or ""
        if rawTitle and rawTitle ~= "" then
            titleText = rawTitle:gsub("%%s", ""):gsub("^%s+", ""):gsub("%s+$", "")
        end
    end
    header.title:SetText(titleText)

    -- If no title, push name up to title position
    if titleText == "" then
        header.name:ClearAllPoints()
        header.name:SetPoint("TOPLEFT", header.title, "TOPLEFT", 0, 0)
    else
        header.name:ClearAllPoints()
        header.name:SetPoint("TOPLEFT", header.title, "BOTTOMLEFT", 0, -1)
    end

    -- Character name
    local name = UnitName("player")
    header.name:SetText(name)
    header.name:SetTextColor(PP:ClassColor())

    -- Subtitle: Level Race Spec Class <Guild> Realm
    local level = UnitLevel("player")
    local raceName = UnitRace("player") or ""
    local className = UnitClass("player") or ""
    local specName = ""
    local spec = GetSpecialization()
    if spec then
        local _, sName = GetSpecializationInfo(spec)
        specName = sName or ""
    end

    local guildName = GetGuildInfo("player")
    local realmName = GetRealmName() or ""

    local parts = {}
    table.insert(parts, tostring(level))
    table.insert(parts, raceName)
    if specName ~= "" then table.insert(parts, specName) end
    table.insert(parts, className)

    local subtitleStr = table.concat(parts, " ")
    if guildName and guildName ~= "" then
        subtitleStr = subtitleStr .. "  <" .. guildName .. ">"
    end
    subtitleStr = subtitleStr .. "  " .. realmName

    header.subtitle:SetText(subtitleStr)

    -- Achievement points
    local achvPts = GetTotalAchievementPoints and GetTotalAchievementPoints() or 0
    header.achvPoints:SetText("|cffFFD700" .. BreakUpLargeNumbers(achvPts) .. "|r")

    -- Item level
    local _, avgEquipped = GetAverageItemLevel()
    local ilvlNum = PP:Round(avgEquipped)
    header.ilvl:SetText("|cffFFD700" .. ilvlNum .. " ILVL|r")
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
