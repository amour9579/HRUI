local _, ns = ...

function ns:SpawnPetFrame(oUF)
    if ns.PetFrame then
        return ns.PetFrame
    end

    local db = ns.db.profile.unitframes.pet
    local frame = oUF:Spawn("pet", "HRUI_Pet")
    frame:SetSize(db.width, db.height)
    frame:SetPoint("CENTER", UIParent, "CENTER", db.x, db.y)

    ns.PetFrame = frame
    return frame
end
