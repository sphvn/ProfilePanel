-- ProfilePanel: 3D character model viewport with atmospheric lighting
local _, PP = ...

local model

local function CreateModel(parent)
    model = CreateFrame("DressUpModel", "ProfilePanelModel", parent)
    model:SetPoint("TOPLEFT", 0, 0)
    model:SetPoint("BOTTOMRIGHT", 0, 0)
    model:SetFrameLevel(parent:GetFrameLevel() + 1)

    -- Dark background base layer
    model.bg = model:CreateTexture(nil, "BACKGROUND", nil, -8)
    model.bg:SetAllPoints()
    model.bg:SetColorTexture(0.01, 0.01, 0.03, 0.95)

    -- Subtle vignette effect (darker edges, lighter center)
    -- Top gradient (dark → transparent)
    model.vigTop = model:CreateTexture(nil, "BACKGROUND", nil, -7)
    model.vigTop:SetPoint("TOPLEFT")
    model.vigTop:SetPoint("TOPRIGHT")
    model.vigTop:SetHeight(80)
    model.vigTop:SetGradient("VERTICAL", CreateColor(0.01, 0.01, 0.03, 0.0), CreateColor(0.01, 0.01, 0.03, 0.6))

    -- Bottom gradient (dark → transparent)
    model.vigBot = model:CreateTexture(nil, "BACKGROUND", nil, -7)
    model.vigBot:SetPoint("BOTTOMLEFT")
    model.vigBot:SetPoint("BOTTOMRIGHT")
    model.vigBot:SetHeight(60)
    model.vigBot:SetGradient("VERTICAL", CreateColor(0.01, 0.01, 0.03, 0.7), CreateColor(0.01, 0.01, 0.03, 0.0))

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
    if not model or type(model) ~= "table" or not model.SetUnit then return end

    local ok, err = pcall(function()
        model:SetUnit("player")
        model:SetFacing(-0.4)
        -- x = zoom (negative = further), y = left/right, z = up/down (negative = lower)
        model:SetPosition(-0.3, 0, -0.15)

        -- Atmospheric lighting: moody purple-blue ambient with warm directional light
        -- SetLight(enabled, omni, dirX, dirY, dirZ, ambIntensity, ambR, ambG, ambB, dirIntensity, dirR, dirG, dirB)
        model:SetLight(true, false, -0.5, 1, -0.5, 0.6, 0.10, 0.08, 0.18, 0.8, 0.7, 0.6, 0.9)
    end)
end

PP:RegisterEvent("PP_FRAME_CREATED", function()
    CreateModel(PP.MainFrame.modelArea)
end)

PP:RegisterEvent("PP_SHOW", function()
    UpdateModel()
end)
