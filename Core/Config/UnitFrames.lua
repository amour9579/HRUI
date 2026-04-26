local _, ns = ...

local anchorValues = ns.ConfigValues.anchorValues
local healthFormatValues = ns.ConfigValues.healthFormatValues
local powerFormatValues = ns.ConfigValues.powerFormatValues
local nameFormatValues = ns.ConfigValues.nameFormatValues
local buffAnchorValues = {
    TOPLEFT = "좌상",
    TOP = "상",
    TOPRIGHT = "우상",
    LEFT = "좌",
    CENTER = "중앙",
    RIGHT = "우",
    BOTTOMLEFT = "좌하",
    BOTTOM = "하",
    BOTTOMRIGHT = "우하",
}
local buffGrowthValues = {
    LEFT = "왼쪽",
    RIGHT = "오른쪽",
}

local function AddArgs(target, source)
    for key, value in pairs(source) do
        target[key] = value
    end
end

local function CreatePlayerIconArgs()
    local function GetIconValue(icon, key)
        return ns.db.profile.unitframes.player.icons[icon][key]
    end

    local function SetIconValue(icon, key, value)
        ns.db.profile.unitframes.player.icons[icon][key] = value

        if ns.RefreshUnit then
            ns:RefreshUnit("player")
        end

        if ns.PlayerFrame and ns.UpdatePlayerIcons then
            ns:UpdatePlayerIcons(ns.PlayerFrame)
        end
    end

    local function CreateIconGroup(order, label, iconKey)
        return {
            type = "group",
            name = label,
            inline = true,
            order = order,
            args = {
                enabled = {
                    type = "toggle",
                    name = "표시",
                    order = 1,
                    get = function() return GetIconValue(iconKey, "enabled") end,
                    set = function(_, value) SetIconValue(iconKey, "enabled", value) end,
                },
                size = {
                    type = "range",
                    name = "크기",
                    order = 2,
                    min = 8,
                    max = 64,
                    step = 1,
                    get = function() return GetIconValue(iconKey, "size") end,
                    set = function(_, value) SetIconValue(iconKey, "size", value) end,
                },
                anchor = {
                    type = "select",
                    name = "기준점",
                    order = 3,
                    values = anchorValues,
                    get = function() return GetIconValue(iconKey, "anchor") end,
                    set = function(_, value) SetIconValue(iconKey, "anchor", value) end,
                },
                x = {
                    type = "range",
                    name = "X",
                    order = 4,
                    min = -200,
                    max = 200,
                    step = 1,
                    get = function() return GetIconValue(iconKey, "x") end,
                    set = function(_, value) SetIconValue(iconKey, "x", value) end,
                },
                y = {
                    type = "range",
                    name = "Y",
                    order = 5,
                    min = -200,
                    max = 200,
                    step = 1,
                    get = function() return GetIconValue(iconKey, "y") end,
                    set = function(_, value) SetIconValue(iconKey, "y", value) end,
                },
            },
        }
    end

    return {
        iconsHeader = { type = "header", name = "상태 아이콘", order = 50 },

        iconsEnabled = {
            type = "toggle",
            name = "상태 아이콘 사용",
            order = 51,
            get = function() return ns.db.profile.unitframes.player.icons.enabled end,
            set = function(_, value)
                ns.db.profile.unitframes.player.icons.enabled = value
                if ns.RefreshUnit then
                    ns:RefreshUnit("player")
                end
            end,
        },

        restIcon = CreateIconGroup(52, "휴식", "rest"),
        combatIcon = CreateIconGroup(53, "전투", "combat"),
        leaderIcon = CreateIconGroup(54, "파티장", "leader"),
        assistantIcon = CreateIconGroup(55, "어시스트", "assistant"),
    }
end

