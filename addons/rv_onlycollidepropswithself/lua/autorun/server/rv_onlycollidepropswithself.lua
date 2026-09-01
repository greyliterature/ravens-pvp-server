hook.Add("PlayerSpawnedProp", "SetCollisionRules", function(ply, model, ent)
    --
    ent:SetCustomCollisionCheck(true)
end)

hook.Add("ShouldCollide", "OnlyCollideEntWithSelf", function(ent1, ent2)
    if not ent2:IsPlayer() then return end
    if ent1:GetCreator() ~= ent2 and ent2:IsPlayer() then --
        return false
    end
end)
