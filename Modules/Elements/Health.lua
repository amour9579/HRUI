local _, ns = ...

local function GetHealthFontPath()
    local ufdb = ns.db and ns.db.profile and ns.db.profile.unitframes
    local appearance = ufdb and ufdb.appearance
    local fontKey = appearance and appearance.healthFont or "default"
    return ns:GetUnitFontPath(fontKey)
end

local function GetHealthFontSize(unit)
    local db = ns.db and ns.db.profile and ns.db.profile.unitframes and ns.db.profile.unitframes[unit]
    local cfg = db and db.healthText
    return (cfg and cfg.fontSize) or 11
end

local function SetHealthText(fontString, format, cur, max)
    if format == "valueMax" then
        fontString:SetFormattedText("%s / %s", ns:FormatHealth(cur), ns:FormatHealth(max))
    else
        fontString:SetText(ns:FormatHealth(cur))
    end
end

function ns:UpdateHealthValue(frame, ...)
    if not frame or not frame.HealthValue or not frame.Health then
        return
    end

    local unit = frame.unit
    local db = ns.db and ns.db.profile and ns.db.profile.unitframes and ns.db.profile.unitframes[unit]
    local cfg = db and db.healthText
    local format = cfg and cfg.format or "value"
    if format ~= "value" and format ~= "valueMax" then
        format = "value"
    end

    local cur, max = ...
    if select("#", ...) < 2 then
        cur = frame.Health:GetValue()
        local _, maxValue = frame.Health:GetMinMaxValues()
        max = maxValue
    end

    SetHealthText(frame.HealthValue, format, cur, max)
end

function ns:CreateHealth(frame)
    local unit = frame.unit
    local db = ns.db.profile.unitframes[unit]
    local powerCfg = db and db.power
    local powerEnabled = powerCfg and powerCfg.enabled
    local powerHeight = (powerCfg and powerCfg.height) or 6
    local bottomOffset = powerEnabled and (powerHeight + 1) or 1

    local health = CreateFrame("StatusBar", nil, frame)
    health.__owner = frame
    health:SetStatusBarTexture(ns:GetTexture())
    health:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    health:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    health:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, bottomOffset)
    health:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, bottomOffset)
    health.frequentUpdates = true

    local bg = health:CreateTexture(nil, "BORDER")
    bg:SetAllPoints()
    bg:SetTexture(ns:GetTexture())
    bg:SetVertexColor(0.15, 0.15, 0.15, 0.7)
    health.bg = bg

    health.PostUpdate = function(bar, unit, cur, max)
        ns:UpdateHealthValue(bar.__owner or frame, cur, max)
    end

    frame.Health = health
end

function ns:CreateHealthValue(frame)
    local parent = frame.Overlay or frame

    local value = parent:CreateFontString(nil, "OVERLAY")
    value:SetFont(GetHealthFontPath(), GetHealthFontSize(frame.unit), "OUTLINE")
    value:SetTextColor(1, 1, 1)

    frame.HealthValue = value

    ns:UpdateHealthText(frame)
    ns:UpdateHealthValue(frame)
end

function ns:UpdateHealthText(frame)
    if not frame or not frame.HealthValue or not frame.Health then
        return
    end

    local unit = frame.unit
    local db = ns.db.profile.unitframes[unit]
    local cfg = db and db.healthText
    if not cfg then
        return
    end

    frame.HealthValue:SetFont(GetHealthFontPath(), GetHealthFontSize(unit), "OUTLINE")

    if cfg.enabled then
        frame.HealthValue:Show()
    else
        frame.HealthValue:Hide()
        return
    end

    local anchor = ns:GetTextAnchorPoint(cfg.anchor)

    frame.HealthValue:ClearAllPoints()
    frame.HealthValue:SetPoint(anchor, frame.Health, anchor, cfg.x or 0, cfg.y or 0)

    if anchor == "LEFT" then
        frame.HealthValue:SetJustifyH("LEFT")
    elseif anchor == "CENTER" then
        frame.HealthValue:SetJustifyH("CENTER")
    else
        frame.HealthValue:SetJustifyH("RIGHT")
    end

    ns:UpdateHealthValue(frame)
end
