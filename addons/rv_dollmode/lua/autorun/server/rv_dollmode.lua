hook.Add("ULibUserGroupChange", "RespawnOnDollModeAdd", function(id, allows, denies, new_group, old_group)
    if not IsValid(player.GetBySteamID(id)) then return end
    if new_group == "DOLLMODE" then
        player.GetBySteamID(id).DollModer = true
        if IsValid(player.GetBySteamID(id)) then player.GetBySteamID(id):Spawn() end
    end

    if old_group == "DOLLMODE" and new_group ~= "DOLLMODE" then --
        player.GetBySteamID(id).DollModer = nil
        player.GetBySteamID(id):Spawn()
    end
end)

hook.Add("ULibUserRemoved", "RemoveDollModer", function(id, user_info)
    for _, ply in player.Iterator() do -- wow this is annoying
        if user_info["name"] == ply:Nick() then
            ply.DollModer = nil
            ply:Spawn()
        end
    end
end)

hook.Add("PlayerInitialSpawn", "SetDollModeOnSpawn", function(ply, trans)
    if ply:GetUserGroup() == "DOLLMODE" then -- 
        ply.DollModer = true
    end
end)

hook.Add("PlayerSpawn", "SetDollModel", function(ply)
    ply:SetCustomCollisionCheck(true)
    if not ply.DollModer then return end
    timer.Simple(0, function()
        if ply:GetUserGroup() ~= "DOLLMODE" then ply.DollModer = nil end
        ply:SetModel("models/maxofs2d/companion_doll.mdl")
    end)
    return true -- todo: is this return necessary? no internet right now to check what it does
end)

hook.Add("ScalePlayerDamage", "NoDollModerDamage", function(ply, hitgroup, dmginfo)
    if dmginfo:GetAttacker().DollModer and not ply.DollModer then
        dmginfo:SetDamage(0)
        return true
    end
end)

hook.Add("PlayerSay", "DollModeMute", function(sender, text, teamChat)
    if sender.DollModer and not sender.LastSayTime then sender.LastSayTime = CurTime() end
    if sender.DollModer and CurTime() > sender.LastSayTime + 3 then
        sender.LastSayTime = CurTime()
        print(sender:Nick() .. " tried saying: " .. text)
        return "I was put in DOLLMODE and all I got was this LOUSY chatmessage!"
    elseif sender.DollModer and CurTime() < sender.LastSayTime + 3 then
        sender:ChatPrint("Please wait before sending another message NOOB")
        return ""
    end
end)

hook.Add("PlayerSpray", "NoDollmoderSprays", function(ply) if ply:GetUserGroup() == "DOLLMODE" then return true end end)