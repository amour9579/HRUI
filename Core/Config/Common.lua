local _, ns = ...

local anchorValues = ns.ConfigValues.anchorValues
local textureValues = ns.ConfigValues.textureValues
local unitFontValues = ns.ConfigValues.unitFrameFontValues

local function CreateAnchorOption(unit, group, order)
    return {
        type = "select",
        name = "기준점",
        order = order,
        values = anchorValues,
        get = function()
            return ns:GetNestedUnitValue(unit, group, "anchor")
        end,
        set = function(_, value)
            ns:SetNestedUnitValue(unit, group, "anchor", value)
        end,
    }
end

local function CreateOffsetOption(unit, group, key, name, order, minValue, maxValue)
    return {
        type = "range",
        name = name,
        order = order,
        min = minValue,
        max = maxValue,
        step = 1,
        get = function()
            return ns:GetNestedUnitValue(unit, group, key)
        end,
        set = function(_, value)
            ns:SetNestedUnitValue(unit, group, key, value)
        end,
    }
end

function ns:CreateTextPositionArgs(unit, group, startOrder, prefix)
    return {
        [prefix .. "Anchor"] = CreateAnchorOption(unit, group, startOrder),
        [prefix .. "X"] = CreateOffsetOption(unit, group, "x",
            prefix == "name" and "이름 X 오프셋" or ((prefix == "healthText") and "체력 X 오프셋" or "자원 X 오프셋"), startOrder + 1,
            -200,
            200),
        [prefix .. "Y"] = CreateOffsetOption(unit, group, "y",
            prefix == "name" and "이름 Y 오프셋" or ((prefix == "healthText") and "체력 Y 오프셋" or "자원 Y 오프셋"), startOrder + 2,
            -100,
            100),
    }
end

function ns:CreateGeneralOptions()
    return {
        type = "group",
        name = "일반",
        order = 1,
        args = {
            moveHeader = {
                type = "header",
                name = "이동 모드",
                order = 1
            },

            toggleMoveMode = {
                type = "execute",
                order = 2,
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

            moverHeader = {
                type = "header",
                name = "격자 / 스냅",
                order = 10
            },

            gridSize = {
                type = "range",
                name = "격자 크기",
                order = 11,
                min = 4,
                max = 64,
                step = 1,
                get = function() return ns.db.profile.movers.gridSize end,
                set = function(_, value)
                    ns.db.profile.movers.gridSize = value
                    if ns.Movers and ns.Movers.RefreshGrid then ns.Movers:RefreshGrid() end
                end,
            },
            snapDistance = {
                type = "range",
                name = "스냅 거리",
                order = 12,
                min = 1,
                max = 32,
                step = 1,
                get = function() return ns.db.profile.movers.snapDistance end,
                set = function(_, value) ns.db.profile.movers.snapDistance = value end,
            },
            fineStep = {
                type = "range",
                name = "Shift 미세 이동 폭",
                order = 13,
                min = 1,
                max = 20,
                step = 1,
                get = function() return ns.db.profile.movers.fineStep end,
                set = function(_, value) ns.db.profile.movers.fineStep = value end,
            },
        },
    }
end

function ns:CreateUnitFrameAppearanceOptions()
    return {
        type = "group",
        name = "텍스처 및 폰트",
        order = 1,
        args = {
            texture = {
                type = "select",
                name = "프레임 텍스처",
                order = 1,
                values = textureValues,
                get = function() return ns.db.profile.general.texture end,
                set = function(_, value)
                    ns.db.profile.general.texture = value
                    ns:RefreshAllUnits()
                end,
            },
            texturePreview = {
                type = "execute",
                name = "미리보기",
                order = 2,
                func = function()
                    if ns.ToggleTexturePreviewPanel then
                        ns:ToggleTexturePreviewPanel()
                    end
                end,
            },

            enabled = {
                type = "toggle",
                name = "테두리 사용",
                order = 3,
                width = "full",
                get = function()
                    return ns.db.profile.borders and ns.db.profile.borders.enabled ~= false
                end,
                set = function(_, value)
                    ns.db.profile.borders = ns.db.profile.borders or {}
                    ns.db.profile.borders.enabled = value
                    ns:RefreshAllUnits()
                end,
            },
            desc = {
                type = "description",
                name = "테두리 표시를 켜거나 끕니다. 즉시 반영되지 않으면 /reload 해주세요.",
                order = 4,
                width = "full",
            },
            color = {
                type = "color",
                name = "테두리 기본 색상",
                order = 5,
                hasAlpha = true,
                get = function()
                    local c = ns.db.profile.borders and ns.db.profile.borders.color or { 0.20, 0.20, 0.20, 1.00 }
                    return c[1], c[2], c[3], c[4] or 1
                end,
                set = function(_, r, g, b, a)
                    ns.db.profile.borders = ns.db.profile.borders or {}
                    local c = ns.db.profile.borders.color or {}
                    c[1], c[2], c[3], c[4] = r, g, b, a or 1
                    ns.db.profile.borders.color = c
                    ns:RefreshAllUnits()
                end,
            },
            hoverColor = {
                type = "color",
                name = "마우스 오버 하이라이트 색상",
                order = 6,
                hasAlpha = true,
                get = function()
                    local c = ns.db.profile.borders and ns.db.profile.borders.hoverColor or { 0.90, 0.90, 0.90, 0.80 }
                    return c[1], c[2], c[3], c[4] or 0.8
                end,
                set = function(_, r, g, b, a)
                    ns.db.profile.borders = ns.db.profile.borders or {}
                    local c = ns.db.profile.borders.hoverColor or {}
                    c[1], c[2], c[3], c[4] = r, g, b, a or 0.8
                    ns.db.profile.borders.hoverColor = c
                    ns:RefreshAllUnits()
                end,
            },

            fontHeader = {
                type = "header",
                name = "폰트",
                order = 10,
            },

            nameFont = {
                type = "select",
                name = "이름 폰트",
                order = 11,
                values = unitFontValues,
                get = function()
                    return ns.db.profile.unitframes.appearance.nameFont or "default"
                end,
                set = function(_, value)
                    ns.db.profile.unitframes.appearance.nameFont = value
                    ns:RefreshAllUnits()
                end,
            },

            healthFont = {
                type = "select",
                name = "체력 폰트",
                order = 12,
                values = unitFontValues,
                get = function()
                    return ns.db.profile.unitframes.appearance.healthFont or "default"
                end,
                set = function(_, value)
                    ns.db.profile.unitframes.appearance.healthFont = value
                    ns:RefreshAllUnits()
                end,
            },

            healthDecimalMode = {
                type = "select",
                name = "체력 텍스트 소수점",
                order = 13,
                values = healthDecimalModeValues,
                get = function()
                    return ns.db.profile.unitframes.appearance.healthDecimalMode or "one"
                end,
                set = function(_, value)
                    if value ~= "one" and value ~= "zero" and value ~= "auto" then
                        value = "one"
                    end

                    ns.db.profile.unitframes.appearance.healthDecimalMode = value
                    ns:RefreshAllUnits()
                end,
            },
            powerFont = {
                type = "select",
                name = "자원 폰트",
                order = 14,
                values = unitFontValues,
                get = function()
                    return ns.db.profile.unitframes.appearance.powerFont or "default"
                end,
                set = function(_, value)
                    ns.db.profile.unitframes.appearance.powerFont = value
                    ns:RefreshAllUnits()
                end,
            },
        },
    }
end
