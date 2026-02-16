-- ProfilePanel: 3D character model viewport
local _, PP = ...

local model

local function CreateModel(parent)
    model = CreateFrame("DressUpModel", "ProfilePanelModel", parent)
    model:SetPoint("TOPLEFT", 2, -2)
    model:SetPoint("BOTTOMRIGHT", -2, 2)
    model:SetFrameLevel(parent:GetFrameLevel() + 1)

    -- Subtle dark background for the model viewport
    model.bg = model:CreateTexture(nil, "BACKGROUND")
    model.bg:SetAllPoints()
    model.bg:SetColorTexture(0.03, 0.03, 0.05, 0.60)

    -- Allow rotation via mouse drag
    model:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self.rotating = true
            self.rotateStart = GetCursorPosition()
        end
    end)

    model:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            self.rotating = false
        end
    end)

    model:SetScript("OnUpdate", function(self)
        if self.rotating then
            local x = GetCursorPosition()
            local diff = (x - (self.rotateStart or x)) * 0.01
            self.rotateStart = x
            local facing = self:GetFacing() or 0
            self:SetFacing(facing + diff)
        end
    end)

    model:EnableMouse(true)
end

local function UpdateModel()
    if not model then return end
    model:SetUnit("player")
    model:SetFacing(-0.4)
    model:SetPosition(0, 0, 0)
end

PP:RegisterEvent("PP_FRAME_CREATED", function()
    CreateModel(PP.MainFrame.modelArea)
end)

PP:RegisterEvent("PP_SHOW", function()
    UpdateModel()
end)
