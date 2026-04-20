local _, ns = ...

local function FormatPowerText(format, cur, max)
    cur = tonumber(cur) or 0
    max = tonumber(max) or 0

    if format == "value" then
        return ns:FormatShortValue(cur)
    elseif format == "valueMax" then
        return string.format("%s / %s",
            ns:FormatShortValue(cur),
            ns:FormatShortValue(max)
        )
    end

    return ns:FormatShortValue(cur)
end

local function GetPowerFontPath()
    local ufdb = ns.db and ns.db.profile and ns.db.profile.unitframes
    local appearance = ufdb and ufdb.appearance
    local fontKey = appearance and appearance.powerFont or "default"
    return ns:GetUnitFontPath(fontKey)
end

local function GetPowerFontSize(unit)
    local db = ns.db and ns.db.profile and ns.db.profile.unitframes and ns.db.profile.unitframes[unit]
    local cfg = db and db.powerText
    return (cfg and cfg.fontSize) or 10
end

function ns:UpdatePowerValue(frame)
    if not frame or not frame.PowerValue then
        return
    end

    local unit = frame.unit
    if not unit or not UnitExists(unit) then
        frame.PowerValue:SetText("")
        return
    end

    local db = ns.db.profile.unitframes[unit]
    local cfg = db and db.powerText
    local format = cfg and cfg.format or "value"

    local cur = tonumber(UnitPower(unit)) or 0
    local max = tonumber(UnitPowerMax(unit)) or 0

    frame.PowerValue:SetText(FormatPowerText(format, cur, max))
end

function ns:CreatePower(frame)
    local unit = frame.unit
    local db = ns.db.profile.unitframes[unit]
    local cfg = db and db.power
    local powerHeight = (cfg and cfg.height) or 6

    local power = CreateFrame("StatusBar", nil, frame)
    power:SetStatusBarTexture(ns:GetTexture())
    power:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 1)
    power:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    power:SetHeight(powerHeight)
    power.frequentUpdates = true

    local bg = power:CreateTexture(nil, "BORDER")
    bg:SetAllPoints()
    bg:SetTexture(ns:GetTexture())
    bg:SetVertexColor(0.15, 0.15, 0.15, 0.7)
    power.bg = bg

    power.PostUpdate = function(bar)
        local owner = bar.__owner or frame
        ns:UpdatePowerValue(owner)
    end

    frame.Power = power

    ns:UpdatePowerBar(frame)
end

function ns:CreatePowerValue(frame)
    local parent = frame.Overlay or frame

    local value = parent:CreateFontString(nil, "OVERLAY")
    value:SetFont(GetPowerFontPath(), GetPowerFontSize(frame.unit), "OUTLINE")
    value:SetTextColor(1, 1, 1)

    frame.PowerValue = value

    ns:UpdatePowerText(frame)
    ns:UpdatePowerValue(frame)
end

function ns:UpdatePowerBar(frame)
    if not frame or not frame.Power or not frame.Health then
        return
    end

    local unit = frame.unit
    local db = ns.db.profile.unitframes[unit]
    local cfg = db and db.power
    if not cfg then
        return
    end

    local height = cfg.height or 6

    frame.Power:ClearAllPoints()
    frame.Power:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 1)
    frame.Power:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    frame.Power:SetHeight(height)

    if cfg.enabled then
        frame.Power:Show()

        frame.Health:ClearAllPoints()
        frame.Health:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
        frame.Health:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
        frame.Health:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, height + 1)
        frame.Health:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, height + 1)
    else
        frame.Power:Hide()

        frame.Health:ClearAllPoints()
        frame.Health:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
        frame.Health:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
        frame.Health:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 1)
        frame.Health:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    end

    ns:UpdatePowerText(frame)
    ns:UpdatePowerValue(frame)
end

function ns:UpdatePowerText(frame)
    if not frame or not frame.PowerValue or not frame.Power then
        return
    end

    local unit = frame.unit
    local db = ns.db.profile.unitframes[unit]
    local cfg = db and db.powerText
    local powerCfg = db and db.power

    frame.PowerValue:SetFont(GetPowerFontPath(), GetPowerFontSize(unit), "OUTLINE")

    if not cfg or not powerCfg or not powerCfg.enabled or not cfg.enabled then
        frame.PowerValue:Hide()
        return
    end

    frame.PowerValue:Show()

    local anchor = ns:GetTextAnchorPoint(cfg.anchor)

    frame.PowerValue:ClearAllPoints()
    frame.PowerValue:SetPoint(anchor, frame.Power, anchor, cfg.x or 0, cfg.y or 0)

    if anchor == "LEFT" then
        frame.PowerValue:SetJustifyH("LEFT")
    elseif anchor == "CENTER" then
        frame.PowerValue:SetJustifyH("CENTER")
    else
        frame.PowerValue:SetJustifyH("RIGHT")
    end

    ns:UpdatePowerValue(frame)
end
