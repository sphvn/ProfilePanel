-- ProfilePanel: Lightweight event registration and dispatch
local _, PP = ...

PP.RegisteredEvents = {}
PP.EventFrame = CreateFrame("Frame")

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------
function PP:RegisterEvent(event, handler, isBlizzard)
    self.RegisteredEvents[event] = self.RegisteredEvents[event] or {}
    table.insert(self.RegisteredEvents[event], handler)
    if isBlizzard then
        self.EventFrame:RegisterEvent(event)
    end
end

function PP:UnregisterEvent(event, handler)
    local handlers = self.RegisteredEvents[event]
    if not handlers then return end
    for i = #handlers, 1, -1 do
        if handlers[i] == handler then
            table.remove(handlers, i)
        end
    end
    if #handlers == 0 and self.EventFrame:IsEventRegistered(event) then
        self.EventFrame:UnregisterEvent(event)
    end
end

function PP:FireEvent(event, ...)
    local handlers = self.RegisteredEvents[event]
    if handlers then
        for _, fn in ipairs(handlers) do
            local ok, err = pcall(fn, event, ...)
            if not ok then
                -- Print error but don't break the handler chain
                print("|cffff4444ProfilePanel:|r Error in " .. tostring(event) .. ": " .. tostring(err))
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Central dispatcher
--------------------------------------------------------------------------------
PP.EventFrame:SetScript("OnEvent", function(_, event, ...)
    local handlers = PP.RegisteredEvents[event]
    if handlers then
        for _, fn in ipairs(handlers) do
            fn(event, ...)
        end
    end
end)

--------------------------------------------------------------------------------
-- Lifecycle events
--------------------------------------------------------------------------------
PP:RegisterEvent("ADDON_LOADED", function(_, addon)
    if addon ~= PP.addonName then return end
    ProfilePanelDB = ProfilePanelDB or {}
    PP.db = setmetatable(ProfilePanelDB, { __index = PP.defaults })
    PP:FireEvent("PP_INITIALIZED")
end, true)

PP:RegisterEvent("PLAYER_LOGIN", function()
    PP:FireEvent("PP_READY")
end, true)

--------------------------------------------------------------------------------
-- Stat / equipment update events → consolidated into PP_STATS_UPDATE
--------------------------------------------------------------------------------
local unitEvents = {
    UNIT_STATS = true,
    UNIT_ATTACK_POWER = true,
    UNIT_DAMAGE = true,
    UNIT_RANGEDDAMAGE = true,
}

local statEvents = {
    "UNIT_STATS",
    "COMBAT_RATING_UPDATE",
    "MASTERY_UPDATE",
    "SPEED_UPDATE",
    "LIFESTEAL_UPDATE",
    "AVOIDANCE_UPDATE",
    "PLAYER_EQUIPMENT_CHANGED",
    "PLAYER_AVG_ITEM_LEVEL_UPDATE",
    "UNIT_ATTACK_POWER",
    "UNIT_DAMAGE",
    "UNIT_RANGEDDAMAGE",
    "UPDATE_SHAPESHIFT_FORM",
    "PLAYER_ENTERING_WORLD",
}

for _, ev in ipairs(statEvents) do
    PP:RegisterEvent(ev, function(event, ...)
        if unitEvents[event] then
            local unit = ...
            if unit ~= "player" then return end
        end
        PP:FireEvent("PP_STATS_UPDATE")
    end, true)
end
