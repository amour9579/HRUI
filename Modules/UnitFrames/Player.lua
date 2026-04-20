local _, ns = ...

function ns:SpawnPlayerFrame(oUF)
    if ns.PlayerFrame then
        return ns.PlayerFrame
    end

    local db = ns.db.profile.unitframes.player
    local frame = oUF:Spawn("player", "HRUI_Player")
    frame:SetSize(db.width, db.height)
    frame:SetPoint("CENTER", UIParent, "CENTER", db.x, db.y)

    ns.PlayerFrame = frame
    return frame
end
