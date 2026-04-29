local _, ns = ...

local function DisableBlizzardPlayerCastBar()
    local blizz = _G.OverlayPlayerCastingBarFrame
    if not blizz then
        return
    end

    if blizz.__HRUI_Disabled then
        blizz:Hide()
        blizz:SetAlpha(0)
        return
    end

    blizz.__HRUI_Disabled = true
    blizz:UnregisterAllEvents()
    blizz:Hide()
    blizz:SetAlpha(0)
    blizz.Show = function() end

    if blizz.HookScript then
        blizz:HookScript("OnShow", function(self)
            self:Hide()
            self:SetAlpha(0)
        end)
    end
end

local function GetProfessionsCastBarAnchor()
    local ProfessionsFrame = _G.ProfessionsFrame
    if not ProfessionsFrame or not ProfessionsFrame:IsShown() then
        return nil
    end

    local craftingPage = ProfessionsFrame.CraftingPage
    if not craftingPage then
        return nil
    end

    return craftingPage.OverlayCastBarAnchor
end

local function ApplyProfessionVisualState(frame, usingProfessionAnchor)
    if not frame then
        return
    end

    if usingProfessionAnchor then
        frame:SetFrameStrata("HIGH")
        frame:SetFrameLevel(120)

        if frame.Icon then
            frame.Icon:Hide()
        end
    else
        frame:SetFrameStrata("MEDIUM")
        frame:SetFrameLevel(10)

        local db = ns.db and ns.db.profile and ns.db.profile.castbars and ns.db.profile.castbars.player
        if frame.Icon and db and db.icon and db.icon.enabled then
            frame.Icon:Show()
        end
    end
end
local function UpdatePlayerCastbarAnchor(frame)
    if not frame then
        return
    end

    local db = ns.db and ns.db.profile and ns.db.profile.castbars and ns.db.profile.castbars.player
    if not db then
        return
    end

    local anchor = GetProfessionsCastBarAnchor()
    frame:ClearAllPoints()

    if anchor then
        frame:SetParent(UIParent)
        frame:SetPoint("CENTER", anchor, "CENTER", 0, 0)
        frame:SetSize(240, 20)
        frame.__HRUI_UsingProfessionAnchor = true
        ApplyProfessionVisualState(frame, true)
    else
        frame:SetParent(UIParent)
        frame:SetPoint("CENTER", UIParent, "CENTER", db.x or 0, db.y or 0)
        frame:SetSize(db.width, db.height)
        frame.__HRUI_UsingProfessionAnchor = false
        ApplyProfessionVisualState(frame, false)
    end
end

function ns:UpdatePlayerCastbarAnchor(frame)
    UpdatePlayerCastbarAnchor(frame)
end

local function HookProfessionsCastbarAnchor()
    if ns.__HRUI_ProfessionsHooked then
        return
    end

    local ProfessionsFrame = _G.ProfessionsFrame
    if not ProfessionsFrame then
        return
    end

    ns.__HRUI_ProfessionsHooked = true

    ProfessionsFrame:HookScript("OnShow", function()
        DisableBlizzardPlayerCastBar()
        if ns.PlayerCastbar then
            UpdatePlayerCastbarAnchor(ns.PlayerCastbar)
        end
    end)

    ProfessionsFrame:HookScript("OnHide", function()
        if ns.PlayerCastbar then
            UpdatePlayerCastbarAnchor(ns.PlayerCastbar)
        end
    end)

    if ProfessionsFrame.CraftingPage and ProfessionsFrame.CraftingPage.HookScript then
        ProfessionsFrame.CraftingPage:HookScript("OnShow", function()
            DisableBlizzardPlayerCastBar()
            if ns.PlayerCastbar then
                UpdatePlayerCastbarAnchor(ns.PlayerCastbar)
            end
        end)

        ProfessionsFrame.CraftingPage:HookScript("OnHide", function()
            if ns.PlayerCastbar then
                UpdatePlayerCastbarAnchor(ns.PlayerCastbar)
            end
        end)
    end
end