local function CreateUnitGroup(unit, label)
    local args = {
        enabled = {
            type = "toggle",
            name = "표시",
            order = 1,
            get = function() return ns:GetUnitValue(unit, "enabled") end,
            set = function(_, value) ns:SetUnitValue(unit, "enabled", value) end,
        },
        move = {
            type = "execute",
            order = 1.1,
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
        break4 = {
            type = "description",
            name = "\n",
            width = "full",
            order = 1.2,
        },
        width = {
            type = "range",
            name = "너비",
            order = 2,
            min = 80,
            max = 600,
            step = 1,
            get = function() return ns:GetUnitValue(unit, "width") end,
            set = function(_, value) ns:SetUnitValue(unit, "width", value) end,
        },
        height = {
            type = "range",
            name = "높이",
            order = 3,
            min = 10,
            max = 100,
            step = 1,
            get = function() return ns:GetUnitValue(unit, "height") end,
            set = function(_, value) ns:SetUnitValue(unit, "height", value) end,
        },
        x = {
            type = "range",
            name = "중앙 기준 X",
            order = 4,
            min = -1000,
            max = 1000,
            step = 1,
            get = function() return ns:GetUnitValue(unit, "x") end,
            set = function(_, value) ns:SetUnitValue(unit, "x", value) end,
        },

        y = {
            type = "range",
            name = "중앙 기준 Y",
            order = 5,
            min = -1000,
            max = 1000,
            step = 1,
            get = function() return ns:GetUnitValue(unit, "y") end,
            set = function(_, value) ns:SetUnitValue(unit, "y", value) end,
        },

        bossSpacing = {
            type = "range",
            name = "보스 프레임 간격",
            order = 6,
            min = 0,
            max = 50,
            step = 1,
            hidden = function() return unit ~= "boss" end,
            get = function() return ns:GetUnitValue(unit, "spacing") or 8 end,
            set = function(_, value) ns:SetUnitValue(unit, "spacing", value) end,
        },

        nameHeader = { type = "header", name = "이름", order = 10 },
        nameFormat = {
            type = "select",
            name = "이름 표시 방식",
            order = 10.5,
            values = nameFormatValues,
            get = function() return ns:GetNestedUnitValue(unit, "name", "format") end,
            set = function(_, value) ns:SetNestedUnitValue(unit, "name", "format", value) end,
        },

        nameFontSize = {
            type = "range",
            name = "이름 글자 크기",
            order = 12,
            min = 6,
            max = 32,
            step = 1,
            get = function()
                return ns:GetNestedUnitValue(unit, "name", "fontSize") or 12
            end,
            set = function(_, value)
                ns:SetNestedUnitValue(unit, "name", "fontSize", value)
            end,
        },

        break1 = {
            type = "description",
            name = "\n",
            width = "full",
            order = 12.1,
        },

        powerHeader = { type = "header", name = "자원바", order = 20 },
        powerEnabled = {
            type = "toggle",
            name = "자원바 사용",
            order = 21,
            get = function() return ns:GetNestedUnitValue(unit, "power", "enabled") end,
            set = function(_, value) ns:SetNestedUnitValue(unit, "power", "enabled", value) end,
        },
        powerHeight = {
            type = "range",
            name = "자원바 높이",
            order = 22,
            min = 4,
            max = 20,
            step = 1,
            get = function() return ns:GetNestedUnitValue(unit, "power", "height") end,
            set = function(_, value) ns:SetNestedUnitValue(unit, "power", "height", value) end,
        },

        powerTextHeader = { type = "header", name = "자원 텍스트", order = 23 },
        powerTextEnabled = {
            type = "toggle",
            name = "자원 텍스트 표시",
            order = 24,
            get = function() return ns:GetNestedUnitValue(unit, "powerText", "enabled") end,
            set = function(_, value) ns:SetNestedUnitValue(unit, "powerText", "enabled", value) end,
        },
        powerTextFormat = {
            type = "select",
            name = "자원 표시 방식",
            order = 25,
            values = powerFormatValues,
            get = function() return ns:GetNestedUnitValue(unit, "powerText", "format") end,
            set = function(_, value) ns:SetNestedUnitValue(unit, "powerText", "format", value) end,
        },
        
        powerTextFontSize = {
            type = "range",
            name = "자원 글자 크기",
            order = 25.2,
            min = 6,
            max = 32,
            step = 1,
            get = function()
                return ns:GetNestedUnitValue(unit, "powerText", "fontSize") or 10
            end,
            set = function(_, value)
                ns:SetNestedUnitValue(unit, "powerText", "fontSize", value)
            end,
        },

        break2 = {
            type = "description",
            name = "\n",
            width = "full",
            order = 25.3,
        },

        healthTextHeader = { type = "header", name = "체력 텍스트", order = 30 },
        healthTextEnabled = {
            type = "toggle",
            name = "체력 텍스트 표시",
            order = 31,
            get = function() return ns:GetNestedUnitValue(unit, "healthText", "enabled") end,
            set = function(_, value) ns:SetNestedUnitValue(unit, "healthText", "enabled", value) end,
        },
        healthTextFormat = {
            type = "select",
            name = "체력 표시 방식",
            order = 32,
            values = healthFormatValues,
            get = function()
                local value = ns:GetNestedUnitValue(unit, "healthText", "format")
                if value ~= "value" and value ~= "valueMax" then
                    return "value"
                end
                return value
            end,
            set = function(_, value)
                if value ~= "value" and value ~= "valueMax" then
                    value = "value"
                end
                ns:SetNestedUnitValue(unit, "healthText", "format", value)
            end,
        },
        
        healthTextFontSize = {
            type = "range",
            name = "체력 글자 크기",
            order = 32.2,
            min = 6,
            max = 32,
            step = 1,
            get = function()
                return ns:GetNestedUnitValue(unit, "healthText", "fontSize") or 11
            end,
            set = function(_, value)
                ns:SetNestedUnitValue(unit, "healthText", "fontSize", value)
            end,
        },

        break3 = {
            type = "description",
            name = "\n",
            width = "full",
            order = 32.3,
        },
        buffsHeader = { type = "header", name = "버프", order = 40 },
        buffsEnabled = {
            type = "toggle",
            name = "버프 표시",
            order = 41,
            get = function() return ns:GetNestedUnitValue(unit, "buffs", "enabled") end,
            set = function(_, value) ns:SetNestedUnitValue(unit, "buffs", "enabled", value) end,
        },
        buffsSize = {
            type = "range",
            name = "아이콘 크기",
            order = 43,
            min = 10,
            max = 48,
            step = 1,
            get = function() return ns:GetNestedUnitValue(unit, "buffs", "size") or 18 end,
            set = function(_, value) ns:SetNestedUnitValue(unit, "buffs", "size", value) end,
        },
        buffsMax = {
            type = "range",
            name = "최대 아이콘 수",
            order = 44,
            min = 1,
            max = 20,
            step = 1,
            get = function() return ns:GetNestedUnitValue(unit, "buffs", "maxIcons") or 8 end,
            set = function(_, value) ns:SetNestedUnitValue(unit, "buffs", "maxIcons", value) end,
        },
        buffsSpacing = {
            type = "range",
            name = "아이콘 간격",
            order = 45,
            min = 0,
            max = 12,
            step = 1,
            get = function() return ns:GetNestedUnitValue(unit, "buffs", "spacing") or 2 end,
            set = function(_, value) ns:SetNestedUnitValue(unit, "buffs", "spacing", value) end,
        },
        buffsAnchor = {
            type = "select",
            name = "기준점",
            order = 46,
            values = buffAnchorValues,
            get = function() return ns:GetNestedUnitValue(unit, "buffs", "anchor") or "TOPRIGHT" end,
            set = function(_, value) ns:SetNestedUnitValue(unit, "buffs", "anchor", value) end,
        },
        buffsGrowth = {
            type = "select",
            name = "증가 방향",
            order = 47,
            values = buffGrowthValues,
            get = function() return ns:GetNestedUnitValue(unit, "buffs", "growth") or "LEFT" end,
            set = function(_, value) ns:SetNestedUnitValue(unit, "buffs", "growth", value) end,
        },
        buffsX = {
            type = "range",
            name = "버프 X",
            order = 48,
            min = -200,
            max = 200,
            step = 1,
            get = function() return ns:GetNestedUnitValue(unit, "buffs", "x") or 0 end,
            set = function(_, value) ns:SetNestedUnitValue(unit, "buffs", "x", value) end,
        },
        buffsY = {
            type = "range",
            name = "버프 Y",
            order = 49,
            min = -200,
            max = 200,
            step = 1,
            get = function() return ns:GetNestedUnitValue(unit, "buffs", "y") or 0 end,
            set = function(_, value) ns:SetNestedUnitValue(unit, "buffs", "y", value) end,
        },

        debuffsHeader = { type = "header", name = "디버프", order = 60 },
        debuffsEnabled = {
            type = "toggle",
            name = "디버프 표시",
            order = 61,
            get = function() return ns:GetNestedUnitValue(unit, "debuffs", "enabled") end,
            set = function(_, value) ns:SetNestedUnitValue(unit, "debuffs", "enabled", value) end,
        },
        debuffsSize = {
            type = "range",
            name = "아이콘 크기",
            order = 63,
            min = 10,
            max = 48,
            step = 1,
            get = function() return ns:GetNestedUnitValue(unit, "debuffs", "size") or 18 end,
            set = function(_, value) ns:SetNestedUnitValue(unit, "debuffs", "size", value) end,
        },
        debuffsMax = {
            type = "range",
            name = "최대 아이콘 수",
            order = 64,
            min = 1,
            max = 20,
            step = 1,
            get = function() return ns:GetNestedUnitValue(unit, "debuffs", "maxIcons") or 8 end,
            set = function(_, value) ns:SetNestedUnitValue(unit, "debuffs", "maxIcons", value) end,
        },
        debuffsSpacing = {
            type = "range",
            name = "아이콘 간격",
            order = 65,
            min = 0,
            max = 12,
            step = 1,
            get = function() return ns:GetNestedUnitValue(unit, "debuffs", "spacing") or 2 end,
            set = function(_, value) ns:SetNestedUnitValue(unit, "debuffs", "spacing", value) end,
        },
        debuffsAnchor = {
            type = "select",
            name = "기준점",
            order = 66,
            values = buffAnchorValues,
            get = function() return ns:GetNestedUnitValue(unit, "debuffs", "anchor") or "TOPLEFT" end,
            set = function(_, value) ns:SetNestedUnitValue(unit, "debuffs", "anchor", value) end,
        },
        debuffsGrowth = {
            type = "select",
            name = "증가 방향",
            order = 67,
            values = buffGrowthValues,
            get = function() return ns:GetNestedUnitValue(unit, "debuffs", "growth") or "RIGHT" end,
            set = function(_, value) ns:SetNestedUnitValue(unit, "debuffs", "growth", value) end,
        },
        debuffsX = {
            type = "range",
            name = "디버프 X",
            order = 68,
            min = -200,
            max = 200,
            step = 1,
            get = function() return ns:GetNestedUnitValue(unit, "debuffs", "x") or 0 end,
            set = function(_, value) ns:SetNestedUnitValue(unit, "debuffs", "x", value) end,
        },
        debuffsY = {
            type = "range",
            name = "디버프 Y",
            order = 69,
            min = -200,
            max = 200,
            step = 1,
            get = function() return ns:GetNestedUnitValue(unit, "debuffs", "y") or 0 end,
            set = function(_, value) ns:SetNestedUnitValue(unit, "debuffs", "y", value) end,
        },
    }

    AddArgs(args, ns:CreateTextPositionArgs(unit, "name", 13, "name"))
    AddArgs(args, ns:CreateTextPositionArgs(unit, "powerText", 26, "powerText"))
    AddArgs(args, ns:CreateTextPositionArgs(unit, "healthText", 33, "healthText"))
    if unit == "player" then
        AddArgs(args, CreatePlayerIconArgs())
    end

    return {
        type = "group",
        name = label,
        args = args,
    }
end

function ns:CreateUnitFrameOptions()
    return {
        type = "group",
        name = "유닛프레임",
        order = 2,
        childGroups = "tree",
        args = {
            appearance = ns:CreateUnitFrameAppearanceOptions(),
            player = { type = "group", name = "플레이어", order = 2, args = CreateUnitGroup("player", "플레이어").args },
            target = { type = "group", name = "타겟", order = 3, args = CreateUnitGroup("target", "타겟").args },
            targettarget = { type = "group", name = "대상의 대상", order = 4, args = CreateUnitGroup("targettarget", "대상의 대상").args },
            focus = { type = "group", name = "주시", order = 5, args = CreateUnitGroup("focus", "주시").args },
            boss = { type = "group", name = "보스", order = 6, args = CreateUnitGroup("boss", "보스").args },
            pet = { type = "group", name = "펫", order = 7, args = CreateUnitGroup("pet", "펫").args },
        },
    }
end
