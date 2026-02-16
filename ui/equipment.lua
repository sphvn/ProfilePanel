-- ProfilePanel: Equipment slot layout with item names, ilvl, enchants, and gem icons
-- Displays: [Icon] Item Name  ilvl
--                  Enchant Name  [gem][gem]
local _, PP = ...

local SLOT_SIZE   = 37
local SLOT_GAP    = 4
local GEM_SIZE    = 12
local slotFrames  = {}

-- Colors
local ENCHANT_COLOR   = { 0.16, 0.98, 0.71 }   -- mint green (CCS style)
local MISSING_COLOR   = { 1.00, 0.00, 0.00 }    -- red
local ILVL_FONT_SIZE  = 9
local NAME_FONT_SIZE  = 9
local ENCHANT_FONT_SIZE = 8

--------------------------------------------------------------------------------
-- Create rich overlay elements on a Blizzard slot button
-- "side" = "LEFT" or "RIGHT" (determines text anchor direction)
--------------------------------------------------------------------------------
local function CreateSlotOverlay(btn, slotID, side)
    if not btn then return end
    local overlay = {}
    overlay.slotID = slotID
    overlay.button = btn
    overlay.side   = side

    -- Container frame for text elements (overlays the model area)
    overlay.textFrame = CreateFrame("Frame", nil, btn:GetParent())
    overlay.textFrame:SetFrameLevel(btn:GetFrameLevel() + 5)
    overlay.textFrame:SetSize(200, SLOT_SIZE)

    if side == "LEFT" then
        overlay.textFrame:SetPoint("LEFT", btn, "RIGHT", 3, 0)
    else
        overlay.textFrame:SetPoint("RIGHT", btn, "LEFT", -3, 0)
    end

    -- Item level badge (on the slot button itself)
    overlay.ilvl = btn:CreateFontString(nil, "OVERLAY")
    overlay.ilvl:SetFont(STANDARD_TEXT_FONT, ILVL_FONT_SIZE, "OUTLINE")
    overlay.ilvl:SetPoint("BOTTOMRIGHT", 2, -2)
    overlay.ilvl:SetTextColor(1, 1, 1)

    -- Item name (quality-colored, next to slot)
    overlay.itemName = overlay.textFrame:CreateFontString(nil, "OVERLAY")
    overlay.itemName:SetFont(STANDARD_TEXT_FONT, NAME_FONT_SIZE, "OUTLINE")
    overlay.itemName:SetTextColor(1, 1, 1)
    overlay.itemName:SetWordWrap(false)

    if side == "LEFT" then
        overlay.itemName:SetPoint("TOPLEFT", overlay.textFrame, "TOPLEFT", 0, 0)
        overlay.itemName:SetPoint("RIGHT", overlay.textFrame, "RIGHT", 0, 0)
        overlay.itemName:SetJustifyH("LEFT")
    else
        overlay.itemName:SetPoint("TOPRIGHT", overlay.textFrame, "TOPRIGHT", 0, 0)
        overlay.itemName:SetPoint("LEFT", overlay.textFrame, "LEFT", 0, 0)
        overlay.itemName:SetJustifyH("RIGHT")
    end

    -- Enchant text (below name, green or red if missing)
    overlay.enchantText = overlay.textFrame:CreateFontString(nil, "OVERLAY")
    overlay.enchantText:SetFont(STANDARD_TEXT_FONT, ENCHANT_FONT_SIZE)
    overlay.enchantText:SetTextColor(unpack(ENCHANT_COLOR))
    overlay.enchantText:SetWordWrap(false)

    if side == "LEFT" then
        overlay.enchantText:SetPoint("TOPLEFT", overlay.itemName, "BOTTOMLEFT", 0, -1)
        overlay.enchantText:SetJustifyH("LEFT")
    else
        overlay.enchantText:SetPoint("TOPRIGHT", overlay.itemName, "BOTTOMRIGHT", 0, -1)
        overlay.enchantText:SetJustifyH("RIGHT")
    end

    -- Gem icons (up to 3, small squares next to enchant text)
    overlay.gems = {}
    for i = 1, 3 do
        local gem = overlay.textFrame:CreateTexture(nil, "OVERLAY")
        gem:SetSize(GEM_SIZE, GEM_SIZE)
        gem:Hide()
        overlay.gems[i] = gem
    end

    -- Warning dot (on the slot button, for at-a-glance missing indicator)
    overlay.warning = btn:CreateTexture(nil, "OVERLAY")
    overlay.warning:SetSize(10, 10)
    overlay.warning:SetPoint("TOPRIGHT", 2, 2)
    overlay.warning:SetAtlas("communities-icon-notification")
    overlay.warning:Hide()

    return overlay
