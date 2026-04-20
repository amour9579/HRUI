local _, ns = ...

function ns.UnitFrameStyle(self, unit)
    self.unit = unit
    self:SetSize(260, 36)

    self:RegisterForClicks("AnyUp")
    self:EnableMouse(true)
    self:SetAttribute("unit", unit)
    self:SetAttribute("*type1", "target")
    self:SetAttribute("*type2", "togglemenu")

    ns:CreateBackdrop(self)
    ns:CreateHealth(self)
    ns:CreatePower(self)
    ns:CreateOverlay(self)
    ns:CreateMouseoverHighlight(self)
    ns:CreateName(self)
    ns:CreateHealthValue(self)
    ns:CreatePowerValue(self)
    if ns.CreatePlayerIcons then
        ns:CreatePlayerIcons(self)
    end
    if ns.CreateBuffIndicators then
        ns:CreateBuffIndicators(self)
    end

    self.Health.colorClass = true
    self.Health.colorReaction = true
    self.Health.colorDisconnected = true
    self.Health.colorTapping = true

    self.Power.colorPower = true

    ns:RefreshFrameElements(self)
end

local function ForceUpdateTag(fs)
    if not fs then
        return
    end

    if fs.UpdateTag then
        fs:UpdateTag()
    elseif fs.__owner and fs.__tag then
        fs.__owner:Tag(fs, fs.__tag)
    end
end

function ns:RefreshFrameElements(frame)
    if not frame then
        return
    end

    if ns.UpdatePowerBar then
        ns:UpdatePowerBar(frame)
    end

    if ns.UpdateNameFont then
        ns:UpdateNameFont(frame)
    end

    if ns.UpdateNamePosition then
        ns:UpdateNamePosition(frame)
    end

    if ns.UpdateHealthText then
        ns:UpdateHealthText(frame)
    end

    if ns.UpdatePowerText then
        ns:UpdatePowerText(frame)
    end

    if ns.UpdateFrameTexture then
        ns:UpdateFrameTexture(frame)
    end

    if ns.ApplyBackdropStyle then
        ns:ApplyBackdropStyle(frame, frame.__HRUIHovered)
    end

    if ns.RefreshPlayerIcons then
        ns:RefreshPlayerIcons(frame)
    end
    if ns.UpdateBuffIndicators then
        ns:UpdateBuffIndicators(frame)
    end

    ForceUpdateTag(frame.Name)
end

function ns:UpdateFrameTexture(frame)
    if not frame then
        return
    end

    local texture = ns:GetTexture()

    if frame.Health then
        frame.Health:SetStatusBarTexture(texture)
        if frame.Health.bg then
            frame.Health.bg:SetTexture(texture)
            frame.Health.bg:SetVertexColor(0.05, 0.05, 0.05, 0.85)
        end
    end

    if frame.Power then
        frame.Power:SetStatusBarTexture(texture)
        if frame.Power.bg then
            frame.Power.bg:SetTexture(texture)
            frame.Power.bg:SetVertexColor(0.05, 0.05, 0.05, 0.85)
        end
    end
end
