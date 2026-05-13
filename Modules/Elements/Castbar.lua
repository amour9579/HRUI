local _, ns = ...

local function GetCastbarStyle(frame)
    local unit = frame and frame.unit or nil

    if ns.GetCastbarStyle then
        return ns:GetCastbarStyle(unit)
    end

    return {
        cast = { 0.95, 0.75, 0.20 },
        channel = { 0.20, 0.70, 1.00 },
        nonInterruptible = { 0.75, 0.20, 0.20 },
        bg = { 0.08, 0.08, 0.08, 0.90 },
        border = { 0.20, 0.20, 0.20, 1.00 },
        text = { 1.00, 1.00, 1.00 },
        showBorder = true,
        showSpark = true,
    }
end

local function FormatTime(value)
    if type(value) ~= "number" or value < 0 then
        return ""
    end

    return string.format("%.1f", value)
end

local function NormalizeMS(value)
    if value == nil then
        return 0
    end

    local n = tonumber(tostring(value))
    if not n then
        return 0
    end

    return n
end

local function SafeDurationCall(method, object)
    if type(method) ~= "function" or not object then
        return nil
    end

    local ok, value = pcall(method, object)
    if ok then
        return value
    end

    return nil
end

local function CopyDurationObject(duration)
    if not duration then
        return nil
    end

    if type(duration.Copy) == "function" then
        local ok, copy = pcall(duration.Copy, duration)
        if ok and copy then
            return copy
        end
    end

    return duration
end

local function HideEmpowerStages(castbar)
    if not castbar or not castbar.EmpowerStages then
        return
    end

    for _, marker in ipairs(castbar.EmpowerStages) do
        marker:Hide()
    end
end

local function NormalizePercent(value)
    local n = tonumber(value)
    if not n then
        return nil
    end

    -- API/환경 차이 방어: 25 또는 0.25 둘 다 처리
    if n > 1 then
        n = n / 100
    end

    if n <= 0 then
        return nil
    end

    return n
end

