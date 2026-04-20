local _, ns = ...

ns.ConfigValues = ns.ConfigValues or {}

function ns:GetCastbarFontPath(fontKey)
    if not fontKey or fontKey == "default" then
        return STANDARD_TEXT_FONT
    end

    if fontKey == "2002" then
        return "Fonts\\2002.ttf"
    elseif fontKey == "2002B" then
        return "Fonts\\2002B.ttf"
    elseif fontKey == "K_Damage" then
        return "Fonts\\K_Damage.ttf"
    end

    return "Interface\\AddOns\\HRUI\\Media\\Fonts\\" .. fontKey .. ".ttf"
end

function ns:GetUnitFontPath(fontKey)
    if not fontKey or fontKey == "default" then
        return STANDARD_TEXT_FONT
    end

    if fontKey == "2002" then
        return "Fonts\\2002.ttf"
    elseif fontKey == "2002B" then
        return "Fonts\\2002B.ttf"
    elseif fontKey == "K_Damage" then
        return "Fonts\\K_Damage.ttf"
    end

    return "Interface\\AddOns\\HRUI\\Media\\Fonts\\" .. fontKey .. ".ttf"
end

ns.ConfigValues.unitFrameFontValues = {
    default = "기본",
    ["2002"] = "2002",
    ["2002B"] = "2002 Bold",
    ["K_Damage"] = "데미지 글꼴",
    ["GmarketSansTTFBold"] = "G마켓 산스",
    ["ChosunCentennial_ttf"] = "조선 굴림체",
    ["Maplestory Light"] = "넥슨 메이플",
    ["ActionMan"] = "ActionMan",
}

ns.ConfigValues.anchorValues = {
    LEFT = "좌",
    CENTER = "가운데",
    RIGHT = "우",
}

ns.ConfigValues.castbarFontValues = {
    default = "기본",
    ["2002"] = "2002",
    ["2002B"] = "2002 Bold",
    ["K_Damage"] = "데미지 글꼴",
    ["GmarketSansTTFBold"] = "G마켓 산스",
    ["ChosunCentennial_ttf"] = "조선 굴림체",
    ["Maplestory Light"] = "넥슨 메이플",
    ["ActionMan"] = "ActionMan",
}

ns.ConfigValues.healthFormatValues = {
    value = "현재값",
    valueMax = "현재/최대",
}

ns.ConfigValues.powerFormatValues = {
    value = "현재값",
    valueMax = "현재/최대",
}

ns.ConfigValues.nameFormatValues = {
    name = "이름",
    levelName = "레벨 + 이름",
}

ns.ConfigValues.textureValues = {
    default = "Default",
    smooth = "Smooth",
    aluminium  = "Aluminium",
    diagonal   = "Diagonal",
    glowTex    = "ElvUI GlowBorder",
    melli      = "Melli",
    minimalist = "Minimalist",
    normTex    = "ElvUI Gloss",
    normTex2   = "ElvUI Norm",
    normTex3   = "ElvUI Norm1",
    rocks      = "Rocks",
    striped    = "Striped",
}

