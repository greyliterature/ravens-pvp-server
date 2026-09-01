CreateClientConVar("rv_handicap", "100", false, true, "percentage damage to give to other players", 1, 100)
if SERVER then
    hook.Add("ScalePlayerDamage", "HandicapDamage", function(ply, hitgroup, dmginfo)
        local Attacker = dmginfo:GetAttacker()
        if not Attacker:IsPlayer() then return end
        if Attacker:IsBot() then return end
        local AttackerHandicap = math.Clamp(Attacker:GetInfoNum("rv_handicap", 100), 1, 100)
        dmginfo:ScaleDamage(0.01 * AttackerHandicap)
    end)
end
