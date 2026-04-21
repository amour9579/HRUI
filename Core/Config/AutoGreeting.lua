local _, ns = ...

local function GetAutoGreetingDB()
    ns.db.profile.chat = ns.db.profile.chat or {}

    if not ns.db.profile.chat.autoGreeting then
        ns.db.profile.chat.autoGreeting = {
            enabled = true,
            joinEnabled = true,
            joinMessage = "안녕 하세요",
            challengeCompletedEnabled = true,
            challengeCompletedMessage = "수고 하셨습니다",
        }
    end

    local db = ns.db.profile.chat.autoGreeting

    if db.enabled == nil then
        db.enabled = true
    end

    if db.joinEnabled == nil then
        db.joinEnabled = true
    end

    if db.challengeCompletedEnabled == nil then
        db.challengeCompletedEnabled = true
    end

    if db.joinMessage == nil or db.joinMessage == "" then
        db.joinMessage = "안녕 하세요"
    end

    if db.challengeCompletedMessage == nil or db.challengeCompletedMessage == "" then
        db.challengeCompletedMessage = "수고 하셨습니다"
    end

    return db
end

function ns:CreateAutoGreetingOptions()
    return {
        type = "group",
        name = "자동인사",
        order = 7,
        args = {
            desc = {
                type = "description",
                name = "자동 인사 설정",
                order = 0,
                fontSize = "medium",
            },

            enabled = {
                type = "toggle",
                name = "자동 인사 사용",
                width = "full",
                order = 2,
                get = function()
                    return GetAutoGreetingDB().enabled
                end,
                set = function(_, value)
                    GetAutoGreetingDB().enabled = value
                    if ns.AutoGreeting and ns.AutoGreeting.Refresh then
                        ns.AutoGreeting:Refresh()
                    end
                end,
            },

            joinEnabled = {
                type = "toggle",
                name = "파티 참가 시 인사",
                --width = "half",
                order = 3,
                disabled = function()
                    return not GetAutoGreetingDB().enabled
                end,
                get = function()
                    return GetAutoGreetingDB().joinEnabled
                end,
                set = function(_, value)
                    GetAutoGreetingDB().joinEnabled = value
                    if ns.AutoGreeting and ns.AutoGreeting.Refresh then
                        ns.AutoGreeting:Refresh()
                    end
                end,
            },

            challengeCompletedEnabled = {
                type = "toggle",
                name = "쐐기 완료 시 인사",
                --width = "half",
                order = 4,
                disabled = function()
                    return not GetAutoGreetingDB().enabled
                end,
                get = function()
                    return GetAutoGreetingDB().challengeCompletedEnabled
                end,
                set = function(_, value)
                    GetAutoGreetingDB().challengeCompletedEnabled = value
                    if ns.AutoGreeting and ns.AutoGreeting.Refresh then
                        ns.AutoGreeting:Refresh()
                    end
                end,
            },

            break1 = {
                type = "description",
                name = "",
                width = "full",
                order = 4.1,
            },

            joinMessage = {
                type = "input",
                name = "파티 참가 문구",
                width = "full",
                order = 5,
                disabled = function()
                    local db = GetAutoGreetingDB()
                    return not db.enabled or not db.joinEnabled
                end,
                get = function()
                    return GetAutoGreetingDB().joinMessage or ""
                end,
                set = function(_, value)
                    GetAutoGreetingDB().joinMessage = value ~= "" and value or "안녕 하세요"
                end,
            },

            challengeCompletedMessage = {
                type = "input",
                name = "쐐기 완료 문구",
                width = "full",
                order = 6,
                disabled = function()
                    local db = GetAutoGreetingDB()
                    return not db.enabled or not db.challengeCompletedEnabled
                end,
                get = function()
                    return GetAutoGreetingDB().challengeCompletedMessage or ""
                end,
                set = function(_, value)
                    GetAutoGreetingDB().challengeCompletedMessage = value ~= "" and value or "수고 하셨습니다"
                end,
            },
        },
    }
end