end

--------------------------------------------------------------------------------
-- Position gem icons relative to enchant text
--------------------------------------------------------------------------------
local function LayoutGems(overlay, gemCount)
    if gemCount == 0 then return end

    local anchor
    if overlay.side == "LEFT" then
        anchor = { "LEFT", overlay.enchantText, "RIGHT", 3, 0 }
    else
        anchor = { "RIGHT", overlay.enchantText, "LEFT", -3, 0 }
    end

    for i = 1, gemCount do
        local gem = overlay.gems[i]
        if i == 1 then
            gem:SetPoint(anchor[1], anchor[2], anchor[3], anchor[4], anchor[5])
        else
            if overlay.side == "LEFT" then
                gem:SetPoint("LEFT", overlay.gems[i - 1], "RIGHT", 1, 0)
            else
                gem:SetPoint("RIGHT", overlay.gems[i - 1], "LEFT", -1, 0)
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Position slot buttons in our layout
--------------------------------------------------------------------------------
local function LayoutColumn(column, parent, anchorPoint, offsetX, side)
    for i, btnName in ipairs(column) do
        local btn = _G[btnName]
        if btn then
            local slotID = PP.SlotIDs[btnName]

            btn:SetParent(parent)
            btn:ClearAllPoints()

            local yOff = -((i - 1) * (SLOT_SIZE + SLOT_GAP))
            if anchorPoint == "TOPLEFT" then
                btn:SetPoint("TOPLEFT", parent, "TOPLEFT", offsetX, yOff)
            else
                btn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", offsetX, yOff)
            end

            btn:SetFrameLevel(parent:GetFrameLevel() + 10)

            local overlay = CreateSlotOverlay(btn, slotID, side)
            if overlay then
                slotFrames[btnName] = overlay
            end
        end
    end
end

local function LayoutWeapons(parent)
    local mh = _G["CharacterMainHandSlot"]
    local oh = _G["CharacterSecondaryHandSlot"]

    if mh then
        mh:SetParent(parent)
        mh:ClearAllPoints()
        mh:SetPoint("RIGHT", parent, "CENTER", -4, 0)
        mh:SetFrameLevel(parent:GetFrameLevel() + 10)
        local overlay = CreateSlotOverlay(mh, PP.SlotIDs["CharacterMainHandSlot"], "LEFT")
        if overlay then
            -- Reposition text for weapon: below the icon
            overlay.textFrame:ClearAllPoints()
            overlay.textFrame:SetPoint("TOP", mh, "BOTTOM", 0, -2)
            overlay.textFrame:SetSize(160, 30)
            overlay.itemName:ClearAllPoints()
            overlay.itemName:SetPoint("TOP", overlay.textFrame, "TOP", 0, 0)
            overlay.itemName:SetJustifyH("CENTER")
            overlay.enchantText:ClearAllPoints()
            overlay.enchantText:SetPoint("TOP", overlay.itemName, "BOTTOM", 0, -1)
            overlay.enchantText:SetJustifyH("CENTER")
            slotFrames["CharacterMainHandSlot"] = overlay
        end
    end

    if oh then
        oh:SetParent(parent)
        oh:ClearAllPoints()
        oh:SetPoint("LEFT", parent, "CENTER", 4, 0)
        oh:SetFrameLevel(parent:GetFrameLevel() + 10)
        local overlay = CreateSlotOverlay(oh, PP.SlotIDs["CharacterSecondaryHandSlot"], "RIGHT")
        if overlay then
            overlay.textFrame:ClearAllPoints()
            overlay.textFrame:SetPoint("TOP", oh, "BOTTOM", 0, -2)
            overlay.textFrame:SetSize(160, 30)
            overlay.itemName:ClearAllPoints()
            overlay.itemName:SetPoint("TOP", overlay.textFrame, "TOP", 0, 0)
            overlay.itemName:SetJustifyH("CENTER")
            overlay.enchantText:ClearAllPoints()
            overlay.enchantText:SetPoint("TOP", overlay.itemName, "BOTTOM", 0, -1)
            overlay.enchantText:SetJustifyH("CENTER")
            slotFrames["CharacterSecondaryHandSlot"] = overlay
        end
    end
