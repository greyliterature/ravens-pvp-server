--[[------------------------------
    init 
--------------------------------]]
local GamemodeVars = include("customgamemodes/gamemodevars.lua")
CurrentGamemode = GamemodeVars.CurrentGamemode[2]
local ReadyUpRatio = GamemodeVars.ReadyUpRatio[2]
local ReadyUpCount = 0
local MatchInProgress = GamemodeVars.MatchInProgress[2]
SetGlobal3("Bool", "MatchInProgress", false)
local RoundInProgress = false
local StartingNewRound = false
--[[------------------------------
    Shared teams 
--------------------------------]]
TEAM_RED = 1
TEAM_BLUE = 2
-- Returns blue, unless red has less players. Then it returns red.
local function GetLowestTeam()
    local LowestTeam = TEAM_BLUE
    local RedPlayers = #team.GetPlayers(TEAM_RED)
    local BluePlayers = #team.GetPlayers(TEAM_BLUE)
    if RedPlayers < BluePlayers then LowestTeam = TEAM_RED end
    return LowestTeam
end

--[[------------------------------
    Shared hook functions 
--------------------------------]]
local function ShouldRunHook() -- for making sure that some of the hooks dont run when the gamemode is ffa
    return -- this is not needed if the include system works 
    --return GetGlobalString("CurrentGamemode", "FFA") ~= "FFA"
end

