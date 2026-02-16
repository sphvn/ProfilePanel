-- ProfilePanel: Tab system — controls which content appears in the right panel
-- Tab buttons live in the header top-right; clicking one swaps the statsPanel content.
local _, PP = ...

local TAB_GAP = 4

PP.activeTab = "stats"

local TAB_DEFS = {
    { id = "stats",    label = "Stats" },
    { id = "gearsets", label = "Sets" },
    { id = "titles",   label = "Titles" },
}

local tabButtons = {}

--------------------------------------------------------------------------------
-- Highlight management
--------------------------------------------------------------------------------
local function UpdateHighlights()
    for _, btn in ipairs(tabButtons) do
        if btn.tabID == PP.activeTab then
            btn.label:SetTextColor(1, 0.84, 0)
            btn.activeBar:Show()
        else
            btn.label:SetTextColor(0.50, 0.50, 0.50)
            btn.activeBar:Hide()
        end
    end
end

--------------------------------------------------------------------------------
-- Tab switching
--------------------------------------------------------------------------------
local function SwitchTab(tabID)
    if PP.activeTab == tabID then return end
    PP.activeTab = tabID
    UpdateHighlights()
    PP:FireEvent("PP_TAB_CHANGED", tabID)
end

function PP:GetActiveTab()
    return PP.activeTab
end

--------------------------------------------------------------------------------
-- Build tab buttons
--------------------------------------------------------------------------------
local function CreateTabs()
    local header = PP.MainFrame.header
    local statsPanel = PP.MainFrame.statsPanel
    if not header or not statsPanel then return end

    -- Create buttons right-to-left in the header top-right area.
    -- Leave ~26 px gap on the right for the close button (which lives on MainFrame).
    local prevBtn = nil
    for i = #TAB_DEFS, 1, -1 do
        local def = TAB_DEFS[i]
        local btn = CreateFrame("Button", nil, header)
        btn.tabID = def.id
        btn:SetHeight(20)

        -- Label
        btn.label = btn:CreateFontString(nil, "OVERLAY")
        btn.label:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        btn.label:SetPoint("CENTER", 0, 1)
        btn.label:SetText(def.label)
        btn.label:SetTextColor(0.50, 0.50, 0.50)

        -- Auto-size button width to fit label + padding
        local tw = btn.label:GetStringWidth()
        btn:SetWidth(math.max(tw + 12, 30))

        -- Active indicator (gold underline)
        btn.activeBar = btn:CreateTexture(nil, "OVERLAY")
        btn.activeBar:SetPoint("BOTTOMLEFT", 2, 0)
        btn.activeBar:SetPoint("BOTTOMRIGHT", -2, 0)
        btn.activeBar:SetHeight(2)
        btn.activeBar:SetColorTexture(1, 0.84, 0, 0.8)
        btn.activeBar:Hide()

        -- Hover
        btn:SetScript("OnEnter", function(self)
            if self.tabID ~= PP.activeTab then
                self.label:SetTextColor(0.80, 0.80, 0.80)
            end
        end)
        btn:SetScript("OnLeave", function(self)
            if self.tabID ~= PP.activeTab then
                self.label:SetTextColor(0.50, 0.50, 0.50)
            end
        end)
        btn:SetScript("OnClick", function(self)
            SwitchTab(self.tabID)
        end)

        -- Anchor: rightmost button first, then chain leftward
        if prevBtn then
            btn:SetPoint("TOPRIGHT", prevBtn, "TOPLEFT", -TAB_GAP, 0)
        else
            btn:SetPoint("TOPRIGHT", header, "TOPRIGHT", -26, -4)
        end

        table.insert(tabButtons, 1, btn)
        prevBtn = btn
    end

    -- Initial highlight state
    UpdateHighlights()
end

--------------------------------------------------------------------------------
-- Custom gear sets list
--------------------------------------------------------------------------------
local SET_ROW_HEIGHT = 36
local SET_ROW_GAP    = 2
local SET_ICON_SIZE  = 28
local SET_BTN_HEIGHT = 22

