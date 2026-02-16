-- ProfilePanel: Main frame — hooks CharacterFrame and provides layout regions
local _, PP = ...

local FRAME_WIDTH  = 730
local FRAME_HEIGHT = 615
local HEADER_HEIGHT = 70
local STATS_PANEL_WIDTH = 200

local TAB_BAR_HEIGHT = 28

local MainFrame
local hiddenElements = {}

-- View state: "character", "reputation", "currency"
local currentView = "character"

-- Persistent elements (parented to CharacterFrame, survive PaperDollFrame hide)
local repCurrOverlay   -- dark bg + border for rep/currency views
local tabBar           -- bottom tab strip
local bottomTabBtns = {}

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

    -- Blizzard bottom tabs (we provide our own)
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
-- ┌──────────────────────────────────────────┬──────────────┐
-- │  Header (70px)                           │              │
-- ├──────────────────────────────────────────┤  Stats Panel │
-- │ [icon] Name         Name [icon]  vert sep│  (scrollable)│
-- │        ilvl             ilvl     │       │              │
-- │        Enchant       Enchant     │       │              │
-- │                                  │       │              │
-- │     (Model fills entire area)    │       │              │
-- │                                  │       │              │
-- │     [MH icon] Name  [OH icon]    │       │              │
-- └──────────────────────────────────┴───────┴──────────────┘
-- [ Character ]  [ Reputation ]  [ Currency ]
--------------------------------------------------------------------------------
local function CreateLayout(parent)
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

    -- Content area (below header, left of stats panel)
    local contentTop = -(HEADER_HEIGHT + 8)

    -- Model region (fills entire content area, equipment overlays on top)
    parent.modelArea = CreateFrame("Frame", nil, parent)
    parent.modelArea:SetPoint("TOPLEFT", 8, contentTop)
    parent.modelArea:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -(STATS_PANEL_WIDTH + 8), 4)

    -- Vertical separator between model section and stats panel
    local vertSep = parent:CreateTexture(nil, "ARTWORK")
    vertSep:SetPoint("TOPLEFT", parent.modelArea, "TOPRIGHT", 0, 0)
    vertSep:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", FRAME_WIDTH - STATS_PANEL_WIDTH, 8)
    vertSep:SetWidth(1)
    vertSep:SetColorTexture(1, 1, 1, 0.08)

    -- Stats panel (right side, scrollable)
    parent.statsPanel = CreateFrame("Frame", nil, parent)
    parent.statsPanel:SetPoint("TOPLEFT", parent.modelArea, "TOPRIGHT", 4, 0)
    parent.statsPanel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -8, 8)

    -- Manual scroll frame (no Blizzard template to avoid compatibility issues)
    local scroll = CreateFrame("ScrollFrame", nil, parent.statsPanel)
    scroll:SetAllPoints()
    scroll:EnableMouseWheel(true)

    local scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetWidth(STATS_PANEL_WIDTH - 8)
    scrollChild:SetHeight(1) -- dynamically set by stats.lua
    scroll:SetScrollChild(scrollChild)

    scroll:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = max(0, scrollChild:GetHeight() - self:GetHeight())
        local newScroll = max(0, min(current - (delta * 30), maxScroll))
        self:SetVerticalScroll(newScroll)
    end)

    parent.statsScrollFrame = scroll
    parent.statsArea = scrollChild
end

--------------------------------------------------------------------------------
-- Bottom tab bar — custom Character / Reputation / Currency tabs
-- Parented to CharacterFrame so it stays visible across all views.
--------------------------------------------------------------------------------
local function UpdateBottomTabHighlights()
    local activeID = currentView == "character" and 1
                  or currentView == "reputation" and 2
                  or 3
    for _, btn in ipairs(bottomTabBtns) do
        if btn.tabID == activeID then
            btn.label:SetTextColor(1, 0.84, 0)
            btn.activeBar:Show()
        else
            btn.label:SetTextColor(0.50, 0.50, 0.50)
            btn.activeBar:Hide()
        end
    end
end

