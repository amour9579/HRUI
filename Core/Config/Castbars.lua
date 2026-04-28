local _, ns = ...

local castbarFontValues = ns.ConfigValues.castbarFontValues

local function CreateCastbarGroup(unit, label)
    return {
        type = "group",
        name = label,
        args = {
            enabled = {
                type = "toggle",
                name = "표시",
                order = 1,
                get = function()
                    local db = ns:GetCastbarDB(unit); return db and db.enabled
                end,
                set = function(_, value)
                    local db = ns:GetCastbarDB(unit); if db then
                        db.enabled = value; ns:RefreshCastbar(unit)
                    end
                end,
            },
            width = {
                type = "input",
                name = "너비",
                order = 2,
                get = function() return ns:GetCastbarNumber(unit, "width") end,
                set = function(
                    _, value)
                    ns:SetCastbarNumber(unit, "width", value)
                end
            },
            height = {
                type = "input",
                name = "높이",
                order = 3,
                get = function() return ns:GetCastbarNumber(unit, "height") end,
                set = function(
                    _, value)
                    ns:SetCastbarNumber(unit, "height", value)
                end
            },
            x = {
                type = "input",
                name = "중앙 기준 X",
                order = 4,
                get = function() return ns:GetCastbarNumber(unit, "x") end,
                set = function(
                    _, value)
                    ns:SetCastbarNumber(unit, "x", value)
                end
            },
            
            y = {
                type = "input",
                name = "중앙 기준 Y",
                order = 5,
                get = function() return ns:GetCastbarNumber(unit, "y") end,
                set = function(
                    _, value)
                    ns:SetCastbarNumber(unit, "y", value)
                end
            },
            
            move = {
                type = "execute",
                order = 6,
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

            test = {
                type = "execute",
                name = "테스트 표시",
                order = 7,
                func = function()
                    local db = ns:GetCastbarDB(unit)
                    local frame

                    if unit == "player" then
                        frame = ns.PlayerCastbar
                    elseif unit == "target" then
                        frame = ns.TargetCastbar
                    elseif unit == "pet" then
                        frame = ns.PetCastbar
                    end

                    if not frame then
                        return
                    end

                    if not db or not db.enabled then
                        if unit == "target" and ns.ResetTargetCastbar then
                            ns:ResetTargetCastbar(frame)
                        else
                            ns:ResetCastbar(frame)
                        end

                        return
                    end

                    if unit == "target" then
                        frame.__HRUI_TestCastbar = true
                    end

                    local now = GetTime()

                    ns:ResetCastbar(frame)
                    ns:StartCastbarCast(frame, "Test Spell", 136243, now * 1000, (now + 10) * 1000, false)

                    if C_Timer and C_Timer.After then
                        C_Timer.After(10.05, function()
                            if not frame then
                                return
                            end

                            if unit == "target" then
                                if frame.__HRUI_TestCastbar then
                                    if ns.ResetTargetCastbar then
                                        ns:ResetTargetCastbar(frame)
                                    else
                                        frame.__HRUI_TestCastbar = nil
                                        ns:ResetCastbar(frame)
                                    end
                                end
                            else
                                ns:ResetCastbar(frame)
                            end
                        end)
                    end
                end,
            },
            iconHeader = { type = "header", name = "아이콘", order = 10 },
            iconEnabled = {
                type = "toggle",
                name = "아이콘 표시",
                order = 11,
                get = function()
                    local db = ns:GetCastbarDB(unit); return db and db.icon and db.icon.enabled
                end,
                set = function(_, value)
                    local db = ns:GetCastbarDB(unit); if db and db.icon then
                        db.icon.enabled = value; ns:RefreshCastbar(unit)
                    end
                end,
            },
            iconSize = {
                type = "input",
                name = "아이콘 크기",
                order = 12,
                get = function()
                    return ns:GetCastbarNestedNumber(
                        unit, "icon", "size")
                end,
                set = function(_, value) ns:SetCastbarNestedNumber(unit, "icon", "size", value) end
            },
            textHeader = { type = "header", name = "텍스트", order = 20 },
            textEnabled = {
                type = "toggle",
                name = "시전명 표시",
                order = 21,
                get = function()
                    local db = ns:GetCastbarDB(unit); return db and db.text and db.text.enabled
                end,
                set = function(_, value)
                    local db = ns:GetCastbarDB(unit); if db and db.text then
                        db.text.enabled = value; ns:RefreshCastbar(unit)
                    end
                end,
            },
            
            textAnchor = {
                type = "select",
                name = "주문명 기준점",
                order = 23,
                values = function()
                    return ns.ConfigValues.anchorValues
                end,
                get = function()
                    local db = ns:GetCastbarDB(unit)
                    return db and db.text and db.text.anchor or "CENTER"
                end,
                set = function(_, value)
                    local db = ns:GetCastbarDB(unit)
                    if db and db.text then
                        db.text.anchor = value
                        ns:RefreshCastbar(unit)
                    end
                end,
            },

            textX = {
                type = "input",
                name = "주문명 X",
                order = 24,
                get = function()
                    return ns:GetCastbarNestedNumber(unit, "text", "x")
                end,
                set = function(_, value)
                    ns:SetCastbarNestedNumber(unit, "text", "x", value)
                end,
            },

            textY = {
                type = "input",
                name = "주문명 Y",
                order = 25,
                get = function()
                    return ns:GetCastbarNestedNumber(unit, "text", "y")
                end,
                set = function(_, value)
                    ns:SetCastbarNestedNumber(unit, "text", "y", value)
                end,
            },

            timeEnabled = {
                type = "toggle",
                name = "시간 표시",
                order = 26,
                get = function()
                    local db = ns:GetCastbarDB(unit); return db and db.time and db.time.enabled
                end,
                set = function(_, value)
                    local db = ns:GetCastbarDB(unit); if db and db.time then
                        db.time.enabled = value; ns:RefreshCastbar(unit)
                    end
                end,
            },
        },
    }
end

function ns:CreateCastbarOptions()
    return {
        type = "group",
        name = "시전 바",
        order = 3,
        childGroups = "tree",
        args = {
            style = {
                type = "group",
                name = "스타일",
                order = 1,
                args = {
                    castColor = {
                        type = "color",
                        name = "시전 색상",
                        order = 1,
                        hasAlpha = false,
                        get = function()
                            local c = ns.db.profile.castbars.style.castColor; return c[1], c[2], c[3]
                        end,
                        set = function(_, r, g, b)
                            local c = ns.db.profile.castbars.style.castColor; c[1], c[2], c[3] = r, g, b; ns
                                :RefreshAllCastbars()
                        end,
                    },
                    channelColor = {
                        type = "color",
                        name = "채널 색상",
                        order = 2,
                        hasAlpha = false,
                        get = function()
                            local c = ns.db.profile.castbars.style.channelColor; return c[1], c[2], c[3]
                        end,
                        set = function(_, r, g, b)
                            local c = ns.db.profile.castbars.style.channelColor; c[1], c[2], c[3] = r, g, b; ns
                                :RefreshAllCastbars()
                        end,
                    },
                    nonInterruptibleColor = {
                        type = "color",
                        name = "차단 불가 색상",
                        order = 3,
                        hasAlpha = false,
                        get = function()
                            local c = ns.db.profile.castbars.style.nonInterruptibleColor; return c[1], c[2], c[3]
                        end,
                        set = function(_, r, g, b)
                            local c = ns.db.profile.castbars.style.nonInterruptibleColor; c[1], c[2], c[3] = r, g, b; ns
                                :RefreshAllCastbars()
                        end,
                    },
                    break1 = {
                        type = "description",
                        name = "\n",
                        width = "full",
                        order = 4.1,
                    },
                    showBorder = {
                        type = "toggle",
                        name = "테두리 표시",
                        order = 5,
                        get = function() return ns.db.profile.castbars.style.showBorder end,
                        set = function(_, value)
                            ns.db.profile.castbars.style.showBorder = value; ns:RefreshAllCastbars()
                        end,
                    },
                    showSpark = {
                        type = "toggle",
                        name = "스파크 표시",
                        order = 6,
                        get = function() return ns.db.profile.castbars.style.showSpark end,
                        set = function(_, value)
                            ns.db.profile.castbars.style.showSpark = value; ns:RefreshAllCastbars()
                        end,
                    },
                    bgAlpha = {
                        type = "range",
                        name = "배경 투명도",
                        order = 7,
                        min = 0,
                        max = 1,
                        step = 0.01,
                        isPercent = false,
                        get = function() return ns.db.profile.castbars.style.bgAlpha end,
                        set = function(_, value)
                            ns.db.profile.castbars.style.bgAlpha = value; ns:RefreshAllCastbars()
                        end,
                    },
                    break2 = {
                        type = "description",
                        name = "\n",
                        width = "full",
                        order = 7.1,
                    },
                    font = {
                        type = "select",
                        name = "시전바 폰트",
                        order = 8,
                        values = castbarFontValues,
                        get = function()
                            return ns.db.profile.castbars.style.font or "default"
                        end,
                        set = function(_, value)
                            ns.db.profile.castbars.style.font = value
                            if ns.Modules and ns.Modules.Castbars and ns.Modules.Castbars.RefreshAll then
                                ns.Modules.Castbars:RefreshAll()
                            end
                        end,
                    },
                },
            },
            player = { type = "group", name = "플레이어", order = 2, args = CreateCastbarGroup("player", "플레이어").args },
            target = { type = "group", name = "대상", order = 3, args = CreateCastbarGroup("target", "대상").args },
            pet    = { type = "group", name = "소환수", order = 4, args = CreateCastbarGroup("pet", "소환수").args },
        },
    }
end
