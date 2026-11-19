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
rv_gm.SetAllToSpectate(true)
rv_gm.AllowPlayerFriendlyFire(false)
rv_gm.AllowPlayerRespawns(false)
rv_gm.AllowPlayerSuicide(false)
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

RunConsoleCommand("unblacklistclass", "weapon_frag")
AddGamemodeHook("PlayerSetModel", "ClanArenaSetArmor", function(ply)
    ply:SetArmor(100)
    ply:SetMaxArmor(100)
end)

--rv_gm.SetRoundLimit(10) score limit is more appropriate
rv_gm.RemoveConflictingHooks()
rv_gm.DisablePlayerRewards()
--[[----------------------------------------------------------------------
    Death
------------------------------------------------------------------------]]
local function GetDeadCount(TeamIndex)
    local TeamPlayers = team.GetPlayers(TeamIndex)
    local DeadCount = 0
    for _, ply in ipairs(TeamPlayers) do
        if ply:Alive() == false then --
            DeadCount = DeadCount + 1
        end
    end

    if #TeamPlayers == 0 then
        print("Team is empty, squad wiped")
        return true
    end

    if DeadCount == #TeamPlayers then
        print("Team squad wiped proper")
        return true
    end
    return DeadCount
end

local LastManStandingVoicelines = {
    "vo/k_lab/kl_barneysturn.wav", --
    "vo/canals/boxcar_becareful.wav",
    "vo/k_lab/al_careful02.wav",
    "vo/npc/male01/goodgod.wav",
    "vo/trainyard/ba_goodluck01.wav",
    "vo/trainyard/male01/cit_window_use01.wav",
    "vo/trainyard/male01/cit_tvbust05.wav",
    "vo/npc/male01/ohno.wav",
    "vo/npc/male01/gordead_ans14.wav",
    "vo/npc/male01/evenodds.wav",
    "vo/npc/female01/question21.wav",
    "vo/canals/arrest_lookingforyou.wav",
    "vo/ravenholm/monk_helpme01.wav",
    "vo/ravenholm/shotgun_advice.wav",
}

AddGamemodeHook("PlayerDeath", "TrackRoundDeath", function(victim, inflictor, attacker)
    if rv_gm.MatchInProgress ~= true then --
        return
    end

    if not attacker:IsPlayer() then return end
    if attacker:Team() ~= TEAM_RED and attacker:Team() ~= TEAM_BLUE then return end
    if victim:Team() ~= TEAM_RED and victim:Team() ~= TEAM_BLUE then return end
    local OtherTeam = (victim:Team() == TEAM_RED and TEAM_BLUE) or TEAM_RED
    local AttackerTeam = (attacker:IsPlayer() and attacker:Team()) or OtherTeam
    --
    if GetDeadCount(victim:Team()) == true then
        if victim == attacker then
            rv_gm.EndRound((victim:Team() == TEAM_RED and TEAM_BLUE) or TEAM_RED)
        else
            rv_gm.EndRound(AttackerTeam)
        end
    elseif GetDeadCount(victim:Team()) == #team.GetPlayers(victim:Team()) - 1 then
        for _, ply in ipairs(team.GetPlayers(victim:Team())) do
            if ply:Alive() then
                rv_gm.SendSound(ply, -1, LastManStandingVoicelines[math.random(1, #LastManStandingVoicelines)])
                rv_gm.SendNotif(ply, {"Last man standing."}, {CurTime() + 3}, nil, true)
                break
            end
        end
    end
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
local RoundStartDelay = 10
AddGamemodeHook("rv_gm.RoundStarted", "RoundStarted", function(RoundCount)
    rv_gm.LockAttacks(RoundStartDelay)
    rv_gm.RespawnAllPlayers()
    rv_gm.SendNotif(nil, {"10", "9", "8", "7", "6", "5", "4", "3", "2", "1", "FIGHT!"}, {CurTime() + 1, CurTime() + 2, CurTime() + 3, CurTime() + 4, CurTime() + 5, CurTime() + 6, CurTime() + 7, CurTime() + 8, CurTime() + 9, CurTime() + 10, CurTime() + 11}, "Round begins in", "Round begins in")
    rv_gm.SetTimeLimit(600 + RoundStartDelay)
    rv_gm.SetMatchInProgress(true)
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
        rv_gm.BalanceTeams()
        rv_gm.SendNotif(nil, {"Starts in: 3", "Starts in: 2", "Starts in: 1"}, {CurTime() + 1, CurTime() + 2, CurTime() + 3}, "Clan Arena")
        rv_gm.RespawnAllPlayers()
        -- this seems redundant and unnecessary 
        timer.Simple(MatchStartDelay, function()
            --
            rv_gm.StartRound()
        end)
    end)
    return
end)

AddGamemodeHook("rv_gm.MatchEnded", "MatchEnded", function(WinnerIndex, loserstbl)
    ColoredChatPrint({team.GetColor(WinnerIndex), team.GetName(WinnerIndex), " wins " .. team.GetScore(WinnerIndex) .. " - " .. team.GetScore(next(loserstbl))})
    SetGamemode("FFA")
    if mapvote then
        mapvote.StartMapVote()
    else
        ErrorNoHaltWithStack("NO MAPVOTE")
    end

    print("MATCH ENDED")
end)
