local _, ns = ...

local function UpdatePetCastState(frame)
    if not frame or not UnitExists("pet") or not ns.db.profile.castbars.pet.enabled then
        if frame then
            ns:ResetCastbar(frame)
        end
        return
    end

    local name, _, texture, startTimeMS, endTimeMS, _, _, notInterruptible = UnitCastingInfo("pet")
    if name and startTimeMS and endTimeMS then
        ns:StartCastbarCast(frame, name, texture, startTimeMS, endTimeMS, notInterruptible)
        return
    end

    local chName, _, chTexture, chStartTimeMS, chEndTimeMS, _, chNotInterruptible = UnitChannelInfo("pet")
    if chName and chStartTimeMS and chEndTimeMS then
        ns:StartCastbarChannel(frame, chName, chTexture, chStartTimeMS, chEndTimeMS, chNotInterruptible)
        return
    end

    ns:ResetCastbar(frame)
end

function ns:SpawnPetCastbar()
    if ns.PetCastbar then
        return ns.PetCastbar
    end

    local db = ns.db.profile.castbars.pet

    local frame = CreateFrame("StatusBar", "HRUI_PetCastbar", UIParent, "BackdropTemplate")
    frame.unit = "pet"
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

    frame:RegisterEvent("UNIT_PET")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")

    frame:RegisterUnitEvent("UNIT_SPELLCAST_START", "pet")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "pet")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "pet")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "pet")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_DELAYED", "pet")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "pet")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "pet")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "pet")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE", "pet")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "pet")

    frame:SetScript("OnEvent", function(self, event, unit)
        if event == "PLAYER_ENTERING_WORLD" then
            UpdatePetCastState(self)
            return
        end

        if event == "UNIT_PET" then
            if unit == "player" then
                UpdatePetCastState(self)
            end
            return
        end

        if unit ~= "pet" then
            return
        end

        if event == "UNIT_SPELLCAST_STOP"
            or event == "UNIT_SPELLCAST_INTERRUPTED"
            or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
            ns:ResetCastbar(self)
            return
        end

        if event == "UNIT_SPELLCAST_FAILED" then
            UpdatePetCastState(self)
            return
        end

        UpdatePetCastState(self)
    end)

    ns.PetCastbar = frame
    return frame
end
