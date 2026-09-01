if SERVER then
    util.AddNetworkString("startvoiceline")
    local VoiceLineRateLimit = 0.25
    local VoiceLinePlayers = {}
    net.Receive("startvoiceline", function(len, ply)
        VoiceLinePlayers[ply] = VoiceLinePlayers[ply] or 0
        if CurTime() < VoiceLinePlayers[ply] + VoiceLineRateLimit then return end
        if not ply:Alive() then return end
        VoiceLinePlayers[ply] = CurTime()
        local RequestedSound = net.ReadString()
        if ply.LastSound then
            ply:StopSound(ply.LastSound)
            ply.LastSound = nil
        end

        timer.Remove("SoundStopper" .. ply:Nick())
        ply:EmitSound(RequestedSound, 75, 100, 1, CHAN_AUTO)
        timer.Create("SoundStopper" .. ply:Nick(), SoundDuration(RequestedSound), 1, function()
            if ply.LastSound then --
                ply:StopSound(ply.LastSound)
                ply.LastSound = nil
            end
        end)

        ply.LastSound = RequestedSound
    end)

    hook.Add("PlayerDeath", "StopSoundsOnDeath", function(victim, inflictor, attacker)
        if victim.LastSound then
            victim:StopSound(victim.LastSound)
            return
        end
    end)
elseif CLIENT then
    concommand.Add("rv_voicetaunt", function(ply, cmd, args)
        if not args[1] then return end
        net.Start("startvoiceline")
        net.WriteString(args[1])
        net.SendToServer()
    end, nil, "Start a voicetaunt. Example: rv_voicetaunt  vo/npc/male01/question06.wav")
end