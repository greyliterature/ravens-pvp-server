if CLIENT then
    -- should add damage sparks like ql later.. maybe make it replace blood particle effect? probably easy 
    local function ExpDecay(a, b, decay, dt) -- thanks styled, https://github.com/StyledStrike/gmod-glide/blob/ccc66c0cf676d4332e6c5f4b3ac2dc9fb5488a2f/lua/glide/sh_utils.lua#L76
        return b + (a - b) * math.exp(-decay * dt)
    end

    local function easedLerp(fraction, from, to)
        return Lerp(math.ease.OutBounce(fraction), from, to)
    end

    local Damages = {}
    local DamageColor = Color(255, 0, 0, 255) -- make this overridable later
    hook.Add("HUDPaint", "rv_damageflyout", function()
        for _, tbl in pairs(Damages) do
            local StartTime = tbl[1]
            local HitPos = tbl[2]
            local weapclass = tbl[3]
            local damage = tbl[6]
            --local StartTime = tbl[3]
            local toscreen = HitPos:ToScreen()
            local x, y = toscreen.x, toscreen.y
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

    hook.Add("ScalePlayerDamage", "rv_damageflyout", function(ply, _, dmginfo)
        local Attacker = dmginfo:GetAttacker()
        if Attacker ~= LocalPlayer() then return end
        local HitPos = dmginfo:GetDamagePosition()
        local weapclass = dmginfo:GetWeapon():GetClass() -- can this be invalid?
        local Damage = dmginfo:GetDamage()
        print(Damage, "HIII")
        local xmultiple, ymultiple = RandomGravMultiple()
        Damages[#Damages + 1] = {CurTime(), HitPos, weapclass, xmultiple, ymultiple, Damage}
    end)

    net.Receive("rv_damageflyout", function(_, _)
        local DamagePosition = net.ReadVector()
        local Damage = net.ReadUInt(8)
        local weapclass = net.ReadString()
        local xmultiple, ymultiple = RandomGravMultiple()
        Damages[#Damages + 1] = {CurTime(), DamagePosition, weapclass, xmultiple, ymultiple, Damage}
    end)
elseif SERVER then
    -- will need to do networking for explosives somewhere here
    util.AddNetworkString("rv_damageflyout")
    hook.Add("ScalePlayerDamage", "rv_damageflyout", function(ply, _, dmginfo)
        local Attacker = dmginfo:GetAttacker()
        --if not Attackert:UserInfoNum()
        if not dmginfo:IsDamageType(DMG_BLAST) then return end
        local HitPos = dmginfo:GetDamagePosition()
        local weapclass = dmginfo:GetWeapon():GetClass() -- can this be invalid?
        local Damage = dmginfo:GetDamage()
        local tr = util.TraceLine({
            -- this is accurate enough, might not work in weird corners, but then id have to use some kind of weird multipoint magic, which i dont want to do anyway
            startpos = HitPos,
            endpos = ply:GetPos() + ply:OBBCenter(),
        })

        HitPos = tr.HitPos
        net.Start("rv_damageflyout")
        net.WriteVector(HitPos)
        net.WriteUInt(Damage, 8)
        net.WriteString(weapclass)
        net.Send(Attacker)
    end)
end