local function CreateBottomTabBar()
    tabBar = CreateFrame("Frame", "ProfilePanelTabBar", CharacterFrame)
    tabBar:SetPoint("TOPLEFT", PaperDollFrame, "TOPLEFT", 0, -FRAME_HEIGHT)
    tabBar:SetSize(FRAME_WIDTH, TAB_BAR_HEIGHT)
    tabBar:SetFrameLevel(CharacterFrame:GetFrameLevel() + 30)

    -- Tab bar background
    local bg = tabBar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.06, 0.06, 0.10, 0.97)

    -- Top separator line
    local sep = tabBar:CreateTexture(nil, "BORDER")
    sep:SetPoint("TOPLEFT", 0, 0)
    sep:SetPoint("TOPRIGHT", 0, 0)
    sep:SetHeight(1)
    sep:SetColorTexture(1, 1, 1, 0.08)

    -- Tab definitions
    local BOTTOM_TABS = {
        { id = 1, label = "Character" },
        { id = 2, label = "Reputation" },
        { id = 3, label = "Currency" },
    }

    local tabWidth = 100
    local gap = 2

    for i, def in ipairs(BOTTOM_TABS) do
        local btn = CreateFrame("Button", nil, tabBar)
        btn:SetSize(tabWidth, TAB_BAR_HEIGHT - 2)
        btn:SetPoint("BOTTOMLEFT", tabBar, "BOTTOMLEFT",
                     8 + (i - 1) * (tabWidth + gap), 1)

        btn.label = btn:CreateFontString(nil, "OVERLAY")
        btn.label:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        btn.label:SetPoint("CENTER")
        btn.label:SetText(def.label)
        btn.label:SetTextColor(0.50, 0.50, 0.50)

        -- Active indicator (gold top bar)
        btn.activeBar = btn:CreateTexture(nil, "OVERLAY")
        btn.activeBar:SetPoint("TOPLEFT", 2, 0)
        btn.activeBar:SetPoint("TOPRIGHT", -2, 0)
        btn.activeBar:SetHeight(2)
        btn.activeBar:SetColorTexture(1, 0.84, 0, 0.8)
        btn.activeBar:Hide()

        -- Hover
        btn:SetScript("OnEnter", function(self)
            if self.tabID ~= (currentView == "character" and 1
                           or currentView == "reputation" and 2 or 3) then
                self.label:SetTextColor(0.80, 0.80, 0.80)
            end
        end)
        btn:SetScript("OnLeave", function()
            UpdateBottomTabHighlights()
        end)

        -- Click: trigger the corresponding Blizzard tab
        btn:SetScript("OnClick", function()
            local blizzTab = _G["CharacterFrameTab" .. def.id]
            if blizzTab then blizzTab:Click() end
        end)

        btn.tabID = def.id
        table.insert(bottomTabBtns, btn)
    end

    tabBar:Hide()
    PP.tabBar = tabBar
end

--------------------------------------------------------------------------------
-- Rep / Currency overlay — dark background + border for non-character views
-- Parented to CharacterFrame so it stays visible when PaperDollFrame hides.
--------------------------------------------------------------------------------
-- Elements hidden during rep/currency view that need restoring
local repCurrHidden = {}

local function HideRepCurrElement(element)
    if element and element.Hide then
        element:Hide()
        repCurrHidden[element] = true
    end
end

local function RestoreRepCurrElements()
    for element in pairs(repCurrHidden) do
        if element.Show then element:Show() end
        if element.SetAlpha then element:SetAlpha(1) end
        if element.EnableMouse then element:EnableMouse(true) end
    end
    wipe(repCurrHidden)
end

