local JoinColor = Color(161, 255, 161, 255)
if CLIENT then
    CreateClientConVar("rv_joinsound_enable", 0, true, false, "Whether or not to play a sound when someone spawns into the server.", 0, 1)
    CreateClientConVar("rv_joinsound_flash", 0, true, false, "Whether or not to flash the Gmod icon when someone spawns into the server.", 0, 1)
    CreateClientConVar("rv_joinsound", "garrysmod/balloon_pop_cute.wav", true, false, "The sound to play when someone spawns.")
    hook.Add("ChatText", "SuppressJoinLeave", function(index, name, text, type)
        if type == "joinleave" then -- 
            return true
        end
    end)
end

gameevent.Listen("player_activate")
hook.Add("player_activate", "SpawnMessage", function(data)
    if SERVER then
        ColoredChatPrint({JoinColor, "Player " .. Player(data.userid):Nick() .. " has spawned " .. "( " .. Player(data.userid):SteamID() .. " )"})
        MsgC(JoinColor, "Player " .. Player(data.userid):Nick() .. " has spawned " .. "( " .. Player(data.userid):SteamID() .. " )\n")
    elseif CLIENT then
        if GetConVar("rv_joinsound_enable"):GetBool() == true then --
            surface.PlaySound(GetConVar("rv_joinsound"):GetString())
            if GetConVar("rv_joinsound_flash"):GetBool() == true and not system.HasFocus() then -- 
                system.FlashWindow()
            end
        end
    end
end)

if SERVER then
    gameevent.Listen("player_connect")
    hook.Add("player_connect", "ConnectMessage", function(data)
        MsgC(JoinColor, "Player " .. data.name .. " has joined the game " .. "( " .. data.networkid .. " )\n")
        ColoredChatPrint({JoinColor, "Player " .. data.name .. " has joined the game " .. "( " .. data.networkid .. " )"})
    end)

    gameevent.Listen("player_disconnect")
    hook.Add("player_disconnect", "DisconnectMessage", function(data)
        MsgC(JoinColor, "Player " .. data.name .. " left the game " .. "(" .. "[ " .. data.networkid .. " ] " .. data.reason .. ")" .. "\n")
        ColoredChatPrint({JoinColor, "Player " .. data.name .. " left the game " .. "(" .. "[ " .. data.networkid .. " ] " .. data.reason .. ")"})
        --Player Bot19 left the game (Kicked from server)
    end)
end
