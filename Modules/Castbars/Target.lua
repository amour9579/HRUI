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
    UNIT_SPELLCAST_INTERRUPTED = true,
    UNIT_SPELLCAST_CHANNEL_STOP = true,
}

local function GetTargetCastUnit(eventUnit)
    if eventUnit and UnitExists(eventUnit) and UnitExists("target") and UnitIsUnit(eventUnit, "target") then
        return eventUnit
    end

    if UnitExists("target") then
        return "target"
    end

    return nil
end

local function UpdateTargetCastState(frame, eventUnit)
    if not frame or not UnitExists("target") or not ns.db.profile.castbars.target.enabled then
        if frame then
            ns:ResetCastbar(frame)
        end
        return
    end

    local unit = GetTargetCastUnit(eventUnit)
    if not unit then
        ns:ResetCastbar(frame)
        return
    end

    local name, _, texture, startTimeMS, endTimeMS, _, _, notInterruptible, spellID = UnitCastingInfo(unit)
    if name and startTimeMS and endTimeMS then
        local castKey = "cast:" ..
            tostring(spellID or name) .. ":" .. tostring(startTimeMS) .. ":" .. tostring(endTimeMS)

        if frame.__HRUI_TargetCastKey ~= castKey then
            frame.__HRUI_TargetCastKey = castKey
            ns:StartCastbarCast(frame, name, texture, startTimeMS, endTimeMS, notInterruptible)
        end
        return
    end

    local chName, _, chTexture, chStartTimeMS, chEndTimeMS, _, chNotInterruptible, chSpellID = UnitChannelInfo(unit)
    if chName and chStartTimeMS and chEndTimeMS then
        local castKey = "channel:" ..
            tostring(chSpellID or chName) .. ":" .. tostring(chStartTimeMS) .. ":" .. tostring(chEndTimeMS)

        if frame.__HRUI_TargetCastKey ~= castKey then
            frame.__HRUI_TargetCastKey = castKey
            ns:StartCastbarChannel(frame, chName, chTexture, chStartTimeMS, chEndTimeMS, chNotInterruptible)
        end
        return
    end

    frame.__HRUI_TargetCastKey = nil
    ns:ResetCastbar(frame)
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

        if self.__HRUI_TargetCastPoll >= 0.05 then
            self.__HRUI_TargetCastPoll = 0
            UpdateTargetCastState(self)
        end
        ns:UpdateCastbar(self)
    end)

    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")

    for _, event in ipairs(spellcastEvents) do
        frame:RegisterEvent(event)
    end

    frame:SetScript("OnEvent", function(self, event, unit)
        if event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
            UpdateTargetCastState(self)
            return
        end

        if event == "NAME_PLATE_UNIT_ADDED" then
            if unit and UnitExists("target") and UnitIsUnit(unit, "target") then
                UpdateTargetCastState(self, unit)
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
            self.__HRUI_TargetCastKey = nil
            ns:ResetCastbar(self)
            return
        end

        UpdateTargetCastState(self, unit)
    end)

    ns.TargetCastbar = frame
    return frame
end