local function CreateRepCurrOverlay()
    repCurrOverlay = CreateFrame("Frame", "ProfilePanelRepCurrOverlay", CharacterFrame)
    repCurrOverlay:SetPoint("TOPLEFT", PaperDollFrame, "TOPLEFT", 0, 0)
    repCurrOverlay:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    repCurrOverlay:SetFrameLevel(CharacterFrame:GetFrameLevel() + 2)

    repCurrOverlay.bg = repCurrOverlay:CreateTexture(nil, "BACKGROUND")
    repCurrOverlay.bg:SetAllPoints()
    repCurrOverlay.bg:SetColorTexture(unpack(PP.BgColor))

    CreateBorder(repCurrOverlay)
    CreateCloseButton(repCurrOverlay)

    -- View title (shared between Reputation and Currency)
    repCurrOverlay.title = repCurrOverlay:CreateFontString(nil, "OVERLAY")
    repCurrOverlay.title:SetFont(STANDARD_TEXT_FONT, 20, "OUTLINE")
    repCurrOverlay.title:SetPoint("TOPLEFT", 16, -14)
    repCurrOverlay.title:SetTextColor(1, 1, 1)

    -- Thin separator below title
    repCurrOverlay.titleSep = repCurrOverlay:CreateTexture(nil, "ARTWORK")
    repCurrOverlay.titleSep:SetPoint("TOPLEFT", repCurrOverlay.title, "BOTTOMLEFT", -4, -8)
    repCurrOverlay.titleSep:SetPoint("RIGHT", repCurrOverlay, "RIGHT", -12, 0)
    repCurrOverlay.titleSep:SetHeight(1)
    repCurrOverlay.titleSep:SetColorTexture(1, 1, 1, 0.08)

    repCurrOverlay:Hide()
end

local TITLE_AREA_HEIGHT = 46  -- title + separator + padding

local function ShowRepCurrView(viewName)
    currentView = viewName
    RestoreRepCurrElements()

    -- Show dark overlay (MainFrame is already hidden since PaperDollFrame hid)
    repCurrOverlay:Show()

    -- Suppress Blizzard tabs — using alpha+mouse disable because
    -- PanelTemplates_SetTab re-shows them on subcategory interaction.
    for _, tabName in ipairs({ "CharacterFrameTab1", "CharacterFrameTab2", "CharacterFrameTab3" }) do
        local tab = _G[tabName]
        if tab then
            tab:SetAlpha(0)
            tab:EnableMouse(false)
            repCurrHidden[tab] = true
        end
    end

    if viewName == "reputation" then
        repCurrOverlay.title:SetText("Reputation")

        -- Reposition ReputationFrame to fill the overlay
        if ReputationFrame then
            ReputationFrame:ClearAllPoints()
            ReputationFrame:SetPoint("TOPLEFT", repCurrOverlay, "TOPLEFT", 4, -4)
            ReputationFrame:SetPoint("BOTTOMRIGHT", repCurrOverlay, "BOTTOMRIGHT", -4, 4)

            -- Reposition ScrollBox to fill the area below the title
            if ReputationFrame.ScrollBox then
                ReputationFrame.ScrollBox:ClearAllPoints()
                ReputationFrame.ScrollBox:SetPoint("TOPLEFT", repCurrOverlay, "TOPLEFT", 12, -TITLE_AREA_HEIGHT)
                ReputationFrame.ScrollBox:SetPoint("BOTTOMRIGHT", repCurrOverlay, "BOTTOMRIGHT", -30, 8)
            end

            -- Hide the "All" filter dropdown
            if ReputationFrame.filterDropdown then
                HideRepCurrElement(ReputationFrame.filterDropdown)
            end
        end

    else -- currency
        repCurrOverlay.title:SetText("Currency")

        -- Reposition TokenFrame to fill the overlay
        if TokenFrame then
            TokenFrame:ClearAllPoints()
            TokenFrame:SetPoint("TOPLEFT", repCurrOverlay, "TOPLEFT", 4, -4)
            TokenFrame:SetPoint("BOTTOMRIGHT", repCurrOverlay, "BOTTOMRIGHT", -4, 4)

            -- Reposition ScrollBox to fill the area below the title
            if TokenFrame.ScrollBox then
                TokenFrame.ScrollBox:ClearAllPoints()
                TokenFrame.ScrollBox:SetPoint("TOPLEFT", repCurrOverlay, "TOPLEFT", 12, -TITLE_AREA_HEIGHT)
                TokenFrame.ScrollBox:SetPoint("BOTTOMRIGHT", repCurrOverlay, "BOTTOMRIGHT", -30, 8)
            end

            -- Hide the filter dropdown ("Ashkeryn Only" etc.)
            if TokenFrame.filterDropdown then
                HideRepCurrElement(TokenFrame.filterDropdown)
            end

            -- Hide the bonus currency / backpack token frame
            if BackpackTokenFrame then
                HideRepCurrElement(BackpackTokenFrame)
            end
        end
    end

    UpdateBottomTabHighlights()
