-- ProfilePanel: Custom equipment slot display (armory-style)
-- Fully custom frames — no Blizzard button reparenting.
-- Layout: [Icon] Item Name  ilvl
--                Enchant  [gem][gem]
-- Supports: drag-and-drop, shift-link, ctrl-preview, right-click gear menu
local _, PP = ...

local SLOT_SIZE   = 37
local SLOT_HEIGHT = 42
local SLOT_GAP    = 2
local GEM_SIZE    = 12
local TEXT_WIDTH  = 170
local WEAPON_TEXT_WIDTH = 140

-- Colors
local ENCHANT_COLOR     = { 0.16, 0.98, 0.71 }   -- mint green (CCS style)
local MISSING_COLOR     = { 1.00, 0.00, 0.00 }    -- red
local SOCKET_EMPTY_CLR  = { 0.45, 0.45, 0.50, 0.8 }
local SOCKET_SIZE       = 10
local ILVL_FONT_SIZE    = 9
local NAME_FONT_SIZE    = 9
local ENCHANT_FONT_SIZE = 8

local slotFrames = {}

--------------------------------------------------------------------------------
-- Inventory type → equipment slot mapping (for right-click gear menu)
--------------------------------------------------------------------------------
local SLOT_TO_INVTYPES = {
    [INVSLOT_HEAD]     = { "INVTYPE_HEAD" },
    [INVSLOT_NECK]     = { "INVTYPE_NECK" },
    [INVSLOT_SHOULDER] = { "INVTYPE_SHOULDER" },
    [INVSLOT_BACK]     = { "INVTYPE_CLOAK" },
    [INVSLOT_CHEST]    = { "INVTYPE_CHEST", "INVTYPE_ROBE" },
    [INVSLOT_BODY]     = { "INVTYPE_BODY" },
    [INVSLOT_TABARD]   = { "INVTYPE_TABARD" },
    [INVSLOT_WRIST]    = { "INVTYPE_WRIST" },
    [INVSLOT_HAND]     = { "INVTYPE_HAND" },
    [INVSLOT_WAIST]    = { "INVTYPE_WAIST" },
    [INVSLOT_LEGS]     = { "INVTYPE_LEGS" },
    [INVSLOT_FEET]     = { "INVTYPE_FEET" },
    [INVSLOT_FINGER1]  = { "INVTYPE_FINGER" },
    [INVSLOT_FINGER2]  = { "INVTYPE_FINGER" },
    [INVSLOT_TRINKET1] = { "INVTYPE_TRINKET" },
    [INVSLOT_TRINKET2] = { "INVTYPE_TRINKET" },
    [INVSLOT_MAINHAND] = { "INVTYPE_WEAPON", "INVTYPE_WEAPONMAINHAND", "INVTYPE_2HWEAPON" },
    [INVSLOT_OFFHAND]  = { "INVTYPE_WEAPON", "INVTYPE_WEAPONOFFHAND", "INVTYPE_SHIELD", "INVTYPE_HOLDABLE" },
}

--------------------------------------------------------------------------------
-- Scan bags for items matching a slot's valid invTypes
-- Returns table sorted by ilvl descending: { { bag, slot, link, name, ilvl, quality, icon }, ... }
--------------------------------------------------------------------------------
local function GetBagItemsForSlot(slotID)
    local validTypes = SLOT_TO_INVTYPES[slotID]
    if not validTypes then return {} end

    local validSet = {}
    for _, t in ipairs(validTypes) do
        validSet[t] = true
    end

    local results = {}
    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local containerInfo = C_Container.GetContainerItemInfo(bag, slot)
            if containerInfo and containerInfo.itemID then
                local _, _, _, invType = GetItemInfoInstant(containerInfo.itemID)
                if invType and validSet[invType] and IsEquippableItem(containerInfo.itemID) then
                    local itemLink = containerInfo.hyperlink
                    local itemName = containerInfo.itemName or ""
                    local itemQuality = containerInfo.quality or 1
                    local itemIcon = containerInfo.iconFileID
                    local itemLoc = ItemLocation:CreateFromBagAndSlot(bag, slot)
                    local ilvl = 0
                    if C_Item.DoesItemExist(itemLoc) then
                        ilvl = C_Item.GetCurrentItemLevel(itemLoc) or 0
                    end
                    table.insert(results, {
                        bag     = bag,
                        slot    = slot,
                        link    = itemLink,
                        name    = itemName,
                        ilvl    = ilvl,
                        quality = itemQuality,
                        icon    = itemIcon,
                    })
                end
            end
        end
    end

    table.sort(results, function(a, b) return a.ilvl > b.ilvl end)
    return results
