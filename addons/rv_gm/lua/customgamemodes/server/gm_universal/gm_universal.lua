rv_gm = {}
RemoveLastGamemodesEntities()
local TEAM_RED, TEAM_BLUE = 1, 2
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

function rv_gm.ForcePlayerToUnSpectate(ply)
    FSpectate.forceUnspectate(ply)
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

function rv_gm.SetPlayerToNotRespawn(ply, bool)
    ply.CanRespawn = (bool == true and bool) or nil
end

hook.Add("PlayerDeathThink", "AllowPlayerRespawns", function(ply)
    if CanPlayersRespawn == false then
        if not ply.CanRespawn then
            return false
        else
            return
        end
    end
    return
end)

local TeamIndexes = {}
function rv_gm.SetUpTeams(tbl)
    TeamIndexes = {}
    for teamindex, elements in pairs(tbl) do
        TeamIndexes[#TeamIndexes + 1] = teamindex
        team.SetUp(teamindex, elements.teamname, elements.teamcolor, elements.isjoinable)
    end
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

local CanPlayersFriendlyfire = nil
function rv_gm.AllowPlayerFriendlyFire(bool)
    if bool == true then
        CanPlayersFriendlyfire = nil
    elseif bool == false then
        CanPlayersFriendlyfire = false
    end
end

AddGamemodeHook("ScalePlayerDamage", "DisableFriendlyFire", function(ply, hitgroup, dmginfo)
    if not CanPlayersFriendlyfire then return end
    local attacker = dmginfo:GetAttacker()
    if not attacker:IsPlayer() then return end
    if ply:Team() == attacker:Team() then return CanPlayersFriendlyfire end
end)

AddGamemodeHook("CanPlayerSuicide", "DisableSuicide", function(ply)
    --
    return CanPlayersSuicide
end)

hook.Add("InitPostEntityStarted", "SetSpectateOnJoin", function(ply)
    local ShouldSpectateOnJoin = hook.Run("ShouldSpectateOnJoin", ply)
    if ShouldSpectateOnJoin ~= true then return end
    rv_gm.ForcePlayerToSpectate(ply, nil)
end)

--[[------------------------------
    Spawn system
--------------------------------]]
rv_gm.Info_player_starts = {}
function rv_gm.RemoveAllSpawns() -- don't forgot to run rv_gm.ReaddAllSpawns() after the match is over
    for _, info_player_start in ipairs(ents.FindByClass("info_player_start")) do
        local pos = info_player_start:GetPos()
        local angs = info_player_start:GetAngles()
        rv_gm.Info_player_starts[#rv_gm.Info_player_starts + 1] = {pos, angs}
        info_player_start:Remove()
    end
end

function rv_gm.CreateSpawn(vec, angs, teamindex)
    local Info_player_start = rv_gm.CreateGamemodeEntity("info_player_start")
    Info_player_start:SetPos(vec)
    Info_player_start.TeamIndex = teamindex
    Info_player_start:Spawn()
end

function rv_gm.ReaddAllSpawns()
    for _, tbl in ipairs(rv_gm.Info_player_starts) do
        local pos = tbl[1]
        local angs = tbl[2]
        rv_gm.CreateSpawn(pos, angs, nil)
    end
end

--[[------------------------------
    Remove conflicting hooks (FFA)
--------------------------------]]
function rv_gm.RemoveConflictingHooks()
    timer.Remove("AutoRTV")
    hook.Remove("PlayerInitialSpawn", "NetworkMOTD")
    hook.Remove("OnRequestFullUpdate", "NetworkMOTD")
    hook.Remove("ScalePlayerDamage", "RestrictTeamDamage")
    hook.Remove("PlayerSay", "HandleChatCommands")
    hook.Remove("ShouldCollide", "MakePlayersNotCollide")
    hook.Remove("ShouldCollide", "OnlyCollideEntWithSelf")
    hook.Remove("PlayerSpawn", "SetSpawnHealthArmor")
end

function rv_gm.DisablePlayerRewards()
    AddGamemodeHook("ShouldRefillAmmoOnSpawn", "CustomLoadout", function(ply)
        --
        return false
    end)

    AddGamemodeHook("ShouldRewardPlayer", "CustomLoadout", function(ply)
        --
        return false
    end)

    AddGamemodeHook("GetCustomLoadout", "CustomLoadout", function(ply)
        --
        return Loadout
    end)
end

--[[------------------------------
    Triggers
--------------------------------]]
function rv_gm.GetAllTriggerParents()
end

--local color_transparent = Color(0, 0, 0, 0)
--
local InfoParents = {}
function rv_gm.CreateTrigger(vec, parent, minbounds, maxbounds, parentcolor, starttouchfunc, touchfunc, endtouchfunc)
    local trigger = rv_gm.CreateGamemodeEntity("base_brush")
    trigger:SetPos(vec)
    trigger:Spawn()
    trigger:Activate()
    trigger:SetCollisionBounds(minbounds, maxbounds)
    trigger:SetCollisionGroup(COLLISION_GROUP_NONE)
    trigger:SetSolid(SOLID_BBOX)
    trigger:SetNotSolid(true)
    if starttouchfunc then
        function trigger.StartTouch(self, ent)
            if ent.IsInfoParentPot then return end
            starttouchfunc(self, ent)
        end
    end

    if touchfunc then
        function trigger.Touch(self, ent)
            if ent.IsInfoParentPot then return end
            touchfunc(self, ent)
        end
    end

    if endtouchfunc then
        function trigger.EndTouch(self, ent)
            if ent.IsInfoParentPot then return end
            endtouchfunc(self, ent)
        end
    end

    trigger:SetTrigger(true)
    trigger:SetParent(parent)
    trigger:SetLocalPos(vector_origin)
    local InfoParent = rv_gm.CreateGamemodeEntity("prop_physics")
    InfoParent:SetModel("models/props_interiors/pot02a.mdl")
    InfoParent:SetPos(trigger:GetPos())
    InfoParent:Spawn()
    InfoParent:SetCollisionBounds(minbounds, maxbounds)
    InfoParent:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
    InfoParent:GetPhysicsObject():EnableMotion(false)
    parentcolorcopy = parentcolor:Copy()
    parentcolorcopy.a = 0
    InfoParent:SetColor(parentcolorcopy)
    InfoParent:SetRenderMode(RENDERMODE_TRANSCOLOR)
    InfoParent.IsInfoParentPot = true
    InfoParents[trigger] = InfoParent
    timer.Simple(0.1, function()
        --
        rv_gm.SendTriggerInfo(nil, InfoParent)
    end)
    return trigger
end

AddGamemodeHook("Think", "SetInfoParentPoses", function()
    for trigger, infoparent in pairs(InfoParents) do
        if not IsValid(infoparent) or not IsValid(trigger) then
            InfoParents[trigger] = nil
            continue
        end

        infoparent:SetPos(trigger:GetPos())
        infoparent:SetAngles(trigger:GetAngles())
    end
end)

util.AddNetworkString("TriggerParentMade")
function rv_gm.SendTriggerInfo(ply, triggerparent)
    net.Start("TriggerParentMade")
    net.WriteEntity(triggerparent)
    net[(ply and "Send") or "Broadcast"](ply)
end

--[[------------------------------
    Ent garbage collection
--------------------------------]]
function rv_gm.CreateGamemodeEntity(class)
    local ent = ents.Create(class)
    GamemodeEntities[#GamemodeEntities + 1] = ent
    return ent
end

--[[------------------------------
    Gamemode Data (flag poses, hill poses, etc.)
--------------------------------]]
local GamemodeData = nil
local GamemodeDataPath = "rv_gamemodedata.json"
if file.Exists(GamemodeDataPath, "DATA") then --
    GamemodeData = util.JSONToTable(file.Read(GamemodeDataPath, "DATA"))
end

function rv_gm.AddGamemodeData(category, tbl, map) -- please do not use .bsp for this, game.GetMap() does not include .bsp.
    GamemodeData = GamemodeData or {}
    GamemodeData[map] = GamemodeData[map] or {}
    GamemodeData[map][category] = tbl
    file.Write(GamemodeDataPath, util.TableToJSON(GamemodeData, true))
end

--[[
rv_gm.AddGamemodeData("Flags", {
    [1] = Vector(-2485.022705, -2778.487061, 428.661743),
    [2] = Vector(1775.324463, 12.771225, -42.469872),
}, "gm_construct")

rv_gm.AddGamemodeData("Spawns", {
    [1] = {
        --
        Vector(-2657.591797, -2696.772949, 340.514252),
        Angle(0, 0, 0)
    },
    [2] = {
        --
        Vector(1530.274048, 215.959045, -22.229469),
        Angle(0, 180, 0)
    },
}, "gm_construct")
--]]
function rv_gm.RequestGamemodeData()
    hook.Run("rv_gm.GamemodeDataLoaded", GamemodeData)
end

--[[------------------------------
    CTF (shared because maybe its needed in another mode)
--------------------------------]]
local FlagBaseModel = "models/props_c17/gravestone_cross001b.mdl"
local FlagBaseFlagOffset = Vector(0, 0, 40)
local FlagBaseDetectionMins = Vector(-25, -25, -25)
local FlagBaseDetectionMaxes = Vector(25, 25, 75)
local CTFEntities = {}
util.AddNetworkString("CTFEntityCreated")
function rv_gm.CreateDollFlagBase(vec, teamindex, spawnwithflag)
    local FlagBase = rv_gm.CreateGamemodeEntity("prop_physics")
    FlagBase:SetModel(FlagBaseModel)
    FlagBase:SetModelScale(0.5, 0)
    FlagBase:SetPos(vec)
    FlagBase.TeamIndex = teamindex
    FlagBase:SetColor(team.GetColor(teamindex))
    FlagBase:Spawn()
    FlagBase:GetPhysicsObject():EnableMotion(false)
    FlagBase:Activate()
    if spawnwithflag == true then --
        rv_gm.CreateDollFlag(vec + FlagBaseFlagOffset, teamindex)
    end

    local function starttouchfunc(self, ent)
        if not ent.IsDollFlag then return end
        if ent.TeamIndex == self.TeamIndex then return end
        rv_gm.ReturnDollFlagToBase(ent)
        rv_gm.AddTeamScore(ent.TeamIndex, 1)
    end

    --[[
    local function endtouchfunc(self, ent)
        if not ent.IsDollFlag then return end
        ent.AtBase = nil
        rv_gm.SetDollPhysicsNormal(ent)
    end
    --]]
    timer.Simple(0.5, function()
        if not IsValid(FlagBase) then return end
        net.Start("CTFEntityCreated")
        net.WriteEntity(FlagBase)
        net.WriteUInt(FlagBase.TeamIndex, 7)
        net.Broadcast()
    end)

    local trigger = rv_gm.CreateTrigger(Vector(0, 0, 0), FlagBase, FlagBaseDetectionMins, FlagBaseDetectionMaxes, team.GetColor(teamindex), starttouchfunc, nil, endtouchfunc)
    trigger.TeamIndex = teamindex
    trigger.IsBase = true
    CTFEntities[FlagBase] = true
    return FlagBase
end

local CTFDollFlags = {}
--local DollDetectionMins = Vector(-15, -15, -5)
--local DollDetectionMaxes = Vector(15, 15, 30)
local DollModel = "models/maxofs2d/companion_doll.mdl"
function rv_gm.CreateDollFlag(vec, teamindex)
    local doll = rv_gm.CreateGamemodeEntity("prop_physics")
    doll:AddEFlags(EFL_IN_SKYBOX)
    doll:SetModel(DollModel)
    doll:SetPos(vec)
    doll.TeamIndex = teamindex
    doll:SetColor(team.GetColor(teamindex))
    doll:Spawn()
    rv_gm.SetDollPhysicsStatic(doll)
    doll.AtBase = true
    doll.IsDollFlag = true
    doll.BasePos = vec
    timer.Simple(0.5, function()
        if not IsValid(doll) then return end
        net.Start("CTFEntityCreated")
        net.WriteEntity(doll)
        net.WriteUInt(doll.TeamIndex, 7)
        net.Broadcast()
    end)

    CTFDollFlags[doll] = true
    CTFEntities[doll] = true
    --local trigger = rv_gm.CreateTrigger(Vector(0, 0, 0), doll, DollDetectionMins, DollDetectionMaxes, team.GetColor(teamindex), starttouchfunc, print("yoo"), print("yoooo"))
    --trigger.TeamIndex = teamindex
end

function rv_gm.GetAllDollFlags()
    return CTFDollFlags
end

util.AddNetworkString("InitCTFEntities")
AddGamemodeHook("InitPostEntityStarted", "SendCTFEntities", function(ply)
    net.Start("InitCTFEntities")
    local NumKeys = table.Count(CTFEntities)
    net.WriteUInt(NumKeys, 6)
    for ent, _ in pairs(CTFEntities) do
        net.WriteEntity(ent)
        net.WriteUInt(ent.TeamIndex, 7)
    end
end)

util.AddNetworkString("RevealFlag")
local RevelationDelay = 5 -- reveal after x seconds of picking up flag
function rv_gm.SetRevelationDelay(delay)
    RevelationDelay = delay
end

local FlagReturnDelay = 9999
function rv_gm.SetFlagReturnDelay(delay)
    FlagReturnDelay = delay
    SetGlobal3("Float", "FlagReturnDelay", delay)
end

function rv_gm.RevealFlag(revealedply, ent, bool)
    net.Start("RevealFlag")
    net.WritePlayer(revealedply)
    net.WriteEntity(ent)
    net.WriteBool(bool)
    net.Broadcast()
    hook.Run("rv_gm.FlagRevealed", revealedply, ent, Revealed)
    if bool == false or bool == nil then timer.Remove("FlagRevelation" .. ent:EntIndex()) end
end

util.AddNetworkString("PlayerPickedUpCTFEntity")
AddGamemodeHook("GravGunOnPickedUp", "NetworkGravGunForFlags", function(ply, ent)
    if not CTFEntities[ent] then return end
    ent.LastPickedUpPly = ply
    ent.AtBase = false
    net.Start("PlayerPickedUpCTFEntity")
    local PickedUp = true
    net.WriteBool(PickedUp)
    net.WriteEntity(ent)
    net.WritePlayer(ply)
    net.Broadcast()
    if timer.Exists("FlagRevelation" .. ent:EntIndex()) then return end
    timer.Create("FlagRevelation" .. ent:EntIndex(), RevelationDelay, 1, function()
        --
        rv_gm.RevealFlag(ent.LastPickedUpPly, ent, not ent.AtBase)
    end)
end)

AddGamemodeHook("GravGunOnDropped", "NetworkGravGunForFlags", function(ply, ent)
    if not CTFEntities[ent] then return end
    ent.LastPickedUpPly = nil
    if ent.AtBase == false then
        print("YUP")
        timer.Create("RTBDollFlag" .. ent:EntIndex(), FlagReturnDelay, 1, function()
            rv_gm.ReturnDollFlagToBase(ent) --
        end)
    end

    net.Start("PlayerPickedUpCTFEntity")
    local PickedUp = false
    net.WriteBool(PickedUp)
    net.WriteEntity(ent)
    net.WritePlayer(ply)
    net.Broadcast()
end)

function rv_gm.SetDollPhysicsStatic(doll)
    local physobj = doll:GetPhysicsObject()
    --physobj:SetAngleDragCoefficient(1000000)
    physobj:SetDragCoefficient(1000000)
    --physobj:SetDamping(100000, 100000)
    --physobj:SetInertia(Vector(100000, 100000, 100000))
    doll:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    doll:SetVelocity(vector_origin)
    physobj:SetAngleVelocity(vector_origin)
    physobj:SetAngleVelocityInstantaneous(vector_origin)
    doll:SetAngles(angle_zero)
end

function rv_gm.SetDollPhysicsNormal(doll)
    print("run eyaedfsadsfyefea")
    local physobj = doll:GetPhysicsObject()
    physobj:SetAngleDragCoefficient(0.2)
    physobj:SetDragCoefficient(0.07)
    physobj:SetMass(1)
    --physobj:SetDamping(0, 0)
    --physobj:SetInertia(Vector(0.1, 0.1, 0.1))
    --physobj:SetMass(1)
    doll:SetCollisionGroup(COLLISION_GROUP_NONE)
end

util.AddNetworkString("DollRTBed")
function rv_gm.ReturnDollFlagToBase(doll)
    rv_gm.SetDollPhysicsStatic(doll)
    doll.AtBase = true
    doll:ForcePlayerDrop()
    doll:SetPos(doll.BasePos)
    net.Start("DollRTBed")
    net.WriteEntity(doll)
    net.Broadcast()
    rv_gm.RevealFlag(nil, doll, false)
end

AddGamemodeHook("GravGunPickupAllowed", "DollFlagPickup", function(ply, ent)
    if not ent.IsDollFlag then return end
    local CanPickupDollFlag = hook.Run("rv_gm.CanPickupDollFlag", ply, ent)
    return CanPickupDollFlag
end)

AddGamemodeHook("GravGunOnPickedUp", "DollFlagPickup", function(ply, ent)
    if not ent.IsDollFlag then return end
    hook.Run("rv_gm.DollFlagPickedUp", ply, ent)
end)

AddGamemodeHook("GravGunPunt", "DollFlagPunt", function(ply, ent)
    --
    if not ent.IsDollFlag then return end
    local CanPunt = hook.Run("rv_gm.DollFlagPunt", ply, ent)
    return CanPunt
end)

--[[------------------------------
    Match logic
--------------------------------]]
local MatchInProgress = false
function rv_gm.SetMatchInProgress(bool)
    MatchInProgress = bool
    SetGlobal3("Bool", "MatchInProgress", bool)
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
        if MatchInProgress == false then return end
        rv_gm.EndMatch()
    end)
end

function rv_gm.SetJoinTeam(ply)
    if ply:IsBot() then
        print(ply)
        ply:SetTeam(TEAM_RED)
    else
        ply:SetTeam(TEAM_SPECTATOR)
    end
end

hook.Add("PlayerInitialSpawn", "SetTeamOnJoin", function(ply, _)
    --
    rv_gm.SetJoinTeam(ply)
end)

function rv_gm.ResetScores(Teams)
    if not Teams then Teams = rv_gm.GetTeamIndexes() end
    for teamindex, _ in pairs(team.GetAllTeams()) do
        team.SetScore(teamindex, 0)
    end
end

local ScoreLimit = 100
function rv_gm.SetScoreLimit(score)
    ScoreLimit = score
    SetGlobal3("Int", "MatchScoreLimit", score)
end

function rv_gm.AddTeamScore(teamindex, score)
    if MatchInProgress == false then return end
    team.AddScore(teamindex, score)
    if team.GetScore(teamindex) >= ScoreLimit then
        --
        rv_gm.EndMatch()
    end
end

-- Start/endround
local RoundCount = 0
function rv_gm.StartRound()
    RoundCount = RoundCount + 1
    hook.Run("rv_gm.RoundStarted", RoundCount)
end

-- Start/Endmatch
function rv_gm.ShuffleTeams(Teams)
    if not Teams then Teams = rv_gm.GetTeamIndexes() end
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

function rv_gm.RespawnAllPlayers(Teams)
    if not Teams then Teams = rv_gm.GetTeamIndexes() end
    -- respawn everyone in {Teams1, Teams2, ... , TeamsN}
    for _, TeamIndex in ipairs(Teams) do
        for _, ply in ipairs(team.GetPlayers(TeamIndex)) do
            FSpectate.forceUnspectate(ply)
            ply:Spawn()
        end
    end
end

rv_gm.SetMatchInProgress(false) -- autorefresh
function rv_gm.StartMatch()
    rv_gm.SetMatchInProgress(true)
    timer.Remove("MatchTimeLimit") -- or else conflicts, annoying but yeah
    hook.Run("rv_gm.MatchStarted")
end

function rv_gm.EndMatch()
    local WinnerIndex, BestTeamScore = -9999, 0
    local loserstbl = {}
    for _, teamindex in ipairs(rv_gm.GetTeamIndexes()) do
        local teamscore = team.GetScore(teamindex)
        loserstbl[teamindex] = teamscore
        if teamscore > BestTeamScore then
            -- 
            WinnerIndex, BestTeamScore = teamindex, team.GetScore(BestTeamIndex)
        end
    end

    rv_gm.SetAllPlayersUnready()
    table.remove(loserstbl, WinnerIndex)
    timer.Remove("MatchTimeLimit")
    hook.Run("rv_gm.MatchEnded", WinnerIndex, loserstbl)
end

--[[------------------------------
    Warmup logic
--------------------------------]]
local ReadyUpRatio = 100
function rv_gm.SetReadyUpRatio(ratio)
    ReadyUpRatio = ratio
    SetGlobal3("Int", "ReadyUpRatio", ratio)
end

function rv_gm.GetValidPlayers()
    local players = {}
    for _, ply in player.Iterator() do
        local ShouldIncludePlayer = hook.Run("rv_gm.IsValidPlayer", ply)
        if ShouldIncludePlayer == true then
            players[#players + 1] = ply
        elseif ShouldIncludePlayer == false then
            continue
        elseif ShouldIncludePlayer == nil then
            -- could do with some ply:team() == TEAM_SPECTATOR logic here, 
            -- but for now expect the operator to know that 
            continue
        end
    end
    return players
end

local ReadyUpCount = 0
function rv_gm.SetPlayerReadiedUp(ply, bool)
    ply.ReadyUpState = (bool == nil and not ply.ReadyUpState) or bool
    ReadyUpCount = (ply.ReadyUpState == true and 1) or -1
    print("Set readyup state for " .. ply:Nick() .. " " .. tostring(ply.ReadyUpState))
    SetGlobal3("Int", "ReadyUpCount", ReadyUpCount)
    if ReadyUpCount > #rv_gm.GetValidPlayers() then --
        rv_gm.StartMatch()
    end
end

function rv_gm.SetAllPlayersUnready()
    for _, ply in player.Iterator() do
        ply.ReadyUpState = nil
        rv_gm.SetPlayerReadiedUp(ply, false)
    end

    ReadyUpCount = 0
    SetGlobal3("Int", "ReadyUpCount", ReadyUpCount)
end

rv_gm.SetAllPlayersUnready() -- for autorefresh
rv_gm.SetReadyUpRatio(ReadyUpRatio)
local PlayersCanReadyUp = false
function rv_gm.SetPlayersCanReadyUp(bool)
    PlayersCanReadyUp = bool
    SetGlobal3("Bool", "PlayersCanReadyUp", bool)
end

local LastReadyUpTimes = {} -- ply = CurTime()
local ReadyUpRateLimit = 0.1 -- seconds
AddGamemodeHook("PlayerButtonDown", "ReadyUpButtons", function(ply, button)
    --
    if button ~= KEY_F3 then return end
    if PlayersCanReadyUp == false then return end
    LastReadyUpTimes[ply] = LastReadyUpTimes[ply] or 0
    if LastReadyUpTimes[ply] + ReadyUpRateLimit > CurTime() then -- rate limited 
        return
    end

    LastReadyUpTimes[ply] = CurTime()
    if MatchInProgress == true then
        print(ply:Nick() .. " tried readying up while match is started")
        return
    end

    if #team.GetPlayers(TEAM_RED) == 0 or #team.GetPlayers(TEAM_BLUE) == 0 then
        print("UNCOMMENT THIS LATER")
        --rv_gm.SendNotif(ply, {"Both teams must be present to ready-up."}, {CurTime() + 2}, nil, true)
        --return
    end

    local CanPlayerReadyUp, err = hook.Run("rv_gm.CanPlayerReadyUp", ply)
    if CanPlayerReadyUp == false then
        print("SAD")
        rv_gm.SendNotif(ply, {err}, {CurTime() + 1}, nil, true)
        return
    end

    rv_gm.SetPlayerReadiedUp(ply)
    rv_gm.SendNotif(nil, {ply:Nick() .. " is" .. ((ply.ReadyUpState == true and "") or " not") .. " Ready"}, {CurTime() + 2}, nil, true)
end)

--[[------------------------------
    Teams request
--------------------------------]]
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
