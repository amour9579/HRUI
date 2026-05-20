local _, ns = ...

local DEFAULT_MAX_BOSS_FRAMES = 5

local StatusBarTimerDirection = Enum.StatusBarTimerDirection
local StatusBarInterpolation = Enum.StatusBarInterpolation

local spellcastEvents = {
    "UNIT_SPELLCAST_START",
    "UNIT_SPELLCAST_STOP",
    "UNIT_SPELLCAST_FAILED",
    "UNIT_SPELLCAST_INTERRUPTED",
    "UNIT_SPELLCAST_DELAYED",
    "UNIT_SPELLCAST_EMPOWER_START",
    "UNIT_SPELLCAST_EMPOWER_UPDATE",
    "UNIT_SPELLCAST_EMPOWER_STOP",
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
    UNIT_SPELLCAST_EMPOWER_STOP = true,
}

local startEvents = {
    UNIT_SPELLCAST_START = true,
    UNIT_SPELLCAST_DELAYED = true,
    UNIT_SPELLCAST_EMPOWER_START = true,
    UNIT_SPELLCAST_EMPOWER_UPDATE = true,
    UNIT_SPELLCAST_CHANNEL_START = true,
    UNIT_SPELLCAST_CHANNEL_UPDATE = true,
}

local function GetMaxBossFrames()
    return tonumber(_G.MAX_BOSS_FRAMES) or DEFAULT_MAX_BOSS_FRAMES
end

local function GetBossCastbarDB()
    return ns.db
        and ns.db.profile
        and ns.db.profile.castbars
        and ns.db.profile.castbars.boss
end

local function GetBossUnitFrame(index)
    return ns.BossFrames and ns.BossFrames[index]
end

local function GetBossCastbarStyle()
    if ns.GetCastbarStyle then
        local style = ns:GetCastbarStyle("boss")

        return {
            cast = style.cast,
            channel = style.channel,
            nonInterruptible = style.nonInterruptible,
        }
    end

    return {
        cast = { 0.95, 0.75, 0.20 },
        channel = { 0.20, 0.70, 1.00 },
        nonInterruptible = { 0.75, 0.20, 0.20 },
    }
end

local function SetBossCastbarColor(frame, color)
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

local function ApplyBossCastbarColor(frame, isChannel, notInterruptible)
    if not frame then
        return
    end

    local style = GetBossCastbarStyle()
    local baseColor = isChannel and style.channel or style.cast
    local nonInterruptibleColor = style.nonInterruptible

    if ApplyBooleanColor(frame, notInterruptible, nonInterruptibleColor, baseColor) then
        return
    end

    SetBossCastbarColor(frame, baseColor)
end

local function ResetBossCastbar(frame)
    if frame then
        frame.__HRUI_BossTimerActive = nil
        frame.__HRUI_BossTimerKind = nil
        frame.__HRUI_BossLastNotInterruptible = nil
        frame.__HRUI_BossPollElapsed = 0
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
        return d and d:Copy()
    end)

    if ok then
        return duration
    end

    return nil
end

local function ApplyBossCastbarAnchor(castbar, bossFrame, db)
    if not castbar or not bossFrame or not db then
        return
    end

    castbar:SetParent(bossFrame)
    castbar:ClearAllPoints()
    castbar:SetPoint("TOP", bossFrame, "BOTTOM", db.x or 0, db.y or -4)
    castbar:SetSize(db.width or 220, db.height or 18)
end

local function StartBossTimer(frame, spellName, icon, duration, isChannel, notInterruptible)
    if not frame or not duration or not frame.SetTimerDuration then
        return false
    end

    local direction = isChannel
        and StatusBarTimerDirection.RemainingTime
        or StatusBarTimerDirection.ElapsedTime

    frame.casting = nil
    frame.channeling = nil
    frame.empowering = nil
    frame.startTime = nil
    frame.endTime = nil
    frame.notInterruptible = nil

    frame.__HRUI_BossTimerActive = true
    frame.__HRUI_BossTimerKind = isChannel and "channel" or "cast"
    frame.__HRUI_BossLastNotInterruptible = notInterruptible

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

    ApplyBossCastbarColor(frame, isChannel, notInterruptible)

    frame:Show()
    return true