end

--------------------------------------------------------------------------------
-- Right-click gear dropdown (context menu)
--------------------------------------------------------------------------------
local function ShowSlotDropdown(slotFrame)
    local items = GetBagItemsForSlot(slotFrame.slotID)
    local hasItem = GetInventoryItemLink("player", slotFrame.slotID) ~= nil

    if #items == 0 and not hasItem then return end

    MenuUtil.CreateContextMenu(slotFrame, function(ownerRegion, rootDescription)
        if #items > 0 then
            rootDescription:CreateTitle("Equip Item")
            for _, item in ipairs(items) do
                local r, g, b = GetItemQualityColor(item.quality or 1)
                local hex = string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
                local label = string.format("|T%s:14:14:0:0:64:64:4:60:4:60|t  |cff%s%s|r  |cff888888(%d)|r",
                    item.icon or "", hex, item.name, item.ilvl)
                rootDescription:CreateButton(label, function()
                    C_Container.PickupContainerItem(item.bag, item.slot)
                    EquipCursorItem(slotFrame.slotID)
                end)
            end
        end

        if hasItem then
            if #items > 0 then
                rootDescription:CreateDivider()
            end
            rootDescription:CreateButton("|cffff4444Unequip|r", function()
                PickupInventoryItem(slotFrame.slotID)
                -- Find first free bag slot and place the item there
                for bag = 0, 4 do
                    local numSlots = C_Container.GetContainerNumSlots(bag)
                    for slot = 1, numSlots do
                        local info = C_Container.GetContainerItemInfo(bag, slot)
                        if not info then
                            C_Container.PickupContainerItem(bag, slot)
                            return
                        end
                    end
                end
            end)
        end
    end)
end

--------------------------------------------------------------------------------
-- Shared click/drag handlers (added to both slot types)
--------------------------------------------------------------------------------
local function SetupInteraction(frame, tooltipAnchor)
    frame:RegisterForDrag("LeftButton")
    frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    frame:SetScript("OnDragStart", function(self)
        PickupInventoryItem(self.slotID)
    end)

    frame:SetScript("OnReceiveDrag", function(self)
        EquipCursorItem(self.slotID)
    end)

    frame:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            if IsModifiedClick("CHATLINK") then
                HandleModifiedItemClick(GetInventoryItemLink("player", self.slotID))
            elseif IsModifiedClick("DRESSUP") then
                DressUpItemLink(GetInventoryItemLink("player", self.slotID))
            elseif GetCursorInfo() then
                EquipCursorItem(self.slotID)
            else
                PickupInventoryItem(self.slotID)
            end
        elseif button == "RightButton" then
            ShowSlotDropdown(self)
        end
    end)

    frame:SetScript("OnEnter", function(self)
        -- Highlight icon on hover
        if self.highlight then
            self.highlight:Show()
        end
        -- Cursor feedback: show equip cursor when holding an item
        if GetCursorInfo() then
            SetCursor("EQUIPCURSOR")
        end
        GameTooltip:SetOwner(self, tooltipAnchor)
        GameTooltip:SetInventoryItem("player", self.slotID)
        GameTooltip:Show()
    end)

    frame:SetScript("OnLeave", function(self)
        if self.highlight then
            self.highlight:Hide()
        end
        ResetCursor()
        GameTooltip:Hide()
    end)
end

