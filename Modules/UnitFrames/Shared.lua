local _, ns = ...

local function GetBorderDB()
    local profile = ns.db and ns.db.profile
    profile = profile or {}
    profile.borders = profile.borders or {}

    local db = profile.borders
    db.enabled = db.enabled ~= false
    db.color = db.color or { 0.20, 0.20, 0.20, 1.00 }
    db.hoverColor = db.hoverColor or { 0.90, 0.90, 0.90, 0.80 }

    return db
end

function ns:GetBorderColors()
    local db = GetBorderDB()
    return db.color, db.hoverColor, db.enabled
end

function ns:ApplyBackdropStyle(frame, hovered)
    if not frame or not frame.Backdrop then
        return
    end

    local baseColor, hoverColor, enabled = ns:GetBorderColors()

    if not enabled then
        frame.Backdrop:SetBackdrop(nil)
        frame.Backdrop:SetBackdropColor(0, 0, 0, 0)
        frame.Backdrop:SetBackdropBorderColor(0, 0, 0, 0)
        frame.Backdrop:Hide()
        return
    end

    frame.Backdrop:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame.Backdrop:SetBackdropColor(0.06, 0.06, 0.06, 0.9)

    local color = hovered and hoverColor or baseColor
    frame.Backdrop:SetBackdropBorderColor(
        color[1] or 1,
        color[2] or 1,
        color[3] or 1,
        color[4] or 1
    )

    frame.Backdrop:Show()
end

function ns:CreateBackdrop(frame)
    if not frame or frame.Backdrop then
        return
    end

    local bg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    bg:SetPoint("TOPLEFT", frame, "TOPLEFT", -1, 1)
    bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1)

    bg:SetFrameStrata(frame:GetFrameStrata())
    bg:SetFrameLevel(math.max(frame:GetFrameLevel() - 1, 0))

    frame.Backdrop = bg
    ns:ApplyBackdropStyle(frame)
end

function ns:CreateOverlay(frame)
    local overlay = CreateFrame("Frame", nil, frame)
    overlay:SetAllPoints(frame)
    overlay:SetFrameLevel(frame:GetFrameLevel() + 10)
    overlay:EnableMouse(false)

    frame.Overlay = overlay
end

function ns:CreateMouseoverHighlight(frame)
    if not frame or frame.__HRUIHoverHooked then
        return
    end

    frame.__HRUIHoverHooked = true

    frame:EnableMouse(true)

    frame:HookScript("OnEnter", function(self)
        self.__HRUIHovered = true

        if self.Backdrop then
            ns:ApplyBackdropStyle(self, true)
        end

        if self.unit and UnitExists(self.unit) then
            GameTooltip_SetDefaultAnchor(GameTooltip, self)
            GameTooltip:SetUnit(self.unit)
            GameTooltip:Show()
        end
    end)

    frame:HookScript("OnLeave", function(self)
        self.__HRUIHovered = nil

        if self.Backdrop then
            ns:ApplyBackdropStyle(self, false)
        end

        GameTooltip:Hide()
    end)

    frame:HookScript("OnHide", function(self)
        self.__HRUIHovered = nil

        if self.Backdrop then
            ns:ApplyBackdropStyle(self, false)
        end

        GameTooltip:Hide()
    end)
end
