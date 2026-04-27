local _, ns = ...

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

local restartEvents = {
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
        frame.__HRUI_TargetDurationActive = nil
        frame.__HRUI_TargetDurationKind = nil
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

local function CopyUnitDuration(durationFunc, unit)
    if type(durationFunc) ~= "function" then
        return nil
    end

    local ok, duration = pcall(function()
        return durationFunc(unit):Copy()
    end)

    if ok then
        return duration
    end

    return nil
end
local function GetTargetCastUnit(eventUnit)
    if eventUnit
        and UnitExists(eventUnit)
        and UnitExists("target")
        and UnitIsUnit(eventUnit, "target") then
        return eventUnit
    end

    if UnitExists("target") then
        return "target"
    end

    return nil
end

local function StartTargetDurationCastbar(frame, spellName, icon, duration, isChannel)
    if not frame or not duration or not frame.SetTimerDuration then
        return
    end

    local style = GetTargetCastbarStyle()

    frame.casting = nil
    frame.channeling = nil
    frame.startTime = nil
    frame.endTime = nil
    frame.notInterruptible = nil

    frame.__HRUI_TargetDurationActive = true
    frame.__HRUI_TargetDurationKind = isChannel and "channel" or "cast"

    local direction = isChannel
        and Enum.StatusBarTimerDirection.RemainingTime
        or Enum.StatusBarTimerDirection.ElapsedTime

    frame:SetTimerDuration(
        duration,
        Enum.StatusBarInterpolation.Immediate,
        direction
    )

    if frame.Text then
        SafeSetText(frame.Text, spellName)
    end

    if frame.Time then
        frame.Time:SetText("")
    end

    if frame.Icon then
        SafeSetTexture(frame.Icon, icon)
    end

    if frame.Spark then
        frame.Spark:Hide()
    end

    if isChannel then
        frame:SetStatusBarColor(unpack(style.channel))
    else
        frame:SetStatusBarColor(unpack(style.cast))
    end

    frame:Show()
end

local function UpdateTargetCastState(frame, eventUnit, forceRestart)
    if not frame
        or not UnitExists("target")
        or not ns.db.profile.castbars.target.enabled then
        if frame then
            ResetTargetCastbar(frame)
        end

        return
    end

    local unit = GetTargetCastUnit(eventUnit)
    if not unit then
        ResetTargetCastbar(frame)
        return
    end

    local castDuration = CopyUnitDuration(UnitCastingDuration, unit)
    if castDuration then
        if forceRestart
            or not frame.__HRUI_TargetDurationActive
            or frame.__HRUI_TargetDurationKind ~= "cast" then
            local name, _, texture = UnitCastingInfo(unit)
            StartTargetDurationCastbar(frame, name, texture, castDuration, false)
        end

        return
    end

    local channelDuration = CopyUnitDuration(UnitChannelDuration, unit)
    if channelDuration then
        if forceRestart
            or not frame.__HRUI_TargetDurationActive
            or frame.__HRUI_TargetDurationKind ~= "channel" then
            local chName, _, chTexture = UnitChannelInfo(unit)
            StartTargetDurationCastbar(frame, chName, chTexture, channelDuration, true)
        end

        return
    end

    ResetTargetCastbar(frame)
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

    frame:SetScript("OnUpdate", function(self, elapsed)
        self.__HRUI_TargetCastPoll = (self.__HRUI_TargetCastPoll or 0) + (elapsed or 0)

        if self.__HRUI_TargetCastPoll >= 0.10 then
            self.__HRUI_TargetCastPoll = 0
            UpdateTargetCastState(self, nil, false)
        end
    end)

    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")

    for _, event in ipairs(spellcastEvents) do
        frame:RegisterEvent(event)
    end

    frame:SetScript("OnEvent", function(self, event, unit)
        if event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
            ResetTargetCastbar(self)
            UpdateTargetCastState(self, nil, true)
            return
        end

        if event == "NAME_PLATE_UNIT_ADDED" then
            if unit and UnitExists("target") and UnitIsUnit(unit, "target") then
                UpdateTargetCastState(self, unit, true)
            end
            return
        end

        if not unit or not UnitExists("target") then
            return
        end

        if unit ~= "target" and not UnitIsUnit(unit, "target") then
            return
        end

        if stopEvents[event] then
            ResetTargetCastbar(self)
            return
        end

        UpdateTargetCastState(self, unit, restartEvents[event] == true)
    end)

    ns.TargetCastbar = frame
    return frame
end