local setFrame        -- container frame
local setScroll       -- ScrollFrame
local setChild        -- scroll child
local setRows = {}    -- pool of row buttons
local setSelectedID   -- currently selected set for Save
local RefreshSetList  -- forward declaration

--------------------------------------------------------------------------------
-- Gold border highlight (shared by title + set rows)
--------------------------------------------------------------------------------
local BORDER_WIDTH = 1.5
local BORDER_COLOR = { 1, 0.84, 0, 0.8 }
local BORDER_HOVER_COLOR = { 1, 0.84, 0, 0.35 }

local function AddGoldBorder(frame)
    frame.borderTop = frame:CreateTexture(nil, "OVERLAY")
    frame.borderTop:SetHeight(BORDER_WIDTH)
    frame.borderTop:SetPoint("TOPLEFT", 0, 0)
    frame.borderTop:SetPoint("TOPRIGHT", 0, 0)
    frame.borderTop:SetColorTexture(unpack(BORDER_COLOR))
    frame.borderTop:Hide()

    frame.borderBottom = frame:CreateTexture(nil, "OVERLAY")
    frame.borderBottom:SetHeight(BORDER_WIDTH)
    frame.borderBottom:SetPoint("BOTTOMLEFT", 0, 0)
    frame.borderBottom:SetPoint("BOTTOMRIGHT", 0, 0)
    frame.borderBottom:SetColorTexture(unpack(BORDER_COLOR))
    frame.borderBottom:Hide()

    frame.borderLeft = frame:CreateTexture(nil, "OVERLAY")
    frame.borderLeft:SetWidth(BORDER_WIDTH)
    frame.borderLeft:SetPoint("TOPLEFT", 0, 0)
    frame.borderLeft:SetPoint("BOTTOMLEFT", 0, 0)
    frame.borderLeft:SetColorTexture(unpack(BORDER_COLOR))
    frame.borderLeft:Hide()

    frame.borderRight = frame:CreateTexture(nil, "OVERLAY")
    frame.borderRight:SetWidth(BORDER_WIDTH)
    frame.borderRight:SetPoint("TOPRIGHT", 0, 0)
    frame.borderRight:SetPoint("BOTTOMRIGHT", 0, 0)
    frame.borderRight:SetColorTexture(unpack(BORDER_COLOR))
    frame.borderRight:Hide()
end

local function ShowGoldBorder(frame)
    if frame.borderTop then
        frame.borderTop:SetColorTexture(unpack(BORDER_COLOR))
        frame.borderBottom:SetColorTexture(unpack(BORDER_COLOR))
        frame.borderLeft:SetColorTexture(unpack(BORDER_COLOR))
        frame.borderRight:SetColorTexture(unpack(BORDER_COLOR))
        frame.borderTop:Show()
        frame.borderBottom:Show()
        frame.borderLeft:Show()
        frame.borderRight:Show()
    end
end

local function ShowHoverBorder(frame)
    if frame.borderTop then
        frame.borderTop:SetColorTexture(unpack(BORDER_HOVER_COLOR))
        frame.borderBottom:SetColorTexture(unpack(BORDER_HOVER_COLOR))
        frame.borderLeft:SetColorTexture(unpack(BORDER_HOVER_COLOR))
        frame.borderRight:SetColorTexture(unpack(BORDER_HOVER_COLOR))
        frame.borderTop:Show()
        frame.borderBottom:Show()
        frame.borderLeft:Show()
        frame.borderRight:Show()
    end
end

local function HideGoldBorder(frame)
    if frame.borderTop then
        frame.borderTop:Hide()
        frame.borderBottom:Hide()
        frame.borderLeft:Hide()
        frame.borderRight:Hide()
    end
end

--------------------------------------------------------------------------------
-- Inline delete (X) button helper for gear set rows
--------------------------------------------------------------------------------

