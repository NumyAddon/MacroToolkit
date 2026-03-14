local _G = _G
--- @class MacroToolkit
local MT = MacroToolkit
local L = MT.L
local format, gsub, lower, match = string.format, string.gsub, string.lower, string.match
local ipairs, pairs, tonumber, type = ipairs, pairs, tonumber, type
local GetLocale = GetLocale
local GetMacroInfo, GetNumMacros = GetMacroInfo, GetNumMacros
local GetNumSpellTabs = GetNumSpellTabs or (C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines)

local function trim(value)
    return match(value or "", "^%s*(.-)%s*$") or ""
end

local function getSpellInfoCompat(spellIDOrName)
    local numericSpellID = tonumber(spellIDOrName, 10)
    if C_Spell and C_Spell.GetSpellInfo then
        local spellInfo = C_Spell.GetSpellInfo(numericSpellID or spellIDOrName)
        if spellInfo then return spellInfo.name, spellInfo.spellID end
    end
    if _G.GetSpellInfo then
        local name, _, _, _, _, _, spellID = _G.GetSpellInfo(numericSpellID or spellIDOrName)
        if name then return name, spellID or numericSpellID end
    end
end

local function getSpellBookItemData(slot)
    if C_SpellBook and C_SpellBook.GetSpellBookItemInfo and Enum and Enum.SpellBookSpellBank then
        local info = C_SpellBook.GetSpellBookItemInfo(slot, Enum.SpellBookSpellBank.Player)
        if info then return info.itemType, info.spellID end
        return
    end
    if _G.GetSpellBookItemInfo then
        local spellType, spellID = _G.GetSpellBookItemInfo(slot, "spell")
        return spellType, spellID
    end
end

local function buildAliasSet(prefix)
    local aliases = {}
    for i = 1, 99 do
        local alias = _G[format("%s%d", prefix, i)]
        if not alias then break end
        aliases[lower(string.sub(alias, 2))] = true
    end
    return aliases
end

local CAST_ALIASES = buildAliasSet("SLASH_CAST")
local USE_ALIASES = buildAliasSet("SLASH_USE")
local CAST_SEQUENCE_ALIASES = buildAliasSet("SLASH_CASTSEQUENCE")
local CAST_RANDOM_ALIASES = buildAliasSet("SLASH_CASTRANDOM")
local USE_RANDOM_ALIASES = buildAliasSet("SLASH_USERANDOM")
local SHOW_ALIASES = {show = true}
local SHOW_TOOLTIP_ALIASES = {showtooltip = true}

for alias in pairs(USE_ALIASES) do
    CAST_ALIASES[alias] = true
end
for alias in pairs(USE_RANDOM_ALIASES) do
    CAST_RANDOM_ALIASES[alias] = true
end

local function getTranslationCommandType(command)
    command = lower(command or "")
    if CAST_SEQUENCE_ALIASES[command] then return "sequence" end
    if CAST_RANDOM_ALIASES[command] then return "random" end
    if CAST_ALIASES[command] then return "single" end
    if SHOW_ALIASES[command] or SHOW_TOOLTIP_ALIASES[command] then return "single" end
end

