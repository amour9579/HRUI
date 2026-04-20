local _, ns = ...

local function GetCastbarStyle()
    local style = ns.db and ns.db.profile and ns.db.profile.castbars and ns.db.profile.castbars.style

    return {
        cast = (style and style.castColor) or { 0.95, 0.75, 0.20 },
        channel = (style and style.channelColor) or { 0.20, 0.70, 1.00 },
        nonInterruptible = (style and style.nonInterruptibleColor) or { 0.75, 0.20, 0.20 },
        bg = { 0.08, 0.08, 0.08, (style and style.bgAlpha) or 0.90 },
        border = { 0.20, 0.20, 0.20, 1.00 },
        text = { 1.00, 1.00, 1.00 },
        showBorder = (style and style.showBorder) ~= false,
        showSpark = (style and style.showSpark) ~= false,
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
end

function ns:CreateCastbar(frame, db)
    if not frame then
        return
    end

    local style = GetCastbarStyle()

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
    frame.startTime = nil
    frame.endTime = nil
    frame.notInterruptible = nil

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

    local style = GetCastbarStyle()

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

    local style = GetCastbarStyle()

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

function ns:UpdateCastbar(frame, currentTime)
    if not frame or (not frame.casting and not frame.channeling) then
        return
    end

    currentTime = currentTime or GetTime()

    local startTime = frame.startTime or 0
    local endTime = frame.endTime or 0
    local duration = math.max(endTime - startTime, 0)
    local style = GetCastbarStyle()

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
    end
end
