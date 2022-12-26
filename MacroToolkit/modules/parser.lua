local MT = MacroToolkit
local string, table, ipairs, pairs, type, math = string, table, ipairs, pairs, type, math
local strsplit, select, wipe, tonumber, tostring = strsplit, select, wipe, tonumber, tostring
local GetSpellInfo, GetItemInfo = GetSpellInfo, GetItemInfo, IsHelpfulSpell, IsHarmfulSpell
local format = string.format
local _G = _G
local L = MT.L
MT.clist = {cast={}, script={}, click={}, console={}, target={}, castsequence={}, stopmacro={}}

local function trim(s) return string.match(s, "^%s*(.*%S)") or "" end
local function escape(s) return (s:gsub("[%-%.%+%[%]%(%)%$%^%%%?%*]","%%%1"):gsub("%z","%%z")) end

function MT:FindShortest(cglobal)
    local shortest = string.rep("x", 99)
    local current
    for c = 1, 99 do
        current = _G[format("%s%s", cglobal, c)]
        if current then if string.len(current) < string.len(shortest) then shortest = current end
        else break end
    end
    return shortest
end

function MT:BuildCommandList()
    local cglobal, command, shortest, digit, param, custom, dpos
    local castmax, modmax, randommax, usemax, modemax, usermax = 0, 0, 0, 0, 0, 0
    for k, v in pairs(_G) do
        if type(v) == "string" then
            if string.sub(k, 1, 6) == "SLASH_" then
                dpos = string.find(k, "%d+$") or 2
                digit = tonumber(string.match(k, "%d+$"))
                cglobal = string.sub(k, 1, dpos - 1)
                if cglobal == "SLASH_CASTSEQUENCE" then table.insert(MT.clist.castsequence, string.sub(v, 2)) end
                if cglobal == "SLASH_CAST" then
                    if castmax < digit then castmax = digit end
                    table.insert(MT.clist.cast, string.sub(v, 2))
                end
                if cglobal == "SLASH_CHAT_MODERATOR" then if modmax < digit then modmax = digit end end
                if cglobal == "SLASH_CASTRANDOM" then if randommax < digit then randommax = digit end end
                if cglobal == "SLASH_USE" then
                    if usemax < digit then usemax = digit end
                    table.insert(MT.clist.cast, string.sub(v, 2))
                end
                if cglobal == "SLASH_CHAT_MODERATE" then if modemax < digit then modemax = digit end end
                if cglobal == "SLASH_USERANDOM" then if usermax < digit then usermax = digit end end
                if cglobal == "SLASH_SCRIPT" then table.insert(MT.clist.script, string.sub(v, 2)) end
                if cglobal == "SLASH_CONSOLE" then table.insert(MT.clist.console, string.sub(v, 2)) end
                if cglobal == "SLASH_TARGET" then table.insert(MT.clist.target, string.sub(v, 2)) end
                if cglobal == "SLASH_CLICK" then table.insert(MT.clist.click, string.sub(v, 2)) end
                if cglobal == "SLASH_STOPMACRO" then table.insert(MT.clist.stopmacro, string.sub(v, 2)) end
            end
        end
    end
    for c = 1, usemax do _G[format("SLASH_CAST%d", castmax + c)] = _G[format("SLASH_USE%d", c)] end
    for m = 1, modemax do _G[format("SLASH_MODERATOR%d", modmax + m)] = _G[format("SLASH_MODERATE%d", m)] end
    for r = 1, usermax do _G[format("SLASH_CASTRANDOM%d", randommax + r)] = _G[format("SLASH_USERANDOM%d", r)] end
    for k, v in pairs(_G) do
        if type(v) == "string" then
            if string.sub(k, 1, 6) == "SLASH_" then
                if not string.find(k, "STOPWATCH_PARAM_") then
                    digit = string.find(k, "%d+$")
                    if not digit then digit = string.len(k) + 1 end
                    cglobal = string.sub(k, 1, digit - 1)
                    command = escape(string.sub(v, 2))
                    custom = nil
                    shortest = string.sub(MT:FindShortest(cglobal), 2)
                    param = MT.commandinfo[string.sub(cglobal, 7)] or 0
                    for _, c in ipairs(MT.db.global.custom) do if c.n == command then custom = 1 end end
                    MT.commands[command] = {shortest, param, nil, custom}
                end
            elseif string.find(k, "EMOTE%d+_CMD") then
                digit = string.find(k, "%d+$")
                if digit then
                    cglobal = string.sub(k, 1, digit - 1)
                    command = escape(string.sub(v, 2))
                    shortest = string.sub(MT:FindShortest(cglobal), 2)
                    param = MT.emoteinfo[tonumber(string.sub(string.find(cglobal, "%d+")))] or 0
                    MT.commands[command] = {shortest, param, 1}
                end
            end
        end
    end
end

