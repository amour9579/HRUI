local _, ns = ...

local DEFAULT_JOIN_MESSAGE = "안녕 하세요"
local DEFAULT_CHALLENGE_COMPLETED_MESSAGE = "수고 하셨습니다"
local DEFAULT_SUMMON_MESSAGE = "감사 합니다"

local function GetAutoGreetingDB()
    ns.db.profile.chat = ns.db.profile.chat or {}

    if not ns.db.profile.chat.autoGreeting then
        ns.db.profile.chat.autoGreeting = {
            enabled = true,
            joinEnabled = true,
            joinMessage = DEFAULT_JOIN_MESSAGE,
            challengeCompletedEnabled = true,
            challengeCompletedMessage = DEFAULT_CHALLENGE_COMPLETED_MESSAGE,
            summonEnabled = true,
            summonMessage = DEFAULT_SUMMON_MESSAGE,
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

    if db.summonEnabled == nil then
        db.summonEnabled = true
    end

    if db.joinMessage == nil or db.joinMessage == "" then
        db.joinMessage = DEFAULT_JOIN_MESSAGE
    end

    if db.challengeCompletedMessage == nil or db.challengeCompletedMessage == "" then
        db.challengeCompletedMessage = DEFAULT_CHALLENGE_COMPLETED_MESSAGE
    end

    if db.summonMessage == nil or db.summonMessage == "" then
        db.summonMessage = DEFAULT_SUMMON_MESSAGE
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

            summonEnabled = {
                type = "toggle",
                name = "소환 받을 시 인사",
                order = 5,
                disabled = function()
                    return not GetAutoGreetingDB().enabled
                end,
                get = function()
                    return GetAutoGreetingDB().summonEnabled
                end,
                set = function(_, value)
                    GetAutoGreetingDB().summonEnabled = value
                    if ns.AutoGreeting and ns.AutoGreeting.Refresh then
                        ns.AutoGreeting:Refresh()
                    end
                end,
            },

            break1 = {
                type = "description",
                name = "",
                width = "full",
                order = 5.1,
            },

            joinMessage = {
                type = "input",
                name = "파티 참가 문구",
                width = "full",
                order = 6,
                disabled = function()
                    local db = GetAutoGreetingDB()
                    return not db.enabled or not db.joinEnabled
                end,
                get = function()
                    return GetAutoGreetingDB().joinMessage or ""
                end,
                set = function(_, value)
                    GetAutoGreetingDB().joinMessage = value ~= "" and value or DEFAULT_JOIN_MESSAGE
                end,
            },

            challengeCompletedMessage = {
                type = "input",
                name = "쐐기 완료 문구",
                width = "full",
                order = 7,
                disabled = function()
                    local db = GetAutoGreetingDB()
                    return not db.enabled or not db.challengeCompletedEnabled
                end,
                get = function()
                    return GetAutoGreetingDB().challengeCompletedMessage or ""
                end,
                set = function(_, value)
                    GetAutoGreetingDB().challengeCompletedMessage = value ~= "" and value or DEFAULT_CHALLENGE_COMPLETED_MESSAGE
                end,
            },

            summonMessage = {
                type = "input",
                name = "소환 감사 문구",
                width = "full",
                order = 8,
                disabled = function()
                    local db = GetAutoGreetingDB()
                    return not db.enabled or not db.summonEnabled
                end,
                get = function()
                    return GetAutoGreetingDB().summonMessage or ""
                end,
                set = function(_, value)
                    GetAutoGreetingDB().summonMessage = value ~= "" and value or DEFAULT_SUMMON_MESSAGE
                end,
            },
        },
    }
end
