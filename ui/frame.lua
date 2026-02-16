-- ProfilePanel: Main frame — hooks CharacterFrame and provides layout regions
local _, PP = ...

local FRAME_WIDTH  = 730
local FRAME_HEIGHT = 650
local HEADER_HEIGHT = 70
local STATS_PANEL_WIDTH = 146
local GEAR_COL_WIDTH = 46

local MainFrame
local hiddenElements = {}

--------------------------------------------------------------------------------
-- Blizzard chrome — hide/show helpers
-- We hide all default CharacterFrame decorations when our panel is active and
-- restore them on hide so Reputation / Currency tabs still work.
--------------------------------------------------------------------------------
local function HideElement(element)
    if element and element.Show then
        element:Hide()
        hiddenElements[element] = true
    end
end

local function HideElementAlpha(element)
    if element and element.SetAlpha then
        element:SetAlpha(0)
        hiddenElements[element] = true
    end
end

local function RestoreElements()
    for element in pairs(hiddenElements) do
        if element.SetAlpha then element:SetAlpha(1) end
        if element.Show then element:Show() end
    end
    wipe(hiddenElements)
end

local function HideBlizzardChrome()
    -- Frame border / nineslice
    HideElement(CharacterFrame.NineSlice)

    -- Portrait orb (top-left)
    HideElement(CharacterFrame.PortraitContainer)

    -- Title bar ("Battlemaster Ashkeryn")
    HideElement(CharacterFrame.TitleContainer)

    -- Background art
    HideElement(CharacterFrame.Bg)
    HideElement(CharacterFrame.TopTileStreaks)

    -- Inset panels
    HideElement(CharacterFrameInset)
    HideElement(CharacterFrameInsetRight)

    -- Default character model
    HideElement(CharacterModelScene)

    -- PaperDoll items (we provide our own equipment display)
    HideElementAlpha(PaperDollItemsFrame)

    -- Default stat pane
    HideElement(CharacterStatsPane)

    -- Bottom tabs (Summary / Reputation / Currency)
    HideElement(CharacterFrameTab1)
    HideElement(CharacterFrameTab2)
    HideElement(CharacterFrameTab3)

    -- Blizzard close button (we provide our own)
    if CharacterFrame.CloseButton then
        CharacterFrame.CloseButton:SetAlpha(0)
        CharacterFrame.CloseButton:EnableMouse(false)
    end
end

local function RestoreBlizzardChrome()
    RestoreElements()

    if CharacterFrame.CloseButton then
        CharacterFrame.CloseButton:SetAlpha(1)
        CharacterFrame.CloseButton:EnableMouse(true)
    end
end

--------------------------------------------------------------------------------
-- Frame border — thin subtle edges
--------------------------------------------------------------------------------
local function CreateBorder(parent)
    local a = 0.12
    local c = { 1, 1, 1, a }

    local top = parent:CreateTexture(nil, "BORDER")
    top:SetPoint("TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", 0, 0)
    top:SetHeight(1)
    top:SetColorTexture(unpack(c))

    local bot = parent:CreateTexture(nil, "BORDER")
    bot:SetPoint("BOTTOMLEFT", 0, 0)
    bot:SetPoint("BOTTOMRIGHT", 0, 0)
    bot:SetHeight(1)
    bot:SetColorTexture(unpack(c))

    local left = parent:CreateTexture(nil, "BORDER")
    left:SetPoint("TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", 0, 0)
    left:SetWidth(1)
    left:SetColorTexture(unpack(c))

    local right = parent:CreateTexture(nil, "BORDER")
    right:SetPoint("TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", 0, 0)
    right:SetWidth(1)
    right:SetColorTexture(unpack(c))
end

--------------------------------------------------------------------------------
-- Close button — minimal X button
--------------------------------------------------------------------------------
local function CreateCloseButton(parent)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(20, 20)
    btn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -6, -6)
    btn:SetFrameLevel(parent:GetFrameLevel() + 20)

    btn.text = btn:CreateFontString(nil, "OVERLAY")
    btn.text:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
    btn.text:SetPoint("CENTER", 0, 0)
    btn.text:SetText("x")
    btn.text:SetTextColor(0.6, 0.6, 0.6)

    btn:SetScript("OnEnter", function(self)
        self.text:SetTextColor(1, 0.3, 0.3)
    end)
    btn:SetScript("OnLeave", function(self)
        self.text:SetTextColor(0.6, 0.6, 0.6)
    end)
    btn:SetScript("OnClick", function()
        HideDefaultUI()
    end)

    parent.closeBtn = btn
end

