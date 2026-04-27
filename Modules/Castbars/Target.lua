local _, ns = ...

local StatusBarTimerDirection = Enum.StatusBarTimerDirection
local StatusBarInterpolation = Enum.StatusBarInterpolation

local spellcastEvents = {
    "UNIT_SPELLCAST_START",
    "UNIT_SPELLCAST_STOP",
    "UNIT_SPELLCAST_FAILED",
    "UNIT_SPELLCAST_INTERRUPTED",
    "UNIT_SPELLCAST_DELAYED",
    "UNIT_SPELLCAST_CHANNEL_START",
    "UNIT_SPELLCAST_CHANNEL_UPDATE",
    "UNIT_SPELLCAST_CHANNEL_STOP",
    "UNIT_SPELLCAST_INTERRUPTIBLE",
    "UNIT_SPELLCAST_NOT_INTERRUPTIBLE",
}

local stopEvents = {
    UNIT_SPELLCAST_STOP = true,
    UNIT_SPELLCAST_FAILED = true,
    UNIT_SPELLCAST_INTERRUPTED = true,
    UNIT_SPELLCAST_CHANNEL_STOP = true,
}

local startEvents = {
    UNIT_SPELLCAST_START = true,
    UNIT_SPELLCAST_DELAYED = true,
    UNIT_SPELLCAST_CHANNEL_START = true,
    UNIT_SPELLCAST_CHANNEL_UPDATE = true,
    UNIT_SPELLCAST_INTERRUPTIBLE = true,
    UNIT_SPELLCAST_NOT_INTERRUPTIBLE = true,
}

local function GetTargetCastbarStyle()
    local style = ns.db
        and ns.db.profile
        and ns.db.profile.castbars
        and ns.db.profile.castbars.style

    return {
        cast = (style and style.castColor) or { 0.95, 0.75, 0.20 },
        channel = (style and style.channelColor) or { 0.20, 0.70, 1.00 },
    }
end

local function ResetTargetCastbar(frame)
    if frame then
        frame.__HRUI_TargetTimerActive = nil
        frame.__HRUI_TargetTimerKind = nil
    end

    ns:ResetCastbar(frame)
end

local function SafeSetText(fontString, text)
    if not fontString then
        return
    end

    local ok = pcall(fontString.SetText, fontString, text)
    if not ok then
        fontString:SetText("")
    end
end

local function SafeSetTexture(textureObject, texture)
    if not textureObject then
        return
    end

    local ok = pcall(textureObject.SetTexture, textureObject, texture)
    if not ok then
        textureObject:SetTexture(nil)
    end
end

local function SafeSetFormattedTime(fontString, value)
    if not fontString then
        return
    end

    local ok = pcall(fontString.SetFormattedText, fontString, "%.1f", value or 0)
    if not ok then
        fontString:SetText("")
    end
end

local function GetDuration(durationFunc, unit)
    if type(durationFunc) ~= "function" then
        return nil
    end

    local ok, duration = pcall(durationFunc, unit)
    if ok then
        return duration
    end

    return nil
end

local function StartTargetTimer(frame, spellName, icon, duration, isChannel)
    if not frame or not duration or not frame.SetTimerDuration then
        return false
    end

    local style = GetTargetCastbarStyle()
    local direction = isChannel
        and StatusBarTimerDirection.RemainingTime
        or StatusBarTimerDirection.ElapsedTime

    frame.casting = nil
    frame.channeling = nil
    frame.startTime = nil
    frame.endTime = nil
    frame.notInterruptible = nil

    frame.__HRUI_TargetTimerActive = true
    frame.__HRUI_TargetTimerKind = isChannel and "channel" or "cast"

    frame:SetTimerDuration(
        duration,
        StatusBarInterpolation.Immediate,
        direction
    )

    SafeSetText(frame.Text, spellName)
    SafeSetTexture(frame.Icon, icon)

    if frame.Time then
        frame.Time:SetText("")
    end

    if frame.Spark then
        frame.Spark:ClearAllPoints()

        local barTexture = frame:GetStatusBarTexture()
        if barTexture then
            frame.Spark:SetPoint("CENTER", barTexture, "RIGHT", 0, 0)
            frame.Spark:Show()
        else
            frame.Spark:Hide()
        end
    end

    if isChannel then
        frame:SetStatusBarColor(unpack(style.channel))
    else
        frame:SetStatusBarColor(unpack(style.cast))
    end

    frame:Show()
    return true
end

local function StartTargetCastbarFromUnit(frame, unit)
    if not frame or not unit or not UnitExists(unit) then
        return false
    end
    local name, _, texture = UnitCastingInfo(unit)
    if name then
        local duration = GetDuration(UnitCastingDuration, unit)
        if duration then
            return StartTargetTimer(frame, name, texture, duration, false)
        end

        return false
    end

    local chName, _, chTexture = UnitChannelInfo(unit)
    if chName then
        local duration = GetDuration(UnitChannelDuration, unit)
        if duration then
            return StartTargetTimer(frame, chName, chTexture, duration, true)
        end

        return false
    end
    return false
end

local function ForceUpdateTargetCastbar(frame)
    if not frame then
        return
    end

    local db = ns.db
        and ns.db.profile
        and ns.db.profile.castbars
        and ns.db.profile.castbars.target

    if not db or not db.enabled then
        ResetTargetCastbar(frame)
        return
    end

    if not UnitExists("target") then
        ResetTargetCastbar(frame)
        return
    end

    if not StartTargetCastbarFromUnit(frame, "target") then
        ResetTargetCastbar(frame)
    end
end

local function UpdateTargetTimeText(frame)
    if not frame or not frame.__HRUI_TargetTimerActive then
        return
    end

    if not frame.GetTimerDuration then
        return
    end

    local durationObject = frame:GetTimerDuration()
    if not durationObject then
        return
    end

    local ok, remaining = pcall(durationObject.GetRemainingDuration, durationObject)
    if ok then
        SafeSetFormattedTime(frame.Time, remaining)
    end
end

function ns:SpawnTargetCastbar()
    if ns.TargetCastbar then
        return ns.TargetCastbar
    end

    local db = ns.db.profile.castbars.target

    local frame = CreateFrame("StatusBar", "HRUI_TargetCastbar", UIParent, "BackdropTemplate")
    frame.unit = "target"
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(10)
    frame:SetSize(db.width, db.height)
    frame:SetPoint("CENTER", UIParent, "CENTER", db.x, db.y)
    frame:SetMinMaxValues(0, 1)
    frame:SetValue(0)

    ns:CreateCastbar(frame, db)
    frame:Hide()

    frame:SetScript("OnUpdate", function(self)
        UpdateTargetTimeText(self)
    end)

    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")

    for _, event in ipairs(spellcastEvents) do
        frame:RegisterUnitEvent(event, "target")
    end

    frame:SetScript("OnEvent", function(self, event, unit)
        if event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
            ResetTargetCastbar(self)

            ForceUpdateTargetCastbar(self)

            if C_Timer and C_Timer.After then
                C_Timer.After(0, function()
                    ForceUpdateTargetCastbar(self)
                end)
            end

            return
        end

        if unit ~= "target" then
            return
        end

        if stopEvents[event] then
            ResetTargetCastbar(self)
            return
        end

        if startEvents[event] then
            if not StartTargetCastbarFromUnit(self, "target") then
                ResetTargetCastbar(self)
            end
        end
    end)

    ns.TargetCastbar = frame
    return frame
end
