for _, ply in player.Iterator() do
    ply:SetTeam(TEAM_UNASSIGNED)
    FSpectate.forceUnspectate(ply)
    ply:Spawn()
end

net.Receive("RequestTeamJoin", function()
    --
    return
end)

net.Receive("ReadyUp", function()
    --
    return
end)

removedClasses["weapon_frag"] = true
include("autorun/server/rv_motd.lua")
include("autorun/damagelogic.lua")
include("autorun/server/rv_duels.lua")
include("autorun/server/rv_autortv.lua")
PrintMessage(HUD_PRINTTALK, "(server) set gamemode to ffa")