end

local function StartBossCastbarFromUnit(frame, unit)
    if not frame or not unit or not UnitExists(unit) then
        return false
    end

    local channelInfo = { UnitChannelInfo(unit) }
    local chName = channelInfo[1]
    local chTexture = channelInfo[3]
    local chStartTimeMS = channelInfo[4]
    local chEndTimeMS = channelInfo[5]
    local chNotInterruptible = channelInfo[7]
    local isEmpowered = channelInfo[9]
    local numEmpowerStages = channelInfo[10]

    if chName and isEmpowered and ns.StartCastbarEmpower then
        frame.__HRUI_BossTimerActive = nil
        frame.__HRUI_BossTimerKind = nil
        frame.__HRUI_BossLastNotInterruptible = chNotInterruptible

        ns:StartCastbarEmpower(
            frame,
            unit,
            chName,
            chTexture,
            chStartTimeMS,
            chEndTimeMS,
            chNotInterruptible,
            numEmpowerStages
        )
        return true
    end

    local castDuration = GetDurationCopy(UnitCastingDuration, unit)
    if castDuration then
        local name, _, texture, _, _, _, _, notInterruptible = UnitCastingInfo(unit)
        return StartBossTimer(frame, name, texture, castDuration, false, notInterruptible)
    end

    local channelDuration = GetDurationCopy(UnitChannelDuration, unit)
    if channelDuration then
        return StartBossTimer(frame, chName, chTexture, channelDuration, true, chNotInterruptible)
    end

    local castInfo = { UnitCastingInfo(unit) }
    local name = castInfo[1]
    local texture = castInfo[3]
    local startTimeMS = castInfo[4]
    local endTimeMS = castInfo[5]
    local notInterruptible = castInfo[8]

    if name and startTimeMS and endTimeMS and ns.StartCastbarCast then
        frame.__HRUI_BossTimerActive = nil
        frame.__HRUI_BossTimerKind = nil
        frame.__HRUI_BossLastNotInterruptible = notInterruptible

        ns:StartCastbarCast(
            frame,
            name,
            texture,
            startTimeMS,
            endTimeMS,
            notInterruptible
        )
        return true
    end

    if chName and chStartTimeMS and chEndTimeMS and ns.StartCastbarChannel then
        frame.__HRUI_BossTimerActive = nil
        frame.__HRUI_BossTimerKind = nil
        frame.__HRUI_BossLastNotInterruptible = chNotInterruptible

        ns:StartCastbarChannel(
            frame,
            chName,
            chTexture,
            chStartTimeMS,
            chEndTimeMS,
            chNotInterruptible
        )
        return true
    end

    return false
end

local function ForceUpdateBossCastbar(frame)
    if not frame then
        return
    end

    local db = GetBossCastbarDB()
    local unit = frame.unit

    if not db or not db.enabled or not unit or not UnitExists(unit) then
        ResetBossCastbar(frame)
        return
    end

    if not StartBossCastbarFromUnit(frame, unit) then
        ResetBossCastbar(frame)
    end
end

local function UpdateBossTimeText(frame)
    if not frame or not frame.__HRUI_BossTimerActive then
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

local function PollBossCastbar(frame, elapsed)
    if not frame then
        return
    end

    frame.__HRUI_BossPollElapsed = (frame.__HRUI_BossPollElapsed or 0) + (elapsed or 0)
    if frame.__HRUI_BossPollElapsed < 0.15 then
        return
    end

    frame.__HRUI_BossPollElapsed = 0

    local db = GetBossCastbarDB()
    if not db or not db.enabled then
        return
    end

    if frame.__HRUI_BossTimerActive or frame.casting or frame.channeling or frame.empowering then
        return
    end

    if frame.unit and UnitExists(frame.unit) then
        StartBossCastbarFromUnit(frame, frame.unit)
    end
end