local function GetEmpowerStageFractions(unit, numStages)
    -- Retail 12.0+ 권장 경로: hold-at-max 포함 비율
    if type(UnitEmpoweredStagePercentages) == "function" then
        local ok, percentages = pcall(UnitEmpoweredStagePercentages, unit, true)

        if ok and type(percentages) == "table" and #percentages > 0 then
            local fractions = {}
            local acc = 0

            -- 마지막 값은 hold-at-max 구간이므로, 그 직전까지 누적선 표시
            for i = 1, math.max(#percentages - 1, 0) do
                local pct = NormalizePercent(percentages[i])
                if pct then
                    acc = acc + pct

                    if acc > 0 and acc < 1 then
                        fractions[#fractions + 1] = acc
                    end
                end
            end

            if #fractions > 0 then
                return fractions
            end
        end
    end

    -- 구버전 fallback
    if type(GetUnitEmpowerStageDuration) ~= "function" then
        return nil
    end

    numStages = tonumber(numStages) or 0
    if numStages <= 0 then
        return nil
    end

    local durations = {}
    local total = 0

    for i = 1, numStages do
        local d = tonumber(GetUnitEmpowerStageDuration(unit, i)) or 0
        durations[i] = d
        total = total + d
    end

    if type(GetUnitEmpowerHoldAtMaxTime) == "function" then
        total = total + (tonumber(GetUnitEmpowerHoldAtMaxTime(unit)) or 0)
    end

    if total <= 0 then
        return nil
    end

    local fractions = {}
    local acc = 0

    for i = 1, numStages do
        acc = acc + durations[i]

        if acc > 0 and acc < total then
            fractions[#fractions + 1] = acc / total
        end
    end

    return fractions
end

local function ShowEmpowerStages(castbar, unit, numStages)
    if not castbar then
        return
    end

    HideEmpowerStages(castbar)

    local fractions = GetEmpowerStageFractions(unit, numStages)
    if not fractions or #fractions == 0 then
        return
    end

    castbar.EmpowerStages = castbar.EmpowerStages or {}

    local width = castbar:GetWidth()
    local height = math.max(castbar:GetHeight() + 4, 8)

    for i, fraction in ipairs(fractions) do
        local marker = castbar.EmpowerStages[i]

        if not marker then
            marker = castbar:CreateTexture(nil, "OVERLAY")
            marker:SetTexture("Interface\\Buttons\\WHITE8X8")
            castbar.EmpowerStages[i] = marker
        end

        marker:ClearAllPoints()
        marker:SetSize(2, height)
        marker:SetVertexColor(1, 1, 1, 0.85)
        marker:SetPoint("CENTER", castbar, "LEFT", width * fraction, 0)
        marker:Show()
    end

    for i = #fractions + 1, #castbar.EmpowerStages do
        castbar.EmpowerStages[i]:Hide()
    end
end

local function GetEmpowerDurationObject(unit)
    if type(UnitEmpoweredChannelDuration) ~= "function" then
        return nil
    end

    local ok, duration = pcall(UnitEmpoweredChannelDuration, unit, true)
    if ok and duration then
        return CopyDurationObject(duration)
    end

    return nil
end

local function GetFallbackEmpowerDuration(unit, startTimeMS, endTimeMS, numStages)
    local total = 0

    if type(GetUnitEmpowerStageDuration) == "function" then
        numStages = tonumber(numStages) or 0

        for i = 1, numStages do
            total = total + (tonumber(GetUnitEmpowerStageDuration(unit, i)) or 0)
        end

        if type(GetUnitEmpowerHoldAtMaxTime) == "function" then
            total = total + (tonumber(GetUnitEmpowerHoldAtMaxTime(unit)) or 0)
        end

        if total > 0 then
            return total / 1000
        end
    end

    local startMS = NormalizeMS(startTimeMS)
    local endMS = NormalizeMS(endTimeMS)

    if startMS > 0 and endMS > startMS then
        return (endMS - startMS) / 1000
    end

    return 0
end
local function ClearCastbarVisuals(castbar)
    if castbar.Text then
        castbar.Text:SetText("")
    end

    if castbar.Time then
        castbar.Time:SetText("")
    end

    if castbar.Icon then
        castbar.Icon:SetTexture(nil)
    end

    if castbar.Spark then
        castbar.Spark:Hide()
    end
    HideEmpowerStages(castbar)
end

function ns:CreateCastbar(frame, db)
    if not frame then
        return
    end

    local style = GetCastbarStyle(frame)

    frame:SetStatusBarTexture(ns:GetTexture())

    if not frame.BG then
        local bg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        bg:SetAllPoints()
        bg:SetFrameLevel(math.max(frame:GetFrameLevel() - 1, 0))
        frame.BG = bg
    end

    frame.BG:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = style.showBorder and "Interface\\Buttons\\WHITE8X8" or nil,
        edgeSize = style.showBorder and 1 or 0,
    })
    frame.BG:SetBackdropColor(unpack(style.bg))
    if style.showBorder then
        frame.BG:SetBackdropBorderColor(unpack(style.border))
    end

    if not frame.Spark then
        local spark = frame:CreateTexture(nil, "OVERLAY")
        spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
        spark:SetBlendMode("ADD")
        spark:SetSize(18, 28)
        frame.Spark = spark
    end

    if not frame.Icon then
        local icon = frame:CreateTexture(nil, "ARTWORK")
        frame.Icon = icon
    end

    if not frame.Text then
        local text = frame:CreateFontString(nil, "OVERLAY")
        text:SetFont(ns:GetFont(), 11, "OUTLINE")
        text:SetJustifyH("LEFT")
        text:SetTextColor(unpack(style.text))
        frame.Text = text
    end

    if not frame.Time then
        local time = frame:CreateFontString(nil, "OVERLAY")
        time:SetFont(ns:GetFont(), 11, "OUTLINE")
        time:SetJustifyH("RIGHT")
        time:SetTextColor(unpack(style.text))
        frame.Time = time
    end

    local iconSize = (db and db.icon and db.icon.size) or frame:GetHeight()

    frame.Icon:ClearAllPoints()
    frame.Icon:SetPoint("RIGHT", frame, "LEFT", -4, 0)
    frame.Icon:SetSize(iconSize, iconSize)

    frame.Text:ClearAllPoints()
    frame.Text:SetPoint("LEFT", frame, "LEFT", 4, 0)
    frame.Text:SetPoint("RIGHT", frame, "RIGHT", -40, 0)

    frame.Time:ClearAllPoints()
    frame.Time:SetPoint("RIGHT", frame, "RIGHT", -4, 0)

    if db and db.icon and db.icon.enabled then
        frame.Icon:Show()
    else
        frame.Icon:Hide()
    end

    if db and db.text and db.text.enabled then
        frame.Text:Show()
    else
        frame.Text:Hide()
    end

    if db and db.time and db.time.enabled then
        frame.Time:Show()
    else
        frame.Time:Hide()
    end

    if frame.Spark then
        if style.showSpark then
            frame.Spark:Show()
        else
            frame.Spark:Hide()
        end
    end
end

function ns:ResetCastbar(frame)
    if not frame then
        return
    end

    frame.casting = nil
    frame.channeling = nil
    frame.empowering = nil
    frame.startTime = nil
    frame.endTime = nil
    frame.notInterruptible = nil

    frame.empowerDuration = nil
    frame.empowerTotal = nil
    frame:SetMinMaxValues(0, 1)
    frame:SetValue(0)

    ClearCastbarVisuals(frame)
    frame:Hide()
end

function ns:StartCastbarCast(frame, spellName, icon, startTimeMS, endTimeMS, notInterruptible)
    if not frame then
        return
    end

    local startMS = NormalizeMS(startTimeMS)
    local endMS = NormalizeMS(endTimeMS)

    if startMS <= 0 or endMS <= 0 or endMS <= startMS then
        ns:ResetCastbar(frame)
        return
    end

    local startTime = startMS / 1000
    local endTime = endMS / 1000
    local duration = math.max(endTime - startTime, 0)

    local style = GetCastbarStyle(frame)

    frame.casting = true
    frame.channeling = nil
    frame.startTime = startTime
    frame.endTime = endTime
    frame.notInterruptible = notInterruptible

    frame:SetMinMaxValues(0, duration > 0 and duration or 1)
    frame:SetValue(0)

    if frame.Text then
        frame.Text:SetText(spellName or "")
    end

    if frame.Icon then
        frame.Icon:SetTexture(icon)
    end

    if notInterruptible then
        frame:SetStatusBarColor(unpack(style.nonInterruptible))
    else
        frame:SetStatusBarColor(unpack(style.cast))
    end

    frame:Show()
end

function ns:StartCastbarChannel(frame, spellName, icon, startTimeMS, endTimeMS, notInterruptible)
    if not frame then
        return
    end

    local startMS = NormalizeMS(startTimeMS)
    local endMS = NormalizeMS(endTimeMS)

    if startMS <= 0 or endMS <= 0 or endMS <= startMS then
        ns:ResetCastbar(frame)
        return
    end

    local startTime = startMS / 1000
    local endTime = endMS / 1000
    local duration = math.max(endTime - startTime, 0)

    local style = GetCastbarStyle(frame)

    frame.casting = nil
    frame.channeling = true
    frame.startTime = startTime
    frame.endTime = endTime
    frame.notInterruptible = notInterruptible

    frame:SetMinMaxValues(0, duration > 0 and duration or 1)
    frame:SetValue(duration)

    if frame.Text then
        frame.Text:SetText(spellName or "")
    end

    if frame.Icon then
        frame.Icon:SetTexture(icon)
    end

    if notInterruptible then
        frame:SetStatusBarColor(unpack(style.nonInterruptible))
    else
        frame:SetStatusBarColor(unpack(style.channel))
    end

    frame:Show()
end

function ns:StartCastbarEmpower(frame, unit, spellName, icon, startTimeMS, endTimeMS, notInterruptible, numStages)
    if not frame then
        return
    end

    unit = unit or frame.unit or "player"

    local durationObject = GetEmpowerDurationObject(unit)
    local totalDuration = nil

    if durationObject then
        totalDuration = SafeDurationCall(durationObject.GetTotalDuration, durationObject)
    end

    totalDuration = tonumber(totalDuration)

    if not totalDuration or totalDuration <= 0 then
        totalDuration = GetFallbackEmpowerDuration(unit, startTimeMS, endTimeMS, numStages)
    end

    if not totalDuration or totalDuration <= 0 then
        ns:ResetCastbar(frame)
        return
    end

    local style = GetCastbarStyle(frame)
    local now = GetTime()

    frame.casting = nil
    frame.channeling = nil
    frame.empowering = true

    frame.startTime = now
    frame.endTime = now + totalDuration
    frame.notInterruptible = notInterruptible

    frame.empowerDuration = durationObject
    frame.empowerTotal = totalDuration

    frame:SetMinMaxValues(0, totalDuration)
    frame:SetValue(0)

    if frame.Text then
        frame.Text:SetText(spellName or "")
    end

    if frame.Icon then
        frame.Icon:SetTexture(icon)
    end

    if notInterruptible then
        frame:SetStatusBarColor(unpack(style.nonInterruptible))
    else
        frame:SetStatusBarColor(unpack(style.channel))
    end

    ShowEmpowerStages(frame, unit, numStages)

    frame:Show()
end
function ns:UpdateCastbar(frame, currentTime)
    if not frame or (not frame.casting and not frame.channeling and not frame.empowering) then
        return
    end

    currentTime = currentTime or GetTime()

    local startTime = frame.startTime or 0
    local endTime = frame.endTime or 0
    local duration = math.max(endTime - startTime, 0)
    local style = GetCastbarStyle(frame)

    if duration <= 0 then
        ns:ResetCastbar(frame)
        return
    end

    if frame.casting then
        local elapsed = currentTime - startTime

        if elapsed >= duration then
            ns:ResetCastbar(frame)
            return
        end

        frame:SetMinMaxValues(0, duration)
        frame:SetValue(elapsed)

        if frame.Time then
            frame.Time:SetText(FormatTime(duration - elapsed))
        end

        if frame.Spark then
            if style.showSpark then
                local width = frame:GetWidth()
                local progress = elapsed / duration
                frame.Spark:ClearAllPoints()
                frame.Spark:SetPoint("CENTER", frame, "LEFT", width * progress, 0)
                frame.Spark:Show()
            else
                frame.Spark:Hide()
            end
        end
    elseif frame.channeling then
        local remaining = endTime - currentTime
        local elapsed = duration - remaining

        if remaining <= 0 then
            ns:ResetCastbar(frame)
            return
        end

        frame:SetMinMaxValues(0, duration)
        frame:SetValue(remaining)

        if frame.Time then
            frame.Time:SetText(FormatTime(remaining))
        end

        if frame.Spark then
            if style.showSpark then
                local width = frame:GetWidth()
                local progress = elapsed / duration
                frame.Spark:ClearAllPoints()
                frame.Spark:SetPoint("CENTER", frame, "LEFT", width * progress, 0)
                frame.Spark:Show()
            else
                frame.Spark:Hide()
            end
        end
    elseif frame.empowering then
        local total = frame.empowerTotal or 0
        local remaining = nil

        if frame.empowerDuration then
            remaining = SafeDurationCall(frame.empowerDuration.GetRemainingDuration, frame.empowerDuration)
            local durationTotal = SafeDurationCall(frame.empowerDuration.GetTotalDuration, frame.empowerDuration)

            if tonumber(durationTotal) and tonumber(durationTotal) > 0 then
                total = tonumber(durationTotal)
                frame.empowerTotal = total
            end
        end

        remaining = tonumber(remaining)

        if not remaining then
            remaining = (frame.endTime or 0) - currentTime
        end

        if total <= 0 then
            ns:ResetCastbar(frame)
            return
        end

        if remaining <= 0 then
            ns:ResetCastbar(frame)
            return
        end

        local elapsed = total - remaining
        if elapsed < 0 then
            elapsed = 0
        elseif elapsed > total then
            elapsed = total
        end

        frame:SetMinMaxValues(0, total)
        frame:SetValue(elapsed)

        if frame.Time then
            frame.Time:SetText(FormatTime(remaining))
        end

        if frame.Spark then
            if style.showSpark then
                local width = frame:GetWidth()
                local progress = elapsed / total

                frame.Spark:ClearAllPoints()
                frame.Spark:SetPoint("CENTER", frame, "LEFT", width * progress, 0)
                frame.Spark:Show()
            else
                frame.Spark:Hide()
            end
        end
    end
end
