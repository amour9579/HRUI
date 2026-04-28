local _, ns = ...

local registeredCommands = {}

local DEFAULT_ENTRIES = {
    { enabled = true, trigger = "/rl", action = "/reload" },
    { enabled = true, trigger = "/기", action = "/reload" },
}

local function Trim(value)
    value = tostring(value or "")
    if strtrim then
        return strtrim(value)
    end
    return value:match("^%s*(.-)%s*$")
end

function ns:NormalizeSlashLine(value)
    local line = Trim(value)
    if line == "" then return "" end
    if line:sub(1, 1) ~= "/" then
        line = "/" .. line
    end
    return line
end

function ns:NormalizeSlashTrigger(value)
    local line = ns:NormalizeSlashLine(value)
    if line == "" then return "" end
    return line:match("^(%S+)") or ""
end

local function CopyDefaultEntries()
    local entries = {}

    for i, entry in ipairs(DEFAULT_ENTRIES) do
        entries[i] = {
            enabled = entry.enabled,
            trigger = entry.trigger,
            action = entry.action,
        }
    end

    return entries
end

function ns:GetCommandEntries()
    local profile = ns.db and ns.db.profile
    if not profile then return {} end

    if not profile.commands then
        profile.commands = {
            initialized = true,
            entries = CopyDefaultEntries(),
        }
    end

    profile.commands.initialized = true
    profile.commands.entries = profile.commands.entries or CopyDefaultEntries()

    return profile.commands.entries
end

local function Print(message)
    if ns.HRUI and ns.HRUI.Print then
        ns.HRUI:Print(message)
    elseif DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(message)
    end
end

local function FindSlashHandler(slash)
    slash = string.lower(slash or "")

    for name, handler in pairs(SlashCmdList) do
        local index = 1

        while true do
            local alias = _G["SLASH_" .. name .. index]
            if not alias then break end

            if string.lower(alias) == slash then
                return handler
            end

            index = index + 1
        end
    end
end

local function ExecuteSlashLine(line)
    line = ns:NormalizeSlashLine(line)
    if line == "" then return end

    local slash, args = line:match("^(%S+)%s*(.-)$")
    if not slash then return end

    local lowerSlash = string.lower(slash)

    if lowerSlash == "/reload" or lowerSlash == "/rl" then
        ReloadUI()
        return
    end

    local handler = FindSlashHandler(lowerSlash)
    if handler then
        handler(args or "")
        return
    end

    local editBox = DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.editBox
    if editBox and ChatEdit_ParseText then
        editBox:SetText(line)
        ChatEdit_ParseText(editBox, 1)
    else
        Print("실행할 수 없는 명령어입니다: " .. line)
    end
end

local function BuildActionLine(action, input)
    local line = ns:NormalizeSlashLine(action)
    input = Trim(input)

    if line ~= "" and input ~= "" then
        line = line .. " " .. input
    end

    return line
end

function ns:UnregisterCustomChatCommands()
    local addon = ns.HRUI

    if addon and addon.UnregisterChatCommand then
        for command in pairs(registeredCommands) do
            addon:UnregisterChatCommand(command)
        end
    end

    wipe(registeredCommands)
end
function ns:RegisterChatCommands()
    local addon = ns.HRUI
    if not addon or not addon.RegisterChatCommand then
        return
    end

    ns:UnregisterCustomChatCommands()

    local used = {}

    for _, entry in ipairs(ns:GetCommandEntries()) do
        if entry and entry.enabled ~= false then
            local trigger = ns:NormalizeSlashTrigger(entry.trigger)
            local action = ns:NormalizeSlashLine(entry.action)
            local command = trigger ~= "" and string.lower(trigger:sub(2)) or ""

            if command ~= "" and action ~= "" and command ~= "hrui" and not used[command] then
                used[command] = true
                registeredCommands[command] = true

                addon:RegisterChatCommand(command, function(input)
                    local lowerTrigger = string.lower(trigger)
                    local actionSlash = string.lower(ns:NormalizeSlashTrigger(action) or "")

                    if actionSlash == lowerTrigger then
                        Print("자기 자신을 실행하는 명령어는 등록할 수 없습니다: " .. trigger)
                        return
                    end

                    ExecuteSlashLine(BuildActionLine(action, input))
                end, true)
            end
        end
    end
end
