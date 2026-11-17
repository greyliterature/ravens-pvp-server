local ENV = include("rv_env/sv_rv_env.lua")
local ADMIN_LOGS_WEBHOOK = ENV.ADMIN_LOGS_WEBHOOK
local JSON = {
    ["content"] = null,
    ["embeds"] = {
        {
            ["description"] = "HI",
            ["color"] = 5814783,
        }
    },
    ["username"] = "Isaac Kleiner",
    ["attachments"] = {}
}

hook.Add("ULibPlayerBanned", "BanLogs", function(steamid, ban_data)
    PrintTable(ban_data)
    if not ban_data.modified_admin then
        JSON["embeds"][1]["description"] = ban_data.admin .. " banned " .. ban_data.steamID .. " for " .. string.NiceTime(ban_data.time) .. " because " .. (ban_data.reason or "")
    else
        JSON["embeds"][1]["description"] = ban_data.modified_admin .. " changed ban for " .. ban_data.steamID .. " to " .. string.NiceTime(ban_data.modified_time)
    end

    SendWebhook(ADMIN_LOGS_WEBHOOK, JSON, "Gmod Admin logs")
end)

hook.Add("ULibPlayerKicked", "KickLogs", function(steamid, reason, caller)
    JSON["embeds"][1]["description"] = ((IsValid(caller) and caller:Nick()) or "CONSOLE") .. "(" .. ((IsValid(caller) and caller:SteamID()) or "") .. ")" .. " kicked " .. steamid .. " because " .. reason
    SendWebhook(ADMIN_LOGS_WEBHOOK, JSON, "Gmod Admin logs")
end)

hook.Add("ULibUserGroupChange", "UserGroupLogs", function(id, _, _, new_group, old_group)
    JSON["embeds"][1]["description"] = id .. " usergroup change: " .. (old_group or "") .. "->" .. new_group
    SendWebhook(ADMIN_LOGS_WEBHOOK, JSON, "Gmod Admin logs")
end)

hook.Add("InitPostEntity", "StartLogs", function()
    if game.IsDedicated() == false then -- therefore local p2p testing 
        return
    end

    if game.GetMapChangeCount() == 1 then
        JSON["embeds"][1]["description"] = "Server started"
    else
        JSON["embeds"][1]["description"] = "Map started on " .. game.GetMap()
    end

    SendWebhook(ADMIN_LOGS_WEBHOOK, JSON, "Gmod Admin logs", true)
    JSON.embeds[1].fields = nil
end)