end

local function HideRepCurrView()
    RestoreRepCurrElements()
    if repCurrOverlay then
        repCurrOverlay:Hide()
    end
    currentView = "character"
end

--------------------------------------------------------------------------------
-- Create the main frame
--------------------------------------------------------------------------------
local function CreateMainFrame()
    MainFrame = CreateFrame("Frame", "ProfilePanelFrame", PaperDollFrame)
    PP.MainFrame = MainFrame

    -- Single-point anchor + explicit size (don't depend on CharacterFrame's size)
    MainFrame:SetPoint("TOPLEFT", PaperDollFrame, "TOPLEFT", 0, 0)
    MainFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    MainFrame:SetFrameLevel(PaperDollFrame:GetFrameLevel() + 20)

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

    -- If already showing the character view, just refresh data (don't re-run
    -- the full show logic, which would interfere with context menus, tooltips, etc.)
    if MainFrame:IsShown() and currentView == "character" then
        PP:FireEvent("PP_STATS_UPDATE")
        return
    end

    HideBlizzardChrome()
    HideRepCurrView()

    MainFrame:Show()
    if tabBar then tabBar:Show() end

    currentView = "character"
    UpdateBottomTabHighlights()

    PP:FireEvent("PP_SHOW")
    PP:FireEvent("PP_STATS_UPDATE")
end

local function HidePanel()
    if not MainFrame then return end
    MainFrame:Hide()
    HideRepCurrView()

    if tabBar then tabBar:Hide() end

    RestoreBlizzardChrome()

    PP:FireEvent("PP_HIDE")
end

-- Helper for our close button — use HideUIPanel so UIParentPanelManager
-- properly releases the frame slot (plain :Hide() causes position drift).
function HideDefaultUI()
    if CharacterFrame and CharacterFrame:IsShown() then
        HideUIPanel(CharacterFrame)
    end
end

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------
PP:RegisterEvent("PP_READY", function()
    CreateMainFrame()
    CreateBottomTabBar()
    CreateRepCurrOverlay()
    PP:FireEvent("PP_FRAME_CREATED")

    -- Character frame opens with PaperDoll visible → show our panel
    hooksecurefunc(CharacterFrame, "Show", function()
        if PaperDollFrame and PaperDollFrame:IsShown() then
            ShowPanel()
        end
    end)

    -- PaperDoll explicitly shown (tab switch back to Character)
    hooksecurefunc(PaperDollFrame, "Show", function()
        ShowPanel()
    end)

    -- PaperDoll explicitly hidden (tab switch to Rep/Currency)
    -- NOTE: This only fires on explicit :Hide() calls (tab switch),
    -- NOT when PaperDollFrame hides implicitly via CharacterFrame:Hide().
    hooksecurefunc(PaperDollFrame, "Hide", function()
        if MainFrame then
            MainFrame:Hide()
            PP:FireEvent("PP_HIDE")
        end
    end)

    -- CharacterFrame closes entirely → full cleanup
    hooksecurefunc(CharacterFrame, "Hide", function()
        HidePanel()
    end)

    -- Reputation / Currency frame hooks (guarded in case frames are load-on-demand)
    if ReputationFrame then
        hooksecurefunc(ReputationFrame, "Show", function()
            if tabBar and tabBar:IsShown() then
                ShowRepCurrView("reputation")
            end
        end)
    end
    if TokenFrame then
        hooksecurefunc(TokenFrame, "Show", function()
            if tabBar and tabBar:IsShown() then
                ShowRepCurrView("currency")
            end
        end)
    end

    -- Suppress Blizzard tab re-shows during rep/currency views.
    -- PanelTemplates_SetTab calls :Show() on the active tab when subcategories
    -- are clicked. We hook each tab's Show to force alpha=0 while in rep/currency.
    for _, tabName in ipairs({ "CharacterFrameTab1", "CharacterFrameTab2", "CharacterFrameTab3" }) do
        local tab = _G[tabName]
        if tab then
            hooksecurefunc(tab, "Show", function(self)
                if currentView ~= "character" and repCurrOverlay and repCurrOverlay:IsShown() then
                    self:SetAlpha(0)
                    self:EnableMouse(false)
                end
            end)
        end
    end

end)
