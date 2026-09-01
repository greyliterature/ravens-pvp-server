if SERVER then
    util.AddNetworkString("CrossbowHits") -- We have to network this unfortunately.
    resource.AddWorkshop("3668437223")
    hook.Add("EntityTakeDamage", "NetworkCrossbowBoltHits", function(target, dmg)
        if not target:IsPlayer() then return end
        if not IsValid(dmg:GetInflictor()) then return end
        if dmg:GetInflictor():GetClass() == "crossbow_bolt" then
            net.Start("CrossbowHits")
            net.Send(dmg:GetAttacker())
        end
    end)
end

if CLIENT then
    local HitSoundsConvars = {
        ["EnableKillsounds"] = CreateClientConVar("rv_killsounds", "1", true, false, "Whether or not to play kill sounds."),
        ["EnableHitsounds"] = CreateClientConVar("rv_hitsounds", "1", true, false, "Whether or not to play hit sounds."),
        [HITGROUP_GENERIC] = CreateClientConVar("rv_hitsounds_bodyshot", "bfvbody_hit.wav", true, false),
        [HITGROUP_HEAD] = CreateClientConVar("rv_hitsounds_headshot", "bfvbodycritical_hit.wav", true, false, "This is relative to garrysmod/sound folder. Put your custom sound in sound/soundname.wav and set it to soundname.wav."),
        [HITGROUP_CHEST] = CreateClientConVar("rv_hitsounds_bodyshot", "bfvbody_hit.wav", true, false, "This is relative to garrysmod/sound folder. Put your custom sound in sound/soundname.wav and set it to soundname.wav."),
        [HITGROUP_STOMACH] = CreateClientConVar("rv_hitsounds_bodyshot", "bfvbody_hit.wav", true, false, "This is relative to garrysmod/sound folder. Put your custom sound in sound/soundname.wav and set it to soundname.wav."),
        [HITGROUP_LEFTARM] = CreateClientConVar("rv_hitsounds_armshot", "bfvbody_hit.wav", true, false, "This is relative to garrysmod/sound folder. Put your custom sound in sound/soundname.wav and set it to soundname.wav."),
        [HITGROUP_RIGHTARM] = CreateClientConVar("rv_hitsounds_armshot", "bfvbody_hit.wav", true, false, "This is relative to garrysmod/sound folder. Put your custom sound in sound/soundname.wav and set it to soundname.wav."),
        [HITGROUP_LEFTLEG] = CreateClientConVar("rv_hitsounds_legshot", "bfvbody_hit.wav", true, false, "This is relative to garrysmod/sound folder. Put your custom sound in sound/soundname.wav and set it to soundname.wav."),
        [HITGROUP_RIGHTLEG] = CreateClientConVar("rv_hitsounds_legshot", "bfvbody_hit.wav", true, false, "This is relative to garrysmod/sound folder. Put your custom sound in sound/soundname.wav and set it to soundname.wav."),
        [HITGROUP_GEAR] = CreateClientConVar("rv_hitsounds_bodyshot", "bfvbody_hit.wav", true, false, "This is relative to garrysmod/sound folder. Put your custom sound in sound/soundname.wav and set it to soundname.wav."),
        ["KILLSOUND"] = CreateClientConVar("rv_hitsounds_kill", "bfvbodycritical_kill.wav", true, false, "This is relative to garrysmod/sound folder. Put your custom sound in sound/soundname.wav and set it to soundname.wav."),
    }

    net.Receive("CrossbowHits", function(len, ply)
        if HitSoundsConvars["EnableHitsounds"]:GetBool() == false then return end
        surface.PlaySound(HitSoundsConvars[HITGROUP_GENERIC]:GetString()) -- All crossbow hits will be a bodyshot, use the bodyshot convar
    end)

    gameevent.Listen("entity_killed")
    hook.Add("entity_killed", "entity_killed_example", function(data)
        if data.entindex_attacker == data.entindex_killed then return end
        if data.entindex_attacker == LocalPlayer():EntIndex() and HitSoundsConvars["EnableKillsounds"]:GetBool() == true then surface.PlaySound(HitSoundsConvars["KILLSOUND"]:GetString()) end
    end)

    local LastShotTime = 0
    hook.Add("PostEntityFireBullets", "PlaySounds", function(ent, data)
        if not IsFirstTimePredicted() then return end
        if HitSoundsConvars["EnableHitsounds"]:GetBool() == false then return end
        timer.Simple(0, function()
            if LastShotTime == CurTime() then -- prevent multishot gun issues
                return
            end

            local HitGroup = data.Trace["HitGroup"]
            if not data.Trace["Entity"]:IsPlayer() then return end
            --local ShouldKillSound = data.Trace["Entity"]:Health() <= 0 and HitSoundsConvars["EnableKillsounds"]:GetBool() == true
            --surface.PlaySound((ShouldKillSound == false and HitSoundsConvars[HitGroup]:GetString()) or HitSoundsConvars["KILLSOUND"]:GetString())
            local EntAlive = (IsValid(data.Trace["Entity"]) and data.Trace["Entity"]:Health() > 0) or false
            if EntAlive == true then surface.PlaySound(HitSoundsConvars[HitGroup]:GetString()) end
            LastShotTime = CurTime()
        end)
    end)
end