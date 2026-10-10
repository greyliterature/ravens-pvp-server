local rv_gm = include("../gm_universal/gm_universal.lua")
--[[----------------------------------------------------------------------
    autorefresh
------------------------------------------------------------------------]]
rv_gm.ResetScores()
timer.Simple(0, function()
    for _, ply in player.Iterator() do
        if ply:IsBot() == true then ply:SetTeam(1) end
    end
end)

--[[----------------------------------------------------------------------
    init
------------------------------------------------------------------------]]
local TEAM_RED, TEAM_BLUE = 1, 2
team.SetUp(TEAM_RED, "Red Team", Color(255, 0, 0), true)
team.SetUp(TEAM_BLUE, "Blue Team", Color(0, 0, 255), true)
rv_gm.SetAllToSpectate(true)
rv_gm.AllowPlayerRespawns(false)
rv_gm.EnableTeamJoins(true)
rv_gm.SetUpTeams({
    [TEAM_RED] = {
        teamname = "Red team",
        teamcolor = Color(255, 0, 0),
        isjoinable = true,
    },
    [TEAM_BLUE] = {
        teamname = "Blue team",
        teamcolor = Color(0, 0, 255),
        isjoinable = true,
    }
})

rv_gm.RemoveConflictingHooks()
rv_gm.DisablePlayerRewards()
--[[----------------------------------------------------------------------
    Revelation / return
------------------------------------------------------------------------]]
rv_gm.SetFlagReturnDelay(10)
rv_gm.SetRevelationDelay(5)
AddGamemodeHook("rv_gm.FlagRevealed", "RevealNotif", function(revealedply, ent, Revealed)
    --
    if not revealedply then return end
    rv_gm.SendNotif(revealedply, {"Position revealed"}, {CurTime() + 1}, nil, true)
end)

--[[----------------------------------------------------------------------
    Death
------------------------------------------------------------------------]]
local RespawnDelay = 5
AddGamemodeHook("PlayerDeath", "SetSpecOnDeath", function(victim, _, _)
    rv_gm.ForcePlayerToSpectate(victim)
    timer.Simple(RespawnDelay, function()
        rv_gm.ForcePlayerToUnSpectate(victim)
        victim:Spawn()
        return
    end)
    return
end)

--[[----------------------------------------------------------------------
    Readyup
------------------------------------------------------------------------]]
rv_gm.SetReadyUpRatio(0.75)
rv_gm.SetPlayersCanReadyUp(true)
AddGamemodeHook("rv_gm.CanPlayerReadyUp", "NoReadyUpsForSpec", function(ply)
    if ply:Team() == TEAM_SPECTATOR then --
        return false, "Spectators cannot ready up."
    end
end)

AddGamemodeHook("rv_gm.ShouldIncludePlayer", "ExcludeSpectatorsFromReadyup", function(ply)
    if ply:Team() == TEAM_SPECTATOR then --
        return false
    end
    return
end)

rv_gm.SetScoreLimit(7)
AddGamemodeHook("ShouldSpectateOnJoin", "SetSpectateOnJoin", function(ply)
    return true --
end)

-- round start 
-- there is no RoundEnded for CTF because it is really just one round, this is just for notification formality
local RoundStartDelay = 5
AddGamemodeHook("rv_gm.RoundStarted", "RoundStarted", function(RoundCount)
    rv_gm.LockAttacks(RoundStartDelay)
    rv_gm.RespawnAllPlayers()
    rv_gm.SendNotif(nil, {"5", "4", "3", "2", "1", "FIGHT!"}, {CurTime() + 1, CurTime() + 2, CurTime() + 3, CurTime() + 4, CurTime() + 5, CurTime() + 6}, "Round begins in")
    rv_gm.SetTimeLimit(600 + RoundStartDelay)
    return
end)

--match start / end 
local MatchStartDelay = 3
AddGamemodeHook("rv_gm.MatchStarted", "MatchStarted", function()
    rv_gm.LockAttacks(MatchStartDelay + 1)
    for doll, _ in pairs(rv_gm.GetAllDollFlags()) do
        rv_gm.ReturnDollFlagToBase(doll)
    end

    timer.Simple(1, function()
        rv_gm.ShuffleTeams()
        rv_gm.SendNotif(nil, {"Starts in: 3", "Starts in: 2", "Starts in: 1"}, {CurTime() + 1, CurTime() + 2, CurTime() + 3}, "Capture the Flag")
        rv_gm.RespawnAllPlayers()
        --rv_gm.SetMatchInProgress(true) -- rv_gm.StartMatch() handles this for you 
        -- this seems redundant and unnecessary 
        timer.Simple(MatchStartDelay, function()
            --
            rv_gm.StartRound()
        end)
    end)
    return
end)

AddGamemodeHook("rv_gm.MatchEnded", "MatchEnded", function(WinnerIndex, loserstbl)
    ColoredChatPrint({team.GetColor(WinnerIndex), team.GetName(WinnerIndex), " wins " .. team.GetScore(WinnerIndex) .. " - " .. table.concat(loserstbl, " ")})
    SetGamemode("FFA")
    if mapvote then
        mapvote.StartMapVote()
    else
        ErrorNoHaltWithStack("NO MAPVOTE")
    end

    print("MATCH ENDED")
end)

--[[
AddGamemodeHook("rv_gm.CanPickupDollFlag", "AllowDollFlagPickup", function(ply, ent)
    print("HI!")
    if ply:Team() == ent.teamindex then --
        return false
    end
    return
end)
--]]
AddGamemodeHook("rv_gm.DollFlagPickedUp", "DollFlagRTB", function(ply, ent)
    print("HI", ply:Team(), ply, ent)
    if ply:Team() == ent.TeamIndex then
        rv_gm.ReturnDollFlagToBase(ent)
        ent:ForcePlayerDrop()
    else
        rv_gm.SetDollPhysicsNormal(ent)
        ent.AtHomeBase = false
    end
end)

AddGamemodeHook("rv_gm.DollFlagPunt", "DollFlagRTB", function(ply, ent)
    if ply:Team() == ent.TeamIndex then
        rv_gm.ReturnDollFlagToBase(ent)
    else
        ent.AtHomeBase = false
    end
end)

--rv_gm.CreateDollFlagBase(Vector(0, 0, 0), TEAM_RED, true)
--rv_gm.CreateDollFlagBase(Vector(0, 150, 0), TEAM_BLUE, true)
rv_gm.spawns = rv_gm.spawns or {}
for i = #rv_gm.spawns, 1, -1 do
    if IsValid(spawn) then spawn:Remove() end
    table.remove(rv_gm.spawns, i)
end

AddGamemodeHook("rv_gm.GamemodeDataLoaded", "GetFlagData", function(gamemodetbl)
    local map = game.GetMap()
    if table.Count(gamemodetbl[map]["Flags"]) == 0 then
        PrintMessage(HUD_PRINTTALK, "NO FLAGS")
        SetGamemode("FFA")
        return
    end

    for teamindex, flagpos in pairs(gamemodetbl[map]["Flags"]) do
        rv_gm.CreateDollFlagBase(flagpos, teamindex, true)
    end

    for teamindex, tbl in pairs(gamemodetbl[map]["Spawns"]) do
        local pos = tbl[1]
        local angs = tbl[2]
        local usePitch = nil
        rv_gm.spawns[#rv_gm.spawns + 1] = CreateSpawnPoint(nil, pos, angs, usePitch, teamindex)
    end
end)

rv_gm.RequestGamemodeData()