local function CreateSetActionButton(parent, text, width)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width, SET_BTN_HEIGHT)

    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetColorTexture(unpack(PP.CardBgColor))

    btn.label = btn:CreateFontString(nil, "OVERLAY")
    btn.label:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    btn.label:SetPoint("CENTER", 0, 0)
    btn.label:SetText(text)
    btn.label:SetTextColor(0.85, 0.85, 0.85)

    btn:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(0.25, 0.25, 0.25, 0.9)
        self.label:SetTextColor(1, 1, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(unpack(PP.CardBgColor))
        self.label:SetTextColor(0.85, 0.85, 0.85)
    end)

    return btn
end

local function CreateSetRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(SET_ROW_HEIGHT)
    row:RegisterForDrag("LeftButton")

    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetColorTexture(unpack(PP.CardBgColor))

    AddGoldBorder(row)

    -- Gear set icon
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(SET_ICON_SIZE, SET_ICON_SIZE)
    row.icon:SetPoint("LEFT", 4, 0)

    -- Set name
    row.nameLabel = row:CreateFontString(nil, "OVERLAY")
    row.nameLabel:SetFont(STANDARD_TEXT_FONT, 11, "")
    row.nameLabel:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 6, -2)
    row.nameLabel:SetPoint("RIGHT", -22, 0)
    row.nameLabel:SetJustifyH("LEFT")
    row.nameLabel:SetTextColor(0.85, 0.85, 0.85)
    row.nameLabel:SetWordWrap(false)

    -- Equipped / item count subtitle
    row.subLabel = row:CreateFontString(nil, "OVERLAY")
    row.subLabel:SetFont(STANDARD_TEXT_FONT, 9, "")
    row.subLabel:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 6, 2)
    row.subLabel:SetJustifyH("LEFT")
    row.subLabel:SetTextColor(0.50, 0.50, 0.50)

    -- Delete (X) button, shown on hover
    row.deleteBtn = CreateFrame("Button", nil, row)
    row.deleteBtn:SetSize(16, 16)
    row.deleteBtn:SetPoint("RIGHT", -4, 0)
    row.deleteBtn.label = row.deleteBtn:CreateFontString(nil, "OVERLAY")
    row.deleteBtn.label:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    row.deleteBtn.label:SetPoint("CENTER", 0, 0)
    row.deleteBtn.label:SetText("x")
    row.deleteBtn.label:SetTextColor(0.5, 0.3, 0.3)
    row.deleteBtn:SetScript("OnEnter", function(self)
        self.label:SetTextColor(1, 0.4, 0.4)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Delete set", 1, 0.4, 0.4)
        GameTooltip:Show()
    end)
    row.deleteBtn:SetScript("OnLeave", function(self)
        self.label:SetTextColor(0.5, 0.3, 0.3)
        GameTooltip:Hide()
    end)
    row.deleteBtn:SetScript("OnClick", function(self)
        local r = self:GetParent()
        if r.setID then
            StaticPopup_Show("PP_DELETE_EQUIPMENT_SET", r.setName, nil, { setID = r.setID })
        end
    end)
    row.deleteBtn:Hide()

    -- Hover
    row:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(0.14, 0.13, 0.10, 0.95)
        if not self.isEquipped then
            self.nameLabel:SetTextColor(1, 1, 1)
            ShowHoverBorder(self)
        end
        self.deleteBtn:Show()
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(self.setName or "", 1, 1, 1)
        GameTooltip:AddLine("Click to equip  |  Drag to action bar", 0.5, 0.5, 0.5)
        GameTooltip:AddLine("Right-click to rename", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function(self)
        if self.isEquipped then
            self.bg:SetColorTexture(0.18, 0.16, 0.10, 0.9)
            ShowGoldBorder(self)
        else
            self.bg:SetColorTexture(unpack(PP.CardBgColor))
            self.nameLabel:SetTextColor(0.85, 0.85, 0.85)
            HideGoldBorder(self)
        end
        if not self.deleteBtn:IsMouseOver() then
            self.deleteBtn:Hide()
        end
        GameTooltip:Hide()
    end)

    -- Left-click: equip | Right-click: rename
    row:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            if self.setID then
                StaticPopup_Show("PP_RENAME_EQUIPMENT_SET", self.setName, nil, { setID = self.setID, oldName = self.setName })
            end
        else
            if self.setID then
                C_EquipmentSet.UseEquipmentSet(self.setID)
                setSelectedID = self.setID
            end
        end
    end)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    -- Drag: pick up for action bar
    row:SetScript("OnDragStart", function(self)
        if self.setID then
            C_EquipmentSet.PickupEquipmentSet(self.setID)
        end
    end)

    row:Hide()
    return row
