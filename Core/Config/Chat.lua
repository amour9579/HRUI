local _, ns = ...

local function GetInfoBarDB()
    ns.db.profile.chat = ns.db.profile.chat or {}

    if not ns.db.profile.chat.infoBar then
        ns.db.profile.chat.infoBar = {
            enabled = true,
            width = 520,
            height = 20,
            alpha = 0.25,
            backdrop = true,
            outerPadding = 40,
            x = 0,
            y = -250,

            slotCount = 5,
            slots = {
                "TIME",
                "DURABILITY",
                "SPEC",
                "GUILD",
                "MPLUS",
            },
        }
    end

    local db = ns.db.profile.chat.infoBar

    db.slotCount = math.max(2, math.min(5, db.slotCount or 4))
    db.slots = db.slots or {}

    if not db.slots[1] then
        db.slots[1] = db.slots1 or "TIME"
        db.slots[2] = db.slots2 or "DURABILITY"
        db.slots[3] = db.slots3 or "SPEC"
        db.slots[4] = db.slots4 or "GUILD"
        db.slots[5] = db.slots5 or "MPLUS"
    end

    for i = 1, 5 do
        db.slots[i] = db.slots[i] or "NONE"
    end

    return db
end

local function GetCombatMessageDB()
    ns.db.profile.chat = ns.db.profile.chat or {}

    if not ns.db.profile.chat.combatMessage then
        ns.db.profile.chat.combatMessage = {
            enabled = true,
            backdrop = false,

            fontSize = 32,
            x = 0,
            y = 200,
            fadeTime = 1.5,

            startText = "* 전투 시작 *",
            endText = "* 전투 종료 *",

            startColor = { 1.0, 0.1, 0.1 },
            endColor = { 0.2, 1.0, 0.2 },
        }
    end

    return ns.db.profile.chat.combatMessage
end

local infoBarValues = {
    NONE = "없음",
    TIME = "시간",
    GUILD = "길드",
    FRIENDS = "친구",
    SPEC = "특성",
    DURABILITY = "내구도",
    PERFORMANCE = "프레임/지연시간",
    MPLUS = "쐐기",
}

