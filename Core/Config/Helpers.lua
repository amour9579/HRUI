local _, ns = ...

local function GetRoot(path1, path2, path3)
    local db = ns.db and ns.db.profile
    if not db then return nil end
    db = path1 and db[path1] or db
    db = path2 and db and db[path2] or db
    db = path3 and db and db[path3] or db
    return db
end

function ns:GetUnitDB(unit)
    return GetRoot("unitframes", unit)
end

function ns:GetCastbarDB(unit)
    return GetRoot("castbars", unit)
end

local defaultCastbarColors = {
    castColor = { 0.95, 0.75, 0.20 },
    channelColor = { 0.20, 0.70, 1.00 },
    nonInterruptibleColor = { 0.75, 0.20, 0.20 },
}

local function GetCastbarStyleDB()
    return GetRoot("castbars", "style")
end

function ns:GetCastbarUnitColor(unit, colorKey)
    local unitDB = ns:GetCastbarDB(unit)
    local unitColors = unitDB and unitDB.colors
    local unitColor = unitColors and unitColors[colorKey]

    if type(unitColor) == "table" then
        return unitColor
    end

    local styleDB = GetCastbarStyleDB()
    local legacyColor = styleDB and styleDB[colorKey]

    if type(legacyColor) == "table" then
        return legacyColor
    end

    return defaultCastbarColors[colorKey] or { 1, 1, 1 }
end

function ns:SetCastbarUnitColor(unit, colorKey, r, g, b)
    local unitDB = ns:GetCastbarDB(unit)
    if not unitDB or not defaultCastbarColors[colorKey] then
        return
    end

    unitDB.colors = unitDB.colors or {}
    local color = unitDB.colors[colorKey]

    if type(color) ~= "table" then
        color = {}
        unitDB.colors[colorKey] = color
    end

    color[1], color[2], color[3] = r, g, b
    ns:RefreshCastbar(unit)
end

function ns:GetCastbarStyle(unit)
    local styleDB = GetCastbarStyleDB()

    return {
        cast = ns:GetCastbarUnitColor(unit, "castColor"),
        channel = ns:GetCastbarUnitColor(unit, "channelColor"),
        nonInterruptible = ns:GetCastbarUnitColor(unit, "nonInterruptibleColor"),
        bg = { 0.08, 0.08, 0.08, (styleDB and styleDB.bgAlpha) or 0.90 },
        border = { 0.20, 0.20, 0.20, 1.00 },
        text = { 1.00, 1.00, 1.00 },
        showBorder = (styleDB and styleDB.showBorder) ~= false,
        showSpark = (styleDB and styleDB.showSpark) ~= false,
    }
end

function ns:RefreshUnit(unit)
    if ns.Modules.UnitFrames and ns.Modules.UnitFrames.RefreshUnit then
        ns.Modules.UnitFrames:RefreshUnit(unit)
    end
end

function ns:RefreshAllUnits()
    if ns.Modules.UnitFrames and ns.Modules.UnitFrames.RefreshAll then
        ns.Modules.UnitFrames:RefreshAll()
    end
end

function ns:RefreshCastbar(unit)
    if ns.Modules.Castbars and ns.Modules.Castbars.RefreshBar then
        ns.Modules.Castbars:RefreshBar(unit)
    end
end

function ns:RefreshAllCastbars()
    if ns.Modules.Castbars and ns.Modules.Castbars.RefreshAll then
        ns.Modules.Castbars:RefreshAll()
    end
end

function ns:GetUnitValue(unit, key)
    local db = ns:GetUnitDB(unit)
    return db and db[key]
end

function ns:SetUnitValue(unit, key, value)
    local db = ns:GetUnitDB(unit)
    if not db then return end
    db[key] = value
    ns:RefreshUnit(unit)
end

function ns:GetNestedUnitValue(unit, group, key)
    local db = ns:GetUnitDB(unit)
    return db and db[group] and db[group][key]
end

function ns:SetNestedUnitValue(unit, group, key, value)
    local db = ns:GetUnitDB(unit)
    if not db then return end
    db[group] = db[group] or {}
    db[group][key] = value
    ns:RefreshUnit(unit)
end

function ns:GetCastbarNumber(unit, key)
    local db = ns:GetCastbarDB(unit)
    local value = db and db[key]
    return tostring(value or 0)
end

function ns:SetCastbarNumber(unit, key, value)
    local db = ns:GetCastbarDB(unit)
    if not db then return end
    local num = tonumber(value)
    if not num then return end
    num = math.floor(num + 0.5)

    if key == "width" then
        num = math.max(80, math.min(600, num))
    elseif key == "height" then
        num = math.max(8, math.min(60, num))
    elseif key == "x" or key == "y" then
        num = math.max(-1000, math.min(1000, num))
    end

    db[key] = num
    ns:RefreshCastbar(unit)
end

function ns:GetCastbarNestedNumber(unit, group, key)
    local db = ns:GetCastbarDB(unit)
    local value = db and db[group] and db[group][key]
    return tostring(value or 0)
end

function ns:SetCastbarNestedNumber(unit, group, key, value)
    local db = ns:GetCastbarDB(unit)
    if not db or not db[group] then return end
    local num = tonumber(value)
    if not num then return end
    num = math.floor(num + 0.5)

    if group == "icon" and key == "size" then
        num = math.max(8, math.min(64, num))
    end

    db[group][key] = num
    ns:RefreshCastbar(unit)
end
