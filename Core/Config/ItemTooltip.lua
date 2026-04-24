local _, ns = ...

local CVAR_ALWAYS_COMPARE_ITEMS = "alwaysCompareItems"

local function GetItemTooltipDB()
    ns.db.profile.itemTooltip = ns.db.profile.itemTooltip or {}

    local db = ns.db.profile.itemTooltip
    if db.alwaysCompareItems == nil then
        db.alwaysCompareItems = false
    end

    return db
end

local function SetAlwaysCompareItems(enabled)
    local value = enabled and "1" or "0"

    if C_CVar and C_CVar.SetCVar then
        C_CVar.SetCVar(CVAR_ALWAYS_COMPARE_ITEMS, value)
    elseif SetCVar then
        SetCVar(CVAR_ALWAYS_COMPARE_ITEMS, value)
    end
end

function ns:ApplyItemTooltipCVar()
    if not ns.db or not ns.db.profile then
        return
    end

    local db = GetItemTooltipDB()
    SetAlwaysCompareItems(db.alwaysCompareItems)
end

function ns:CreateItemTooltipOptions()
    return {
        type = "group",
        name = "아이템 툴팁",
        order = 5,
        args = {
            header = {
                type = "header",
                name = "아이템 비교 툴팁",
                order = 1,
            },

            alwaysCompareItems = {
                type = "toggle",
                name = "아이템 비교 툴팁 켜기",
                desc = "끄면 Shift 키를 누를 때만 비교 툴팁이 표시됩니다.",
                order = 2,
                width = "full",
                get = function()
                    return GetItemTooltipDB().alwaysCompareItems
                end,
                set = function(_, value)
                    GetItemTooltipDB().alwaysCompareItems = value and true or false
                    ns:ApplyItemTooltipCVar()
                end,
            },

            help = {
                type = "description",
                name = "아이템에 마우스를 올렸을 때 장착 중인 아이템과 비교하는 툴팁을 켜거나 끕니다.\n끄면 Shift 키를 누를 때만 비교 툴팁이 표시됩니다.",
                order = 3,
                width = "full",
            },
        },
    }
end
