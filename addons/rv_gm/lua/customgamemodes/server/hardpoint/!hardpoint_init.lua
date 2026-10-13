local rv_gm = include("../gm_universal/gm_universal.lua")
--[[----------------------------------------------------------------------
    autorefresh
------------------------------------------------------------------------]]
timer.Simple(0, function()
    for _, ply in player.Iterator() do
        if ply:IsBot() == true then ply:SetTeam(1) end
    end
end)

--[[----------------------------------------------------------------------
    init
------------------------------------------------------------------------]]
-- autorefresh
local CONTROLLING_TEAM_NOPLAYERS = 95316
SetGlobal3("Int", "ControllingTeam", CONTROLLING_TEAM_NOPLAYERS)
--
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

rv_gm.ResetScores()
rv_gm.RemoveConflictingHooks()
rv_gm.DisablePlayerRewards()
--[[----------------------------------------------------------------------
    Death
------------------------------------------------------------------------]]
local RespawnDelay = 5
AddGamemodeHook("PlayerDeath", "SetSpecOnDeath", function(ply, _, _)
    local Teammates = team.GetPlayers(ply:Team())
    table.RemoveByValue(Teammates, ply)
    local NextTeammate = Teammates[1]
    rv_gm.ForcePlayerToSpectate(ply, NextTeammate)
    timer.Simple(RespawnDelay, function()
        rv_gm.ForcePlayerToUnSpectate(ply)
        ply:Spawn()
        return
    end)
    return
end)

rv_gm.AllowPlayerFriendlyFire(false)
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

rv_gm.SetScoreLimit(100)
AddGamemodeHook("ShouldSpectateOnJoin", "SetSpectateOnJoin", function(ply)
    return true --
end)