local function CreateBossCastbar(index, bossFrame)
    local db = GetBossCastbarDB()
    if not db or not bossFrame then
        return nil
    end

    local unit = "boss" .. index
    local castbar = CreateFrame("StatusBar", "HRUI_Boss" .. index .. "Castbar", bossFrame, "BackdropTemplate")
    castbar.unit = unit
    castbar.castbarStyleUnit = "boss"
    castbar.__HRUIBossCastbar = true
    castbar:SetFrameStrata("MEDIUM")
    castbar:SetFrameLevel((bossFrame:GetFrameLevel() or 10) + 1)
    castbar:SetMinMaxValues(0, 1)
    castbar:SetValue(0)

    ns:CreateCastbar(castbar, db)
    ApplyBossCastbarAnchor(castbar, bossFrame, db)
    castbar:Hide()

    castbar:SetScript("OnUpdate", function(self, elapsed)
        if self.casting or self.channeling or self.empowering then
            ns:UpdateCastbar(self)
        end

        UpdateBossTimeText(self)

        if self.__HRUI_BossTimerActive then
            ApplyBossCastbarColor(
                self,
                self.__HRUI_BossTimerKind == "channel",
                self.__HRUI_BossLastNotInterruptible
            )
        end

        PollBossCastbar(self, elapsed)
    end)

    castbar:RegisterEvent("PLAYER_ENTERING_WORLD")
    castbar:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")

    for _, event in ipairs(spellcastEvents) do
        castbar:RegisterUnitEvent(event, unit)
    end

    castbar:SetScript("OnEvent", function(self, event, arg1)
        if event == "PLAYER_ENTERING_WORLD" or event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
            ResetBossCastbar(self)
            ForceUpdateBossCastbar(self)

            if C_Timer and C_Timer.After then
                C_Timer.After(0, function()
                    ForceUpdateBossCastbar(self)
                end)
            end

            return
        end

        if arg1 ~= self.unit then
            return
        end

        if stopEvents[event] then
            ResetBossCastbar(self)
            return
        end

        if event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
            self.__HRUI_BossLastNotInterruptible = true

            ApplyBossCastbarColor(
                self,
                self.__HRUI_BossTimerKind == "channel",
                true
            )

            return
        end

        if event == "UNIT_SPELLCAST_INTERRUPTIBLE" then
            self.__HRUI_BossLastNotInterruptible = false

            ApplyBossCastbarColor(
                self,
                self.__HRUI_BossTimerKind == "channel",
                false
            )

            return
        end

        if startEvents[event] then
            if not StartBossCastbarFromUnit(self, self.unit) then
                ResetBossCastbar(self)
            end
        end
    end)

    return castbar
end

function ns:SpawnBossCastbars()
    ns.BossCastbars = ns.BossCastbars or {}

    for index = 1, GetMaxBossFrames() do
        local bossFrame = GetBossUnitFrame(index)
        if bossFrame and not ns.BossCastbars[index] then
            ns.BossCastbars[index] = CreateBossCastbar(index, bossFrame)
        end
    end

    return ns.BossCastbars
end

function ns:RefreshBossCastbars()
    local db = GetBossCastbarDB()
    if not db then
        return
    end

    ns:SpawnBossCastbars()

    for index = 1, GetMaxBossFrames() do
        local bossFrame = GetBossUnitFrame(index)
        local castbar = ns.BossCastbars and ns.BossCastbars[index]

        if bossFrame and not castbar then
            castbar = CreateBossCastbar(index, bossFrame)
            ns.BossCastbars[index] = castbar
        end

        if castbar and bossFrame then
            castbar.castbarStyleUnit = "boss"
            ApplyBossCastbarAnchor(castbar, bossFrame, db)
            ns:CreateCastbar(castbar, db)

            if ns.ApplyCastbarTextSettings then
                ns:ApplyCastbarTextSettings(castbar, db)
            end

            if db.enabled then
                ForceUpdateBossCastbar(castbar)
            else
                ResetBossCastbar(castbar)
            end
        end
    end
end
