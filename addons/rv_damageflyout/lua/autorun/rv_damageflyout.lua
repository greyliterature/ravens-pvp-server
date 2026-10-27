if CLIENT then
    -- should add damage sparks like ql later.. maybe make it replace blood particle effect? probably easy 
    local function ExpDecay(a, b, decay, dt) -- thanks styled, https://github.com/StyledStrike/gmod-glide/blob/ccc66c0cf676d4332e6c5f4b3ac2dc9fb5488a2f/lua/glide/sh_utils.lua#L76
        return b + (a - b) * math.exp(-decay * dt)
    end

    local function easedLerp(fraction, from, to)
        return Lerp(math.ease.OutBounce(fraction), from, to)
    end

    -- Custimoization table
    local Settings = {
        ["weapon_smg1"] = {
            color = Color(255, 0, 0),
        },
        ["weapon_357"] = {
            color = Color(176, 0, 47)
        },
        ["weapon_9mm"] = {
            color = Color(0, 255, 0)
        },
        ["weapon_smg1"] = {
            color = Color(0, 255, 255)
        },
        ["weapon_crossbow"] = {
            color = Color(255, 140, 0)
        },
        ["weapon_crowbar"] = {
            color = Color(255, 255, 0)
        },
        ["weapon_stunstick"] = {
            color = Color(0, 255, 255)
        },
        ["weapon_ar2"] = {
            color = Color(0, 0, 255)
        },
        ["weapon_shotgun"] = {
            color = Color(140, 0, 0)
        },
    }

    if not file.IsDir("ravens", "DATA") then file.CreateDir("ravens") end
    if not file.Exists("ravens/rv_damageflyouts.txt", "DATA") then
        file.Write("ravens/rv_damageflyouts.txt", util.TableToJSON(Settings, true))
    else
        Settings = util.JSONToTable(file.Read("ravens/rv_damageflyouts.txt", "DATA"))
    end

    --
    local Damages = {}
    local DefaultDamageColor = Color(255, 0, 0, 255) -- make this overridable later
    local ConVars = {
        ["rv_damageflyouts_font"] = CreateClientConVar("rv_damageflyouts_font", "255 0 0 255", true, false, "Color of damage flyout"),
        ["rv_damageflyouts_color"] = CreateClientConVar("rv_damageflyouts_color", "255 0 0 255", true, false, "Color of default damage flyout"),
        ["rv_damageflyouts_enabled"] = CreateClientConVar("rv_damageflyouts_enabled", "1", true, true, "", 0, 1),
        ["rv_damageflyouts_size"] = CreateClientConVar("rv_damageflyouts_size", "26", true, false, ""),
    }

    for ConVarName, ConVarObj in pairs(ConVars) do
        local str = ConVarObj:GetString()
        if ConVarName == "rv_damageflyouts_color" then --
            str = string.ToColor(str)
        end

        ConVars[ConVarName] = {ConVarObj, str}
        cvars.AddChangeCallback(ConVarName, function(convar, old, new)
            if convar == "rv_damageflyouts_color" then --
                new = string.ToColor(new)
            end

            ConVars[ConVarName][2] = new
            return
        end, ConVarName)
    end

    hook.Add("HUDPaint", "rv_damageflyout", function()
        if ConVars["rv_damageflyouts_enabled"][2] ~= "1" then return end
        for _, tbl in pairs(Damages) do
            local StartTime = tbl[1]
            local HitPos = tbl[2]
            local weapclass = tbl[3]
            local damage = tbl[6]
            --local StartTime = tbl[3]
            local toscreen = HitPos:ToScreen()
            local x, y = toscreen.x, toscreen.y
            local DamageColor = DefaultDamageColor
            DamageColor = (Settings[weapclass] and Settings[weapclass]["color"]) or DamageColor
            local NewAlpha = ExpDecay((tbl[7] and tbl[7].a) or DamageColor.a, 0, 2, FrameTime())
            local DamageColorAlphaed = ColorAlpha(DamageColor, NewAlpha)
            tbl[7] = DamageColorAlphaed
            local Duration = 2
            local Decayed = math.Clamp((CurTime() - StartTime) / Duration, 0, 1)
            local xmultiple, ymultiple = tbl[4], tbl[5]
            x, y = x + Decayed * xmultiple, y - (Decayed * 2 - 1) ^ 2 * -ymultiple - ymultiple
            draw.SimpleText(damage, "ChatFont", x, y, DamageColorAlphaed, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end)

    local function RandomGravMultiple()
        local xmultiple = math.random(-100, 100)
        local ymultiple = math.random(50, 100)
        return xmultiple, ymultiple
    end

    net.Receive("rv_damageflyout", function(_, _)
        local DamagePosition = net.ReadVector()
        local Damage = net.ReadUInt(8)
        local weapclass = net.ReadString()
        local xmultiple, ymultiple = RandomGravMultiple()
        Damages[#Damages + 1] = {CurTime(), DamagePosition, weapclass, xmultiple, ymultiple, Damage}
    end)

    local HitGroups = {}
    net.Receive("NetworkHitGroupDamage", function(_, _)
        print("REC")
        for hitgroup = HITGROUP_GENERIC, HITGROUP_RIGHTLEG do
            print(type(hitgroup), "HI")
            HitGroups[hitgroup] = net.ReadFloat()
        end

        HitGroups[HITGROUP_GEAR] = net.ReadFloat() -- theres a break for some reason
        PrintTable(HitGroups)
    end)

    timer.Create("ddd", 3, 0, function() print(HitGroups[1]) end)
    hook.Add("ScalePlayerDamage", "rv_damageflyout", function(ply, hitgroup, dmginfo)
        local Attacker = dmginfo:GetAttacker()
        if Attacker ~= LocalPlayer() then return end
        local HitPos = dmginfo:GetDamagePosition()
        local weapclass = dmginfo:GetWeapon():GetClass() -- can this be invalid?
        local Damage = dmginfo:GetDamage() * (HitGroups[hitgroup] or 1)
        print("HEYYY")
        PrintTable(HitGroups)
        print(dmginfo:GetDamage(), type(hitgroup), hitgroup, HitGroups[hitgroup])
        local xmultiple, ymultiple = RandomGravMultiple()
        Damages[#Damages + 1] = {CurTime(), HitPos, weapclass, xmultiple, ymultiple, Damage}
    end)
elseif SERVER then
    -- networking for explosives / bolt
    util.AddNetworkString("rv_damageflyout")
    hook.Add("ScalePlayerDamage", "rv_damageflyout", function(ply, _, dmginfo)
        local Attacker = dmginfo:GetAttacker()
        if Attacker:GetInfo("rv_damageflyouts_enabled") ~= "1" then return end
        if dmginfo:IsDamageType(DMG_BULLET) then -- we only network non bullets, bullets are already handled clientside
            return
        end

        local HitPos = ply:GetPos()
        local weap = dmginfo:GetWeapon()
        local weapclass = nil
        if IsValid(weap) then
            weapclass = weap:GetClass() -- can this be invalid? edit: yes it can be
        end

        local Damage = dmginfo:GetDamage()
        net.Start("rv_damageflyout")
        net.WriteVector(HitPos)
        net.WriteUInt(Damage, 8)
        net.WriteString(weapclass or "")
        net.Send(Attacker)
    end)

    local HitGroups = {}
    --[[
        HITGROUP_GENERIC, 
        HITGROUP_HEAD,
        HITGROUP_CHEST,
        HITGROUP_STOMACH,
        HITGROUP_LEFTARM,
        HITGROUP_RIGHTARM,
        HITGROUP_LEFTLEG,
        HITGROUP_RIGHTLEG,
        HITGROUP_GEAR

    --]]
    local RandomPlayer = nil
    local function GetDamageNumbers(ply)
        if not ply then
            for _, plyy in player.Iterator() do
                if plyy:IsBot() == true then continue end
                RandomPlayer = plyy
                break
            end
        else
            RandomPlayer = ply
        end

        HitGroups = {}
        local dmginfo = DamageInfo()
        dmginfo:SetAttacker(RandomPlayer)
        dmginfo:SetDamageType(DMG_BULLET)
        for hitgroup = HITGROUP_GENERIC, HITGROUP_RIGHTLEG do
            dmginfo:SetDamage(1)
            hook.Run("ScalePlayerDamage", RandomPlayer, hitgroup, dmginfo)
            local DamageAfter = dmginfo:GetDamage()
            HitGroups[hitgroup] = DamageAfter
        end

        local hitgroup = HITGROUP_GEAR
        dmginfo:SetDamage(1)
        hook.Run("ScalePlayerDamage", RandomPlayer, hitgroup, dmginfo)
        local DamageAfter = dmginfo:GetDamage()
        HitGroups[hitgroup] = DamageAfter
    end

    hook.Add("PlayerInitialSpawn", "NetworkHitGroupDamage", function(ply, _)
        --GetDamageNumbers(ply)
        --
        hook.Remove("PlayerInitialSpawn", "NetworkHitGroupDamage")
    end)

    util.AddNetworkString("NetworkHitGroupDamage")
    local function NetworkHitGroupDamage(ply)
        print("called")
        net.Start("NetworkHitGroupDamage")
        --local NumHitGroups = net.WriteUInt(9, 4)
        for hit_group = HITGROUP_GENERIC, HITGROUP_RIGHTLEG do
            net.WriteFloat(HitGroups[hit_group])
        end

        local hit_group = HITGROUP_GEAR
        net.WriteFloat(HitGroups[hit_group])
        if ply then
            net.Send(ply)
        else
            print("broadcast")
            net.Broadcast()
        end
    end

    if CurTime() > 15 then -- autorefresh
        GetDamageNumbers()
        timer.Simple(0, function() -- this timer is ridiculous
            NetworkHitGroupDamage()
        end)
    end

    hook.Add("InitPostEntityStarted", "NetworkHitGroupDamage", function(ply)
        GetDamageNumbers(ply)
        NetworkHitGroupDamage(ply)
    end)
end
