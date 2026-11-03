-- Source - https://stackoverflow.com/a/39087852
-- Posted by Dmitrii Bychenko, modified by community. See post 'Timeline' for change history
-- Retrieved 2026-11-02, License - CC BY-SA 3.0
--proof:
--print(GetBitCount(4294967295))
--output: 32
local function GetBitCount(uint)
    return math.floor(math.log(uint, 2)) + 1
end

--[[

--]]
local SerializedWeapons = {}
local WeaponToSerial = {}
local MAX_WEAPON_BITS = nil
local i = 1
for weaponclass, _ in pairs(list.Get("Weapon")) do
    SerializedWeapons[#SerializedWeapons + 1] = weaponclass
    WeaponToSerial[weaponclass] = i
    i = i + 1
end

local BitFlag = {}
local WeaponToBitFlag = {} -- this apparently is a bitfield (i think), but i already named it this so whatever
i = 0
local bitgroup = 1
for _, weaponclass in ipairs(SerializedWeapons) do
    if i == 32 then
        i = 0
        bitgroup = bitgroup + 1
    end

    BitFlag[bitgroup] = BitFlag[bitgroup] or {}
    BitFlag[bitgroup][2 ^ i] = weaponclass
    WeaponToBitFlag[weaponclass] = {2 ^ i, bitgroup}
    i = i + 1
end

local MAX_WEAPON_BIT_GROUPS = bitgroup
local function WeaponClassToBitFlag(weaponclass)
    return WeaponToBitFlag[weaponclass][1], WeaponToBitFlag[weaponclass][2]
end

--PrintTable(WeaponToBitFlag)
MAX_WEAPON_BITS = GetBitCount(#SerializedWeapons)
--[[

--]]
if CLIENT then
    local MyLoadout = {
        ["weapon_357"] = true,
        ["weapon_pistol"] = true,
        ["weapon_rpg"] = true,
        ["weapon_slam"] = true,
        ["weapon_smg1"] = true,
        ["weapon_crossbow"] = true,
        ["weapon_frag"] = true,
        ["weapon_crowbar"] = true,
        ["weapon_ar2"] = true,
        ["weapon_physcannon"] = true,
        ["weapon_shotgun"] = true,
    }

    local function WriteReadNewLoadout(read)
        if not file.IsDir("ravens", "DATA") then file.CreateDir("ravens") end
        if not file.Exists("ravens/rv_loadout.txt", "DATA") then file.Write("ravens/rv_loadout.txt", util.TableToJSON(MyLoadout, true)) end
        if read == true then
            print("HIII")
            local content = file.Read("ravens/rv_loadout.txt", "DATA")
            MyLoadout = util.JSONToTable((content ~= "" and content) or MyLoadout)
        else
            file.Write("ravens/rv_loadout.txt", util.TableToJSON(MyLoadout, true))
        end
    end

    local function SendLoadoutInit()
        WriteReadNewLoadout(true)
        local Sums = {}
        for weaponclass, _ in pairs(MyLoadout) do
            local bitflag, bitGroup = WeaponClassToBitFlag(weaponclass)
            Sums[bitGroup] = Sums[bitGroup] or 0
            Sums[bitGroup] = Sums[bitGroup] + bitflag
        end

        --[[--]]
        PrintTable(MyLoadout)
        net.Start("SendLoadoutInit")
        for j = 1, MAX_WEAPON_BIT_GROUPS do
            net.WriteUInt(Sums[j], 32)
        end

        net.SendToServer()
    end
    --[[
    if CurTime() > 5 then -- autorefresh debugging
        timer.Simple(0, function() SendLoadoutInit() end)
    end
    --]]
    hook.Add("InitPostEntity", "SendLoadoutInit", SendLoadoutInit)
    local function SendLoadoutChange(classdelta)
        net.Start("LoadoutDelta")
        local deltaserial = WeaponToSerial[classdelta]
        net.WriteUInt(deltaserial, MAX_WEAPON_BITS)
        net.SendToServer()
    end

    local function RemoveFromLoadout(weaponclass)
        MyLoadout[weaponclass] = nil
        print(weaponclass, MyLoadout[weaponclass], "HEY")
        SendLoadoutChange(weaponclass)
        WriteReadNewLoadout()
    end

    local function AddToLoadout(weaponclass)
        MyLoadout[weaponclass] = true
        SendLoadoutChange(weaponclass)
        WriteReadNewLoadout()
    end

    local function IsInLoadout(weaponclass)
        return MyLoadout[weaponclass]
    end

    spawnmenu = spawnmenu or {} -- not sure if this is needed
    local vig = Material("vgui/white_additive_vignette")
    local color_addedtoloadout = Color(0, 255, 0, 60)
    if not spawnmenu.oldCreateContentIcon then spawnmenu.oldCreateContentIcon = spawnmenu.CreateContentIcon end
    local default_border = 3 -- https://github.com/Facepunch/garrysmod/blob/ad8023410600199ad9a12444bc496b9d65226a82/garrysmod/gamemodes/sandbox/gamemode/spawnmenu/creationmenu/content/contenticon.lua#L140
    local WeaponIcons = {}
    function spawnmenu.CreateContentIcon(type, panel, tbl)
        local newpanel = spawnmenu.oldCreateContentIcon(type, panel, tbl)
        if type == "weapon" then
            local spawnname = tbl.spawnname
            WeaponIcons[newpanel] = true
            function newpanel.PaintOver(_, w, h)
                if IsInLoadout(spawnname) ~= true then return end
                PrintTable(MyLoadout)
                surface.SetDrawColor(color_black)
                --surface.DrawRect(0, 0, w, h)
                surface.SetDrawColor(color_addedtoloadout)
                surface.SetMaterial(vig)
                surface.DrawTexturedRect(default_border, default_border, w - default_border * 2, h - default_border * 2)
                surface.DrawTexturedRectRotated(w * 0.5, h * 0.5, w - default_border * 2, h - default_border * 2, 90)
            end
        end
        return newpanel
    end

    hook.Add("SpawnmenuIconMenuOpen", "AddLoadoutOption", function(dmenu, icon, _)
        if not WeaponIcons[icon] then return end
        local spawnname = icon:GetSpawnName()
        local LoadoutFunc = (IsInLoadout(spawnname) == true and RemoveFromLoadout) or AddToLoadout
        local LoadoutText = (IsInLoadout(spawnname) == true and "Remove from loadout") or "Add to loadout"
        local newoption = dmenu:AddOption(LoadoutText, function()
            LoadoutFunc(spawnname)
            return
        end)

        newoption:SetIcon("icon16/bomb.png")
    end)
elseif SERVER then
    local PlayerLoadouts = {}
    util.AddNetworkString("LoadoutDelta")
    net.Receive("LoadoutDelta", function(len, ply)
        PlayerLoadouts[ply] = PlayerLoadouts[ply] or {}
        local deltaserial = net.ReadUInt(MAX_WEAPON_BITS)
        local deltaweapon = SerializedWeapons[deltaserial]
        local IsAlreadyInLoadout = PlayerLoadouts[ply][deltaweapon]
        PlayerLoadouts[ply][deltaweapon] = (IsAlreadyInLoadout == false and true) or nil -- remove if already in loadout, reduces networking
        PrintTable(PlayerLoadouts[ply])
        print(deltaweapon)
    end)

    local DefaultLoadout = {
        ["weapon_357"] = true,
        ["weapon_pistol"] = true,
        ["weapon_rpg"] = true,
        ["weapon_slam"] = true,
        ["weapon_smg1"] = true,
        ["weapon_crossbow"] = true,
        ["weapon_frag"] = true,
        ["weapon_crowbar"] = true,
        ["weapon_ar2"] = true,
        ["weapon_physcannon"] = true,
        ["weapon_shotgun"] = true,
    }

    for _, ply in player.Iterator() do
        PlayerLoadouts[ply] = PlayerLoadouts[ply] or {}
        for weaponclass, _ in pairs(DefaultLoadout) do
            PlayerLoadouts[ply][weaponclass] = true
        end
    end

    -- setmodel is good enough, i have other playerloadout hooks that are too important to remove
    hook.Add("PlayerSetModel", "GiveCustomLoadout", function(ply, _)
        print("HII")
        ply:StripWeapons()
        local Loadout = PlayerLoadouts[ply] or DefaultLoadout
        PrintTable(Loadout)
        print("Yo")
        for weapon, _ in pairs(Loadout) do
            if IsClassBlacklisted(ply, weapon) then continue end
            ply:Give(weapon)
        end
    end)

    local LoadoutDataExpected = {}
    hook.Add("PlayerInitialSpawn", "QueueLoadout", function(ply, _)
        LoadoutDataExpected[ply] = true
        return
    end)

    local function BitFlagToWeaponClass(bitGroup, bitflag)
        --print(bitGroup, bitflag, "HIIII")
        return BitFlag[bitGroup][2 ^ bitflag]
    end

    local function WeaponBitFlagToTable(bitGroup, bitflag)
        local Weapons = {}
        for index = 0, 31 do
            local flag = bit.lshift(1, index)
            if bit.band(flag, bitflag) ~= 0 then --
                Weapons[#Weapons + 1] = BitFlagToWeaponClass(bitGroup, index)
            end
        end
        return Weapons
    end

    util.AddNetworkString("SendLoadoutInit")
    net.Receive("SendLoadoutInit", function(len, ply)
        if not LoadoutDataExpected[ply] then -- ban!
            return
        end

        local Weapons = {}
        LoadoutDataExpected[ply] = nil
        local Sums = {}
        for j = 1, MAX_WEAPON_BIT_GROUPS do
            Sums[j] = net.ReadUInt(32)
            Weapons[#Weapons + 1] = WeaponBitFlagToTable(j, Sums[j])
        end

        --[[--]]
        ply:StripWeapons()
        for _, weapontbl in ipairs(Weapons) do
            for _, weaponclass in ipairs(weapontbl) do
                ply:Give(weaponclass)
            end
        end

        PrintTable(Sums)
    end)

    net.Receive("InitLoadoutData", function(len, ply) end)
    print(MAX_WEAPON_BITS)
end
