local _, ns = ...

local function GetBlizzardTargetCastbar()
    if _G.TargetFrameSpellBar then
        return _G.TargetFrameSpellBar
    end

    local targetFrame = _G.TargetFrame
    if not targetFrame then
        return nil
    end

    return targetFrame.SpellBar
        or targetFrame.spellbar
        or targetFrame.CastBar
        or targetFrame.castbar
end

local function SafeCall(object, method, ...)
    if not object or type(object[method]) ~= "function" then
        return false
    end

    return pcall(object[method], object, ...)
end

local function GetTargetCastbarDB()
    return ns.db
        and ns.db.profile
        and ns.db.profile.castbars
        and ns.db.profile.castbars.target
end

local function ApplyTargetCastbarSettings(frame)
    local db = GetTargetCastbarDB()
    if not frame or not db then
        return
    end

    if not db.enabled then
        SafeCall(frame, "Hide")
        return
    end

    SafeCall(frame, "SetParent", UIParent)
    SafeCall(frame, "SetFrameStrata", "MEDIUM")
    SafeCall(frame, "SetFrameLevel", 10)

    SafeCall(frame, "ClearAllPoints")
    SafeCall(frame, "SetPoint", "CENTER", UIParent, "CENTER", db.x or 0, db.y or 0)
    SafeCall(frame, "SetSize", db.width or 350, db.height or 30)

    if ns.GetTexture then
        SafeCall(frame, "SetStatusBarTexture", ns:GetTexture())
    end

    if ns.CreateCastbar then
        ns:CreateCastbar(frame, db)
    end

    if frame.BG then
        SafeCall(frame.BG, "Show")
    end

    if frame.Icon then
        SafeCall(frame.Icon, "SetSize", db.icon and db.icon.size or db.height or 30,
            db.icon and db.icon.size or db.height or 30)

        if db.icon and db.icon.enabled then
            SafeCall(frame.Icon, "Show")
        else
            SafeCall(frame.Icon, "Hide")
        end
    end

    if frame.Text then
        if db.text and db.text.enabled then
            SafeCall(frame.Text, "Show")
        else
            SafeCall(frame.Text, "Hide")
        end
    end

    if frame.Time then
        if db.time and db.time.enabled then
            SafeCall(frame.Time, "Show")
        else
            SafeCall(frame.Time, "Hide")
        end
    end
end

local function ApplyTargetCastbarSettingsSoon(frame)
    ApplyTargetCastbarSettings(frame)

    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            ApplyTargetCastbarSettings(frame)
        end)

        C_Timer.After(0.05, function()
            ApplyTargetCastbarSettings(frame)
        end)
    end
end

local function HookTargetCastbar(frame)
    if not frame or frame.__HRUI_TargetCastbarHooked then
        return
    end

    frame.__HRUI_TargetCastbarHooked = true

    if frame.HookScript then
        frame:HookScript("OnShow", function(self)
            local db = GetTargetCastbarDB()

            if db and not db.enabled then
                self:Hide()
                return
            end

            ApplyTargetCastbarSettingsSoon(self)
        end)
    end
end

local function CreateTargetCastbarDriver(frame)
    if frame.__HRUI_TargetCastbarDriver then
        return
    end

    local driver = CreateFrame("Frame")
    frame.__HRUI_TargetCastbarDriver = driver

    driver:RegisterEvent("PLAYER_ENTERING_WORLD")
    driver:RegisterEvent("PLAYER_TARGET_CHANGED")
    driver:RegisterEvent("PLAYER_REGEN_ENABLED")

    driver:SetScript("OnEvent", function()
        ApplyTargetCastbarSettingsSoon(frame)
    end)
end

function ns:SpawnTargetCastbar()
    if ns.TargetCastbar then
        ApplyTargetCastbarSettingsSoon(ns.TargetCastbar)
        return ns.TargetCastbar
    end

    local frame = GetBlizzardTargetCastbar()
    if not frame then
        return nil
    end

    frame.unit = "target"

    HookTargetCastbar(frame)
    CreateTargetCastbarDriver(frame)
    ApplyTargetCastbarSettingsSoon(frame)

    ns.TargetCastbar = frame
    return frame
end
