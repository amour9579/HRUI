local _, ns = ...

local function UpdatePlayerCastState(frame)
    if not frame or not ns.db.profile.castbars.player.enabled then
        if frame then
            ns:ResetCastbar(frame)
        end
        return
    end

    local name, _, texture, startTimeMS, endTimeMS, _, _, notInterruptible = UnitCastingInfo("player")
    if name and startTimeMS and endTimeMS then
        ns:StartCastbarCast(frame, name, texture, startTimeMS, endTimeMS, notInterruptible)
        return
    end

    local chName, _, chTexture, chStartTimeMS, chEndTimeMS, _, chNotInterruptible = UnitChannelInfo("player")
    if chName and chStartTimeMS and chEndTimeMS then
        ns:StartCastbarChannel(frame, chName, chTexture, chStartTimeMS, chEndTimeMS, chNotInterruptible)
        return
    end

    ns:ResetCastbar(frame)
end

function ns:SpawnPlayerCastbar()
    if ns.PlayerCastbar then
        return ns.PlayerCastbar
    end

    local db = ns.db.profile.castbars.player

    local frame = CreateFrame("StatusBar", "HRUI_PlayerCastbar", UIParent, "BackdropTemplate")
    frame.unit = "player"
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

    frame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_DELAYED", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "player")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")

    frame:SetScript("OnEvent", function(self, event, unit)
        if event ~= "PLAYER_ENTERING_WORLD" and unit ~= "player" then
            return
        end

        if event == "UNIT_SPELLCAST_STOP"
            or event == "UNIT_SPELLCAST_INTERRUPTED"
            or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
            ns:ResetCastbar(self)
            return
        end

        if event == "UNIT_SPELLCAST_FAILED" then
            UpdatePlayerCastState(self)
            return
        end

        UpdatePlayerCastState(self)
    end)

    ns.PlayerCastbar = frame
    return frame
end
