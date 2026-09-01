hook.Add("PlayerSpawnedProp", "AddOwnerOfProp", function(ply, model, entity)
    entity:SetCreator(ply)
    if not ply.PropProtectionEntities then ply.PropProtectionEntities = {} end
    ply.PropProtectionEntities[entity] = true
end)

hook.Add("PhysgunPickup", "PropProtection", function(ply, entity)
    if entity:IsPlayer() then return end
    if ply:IsSuperAdmin() or entity:GetCreator() == ply then -- shouldcollide messes with physgun traces... superadmins cant pick up other's props no matter what. oh well.
        return true
        --elseif (entity:GetCreator() ~= ply or entity:GetCreator() ~= NULL) then
        --return false
    end
    return false
end)

hook.Add("GravGunPunt", "TurnOffGravGunPunt", function(ply, entity)
    --return false
end)

hook.Add("CanProperty", "PreventProperties", function(ply, property, ent) if not ply:IsSuperAdmin() then return false end end)
hook.Add("PlayerDisconnected", "ClearPropsOnDisconnect", function(ply)
    if not ply.PropProtectionEntities then return end
    for entity, _ in pairs(ply.PropProtectionEntities) do
        if not IsValid(entity) then continue end
        entity:Remove()
    end

    ply.PropProtectionEntities = nil
end)