local function UpdatePlayerCastState(frame)
    if not frame or not ns.db.profile.castbars.player.enabled then
        if frame then
            ns:ResetCastbar(frame)
        end
        return
    end

    local chName, _, chTexture, chStartTimeMS, chEndTimeMS, _, chNotInterruptible, _, isEmpowered, numEmpowerStages =
        UnitChannelInfo("player")

    if chName and isEmpowered then
        UpdatePlayerCastbarAnchor(frame)
        ns:StartCastbarEmpower(
            frame,
            "player",
            chName,
            chTexture,
            chStartTimeMS,
            chEndTimeMS,
            chNotInterruptible,
            numEmpowerStages
        )
        return
    end
    if chName and chStartTimeMS and chEndTimeMS then
        UpdatePlayerCastbarAnchor(frame)
        ns:StartCastbarChannel(frame, chName, chTexture, chStartTimeMS, chEndTimeMS, chNotInterruptible)
        return
    end

    local name, _, texture, startTimeMS, endTimeMS, _, _, notInterruptible =
        UnitCastingInfo("player")

    if name and startTimeMS and endTimeMS then
        UpdatePlayerCastbarAnchor(frame)
        ns:StartCastbarCast(frame, name, texture, startTimeMS, endTimeMS, notInterruptible)
        return
    end

    ns:ResetCastbar(frame)
end

function ns:SpawnPlayerCastbar()
    if ns.PlayerCastbar then
        DisableBlizzardPlayerCastBar()
        UpdatePlayerCastbarAnchor(ns.PlayerCastbar)
        return ns.PlayerCastbar
    end

    local db = ns.db.profile.castbars.player

    local frame = CreateFrame("StatusBar", "HRUI_PlayerCastbar", UIParent, "BackdropTemplate")
    frame.unit = "player"
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(10)
    frame:SetSize(db.width, db.height)
    frame:SetMinMaxValues(0, 1)
    frame:SetValue(0)

    ns:CreateCastbar(frame, db)
    UpdatePlayerCastbarAnchor(frame)
    frame:Hide()

    frame:SetScript("OnUpdate", function(self)
        ns:UpdateCastbar(self)
    end)

    frame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_DELAYED", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_UPDATE", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "player")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("ADDON_LOADED")

    frame:SetScript("OnEvent", function(self, event, arg1)
        if event == "ADDON_LOADED" then
            if arg1 == "Blizzard_Professions" then
                DisableBlizzardPlayerCastBar()
                HookProfessionsCastbarAnchor()
                UpdatePlayerCastbarAnchor(self)
                UpdatePlayerCastState(self)
            end
            return
        end

        if event == "PLAYER_ENTERING_WORLD" then
            DisableBlizzardPlayerCastBar()
            HookProfessionsCastbarAnchor()
            UpdatePlayerCastbarAnchor(self)
            UpdatePlayerCastState(self)
            return
        end

        if arg1 ~= "player" then
            return
        end

        if event == "UNIT_SPELLCAST_EMPOWER_START"
            or event == "UNIT_SPELLCAST_EMPOWER_UPDATE" then
            UpdatePlayerCastState(self)

            if C_Timer and C_Timer.After then
                C_Timer.After(0, function()
                    if ns.PlayerCastbar then
                        UpdatePlayerCastState(ns.PlayerCastbar)
                    end
                end)
            end

            return
        end

        if event == "UNIT_SPELLCAST_EMPOWER_STOP" then
            ns:ResetCastbar(self)
            return
        end

        -- Empower 중에는 일반 CHANNEL_STOP / STOP이 먼저 와도 지우지 않음
        if self.empowering and (
                event == "UNIT_SPELLCAST_STOP"
                or event == "UNIT_SPELLCAST_CHANNEL_STOP"
            ) then
            return
        end
        if event == "UNIT_SPELLCAST_STOP"
            or event == "UNIT_SPELLCAST_FAILED"
            or event == "UNIT_SPELLCAST_INTERRUPTED"
            or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
            ns:ResetCastbar(self)
            return
        end

        UpdatePlayerCastState(self)
    end)

    DisableBlizzardPlayerCastBar()

    ns.PlayerCastbar = frame
    return frame
end
