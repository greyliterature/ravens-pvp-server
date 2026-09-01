local BadClasses = {
    ["weapon_rpg"] = true,
    ["weapon_frag"] = true,
    ["weapon_medkit"] = true,
    ["weapon_slam"] = true,
    ["gmod_tool"] = true,
    ["item_ammo_smg1_grenade"] = true,
    ["item_rpg_round"] = true,
    ["item_healthkit"] = true,
    ["item_healthvial"] = true,
    ["item_battery"] = true,
    ["weapon_nyangun"] = true,
    ["models/props_phx/torpedo.mdl"] = true,
    ["models/props_phx/ww2bomb.mdl"] = true,
    ["models/props_phx/mk-82.mdl"] = true,
    ["models/props_phx/amraam.mdl"] = true,
    ["models/props_phx/misc/flakshell_big.mdl"] = true,
    ["models/props_phx/ball.mdl"] = true,
    ["models/props_phx/cannonball.mdl"] = true,
    ["models/props_phx/cannonball_solid.mdl"] = true,
    ["models/props_phx/misc/potato_launcher_explosive.mdl"] = true,
    ["models/props_c17/oildrum001_explosive.mdl"] = true,
    ["models/props_phx/oildrum001_explosive.mdl"] = true,
    ["models/props_phx/oildrum001_explosive.mdl"] = true,
    ["models/props_junk/gascan001a.mdl"] = true,
    ["models/props_explosive/explosive_butane_can.mdl"] = true,
    ["models/props_explosive/explosive_butane_can02.mdl"] = true,
}

local function IsClassBlacklisted(classname)
    return BadClasses[classname]
end

if SERVER then
    util.AddNetworkString("UpdateClassBlacklistTable")
    local function UpdateClassBlacklistTable(classname, nowblacklisted)
        net.Start("UpdateClassBlacklistTable")
        net.WriteString(classname)
        net.WriteBool(nowblacklisted == true)
        net.Broadcast()
    end

    local function AddClassToBlacklist(classname)
        UpdateClassBlacklistTable(classname, true)
        BadClasses[classname] = true
    end

    concommand.Add("blacklistclass", function(ply, cmd, args, argstr)
        if IsValid(ply) and not ply:IsSuperAdmin() then return end
        local classname = args[1]
        if not classname then return end
        AddClassToBlacklist(classname)
        PrintMessage(HUD_PRINTTALK, "Blacklisted " .. classname .. ".")
        print("Blacklisted " .. classname .. ".")
    end)

    local function RemoveClassFromBlacklist(classname)
        UpdateClassBlacklistTable(classname, false)
        BadClasses[classname] = nil
    end

    concommand.Add("unblacklistclass", function(ply, cmd, args, argstr)
        if IsValid(ply) and not ply:IsSuperAdmin() then return end
        local classname = args[1]
        if not classname then return end
        RemoveClassFromBlacklist(classname)
        PrintMessage("Unblacklisted " .. classname .. ".")
        print("Unblacklisted " .. classname .. ".")
    end)

    util.AddNetworkString("InitClassBlacklistTable")
    local load_queue = {}
    hook.Add("PlayerInitialSpawn", "ClassBlacklistLoadQueue", function(ply)
        load_queue[ply] = true
        return
    end)

    hook.Add("StartCommand", "ClassBlacklistLoadQueue", function(ply, cmd)
        if load_queue[ply] and not cmd:IsForced() then
            load_queue[ply] = nil
            net.Start("InitClassBlacklistTable")
            local numkeys = table.Count(BadClasses)
            net.WriteUInt(numkeys, 8)
            for classname, _ in pairs(BadClasses) do
                net.WriteString(classname)
            end

            net.Send(ply)
        end
    end)

    --[[--------------------------------
        Blacklist hooks
    ----------------------------------]]
    hook.Add("PlayerSpawnProp", "ClassBlacklists", function(ply, model)
        if IsClassBlacklisted(model) then --
            return false
        end
    end)

    hook.Add("PlayerSpawnEffect", "ClassBlacklists", function(ply, model)
        if IsClassBlacklisted(model) then --
            return false
        end
    end)

    hook.Add("PlayerSpawnNPC", "ClassBlacklists", function(ply, class)
        if IsClassBlacklisted(class) then --
            return false
        end
    end)

    hook.Add("PlayerSpawnRagdoll", "ClassBlacklists", function(ply, model)
        if IsClassBlacklisted(model) then --
            return false
        end
    end)

    hook.Add("PlayerSpawnSENT", "ClassBlacklists", function(ply, class)
        if IsClassBlacklisted(class) then --
            return false
        end
    end)

    hook.Add("PlayerSpawnSWEP", "ClassBlacklists", function(ply, weapon, sweptbl)
        if IsClassBlacklisted(weapon) or sweptbl.Spawnable == false or sweptbl.AdminOnly == true then -- 
            return false
        end
    end)

    hook.Add("PlayerSpawnVehicle", "ClassBlacklists", function(ply, model, name, tbl)
        if IsClassBlacklisted(model) then -- 
            return false
        end
    end)

    hook.Add("PlayerGiveSWEP", "ClassBlacklists", function(ply, weapon, spawninfotbl)
        if IsClassBlacklisted(weapon) or spawninfotbl.Spawnable == false or spawninfotbl.AdminOnly == true then -- 
            return false
        end
    end)

    local function GetListTable(category, class)
        return list.Get(category)[class]
    end

    hook.Add("PlayerCanPickupWeapon", "ClassBlacklists", function(ply, weapon)
        local weapontable = GetListTable("Weapon", weapon:GetClass())
        if IsClassBlacklisted(weapon) or (weapontable and weapontable.Spawnable == false or weapontable.AdminOnly == true) then -- 
            return false
        end
    end)

    hook.Add("PlayerCanPickupItem", "ClassBlacklists", function(ply, item)
        local itemtable = GetListTable("SpawnableEntities", item:GetClass())
        if IsClassBlacklisted(item) or (itemtable and itemtable.Spawnable == false or itemtable.AdminOnly == true) then -- 
            return false
        end
    end)

    hook.Add("WeaponEquip", "ClassBlacklists", function(weapon, ply)
        if IsClassBlacklisted(weapon:GetClass()) then --
            weapon:Remove()
        end
    end)
elseif CLIENT then
    net.Receive("InitClassBlacklistTable", function(_, _)
        local numkeys = net.ReadUInt(8)
        for i = 1, numkeys do
            local classname = net.ReadString
            BadClasses[classname] = true
        end
    end)

    net.Receive("UpdateClassBlacklistTable", function(_, _)
        local classname = net.ReadString()
        local nowblacklisted = net.ReadBool()
        BadClasses[classname] = (nowblacklisted == true) or nil
    end)

    if not spawnmenu.oldCreateContentIcon then spawnmenu.oldCreateContentIcon = spawnmenu.CreateContentIcon end
    function spawnmenu.CreateContentIcon(...)
        local args = {...}
        local spawnname = nil
        if args[3] and args[3]["spawnname"] then --
            spawnname = args[3]["spawnname"]
        end

        if IsClassBlacklisted(spawnname) then --
            return
        end

        spawnmenu.oldCreateContentIcon(unpack(args))
    end

    local PANELMETA = FindMetaTable("Panel")
    if not oldSetModel then oldSetModel = PANELMETA.SetModel end
    function PANELMETA:SetModel(modelpath, skin, bodygroups)
        if IsClassBlacklisted(modelpath) then
            self:GetParent():Remove()
            return
        end

        oldSetModel(self, modelpath, skin, bodygroups)
    end
end