function ns:CreateChatOptions()
    return {
        type = "group",
        name = "정보패널",
        order = 5,
        args = {
            desc = {
                type = "description",
                name = "정보패널 설정",
                order = 0,
                fontSize = "medium",
            },

            headerGeneral = {
                type = "header",
                name = "기본",
                order = 1,
            },

            enabled = {
                type = "toggle",
                name = "사용",
                width = "half",
                order = 2,
                get = function()
                    return GetInfoBarDB().enabled
                end,
                set = function(_, value)
                    GetInfoBarDB().enabled = value
                    if ns.ChatInfoBar then
                        ns.ChatInfoBar:Refresh()
                    end
                end,
            },

            backdrop = {
                type = "toggle",
                name = "배경 표시",
                width = "half",
                order = 3,
                get = function()
                    return GetInfoBarDB().backdrop
                end,
                set = function(_, value)
                    GetInfoBarDB().backdrop = value
                    if ns.ChatInfoBar then
                        ns.ChatInfoBar:Refresh()
                    end
                end,
            },
            
            padding = {
                type = "range",
                name = "여백",
                order = 3.3,
                min = 2,
                max = 70,
                step = 1,
                get = function()
                    return GetInfoBarDB().outerPadding
                end,
                set = function(_, value)
                    GetInfoBarDB().outerPadding = value
                    if ns.ChatInfoBar then
                        ns.ChatInfoBar:Refresh()
                    end
                end,
            },
            break1 = {
                type = "description",
                name = "",
                width = "full",
                order = 3.5,
            },

            width = {
                type = "range",
                name = "너비",
                order = 4,
                min = 200,
                max = 800,
                step = 1,
                get = function()
                    return GetInfoBarDB().width
                end,
                set = function(_, value)
                    GetInfoBarDB().width = value
                    if ns.ChatInfoBar then
                        ns.ChatInfoBar:Refresh()
                    end
                end,
            },

            height = {
                type = "range",
                name = "높이",
                order = 5,
                min = 14,
                max = 40,
                step = 1,
                get = function()
                    return GetInfoBarDB().height
                end,
                set = function(_, value)
                    GetInfoBarDB().height = value
                    if ns.ChatInfoBar then
                        ns.ChatInfoBar:Refresh()
                    end
                end,
            },

            alpha = {
                type = "range",
                name = "투명도",
                order = 6,
                min = 0,
                max = 1,
                step = 0.01,
                get = function()
                    return GetInfoBarDB().alpha
                end,
                set = function(_, value)
                    GetInfoBarDB().alpha = value
                    if ns.ChatInfoBar then
                        ns.ChatInfoBar:Refresh()
                    end
                end,
            },

            posX = {
                order = 7,
                type = "range",
                name = "중앙 기준 X",
                min = -1200,
                max = 1200,
                step = 1,
                bigStep = 10,
                get = function()
                    return (ns.db.profile.chat.infoBar.x or 0)
                end,
                set = function(_, value)
                    ns.db.profile.chat.infoBar.x = value
                    if ns.ChatInfoBar and ns.ChatInfoBar.Refresh then
                        ns.ChatInfoBar:Refresh()
                    end
                end,
            },

            posY = {
                order = 8,
                type = "range",
                name = "중앙 기준 Y",
                min = -800,
                max = 800,
                step = 1,
                bigStep = 10,
                get = function()
                    return (ns.db.profile.chat.infoBar.y or 0)
                end,
                set = function(_, value)
                    ns.db.profile.chat.infoBar.y = value
                    if ns.ChatInfoBar and ns.ChatInfoBar.Refresh then
                        ns.ChatInfoBar:Refresh()
                    end
                end,
            },

            headerSlots = {
                type = "header",
                name = "슬롯",
                order = 10,
            },

            slotCount = {
                type = "range",
                name = "슬롯 개수",
                order = 10.1,
                min = 2,
                max = 5,
                step = 1,
                get = function()
                    return GetInfoBarDB().slotCount
                end,
                set = function(_, value)
                    local db = GetInfoBarDB()
                    db.slotCount = value

                    for i = 1, 5 do
                        db.slots[i] = db.slots[i] or "NONE"
                    end

                    if ns.ChatInfoBar then
                        ns.ChatInfoBar:Refresh()
                    end
                end,
            },

            break4 = {
                type = "description",
                name = "",
                width = "full",
                order = 10.2,
            },

            slot1 = {
                type = "select",
                name = "슬롯 1",
                order = 11,
                values = infoBarValues,
                get = function()
                    return GetInfoBarDB().slots[1]
                end,
                set = function(_, value)
                    GetInfoBarDB().slots[1] = value
                    if ns.ChatInfoBar then
                        ns.ChatInfoBar:Refresh()
                    end
                end,
            },

            slot2 = {
                type = "select",
                name = "슬롯 2",
                order = 12,
                values = infoBarValues,
                get = function()
                    return GetInfoBarDB().slots[2]
                end,
                set = function(_, value)
                    GetInfoBarDB().slots[2] = value
                    if ns.ChatInfoBar then
                        ns.ChatInfoBar:Refresh()
                    end
                end,
            },

            slot3 = {
                type = "select",
                name = "슬롯 3",
                order = 13,
                values = infoBarValues,
                hidden = function()
                    return GetInfoBarDB().slotCount < 3
                end,
                get = function()
                    return GetInfoBarDB().slots[3]
                end,
                set = function(_, value)
                    GetInfoBarDB().slots[3] = value
                    if ns.ChatInfoBar then
                        ns.ChatInfoBar:Refresh()
                    end
                end,
            },

            slot4 = {
                type = "select",
                name = "슬롯 4",
                order = 14,
                values = infoBarValues,
                hidden = function()
                    return GetInfoBarDB().slotCount < 4
                end,
                get = function()
                    return GetInfoBarDB().slots[4]
                end,
                set = function(_, value)
                    GetInfoBarDB().slots[4] = value
                    if ns.ChatInfoBar then
                        ns.ChatInfoBar:Refresh()
                    end
                end,
            },

            slot5 = {
                type = "select",
                name = "슬롯 5",
                order = 15,
                values = infoBarValues,
                hidden = function()
                    return GetInfoBarDB().slotCount < 5
                end,
                get = function()
                    return GetInfoBarDB().slots[5]
                end,
                set = function(_, value)
                    GetInfoBarDB().slots[5] = value
                    if ns.ChatInfoBar then
                        ns.ChatInfoBar:Refresh()
                    end
                end,
            },

            headerCombatMessage = {
                type = "header",
                name = "전투 메시지",
                order = 20,
            },

            combatMessageEnabled = {
                type = "toggle",
                name = "전투 메시지 알림",
                width = 1,
                order = 21,
                get = function()
                    return GetCombatMessageDB().enabled
                end,
                set = function(_, value)
                    GetCombatMessageDB().enabled = value
                    if ns.CombatMessage and ns.CombatMessage.Refresh then
                        ns.CombatMessage:Refresh()
                    end
                end,
            },

            combatMessageBackdrop = {
                type = "toggle",
                name = "전투 메시지 배경",
                width = 1,
                order = 21.5,
                disabled = function()
                    return not GetCombatMessageDB().enabled
                end,
                get = function()
                    return GetCombatMessageDB().backdrop
                end,
                set = function(_, value)
                    GetCombatMessageDB().backdrop = value
                    if ns.CombatMessage and ns.CombatMessage.Refresh then
                        ns.CombatMessage:Refresh()
                    end
                end,
            },

            break2 = {
                type = "description",
                name = "",
                width = "full",
                order = 22,
            },
            
            combatMessageFontSize = {
                type = "range",
                name = "글씨 크기",
                order = 23,
                min = 12,
                max = 64,
                step = 1,
                disabled = function()
                    return not GetCombatMessageDB().enabled
                end,
                get = function()
                    return GetCombatMessageDB().fontSize
                end,
                set = function(_, value)
                    GetCombatMessageDB().fontSize = value
                    if ns.CombatMessage and ns.CombatMessage.Refresh then
                        ns.CombatMessage:Refresh()
                    end
                end,
            },

            combatMessagePosX = {
                type = "range",
                name = "메시지 X",
                order = 23.1,
                min = -1200,
                max = 1200,
                step = 1,
                bigStep = 10,
                disabled = function()
                    return not GetCombatMessageDB().enabled
                end,
                get = function()
                    return GetCombatMessageDB().x
                end,
                set = function(_, value)
                    GetCombatMessageDB().x = value
                    if ns.CombatMessage and ns.CombatMessage.Refresh then
                        ns.CombatMessage:Refresh()
                    end
                end,
            },

            combatMessagePosY = {
                type = "range",
                name = "메시지 Y",
                order = 23.2,
                min = -800,
                max = 800,
                step = 1,
                bigStep = 10,
                disabled = function()
                    return not GetCombatMessageDB().enabled
                end,
                get = function()
                    return GetCombatMessageDB().y
                end,
                set = function(_, value)
                    GetCombatMessageDB().y = value
                    if ns.CombatMessage and ns.CombatMessage.Refresh then
                        ns.CombatMessage:Refresh()
                    end
                end,
            },

            combatMessageFadeTime = {
                type = "range",
                name = "페이드 시간",
                order = 23.3,
                min = 0.5,
                max = 3,
                step = 0.1,
                disabled = function()
                    return not GetCombatMessageDB().enabled
                end,
                get = function()
                    return GetCombatMessageDB().fadeTime
                end,
                set = function(_, value)
                    GetCombatMessageDB().fadeTime = value
                    if ns.CombatMessage and ns.CombatMessage.Refresh then
                        ns.CombatMessage:Refresh()
                    end
                end,
            },

            break3 = {
                type = "description",
                name = "",
                width = "full",
                order = 23.5,
            },

            combatMessageStartColor = {
                type = "color",
                name = "전투 시작 색상",
                order = 24,
                hasAlpha = false,
                disabled = function()
                    return not GetCombatMessageDB().enabled
                end,
                get = function()
                    local c = GetCombatMessageDB().startColor
                    return c[1], c[2], c[3]
                end,
                set = function(_, r, g, b)
                    local c = GetCombatMessageDB().startColor
                    c[1], c[2], c[3] = r, g, b
                    if ns.CombatMessage and ns.CombatMessage.Refresh then
                        ns.CombatMessage:Refresh()
                    end
                end,
            },

            combatMessageEndColor = {
                type = "color",
                name = "전투 종료 색상",
                order = 24.1,
                hasAlpha = false,
                disabled = function()
                    return not GetCombatMessageDB().enabled
                end,
                get = function()
                    local c = GetCombatMessageDB().endColor
                    return c[1], c[2], c[3]
                end,
                set = function(_, r, g, b)
                    local c = GetCombatMessageDB().endColor
                    c[1], c[2], c[3] = r, g, b
                    if ns.CombatMessage and ns.CombatMessage.Refresh then
                        ns.CombatMessage:Refresh()
                    end
                end,
            },

            combatMessageStartText = {
                type = "input",
                name = "전투 시작 문구",
                order = 25,
                width = "full",
                disabled = function()
                    return not GetCombatMessageDB().enabled
                end,
                get = function()
                    return GetCombatMessageDB().startText or ""
                end,
                set = function(_, value)
                    GetCombatMessageDB().startText = value ~= "" and value or "* 전투 시작 *"
                    if ns.CombatMessage and ns.CombatMessage.Refresh then
                        ns.CombatMessage:Refresh()
                    end
                end,
            },

            combatMessageEndText = {
                type = "input",
                name = "전투 종료 문구",
                order = 25.1,
                width = "full",
                disabled = function()
                    return not GetCombatMessageDB().enabled
                end,
                get = function()
                    return GetCombatMessageDB().endText or ""
                end,
                set = function(_, value)
                    GetCombatMessageDB().endText = value ~= "" and value or "* 전투 종료 *"
                    if ns.CombatMessage and ns.CombatMessage.Refresh then
                        ns.CombatMessage:Refresh()
                    end
                end,
            },

            combatMessageTestStart = {
                type = "execute",
                name = "전투 시작 테스트",
                order = 26,
                width = "0.9",
                disabled = function()
                    return not GetCombatMessageDB().enabled
                end,
                func = function()
                    local db = GetCombatMessageDB()
                    if ns.CombatMessage and ns.CombatMessage.ToggleTest then
                        ns.CombatMessage:ToggleTest(
                            "전투 시작 테스트",
                            db.startColor or { 1.0, 0.1, 0.1 }
                        )
                    end
                end,
            },

            combatMessageTestEnd = {
                type = "execute",
                name = "전투 종료 테스트",
                order = 26.1,
                width = "0.9",
                disabled = function()
                    return not GetCombatMessageDB().enabled
                end,
                func = function()
                    local db = GetCombatMessageDB()
                    if ns.CombatMessage and ns.CombatMessage.ToggleTest then
                        ns.CombatMessage:ToggleTest(
                            "전투 종료 테스트",
                            db.endColor or { 0.2, 1.0, 0.2 }
                        )
                    end
                end,
            },

            break5 = {
                type = "description",
                name = "",
                width = "full",
                order = 26.5,
            },
            move = {
                type = "execute",
                order = 31,
                name = function()
                    if ns.Movers and ns.Movers:IsUnlocked() then
                        return "이동 모드 종료"
                    end
                    return "이동 모드 시작"
                end,

                func = function()
                    if not ns.Movers then return end

                    if ns.Movers:IsUnlocked() then
                        ns.Movers:Lock()
                    else
                        ns.Movers:Unlock()
                    end
                end,
            },

            resetPosition = {
                type = "execute",
                name = "위치 초기화",
                order = 32,
                func = function()
                    local db = GetInfoBarDB()
                    db.x = 0
                    db.y = -250

                    if ns.ChatInfoBar then
                        ns.ChatInfoBar:Refresh()
                    end
                end,
            },
        },
    }
end
