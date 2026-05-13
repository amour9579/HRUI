local _, ns = ...

local embellishmentCountValues = {
    ["auto"] = "자동",
    ["0"] = "0 - 생략",
    ["1"] = "1",
    ["2"] = "2",
}
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

local function NotifyConfigChanged()
    local AceConfigRegistry = LibStub and LibStub("AceConfigRegistry-3.0", true)
    if AceConfigRegistry and AceConfigRegistry.NotifyChange then
        AceConfigRegistry:NotifyChange("HRUI")
    end
end

local function GetPartyResumeDB()
    local db = GetKeystoneDB()
    db.partyResume = db.partyResume or {}
    db.partyResume.fields = db.partyResume.fields or {}
    return db.partyResume
end

local function IsPartyResumeEnabled()
    local db = GetPartyResumeDB()

    if db.enabled == nil then
        db.enabled = true
    end

    return db.enabled
end

local function SetPartyResumeEnabled(value)
    GetPartyResumeDB().enabled = value
    NotifyConfigChanged()
end

local function IsPartyResumeManual()
    return GetPartyResumeDB().manual == true
end

local function SetPartyResumeManual(value)
    GetPartyResumeDB().manual = value
    NotifyConfigChanged()
end

local function GetPartyResumeManualMessage()
    return GetPartyResumeDB().manualMessage or ""
end

local function SetPartyResumeManualMessage(value)
    GetPartyResumeDB().manualMessage = value or ""
    NotifyConfigChanged()
end
local function GetPartyResumeFields()
    return GetPartyResumeDB().fields
end

local function GetPartyResumeFieldValue(key)
    local fields = GetPartyResumeFields()

    if key == "showSpec" or key == "showItemLevel" or key == "showTierSet" then
        if fields[key] == nil then
            return true
        end

        return fields[key]
    end

    if key == "useSpecAbbrev" then
        return fields[key] == true
    end

    if key == "embellishmentCount" then
        if fields[key] == "auto" then
            return "auto"
        end

        return tonumber(fields[key]) or 0
    end

    return fields[key]
end
local function SetPartyResumeFieldValue(key, value)
    local fields = GetPartyResumeFields()

    if key == "embellishmentCount" then
        if value == "auto" then
            fields[key] = "auto"
        else
            fields[key] = tonumber(value) or 0
        end
    else
        fields[key] = value
    end
    NotifyConfigChanged()
end

local function GetPartyResumePreview()
    if ns.mplus and ns.mplus.BuildPartyResumeMessage then
        return ns.mplus:BuildPartyResumeMessage()
    end

    return "캐릭터 정보를 불러오는 중입니다."