end

RefreshSetList = function()
    if not setFrame then return end

    local setIDs = C_EquipmentSet.GetEquipmentSetIDs()

    for idx, setID in ipairs(setIDs) do
        local row = setRows[idx]
        if not row then
            row = CreateSetRow(setChild)
            setRows[idx] = row
        end

        local name, iconFileID, _, isEquipped, numItems, numEquipped = C_EquipmentSet.GetEquipmentSetInfo(setID)

        row:SetParent(setChild)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -((idx - 1) * (SET_ROW_HEIGHT + SET_ROW_GAP)))
        row:SetPoint("RIGHT", setChild, "RIGHT", 0, 0)

        row.setID = setID
        row.setName = name
        row.nameLabel:SetText(name or "")
        row.icon:SetTexture(iconFileID)

        local subText = (numEquipped or 0) .. "/" .. (numItems or 0) .. " equipped"
        row.subLabel:SetText(subText)

        row.isEquipped = isEquipped
        if isEquipped then
            row.nameLabel:SetTextColor(1, 0.84, 0)
            row.bg:SetColorTexture(0.18, 0.16, 0.10, 0.9)
            row.subLabel:SetTextColor(0.70, 0.60, 0.30)
            ShowGoldBorder(row)
            setSelectedID = setID
        else
            row.nameLabel:SetTextColor(0.85, 0.85, 0.85)
            row.bg:SetColorTexture(unpack(PP.CardBgColor))
            row.subLabel:SetTextColor(0.50, 0.50, 0.50)
            HideGoldBorder(row)
        end

        row:Show()
    end

    -- Hide unused rows
    for i = #setIDs + 1, #setRows do
        setRows[i]:Hide()
    end

    -- Update scroll child height
    local totalHeight = #setIDs * (SET_ROW_HEIGHT + SET_ROW_GAP)
    setChild:SetHeight(math.max(totalHeight, 1))
end

local function CreateSetList(parent)
    setFrame = CreateFrame("Frame", nil, parent)
    setFrame:SetAllPoints()
    setFrame:Hide()

    -- Action buttons: Save and New Set
    local btnWidth = 88
    local saveBtn = CreateSetActionButton(setFrame, "Save", btnWidth)
    saveBtn:SetPoint("TOPLEFT", setFrame, "TOPLEFT", 2, -2)
    saveBtn:SetScript("OnClick", function()
        if setSelectedID then
            C_EquipmentSet.SaveEquipmentSet(setSelectedID)
        end
    end)

    local newBtn = CreateSetActionButton(setFrame, "New Set", btnWidth)
    newBtn:SetPoint("LEFT", saveBtn, "RIGHT", 4, 0)
    newBtn:SetScript("OnClick", function()
        StaticPopup_Show("PP_NEW_EQUIPMENT_SET")
    end)

    -- Scroll frame
    setScroll = CreateFrame("ScrollFrame", nil, setFrame)
    setScroll:SetPoint("TOPLEFT", saveBtn, "BOTTOMLEFT", -2, -4)
    setScroll:SetPoint("BOTTOMRIGHT", setFrame, "BOTTOMRIGHT", 0, 0)
    setScroll:EnableMouseWheel(true)

    setChild = CreateFrame("Frame", nil, setScroll)
    setChild:SetWidth(1)
    setChild:SetHeight(1)
    setScroll:SetScrollChild(setChild)

    setScroll:SetScript("OnSizeChanged", function(self, w)
        if w and w > 0 then
            setChild:SetWidth(w)
        end
    end)

    local scrollOffset = 0
    setScroll:SetScript("OnMouseWheel", function(self, delta)
        local maxScroll = math.max(setChild:GetHeight() - self:GetHeight(), 0)
        scrollOffset = math.max(0, math.min(scrollOffset - delta * SET_ROW_HEIGHT * 3, maxScroll))
        self:SetVerticalScroll(scrollOffset)
    end)
