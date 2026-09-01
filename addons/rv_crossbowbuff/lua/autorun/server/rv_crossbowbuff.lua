--[[
hook.Add("EntityTakeDamage", "Crossbow150Damage", function(target, dmg)
    if target:IsPlayer() and dmg:GetInflictor():GetClass() == "crossbow_bolt" then --
        dmg:SetDamage(150)
    end
end)
--]]