ns.Defaults = {
    profile = {
        general = {
            font = "Fonts\\2002.ttf",
            texture = "default",
        },

        movers = {
            gridSize = 20,
            snapDistance = 8,
            fineStep = 2,
        },

        actionbars = {
            skin = true,
            font = "default",
            fontOutline = "OUTLINE",
            hotkeyFontSize = 11,
            macroFontSize = 10,
            countFontSize = 11,
            showMacroName = false,
            hideBagBar = false,
            hideMicroMenu = false,
        },

        chat = {
            enabled = true,

            infoBar = {
                enabled = true,
                width = 483,
                height = 28,
                alpha = 0.8,
                outerPadding = 40,
                backdrop = true,
                x = 0,
                y = 0,

                slotCount = 5,
                slots = {
                    slots1 = "TIME",
                    slots2 = "GUILD",
                    slots3 = "FRIENDS",
                    slots4 = "SPEC",
                    slots5 = "MPLUS",
                },
            },

            combatMessage = {
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
            },
        },

        mythicPlusReporter = {
            enabled = true,
        },

        dice = {
            enabled = true,
            delay = 5,
            autoRoll = 1,
            hideInDungeons = false,
        },


        unitframes = {
            enabled = true,

            appearance = {
                nameFont = "default",
                healthFont = "default",
                powerFont = "default",
            },

            player = {

                enabled = true,
                width = 220,
                height = 45,
                x = -285,
                y = -250,
                power = { enabled = true, height = 6, },
                name = { anchor = "LEFT", x = 8, y = 0, format = "levelName", fontSize = 12, },
                healthText = { enabled = true, anchor = "RIGHT", x = -8, y = 0, format = "value", fontSize = 11, },
                powerText = { enabled = false, anchor = "CENTER", x = 0, y = 0, format = "value", fontSize = 10, },
                buffs = { enabled = false, size = 20, spacing = 2, maxIcons = 8, anchor = "TOPLEFT", x = 0, y = 6, growth = "RIGHT", },
                icons = {
                    enabled = true,
                    rest = { enabled = true, size = 20, anchor = "LEFT", x = 0, y = 25, },
                    combat = { enabled = true, size = 25, anchor = "CENTER", x = 0, y = 30, },
                    leader = { enabled = true, size = 16, anchor = "RIGHT", x = 0, y = 25, },
                    assistant = { enabled = true, size = 16, anchor = "RIGHT", x = -15, y = 25, },
                },
            },

            target = {
                enabled = true,
                width = 220,
                height = 45,
                x = 285,
                y = -250,
                power = { enabled = true, height = 6, },
                name = { anchor = "LEFT", x = 8, y = 0, format = "levelName", fontSize = 12, },
                healthText = { enabled = true, anchor = "RIGHT", x = -8, y = 0, format = "value", fontSize = 11, },
                powerText = { enabled = false, anchor = "CENTER", x = 0, y = 0, format = "value", fontSize = 10, },
                buffs = { enabled = false, size = 20, spacing = 2, maxIcons = 8, anchor = "TOPRIGHT", x = 0, y = 6, growth = "LEFT", },
            },

            targettarget = {
                enabled = true,
                width = 160,
                height = 30,
                x = 0,
                y = -255,
                power = { enabled = false, height = 6, },
                name = { anchor = "CENTER", x = 0, y = 0, format = "levelName", fontSize = 12, },
                healthText = { enabled = false, anchor = "RIGHT", x = -6, y = 0, format = "value", fontSize = 11, },
                powerText = { enabled = false, anchor = "CENTER", x = 0, y = 0, format = "value", fontSize = 10, },
                buffs = { enabled = false, size = 16, spacing = 2, maxIcons = 6, anchor = "TOP", x = 0, y = 4, growth = "RIGHT", },
            },

            focus = {
                enabled = true,
                width = 160,
                height = 45,
                x = 560,
                y = 195,
                power = { enabled = true, height = 6, },
                name = { anchor = "CENTER", x = 0, y = 0, format = "levelName", fontSize = 12, },
                healthText = { enabled = false, anchor = "RIGHT", x = -3, y = 0, format = "value", fontSize = 11, },
                powerText = { enabled = false, anchor = "CENTER", x = 0, y = 0, format = "value", fontSize = 10, },
                buffs = { enabled = false, size = 16, spacing = 2, maxIcons = 6, anchor = "TOPRIGHT", x = 0, y = 4, growth = "LEFT", },
            },

            pet = {
                enabled = true,
                width = 180,
                height = 25,
                x = -305,
                y = -300,
                power = { enabled = true, height = 4, },
                name = { anchor = "LEFT", x = 6, y = 0, format = "name", fontSize = 12, },
                healthText = { enabled = true, anchor = "RIGHT", x = -6, y = 0, format = "value", fontSize = 11, },
                powerText = { enabled = false, anchor = "CENTER", x = 0, y = 0, format = "value", fontSize = 10, },
                buffs = { enabled = false, size = 14, spacing = 2, maxIcons = 6, anchor = "TOPLEFT", x = 0, y = 4, growth = "RIGHT", },
            },
        },

        config = {
            window = {
                width = 1200,
                height = 600,
                top = nil,
                left = nil,
            },
        },

        borders = {
            enabled = true,
            color = { 0.20, 0.20, 0.20, 1.00 },
            hoverColor = { 0.90, 0.90, 0.90, 0.80 },
        },

        castbars = {
            style = {
                castColor = { 0.95, 0.75, 0.20 },
                channelColor = { 0.20, 0.70, 1.00 },
                nonInterruptibleColor = { 0.75, 0.20, 0.20 },
                bgAlpha = 0.90,
                showBorder = true,
                showSpark = true,
                font = "default",
            },

            player = {
                enabled = true,
                width = 260,
                height = 30,
                x = 15,
                y = -300,
                icon = { enabled = true, size = 30, },
                text = {
                    enabled = true,
                    anchor = "CENTER",
                    x = 0,
                    y = 0,
                },
                time = { enabled = true, },
            },

            target = {
                enabled = true,
                width = 350,
                height = 30,
                x = 18,
                y = 380,
                icon = { enabled = true, size = 30, },
                text = {
                    enabled = true,
                    anchor = "CENTER",
                    x = 0,
                    y = 0,
                },
                time = { enabled = true, },
            },
            pet = {
                enabled = true,
                width = 158,
                height = 18,
                x = -295,
                y = -330,
                icon = { enabled = true, size = 18, },
                text = {
                    enabled = true,
                    anchor = "CENTER",
                    x = 0,
                    y = 0,
                },
                time = { enabled = true, },
            },
        },
    },
}
