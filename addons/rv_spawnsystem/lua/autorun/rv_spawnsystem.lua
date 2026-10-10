local maxdist = 500
maxdist = maxdist ^ 2 -- dont touch
local mindist = 300
mindist = mindist ^ 2 -- dont touch
--[[--]]
local function IsSpawnUsable(spawningply, ent)
    if table.Count(player.GetAll()) == 1 and SERVER then return true end
    for _, ply in player.Iterator() do
        if ply == spawningply then continue end
        local dist = ply:GetPos():DistToSqr(ent:GetPos())
        if dist > maxdist then
            return false -- too far 
        elseif dist < mindist then
            return false -- too close
        else
            return true -- just right!
        end
    end
end

local function DecideSpawn(ply, _)
    if CLIENT then ply = LocalPlayer() end
    local spawns = nil
    if SERVER then -- from https://gmodwiki.com/GM:PlayerSelectSpawn#example
        spawns = ents.FindByClass("info_player_start")
    elseif CLIENT then
        spawns = rv_spawns
    end

    local team_spawns = {}
    for _, spawn in ipairs(spawns) do
        if (spawn.TeamIndex and spawn.TeamIndex == ply:Team()) and ply:Team() ~= TEAM_UNASSIGNED then -- 
            team_spawns[#team_spawns + 1] = spawn
        end
    end

    if #team_spawns > 0 then
        local random_entry = math.random(1, #team_spawns)
        local random_spawn = team_spawns[random_entry]
        hook.Run("IsSpawnpointSuitable", ply, random_spawn, true)
        return random_spawn
    else
        local valid_spawns = {}
        for _, spawn in ipairs(spawns) do
            if IsSpawnUsable(ply, spawn) == true then --
                valid_spawns[#valid_spawns + 1] = spawn
            end
        end

        if #valid_spawns > 0 then
            local random_entry = math.random(1, #valid_spawns)
            return valid_spawns[random_entry]
        end
    end

    local random_entry = math.random(#spawns)
    for _, spawn in RandomPairs(spawns) do
        local IsSpawnPointSuitable = hook.Run("IsSpawnpointSuitable", ply, spawn, false)
        if IsSpawnPointSuitable ~= false then --
            return spawn
        end
    end
    return spawns[random_entry]
end

if SERVER then
    function CreateSpawnPoint(callingply, pos, angs, usePitch, teamindex)
        if IsValid(callingply) and not callingply:IsSuperAdmin() then return end
        teamindex = tonumber(teamindex)
        local Info_player_start = ents.Create("info_player_start")
        Info_player_start:SetPos(pos)
        if not usePitch then --
            angs.z = 0
        end

        Info_player_start:SetAngles(angs)
        Info_player_start.TeamIndex = tonumber(teamindex)
        Info_player_start:Spawn()
        Info_player_start:Activate()
        return Info_player_start
    end

    concommand.Add("rv_createspawn", function(ply, cmd, args)
        local usePitch = args[1]
        local teamindex = args[2]
        CreateSpawnPoint(ply, ply:GetPos(), ply:GetAngles(), usePitch, teamindex)
    end)

    hook.Add("PlayerSelectSpawn", "rv_spawnsystem", DecideSpawn)
    local Players = {}
    local RateLimit = 3
    util.AddNetworkString("rv_showspawns")
    util.AddNetworkString("rv_sendspawns")
    net.Receive("rv_showspawns", function(_, ply)
        Players[ply] = Players[ply] or 0
        if Players[ply] + RateLimit > CurTime() then return end
        if not ply:IsSuperAdmin() then return end
        net.Start("rv_sendspawns")
        local spawns = ents.FindByClass("info_player_start")
        local NumKeys = #spawns
        net.WriteUInt(NumKeys, 7)
        for i = 1, NumKeys do
            net.WriteVector(spawns[i]:GetPos())
            net.WriteAngle(spawns[i]:GetAngles())
            local teamindex = spawns[i].TeamIndex
            local hasteamindex = teamindex ~= nil
            net.WriteBool(hasteamindex)
            if hasteamindex == true then --
                net.WriteUInt(teamindex, 11)
            end
        end

        net.Send(ply)
    end)
elseif CLIENT then
    if rv_spawns then
        for i = #rv_spawns, 1, -1 do -- autorefresh
            if IsValid(rv_spawns[i]) then --
                rv_spawns[i]:Remove()
            end

            table.remove(rv_spawns, i)
        end
    end

    local color_red = Color(255, 0, 0)
    local color_blue = Color(0, 0, 255)
    local color_green = Color(0, 255, 0)
    net.Receive("rv_sendspawns", function(_, _)
        rv_spawns = {}
        local NumKeys = net.ReadUInt(7)
        for i = 1, NumKeys do
            local vec = net.ReadVector()
            local angs = net.ReadAngle()
            local hasteamindex = net.ReadBool()
            local teamindex = nil
            if hasteamindex == true then --
                teamindex = net.ReadUInt(11)
            end

            local csmodel = ClientsideModel("models/editor/playerstart.mdl")
            csmodel:SetPos(vec)
            csmodel:SetAngles(angs)
            csmodel:SetMaterial("debug/debugportals")
            csmodel.TeamIndex = teamindex
            rv_spawns[#rv_spawns + 1] = csmodel
        end
    end)

    local showspawns = true
    concommand.Add("rv_showspawns", function(ply, cmd, args)
        if showspawns == true then
            net.Start("rv_showspawns")
            net.SendToServer()
            hook.Add("Think", "rv_showspawns", function()
                if not rv_spawns then return end
                for _, spawn in ipairs(rv_spawns) do
                    if spawn.TeamIndex == LocalPlayer():Team() then
                        spawn:SetColor(color_green)
                    elseif IsSpawnUsable(LocalPlayer(), spawn) == true then
                        spawn:SetColor(color_blue)
                    else
                        spawn:SetColor(color_red)
                    end
                end
            end)
        else
            for i = #rv_spawns, 1, -1 do
                if IsValid(rv_spawns[i]) then --
                    rv_spawns[i]:Remove()
                end

                table.remove(rv_spawns, i)
            end

            hook.Remove("Think", "rv_showspawns")
        end

        showspawns = not showspawns
    end)
end