local gm = {}
--[[------------------------------
        Ranks
--------------------------------]]
local RankedMatch = false
--[[------------------------------
        Team Balance
--------------------------------]]
local function ShuffleTeams(Teams)
    print("THIS FUNCTION SUCKS. MAKE A BALANCE SYSTEM LATER.")
    local TeamPlayers = {}
    TeamPlayers[TEAM_RED] = team.GetPlayers(TEAM_RED)
    TeamPlayers[TEAM_BLUE] = team.GetPlayers(TEAM_BLUE)
    local IdealTeamCount = math.floor((#TeamPlayers[1] + #TeamPlayers[2]) / 2)
    table.Shuffle(TeamPlayers)
    local Clans = {}
    --[[
        ["313"]:
                [1]	            =	            [313] testguy
                [2]	            =	            [313]edna
        ["350"]:
                [1]	            =	            [350] Bob
        ["511"]:
                [1]	            =	            [511] scripture
                [2]	            =	            [511] billy
        --]]
    for TeamIndex, tbl in ipairs(TeamPlayers) do
        for i = #tbl, 1, -1 do
            --for _, ply in ipairs(tbl) do
            local ply = tbl[i]
            if ply:GetUserGroup() == "DOLLMODE" then
                ply:SetTeam(TEAM_SPECTATOR)
                continue
            end

            local ClanTag = select(1, string.match(ply:Nick(), "%[(.-)%]"))
            if ClanTag then
                Clans[ClanTag] = Clans[ClanTag] or {}
                Clans[ClanTag][#Clans[ClanTag] + 1] = ply
                table.RemoveByValue(tbl, ply)
            end
        end
    end

    local UnitedPlayers = {}
    for TeamIndex, tbl in ipairs(TeamPlayers) do
        for _, ply in ipairs(tbl) do
            UnitedPlayers[#UnitedPlayers + 1] = ply
        end
    end

    local OrderedClans = {}
    for ClanTag, tbl in pairs(Clans) do
        local NextNumber = #OrderedClans + 1
        OrderedClans[NextNumber] = {}
        for _, ply in pairs(tbl) do
            OrderedClans[NextNumber][#OrderedClans[NextNumber] + 1] = ply
        end
    end

    table.sort(OrderedClans, function(a, b)
        --
        return #a[1] > #b[1]
    end)

    local NewTeams = {
        [TEAM_RED] = {},
        [TEAM_BLUE] = {}
    }

    for i, tbl in ipairs(OrderedClans) do
        local ChosenTeam = (i % 2 == 0 and TEAM_RED) or TEAM_BLUE
        for _, ply in ipairs(tbl) do
            NewTeams[ChosenTeam][#NewTeams[ChosenTeam] + 1] = ply
        end
    end

    for _, tbl in ipairs(NewTeams) do
        for i = 1, IdealTeamCount - #tbl do
            local RandomIndex = math.random(1, #UnitedPlayers)
            local RandomPlayer = UnitedPlayers[RandomIndex]
            tbl[#tbl + 1] = RandomPlayer
            table.remove(UnitedPlayers, RandomIndex)
        end
    end

    PrintTable(TeamPlayers)
    PrintTable(NewTeams)
    for TeamIndex, tbl in ipairs(NewTeams) do
        for _, ply in ipairs(tbl) do
            ply:SetTeam(TeamIndex)
        end
    end
end

--[[
    local TeamPlayers = {
        {
            "[511] scripture", --
            "[313] testguy",
            "ryan",
            "joe"
        },
        {
            "[350] Bob", --
            "[511] billy",
            "Robert",
            "[313]edna"
        }
    }

    local IdealTeamCount = math.floor((#TeamPlayers[1] + #TeamPlayers[2]) / 2)
    table.Shuffle(TeamPlayers)
    local Clans = {}
    --[[
        ["313"]:
                [1]	            =	            [313] testguy
                [2]	            =	            [313]edna
        ["350"]:
                [1]	            =	            [350] Bob
        ["511"]:
                [1]	            =	            [511] scripture
                [2]	            =	            [511] billy
    --]]
--[[
    for TeamIndex, tbl in ipairs(TeamPlayers) do
        for i = #tbl, 1, -1 do
            --for _, ply in ipairs(tbl) do
            local ply = tbl[i]
            local ClanTag = select(1, string.match(ply, "%[(.-)%]"))
            if ClanTag then
                Clans[ClanTag] = Clans[ClanTag] or {}
                Clans[ClanTag][#Clans[ClanTag] + 1] = ply
                table.RemoveByValue(tbl, ply)
            end
        end
    end

    local UnitedPlayers = {}
    for TeamIndex, tbl in ipairs(TeamPlayers) do
        for _, ply in ipairs(tbl) do
            UnitedPlayers[#UnitedPlayers + 1] = ply
        end
    end

    local OrderedClans = {}
    for ClanTag, tbl in pairs(Clans) do
        local NextNumber = #OrderedClans + 1
        OrderedClans[NextNumber] = {}
        for _, ply in pairs(tbl) do
            OrderedClans[NextNumber][#OrderedClans[NextNumber] + 1] = ply
        end
    end

    table.sort(OrderedClans, function(a, b)
        --
        return #a[1] > #b[1]
    end)

    local NewTeams = {
        [TEAM_RED] = {},
        [TEAM_BLUE] = {}
    }

    for i, tbl in ipairs(OrderedClans) do
        local ChosenTeam = (i % 2 == 0 and TEAM_RED) or TEAM_BLUE
        for _, ply in ipairs(tbl) do
            NewTeams[ChosenTeam][#NewTeams[ChosenTeam] + 1] = ply
        end
    end

    for _, tbl in ipairs(NewTeams) do
        print(#tbl - IdealTeamCount)
        for i = 1, IdealTeamCount - #tbl do
            print(i, "DDDD")
            local RandomIndex = math.random(1, #UnitedPlayers)
            local RandomPlayer = UnitedPlayers[RandomIndex]
            print(RandomPlayer)
            tbl[#tbl + 1] = RandomPlayer
            table.remove(UnitedPlayers, RandomIndex)
            --print(i)
        end
    end
    PrintTable(TeamPlayers)
    PrintTable(NewTeams)
    --]]
local function BalanceTeams(Teams)
    print("This does nothing. Make it do something later. Whitelist clan tags to not balance teams. Make average elo approach a number")
    ShuffleTeams(Teams)
end

--[[------------------------------
        Notifs HUD
    --------------------------------]]
util.AddNetworkString("SendNotif")
local function SendNotif(ply, NotifsTable, EndTimesTable, Header, ShouldFade)
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
local function LockAttacks(Delay)
    net.Start("LockAttacks")
    local StartDate = CurTime() + Delay
    net.WriteFloat(StartDate)
    net.Broadcast()
    AddGamemodeHook("StartCommand", "LockAttacks", function(ply, cmd)
        if ShouldRunHook() == false then return end
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

--[[------------------------------
        Helpers
--------------------------------]]
local function RespawnPlayers(Teams)
    -- respawn everyone in {Teams1, Teams2, ... , TeamsN}
    for _, TeamIndex in ipairs(Teams) do
        for _, ply in ipairs(team.GetPlayers(TeamIndex)) do
            FSpectate.forceUnspectate(ply)
            ply:Spawn()
        end
    end
end

--[[------------------------------
    SendSound
--------------------------------]]
util.AddNetworkString("SendSound")
local function SendSound(ply, StartDate, SoundName)
    net.Start("SendSound")
    net.WriteFloat(StartDate)
    net.WriteString(SoundName)
    if ply then
        net.Send(ply)
    else
        net.Broadcast()
    end
end

--[[------------------------------
    Player spectate
--------------------------------]]
AddGamemodeHook("PlayerInitialSpawn", "SetSpectateOnInitSpawn", function(ply, trans)
    if ShouldRunHook() == false then return end
    timer.Simple(0, function() ply:SetTeam((ply:IsBot() == false and TEAM_SPECTATOR) or TEAM_RED) end)
    timer.Simple(2, function() FSpectate.startSpectating(ply, nil, false) end)
end)

AddGamemodeHook("PlayerDeathThink", "DontAllowRespawning", function(ply)
    if ply:Team() == TEAM_SPECTATOR then
        return false
    elseif RoundInProgress == false then
        if StartingNewRound == false then
            FSpectate.forceUnspectate(ply)
            ply:Spawn()
            return
        end
    end
    return false
end)

AddGamemodeHook("PlayerDeath", "SpectateOnDeath", function(victim, inflictor, attacker)
    --
    FSpectate.startSpectating(victim, nil, false)
end)

AddGamemodeHook("FSpectate_canSpectate", "NoSpectateWhileAlive", function(ply)
    local canSpec = false
    if ply:Alive() == false or ply:Team() == TEAM_SPECTATOR then --
        canSpec = nil
    end
    return canSpec
end)

--[[------------------------------
        EndMatch
--------------------------------]]
local EndMatchVoicelines = {
    [0] = {
        -- 0 to 2
        ["Winner"] = {"vo/npc/male01/answer01.wav"},
        ["Loser"] = {"vo/npc/female01/question18.wav", "vo/npc/female01/vanswer14.wav", "vo/npc/male01/gordead_ans19.wav", "vo/trainyard/cit_nerve.wav", "vo/trainyard/cit_train_endline.wav", "vo/trainyard/wife_canttake.wav", "vo/trainyard/wife_end.wav", "vo/npc/male01/notthemanithought01.wav", "vo/npc/male01/notthemanithought02.wav", "vo/npc/male01/heretohelp01.wav", "vo/npc/male01/gordead_ques10.wav", "vo/npc/male01/answer36.wav", "vo/npc/male01/answer35.wav", "vo/npc/male01/answer02.wav", "vo/npc/female01/question26.wav", "vo/npc/female01/question25.wav", "vo/npc/female01/question20.wav"}
    },
    [3] = {
        -- 3 to 5
        ["Winner"] = {"vo/npc/male01/answer25.wav"},
        ["Loser"] = {"vo/npc/male01/gordead_ques06.wav", "vo/npc/male01/gordead_ques02.wav", "vo/npc/male01/gordead_ans12.wav", "vo/npc/male01/gordead_ans11.wav", "vo/npc/male01/answer03.wav"},
    },
    [6] = {
        -- 6 to 8
        ["Winner"] = {"vo/npc/male01/answer32.wav", "vo/npc/female01/vanswer07.wav", "vo/npc/female01/squad_affirm07.wav"},
        ["Loser"] = {"vo/npc/male01/gordead_ques16.wav", "vo/npc/male01/gordead_ans15.wav", "vo/npc/male01/answer40.wav", "vo/npc/male01/answer04.wav"},
    },
    [9] = {
        -- 9
        ["Winner"] = {"vo/Streetwar/sniper/ba_returnhero.wav", "vo/trainyard/ba_thatbeer02.wav"},
        ["Loser"] = {"vo/npc/male01/gordead_ques14.wav", "vo/npc/male01/gordead_ans13.wav", "vo/npc/male01/gordead_ans10.wav", "vo/npc/male01/gordead_ans06.wav", "vo/npc/male01/gordead_ans03.wav", "vo/npc/male01/gordead_ans02.wav"},
    },
}

local function GetWinnerLoserVoicelines(LoserScore)
    LoserScore = tonumber(LoserScore)
    local ClosestScore = 0
    for score, _ in pairs(EndMatchVoicelines) do
        if LoserScore >= score and score > ClosestScore then -- 
            ClosestScore = score
        end
    end

    local WinnerSounds = EndMatchVoicelines[ClosestScore]["Winner"]
    local LoserSounds = EndMatchVoicelines[ClosestScore]["Loser"]
    return WinnerSounds, LoserSounds
end

local PlayersCanReadyUp = true
local function EndMatch(WinnerIndex, fulfilled, nonfulfillmentreason)
    MatchInProgress = false
    GamemodeVars.MatchInProgress[2] = false
    SetGlobal3("Bool", "MatchInProgress", false)
    PlayersCanReadyUp = false
    timer.Simple(30, function() PlayersCanReadyUp = true end)
    --
    local WinnerSoundsTable, LoserSoundsTable = GetWinnerLoserVoicelines(team.GetScore((WinnerIndex == TEAM_RED and TEAM_BLUE) or TEAM_RED))
    SendSound(team.GetPlayers(WinnerIndex), -1, WinnerSoundsTable[math.random(1, #WinnerSoundsTable)]) -- winners
    SendSound(team.GetPlayers((WinnerIndex == TEAM_RED and TEAM_BLUE) or TEAM_RED), -1, LoserSoundsTable[math.random(1, #LoserSoundsTable)]) -- losers
    --
    if fulfilled then PrintMessage(HUD_PRINTTALK, team.GetName(WinnerIndex) .. " wins " .. team.GetScore(WinnerIndex) .. " - " .. team.GetScore((WinnerIndex == TEAM_RED and TEAM_BLUE) or TEAM_RED) .. ".") end
    local Teams = {TEAM_RED, TEAM_BLUE}
    for i = 1, #Teams do
        team.SetScore(Teams[i], 0)
        for _, ply in ipairs(team.GetPlayers(Teams[i])) do
            ply.ReadyUpState = false
            ply.DiedInRound = nil
            FSpectate.forceUnspectate(ply)
            ply:Spawn()
        end
    end

    if not fulfilled then
        timer.Simple(0, function()
            --
            PrintMessage(HUD_PRINTTALK, "Match ended early because " .. nonfulfillmentreason)
        end)
    end

    SetGamemode("ffa")
    timer.Simple(3, function()
        --
        MapVote.Start()
    end)
end

--[[------------------------------
    StartRound
--------------------------------]]
local Round = {} -- table to stop annoying shadowing existing binding issue
local function GetDeadCount(TeamIndex)
    local DeadCount = 0
    for _, ply in ipairs(team.GetPlayers(TeamIndex)) do
        if ply:Alive() == false then --
            DeadCount = DeadCount + 1
        end
    end

    if #team.GetPlayers(TeamIndex) == 0 then
        print("Team is empty, squad wiped")
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

local RoundStartDelay = 10
function Round.StartRound(ScoreLimit)
    StartingNewRound = false
    local Teams = {TEAM_RED, TEAM_BLUE}
    RespawnPlayers(Teams)
    LockAttacks(RoundStartDelay)
    SendSound(nil, CurTime() + RoundStartDelay - 4, "vo/k_lab/kl_initializing.wav")
    timer.Simple(RoundStartDelay, function()
        for _, teamindex in ipairs(Teams) do
            for _, ply in ipairs(team.GetPlayers(teamindex)) do
                if ply:Alive() == false then --
                    FSpectate.forceUnspectate(ply)
                    ply:Spawn()
                end
            end
        end

        RoundInProgress = true
    end)

    SendNotif(nil, {"10", "9", "8", "7", "6", "5", "4", "3", "2", "1", "FIGHT!"}, {CurTime() + 1, CurTime() + 2, CurTime() + 3, CurTime() + 4, CurTime() + 5, CurTime() + 6, CurTime() + 7, CurTime() + 8, CurTime() + 9, CurTime() + 10, CurTime() + 11}, "Round begins in")
    AddGamemodeHook("PlayerDeath", "TrackRoundDeath", function(victim, inflictor, attacker)
        if ShouldRunHook() == false then return end
        if RoundInProgress == false then --
            return
        end

        if MatchInProgress ~= true then --
            return
        end

        if attacker:IsPlayer() and attacker:Team() ~= TEAM_RED and attacker:Team() ~= TEAM_BLUE then return end
        if victim:Team() ~= TEAM_RED and victim:Team() ~= TEAM_BLUE then return end
        timer.Simple(0, function()
            --
            FSpectate.startSpectating(victim, nil, false)
        end)

        local OtherTeam = (victim:Team() == TEAM_RED and TEAM_BLUE) or TEAM_RED
        local AttackerTeam = (attacker:IsPlayer() and attacker:Team()) or OtherTeam
        --
        if GetDeadCount(victim:Team()) == #team.GetPlayers(victim:Team()) then
            if victim == attacker then
                Round.EndRound((victim:Team() == TEAM_RED and TEAM_BLUE) or TEAM_RED)
            else
                Round.EndRound(AttackerTeam)
            end
        elseif GetDeadCount(victim:Team()) == #team.GetPlayers(victim:Team()) - 1 then
            for _, ply in ipairs(team.GetPlayers(victim:Team())) do
                if ply:Alive() then
                    SendSound(ply, -1, LastManStandingVoicelines[math.random(1, #LastManStandingVoicelines)])
                    SendNotif(ply, {"Last man standing."}, {CurTime() + 3}, nil, true)
                    break
                end
            end
        end
    end, PRE_HOOK)

    AddGamemodeHook("PlayerDisconnected", "TrackDisconnectDeaths", function(ply)
        if MatchInProgress ~= true then return end
        if ply:Team() ~= TEAM_RED and ply:Team() ~= TEAM_BLUE then return end
        if ShouldRunHook() == false then return end
        local PlayerTeam = ply:Team()
        timer.Simple(0, function()
            if #team.GetPlayers(PlayerTeam) == 0 then --
                EndMatch(nil, nil, " there aren't enough players to start a new round")
            end

            if GetDeadCount(PlayerTeam) == #team.GetPlayers(PlayerTeam) then --
                Round.EndRound((PlayerTeam == TEAM_RED and TEAM_BLUE) or TEAM_RED)
            end
        end)
    end)
end

--[[------------------------------
    EndRound
--------------------------------]]
local RoundLimit = 10
function Round.EndRound(WinnerTeamIndex)
    if MatchInProgress == false then return end
    if RoundInProgress == false then return end
    if StartingNewRound == true then return end
    RoundInProgress = false
    StartingNewRound = true
    team.AddScore(WinnerTeamIndex, 1)
    if team.GetScore(WinnerTeamIndex) >= RoundLimit then --
        EndMatch(WinnerTeamIndex, true)
        return
    end

    SendNotif(nil, {""}, {CurTime() + 3}, team.GetName(WinnerTeamIndex) .. " wins the round", true)
    local NextRoundDelay = 4
    LockAttacks(NextRoundDelay)
    timer.Simple(NextRoundDelay, function()
        --
        Round.StartRound(RoundLimit)
    end)
end

--[[------------------------------
    StartMatch
--------------------------------]]
local function ResetScores(teams)
    for _, v in ipairs(teams) do
        team.SetScore(v, 0)
    end
end

util.AddNetworkString("MatchStarted")
local MatchStartDelay = 3
local function StartMatch(ScoreLimit)
    ScoreLimit = ScoreLimit or RoundLimit
    net.Start("MatchStarted")
    net.WriteBool(true)
    net.Broadcast()
    for _, ply in player.Iterator() do
        ply:SetNWBool("Ready", false)
        ply.ReadyUpState = nil
    end

    StartingNewRound = true
    BalanceTeams({TEAM_RED, TEAM_BLUE})
    ResetScores({TEAM_RED, TEAM_BLUE})
    LockAttacks(MatchStartDelay + RoundStartDelay)
    SendNotif(nil, {"Starts in: 3", "Starts in: 2", "Starts in: 1"}, {CurTime() + 1, CurTime() + 2, CurTime() + 3}, "Clan Arena")
    RespawnPlayers({TEAM_RED, TEAM_BLUE})
    SetGlobal3("Bool", "MatchInProgress", true)
    timer.Simple(MatchStartDelay, function()
        Round.StartRound(ScoreLimit)
        MatchInProgress = true
        GamemodeVars.MatchInProgress[2] = true
    end)
end

--[[------------------------------
    ReadyUp
--------------------------------]]
util.AddNetworkString("ReadyUp")
local ReadiableTeams = {
    [TEAM_RED] = true,
    [TEAM_BLUE] = true,
}

local LastReadyUpTimes = {} -- ply = CurTime()
local ReadyUpRateLimit = 1 -- seconds
net.Receive("ReadyUp", function(len, ply)
    if PlayersCanReadyUp == false then return end
    LastReadyUpTimes[ply] = LastReadyUpTimes[ply] or 0
    if LastReadyUpTimes[ply] + ReadyUpRateLimit > CurTime() then -- rate limited 
        return
    end

    if not ReadiableTeams[ply:Team()] then
        print(ply:Nick() .. " tried readying up while part of team " .. team.GetName(ply:Team()) .. " which is not readiable.")
        return
    end

    if #team.GetPlayers(TEAM_RED) == 0 or #team.GetPlayers(TEAM_BLUE) == 0 then
        SendNotif(ply, {"Both teams must be present to ready-up."}, {CurTime() + 2}, nil, true)
        return
    end

    if MatchInProgress == true then
        print(ply:Nick() .. " tried readying up while match is started")
        return
    end

    LastReadyUpTimes[ply] = CurTime()
    local NewPlayerReadyUpState = not ply.ReadyUpState
    ply.ReadyUpState = NewPlayerReadyUpState
    ReadyUpCount = ReadyUpCount + ((NewPlayerReadyUpState == true and 1) or -1)
    SetGlobal3("UInt", "ReadyUpCount", ReadyUpCount)
    print("New readyup count - " .. ReadyUpCount)
    ply:SetNWBool("Ready", NewPlayerReadyUpState)
    print("Make this NWBool used later")
    SendNotif(nil, {ply:Nick() .. " is" .. ((NewPlayerReadyUpState == true and "") or " not") .. " Ready"}, {CurTime() + 2}, nil, true)
    local ValidPlayers = #team.GetPlayers(TEAM_RED) + #team.GetPlayers(TEAM_BLUE)
    if ReadyUpCount >= math.ceil(ReadyUpRatio * ValidPlayers) and #team.GetPlayers(TEAM_RED) > 0 and #team.GetPlayers(TEAM_BLUE) > 0 then --
        StartMatch(RoundLimit)
    end
end)

--[[------------------------------
    Teams request
--------------------------------]]
util.AddNetworkString("RequestTeamJoin")
local LastTeamRequestTimes = {} -- ply = CurTime()
local TeamJoinRateLimit = 5 -- seconds
local WhitelistedTeams = {
    [TEAM_SPECTATOR] = true,
    [TEAM_RED] = true,
    [TEAM_BLUE] = true,
}

net.Receive("RequestTeamJoin", function(len, ply)
    LastTeamRequestTimes[ply] = LastTeamRequestTimes[ply] or 0
    if LastTeamRequestTimes[ply] + TeamJoinRateLimit > CurTime() then
        SendNotif(ply, {"Please wait before joining another team."}, {CurTime() + 2}, nil, true)
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
        SendNotif(ply, {"That team is full."}, {CurTime() + 1}, nil, true)
        return
    end

    if MatchInProgress == true then --
        if ply:Team() == TEAM_SPECTATOR then
            ply.DiedInRound = true
        else
            SendNotif(ply, {"Match is in progress."}, {CurTime() + 1}, nil, true)
            return
        end
    end

    LastTeamRequestTimes[ply] = CurTime()
    ply:SetTeam(RequestedTeam)
    print(ply:Nick() .. " team set to " .. team.GetName(RequestedTeam) .. "(" .. RequestedTeam .. ")")
    SendNotif(ply, {ply:Nick() .. " has joined " .. ((RequestedTeam ~= TEAM_SPECTATOR and " team " .. (team.GetName(RequestedTeam) or "N/A")) or "the spectators") .. "."}, {CurTime() + 2}, nil, true)
end)

local player_color_red = Vector(1, 0, 0)
local player_color_blue = Vector(0, 0, 1)
local player_color_white = Vector(1, 1, 1)
AddGamemodeHook("PlayerSetModel", "SetTeamColors", function(ply)
    if ShouldRunHook() == false then return end
    timer.Simple(0, function()
        local PlayerTeam = ply:Team()
        ply:SetPlayerColor((PlayerTeam == TEAM_RED and player_color_red or PlayerTeam == TEAM_BLUE and player_color_blue) or player_color_white)
    end)
end)

AddGamemodeHook("PlayerChangedTeam", "SpectateStateOnTeamChange", function(ply, oldTeam, newTeam)
    print(oldTeam, newTeam, MatchInProgress, newTeam ~= TEAM_SPECTATOR)
    if oldTeam == TEAM_SPECTATOR and RoundInProgress == false then --
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

--[[------------------------------
        Teams setup
--------------------------------]]
team.SetUp(TEAM_RED, "Red", colortable.color_red, true)
team.SetUp(TEAM_BLUE, "Blue", colortable.color_blue, true)
--[[------------------------------
        CA startup
--------------------------------]]
for _, ply in player.Iterator() do
    ply:SetTeam(TEAM_SPECTATOR)
    ply:KillSilent()
    FSpectate.startSpectating(ply, nil, false)
end

AddGamemodeHook("CanPlayerSuicide", "DisableSuicide", function(ply)
    if ShouldRunHook() == false then return end
    return false
end)

AddGamemodeHook("ScalePlayerDamage", "DisableFriendlyFire", function(ply, hitgroup, dmginfo)
    if ShouldRunHook() == false then return end
    if ply:Team() == dmginfo:GetAttacker():Team() then --
        return true
    else
        return
    end
end, PRE_HOOK_RETURN)

function gm.SetMatchWarmup(bool)
    --MatchWarmup = bool 
    SetGlobalBool("MatchWarmup", bool)
    --[[
        -- Actually probably not necessary, GetGlobalBool's defaults should handle it
        net.Start("SendWarmupState")
        net.WriteBool(bool)
        net.Broadcast()
    --]]
end

--[[
util.AddNetworkString("OpenJoinTeamPopup")
local function OpenJoinTeamPopup(ply)
    net.Start("OpenJoinTeamPopup")
    net.WriteBool(RankedMatch)
    if ply then
        net.Send(ply)
    else
        net.Broadcast()
    end
end
--]]
--[[------------------------------
    RemoveConflictingHooks
--------------------------------]]
util.AddNetworkString("RemoveConflictingHooks")
--hook.remove duels saycommands, change around hooks, etc
timer.Remove("AutoRTV")
hook.Remove("PlayerInitialSpawn", "NetworkMOTD")
hook.Remove("OnRequestFullUpdate", "NetworkMOTD")
hook.Remove("PlayerDeath", "RewardPlayer")
hook.Remove("PlayerHurt", "HurtContributions")
hook.Remove("ScalePlayerDamage", "RestrictTeamDamage")
--AddGamemodeHook("PlayerSpawn", "SetCollisionRulesOnSpawnReturn", function() return ConflictingHookReturn() end,  POST_HOOK_RETURN)
hook.Remove("PlayerSay", "HandleChatCommands")
hook.Remove("PlayerLoadout", "GiveSpawnWeapons")
hook.Remove("ShouldCollide", "MakePlayersNotCollide")
hook.Remove("ShouldCollide", "OnlyCollideEntWithSelf")
hook.Remove("PlayerSpawn", "SetSpawnHealthArmor")
net.Start("RemoveConflictingHooks")
net.Broadcast()
-- Network the JoinTeam popup and ReadyUp HUD to newly connecting players
--[[
local Queue = {}
AddGamemodeHook("PlayerInitialSpawn", "ReadyUpJoinTeamNetworking", function(ply)
    if ShouldRunHook() == false then
        hook.Remove("PlayerInitialSpawn", "ReadyUpJoinTeamNetworking")
        return
    end

    Queue[ply:UserID()] = true
end)

gameevent.Listen("OnRequestFullUpdate")
AddGamemodeHook("OnRequestFullUpdate", "ReadyUpJoinTeamNetworking", function(data)
    if ShouldRunHook() == false then return end
    local UID = data.userid -- Same as Player:UserID()
    if not Queue[UID] then return end
    Queue[UID] = nil
    --
    -- networking
    local ply = Player(UID)
    -- Remove conflicting hooks
    net.Start("RemoveConflictingHooks")
    net.Send(ply)
end)
--]]
AddGamemodeHook("PlayerInitialSpawn", "dfasfa", function(ply, trans)
    net.Start("RemoveConflictingHooks")
    net.Send(ply)
end)

AddGamemodeHook("PlayerGiveSWEP", "PreventWeaponGiving", function(ply, class, spawninfo)
    if ShouldRunHook() == false then return end
    return false
end)

local Loadout = {
    ["weapon_357"] = 9999,
    ["weapon_ar2"] = 9999,
    ["weapon_crossbow"] = 9999,
    ["weapon_crowbar"] = 9999,
    ["weapon_frag"] = 2,
    ["weapon_physcannon"] = 9999,
    ["weapon_pistol"] = 9999,
    ["weapon_shotgun"] = 9999,
    ["weapon_smg1"] = 9999,
}

--PrintTable(FindHooksByName("PlayerLoadout"))
local CustomHealth = 100
local CustomArmor = 100
function gm.GiveCustomLoadout(ply)
    ply:SetHealth(CustomHealth)
    ply:SetArmor(CustomArmor)
    for weaponclass, ammocount in pairs(Loadout) do
        ply:Give(weaponclass)
        local WeaponEntity = ply:GetWeapon(weaponclass)
        if not IsValid(WeaponEntity) then return end
        local AmmoType = WeaponEntity:GetPrimaryAmmoType()
        ply:RemoveAmmo(100000, AmmoType)
        ply:GiveAmmo(ammocount, AmmoType)
        WeaponEntity:SetClip1(WeaponEntity:GetMaxClip1())
    end
end

removedClasses["weapon_frag"] = nil
AddGamemodeHook("PlayerLoadout", "CustomLoadout", function(ply)
    if ShouldRunHook() == false then return end
    gm.GiveCustomLoadout(ply)
    return true
end, PRE_HOOK_RETURN)

AddGamemodeHook("PlayerSpawn", "FixMetaSpawnNotWorkingOnPlayers", function(ply, trans)
    if ShouldRunHook() == false then return end
    gm.GiveCustomLoadout(ply)
end, PRE_HOOK_RETURN)

--[[------------------------------
        Gamemode Inits
--------------------------------]]
for _, ply in player.Iterator() do -- for autorefresh
    ply.ReadyUpState = false
    ply:SetNWBool("Ready", false)
    ply.DiedInRound = nil
end
--[[------------------------------
    debug helpers
--------------------------------]]
--[[
local function FindHooksByName(event_name)
    local hooks = {}
    for k, v in pairs(hook.GetTable()) do
        if k == event_name then
            for hookid, vv in pairs(v) do
                hooks[#hooks + 1] = hookid
            end
        end
    end
    return hooks
end

PrintTable(FindHooksByName("ScalePlayerDamage"))
--]]
