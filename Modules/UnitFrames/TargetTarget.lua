local _, ns = ...

function ns:SpawnTargetTargetFrame(oUF)
    if ns.TargetTargetFrame then
        return ns.TargetTargetFrame
    end

    local db = ns.db.profile.unitframes.targettarget
    local frame = oUF:Spawn("targettarget", "HRUI_TargetTarget")
    frame:SetSize(db.width, db.height)
    frame:SetPoint("CENTER", UIParent, "CENTER", db.x, db.y)

    ns.TargetTargetFrame = frame
    return frame
end