--------------------------------------------------------------------------------
-- Layout containers
-- ┌───────────────────────────────────────────┬──────────────┐
-- │  Header (full width)                      │              │
-- ├──────┬──────────────────┬──────┬──────────┤  Stats Panel │
-- │ Left │                  │Right │ vert sep │  (scrollable)│
-- │ Gear │   Model Area     │ Gear │          │              │
-- ├──────┴──────┬───────────┴──────┤          │              │
-- │  Weapon Row │                  │          │              │
-- └─────────────┴──────────────────┴──────────┴──────────────┘
--------------------------------------------------------------------------------
local function CreateLayout(parent)
    local leftWidth = FRAME_WIDTH - STATS_PANEL_WIDTH

    -- Header region (full width)
    parent.header = CreateFrame("Frame", nil, parent)
    parent.header:SetPoint("TOPLEFT", 8, -4)
    parent.header:SetPoint("TOPRIGHT", -8, -4)
    parent.header:SetHeight(HEADER_HEIGHT)

    -- Header bottom separator
    local headerSep = parent.header:CreateTexture(nil, "ARTWORK")
    headerSep:SetPoint("BOTTOMLEFT", 0, 0)
    headerSep:SetPoint("BOTTOMRIGHT", 0, 0)
    headerSep:SetHeight(1)
    headerSep:SetColorTexture(1, 1, 1, 0.08)

    -- Equipment left column
    local contentTop = -(HEADER_HEIGHT + 8)
    parent.gearLeft = CreateFrame("Frame", nil, parent)
    parent.gearLeft:SetPoint("TOPLEFT", 8, contentTop)
    parent.gearLeft:SetSize(GEAR_COL_WIDTH, 370)

    -- Equipment right column (left of stats panel)
    parent.gearRight = CreateFrame("Frame", nil, parent)
    parent.gearRight:SetPoint("TOPLEFT", leftWidth - GEAR_COL_WIDTH - 8, contentTop)
    parent.gearRight:SetSize(GEAR_COL_WIDTH, 370)

    -- Model region (between equipment columns)
    parent.modelArea = CreateFrame("Frame", nil, parent)
    parent.modelArea:SetPoint("TOPLEFT", parent.gearLeft, "TOPRIGHT", 4, 0)
    parent.modelArea:SetPoint("BOTTOMRIGHT", parent.gearRight, "BOTTOMLEFT", -4, 50)

    -- Weapon row (below model, spanning left section)
    parent.weaponRow = CreateFrame("Frame", nil, parent)
    parent.weaponRow:SetPoint("TOPLEFT", parent.gearLeft, "BOTTOMLEFT", 0, -4)
    parent.weaponRow:SetPoint("RIGHT", parent.gearRight, "RIGHT", 0, 0)
    parent.weaponRow:SetHeight(42)

    -- Vertical separator between left section and stats panel
    local vertSep = parent:CreateTexture(nil, "ARTWORK")
    vertSep:SetPoint("TOPLEFT", parent, "TOPLEFT", leftWidth, contentTop)
    vertSep:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", leftWidth, 8)
    vertSep:SetWidth(1)
    vertSep:SetColorTexture(1, 1, 1, 0.08)

    -- Stats panel (right side)
    parent.statsPanel = CreateFrame("Frame", nil, parent)
    parent.statsPanel:SetPoint("TOPLEFT", parent, "TOPLEFT", leftWidth + 4, contentTop)
    parent.statsPanel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -8, 8)

    -- Stats content area (direct child, no scroll for now)
    parent.statsArea = parent.statsPanel
end

--------------------------------------------------------------------------------
-- Create the main frame
--------------------------------------------------------------------------------
local function CreateMainFrame()
    -- The original pattern that worked: SetSize on CharacterFrame + two-point anchor
    CharacterFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)

    MainFrame = CreateFrame("Frame", "ProfilePanelFrame", PaperDollFrame)
    PP.MainFrame = MainFrame

    MainFrame:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 0, 0)
    MainFrame:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", 0, 0)
    MainFrame:SetFrameLevel(PaperDollFrame:GetFrameLevel() + 5)

    -- Dark background
    MainFrame.bg = MainFrame:CreateTexture(nil, "BACKGROUND")
    MainFrame.bg:SetAllPoints()
    MainFrame.bg:SetColorTexture(unpack(PP.BgColor))

    CreateBorder(MainFrame)
    CreateCloseButton(MainFrame)
    CreateLayout(MainFrame)
    MainFrame:Hide()

    return MainFrame
end

--------------------------------------------------------------------------------
-- Show / hide management
--------------------------------------------------------------------------------
local function ShowPanel()
    if not MainFrame then return end

    HideBlizzardChrome()

    MainFrame:Show()
    PP:FireEvent("PP_SHOW")
    PP:FireEvent("PP_STATS_UPDATE")
end

local function HidePanel()
    if not MainFrame then return end
    MainFrame:Hide()

    RestoreBlizzardChrome()

    PP:FireEvent("PP_HIDE")
end

-- Helper for our close button
function HideDefaultUI()
    if CharacterFrame and CharacterFrame:IsShown() then
        CharacterFrame:Hide()
    end
end

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------
PP:RegisterEvent("PP_READY", function()
    CreateMainFrame()
    PP:FireEvent("PP_FRAME_CREATED")

    hooksecurefunc(CharacterFrame, "Show", function()
        if PaperDollFrame and PaperDollFrame:IsShown() then
            ShowPanel()
        end
    end)
    hooksecurefunc(PaperDollFrame, "Show", function()
        ShowPanel()
    end)
    hooksecurefunc(PaperDollFrame, "Hide", function()
        HidePanel()
    end)
    hooksecurefunc(CharacterFrame, "Hide", function()
        HidePanel()
    end)

end)
