local _, ns = ...

local function GetKeystoneDB()
    ns.db.profile.mythicPlusReporter = ns.db.profile.mythicPlusReporter or {}

    if ns.db.profile.mythicPlusReporter.enabled == nil then
        ns.db.profile.mythicPlusReporter.enabled = true
    end

    return ns.db.profile.mythicPlusReporter
end

local function GetReportFields()
    local db = GetKeystoneDB()
    db.reportFields = db.reportFields or {}
    return db.reportFields
end

local function GetReportFieldValue(key)
    return GetReportFields()[key] ~= false
end

local function SetReportFieldValue(key, value)
    GetReportFields()[key] = value
end

function ns:CreateKeystoneReporter()
    return {
        type = "group",
        name = "쐐기",
        order = 6,
        args = {
            mythicPlusReporter = {
                type = "toggle",
                name = "쐐기 채팅 자동 보고 사용",
                desc = "길드/파티 채팅에서 !돌, !주차, !keys, !weekly 입력 시 자동으로 응답합니다.",
                order = 1,
                width = "full",
                get = function()
                    return GetKeystoneDB().enabled
                end,
                set = function(_, value)
                    GetKeystoneDB().enabled = value

                    if ns.mplus and ns.mplus.Initialize then
                        ns.mplus:Initialize()
                    end
                end,
            },
            keystone_notice = {
                type = "description",
                name = "|cffffff00※ 채팅에서 !돌, !주차, !keys, !weekly 입력 시 자동으로 응답합니다.|r",
                order = 2,
                width = "full",
            },
            reportFields = {
                type = "group",
                name = "!돌 보고 항목",
                desc = "체크한 항목만 !돌, !keys, !ehf 응답에 포함합니다. 쐐기돌은 항상 보고합니다.",
                order = 3,
                inline = true,
                args = {
                    showSpec = {
                        type = "toggle",
                        name = "전문화",
                        desc = "보고 메시지에 현재 전문화를 포함합니다.",
                        order = 1,
                        width = "half",
                        get = function()
                            return GetReportFieldValue("showSpec")
                        end,
                        set = function(_, value)
                            SetReportFieldValue("showSpec", value)
                        end,
                    },
                    showItemLevel = {
                        type = "toggle",
                        name = "템렙 / 아이템 레벨",
                        desc = "보고 메시지에 현재 착용 아이템 레벨을 포함합니다.",
                        order = 2,
                        width = "half",
                        get = function()
                            return GetReportFieldValue("showItemLevel")
                        end,
                        set = function(_, value)
                            SetReportFieldValue("showItemLevel", value)
                        end,
                    },
                    showScore = {
                        type = "toggle",
                        name = "점수",
                        desc = "보고 메시지에 쐐기 점수를 포함합니다.",
                        order = 3,
                        width = "half",
                        get = function()
                            return GetReportFieldValue("showScore")
                        end,
                        set = function(_, value)
                            SetReportFieldValue("showScore", value)
                        end,
                    },
                },
            },
        }
    }
end
