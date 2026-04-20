local _, ns = ...

function ns:SpawnTargetFrame(oUF)
    if ns.TargetFrame then
        return ns.TargetFrame
    end

    local db = ns.db.profile.unitframes.target
    local frame = oUF:Spawn("target", "HRUI_Target")
    frame:SetSize(db.width, db.height)
    frame:SetPoint("CENTER", UIParent, "CENTER", db.x, db.y)

    ns.TargetFrame = frame
    return frame
end
