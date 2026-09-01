local ENV = include("rv_env/sv_rv_env.lua")
local Token = ENV.INVITES.TOKEN
local InviteChannel = ENV.INVITES.INVITE_CHANNEL
local WebhookLink = ENV.INVITES.INVITE_LOG_WEBHOOK
sql.QueryTyped("CREATE TABLE IF NOT EXISTS discord_invites ( SteamID32 TEXT UNIQUE, discord_invite TEXT, expire_time TEXT)")
function MakeDiscordInvite(ply, ExpirationTime, callback, forced)
    if not IsValid(ply) or not ExpirationTime then return end
    if ply:OwnerSteamID64() ~= ply:SteamID64() and forced ~= true then
        print(ply:Nick() .. " does not own gmod, returning.")
        callback("")
        return
    end

    local PlyData = sql.QueryTyped("SELECT * FROM discord_invites WHERE SteamID32 = ?", ply:SteamID())
    if istable(PlyData) and PlyData[1] and (os.time() - tonumber(PlyData[1]["expire_time"]) < ExpirationTime) then
        print(ply:Nick() .. "'s discord invite has not expired yet, returning.")
        callback("discord.gg/" .. PlyData[1]["discord_invite"])
        return
    end

    reqwest({
        method = "post",
        type = "application/json; charset=utf-8",
        headers = {
            ["User-Agent"] = "Gmod Server Discord Invite Maker",
            ["Content-Type"] = "application/json",
            ["Authorization"] = Token,
        },
        url = InviteChannel,
        body = util.TableToJSON({
            ["max_age"] = ExpirationTime,
            ["max_uses"] = 1,
            ["temporary"] = false,
            ["unique"] = true
        }),
        failed = function(error)
            --
            ErrorNoHalt("SendWebhook HTTP Errored: ", error, "\n")
        end,
        success = function(code, response)
            if code == 200 then --
                local DiscordInvite = util.JSONToTable(response)["code"]
                local ExpirationDate = os.time() + ExpirationTime
                print("Made invite  " .. "`discord.gg/" .. DiscordInvite .. "`" .. " for " .. ply:Nick() .. "`( `" .. ply:SteamID() .. "` )" .. " expiring in  " .. string.NiceTime(ExpirationTime))
                sql.QueryTyped("INSERT OR REPLACE INTO discord_invites ( SteamID32, discord_invite, expire_time ) VALUES ( ?, ?, ? )", ply:SteamID(), DiscordInvite, ExpirationDate)
                local Json = {
                    ["content"] = null,
                    ["embeds"] = {
                        {
                            ["description"] = "Made invite  " .. "`discord.gg/" .. DiscordInvite .. "`" .. " for " .. ply:Nick() .. "`( `" .. ply:SteamID() .. "` )" .. " expiring in  " .. string.NiceTime(ExpirationTime),
                            ["color"] = 5814783,
                        }
                    },
                    ["username"] = "Tom",
                    ["attachments"] = {}
                }

                SendWebhook(WebhookLink, Json, "Gmod Discord Invite Creation Informer")
                callback("discord.gg/" .. DiscordInvite)
            else
                ErrorNoHalt("SendWebhook HTTP Errored: ", code, response, "\n")
                callback(code)
            end
        end
    })
end