--------------------------------------------------------------------------------
-- Thin 1px border around icon (4 edge textures)
--------------------------------------------------------------------------------
local function CreateIconBorder(frame, anchor)
    local border = {}
    local edges = { "TOP", "BOTTOM", "LEFT", "RIGHT" }
    for _, edge in ipairs(edges) do
        local tex = frame:CreateTexture(nil, "OVERLAY")
        tex:SetColorTexture(0.3, 0.3, 0.3, 0.6)
        if edge == "TOP" then
            tex:SetPoint("TOPLEFT", anchor, "TOPLEFT", -1, 1)
            tex:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", 1, 1)
            tex:SetHeight(1)
        elseif edge == "BOTTOM" then
            tex:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", -1, -1)
            tex:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", 1, -1)
            tex:SetHeight(1)
        elseif edge == "LEFT" then
            tex:SetPoint("TOPLEFT", anchor, "TOPLEFT", -1, 1)
            tex:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", -1, -1)
            tex:SetWidth(1)
        else
            tex:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", 1, 1)
            tex:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", 1, -1)
            tex:SetWidth(1)
        end
        border[edge] = tex
    end
    return border
end

local function SetBorderColor(border, r, g, b, a)
    for _, tex in pairs(border) do
        tex:SetColorTexture(r, g, b, a or 0.8)
    end
end

--------------------------------------------------------------------------------
-- Create a hover highlight texture for an icon
--------------------------------------------------------------------------------
local function CreateHighlight(frame, anchor)
    local hl = frame:CreateTexture(nil, "HIGHLIGHT")
    hl:SetPoint("TOPLEFT", anchor, "TOPLEFT", -1, 1)
    hl:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", 1, -1)
    hl:SetColorTexture(1, 1, 1, 0.15)
    hl:Hide()
    return hl
end

--------------------------------------------------------------------------------
-- Create a small circle texture for missing gem sockets
--------------------------------------------------------------------------------
local function CreateEmptySocket(frame)
    local tex = frame:CreateTexture(nil, "OVERLAY")
    tex:SetSize(SOCKET_SIZE, SOCKET_SIZE)
    tex:SetAtlas("auctionhouse-icon-socket")
    tex:SetVertexColor(unpack(SOCKET_EMPTY_CLR))
    tex:Hide()
    return tex
end

