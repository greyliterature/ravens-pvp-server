local function GetAllSubFiles(directory, path, filetype, subfiles) -- https://wiki.facepunch.com/gmod/Global.include#example
    subfiles = subfiles or {}
    directory = directory .. "/"
    local files, directories = file.Find(directory .. "*", path)
    for _, v in ipairs(files) do
        if string.EndsWith(v, filetype) then --
            subfiles[#subfiles + 1] = directory .. v
        end
    end

    for _, v in ipairs(directories) do
        GetAllSubFiles(directory .. v, path, filetype, subfiles)
    end
    return subfiles
end

rv_GamemodeHooks = {}
function AddGamemodeHook(hookname, identifier, func)
    if not hookname then
        error("no hookname")
    elseif not identifier then
        error("no identifier")
    end

    hook.Add(hookname, identifier, func)
    for i = 1, #rv_GamemodeHooks do
        if rv_GamemodeHooks[i][1] == hookname and rv_GamemodeHooks[i][2] == identifier then -- the hook is already in the table, stop spamming entries into the table
            return
        end
    end

    rv_GamemodeHooks[#rv_GamemodeHooks + 1] = {hookname, identifier}
    print("added hook", hookname, identifier)
end

local function RemoveLastGamemodesHooks()
    if #rv_GamemodeHooks == 0 then return end
    for i = #rv_GamemodeHooks, 1, -1 do
        local hookname = rv_GamemodeHooks[i][1]
        local identifier = rv_GamemodeHooks[i][2]
        hook.Remove(hookname, identifier)
        print("removed hook ", hookname, identifier)
        rv_GamemodeHooks[hookname] = nil
    end
end

--[[------------------------------
    init 
--------------------------------]]
--[[
-- not necessary
if SERVER then
    local path = "customgamemodes/server"
    for _, filename in ipairs(GetAllSubFiles(path, "LUA", ".lua")) do
        print("include(" .. filename .. ")")
        include(filename)
    end
    
end
--]]
local path = "customgamemodes/client"
for _, filename in ipairs(GetAllSubFiles(path, "LUA", ".lua")) do
    if SERVER then
        print("AddCSLuaFile(" .. filename .. ")")
        AddCSLuaFile(filename)
        --[[
        -- not necessary, the SetGamemode net should include it on clients. it should not be autorun always
        elseif CLIENT then    
            print("include(" .. filename .. ")")
            include(filename)
        --]]
    end
end

--[[------------------------------
        SetGamemode
--------------------------------]]
local GamemodeVars = include("customgamemodes/gamemodevars.lua")
AddCSLuaFile("customgamemodes/gamemodevars.lua")
--[[
    local GamemodeVars = {
        CurrentGamemode = {"String", "FFA"},
        RoundLimit = {"Int", 10},
    }
--]]
--[[
if SERVER then
    util.AddNetworkString("UpdateGamemodeVar")
    function UpdateGamemodeVar(VarName, NewValue, BitCount)
        BitCount = BitCount or 0
        net.Start("UpdateGamemodeVar")
        net.WriteString(VarName)
        local VarType = GamemodeVars[VarName][1]
        net.WriteString(VarType)
        net.WriteUInt(BitCount, 6)
        local WriteAny = net["Write" .. VarType]
        print(NewValue, BitCount)
        WriteAny(NewValue, BitCount)
        SetGlobal3(VarType, VarName, NewValue)
        --_G["SetGlobal" .. VarType](VarName, NewValue)
        net.Broadcast()
    end
elseif CLIENT then
    net.Receive("UpdateGamemodeVar", function(len, ply)
        local VarName = net.ReadString()
        local VarType = net.ReadString()
        local BitCount = net.ReadUInt(6)
        local VarValue = net["Read" .. VarType](BitCount)
        GamemodeVars[VarName] = GamemodeVars[VarName] or {}
        GamemodeVars[VarName][2] = VarValue
    end)
end
--]]
if SERVER then
    --[[
    local GamemodeInit = {
        ["CA"] = function()
            SetUpTeamsSystem()
            SetAllToSpec()
            gm.SetMatchInProgress(false)
            SetGroundRules()
            AutoRefresh()
            EnableCustomLoadout()
            PreventWeaponGiving()
            NetworkThings()
            SetUpPlayerSpectate()
            DisableSuicide()
            RemoveConflictingHooks()
            gm.SetMatchWarmup(true)
            SetupTeams()
            DisableFriendlyFire()
            OpenJoinTeamPopup(nil)
            OpenReadyUpHUD(nil)
            --ShouldCollideConflictFix()
        end,
    }
    --]]
    util.AddNetworkString("SendNewGamemode")
    function SetGamemode(NewGamemode, RoundLimit, Ranked)
        NewGamemode = string.lower(NewGamemode)
        GamemodeVars.CurrentGamemode[2] = NewGamemode
        SetGlobal3("String", "CurrentGamemode", NewGamemode)
        GamemodeVars.RoundLimit[2] = RoundLimit or 10
        GamemodeVars.RankedMatch[2] = Ranked == true
        --[[
        for VarName, tbl in pairs(GamemodeVars) do
            --local VarType = tbl[1]
            local VarValue = tbl[2]
            local BitCount = tbl[3]
            --UpdateGamemodeVar(VarName, VarValue, BitCount)
            --[[
            local func = _G["SetGlobal2" .. VarType] -- SetGlobal .. "Int"(VarName, VarValue)
            if func then --
                func(VarName, VarValue)
            end
            
        end
        --]]
        --net.Start("SendNewGamemode")
        --net.Broadcast()
        local InitPath = "customgamemodes/server/" .. NewGamemode .. "/" .. "!" .. NewGamemode .. "_init.lua"
        if file.Exists(InitPath, "LUA") then --
            RemoveLastGamemodesHooks()
            include(InitPath)
        end
    end
    --SetGamemode("ca", 10)
elseif CLIENT then
    local function GamemodeInit()
        RemoveLastGamemodesHooks()
        --[[
        for VarName, tbl in pairs(GamemodeVars) do
            local VarType = tbl[1]
            local func = _G["GetGlobal2" .. VarType] -- GetGlobal .. "Int"(VarName, nil)
            if func then --
                GamemodeVars[VarName][2] = func(VarName, nil)
            end
        end
        --]]
        local CurrentGamemode = GetGlobal3("CurrentGamemode", "FFA") --string.lower(GamemodeVars.CurrentGamemode[2])
        local InitPath = "customgamemodes/client/" .. CurrentGamemode .. "/" .. "!" .. CurrentGamemode .. "_init.lua"
        print(InitPath)
        if file.Exists(InitPath, "LUA") then --
            include(InitPath)
        end
        --[[
        local _, directories = file.Find("customgamemodes/client/" .. CurrentGamemode, "LUA")
        if directories then
            for _, filename in ipairs(GetAllSubFiles("customgamemodes/client/" .. CurrentGamemode, "LUA", ".lua")) do
                print("running (" .. filename .. ")")
                include(filename)
            end
        end
        --]]
    end

    hook.Add("Global3VarChanged", "GamemodeInit", function(VarType, VarIndex, VarNewValue, init)
        if VarIndex ~= "CurrentGamemode" then return end
        GamemodeInit()
    end)
    --[[
    hook.Add("InitPostEntity", "GamemodeInit", GamemodeInit)
    net.Receive("SendNewGamemode", function(len, ply)
        --
        GamemodeInit()
    end)
    --]]
end

--[[------------------------------
    VoteGamemode
--------------------------------]]
local function IsValidGamemode(GamemodeName)
    if not GamemodeName then return false end
    local ValidGamemode = file.IsDir("customgamemodes/server/" .. GamemodeName, "LUA")
    return ValidGamemode
end

local VotedForModes = {}
local VoteRatio = 0.75
local function CeilInt(x) -- math.ceil does not round up for integers
    return math.floor(x) + 1
end

local ChangeModeRateLimit = 60 -- seconds
local LastModeChange = 0
hook.Add("PlayerSay", "VotemodeCommands", function(sender, text, teamChat)
    text = string.lower(text)
    local exploded = string.Explode(" ", text)
    local command = exploded[1]
    local args = exploded
    if #args > 1 then table.remove(args, 1) end
    table.RemoveByValue(args, "")
    if GamemodeVars.MatchInProgress[2] == true then return end
    if command == "!votemode" and IsValidGamemode(args[1]) == true then --
        if LastModeChange + ChangeModeRateLimit > CurTime() then
            timer.Simple(0, function()
                --
                sender:ChatPrint("Please wait " .. math.floor((LastModeChange + ChangeModeRateLimit) - CurTime()) .. " seconds before voting to change mode.")
            end)
            return
        end

        local VotedForMode = args[1]
        if sender.VotedForMode and VotedForModes[VotedForMode] then --
            if sender.VotedForMode == VotedForModes[VotedForMode] then return end
            VotedForModes[VotedForMode] = VotedForModes[sender.VotedForMode] - 1
        end

        sender.VotedForMode = VotedForMode
        VotedForModes[VotedForMode] = (VotedForModes[VotedForMode] or 0) + 1
        local VoteRequirement = CeilInt(VoteRatio * #player.GetAll())
        local ModeVotes = VotedForModes[VotedForMode]
        timer.Simple(0, function()
            --
            PrintMessage(HUD_PRINTTALK, sender:Nick() .. " has voted to change mode to " .. args[1] .. ". (" .. ModeVotes .. " / " .. VoteRequirement .. ")")
        end)

        if VotedForModes[VotedForMode] >= VoteRequirement then --
            VotedForModes[VotedForMode] = 0
            sender.VotedForMode = nil
            LastModeChange = CurTime()
            SetGamemode(VotedForMode, 10)
        end
    end
end)

hook.Add("PlayerDisconnected", "DiscountVotesOnDisconnect", function(ply)
    if ply.VotedForMode and VotedForModes[ply.VotedForMode] then --
        VotedForModes[ply.VotedForMode] = VotedForModes[ply.VotedForMode] - 1
    end
end)