local function transformDelimited(text, delimiter, transformer)
    local output, index, changed = {}, 1, false
    while true do
        local delimiterStart = string.find(text, delimiter, index, true)
        local segment = delimiterStart and string.sub(text, index, delimiterStart - 1) or string.sub(text, index)
        local newSegment, segmentChanged = transformer(segment)
        output[#output + 1] = newSegment
        changed = changed or segmentChanged
        if not delimiterStart then break end
        output[#output + 1] = delimiter
        index = delimiterStart + #delimiter
    end
    return table.concat(output), changed
end

local function splitConditionPrefix(clause)
    local leadingWhitespace = match(clause, "^%s*") or ""
    local prefix = leadingWhitespace
    local remainder = string.sub(clause, #leadingWhitespace + 1)
    while string.sub(remainder, 1, 1) == "[" do
        local block = match(remainder, "^(%b[])")
        if not block then break end
        prefix = prefix .. block
        remainder = string.sub(remainder, #block + 1)
        local spaces = match(remainder, "^%s*") or ""
        prefix = prefix .. spaces
        remainder = string.sub(remainder, #spaces + 1)
    end
    return prefix, remainder
end

local function parseMacroLine(line)
    local leadingWhitespace = match(line, "^%s*") or ""
    local trimmedLine = string.sub(line, #leadingWhitespace + 1)
    local prefix = string.sub(trimmedLine, 1, 1)
    if prefix == "#" then
        local command, parameters = match(trimmedLine, "^(#%S+)%s*(.*)$")
        if command then return leadingWhitespace, command, parameters or "", getTranslationCommandType(string.sub(command, 2)) end
    elseif prefix == MT.slash then
        local command, parameters = match(trimmedLine, "^" .. MT.slash .. "(%S+)%s*(.*)$")
        if command then return leadingWhitespace, MT.slash .. command, parameters or "", getTranslationCommandType(command) end
    end
end

function MT:EnsureSpellTranslationStorage()
    if not self.db or not self.db.global then return end
    self.db.global.spellTranslations = self.db.global.spellTranslations or {}
end

function MT:SaveSpellTranslation(spellID, spellName, locale)
    spellID = tonumber(spellID)
    spellName = trim(spellName)
    locale = locale or GetLocale()
    if not spellID or spellName == "" then return false end
    self:EnsureSpellTranslationStorage()
    local key = tostring(spellID)
    local data = self.db.global.spellTranslations[key]
    if not data then
        data = {}
        self.db.global.spellTranslations[key] = data
    end
    if data[locale] == spellName then return false end
    data[locale] = spellName
    return true
end

function MT:GetSpellTranslationReverseIndex()
    self:EnsureSpellTranslationStorage()
    local reverseIndex = {}
    for spellID, locales in pairs(self.db.global.spellTranslations) do
        for locale, spellName in pairs(locales) do
            local key = lower(spellName)
            if key ~= "" and not reverseIndex[key] then
                reverseIndex[key] = {spellID = tonumber(spellID), locale = locale, name = spellName}
            end
        end
    end
    return reverseIndex
end

function MT:GetTranslatedSpellName(spellID, locale)
    spellID = tonumber(spellID)
    locale = locale or GetLocale()
    if not spellID then return end
    self:EnsureSpellTranslationStorage()
    local data = self.db.global.spellTranslations[tostring(spellID)]
    if data and data[locale] then return data[locale] end
    if locale == GetLocale() then
        local currentName = getSpellInfoCompat(spellID)
        if currentName then
            self:SaveSpellTranslation(spellID, currentName, locale)
            return currentName
        end
    end
end

function MT:CountSavedSpellTranslations()
    self:EnsureSpellTranslationStorage()
    local count = 0
    for spellID, locales in pairs(self.db.global.spellTranslations) do
        if tonumber(spellID) and type(locales) == "table" then
            count = count + 1
        end
    end
    return count
end

function MT:ResolveSpellToken(token, reverseIndex)
    local tokenName = trim(token)
    if tokenName == "" then return end
    local bangPrefix = ""
    if string.sub(tokenName, 1, 1) == "!" then
        bangPrefix = "!"
        tokenName = trim(string.sub(tokenName, 2))
    end
    if tokenName == "" then return end

    local currentName, spellID = getSpellInfoCompat(tokenName)
    if spellID then
        self:SaveSpellTranslation(spellID, currentName, GetLocale())
        return spellID, currentName, GetLocale(), bangPrefix
    end

    if reverseIndex then
        local entry = reverseIndex[lower(tokenName)]
        if entry then return entry.spellID, entry.name, entry.locale, bangPrefix end
    end
end

function MT:TransformSpellParameters(parameters, commandType, transformer)
    return transformDelimited(parameters or "", ";", function(clause)
        local prefix, action = splitConditionPrefix(clause)
        if action == "" then return clause, false end
        if commandType == "sequence" or commandType == "random" then
            local resetPrefix = ""
            local remainder = action
            if commandType == "sequence" then
                local foundResetPrefix, resetRemainder = match(action, "^(%s*reset%s*=%s*[^%s]+%s+)(.*)$")
                if foundResetPrefix then
                    resetPrefix = foundResetPrefix
                    remainder = resetRemainder
                end
            end
            local translatedRemainder, changed = transformDelimited(remainder, ",", transformer)
            return prefix .. resetPrefix .. translatedRemainder, changed
        end
        local translatedAction, changed = transformer(action)
        return prefix .. translatedAction, changed
    end)
end

function MT:CaptureMacroSpellTokens(macroBody, reverseIndex)
    if not macroBody or macroBody == "" then return 0 end
    reverseIndex = reverseIndex or self:GetSpellTranslationReverseIndex()
    local saved = 0
    for line in string.gmatch(macroBody .. "\n", "(.-)\n") do
        local _, _, parameters, commandType = parseMacroLine(line)
        if commandType then
            self:TransformSpellParameters(parameters, commandType, function(token)
                local spellID, spellName, locale, bangPrefix = self:ResolveSpellToken(token, reverseIndex)
                if not spellID then return token, false end
                local leadingWhitespace = match(token, "^%s*") or ""
                local trailingWhitespace = match(token, "%s*$") or ""
                local tokenName = trim(token)
                if bangPrefix == "!" then tokenName = trim(string.sub(tokenName, 2)) end
                if locale then saved = saved + (self:SaveSpellTranslation(spellID, tokenName, locale) and 1 or 0) end
                local currentName = self:GetTranslatedSpellName(spellID, GetLocale()) or spellName
                if currentName then saved = saved + (self:SaveSpellTranslation(spellID, currentName, GetLocale()) and 1 or 0) end
                return leadingWhitespace .. bangPrefix .. tokenName .. trailingWhitespace, false
            end)
        end
    end
    return saved
end

function MT:CollectMacroSpellIDs(macroBody, reverseIndex, spellIDs)
    if not macroBody or macroBody == "" then return spellIDs or {} end
    reverseIndex = reverseIndex or self:GetSpellTranslationReverseIndex()
    spellIDs = spellIDs or {}
    for line in string.gmatch(macroBody .. "\n", "(.-)\n") do
        local _, _, parameters, commandType = parseMacroLine(line)
        if commandType then
            self:TransformSpellParameters(parameters, commandType, function(token)
                local spellID = self:ResolveSpellToken(token, reverseIndex)
                if spellID then spellIDs[spellID] = true end
                return token, false
            end)
        end
    end
    return spellIDs
end

local function countKeys(source)
    local count = 0
    for _ in pairs(source or {}) do
        count = count + 1
    end
    return count
end

function MT:ScanSpellbookTranslations()
    local saved = 0
    local spellbookSpellIDs = {}

    if C_SpellBook and C_SpellBook.GetSpellBookItemInfo and Enum and Enum.SpellBookSpellBank then
        local slot = 1
        while true do
            local itemType, itemID = getSpellBookItemData(slot)
            if not itemType and not itemID then break end
            if itemType == Enum.SpellBookItemType.Spell then
                local spellID = itemID
                local spellName = spellID and getSpellInfoCompat(spellID)
                if spellID and spellName then
                    spellbookSpellIDs[spellID] = true
                    saved = saved + (self:SaveSpellTranslation(spellID, spellName, GetLocale()) and 1 or 0)
                end
            end
            slot = slot + 1
        end
        return saved, countKeys(spellbookSpellIDs)
    end

    if not GetNumSpellTabs then return 0, 0 end
    for tabIndex = 1, GetNumSpellTabs() do
        local name, _, offset, numSpells = _G.GetSpellTabInfo and _G.GetSpellTabInfo(tabIndex)
        if name then
            offset = (offset or 0) + 1
            for slot = offset, offset + (numSpells or 0) - 1 do
                local itemType, itemID = getSpellBookItemData(slot)
                if itemType == "SPELL" or itemType == "PETACTION" then
                    local spellID = itemID
                    local spellName = spellID and getSpellInfoCompat(spellID)
                    if spellID and spellName then
                        spellbookSpellIDs[spellID] = true
                        saved = saved + (self:SaveSpellTranslation(spellID, spellName, GetLocale()) and 1 or 0)
                    end
                end
            end
        end
    end
    return saved, countKeys(spellbookSpellIDs)
end

function MT:UpdateSavedTranslationsForCurrentLocale()
    self:EnsureSpellTranslationStorage()
    local updated = 0
    local locale = GetLocale()
    for spellID, locales in pairs(self.db.global.spellTranslations) do
        local numericSpellID = tonumber(spellID)
        if numericSpellID and type(locales) == "table" and not locales[locale] then
            local spellName = getSpellInfoCompat(numericSpellID)
            if spellName and self:SaveSpellTranslation(numericSpellID, spellName, locale) then
                updated = updated + 1
            end
        end
    end
    return updated
end

function MT:ScanSpellTranslations()
    if not self.db or not self.db.global then return {saved = 0, macroCount = 0, spellbookCount = 0, savedDataCount = 0} end
    self:EnsureSpellTranslationStorage()
    local saved, spellbookCount = self:ScanSpellbookTranslations()
    local reverseIndex = self:GetSpellTranslationReverseIndex()
    local seenBodies = {}
    local macroSpellIDs = {}

    local function scanBody(body)
        if body and body ~= "" and not seenBodies[body] then
            seenBodies[body] = true
            self:CollectMacroSpellIDs(body, reverseIndex, macroSpellIDs)
            saved = saved + self:CaptureMacroSpellTokens(body, reverseIndex)
        end
    end

    local numAccountMacros, numCharacterMacros = GetNumMacros()
    for macroIndex = 1, numAccountMacros + numCharacterMacros do
        local _, _, body = GetMacroInfo(macroIndex)
        scanBody(body)
    end

    for _, data in pairs(self.db.global.extended or {}) do
        scanBody(data.body)
    end
    for _, data in pairs(self.db.char.extended or {}) do
        scanBody(data.body)
    end
    for _, data in pairs(self.db.global.extra or {}) do
        scanBody(data.body)
    end

    local savedDataCount = self:UpdateSavedTranslationsForCurrentLocale()

    return {
        saved = saved,
        macroCount = countKeys(macroSpellIDs),
        spellbookCount = spellbookCount,
        savedDataCount = savedDataCount,
    }
end

function MT:TranslateMacro(macroBody, targetLocale)
    targetLocale = targetLocale or GetLocale()
    local reverseIndex = self:GetSpellTranslationReverseIndex()
    local changedTokens = 0
    local translatedLines = {}

    for line in string.gmatch((macroBody or "") .. "\n", "(.-)\n") do
        local leadingWhitespace, commandToken, parameters, commandType = parseMacroLine(line)
        if commandType then
            local translatedParameters, lineChanged = self:TransformSpellParameters(parameters, commandType, function(token)
                local spellID, _, _, bangPrefix = self:ResolveSpellToken(token, reverseIndex)
                if not spellID then return token, false end
                local targetName = self:GetTranslatedSpellName(spellID, targetLocale)
                if not targetName then return token, false end
                local leading = match(token, "^%s*") or ""
                local trailing = match(token, "%s*$") or ""
                local rawToken = trim(token)
                if bangPrefix == "!" then rawToken = trim(string.sub(rawToken, 2)) end
                if rawToken == targetName then return token, false end
                changedTokens = changedTokens + 1
                return leading .. bangPrefix .. targetName .. trailing, true
            end)
            local spacer = translatedParameters ~= "" and " " or ""
            translatedLines[#translatedLines + 1] = leadingWhitespace .. commandToken .. spacer .. translatedParameters
            if not lineChanged and parameters == "" then
                translatedLines[#translatedLines] = line
            end
        else
            translatedLines[#translatedLines + 1] = line
        end
    end

    return table.concat(translatedLines, "\n"), changedTokens
end

function MT:SetTranslationStatus(message, r, g, b)
    if not MacroToolkitTranslationStatus then return end
    MacroToolkitTranslationStatus:SetText(message or "")
    MacroToolkitTranslationStatus:SetTextColor(r or 0.75, g or 0.75, b or 0.75)
end

function MT:BuildSavedTranslationPreview()
    if not self.db or not self.db.global or not self.db.global.spellTranslations then return "" end
    local rows = {}
    for spellID, locales in pairs(self.db.global.spellTranslations) do
        if tonumber(spellID) and type(locales) == "table" then
            local localeNames = {}
            for locale, spellName in pairs(locales) do
                if type(spellName) == "string" and spellName ~= "" then
                    localeNames[#localeNames + 1] = format("%s=%s", locale, spellName)
                end
            end
            table.sort(localeNames)
            if #localeNames > 0 then
                rows[#rows + 1] = { id = tonumber(spellID), text = format("%s: %s", spellID, table.concat(localeNames, ", ")) }
            end
        end
    end
    table.sort(rows, function(a, b) return a.id < b.id end)
    for i, row in ipairs(rows) do
        rows[i] = row.text
    end
    return table.concat(rows, "\n")
end

function MT:UpdateSavedTranslationPreview()
    if not MacroToolkitSavedTranslationText then return end
    MacroToolkitSavedTranslationText:SetText(self:BuildSavedTranslationPreview())
end

function MT:UpdateTranslationWorkspace()
    if not MacroToolkitTranslationText then return end
    self:UpdateSavedTranslationPreview()
    local selectedMacro = MacroToolkitFrame and MacroToolkitFrame.selectedMacro
    local currentBody = MacroToolkitText and MacroToolkitText:GetText() or ""

    if self.translationPreviewFor ~= selectedMacro or self.translationPreviewSource ~= currentBody then
        MacroToolkitTranslationText:SetText("")
        self.translationPreviewFor = selectedMacro
        self.translationPreviewSource = currentBody
    end

    if not selectedMacro then
        MacroToolkitTranslateConvert:Disable()
        MacroToolkitTranslateOverwrite:Disable()
        MacroToolkitTranslateSave:Enable()
        self:SetTranslationStatus(L["Select a macro to translate"])
        return
    end

    MacroToolkitTranslateConvert:Enable()
    MacroToolkitTranslateSave:Enable()
    if trim(MacroToolkitTranslationText:GetText()) == "" then
        MacroToolkitTranslateOverwrite:Disable()
        self:SetTranslationStatus(L["Convert the selected macro to preview localized spell names"])
    else
        MacroToolkitTranslateOverwrite:Enable()
    end
end

function MT:SaveCurrentSpellTranslations()
    local result = self:ScanSpellTranslations()
    self:SetTranslationStatus(format(L["Saved %d macro spells, %d spellbook spells, and updated %d spells from saved data"], result.macroCount or 0, result.spellbookCount or 0, result.savedDataCount or 0), 0.45, 0.85, 0.45)
    self:UpdateSavedTranslationPreview()
end

function MT:ConvertSelectedMacroToCurrentLocale()
    if not MacroToolkitFrame or not MacroToolkitFrame.selectedMacro then return end
    self:ScanSpellTranslations()
    local body = MacroToolkitText:GetText() or ""
    local translatedBody, changedTokens = self:TranslateMacro(body, GetLocale())
    MacroToolkitTranslationText:SetText(translatedBody)
    self.translationPreviewFor = MacroToolkitFrame.selectedMacro
    self.translationPreviewSource = body
    if changedTokens > 0 then
        self:SetTranslationStatus(format(L["Translated %d spell references"], changedTokens), 0.45, 0.85, 0.45)
    else
        self:SetTranslationStatus(L["No stored spell translations matched this macro"])
    end
    self:UpdateTranslationWorkspace()
end

function MT:OverwriteSelectedMacroWithTranslation()
    if not MacroToolkitFrame or not MacroToolkitFrame.selectedMacro then return end
    local translatedBody = MacroToolkitTranslationText:GetText() or ""
    if trim(translatedBody) == "" then
        self:SetTranslationStatus(L["Convert a macro before overwriting it"], 0.85, 0.45, 0.45)
        return
    end
    MacroToolkitText:SetText(translatedBody)
    MacroToolkitFrame.textChanged = true
    self:SaveMacro()
    self:CaptureMacroSpellTokens(translatedBody)
    self.translationPreviewFor = MacroToolkitFrame.selectedMacro
    self.translationPreviewSource = translatedBody
    self:SetTranslationStatus(L["Overwrote the selected macro with translated spell names"], 0.45, 0.85, 0.45)
    self:UpdateSavedTranslationPreview()
    self:MacroFrameUpdate()
end
