local _, ns = ...

function ns:SpawnFocusFrame(oUF)
    if ns.FocusFrame then
        return ns.FocusFrame
    end

    local db = ns.db.profile.unitframes.focus
    local frame = oUF:Spawn("focus", "HRUI_Focus")
    frame:SetSize(db.width, db.height)
    frame:SetPoint("CENTER", UIParent, "CENTER", db.x, db.y)

    ns.FocusFrame = frame
    return frame
end
