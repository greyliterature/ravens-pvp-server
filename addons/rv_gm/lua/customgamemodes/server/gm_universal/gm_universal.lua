rv_gm = {}
function rv_gm.SetAllToSpectate(SetTeam, SilentKill)
    for _, ply in player.Iterator() do
        if SetTeam ~= false then ply:SetTeam(TEAM_SPECTATOR) end
        ply:KillSilent()
        FSpectate.startSpectating(ply, nil, false)
    end
end

function rv_gm.ForcePlayerToSpectate(ply, target)
    FSpectate.startSpectating(ply, target, false)
end

local CanPlayersRespawn = nil
function rv_gm.AllowPlayerRespawns(bool)
    if bool == true then
        CanPlayersRespawn = nil
    elseif bool == false then
        CanPlayersRespawn = false
    end
end

local TeamJoins = false
function rv_gm.EnableTeamJoins(bool)
    TeamJoins = bool
end

function rv_gm.DelayRespawnPlayer(ply, delay)
    timer.Create("RespawnDelay" .. ply:UserID(), delay, 1, function()
        --
        ply:Spawn()
    end)
end

local TeamIndexes = {}
function rv_gm.SetTeamIndexes(tbl)
    TeamIndexes = tbl
end

function rv_gm.GetTeamIndexes()
    return TeamIndexes
end

local CanPlayersSuicide = nil
function rv_gm.AllowPlayerSuicide(bool)
    if bool == true then
        CanPlayersSuicide = nil
    elseif bool == false then
        CanPlayersSuicide = false
    end
end

AddGamemodeHook("CanPlayerSuicide", "DisableSuicide", function(ply)
    --
    return CanPlayersSuicide
end)

hook.Add("PlayerDeathThink", "AllowPlayerRespawns", function(ply)
    --
    if CanPlayersRespawn == false then
        if ply.DiedInRound == true then
            return false
        else
            return
        end
    end
    return
end)

hook.Add("InitPostEntityStarted", "SetSpectateOnJoin", function(ply)
    local ShouldSpectateOnJoin = hook.Run("ShouldSpectateOnJoin", ply)
    if ShouldSpectateOnJoin ~= true then return end
    rv_gm.ForcePlayerToSpectate(ply, nil)
end)

--[[------------------------------
    Match logic
--------------------------------]]
local MatchInProgress = false
function rv_gm.SetMatchInProgress(bool)
    MatchInProgress = bool
end

local RoundInProgress = false
function rv_gm.SetRoundInProgress(bool)
    RoundInProgress = bool
end

--local MatchEndDate = 0
function rv_gm.SetTimeLimit(delayfromnow)
    --MatchEndDate = CurTime() + delayfromnow
    SetGlobal3("Float", "MatchTimeLimit", CurTime() + delayfromnow)
    timer.Create("MatchTimeLimit", delayfromnow, 1, function()
        --
        rv_gm.EndMatch()
    end)
end

local ScoreLimit = 100
function rv_gm.SetScoreLimit(score)
    ScoreLimit = score
    SetGlobal3("Int", "MatchScoreLimit", score)
end

function rv_gm.AddTeamScore(teamindex)
    if MatchInProgress == false then return end
    team.AddScore(teamindex, score)
    if team.GetScore(teamindex) >= ScoreLimit then
        --
        rv_gm.EndMatch()
    end
end

function rv_gm.EndMatch()
    local BestTeamIndex, BestTeamScore = -9999, 0
    local OtherTeams = {}
    for _, teamindex in ipairs(rv_gm.GetTeamIndexes()) do
        local teamscore = team.GetScore(teamindex)
        OtherTeams[teamindex] = teamscore
        if teamscore > BestTeamScore then
            -- 
            BestTeamIndex, BestTeamScore = teamindex, BestTeamIndex
        end
    end

    OtherTeams[BestTeamIndex] = nil
    ColoredChatPrint({team.GetColor(BestTeamIndex), team.GetName(BestTeamIndex), " wins " .. team.GetScore(BestTeamIndex) .. table.concat(OtherTeams, " ")})
    hook.Run("rv_gm.MatchEnded")
end

--[[------------------------------
    Teams request
--------------------------------]]
local TEAM_RED, TEAM_BLUE = 1, 2
local function GetLowestTeam()
    local LowestTeam = TEAM_BLUE
    local RedPlayers = #team.GetPlayers(TEAM_RED)
    local BluePlayers = #team.GetPlayers(TEAM_BLUE)
    if RedPlayers < BluePlayers then LowestTeam = TEAM_RED end
    return LowestTeam
end

util.AddNetworkString("RequestTeamJoin")
local WhitelistedTeams = {
    [TEAM_SPECTATOR] = true,
    [TEAM_RED] = true,
    [TEAM_BLUE] = true,
}

function rv_gm.WhitelistTeam(teamindex)
    WhitelistedTeams[teamindex] = true
end

function rv_gm.BlacklistTeam(teamindex)
    WhitelistedTeams[teamindex] = nil
end

