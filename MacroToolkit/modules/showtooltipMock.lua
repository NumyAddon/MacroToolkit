local MT = MacroToolkit

-- copied the update timing concept from SecureStateDriverManager
local UPDATE_THROTTLE = 0.2;
local timer = 0;

local TAB_CHAR = 2;
local TAB_ACCOUNT = 1;

MT.extendedMacroCache = MT.extendedMacroCache or {}
local function buildCache()
    local cache = MT.extendedMacroCache
    wipe(cache)
    for slot = 1, _G.MAX_ACCOUNT_MACROS + _G.MAX_CHARACTER_MACROS do
        local body = select(3, GetMacroInfo(slot))
        if body then
            local toolkitIndex = string.match(body, "MTSBP?(%d+)")
            if toolkitIndex then
                cache[slot] = toolkitIndex
            end
        end
    end
end
hooksecurefunc('CreateMacro', buildCache)
hooksecurefunc('EditMacro', buildCache)
hooksecurefunc('DeleteMacro', buildCache)

local function startsWithSlashCastCommand(body)
    local i, slashCommand = 1, _G["SLASH_CAST1"]
    while slashCommand do
        if string.match(body, "^" .. slashCommand .. " ") then
            return true
        end
        i = i + 1
        slashCommand = _G["SLASH_CAST" .. i]
    end
    return false
end

local function handleBody(body, slot)
    if not string.find(body, "^#showtooltip%s?\n") then return end

    local secondLine = string.match(body, "^#showtooltip%s?\n([^\n]*)")
    if not startsWithSlashCastCommand(secondLine) then return end

    local success, errorOrSpell, target = pcall(SecureCmdOptionParse, secondLine)
    if not success or not errorOrSpell then return end

    local firstLine = string.match(errorOrSpell, "^(.-)\n") or errorOrSpell
    local trimmed = string.match(firstLine, "^%s*(.-)%s*$")
    if trimmed == "" or not GetSpellInfo(trimmed) then return end

    SetMacroSpell(slot, trimmed, target)
end

local function OnUpdate(self, elapsed)
    timer = timer - elapsed;
    if ( timer <= 0 ) then
        timer = UPDATE_THROTTLE;

        local cache = MT.extendedMacroCache
        for slot, toolkitIndex in pairs(cache) do
            local tab = slot > _G.MAX_ACCOUNT_MACROS and TAB_CHAR or TAB_ACCOUNT
            local body = MT:GetExtendedBody(toolkitIndex, tab)
            if body then
                handleBody(body, slot)
            end
        end
    end
end

local function OnEvent(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        buildCache()
    end
    timer = 0;
end

local frame = CreateFrame("Frame");
frame:SetScript("OnUpdate", OnUpdate);
frame:SetScript("OnEvent", OnEvent);

frame:RegisterEvent("PLAYER_ENTERING_WORLD");

-- Events that trigger early rescans
frame:RegisterEvent("MODIFIER_STATE_CHANGED");
frame:RegisterEvent("ACTIONBAR_PAGE_CHANGED");
frame:RegisterEvent("UPDATE_BONUS_ACTIONBAR");
frame:RegisterEvent("PLAYER_ENTERING_WORLD");
frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM");
frame:RegisterEvent("UPDATE_STEALTH");
frame:RegisterEvent("PLAYER_TARGET_CHANGED");
frame:RegisterEvent("PLAYER_FOCUS_CHANGED");
frame:RegisterEvent("PLAYER_REGEN_DISABLED");
frame:RegisterEvent("PLAYER_REGEN_ENABLED");
frame:RegisterEvent("UNIT_PET");
frame:RegisterEvent("GROUP_ROSTER_UPDATE");
-- Deliberately ignoring mouseover and others' target changes because they change so much