end

local function ShowSetList()
    if setFrame then
        setFrame:Show()
        local w = setScroll:GetWidth()
        if w and w > 0 then
            setChild:SetWidth(w)
        end
        RefreshSetList()
    end
end

local function HideSetList()
    if setFrame then
        setFrame:Hide()
    end
end

-- New set dialog
StaticPopupDialogs["PP_NEW_EQUIPMENT_SET"] = {
    text = "Enter a name for your new equipment set:",
    button1 = "Create",
    button2 = "Cancel",
    hasEditBox = true,
    editBoxWidth = 200,
    OnAccept = function(self)
        local editBox = self.editBox or self.EditBox
        if editBox then
            local name = strtrim(editBox:GetText())
            if name ~= "" then
                local icon = GetInventoryItemTexture("player", 1) or 134400
                C_EquipmentSet.CreateEquipmentSet(name, icon)
            end
        end
    end,
    EditBoxOnEnterPressed = function(editBox)
        local parent = editBox:GetParent()
        StaticPopupDialogs["PP_NEW_EQUIPMENT_SET"].OnAccept(parent)
        parent:Hide()
    end,
    EditBoxOnEscapePressed = function(editBox)
        editBox:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Rename set dialog
StaticPopupDialogs["PP_RENAME_EQUIPMENT_SET"] = {
    text = "Rename equipment set \"%s\":",
    button1 = "Save",
    button2 = "Cancel",
    hasEditBox = true,
    editBoxWidth = 200,
    OnShow = function(self, data)
        local editBox = self.editBox or self.EditBox
        if editBox and data and data.oldName then
            editBox:SetText(data.oldName)
            editBox:HighlightText()
        end
    end,
    OnAccept = function(self, data)
        local editBox = self.editBox or self.EditBox
        if editBox and data and data.setID then
            local newName = strtrim(editBox:GetText())
            if newName ~= "" then
                local _, _, iconID = C_EquipmentSet.GetEquipmentSetInfo(data.setID)
                C_EquipmentSet.ModifyEquipmentSet(data.setID, newName, iconID)
            end
        end
    end,
    EditBoxOnEnterPressed = function(editBox)
        local parent = editBox:GetParent()
        StaticPopupDialogs["PP_RENAME_EQUIPMENT_SET"].OnAccept(parent, parent.data)
        parent:Hide()
    end,
    EditBoxOnEscapePressed = function(editBox)
        editBox:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Delete confirmation dialog
StaticPopupDialogs["PP_DELETE_EQUIPMENT_SET"] = {
    text = "Delete equipment set \"%s\"?",
    button1 = "Delete",
    button2 = "Cancel",
    OnAccept = function(self, data)
        if data and data.setID then
            C_EquipmentSet.DeleteEquipmentSet(data.setID)
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}


--------------------------------------------------------------------------------
-- Custom title list
--------------------------------------------------------------------------------
local ROW_HEIGHT = 22
local ROW_GAP    = 1
local SEARCH_HEIGHT = 22

local titleFrame      -- container frame (holds search + scroll)
local titleScroll     -- ScrollFrame
local titleChild      -- scroll child
local titleSearchBox  -- EditBox
local titleCountLabel -- "N Titles" header text
local titleRows = {}  -- pool of row buttons
local titleData = {}  -- { {id=, name=}, ... } sorted, filtered
local pendingTitle    -- local override for instant highlight feedback
local RefreshTitleList -- forward declaration

local function CreateTitleRow(parent, index)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_HEIGHT)

    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetColorTexture(unpack(PP.CardBgColor))

    AddGoldBorder(row)

    row.label = row:CreateFontString(nil, "OVERLAY")
    row.label:SetFont(STANDARD_TEXT_FONT, 11)
    row.label:SetPoint("LEFT", 8, 0)
    row.label:SetPoint("RIGHT", -4, 0)
    row.label:SetJustifyH("LEFT")
    row.label:SetTextColor(0.85, 0.85, 0.85)
    row.label:SetWordWrap(false)

    row:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(0.14, 0.13, 0.10, 0.95)
        if not self.isActive then
            self.label:SetTextColor(1, 1, 1)
            ShowHoverBorder(self)
        end
    end)
    row:SetScript("OnLeave", function(self)
        if self.isActive then
            self.bg:SetColorTexture(0.18, 0.16, 0.10, 0.9)
            ShowGoldBorder(self)
        else
            self.bg:SetColorTexture(unpack(PP.CardBgColor))
            self.label:SetTextColor(0.85, 0.85, 0.85)
            HideGoldBorder(self)
        end
    end)
    row:SetScript("OnClick", function(self)
        pendingTitle = self.titleID
        PP.pendingTitleID = self.titleID
        SetCurrentTitle(self.titleID)
        RefreshTitleList()
        PP:FireEvent("PP_STATS_UPDATE")
        C_Timer.After(0.3, function()
            PP:FireEvent("PP_STATS_UPDATE")
        end)
    end)

    row:Hide()
    return row