--*************************************************
--* Damerau�Levenshtein Distance                  *
--* based on code from http://nayruden.com/?p=115 *
--*************************************************
local function getLevenshtein(s, t, lim)
    local slen, tlen = #s, #t
    if lim and math.abs(slen - tlen) >= lim then return lim end
    if type(s) == "string" then s = {string.byte(s, 1, slen)} end
    if type(t) == "string" then t = {string.byte(t, 1, tlen)} end
    local numcolumns = tlen + 1
    local d = {}
    for i = 0, slen do d[i * numcolumns] = i end
    for j = 0, tlen do d[j] = j end
    for i = 1, slen do
        local ipos = i * numcolumns
        local best = lim
        for j = 1, tlen do
            local addcost = (s[i] ~= t[j] and 1 or 0)
            local val = min(
                    d[ipos - numcolumns + j] + 1,
                    d[ipos + j - 1] + 1,
                    d[ipos - numcolumns + j - 1] + addcost)
            d[ipos + j] = val
            if i > 1 and j > 1 and s[i] == t[j - 1] and s[i - 1] == t[j] then
                d[ipos + j] = min(val, d[ipos - numcolumns - numcolumns + j - 2] + addcost)
            end
            if lim and val < best then best = val end
        end
        if lim and best >= lim then return lim end
    end
    return d[#d]
end

local function findMatch(source, values)
    local diff, bestmatch = 99, ""
    local d
    for k, v in pairs(values) do
        d = getLevenshtein(source, k)
        if d < diff then
            diff = d
            bestmatch = k
        end
    end
    return bestmatch
end

local function validateCommandVerb(commandtext, parameters)
    local param = string.len(trim(parameters or "")) > 0
    local c, cc = format("|c%s", MT.db.profile.defaultcolour), format("|c%s", MT.db.profile.commandcolour)
    local p = false
    local prefix = MT.slash

    commandtext = trim(commandtext)
    if commandtext == string.sub(_G.SLASH_SHOWTOOLTIP1, 2) or commandtext == string.sub(_G.SLASH_SHOW1, 2) then prefix = "#" end
    local msg = format("%s: %s%s%s", L["Invalid command"], prefix, cc, commandtext)
    --ticket 139
    if string.sub(commandtext, 1, 1) == MT.slash then
        msg = nil
    else
        for k, v in pairs(MT.commands) do
            if k == commandtext then
                if v[3] then cc = format("|c%s", MT.db.profile.emotecolour) end
                if v[2] == 5 then
                    msg = format("%s: %s%s%s", L["Command removed"], MT.slash, cc, commandtext)
                    p = true
                elseif v[2] == 1 then
                    if not param then
                        msg = format("%s: %s%s%s", L["Required parameter missing"], MT.slash, cc, commandtext)
                        p = true
                    else msg = nil end
                else msg = nil end
                break
            end
        end
    end
    for _, s in ipairs(MT.scripts) do
        if commandtext == s[2] then
            cc = format("|c%s", MT.db.profile.mtcolour)
            break
        end
    end
    for _, s in ipairs(MT.db.global.custom) do
        if commandtext == s.n then
            cc = format("|c%s", MT.db.profile.scriptcolour)
            break
        end
    end
    if IsSecureCmd('/'..commandtext) then
        msg = nil
    end
    if not msg then c = cc
    else
        msg = format("%s|r", msg)
        local matched = findMatch(commandtext, MT.commands)
        prefix = MT.slash
        if matched == string.sub(_G.SLASH_SHOWTOOLTIP1, 2) or matched == string.sub(_G.SLASH_SHOW1, 2) then prefix = "#" end
        if not p then msg = format("%s\n      %s: %s%s|r", msg, L["did you mean"], prefix, matched) end
    end
    return c, msg
end

local function isNumeric(args, withslash)
    local numeric = true
    local arg1
    for _, a in ipairs(args) do
        --handle / in numeric arguments
        if withslash then
            if string.sub(a, string.len(a) - 1, 1) ~= "/" then a = string.gsub(a, "/", "") end
        end
        if not tonumber(trim(a)) then
            numeric = nil
            arg1 = a
            break
        end
    end
    return numeric, arg1
end

local function isAlphaNumeric(args, customPattern)
    local alpha, arg1
    local pattern = customPattern or "%w+"
    for _, a in ipairs(args) do
        local s, e = string.find(a, pattern)
        alpha = (s == 1 and e == string.len(a))
        if not alpha then
            arg1 = a
            break
        end
    end
    return alpha, arg1
end

local function isValid(args, opt)
    local valid, arg1
    for _, a in ipairs(args) do
        valid = nil
        if opt == 5 then -- strip out colons and spaces for mod combinations
            a = string.gsub(a, ":", "")
            a = string.gsub(a, " ", "")
        end
        for _, o in ipairs(MT.optargs[opt]) do
            if type(a) == "string" then a = string.lower(a) end
            if o == trim(a) then
                valid = true
                break
            end
        end
        if not valid then
            arg1 = a
            break
        end
    end
    return valid, arg1
end

local function isCast(command) for _, c in ipairs(MT.clist.cast) do if c == command then return true end end end
local function isScript(command) for _, c in ipairs(MT.clist.script) do if c == command then return true end end end
local function isClick(command) for _, c in ipairs(MT.clist.click) do if c == command then return true end end end
local function isConsole(command) for _, c in ipairs(MT.clist.console) do if c == command then return true end end end
local function isTarget(command) for _, c in ipairs(MT.clist.target) do if c == command then return true end end end
local function isCastSequence(command) for _, c in ipairs(MT.clist.castsequence) do if c == command then return true end end end

function MT:IsCast(command) return isCast(command) end
function MT:IsStopMacro(command) for _, c in ipairs(MT.clist.stopmacro) do if c == command then return true end end end
function MT:IsTarget(command) return isTarget(command) end
function MT:IsCastSequence(command) return isCastSequence(command) end

local function validateParameters(parameters, commandtext)
    local c = format("|c%s", MT.db.profile.stringcolour)
    local err
    parameters = trim(parameters)
    commandtext = trim(commandtext)
    if string.sub(parameters, 1, 1) == "!" then parameters = string.sub(parameters, 2) end
    if isScript(commandtext) or  isConsole(commandtext) or isClick(commandtext) then c = format("|c%s", MT.db.profile.scriptcolour)
    elseif isTarget(commandtext) then c = format("|c%s", MT.db.profile.targetcolour)
    elseif GetSpellInfo(parameters) then c = format("|c%s", MT.db.profile.spellcolour)
    elseif GetItemInfo(parameters) then c = format("|c%s", MT.db.profile.itemcolour)
    elseif isNumeric({parameters}) then c = format("|c%s", MT.db.profile.stringcolour)
    elseif MT.db.profile.unknown then err = format("%s: |c%s%s|r", L["Unknown parameter"], MT.db.profile.stringcolour, parameters) end
    return c, err
end

local function parseSequence(parameters)
    local reset, cs = "", ""
    local c = format("|c%s", MT.db.profile.stringcolour)
    local s, e, rw, res = string.find(parameters, "(reset%s*=%s*)(.*)")
    local err, err2, rwhole, parok
    local rpars = {"target", "combat", "ctrl", "shift", "alt"}
    if s then
        local s1, e1 = string.find(res, " ")
        if s1 then
            reset = string.sub(res, 1, s1 - 1)
            rwhole = format("%s%s", rw, reset)
            cs = trim(string.sub(res, s1))
        else
            reset = res
            rwhole = string.sub(parameters, s, e)
        end
        if reset == "" then err = format("%s: reset", L["Required parameter missing"])
        else
            local rp = {strsplit("/", reset)}
            for _, p in ipairs(rp) do
                if not isNumeric({p}) then
                    --ticket 85
                    for _, rp in ipairs(rpars) do
                        if p == rp then
                            parok = true
                            break
                        end
                    end
                    if not parok then
                        err = format("%s: reset=|c%s%s|r", L["Unknown parameter"], MT.db.profile.stringcolour, p)
                        break
                    else parok = false end
                end
            end
        end
    else cs = parameters end

    --0 is no longer accepted as a valid slot as of 6.0.2
    s, e, rw = string.find(cs, "0%s*,")
    if s then err2 = format("%s: |c%s0|r", L["Invalid argument"], MT.db.profile.stringcolour) end

    if not err then c = format("|c%s", MT.db.profile.seqcolour) end
    return err, reset, cs, c, rwhole, err2
end

local function validateCondition(condition, optionArguments, parameters)
    local color, conditionColor, isCondition = format("|c%s", MT.db.profile.defaultcolour), format("|c%s", MT.db.profile.conditioncolour), true
    local msg = format("%s: %s%s", L["Invalid condition"], conditionColor, condition)
    local target, noa, valid, arg1, no
    local colorArguments = false

    if string.len(condition) == 0 then return "", nil end
    if string.sub(condition, 1, 2) == "no" then
        condition = string.sub(condition,3)
        no = true
    end
    local s, e = string.find(condition, "target%s-=")
    if not s then s, e = string.find(condition, "@") end
    if s then
        if e then target = string.sub(condition, e + 1) end
        if not target then
            msg = L["Invalid target"]
            isCondition = false
        elseif string.find(trim(target),"[%p%s%c]") then
            msg = format("%s: |c%s%s", L["Invalid target"], MT.db.profile.targetcolour, trim(target))
            isCondition = false
        else msg = nil end
    else
        local k = condition
        local v = MT.conditions[k] or nil
        if v then
            if v > 0 and k ~= "group" and k ~= "mod" and k ~= "modifier" and k~= "pet" and (not no) then
                if #optionArguments == 0 then
                    msg = format("%s: %s%s", L["Argument not optional"], conditionColor, condition)
                    noa = true
                    isCondition = false
                end
            end
            if #optionArguments > 0 then
                if v == 0 then
                    msg = format("%s: %s%s", L["Invalid argument"], conditionColor, condition)
                    isCondition = false
                elseif v == 1 then --validate numeric
                    valid, arg1 = isNumeric(optionArguments)
                    if not valid then
                        msg = format("%s: %s%s|r - %s", L["Arguments must be numeric"], conditionColor, condition, arg1)
                        isCondition = false
                    else msg = nil end
                elseif v == 2 then --validate text
                    if isNumeric(optionArguments) then
                        msg = format("%s: %s%s", L["Arguments must not be numeric"], conditionColor, condition)
                        isCondition = false
                    else msg = nil end
                elseif v == 3 then --validate alphanumeric
                    valid, arg1 = isAlphaNumeric(optionArguments)
                    if not valid then
                        msg = format("%s: %s%s|r - %s", L["Arguments must be alphanumeric"], conditionColor, condition, arg1)
                        isCondition = false
                    else msg = nil end
                elseif v > 3 and v < 7 then --validate group
                    valid, arg1 = isValid(optionArguments, v)
                    if not valid then
                        msg = format("%s: %s%s|r - %s", L["Invalid argument"], conditionColor, condition, arg1)
                        isCondition = false
                    else msg = nil end
                elseif v == 7 then
                    valid, arg1 = isNumeric(optionArguments, true)
                    if not valid then
                        msg = format("%s: %s%s|r - %s", L["Arguments must be numeric"], conditionColor, condition, arg1)
                        isCondition = false
                    else msg = nil end
                elseif v == 8 then --validate alphanumeric + spaces
                    valid, arg1 = isAlphaNumeric(optionArguments, "[%w ]+")
                    if not valid then
                        msg = format("%s: %s%s|r - %s", L["Arguments must be alphanumeric"], conditionColor, condition, arg1)
                        isCondition = false
                    else msg = nil end
                end
            elseif not noa then msg = nil end
        end
    end
    if not msg then
        color = conditionColor
        if condition == 'known' and optionArguments and optionArguments[1] then
            local name, _ = GetSpellInfo(optionArguments[1])
            if not name then
                msg = format("%s: [%s%s|r:%s] - %s", L["Invalid condition"], conditionColor, condition, optionArguments[1], "Unknown spell")
                isCondition = false
            elseif name:lower() ~= parameters:lower() and optionArguments[1]:lower() ~= parameters:lower() then
                local spellID = select(7, GetSpellInfo(parameters))
                msg = format(
                    "Known spell mismatch: [%s%s|r:%s (%s)]\n       %s%s",
                    conditionColor,
                    condition,
                    optionArguments[1],
                    name,
                    parameters,
                    spellID and format(" (%s)", spellID) or ""
                )
                isCondition = false
            end
            if name then
                colorArguments = format("|c%s", MT.db.profile.spellcolour)
            end
        end
    else
        msg = format("%s|r", msg)
        if isCondition then
            msg = format("%s\n      %s: %s%s%s|r", msg, L["did you mean"], conditionColor, no and "no" or "", findMatch(condition, MT.conditions))
        end
    end
    return color, msg, colorArguments
end

local function replace(original, replacetext, replacewith, start)
    if replacetext == "" then return original, 0 end
    local s, e = string.find(replacewith, "target%s-=")
    start = start - 1
    if s then e = s + 5 end
    if s and not string.find(replacewith, format("|c%s", MT.db.profile.defaultcolour)) then
        local rw = format("%starget|r", string.sub(replacewith, 1, s - 1))
        local s2, e2 = string.find(replacewith, "%s?=%s*", s)
        replacewith = format("%s%s|c%s%s|r", rw, string.sub(replacewith, s2, e2), MT.db.profile.targetcolour, string.sub(replacewith, e2 + 1))
    end
    s, e = string.find(replacewith, "@")
    if s and not string.find(replacewith, format("|c%s", MT.db.profile.defaultcolour)) then
        replacewith = format("%s|c%s%s|r", string.sub(replacewith, 1, s), MT.db.profile.targetcolour, string.sub(replacewith, e + 1))
    end
    s, e = string.find(original, escape(replacetext), start)
    local rout = ""
    if s then rout = format("%s%s%s", string.sub(original, 1, s - 1), replacewith, string.sub(original, e + 1)) end
    return rout
end

function MT:Decolourise(macrotext)
    macrotext = string.gsub(macrotext, "|cff%x%x%x%x%x%x", "")
    macrotext = string.gsub(macrotext, "|r", "")
    return macrotext
end

local function matchedBrackets(macrotext)
    local _, leftbracket = string.gsub(macrotext, "%[", "")
    local _, rightbracket = string.gsub(macrotext, "%]", "")
    local _, leftbrace = string.gsub(macrotext, "%(", "")
    local _, rightbrace = string.gsub(macrotext, "%)", "")
    local _, leftcb = string.gsub(macrotext, "{", "")
    local _, rightcb = string.gsub(macrotext, "}", "")
    local _, quotes = string.gsub(macrotext, "\"", "")
    local mtype = ""
    if leftbracket - rightbracket ~= 0 then mtype = "[ ]" end
    if leftbrace - rightbrace ~= 0 then mtype = format("%s ( )", mtype) end
    if leftcb - rightcb ~= 0 then mtype = format("%s { }", mtype) end
    if quotes % 2 ~= 0 then mtype = format("%s \" \"", mtype) end
    return mtype
end

local function removeConditional(line, pattern, conditionalPattern)
    local s, e = string.find(line, pattern)
    while s do
        local s1, e1 = string.find(line, conditionalPattern, s)
        if not s1 or not e1 then break end -- shouldn't happen, but don't want to throw an error if it does
        if string.match(string.sub(line,s1,s1), '[^,]') then s1 = s1 - 1 end

        line = format("%s%s", string.sub(line, 1, s1), string.sub(line, e1 + 1))
        s, e = string.find(line, pattern)
    end
    return line
end

function MT:ShortenMacro(macrotext)
    if string.len(macrotext) == 0 then return end
    local olen = 0
    local mout = {}
    local show, showt, firstc, shows, s2
    local pattern
    olen = string.len(macrotext)
    macrotext = format("%s\n", macrotext)
    local lines = {strsplit("\n", macrotext)}
    for i, line in ipairs(lines) do
        --if i == 3 then print(l) return end
        local s, e = string.find(line, format("%s%s", MT.slash, MT.slash))
        if s then
            if s == 1 then
                line = ""
            else
                line = string.sub(line, 1, s - 1)
            end
        end
        if line ~= "" then
            line = string.gsub(line, "%s+", " ")
            line = string.gsub(line, "%s-([%]=,;])", "%1")
            line = string.gsub(line, "([%[%]=;])%s+", "%1")
            line = string.gsub(line, "%[(%w),%s+(%w)%]", "%1%2")
            line = string.gsub(line, "%s-/%s+", "/")
            line = string.gsub(line, "%s-;$", "")
            line = string.gsub(line, "target=", "@")
            line = string.gsub(line, "modifier%s-", "mod")
            line = string.gsub(line, "mod%s-:%s+", "mod:")
            line = string.gsub(line, "group%s-:%s+", "group:")
            line = string.gsub(line, "(known:[%w ])%s+", "%1")

            local knownConditionals = {}
            s, e = string.find(line, "%[.-%]")
            while s do -- for each bracketed section, strip spaces and extract known conditionals
                local s1 = string.sub(line, s, e)
                local kStart, kEnd = string.find(s1, "known:[%w ]+")
                if kStart then
                    local known = kStart and string.sub(s1, kStart, kEnd)
                    if known then
                        knownConditionals[string.gsub(known, "%s+", "")] = known
                    end
                end
                s1 = string.gsub(s1, "%s+", "")
                line = format("%s%s%s", string.sub(line, 1, s - 1), s1, string.sub(line, e + 1))
                s, e = string.find(line, "%[.-%]", e + 1)
            end

            for k, v in pairs(knownConditionals) do
                local spellNameOrID = string.gsub(v, "known:", "")
                -- if not a number
                if not tonumber(spellNameOrID) then
                    local spellInfo = { GetSpellInfo(spellNameOrID) }
                    local spellName, spellID = spellInfo[1], spellInfo[7]
                    if spellID and string.len(spellID) < string.len(spellName) then v = format("known:%d", spellID) end
                end
                line = string.gsub(line, k, v)
            end

            local existsConditionPattern = ",-%s-exists,*"

            line = removeConditional(line, "%[.-[^o]help.-[^o]exists.-%]", existsConditionPattern) -- help & exists
            line = removeConditional(line, "%[help.-[^o]exists.-%]", existsConditionPattern) -- help & exists
            line = removeConditional(line, "%[.-,-[^o]exists.-[^o]help.-%]", existsConditionPattern) -- exists & help
            line = removeConditional(line, "%[exists.-[^o]help.-%]", existsConditionPattern) -- exists & help
            line = removeConditional(line, "%[.-[^o]harm.-[^o]exists.-%]", existsConditionPattern) -- harm & exists
            line = removeConditional(line, "%[harm.-[^o]exists.-%]", existsConditionPattern) -- harm & exists
            line = removeConditional(line, "%[.-,-[^o]exists.-[^o]harm.-%]", existsConditionPattern) -- exists & harm
            line = removeConditional(line, "%[exists.-[^o]harm.-%]", existsConditionPattern) -- exists & harm

            local noHarmConditionPattern = ",-%s-noharm,*"
            local noHelpConditionPattern = ",-%s-nohelp,*"

            line = removeConditional(line, "%[.-nohelp.-noexists.-%]", noHelpConditionPattern) -- nohelp & noexists
            line = removeConditional(line, "%[.-,-noexists.-nohelp.-%]", noHelpConditionPattern) -- noexists & nohelp
            line = removeConditional(line, "%[.-noharm.-noexists.-%]", noHarmConditionPattern) -- noharm & noexists
            line = removeConditional(line, "%[.-,-noexists.-noharm.-%]", noHarmConditionPattern) -- noexists & noharm

            -- "noexists" & "help"/"harm" makes no logical sense, since it can never match, maybe show an error?
            -- "help"/"harm" imply "exists", so combining it with "noexists" makes no sense

            -- cleanup trailing comma in [ ] blocks
            pattern = "(%[.-),%s-(%])"
            line = string.gsub(line, pattern, "%1%2")

            --avoid confusion between actionbar condition and swapactionbar / command
            local s1
            s, e, s1 = string.find(line, "(%[.*)actionbar%s-")
            if s then line = format("%s%s%s%s", string.sub(line, 1, s - 1), s1, "bar", string.sub(line, e + 1)) end
            line = string.gsub(line, "bar%s-:%s+", "bar:")
            line = string.gsub(line, "button%s-", "btn")
            line = string.gsub(line, "btn%s-:%s+", "btn:")
            line = string.gsub(line, "equipped%s-", "worn")
            line = string.gsub(line, "worn%s-:%s+", "worn:")
            line = string.gsub(line, "stance%s-", "form")
            line = string.gsub(line, "form%s-:%s+", "form:")
            s, e, s1, s2 = string.find(line, "%](%a.-);(.-)$")
            if s then if s1 == s2 then line = format("%s[]%s", string.sub(line, 1, s), s1) end end
            s, e = string.find(line, _G.SLASH_SHOWTOOLTIP1)
            if s then showt = i
            else
                s, e = string.find(line, _G.SLASH_SHOW1)
                if s then show = i end
            end
            local _, _, command, parameters = MT:ParseMacro(line)
            if command == string.sub(_G.SLASH_SHOW1, 2) or command == string.sub(_G.SLASH_SHOWTOOLTIP1, 2) then
                if not shows then shows = parameters end
            elseif isCast(command) then if not firstc then firstc = parameters end
            elseif isScript(command) then
                if not string.find(line, "DEFAULT_CHAT_FRAME:AddMessage%(.-,%s-[%d,]%)") then line = string.gsub(line, "DEFAULT_CHAT_FRAME:AddMessage", "print") end
                line = string.gsub(line, "%s-([{}%(%)%-%+])", "%1")
                line = string.gsub(line, "([{}%(%)%-%+])%s+", "%1")
                line = string.gsub(line, "table%.getn", "#")
                line = string.gsub(line, "getn", "#")
                line = string.gsub(line, "table.wipe", "wipe")
                line = string.gsub(line, "string%.format", "format")
                line = string.gsub(line, "string%.gsub", "gsub")
                line = string.gsub(line, "string%.reverse", "strrev")
                local rep = {"byte", "char", "find", "len", "lower", "match", "rep", "sub", "upper"}
                for _, r in ipairs(rep) do
                    local bc1 = string.match(line, format("string%%.%s%%((.-%%))", r))
                    local bc2 = string.match(line, format("str%s%%((.-%%))", r))
                    local bc = bc1 and bc1 or bc2
                    local p1, p2
                    if bc then
                        p1 = string.match(bc, "(.-)[,%)]") or ""
                        if string.len(bc) ~= string.len(p1) + 1 then
                            s, e = string.find(bc, ",")
                            p2 = string.sub(bc, s + 1)
                        end
                        line = string.gsub(line, format("%s%s%%(.-%%)", (bc2 and "str" or "string%."), r), format("%s:%s(%s", p1, r, p2 or ")"))
                    end
                end
            end
            local ss
            for c, d in pairs(MT.commands) do
                s, e = string.find(line, format("%s%s()$", MT.slash, c))
                if not s then s, e, ss = string.find(line, format("%s%s(%%s.*)", MT.slash, c)) end
                if s then
                    if s~= e then
                        if string.len(string.sub(line, s + 1, e - 1)) > string.len(d[1]) then
                            line = format("%s%s%s", MT.slash, d[1], (ss or ""))
                            break
                        end
                    end
                end
            end
            macrotext = string.gsub(macrotext, ";$", "")
            local srun, scon = MT:FindShortest("SLASH_SCRIPT"), MT:FindShortest("SLASH_CONSOLE")
            if MT.db.profile.replacemt then
                line = string.gsub(line, format("%s UIErrorsFrame:Clear%%(%%)", srun), format("%smtce", MT.slash))
                line = string.gsub(line, format("%s UIErrorsFrame:RegisterEvent%%(\"UI_ERROR_MESSAGE\"%%)", srun), format("%smteo", MT.slash))
                line = string.gsub(line, format("%s UIErrorsFrame:RegisterEvent%%('UI_ERROR_MESSAGE'%%)", srun), format("%smteo", MT.slash))
                line = string.gsub(line, format("%s UIErrorsFrame:UnregisterEvent%%(\"UI_ERROR_MESSAGE\"%%)", srun), format("%smtex", MT.slash))
                line = string.gsub(line, format("%s UIErrorsFrame:UnregisterEvent%%('UI_ERROR_MESSAGE'%%)", srun), format("%smtex", MT.slash))
                line = string.gsub(line, format("%s Sound_EnableSFX 0", scon), format("%smtsx", MT.slash))
                line = string.gsub(line, format("%s Sound_EnableSFX 1", scon), format("%smtso", MT.slash))
                line = string.gsub(line, format("%s VehicleExit%%(%%)", srun), format("%smtev", MT.slash))
            end
            --*** ticket 89
            line = string.gsub(line, "(mod:ctrl),mod:(.-),mod(.-)", "%1%2%3")
            line = string.gsub(line, "(mod:shift),mod:(.-),mod:(.-)", "%1%2%3")
            line = string.gsub(line, "(mod:alt),mod:(.-),mod:(.-)", "%1%2%3")
            line = string.gsub(line, "(mod:ctrl),mod:(.-)", "%1%2")
            line = string.gsub(line, "(mod:shift),mod:(.-)", "%1%2")
            line = string.gsub(line, "(mod:alt),mod:(.-)", "%1%2")
            line = string.gsub(line, "mod:ctrl:shift:alt:?", "mod:ctrlshiftalt")
            line = string.gsub(line, "mod:ctrl:alt:shift:?", "mod:ctrlshiftalt")
            line = string.gsub(line, "mod:shift:ctrl:alt:?", "mod:ctrlshiftalt")
            line = string.gsub(line, "mod:shift:alt:ctrl:?", "mod:ctrlshiftalt")
            line = string.gsub(line, "mod:alt:shift:ctrl:?", "mod:ctrlshiftalt")
            line = string.gsub(line, "mod:alt:ctrl:shift:?", "mod:ctrlshiftalt")
            line = string.gsub(line, "mod:ctrl:alt:?", "mod:ctrlalt")
            line = string.gsub(line, "mod:alt:ctrl:?", "mod:ctrlalt")
            line = string.gsub(line, "mod:ctrl:shift:?", "mod:ctrlshift")
            line = string.gsub(line, "mod:shift:ctrl:?", "mod:ctrlshift")
            line = string.gsub(line, "mod:alt:shift:?", "mod:altshift")
            line = string.gsub(line, "mod:shift:alt:?", "mod:altshift")
            line = string.gsub(line, "mod:alt:", "mod:alt")
            line = string.gsub(line, "mod:ctrl:", "mod:ctrl")
            line = string.gsub(line, "mod:shift:", "mod:shift")
            --***
            table.insert(mout, line)
        end
    end
    if show and showt then table.remove(mout, show) end
    if shows and shows == firstc then mout[showt] = _G.SLASH_SHOWTOOLTIP1 end
    local mshort = ""
    for i, m in ipairs(mout) do mshort = format("%s%s\n", mshort, m) end
    mshort = trim(mshort)
    local nlen = olen - string.len(mshort)
    return mshort, nlen, firstc
end

function MT:FindComment(parameters)
    local s, e = string.find(parameters, format("%s%s", MT.slash, MT.slash))
    return s
end

function MT:ParseMacro(macrotext)
    if macrotext == "\n" then return macrotext, {} end
    if string.len(macrotext) == 0 then return nil, {} end
    local command_verb, options, comment
    local command_objects, conditions, condition_phrases = {}, {}, {}
    local command_object, condition, condition_phrase, condition_string
    local option_arguments, parsed_text, errors = {}, {}, {}
    local parameters, option_word, option_argument, target, pp
    local spos, schar, ss, se, pt, err, color, pos, mout, vv, epos, lpos

    -- ticket 139 - handle comments at the start of a line
    if string.sub(macrotext, 1, 2) == format("%s%s", MT.slash, MT.slash) then
        comment = string.sub(macrotext, 3)
        color = format("|c%s", MT.db.profile.comcolour)
        table.insert(parsed_text, { t = comment, c = color, s = 3})
    else
        schar = string.sub(macrotext, 1, 1)
        if schar == "#" or schar == MT.slash then
            local matchbrackets = matchedBrackets(macrotext)
            if matchbrackets ~= "" then table.insert(errors, format("%s: %s", L["Unmatched"], matchbrackets)) end
            spos = string.find(macrotext, " ")
            if spos then command_verb = string.sub(macrotext, 2, spos - 1)
            else
                command_verb = string.sub(macrotext, 2)
                color, err = validateCommandVerb(command_verb)
                if err then table.insert(errors, err) end
                table.insert(parsed_text, { t = command_verb, c = color, s = 2})
                vv = true
            end
            if spos then options = string.sub(macrotext, spos + 1) end
            if isScript(command_verb) then
                if spos then
                    parameters = options
                    color, err = validateParameters(parameters, command_verb)
                    if err then table.insert(errors, err) end
                    table.insert(parsed_text, { t = parameters, c = color, s = spos + 1})
                    color, err = validateCommandVerb(command_verb, parameters)
                    if err then table.insert(errors, err) end
                    table.insert(parsed_text, { t = command_verb, c = color, s = 2})
                end
            elseif options then
                if string.find(options, ";") then command_objects = {strsplit(";", options)}
                else command_objects = {options} end
                local seqpos
                for _, command_object in ipairs(command_objects)do
                    wipe(conditions)
                    ss, se = string.find(command_object, "%[.*%]")
                    if ss then
                        condition_string = string.sub(command_object, ss, se)
                        for c in string.gmatch(condition_string, "%[(.-)%]") do
                            pos = string.find(macrotext, escape(c), lpos or 1)
                            lpos = pos + string.len(c)
                            table.insert(conditions, {c = c, p = pos})
                        end
                        parameters = string.sub(command_object, se + 1)
                    else parameters = command_object end
                    pp = pp or parameters
                    if string.len(parameters or "") > 0 then
                        if isCastSequence(command_verb) then
                            local rerr, reset, sequence, col, rwhole, rerr2 = parseSequence(parameters)
                            if rerr then table.insert(errors, rerr) end
                            if rerr2 then table.insert(errors, rerr2) end
                            if rwhole then
                                local rpos = string.find(macrotext, escape(rwhole))
                                table.insert(parsed_text, {t = rwhole, c = col, s = rpos})
                            end
                            local casts = {strsplit(",", sequence)}
                            if not seqpos then seqpos = string.find(macrotext, escape(sequence)) end
                            for _, cast in ipairs(casts) do
                                col, err = validateParameters(cast, command_verb)
                                if err then table.insert(errors, err) end
                                seqpos = string.find(macrotext, escape(cast), seqpos)
                                table.insert(parsed_text, {t = cast, c = col, s = seqpos})
                                seqpos = seqpos + string.len(cast)
                            end
                            parameters = sequence
                        else
                            local fc = MT:FindComment(parameters)
                            if fc then
                                comment = string.sub(parameters, fc + 2)
                                color = format("|c%s", MT.db.profile.comcolour)
                                local ppos = MT:FindComment(macrotext)
                                table.insert(parsed_text, { t = comment, c = color, s = ppos + 2})
                                parameters = string.sub(parameters, 1, fc - 1)
                            end
                            color, err = validateParameters(parameters, command_verb)
                            if err then table.insert(errors, err) end
                            pos, epos = string.find(macrotext, escape(parameters), epos or 1)
                            table.insert(parsed_text, { t = parameters, c = color, s = pos})
                        end
                    end
                    if not vv then
                        local fc = MT:FindComment(parameters)
                        if fc then
                            comment = string.sub(parameters, fc + 2)
                            color = format("|c%s", MT.db.profile.comcolour)
                            local ppos = MT:FindComment(macrotext)
                            table.insert(parsed_text, { t = comment, c = color, s = ppos + 2})
                            parameters = string.sub(parameters, 1, fc - 1)
                        end
                        color, err = validateCommandVerb(command_verb, parameters)
                        if err then table.insert(errors, err) end
                        table.insert(parsed_text, { t = command_verb, c = color, s = 2})
                        vv = true
                    end
                    for _, c in ipairs(conditions) do
                        local cps = {strsplit(",", c.c)}
                        for _, condition_phrase in ipairs(cps) do
                            spos = string.find(condition_phrase, ":")
                            wipe(option_arguments)
                            if spos then
                                option_arguments = {strsplit("/", string.sub(condition_phrase, spos + 1))}
                                condition = string.sub(condition_phrase, 1, spos - 1)
                            else condition = condition_phrase end
                            local colorArguments
                            color, err, colorArguments = validateCondition(condition, option_arguments, parameters)
                            if err then table.insert(errors, err) end
                            pos = string.find(macrotext, escape(condition), c.p)
                            table.insert(parsed_text, { t = condition, c = color, s = pos})
                            if colorArguments then
                                for _, argument in ipairs(option_arguments) do
                                    pos = string.find(macrotext, escape(argument), pos)
                                    table.insert(parsed_text, { t = argument, c = colorArguments, s = pos})
                                end
                            end
                        end
                    end
                end
            end
        else table.insert(errors, format("%s: |c%s%s|r", L["Not a macro command"], MT.db.profile.errorcolour, macrotext)) end
    end

    table.sort(parsed_text, function(a,b) return a.s < b.s end)
    mout = macrotext

    local offset = 0
    local lbefore, lafter
    for _, term in ipairs(parsed_text) do
        lbefore = string.len(mout)
        mout = replace(mout, term.t, format("%s%s%s", term.c, term.t, term.c == "" and "" or "|r"), term.s + offset)
        lafter = string.len(mout)
        offset = offset + (lafter - lbefore)
    end
    return mout, errors, command_verb, pp
end

