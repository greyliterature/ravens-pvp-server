--https://wiki.facepunch.com/gmod/Enums/DMG
--https://wiki.facepunch.com/gmod/GM:EntityTakeDamage
-- makes some weapons have no damage like supers (props, fall damage, ar2 orb, rpg) 
hook.Add("EntityTakeDamage", "DamageScales", function(target, dmginfo)
	if target:IsPlayer() then
		if dmginfo:IsDamageType(1) then -- Prop damage, also ar2 orb damage?
			dmginfo:ScaleDamage(0)
		elseif IsValid(dmginfo:GetWeapon()) and dmginfo:GetWeapon():GetClass() == "weapon_rpg" then
			-- rpg damage
			dmginfo:ScaleDamage(0)
		end
	end
end)

hook.Add("GetFallDamage", "NoFallDamage", function(ply, speed) return 0 end)