end

--------------------------------------------------------------------------------
-- Update all slot info
--------------------------------------------------------------------------------
local function UpdateEquipment()
    for btnName, overlay in pairs(slotFrames) do
        local info = PP:GetSlotInfo(overlay.slotID)

        if info then
            -- Item level badge (on icon)
            overlay.ilvl:SetText(info.ilvl > 0 and info.ilvl or "")
            local r, g, b = GetItemQualityColor(info.quality or 1)
            overlay.ilvl:SetTextColor(r, g, b)

            -- Item name (quality-colored)
            overlay.itemName:SetText(info.name or "")
            overlay.itemName:SetTextColor(r, g, b)

            -- Enchant text
            if info.enchant and info.enchant ~= "" then
                overlay.enchantText:SetText(info.enchant)
                overlay.enchantText:SetTextColor(unpack(ENCHANT_COLOR))
            elseif info.missingEnchant then
                overlay.enchantText:SetText("Missing Enchant")
                overlay.enchantText:SetTextColor(unpack(MISSING_COLOR))
            else
                overlay.enchantText:SetText("")
            end

            -- Gem icons
            local gemCount = 0
            for i = 1, 3 do
                overlay.gems[i]:ClearAllPoints()
                overlay.gems[i]:Hide()
            end

            -- Determine expected gem count for this slot
            local expectedGems = 0
            local sid = overlay.slotID
            if sid == INVSLOT_HEAD or sid == INVSLOT_WRIST or sid == INVSLOT_WAIST then
                expectedGems = 1
            elseif sid == INVSLOT_NECK or sid == INVSLOT_FINGER1 or sid == INVSLOT_FINGER2 then
                expectedGems = 2
            end

            for i = 1, math.max(#info.gems, expectedGems) do
                if i > 3 then break end
                gemCount = gemCount + 1
                local gem = overlay.gems[i]

                if info.gems[i] then
                    -- Filled gem — show icon
                    local gemIcon = C_Item.GetItemIconByID(info.gems[i])
                    if gemIcon then
                        gem:SetTexture(gemIcon)
                        gem:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                    else
                        gem:SetColorTexture(0.3, 0.8, 0.3, 0.8)
                    end
                    gem:SetDesaturated(false)
                else
                    -- Empty socket — red indicator
                    gem:SetAtlas("communities-icon-notification")
                    gem:SetDesaturated(false)
                end
                gem:Show()
            end

            LayoutGems(overlay, gemCount)

            -- Warning dot
            if info.missingEnchant or info.missingGem then
                overlay.warning:Show()
            else
                overlay.warning:Hide()
            end

            overlay.textFrame:Show()
        else
            -- Empty slot
            overlay.ilvl:SetText("")
            overlay.itemName:SetText("")
            overlay.enchantText:SetText("")
            overlay.warning:Hide()
            overlay.textFrame:Hide()
            for i = 1, 3 do
                overlay.gems[i]:Hide()
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Init
--------------------------------------------------------------------------------
PP:RegisterEvent("PP_FRAME_CREATED", function()
    -- TEMPORARILY DISABLED: reparenting slot buttons causes anchor family errors
    -- The Blizzard slot buttons have internal child anchors that create cross-tree cycles
    -- TODO: Create our own item display frames instead of reparenting Blizzard buttons
    --[[
    local mf = PP.MainFrame
    LayoutColumn(PP.SlotLayout.LEFT,  mf.gearLeft,  "TOPLEFT",  0, "LEFT")
    LayoutColumn(PP.SlotLayout.RIGHT, mf.gearRight, "TOPRIGHT", 0, "RIGHT")
    LayoutWeapons(mf.weaponRow)
    ]]
end)

PP:RegisterEvent("PP_STATS_UPDATE", function()
    UpdateEquipment()
end)