--------------------------------------------------------------------------------
-- Create a single custom equipment slot frame
-- "side" = "LEFT" or "RIGHT" (determines icon/text anchor direction)
--------------------------------------------------------------------------------
local function CreateSlotFrame(parent, slotID, side)
    local frame = CreateFrame("Button", nil, parent)
    frame:SetSize(SLOT_SIZE + TEXT_WIDTH + 4, SLOT_HEIGHT)
    frame:SetFrameLevel(parent:GetFrameLevel() + 10)
    frame:EnableMouse(true)
    frame.slotID = slotID
    frame.side   = side

    -- Icon texture
    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetSize(SLOT_SIZE, SLOT_SIZE)

    -- Empty slot background (shown when no item equipped)
    frame.emptyBg = frame:CreateTexture(nil, "BACKGROUND")
    frame.emptyBg:SetSize(SLOT_SIZE, SLOT_SIZE)
    frame.emptyBg:SetColorTexture(0.08, 0.08, 0.12, 0.60)

    -- Line 1: Item name (quality-colored)
    frame.itemName = frame:CreateFontString(nil, "OVERLAY")
    frame.itemName:SetFont(STANDARD_TEXT_FONT, NAME_FONT_SIZE, "OUTLINE")
    frame.itemName:SetTextColor(1, 1, 1)
    frame.itemName:SetWordWrap(false)

    -- Line 2: Item level (below name)
    frame.ilvl = frame:CreateFontString(nil, "OVERLAY")
    frame.ilvl:SetFont(STANDARD_TEXT_FONT, ILVL_FONT_SIZE, "OUTLINE")
    frame.ilvl:SetTextColor(1, 1, 1)

    -- Line 3: Enchant text + gem icons (below ilvl)
    frame.enchantText = frame:CreateFontString(nil, "OVERLAY")
    frame.enchantText:SetFont(STANDARD_TEXT_FONT, ENCHANT_FONT_SIZE, "OUTLINE")
    frame.enchantText:SetTextColor(unpack(ENCHANT_COLOR))
    frame.enchantText:SetWordWrap(false)

    -- Gem icons (up to 3 — textures for filled, small circles for empty)
    frame.gems = {}
    for i = 1, 3 do
        local gem = frame:CreateTexture(nil, "OVERLAY")
        gem:SetSize(GEM_SIZE, GEM_SIZE)
        gem:Hide()
        frame.gems[i] = gem
    end
    frame.sockets = {}
    for i = 1, 3 do
        frame.sockets[i] = CreateEmptySocket(frame)
    end

    -- Anchor icon and text based on side
    if side == "LEFT" then
        frame.icon:SetPoint("LEFT", 0, 0)
        frame.emptyBg:SetPoint("CENTER", frame.icon, "CENTER", 0, 0)

        frame.itemName:SetPoint("TOPLEFT", frame.icon, "TOPRIGHT", 4, 0)
        frame.itemName:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
        frame.itemName:SetJustifyH("LEFT")

        frame.ilvl:SetPoint("TOPLEFT", frame.itemName, "BOTTOMLEFT", 0, -1)
        frame.ilvl:SetJustifyH("LEFT")

        frame.enchantText:SetPoint("TOPLEFT", frame.ilvl, "BOTTOMLEFT", 0, -1)
        frame.enchantText:SetJustifyH("LEFT")
    else
        frame.icon:SetPoint("RIGHT", 0, 0)
        frame.emptyBg:SetPoint("CENTER", frame.icon, "CENTER", 0, 0)

        frame.itemName:SetPoint("TOPRIGHT", frame.icon, "TOPLEFT", -4, 0)
        frame.itemName:SetPoint("LEFT", frame, "LEFT", 0, 0)
        frame.itemName:SetJustifyH("RIGHT")

        frame.ilvl:SetPoint("TOPRIGHT", frame.itemName, "BOTTOMRIGHT", 0, -1)
        frame.ilvl:SetJustifyH("RIGHT")

        frame.enchantText:SetPoint("TOPRIGHT", frame.ilvl, "BOTTOMRIGHT", 0, -1)
        frame.enchantText:SetJustifyH("RIGHT")
    end

    -- Thin 1px border around icon (quality-colored)
    frame.iconBorder = CreateIconBorder(frame, frame.icon)

    -- Hover highlight
    frame.highlight = CreateHighlight(frame, frame.icon)

    -- Interaction: drag-and-drop, click, tooltip
    local anchor = "ANCHOR_" .. (side == "LEFT" and "RIGHT" or "LEFT")
    SetupInteraction(frame, anchor)

    return frame
end