end

RefreshTitleList = function()
    if not titleFrame then return end

    local searchText = titleSearchBox and titleSearchBox:GetText():lower() or ""
    local currentTitle = pendingTitle or GetCurrentTitle()

    -- Build filtered title list
    wipe(titleData)

    -- "No Title" entry (titleID 0)
    local noTitleName = "No Title"
    if searchText == "" or noTitleName:lower():find(searchText, 1, true) then
        table.insert(titleData, { id = 0, name = noTitleName })
    end

    local numTitles = GetNumTitles()
    for i = 1, numTitles do
        if IsTitleKnown(i) then
            local rawName = GetTitleName(i)
            if rawName then
                local name = rawName:gsub("%%s", ""):gsub("^%s+", ""):gsub("%s+$", "")
                if name ~= "" then
                    if searchText == "" or name:lower():find(searchText, 1, true) then
                        table.insert(titleData, { id = i, name = name })
                    end
                end
            end
        end
    end

    -- Sort alphabetically (keep "No Title" first)
    table.sort(titleData, function(a, b)
        if a.id == 0 then return true end
        if b.id == 0 then return false end
        return a.name:lower() < b.name:lower()
    end)

    -- Update count label
    local totalKnown = 0
    for i = 1, numTitles do
        if IsTitleKnown(i) then totalKnown = totalKnown + 1 end
    end
    if titleCountLabel then
        titleCountLabel:SetText(totalKnown .. " Titles")
    end

    -- Layout rows
    local panelWidth = titleChild:GetWidth()
    for idx, entry in ipairs(titleData) do
        local row = titleRows[idx]
        if not row then
            row = CreateTitleRow(titleChild, idx)
            titleRows[idx] = row
        end

        row:SetParent(titleChild)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -((idx - 1) * (ROW_HEIGHT + ROW_GAP)))
        row:SetPoint("RIGHT", titleChild, "RIGHT", 0, 0)
        row.titleID = entry.id
        row.label:SetText(entry.name)

        local isActive = (entry.id == currentTitle) or (entry.id == 0 and currentTitle == 0)
        row.isActive = isActive
        if isActive then
            row.label:SetTextColor(1, 0.84, 0)
            row.bg:SetColorTexture(0.18, 0.16, 0.10, 0.9)
            ShowGoldBorder(row)
        else
            row.label:SetTextColor(0.85, 0.85, 0.85)
            row.bg:SetColorTexture(unpack(PP.CardBgColor))
            HideGoldBorder(row)
        end

        row:Show()
    end

    -- Hide unused rows
    for i = #titleData + 1, #titleRows do
        titleRows[i]:Hide()
    end

    -- Update scroll child height
    local totalHeight = #titleData * (ROW_HEIGHT + ROW_GAP)
    titleChild:SetHeight(math.max(totalHeight, 1))
end

