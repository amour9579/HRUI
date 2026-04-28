local _, ns = ...

local MAX_COMMAND_SLOTS = 10

local function NotifyChange()
    if ns.RegisterChatCommands then
        ns:RegisterChatCommands()
    end

    local registry = LibStub("AceConfigRegistry-3.0", true)
    if registry then
        registry:NotifyChange("HRUI")
    end
end

local function GetEntry(index)
    local entries = ns:GetCommandEntries()
    entries[index] = entries[index] or {
        enabled = false,
        trigger = "",
        action = "",
    }

    return entries[index]
end

local function CreateCommandSlot(index)
    return {
        type = "group",
        name = "명령어 " .. index,
        inline = true,
        order = 10 + index,
        args = {
            enabled = {
                type = "toggle",
                name = "사용",
                order = 1,
                width = "half",
                get = function()
                    return GetEntry(index).enabled ~= false
                end,
                set = function(_, value)
                    GetEntry(index).enabled = value
                    NotifyChange()
                end,
            },

            trigger = {
                type = "input",
                name = "사용 문구",
                desc = "직접 입력할 명령어입니다. 예: /ao",
                order = 2,
                width = "double",
                get = function()
                    return GetEntry(index).trigger or ""
                end,
                set = function(_, value)
                    GetEntry(index).trigger = ns:NormalizeSlashTrigger(value)
                    NotifyChange()
                end,
            },

            action = {
                type = "input",
                name = "실행 문구",
                desc = "실제로 실행할 명령어입니다. 예: /매크로",
                order = 3,
                width = "double",
                get = function()
                    return GetEntry(index).action or ""
                end,
                set = function(_, value)
                    GetEntry(index).action = ns:NormalizeSlashLine(value)
                    NotifyChange()
                end,
            },

            clear = {
                type = "execute",
                name = "비우기",
                order = 4,
                width = "half",
                func = function()
                    local entry = GetEntry(index)
                    entry.enabled = false
                    entry.trigger = ""
                    entry.action = ""
                    NotifyChange()
                end,
            },
        },
    }
end

function ns:CreateCommandOptions()
    local args = {
        description = {
            type = "description",
            name = "사용 문구는 직접 입력할 축약 명령어, 실행 문구는 실제 실행할 명령어입니다.\n예: 사용 문구 /ao → 실행 문구 /매크로",
            order = 1,
            width = "full",
        },
    }

    for i = 1, MAX_COMMAND_SLOTS do
        args["slot" .. i] = CreateCommandSlot(i)
    end

    return {
        type = "group",
        name = "슬래시 명령어",
        order = 9,
        args = args,
    }
end