end
function ns:CreateKeystoneReporter()
    return {
        type = "group",
        name = "파티이력서/쐐기",
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
                        width = "half",
                        order = 1,
                        get = function()
                            return GetReportFieldValue("showSpec")
                        end,
                        set = function(_, value)
                            SetReportFieldValue("showSpec", value)
                        end,
                    },
                    showItemLevel = {
                        type = "toggle",
                        name = "템렙",
                        desc = "보고 메시지에 현재 착용 아이템 레벨을 포함합니다.",
                        width = "half",
                        order = 2,
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
                        get = function()
                            return GetReportFieldValue("showScore")
                        end,
                        set = function(_, value)
                            SetReportFieldValue("showScore", value)
                        end,
                    },
                },
            },
            partyResumeFields = {
                type = "group",
                name = "이력서 양식",
                desc = "파티 참가 신청 쪽지에 사용할 이력서 서식을 설정합니다.",
                order = 4,
                inline = true,
                args = {
                    resumeNotice = {
                        type = "description",
                        name = "|cffffff00※ 자동입력은 WoW 보안 제한 때문에 불가능합니다. 보조창에서 Ctrl+C 후 신청 쪽지 칸에 Ctrl+V 하세요.|r",
                        order = 1,
                        width = "full",
                    },

                    enabled = {
                        type = "toggle",
                        name = "파티 이력서 사용",
                        desc = "파티 참가 신청 창이 열릴 때 파티 이력서 보조창을 표시합니다.",
                        order = 2,
                        width = "full",
                        get = IsPartyResumeEnabled,
                        set = function(_, value)
                            SetPartyResumeEnabled(value)
                        end,
                    },

                    powerHeader = { type = "header", name = "자동 서식", order = 3 },
                    showSpec = {
                        type = "toggle",
                        name = "전문화",
                        desc = "이력서에 현재 전문화를 포함합니다.",
                        width = "half",
                        order = 3.1,
                        get = function()
                            return GetPartyResumeFieldValue("showSpec")
                        end,
                        set = function(_, value)
                            SetPartyResumeFieldValue("showSpec", value)
                        end,
                    },

                    useSpecAbbrev = {
                        type = "toggle",
                        name = "전문화 약칭",
                        desc = "이력서 전문화를 직업별 약칭으로 표시합니다. 예: 생존→생냥, 냉기 법사→냉법, 냉기 죽기→냉죽, 신성 기사→신기, 신성 사제→신사",
                        width = "half",
                        order = 3.15,
                        get = function()
                            return GetPartyResumeFieldValue("useSpecAbbrev")
                        end,
                        set = function(_, value)
                            SetPartyResumeFieldValue("useSpecAbbrev", value)
                        end,
                        disabled = function()
                            return not GetPartyResumeFieldValue("showSpec")
                        end,
                    },

                    showItemLevel = {
                        type = "toggle",
                        name = "템렙",
                        desc = "이력서에 현재 착용 아이템 레벨을 포함합니다.",
                        width = "half",
                        order = 3.2,
                        get = function()
                            return GetPartyResumeFieldValue("showItemLevel")
                        end,
                        set = function(_, value)
                            SetPartyResumeFieldValue("showItemLevel", value)
                        end,
                    },

                    showTierSet = {
                        type = "toggle",
                        name = "셋템보유",
                        desc = "이력서에 현재 전문화 기준 셋템 착용 개수를 포함합니다.",
                        width = "half",
                        order = 3.3,
                        get = function()
                            return GetPartyResumeFieldValue("showTierSet")
                        end,
                        set = function(_, value)
                            SetPartyResumeFieldValue("showTierSet", value)
                        end,
                    },

                    embellishmentCount = {
                        type = "select",
                        name = "장식보유",
                        desc = "자동을 선택하면 착용 아이템 툴팁의 ‘장식됨’을 검사해 0~2개를 자동 표시합니다. 0이면 생략합니다.",
                        values = embellishmentCountValues,
                        style = "dropdown",
                        width = "half",
                        order = 3.4,
                        get = function()
                            return tostring(GetPartyResumeFieldValue("embellishmentCount"))
                        end,
                        set = function(_, value)
                            SetPartyResumeFieldValue("embellishmentCount", value)
                        end,
                    },

                    powerHeader1 = { type = "header", name = "수동 서식", order = 4 },

                    manual = {
                        type = "toggle",
                        name = "수동입력 사용",
                        desc = "체크하면 자동 서식 대신 직접 입력한 메시지를 사용합니다.",
                        order = 4.1,
                        width = "full",
                        get = IsPartyResumeManual,
                        set = function(_, value)
                            SetPartyResumeManual(value)
                        end,
                    },

                    manualMessage = {
                        type = "input",
                        name = "수동 메시지",
                        desc = "수동입력 사용 시 파티 이력서에 표시할 문구입니다.",
                        order = 4.2,
                        width = "full",
                        multiline = true,
                        get = GetPartyResumeManualMessage,
                        set = function(_, value)
                            SetPartyResumeManualMessage(value)
                        end,
                        disabled = function()
                            return not IsPartyResumeManual()
                        end,
                    },
                    preview = {
                        type = "input",
                        name = "완성된 서식",
                        desc = "현재 체크 상태와 캐릭터 정보를 기준으로 생성되는 파티 이력서입니다.",
                        order = 10,
                        width = "full",
                        get = GetPartyResumePreview,
                        set = function()
                            -- 미리보기 전용
                        end,
                    },
                },
            },
        }
    }
end