local function CreateTitleList(parent)
    titleFrame = CreateFrame("Frame", nil, parent)
    titleFrame:SetAllPoints()
    titleFrame:Hide()

    -- Count label
    titleCountLabel = titleFrame:CreateFontString(nil, "OVERLAY")
    titleCountLabel:SetFont(STANDARD_TEXT_FONT, 9)
    titleCountLabel:SetPoint("TOPLEFT", 4, -2)
    titleCountLabel:SetTextColor(0.50, 0.50, 0.50)
    titleCountLabel:SetText("")

    -- Search box
    titleSearchBox = CreateFrame("EditBox", nil, titleFrame, "InputBoxTemplate")
    titleSearchBox:SetHeight(SEARCH_HEIGHT)
    titleSearchBox:SetPoint("TOPLEFT", titleFrame, "TOPLEFT", 4, -14)
    titleSearchBox:SetPoint("TOPRIGHT", titleFrame, "TOPRIGHT", -4, -14)
    titleSearchBox:SetAutoFocus(false)
    titleSearchBox:SetFont(STANDARD_TEXT_FONT, 10, "")
    titleSearchBox:SetTextInsets(4, 4, 0, 0)

    titleSearchBox:SetScript("OnTextChanged", function()
        RefreshTitleList()
    end)
    titleSearchBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    titleSearchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)

    -- Scroll frame (manual, same pattern as stats.lua)
    titleScroll = CreateFrame("ScrollFrame", nil, titleFrame)
    titleScroll:SetPoint("TOPLEFT", titleSearchBox, "BOTTOMLEFT", -4, -4)
    titleScroll:SetPoint("BOTTOMRIGHT", titleFrame, "BOTTOMRIGHT", 0, 0)
    titleScroll:EnableMouseWheel(true)

    titleChild = CreateFrame("Frame", nil, titleScroll)
    titleChild:SetWidth(1)
    titleChild:SetHeight(1)
    titleScroll:SetScrollChild(titleChild)

    -- Update child width when scroll frame resizes
    titleScroll:SetScript("OnSizeChanged", function(self, w)
        if w and w > 0 then
            titleChild:SetWidth(w)
        end
    end)

    -- Mouse wheel scrolling
    local scrollOffset = 0
    titleScroll:SetScript("OnMouseWheel", function(self, delta)
        local maxScroll = math.max(titleChild:GetHeight() - self:GetHeight(), 0)
        scrollOffset = math.max(0, math.min(scrollOffset - delta * ROW_HEIGHT * 3, maxScroll))
        self:SetVerticalScroll(scrollOffset)
    end)
end

local function ShowTitleList()
    if titleFrame then
        pendingTitle = nil  -- reset on tab open so we read fresh from API
        PP.pendingTitleID = nil
        titleFrame:Show()
        -- Set child width now that parent has real dimensions
        local w = titleScroll:GetWidth()
        if w and w > 0 then
            titleChild:SetWidth(w)
        end
        RefreshTitleList()
    end
end

local function HideTitleList()
    if titleFrame then
        titleFrame:Hide()
    end
end

--------------------------------------------------------------------------------
-- Tab content visibility management
--------------------------------------------------------------------------------
PP:RegisterEvent("PP_TAB_CHANGED", function(event, tabID)
    -- Custom gear sets list
    if tabID == "gearsets" then
        ShowSetList()
    else
        HideSetList()
    end

    -- Custom title list
    if tabID == "titles" then
        ShowTitleList()
    else
        HideTitleList()
    end
end)

--------------------------------------------------------------------------------
-- Init
--------------------------------------------------------------------------------
PP:RegisterEvent("PP_FRAME_CREATED", function()
    CreateTabs()
    CreateTitleList(PP.MainFrame.statsPanel)
    CreateSetList(PP.MainFrame.statsPanel)
end)

-- Auto-refresh set list when equipment sets change
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("EQUIPMENT_SETS_CHANGED")
eventFrame:SetScript("OnEvent", function()
    if PP.activeTab == "gearsets" and setFrame and setFrame:IsShown() then
        RefreshSetList()
    end
end)