local LastTeamRequestTimes = {} -- ply = CurTime()
local TeamJoinRateLimit = 5 -- seconds
net.Receive("RequestTeamJoin", function(len, ply)
    if TeamJoins == false then return end
    LastTeamRequestTimes[ply] = LastTeamRequestTimes[ply] or 0
    if LastTeamRequestTimes[ply] + TeamJoinRateLimit > CurTime() then
        rv_gm.SendNotif(ply, {"Please wait before joining another team."}, {CurTime() + 2}, nil, true)
        return
    end

    if ply:GetUserGroup() == "DOLLMODE" then
        print(ply:Nick() .. " tried to join a team, but is in dollmode.")
        return
    end

    local RequestedTeam = net.ReadInt(32)
    print(ply:Nick() .. " requested to join team " .. team.GetName(RequestedTeam) .. "(" .. RequestedTeam .. ")")
    if not WhitelistedTeams[RequestedTeam] then
        print(ply:Nick() .. " tried joining team " .. team.GetName(RequestedTeam) .. "(" .. RequestedTeam .. ")" .. " which is not whitelisted")
        return
    end

    if GetLowestTeam() ~= RequestedTeam and RequestedTeam ~= TEAM_SPECTATOR and #team.GetPlayers(RequestedTeam) ~= #team.GetPlayers(GetLowestTeam()) and #team.GetPlayers(RequestedTeam) > 0 then
        print(ply:Nick() .. " requested to join team " .. team.GetName(RequestedTeam) .. "(" .. RequestedTeam .. ")" .. ", but it does not have enough players.")
        rv_gm.SendNotif(ply, {"That team is full."}, {CurTime() + 1}, nil, true)
        return
    end

    if MatchInProgress == true then --
        if ply:Team() == TEAM_SPECTATOR then
            ply.DiedInRound = true
        else
            rv_gm.SendNotif(ply, {"Match is in progress."}, {CurTime() + 1}, nil, true)
            return
        end
    end

    LastTeamRequestTimes[ply] = CurTime()
    ply:SetTeam(RequestedTeam)
    print(ply:Nick() .. " team set to " .. team.GetName(RequestedTeam) .. "(" .. RequestedTeam .. ")")
    rv_gm.SendNotif(ply, {ply:Nick() .. " has joined " .. ((RequestedTeam ~= TEAM_SPECTATOR and " team " .. (team.GetName(RequestedTeam) or "N/A")) or "the spectators") .. "."}, {CurTime() + 2}, nil, true)
end)

AddGamemodeHook("PlayerChangedTeam", "SpectateStateOnTeamChange", function(ply, oldTeam, newTeam)
    if TeamJoins == false then return end
    print("HIII", oldTeam, newTeam)
    if oldTeam == TEAM_SPECTATOR and (RoundInProgress == false or MatchInProgress == false) then
        FSpectate.forceUnspectate(ply)
        ply:Spawn()
    elseif (oldTeam == TEAM_BLUE or oldTeam == TEAM_RED) and MatchInProgress == false and newTeam ~= TEAM_SPECTATOR then
        FSpectate.forceUnspectate(ply)
        ply:Spawn()
    elseif newTeam == TEAM_SPECTATOR then
        ply:KillSilent()
        FSpectate.startSpectating(ply, nil, false)
    end
end)

local player_color_red = Vector(1, 0, 0)
local player_color_blue = Vector(0, 0, 1)
local TeamColors = {
    [TEAM_RED] = player_color_red,
    [TEAM_BLUE] = player_color_blue,
}

AddGamemodeHook("PlayerSetModel", "SetTeamColors", function(ply)
    timer.Simple(0, function()
        local PlayerTeam = ply:Team()
        if TeamColors[PlayerTeam] then --
            ply:SetPlayerColor(TeamColors[PlayerTeam])
        end
    end)
end)

--[[------------------------------
    SendNotif
--------------------------------]]
util.AddNetworkString("SendNotif")
function rv_gm.SendNotif(ply, NotifsTable, EndTimesTable, Header, ShouldFade)
    net.Start("SendNotif")
    --[[
            NotifsTable = {
                "Starts in: 3",
                "Starts in: 2",
                "Starts in: 1",
                "FIGHT!"
            }

            EndTimesTable = {
                CurTime() + 1, 
                CurTime() + 2,
                CurTime() + 3,
                CurTime() + 4,
            }
    --]]
    local NumberOfKeys = #NotifsTable
    net.WriteUInt(NumberOfKeys, 5)
    for i = 1, #NotifsTable do
        local NotifText = NotifsTable[i]
        local NotifEndTime = EndTimesTable[i]
        net.WriteString(NotifText)
        net.WriteFloat(NotifEndTime)
    end

    net.WriteBool(ShouldFade == true)
    net.WriteString(Header or "") -- Clan Arena
    if ply then
        net.Send(ply)
    else
        net.Broadcast()
    end
end

--[[------------------------------
    Lock attacks (for match / round start delay)
--------------------------------]]
util.AddNetworkString("LockAttacks")
function rv_gm.LockAttacks(Delay)
    net.Start("LockAttacks")
    local StartDate = CurTime() + Delay
    net.WriteFloat(StartDate)
    net.Broadcast()
    AddGamemodeHook("StartCommand", "LockAttacks", function(ply, cmd)
        if CurTime() > StartDate then
            if cmd:KeyDown(IN_ATTACK) then --
                cmd:AddKey(IN_ATTACK)
            end

            if cmd:KeyDown(IN_ATTACK2) then --
                cmd:AddKey(IN_ATTACK2)
            end

            hook.Remove("StartCommand", "LockAttacks")
            return
        end

        if cmd:KeyDown(IN_ATTACK) then cmd:RemoveKey(IN_ATTACK) end
        if cmd:KeyDown(IN_ATTACK2) then cmd:RemoveKey(IN_ATTACK2) end
    end)
end
return rv_gm
