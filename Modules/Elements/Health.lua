local _, ns = ...

local function GetConfigUnit(frame)
    if not frame then
        return nil
    end

    if frame.HRUIConfigUnit then
        return frame.HRUIConfigUnit
    end

    local unit = frame.unit

    -- 차량 상태에서 이미 vehicle로 들어온 경우 설정은 player 것을 사용
    if unit == "vehicle" then
        unit = "player"
    end

    frame.HRUIConfigUnit = unit
    return unit
end

local function GetActiveUnit(frame, configUnit)
    if not frame then
        return nil
    end

    local unit = frame.unit or configUnit

    if unit and UnitExists(unit) then
        return unit
    end

    if configUnit and UnitExists(configUnit) then
        return configUnit
    end

    return nil
end
local function FormatHealthText(format, cur, max)
    local curText = ns:FormatHealth(cur)

    if format == "valueMax" then
        local maxText = ns:FormatHealth(max)

        if curText == "" and maxText == "" then
            return ""
        end

        if maxText == "" then
            return curText
        end

        if curText == "" then
            return maxText
        end

        return curText .. " / " .. maxText
    end

    return curText
end

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

function ns:UpdateHealthValue(frame)
    if not frame or not frame.HealthValue or not frame.Health then
        return
    end

    local configUnit = GetConfigUnit(frame)
    local activeUnit = GetActiveUnit(frame, configUnit)

    local db = ns.db and ns.db.profile and ns.db.profile.unitframes and ns.db.profile.unitframes[configUnit]
    local cfg = db and db.healthText

    local format = cfg and cfg.format or "value"
    if format ~= "value" and format ~= "valueMax" then
        format = "value"
    end

    if not activeUnit then
        frame.HealthValue:SetText("")
        return
    end

    local cur = UnitHealth(activeUnit)
    local max = UnitHealthMax(activeUnit)

    frame.HealthValue:SetText(FormatHealthText(format, cur, max))
end

function ns:CreateHealth(frame)
    local unit = frame.unit
    -- 중요: oUF가 차량 상태에서 frame.unit을 vehicle로 바꿔도
    -- 옵션 조회용 유닛은 최초 생성 시점의 unit으로 고정
    frame.HRUIConfigUnit = frame.HRUIConfigUnit or unit
    local db = ns.db.profile.unitframes[unit]
    local powerCfg = db and db.power
    local powerEnabled = powerCfg and powerCfg.enabled
    local powerHeight = (powerCfg and powerCfg.height) or 6
    local bottomOffset = powerEnabled and (powerHeight + 1) or 1

    local health = CreateFrame("StatusBar", nil, frame)
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

    health.PostUpdate = function(bar)
        local owner = bar.__owner or frame
        ns:UpdateHealthValue(owner)
    end

    frame.Health = health
end

function ns:CreateHealthValue(frame)
    local configUnit = GetConfigUnit(frame)
    local parent = frame.Overlay or frame

    local value = parent:CreateFontString(nil, "OVERLAY")
    value:SetFont(GetHealthFontPath(), GetHealthFontSize(configUnit), "OUTLINE")
    value:SetTextColor(1, 1, 1)

    frame.HealthValue = value

    ns:UpdateHealthText(frame)
    ns:UpdateHealthValue(frame)
end

function ns:UpdateHealthText(frame)
    if not frame or not frame.HealthValue or not frame.Health then
        return
    end

    local configUnit = GetConfigUnit(frame)
    local db = ns.db.profile.unitframes[configUnit]
    local cfg = db and db.healthText
    if not cfg then
        return
    end

    frame.HealthValue:SetFont(GetHealthFontPath(), GetHealthFontSize(configUnit), "OUTLINE")

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
