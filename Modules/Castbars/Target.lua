local _, ns = ...

local POLL_INTERVAL = 0.05

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
        local d = durationFunc(unit)
        return d:Copy()
    end)

    if ok then
        return duration
    end

    return nil
end

local function StartTargetDurationCastbar(frame, spellName, icon, duration, isChannel)
    if not frame or duration == nil or not frame.SetTimerDuration then
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

    SafeSetText(frame.Text, spellName)

    if frame.Time then
        frame.Time:SetText("")
    end

    SafeSetTexture(frame.Icon, icon)

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

local function UpdateTargetCastState(frame)
    if not frame
        or not ns.db
        or not ns.db.profile
        or not ns.db.profile.castbars
        or not ns.db.profile.castbars.target
        or not ns.db.profile.castbars.target.enabled then
        if frame then
            ResetTargetCastbar(frame)
        end

        return
    end

    if not UnitExists("target") then
        ResetTargetCastbar(frame)
        return
    end

    local castDuration = CopyUnitDuration(UnitCastingDuration, "target")
    if castDuration ~= nil then
        local name, _, texture = UnitCastingInfo("target")
        StartTargetDurationCastbar(frame, name, texture, castDuration, false)
        return
    end

    local channelDuration = CopyUnitDuration(UnitChannelDuration, "target")
    if channelDuration ~= nil then
        local chName, _, chTexture = UnitChannelInfo("target")
        StartTargetDurationCastbar(frame, chName, chTexture, channelDuration, true)
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

        if self.__HRUI_TargetCastPoll >= POLL_INTERVAL then
            self.__HRUI_TargetCastPoll = 0
            UpdateTargetCastState(self)
        end
    end)

    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")

    frame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
            ResetTargetCastbar(self)
            UpdateTargetCastState(self)
        end
    end)

    ns.TargetCastbar = frame
    return frame
end
