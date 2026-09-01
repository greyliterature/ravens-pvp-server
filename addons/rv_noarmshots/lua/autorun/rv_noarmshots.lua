-- thanks zynx
hook.Add( "PostGamemodeLoaded", "limb_damage", function()
    function GAMEMODE:ScalePlayerDamage( ply, hitgroup, dmginfo )
        if ( hitgroup == HITGROUP_HEAD ) then
            dmginfo:ScaleDamage( 2 )
        end

        if ( hitgroup == HITGROUP_LEFTLEG ) or ( hitgroup == HITGROUP_RIGHTLEG ) then
            dmginfo:ScaleDamage( 0.25 )
        end
    end

    GAMEMODE.ScaleNPCDamage = GAMEMODE.ScalePlayerDamage
end )
