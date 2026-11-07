require("reqwest")
local ENV = include("rv_env/sv_rv_env.lua")
util.AddNetworkString("SendCommitData")
util.AddNetworkString("SendAdminMOTDInfo")
util.AddNetworkString("SendDiscordInvite")
local DiscordInviteRequirement = 5 -- required amount of unique matches so that player gets an invite
local function GetUniqueMatches(ply)
    local MatchesPlayed = sql.QueryTyped("SELECT * FROM match_data WHERE winner_SteamID64 = ? OR loser_SteamID64 = ?", ply:SteamID64(), ply:SteamID64())
    ply.matchesleft = DiscordInviteRequirement
    if MatchesPlayed ~= false then
        local UniquePlayersFought = {}
        for _, data in pairs(MatchesPlayed) do
            local info = {data["winner_SteamID64"], data["loser_SteamID64"],}
            local forfeited = tobool(data["forfeited"])
            for i = 1, #info do
                if ply:SteamID64() ~= info[i] and forfeited == false and not UniquePlayersFought[info[i]] then --
                    UniquePlayersFought[info[i]] = true
                end
            end
        end

        if table.Count(UniquePlayersFought) >= DiscordInviteRequirement then --
            MakeDiscordInvite(ply, 86400, function(invite)
                --
                ply.invite = invite
            end, forced)
        else
            ply.matchesleft = DiscordInviteRequirement - table.Count(UniquePlayersFought)
        end
    end
end

--[[
sql.QueryTyped("ALTER TABLE match_data ADD COLUMN forfeited INTEGER DEFAULT 0;")
sql.QueryTyped("ALTER TABLE match_data ADD COLUMN rated INTEGER DEFAULT 0;")
--]]
local function SendCommitData(ply)
    local CommitDatas = {}
    -- This http request is about the only thing made by ai in the entire rv_motd scripts
    local GITHUB_TOKEN = ENV.GITHUB_TOKEN
    local url = "https://api.github.com/repos/greyliterature/ravens-pvp-server/commits?per_page=5"
    reqwest({
        url = url,
        method = "GET",
        headers = {
            ["Authorization"] = "Bearer " .. GITHUB_TOKEN,
            ["User-Agent"] = "GMod-Server"
        },
        success = function(code, body, headers)
            local data = util.JSONToTable(body)
            if not data then
                print("Failed to parse JSON")
                return
            end

            for _, commit in ipairs(data) do
                CommitDatas[#CommitDatas + 1] = utf8.sub(commit.commit.message, 1, 79) .. ((#commit.commit.message + #commit.commit.author.name >= 79 and "... - ") or " - ") .. "Authored by " .. commit.commit.author.name
            end

            net.Start("SendCommitData")
            net.WriteTable(CommitDatas)
            net.Send(ply)
        end,
        failed = function(err) print("GitHub request failed:", err) end
    })
end

hook.Add("InitPostEntityStarted", "NetworkMOTD", function(ply)
    GetUniqueMatches(ply)
    local Admins = {}
    for group, _ in pairs(ulx.motdSettings.admins) do
        --ulx.motdSettings.admins[group] = {}
        for steamID, dt in pairs(ULib.ucl.users) do
            if dt.group == group and dt.name then
                Admins[dt.name] = steamID
                --table.insert(ulx.motdSettings.admins[group], data.name)
            end
        end
    end

    SendCommitData(ply)
    net.Start("SendAdminMOTDInfo")
    net.WriteTable(Admins)
    net.Send(ply)
    if ply:OwnerSteamID64() == ply:SteamID64() then
        net.Start("SendDiscordInvite")
        net.WriteString(ply.invite or ("To prevent spam & alting, you must complete " .. ply.matchesleft .. " more duels with different people for an invite. "))
        net.WriteBool((ply.invite and true) or ply.matchesleft <= 0)
        net.Send(ply)
    elseif ply:OwnerSteamID64() ~= ply:SteamID64() then
        print(ply:Nick() .. " does not own gmod, not making invite.\n")
    end
end)
