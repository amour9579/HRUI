local _, ns = ...

local function UpdateTargetCastState(frame)
    if not frame or not UnitExists("target") or not ns.db.profile.castbars.target.enabled then
        if frame then
            ns:ResetCastbar(frame)
        end
        return
    end

    local name, _, texture, startTimeMS, endTimeMS, _, _, notInterruptible = UnitCastingInfo("target")
    if name and startTimeMS and endTimeMS then
        ns:StartCastbarCast(frame, name, texture, startTimeMS, endTimeMS, notInterruptible)
        return
    end

    local chName, _, chTexture, chStartTimeMS, chEndTimeMS, _, chNotInterruptible = UnitChannelInfo("target")
    if chName and chStartTimeMS and chEndTimeMS then
        ns:StartCastbarChannel(frame, chName, chTexture, chStartTimeMS, chEndTimeMS, chNotInterruptible)
        return
    end

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

    frame:SetScript("OnUpdate", function(self)
        ns:UpdateCastbar(self)
    end)

    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_START", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_DELAYED", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "target")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")

    frame:SetScript("OnEvent", function(self, event, unit)
        if event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
            UpdateTargetCastState(self)
            return
        end

        if unit ~= "target" then
            return
        end

        if event == "UNIT_SPELLCAST_STOP"
            or event == "UNIT_SPELLCAST_INTERRUPTED"
            or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
            ns:ResetCastbar(self)
            return
        end

        if event == "UNIT_SPELLCAST_FAILED" then
            UpdateTargetCastState(self)
            return
        end

        UpdateTargetCastState(self)
    end)

    ns.TargetCastbar = frame
    return frame
end
