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

local function GetPartyResumeFields()
    return GetPartyResumeDB().fields
end

local function GetPartyResumeFieldValue(key)
    local fields = GetPartyResumeFields()

    if fields[key] == nil then
        return true
    end

    return fields[key]
end

local function SetPartyResumeFieldValue(key, value)
    GetPartyResumeFields()[key] = value
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
                        name = "|cffffff00※ 참가 신청 창이 열리면 완성된 서식을 선택할 수 있는 보조창이 표시됩니다. Ctrl+C 후 쪽지 칸에 Ctrl+V 하세요.|r",
                        order = 1,
                        width = "full",
                    },

                    showSpec = {
                        type = "toggle",
                        name = "전문화",
                        desc = "이력서에 현재 전문화를 포함합니다.",
                        width = "half",
                        order = 2,
                        get = function()
                            return GetPartyResumeFieldValue("showSpec")
                        end,
                        set = function(_, value)
                            SetPartyResumeFieldValue("showSpec", value)
                        end,
                    },

                    showItemLevel = {
                        type = "toggle",
                        name = "템렙",
                        desc = "이력서에 현재 착용 아이템 레벨을 포함합니다.",
                        width = "half",
                        order = 3,
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
                        order = 4,
                        get = function()
                            return GetPartyResumeFieldValue("showTierSet")
                        end,
                        set = function(_, value)
                            SetPartyResumeFieldValue("showTierSet", value)
                        end,
                    },

                    showEmbellishment = {
                        type = "toggle",
                        name = "장식보유",
                        desc = "이력서에 현재 착용 중인 장식 아이템 개수를 포함합니다.",
                        width = "half",
                        order = 5,
                        get = function()
                            return GetPartyResumeFieldValue("showEmbellishment")
                        end,
                        set = function(_, value)
                            SetPartyResumeFieldValue("showEmbellishment", value)
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

                    showHelper = {
                        type = "execute",
                        name = "이력서 선택창 열기",
                        desc = "완성된 서식을 선택 가능한 보조창으로 표시합니다.",
                        order = 11,
                        func = function()
                            if ns.mplus and ns.mplus.ShowPartyResumeHelper then
                                ns.mplus:ShowPartyResumeHelper()
                            end
                        end,
                    },
                },
            },
        }
    }
end