--------------------------------------------------------------------------------
-- Create a weapon slot frame (icon on top, text centered below)
--------------------------------------------------------------------------------
local function CreateWeaponFrame(parent, slotID)
    local frame = CreateFrame("Button", nil, parent)
    frame:SetSize(WEAPON_TEXT_WIDTH, SLOT_SIZE + 30)
    frame:SetFrameLevel(parent:GetFrameLevel() + 10)
    frame:EnableMouse(true)
    frame.slotID = slotID
    frame.side   = "WEAPON"

    -- Icon
    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetSize(SLOT_SIZE, SLOT_SIZE)
    frame.icon:SetPoint("TOP", 0, 0)

    -- Thin 1px border around icon (quality-colored)
    frame.iconBorder = CreateIconBorder(frame, frame.icon)

    -- Empty slot bg
    frame.emptyBg = frame:CreateTexture(nil, "BACKGROUND")
    frame.emptyBg:SetSize(SLOT_SIZE, SLOT_SIZE)
    frame.emptyBg:SetPoint("CENTER", frame.icon, "CENTER", 0, 0)
    frame.emptyBg:SetColorTexture(0.08, 0.08, 0.12, 0.60)

    -- Line 1: Item name (centered below icon)
    frame.itemName = frame:CreateFontString(nil, "OVERLAY")
    frame.itemName:SetFont(STANDARD_TEXT_FONT, NAME_FONT_SIZE, "OUTLINE")
    frame.itemName:SetPoint("TOP", frame.icon, "BOTTOM", 0, -2)
    frame.itemName:SetWidth(WEAPON_TEXT_WIDTH)
    frame.itemName:SetJustifyH("CENTER")
    frame.itemName:SetWordWrap(false)

    -- Line 2: Item level (centered below name)
    frame.ilvl = frame:CreateFontString(nil, "OVERLAY")
    frame.ilvl:SetFont(STANDARD_TEXT_FONT, ILVL_FONT_SIZE, "OUTLINE")
    frame.ilvl:SetPoint("TOP", frame.itemName, "BOTTOM", 0, -1)
    frame.ilvl:SetTextColor(1, 1, 1)

    -- Line 3: Enchant text (centered below ilvl)
    frame.enchantText = frame:CreateFontString(nil, "OVERLAY")
    frame.enchantText:SetFont(STANDARD_TEXT_FONT, ENCHANT_FONT_SIZE, "OUTLINE")
    frame.enchantText:SetPoint("TOP", frame.ilvl, "BOTTOM", 0, -1)
    frame.enchantText:SetJustifyH("CENTER")
    frame.enchantText:SetWordWrap(false)
    frame.enchantText:SetTextColor(unpack(ENCHANT_COLOR))

    -- Gem icons + empty socket circles
    frame.gems = {}
    for i = 1, 3 do
        local gem = frame:CreateTexture(nil, "OVERLAY")
        gem:SetSize(GEM_SIZE, GEM_SIZE)
        gem:Hide()
        frame.gems[i] = gem
    end
    frame.sockets = {}
    for i = 1, 3 do
        frame.sockets[i] = CreateEmptySocket(frame)
    end

    -- Hover highlight
    frame.highlight = CreateHighlight(frame, frame.icon)

    -- Interaction: drag-and-drop, click, tooltip
    SetupInteraction(frame, "ANCHOR_TOP")

    return frame
end

--------------------------------------------------------------------------------
-- Position gem icons / socket outlines relative to enchant text
-- Anchors each visible element at a fixed offset from enchant text
--------------------------------------------------------------------------------
local function LayoutGems(frame, totalCount)
    if totalCount == 0 then return end

    local isRight = (frame.side == "RIGHT")
    local spacing = GEM_SIZE + 2

    for i = 1, totalCount do
        local gem = frame.gems[i]
        local sock = frame.sockets[i]

        -- Clear both to prevent stale anchors
        gem:ClearAllPoints()
        sock:ClearAllPoints()

        -- Pick whichever element is visible
        local el = gem:IsShown() and gem or sock
        if not el:IsShown() then
            -- neither visible, skip
        elseif isRight then
            el:SetPoint("RIGHT", frame.enchantText, "LEFT", -3 - ((i - 1) * spacing), 0)
        else
            el:SetPoint("LEFT", frame.enchantText, "RIGHT", 3 + ((i - 1) * spacing), 0)
        end
    end
end

--------------------------------------------------------------------------------
-- Layout all slot frames on the model area
--------------------------------------------------------------------------------
local function LayoutSlots(modelArea)
    local padX, padY = 4, 4

    -- Left column (8 slots, top-left of model area)
    for i, btnName in ipairs(PP.SlotLayout.LEFT) do
        local slotID = PP.SlotIDs[btnName]
        local frame = CreateSlotFrame(modelArea, slotID, "LEFT")
        local yOff = -padY - ((i - 1) * (SLOT_HEIGHT + SLOT_GAP))
        frame:SetPoint("TOPLEFT", modelArea, "TOPLEFT", padX, yOff)
        slotFrames[btnName] = frame
    end

    -- Right column (8 slots, top-right of model area)
    for i, btnName in ipairs(PP.SlotLayout.RIGHT) do
        local slotID = PP.SlotIDs[btnName]
        local frame = CreateSlotFrame(modelArea, slotID, "RIGHT")
        local yOff = -padY - ((i - 1) * (SLOT_HEIGHT + SLOT_GAP))
        frame:SetPoint("TOPRIGHT", modelArea, "TOPRIGHT", -padX, yOff)
        slotFrames[btnName] = frame
    end

    -- Weapons (centered at bottom of model area)
    local mhFrame = CreateWeaponFrame(modelArea, PP.SlotIDs["CharacterMainHandSlot"])
    mhFrame:SetPoint("BOTTOMRIGHT", modelArea, "BOTTOM", -8, 4)
    slotFrames["CharacterMainHandSlot"] = mhFrame

    local ohFrame = CreateWeaponFrame(modelArea, PP.SlotIDs["CharacterSecondaryHandSlot"])
    ohFrame:SetPoint("BOTTOMLEFT", modelArea, "BOTTOM", 8, 4)
    slotFrames["CharacterSecondaryHandSlot"] = ohFrame
