local _, ns = ...

local function NormalizeNumber(value)
    if value == nil then
        return 0
    end

    local n = tonumber(tostring(value))
    if not n then
        return 0
    end

    return n
end

local function GetFormattedUnitName(unitToken)
    if not UnitExists(unitToken) then
        return ""
    end

    local db = ns.db and ns.db.profile and ns.db.profile.unitframes and ns.db.profile.unitframes[unitToken]
    local cfg = db and db.name
    local format = cfg and cfg.format or "levelName"

    local name = UnitName(unitToken) or ""
    if format == "name" then
        return name
    end

    local level = NormalizeNumber(UnitLevel(unitToken))
    if level <= 0 then
        return name
    end

    return string.format("|cffffff00%d|r %s", level, name)
end

local function GetNameFontPath()
    local ufdb = ns.db and ns.db.profile and ns.db.profile.unitframes
    local appearance = ufdb and ufdb.appearance
    local fontKey = appearance and appearance.nameFont or "default"
    return ns:GetUnitFontPath(fontKey)
end

local function GetNameFontSize(unit)
    local db = ns.db and ns.db.profile and ns.db.profile.unitframes and ns.db.profile.unitframes[unit]
    local cfg = db and db.name
    return (cfg and cfg.fontSize) or 12
end

function ns:CreateName(frame)
    local parent = frame.Overlay or frame

    local name = parent:CreateFontString(nil, "OVERLAY")
    name:SetFont(GetNameFontPath(), GetNameFontSize(frame.unit), "OUTLINE")
    name:SetJustifyH("LEFT")
    name:SetTextColor(1, 1, 1)

    frame.Name = name

    if _G.oUF and _G.oUF.Tags then
        _G.oUF.Tags.Methods["hrui:name"] = function(unitToken)
            return GetFormattedUnitName(unitToken)
        end

        _G.oUF.Tags.Events["hrui:name"] =
        "UNIT_NAME_UPDATE UNIT_LEVEL PLAYER_TARGET_CHANGED PLAYER_FOCUS_CHANGED UNIT_TARGET PLAYER_ENTERING_WORLD"

        frame:Tag(name, "[hrui:name]")
    end

    ns:UpdateNamePosition(frame)
end

function ns:UpdateNamePosition(frame)
    if not frame or not frame.Name or not frame.Health then
        return
    end

    local unit = frame.unit
    local db = ns.db.profile.unitframes[unit]
    local cfg = db and db.name
    if not cfg then
        return
    end

    frame.Name:SetFont(GetNameFontPath(), GetNameFontSize(unit), "OUTLINE")

    local anchor = ns:GetTextAnchorPoint(cfg.anchor)

    frame.Name:ClearAllPoints()
    frame.Name:SetPoint(anchor, frame.Health, anchor, cfg.x or 0, cfg.y or 0)

    if anchor == "LEFT" then
        frame.Name:SetJustifyH("LEFT")
    elseif anchor == "CENTER" then
        frame.Name:SetJustifyH("CENTER")
    else
        frame.Name:SetJustifyH("RIGHT")
    end
end
