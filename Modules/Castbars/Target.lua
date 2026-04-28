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
}

local function GetTargetCastbarStyle()
    local style = ns.db
        and ns.db.profile
        and ns.db.profile.castbars
        and ns.db.profile.castbars.style

    return {
        cast = (style and style.castColor) or { 0.95, 0.75, 0.20 },
        channel = (style and style.channelColor) or { 0.20, 0.70, 1.00 },
        nonInterruptible = (style and style.nonInterruptibleColor) or { 0.75, 0.20, 0.20 },
    }
end

local function SetTargetCastbarColor(frame, color)
    if not frame or not color then
        return
    end

    local r = color[1]
    local g = color[2]
    local b = color[3]
    local a = color[4] or 1

    if frame.SetStatusBarColor then
        frame:SetStatusBarColor(r, g, b, a)
    end

    local texture = frame.GetStatusBarTexture and frame:GetStatusBarTexture()
    if texture and texture.SetVertexColor then
        texture:SetVertexColor(r, g, b, a)
    end
end

local function ApplyBooleanColor(frame, secretBoolean, trueColor, falseColor)
    if not frame
        or not C_CurveUtil
        or not C_CurveUtil.EvaluateColorValueFromBoolean then
        return false
    end

    local ok = pcall(function()
        local r = C_CurveUtil.EvaluateColorValueFromBoolean(secretBoolean, trueColor[1], falseColor[1])
        local g = C_CurveUtil.EvaluateColorValueFromBoolean(secretBoolean, trueColor[2], falseColor[2])
        local b = C_CurveUtil.EvaluateColorValueFromBoolean(secretBoolean, trueColor[3], falseColor[3])
        local a = C_CurveUtil.EvaluateColorValueFromBoolean(secretBoolean, trueColor[4] or 1, falseColor[4] or 1)

        if frame.SetStatusBarColor then
            frame:SetStatusBarColor(r, g, b, a)
        end

        local texture = frame.GetStatusBarTexture and frame:GetStatusBarTexture()
        if texture and texture.SetVertexColor then
            texture:SetVertexColor(r, g, b, a)
        end
    end)

    return ok
end

local function ApplyTargetCastbarColor(frame, isChannel, notInterruptible)
    if not frame then
        return
    end

    local style = GetTargetCastbarStyle()
    local baseColor = isChannel and style.channel or style.cast
    local nonInterruptibleColor = style.nonInterruptible

    if ApplyBooleanColor(frame, notInterruptible, nonInterruptibleColor, baseColor) then
        return
    end

    SetTargetCastbarColor(frame, baseColor)
end

local function ResetTargetCastbar(frame)
    if frame then
        frame.__HRUI_TestCastbar = nil
        frame.__HRUI_TargetTimerActive = nil
        frame.__HRUI_TargetTimerKind = nil
        frame.__HRUI_TargetLastNotInterruptible = nil
    end

    ns:ResetCastbar(frame)
end

function ns:ResetTargetCastbar(frame)
    ResetTargetCastbar(frame or ns.TargetCastbar)
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

    local ok = pcall(fontString.SetFormattedText, fontString, "%.1f", value)
    if not ok then
        fontString:SetText("")
    end
end

local function GetDurationCopy(durationFunc, unit)
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

local function StartTargetTimer(frame, spellName, icon, duration, isChannel, notInterruptible)
    if not frame or not duration or not frame.SetTimerDuration then
        return false
    end

    local direction = isChannel
        and StatusBarTimerDirection.RemainingTime
        or StatusBarTimerDirection.ElapsedTime

    frame.__HRUI_TestCastbar = nil

    frame.casting = nil
    frame.channeling = nil
    frame.startTime = nil
    frame.endTime = nil
    frame.notInterruptible = nil

    frame.__HRUI_TargetTimerActive = true
    frame.__HRUI_TargetTimerKind = isChannel and "channel" or "cast"
    frame.__HRUI_TargetLastNotInterruptible = notInterruptible

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

    ApplyTargetCastbarColor(frame, isChannel, notInterruptible)

    frame:Show()
    return true
end

local function StartTargetCastbarFromUnit(frame, unit)
    if not frame or not unit or not UnitExists(unit) then
        return false
    end

    local castDuration = GetDurationCopy(UnitCastingDuration, unit)
    if castDuration then
        local name, _, texture, _, _, _, _, notInterruptible = UnitCastingInfo(unit)
        return StartTargetTimer(frame, name, texture, castDuration, false, notInterruptible)
    end

    local channelDuration = GetDurationCopy(UnitChannelDuration, unit)
    if channelDuration then
        local chName, _, chTexture, _, _, _, chNotInterruptible = UnitChannelInfo(unit)
        return StartTargetTimer(frame, chName, chTexture, channelDuration, true, chNotInterruptible)
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
        local targetDB = ns.db
            and ns.db.profile
            and ns.db.profile.castbars
            and ns.db.profile.castbars.target

        if not targetDB or not targetDB.enabled then
            ResetTargetCastbar(self)
            return
        end

        if self.__HRUI_TestCastbar then
            ns:UpdateCastbar(self)

            if not self.casting and not self.channeling then
                self.__HRUI_TestCastbar = nil
            end

            return
        end

        UpdateTargetTimeText(self)

        if self.__HRUI_TargetTimerActive then
            ApplyTargetCastbarColor(
                self,
                self.__HRUI_TargetTimerKind == "channel",
                self.__HRUI_TargetLastNotInterruptible
            )
        end
    end)

    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")

    for _, event in ipairs(spellcastEvents) do
        frame:RegisterUnitEvent(event, "target")
    end

    frame:SetScript("OnEvent", function(self, event)
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

        if stopEvents[event] then
            ResetTargetCastbar(self)
            return
        end

        if event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
            self.__HRUI_TargetLastNotInterruptible = true

            ApplyTargetCastbarColor(
                self,
                self.__HRUI_TargetTimerKind == "channel",
                true
            )

            return
        end

        if event == "UNIT_SPELLCAST_INTERRUPTIBLE" then
            self.__HRUI_TargetLastNotInterruptible = false

            ApplyTargetCastbarColor(
                self,
                self.__HRUI_TargetTimerKind == "channel",
                false
            )

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
