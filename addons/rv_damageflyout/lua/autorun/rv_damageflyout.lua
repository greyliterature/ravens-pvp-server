if CLIENT then
    -- should add damage sparks like ql later.. maybe make it replace blood particle effect? probably easy 
    local function ExpDecay(a, b, decay, dt) -- thanks styled, https://github.com/StyledStrike/gmod-glide/blob/ccc66c0cf676d4332e6c5f4b3ac2dc9fb5488a2f/lua/glide/sh_utils.lua#L76
        return b + (a - b) * math.exp(-decay * dt)
    end

    --[[
    local function easedLerp(fraction, from, to)
        return Lerp(math.ease.OutBounce(fraction), from, to)
    end
    --]]
    -- Custimoization table
    local Settings = {
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
            color = Color(218, 0, 0)
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
        ["rv_damageflyouts_font"] = CreateClientConVar("rv_damageflyouts_font", "ChatFont", true, false, "Damage flyout font"),
        ["rv_damageflyouts_color"] = CreateClientConVar("rv_damageflyouts_color", "255 0 0 255", true, false, "Color of default damage flyout"),
        ["rv_damageflyouts_enabled"] = CreateClientConVar("rv_damageflyouts_enabled", "1", true, true, "", 0, 1),
        ["rv_damageflyouts_size"] = CreateClientConVar("rv_damageflyouts_size", "26", true, false, "Damage flyout size"),
        ["rv_damageflyouts_combine_shotgun"] = CreateClientConVar("rv_damageflyouts_combine_shotgun", "1", true, false, "Combine shotgun damage numbers"),
        ["rv_damageflyouts_fadespeed"] = CreateClientConVar("rv_damageflyouts_fadespeed", "2", true, false, "Damage flyout fade speed, sort of broken, remind me to fix this later"),
    }

    local function UpdateFlyoutFont(fontname, fontsize)
        surface.CreateFont("rv_damageflyoutfont", {
            font = fontname,
            extended = false,
            size = tonumber(fontsize),
            weight = 500,
            blursize = 0,
            scanlines = 0,
            antialias = true,
            underline = false,
            italic = false,
            strikeout = false,
            symbol = false,
            rotary = false,
            shadow = false,
            additive = false,
            outline = false,
        })
    end

    concommand.Add("rv_damageflyouts_refreshfont", function(_, _, _, _)
        local fontname = ConVars["rv_damageflyouts_font"][2]
        local fontsize = ConVars["rv_damageflyouts_size"][2]
        UpdateFlyoutFont(fontname, fontsize)
        return
    end, nil, "Recreate font")

    for ConVarName, ConVarObj in pairs(ConVars) do
        local str = ConVarObj:GetString()
        if ConVarName == "rv_damageflyouts_color" then --
            str = string.ToColor(str)
        elseif ConVarName == "rv_damageflyouts_fadespeed" then
            str = tonumber(str)
        end

        ConVars[ConVarName] = {ConVarObj, str}
        cvars.AddChangeCallback(ConVarName, function(convar, _, new)
            if convar == "rv_damageflyouts_color" then --
                new = string.ToColor(new)
            elseif convar == "rv_damageflyouts_fadespeed" then
                new = tonumber(str)
            end

            ConVars[ConVarName][2] = new
            return
        end, ConVarName)
    end

    local DefaultFonts = {
        BudgetLabel = true,
        CenterPrintText = true,
        ChatFont = true,
        CloseCaption_Bold = true,
        CloseCaption_BoldItalic = true,
        CloseCaption_Italic = true,
        CloseCaption_Normal = true,
        CreditsOutroText = true,
        CreditsText = true,
        DebugFixed = true,
        DebugFixedSmall = true,
        DebugOverlay = true,
        Default = true,
        DefaultFixed = true,
        DefaultFixedDropShadow = true,
        DefaultSmall = true,
        DefaultUnderline = true,
        DefaultVerySmall = true,
        HudDefault = true,
        HudHintTextLarge = true,
        HudHintTextSmall = true,
        HudSelectionNumbers = true,
        HudSelectionText = true,
        TargetID = true,
        TargetIDSmall = true,
        Trebuchet18 = true,
        Trebuchet24 = true,
    }

    hook.Add("HUDPaint", "rv_damageflyout", function()
        if ConVars["rv_damageflyouts_enabled"][2] ~= "1" then return end
        for index, tbl in pairs(Damages) do
            local StartTime = tbl[1]
            local HitPos = tbl[2]
            local weapclass = tbl[3]
            local damage = tbl[6]
            --local StartTime = tbl[3]
            local toscreen = HitPos:ToScreen()
            local x, y = toscreen.x, toscreen.y
            local DamageColor = DefaultDamageColor
            DamageColor = (Settings[weapclass] and Settings[weapclass]["color"]) or DamageColor
            local NewAlpha = ExpDecay((tbl[7] and tbl[7].a) or DamageColor.a, 0, ConVars["rv_damageflyouts_fadespeed"][2], FrameTime())
            local DamageColorAlphaed = ColorAlpha(DamageColor, NewAlpha)
            tbl[7] = DamageColorAlphaed
            local Duration = 0.5
            local Decayed = math.Clamp((CurTime() - StartTime) / Duration, 0, 1)
            local xmultiple, ymultiple = tbl[4], tbl[5]
            x, y = x + Decayed * xmultiple, y - (Decayed - 1) ^ 2 * -ymultiple - ymultiple
            if Decayed >= 1 then -- it should never be more than 1, but just in case
                Damages[index] = nil
            end

            draw.SimpleText(damage, (DefaultFonts[ConVars["rv_damageflyouts_font"][2]] and ConVars["rv_damageflyouts_font"][2]) or "rv_damageflyoutfont", x, y, DamageColorAlphaed, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
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
        for hitgroup = HITGROUP_GENERIC, HITGROUP_RIGHTLEG do
            HitGroups[hitgroup] = net.ReadFloat()
        end

        HitGroups[HITGROUP_GEAR] = net.ReadFloat() -- theres a break for some reason
    end)

    local CollectionDamage = 0
    local PelletCount = 0
    local LastHit = nil
    local FirstTrace = nil
    local Shots = {}
    hook.Add("ScalePlayerDamage", "rv_damageflyout", function(ply, hitgroup, dmginfo)
        if not IsFirstTimePredicted() then return end
        local Attacker = dmginfo:GetAttacker()
        local localply = LocalPlayer()
        if Attacker ~= localply then return end
        local HitPos = dmginfo:GetDamagePosition()
        local weapclass = dmginfo:GetWeapon():GetClass() -- can this be invalid?
        local Damage = dmginfo:GetDamage() * (HitGroups[hitgroup] or 1)
        local xmultiple, ymultiple = RandomGravMultiple()
        if ConVars["rv_damageflyouts_combine_shotgun"][2] == "1" then
            CollectionDamage = CollectionDamage + Damage
            if LastHit == CurTime() then PelletCount = PelletCount + 1 end
            if PelletCount == 0 then --
                local shootpos = localply:GetShootPos()
                FirstTrace = util.TraceLine({
                    start = shootpos,
                    endpos = shootpos + localply:GetAimVector() * 5000,
                    filter = localply
                }).HitPos
            end

            Shots[CurTime()] = {CurTime(), PelletCount > 1 and FirstTrace or HitPos, weapclass, xmultiple, ymultiple, math.Truncate(CollectionDamage, 2)}
            if PelletCount == 0 and Shots[LastHit] then
                Damages[#Damages + 1] = Shots[LastHit]
                return
            end

            timer.Simple(0, function()
                if CollectionDamage == 0 then -- works well enough
                    return
                end

                Damages[#Damages + 1] = Shots[LastHit]
                Shots[LastHit] = nil
                CollectionDamage = 0
                PelletCount = 0
            end)
        else
            Damages[#Damages + 1] = {CurTime(), HitPos, weapclass, xmultiple, ymultiple, Damage}
        end

        LastHit = CurTime()
    end)
elseif SERVER then
    -- networking for explosives / bolt
    util.AddNetworkString("rv_damageflyout")
    hook.Add("ScalePlayerDamage", "rv_damageflyout", function(ply, _, dmginfo)
        local Attacker = dmginfo:GetAttacker()
        local weap = dmginfo:GetWeapon()
        local weapclass = nil
        if IsValid(weap) then
            weapclass = weap:GetClass() -- can this be invalid? edit: yes it can be
        end

        if Attacker:GetInfo("rv_damageflyouts_enabled") ~= "1" then return end
        if dmginfo:IsDamageType(DMG_BULLET) and weapclass ~= "weapon_crossbow" then
            -- we only network non bullets, bullets are already handled clientside
            -- the crossbow also apparently does bullet damage, so we have to check that too
            return
        end

        local HitPos = ply:GetPos() + ply:OBBCenter()
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
            net.Broadcast()
        end
    end

    if CurTime() > 15 then -- autorefresh
        GetDamageNumbers()
        timer.Simple(0, function()
            -- this timer is ridiculous
            NetworkHitGroupDamage()
        end)
    end

    hook.Add("InitPostEntityStarted", "NetworkHitGroupDamage", function(ply)
        GetDamageNumbers(ply)
        NetworkHitGroupDamage(ply)
    end)
end