end

--------------------------------------------------------------------------------
-- Update all slot info
--------------------------------------------------------------------------------
local function UpdateEquipment()
    for btnName, frame in pairs(slotFrames) do
        local info = PP:GetSlotInfo(frame.slotID)

        -- Icon texture (always update, even for empty slots)
        local texture = GetInventoryItemTexture("player", frame.slotID)
        if texture then
            frame.icon:SetTexture(texture)
            frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            frame.icon:Show()
            frame.emptyBg:Hide()
        else
            frame.icon:SetTexture(nil)
            frame.emptyBg:Show()
        end

        if info then
            local r, g, b = GetItemQualityColor(info.quality or 1)

            -- Quality-colored thin icon border
            SetBorderColor(frame.iconBorder, r, g, b, 0.8)

            -- Item level badge
            frame.ilvl:SetText(info.ilvl > 0 and info.ilvl or "")
            frame.ilvl:SetTextColor(r, g, b)

            -- Item name
            frame.itemName:SetText(info.name or "")
            frame.itemName:SetTextColor(r, g, b)

            -- Enchant text
            if info.enchant and info.enchant ~= "" then
                frame.enchantText:SetText(info.enchant)
                frame.enchantText:SetTextColor(unpack(ENCHANT_COLOR))
            elseif info.missingEnchant then
                frame.enchantText:SetText("Missing Enchant")
                frame.enchantText:SetTextColor(unpack(MISSING_COLOR))
            else
                frame.enchantText:SetText("")
            end

            -- Reset all gem/socket visuals
            for i = 1, 3 do
                frame.gems[i]:ClearAllPoints()
                frame.gems[i]:Hide()
                frame.sockets[i]:ClearAllPoints()
                frame.sockets[i]:Hide()
            end

            -- Determine expected sockets for this slot
            local expectedGems = 0
            local sid = frame.slotID
            if sid == INVSLOT_HEAD or sid == INVSLOT_WRIST or sid == INVSLOT_WAIST then
                expectedGems = 1
            elseif sid == INVSLOT_NECK or sid == INVSLOT_FINGER1 or sid == INVSLOT_FINGER2 then
                expectedGems = 2
            end

            local totalSlots = math.max(#info.gems, expectedGems)

            for i = 1, totalSlots do
                if i > 3 then break end

                if info.gems[i] then
                    -- Filled gem: show icon texture
                    local gem = frame.gems[i]
                    local gemIcon = C_Item.GetItemIconByID(info.gems[i])
                    if gemIcon then
                        gem:SetTexture(gemIcon)
                        gem:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                    else
                        gem:SetColorTexture(0.3, 0.8, 0.3, 0.8)
                    end
                    gem:SetDesaturated(false)
                    gem:Show()
                else
                    -- Empty socket: show outline
                    frame.sockets[i]:Show()
                end
            end

            LayoutGems(frame, totalSlots)
        else
            -- Empty slot — clear all text and visuals
            SetBorderColor(frame.iconBorder, 0.3, 0.3, 0.3, 0.4)
            frame.ilvl:SetText("")
            frame.itemName:SetText("")
            frame.enchantText:SetText("")
            for i = 1, 3 do
                frame.gems[i]:Hide()
                frame.sockets[i]:Hide()
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Init
--------------------------------------------------------------------------------
PP:RegisterEvent("PP_FRAME_CREATED", function()
    local mf = PP.MainFrame
    if mf and mf.modelArea then
        LayoutSlots(mf.modelArea)
    end
end)

PP:RegisterEvent("PP_STATS_UPDATE", function()
    UpdateEquipment()
end)
