hook.Add("InitPostEntity", "AutoRTVDelay", function()
    timer.Create("AutoRTV", 7200, 0, function() 
        if player.GetCountConnecting() + player.GetCount() == 0 then return end
        MapVote.Start()
    end)
end)

local LastNotifTime = 0
local RateLimit = 10
hook.Add("PlayerSay", "!NextRTV", function(sender, text, teamChat)
    if text == "!nextrtv" and CurTime() > LastNotifTime + RateLimit then
        LastNotifTime = CurTime()
        timer.Simple(0, function() --
            PrintMessage(HUD_PRINTTALK, "Next auto RTV in " .. math.Truncate(timer.TimeLeft("AutoRTV"), 0) .. " seconds.")
        end)
    end
end)