-- round start 
-- there is no RoundEnded for KOTH because it is really just one round, this is just for notification formality
local RoundStartDelay = 5
AddGamemodeHook("rv_gm.RoundStarted", "RoundStarted", function(RoundCount)
    rv_gm.LockAttacks(RoundStartDelay)
    rv_gm.RespawnAllPlayers()
    rv_gm.SendNotif(nil, {"5", "4", "3", "2", "1", "FIGHT!"}, {CurTime() + 1, CurTime() + 2, CurTime() + 3, CurTime() + 4, CurTime() + 5, CurTime() + 6}, "Round begins in")
    rv_gm.SetTimeLimit(600 + RoundStartDelay)
    rv_gm.SetMatchInProgress(true) -- rv_gm.StartMatch() handles this for you 
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
        rv_gm.SendNotif(nil, {"Starts in: 3", "Starts in: 2", "Starts in: 1"}, {CurTime() + 1, CurTime() + 2, CurTime() + 3}, "Hard Point")
        rv_gm.RespawnAllPlayers()
        -- this seems redundant and unnecessary 
        timer.Simple(MatchStartDelay, function()
            timer.Stop("HillsScore")
            timer.Start("HillsScore")
            SetGlobal3("Float", "HillStart", CurTime()) -- reset hill creation times
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

--rv_gm.CreateDollFlagBase(Vector(0, 0, 0), TEAM_RED, true)
--rv_gm.CreateDollFlagBase(Vector(0, 150, 0), TEAM_BLUE, true)
rv_gm.spawns = rv_gm.spawns or {}
for i = #rv_gm.spawns, 1, -1 do
    if IsValid(spawn) then spawn:Remove() end
    table.remove(rv_gm.spawns, i)
end

local HillMins, HillMaxes = Vector(-300, -300, 0), Vector(300, 300, 200)
local HardPointsPoses = {}
local HardPointSwapDelay = 45
local LastHardpoint = nil
local HardPointUnlockDelay = 10
local HardPointScoreTime = 3 -- how often in seconds should we reward the players on the hardpoint
local HardPointScoreReward = 1 -- amount we give PER PLAYER on the hardpoint to the best team
local function CreateHardPoint(pos)
    local function StartTouchFunc(self, ent)
        if not ent:IsPlayer() then return end
        self.PlayersOnHill = (self.PlayersOnHill or 0) + 1
        self.Players = self.Players or {}
        self.Players[ent] = true
        local ControllingTeam, bestscore, secondbestteamindex, secondbestscore = rv_gm.GetHighestTeamOnHill(self)
        if not ControllingTeam then --
            ControllingTeam = CONTROLLING_TEAM_NOPLAYERS
        elseif bestscore == secondbestscore and secondbestteamindex then
            ControllingTeam = CONTROLLING_TEAM_CONTESTED
        end

        print("Controlling team: " .. ControllingTeam)
        SetGlobal3("Int", "ControllingTeam", ControllingTeam)
    end

    local function EndTouchFunc(self, ent)
        if not ent:IsPlayer() then return end
        self.PlayersOnHill = (self.PlayersOnHill or 1) - 1
        self.Players = self.Players or {}
        self.Players[ent] = nil
        local ControllingTeam = select(1, rv_gm.GetHighestTeamOnHill(self))
        if not ControllingTeam then --
            ControllingTeam = CONTROLLING_TEAM_NOPLAYERS
        end

        print("Controlling team: " .. ControllingTeam)
        SetGlobal3("Int", "ControllingTeam", ControllingTeam)
    end

    local HardPoint = rv_gm.CreateTrigger(pos, nil, HillMins, HillMaxes, color_white, StartTouchFunc, nil, EndTouchFunc)
    LastHardpoint = HardPoint
    SetGlobal3("Float", "HardPointUnlockDate", CurTime() + HardPointUnlockDelay)
    timer.Simple(HardPointUnlockDelay, function()
        AddGamemodeTimer("HardPointsScore", HardPointScoreTime, 0, function()
            if not HardPoint then
                timer.Remove("HardPointsScore")
                return
            end

            local PlayersOnHill = HardPoint.Players
            local bestteamindex, bestscore, _, secondbestscore = rv_gm.GetHighestTeamOnHill(HardPoint)
            if bestscore == secondbestscore and bestscore ~= 0 then -- equal players on both teams, no reward
                return
            end

            for ply, _ in pairs(PlayersOnHill) do
                local PlayerTeam = ply:Team()
                if PlayerTeam == bestteamindex then rv_gm.AddTeamScore(PlayerTeam, HardPointScoreReward) end
            end
        end)
    end)
end

AddGamemodeHook("rv_gm.GamemodeDataLoaded", "SetSpawns", function(gamemodetbl)
    local map = game.GetMap()
    HardPointsPoses = gamemodetbl[map]["HardPoints"]
    local random_hardpointpos = HardPointsPoses[math.random(1, #HardPointsPoses)]
    CreateHardPoint(random_hardpointpos)
    for teamindex, tbl in pairs(gamemodetbl[map]["Spawns"]) do
        for _, data in ipairs(tbl) do
            local pos = data[1]
            local angs = data[2]
            local usePitch = nil
            print(pos, angs)
            rv_gm.spawns[#rv_gm.spawns + 1] = CreateSpawnPoint(nil, pos, angs, usePitch, nil)
        end
    end

    AddGamemodeTimer("SwapHardPoint", HardPointSwapDelay, 0, function()
        local LastHardPointPos = nil
        print("HI!!!", IsValid(LastHardpoint))
        if IsValid(LastHardpoint) then
            LastHardPointPos = LastHardpoint:GetPos()
            LastHardpoint.InfoParent:Remove()
            LastHardpoint:Remove()
        end

        for _, HardPointPos in RandomPairs(HardPointsPoses) do
            if HardPointPos ~= LastHardPointPos then --
                random_hardpointpos = HardPointPos
            end
        end

        print(random_hardpointpos)
        CreateHardPoint(random_hardpointpos)
    end)
end)

rv_gm.RequestGamemodeData()
