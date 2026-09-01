-- TODO
-- local matches_count = (highestmatchid[1]["MAX(match_id)"] or 0) + 1 -- this line makes the first match ALWAYS rating period 1, then after that are different rating periods. WRONG!
local CalculateNewGlicko, _ = include("autorun/server/rv_glicko.lua")
--[[-----------------------
    Constants
-------------------------]]
RatingPeriodInterval = 5 -- Amount of matches between rating periods (the paper recommends 5-10, but thats for a chess tournament that has very low amount of games played, I'll see if 15 works well)
--[[-----------------------
    From https://wiki.facepunch.com/gmod/sql.QueryTyped#example, I don't want to have to print out every single error
-------------------------]]
sql.m_strError = nil
-- This is required to invoke __newindex
setmetatable(sql, {
    __newindex = function(table, k, v) if k == "m_strError" and v and #v > 0 then ErrorNoHaltWithStack("[SQL Error] " .. v) end end
})

--[[-----------------------
    Example with database
-------------------------]]
local ratingperiod = nil
local function UpdateGlicko(ply, newrating, newrd, category, matchid)
    print("Updating " .. tostring(ply) .. "glicko")
    sql.QueryTyped("CREATE TABLE IF NOT EXISTS player_glickos (steamid64 TEXT UNIQUE, rating INTEGER, rd INTEGER, matchessincelastrating INTEGER, lastmatchid INTEGER, forfeited INTEGER DEFAULT 0, rated INTEGER DEFAULT 0)")
    local tblexists = sql.QueryTyped("SELECT name FROM sqlite_master WHERE type='table' AND name='player_glickos';")
    --PrintTable(tblexists)
    PlayerData = nil
    if tblexists then
        PlayerData = sql.QueryTyped("SELECT * FROM player_glickos WHERE steamid64 = ?", ply) -- Try and get last glicko
    end

    -- Get rating period
    --local highestmatchid = sql.QueryTyped("SELECT MAX(match_id) FROM match_data WHERE match_id")
    --local matches_count = highestmatchid[1]["MAX(match_id)"] + 1
    --ratingperiod = math.ceil(matches_count / RatingPeriodInterval)
    ----
    print(newrating)
    print(newrd)
    sql.QueryTyped("INSERT OR REPLACE INTO player_glickos (steamid64, rating, rd, matchessincelastrating, lastmatchid) VALUES (?, ?, ?, ?, ?)", ply, newrating, newrd, 0, matchid)
end

-- Make match_data and player_glickos table
sql.QueryTyped("CREATE TABLE IF NOT EXISTS match_data ( match_id INTEGER PRIMARY KEY AUTOINCREMENT, winner_SteamID64 TEXT, loser_SteamID64 TEXT, tie BOOLEAN, category TEXT, matchdate TEXT, ratingperiod INTEGER)")
sql.QueryTyped("CREATE TABLE IF NOT EXISTS player_glickos (steamid64 TEXT UNIQUE, rating INTEGER, rd INTEGER, matchessincelastrating INTEGER, lastmatchid INTEGER)")
--
--[[
local function GetUnusedMatches(player, lastmatchid, category)
    return sql.QueryTyped("SELECT * FROM match_data WHERE (winner_SteamID64 = ? OR loser_SteamID64 = ?) AND match_id > ? AND category = ? ORDER BY match_id ASC", player, player, lastmatchid or 0, category)
end
--]]
-- You should be adding to the match_data table in whatever function you use to end a round like this:
local MatchesLeft = {}
--steamid = matchesleft
local function UpdateDatabaseGlicko(winner, winnerscore, loser, loserscore, category, forfeited, rated)
    local highestmatchid = sql.QueryTyped("SELECT MAX(match_id) FROM match_data WHERE match_id")
    local matches_count = (highestmatchid[1]["MAX(match_id)"] or 0) + 1
    ratingperiod = math.ceil(matches_count / RatingPeriodInterval)
    sql.QueryTyped("INSERT INTO match_data (winner_SteamID64, loser_SteamID64, tie, category, matchdate, ratingperiod, forfeited, rated) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", --
        IsValid(winner) and winner:SteamID64() or winner, --
        IsValid(loser) and loser:SteamID64() or loser, --
        ((winner.score and loser.score) and (winner.score == loser.score)) or (winnerscore == loserscore and forfeited == false), --
        category, --
        tostring(os.time()), --
        ratingperiod, --
        forfeited, --
        rated)

    -- the rating period isn't used right now
    if rated == true then
        local players = {winner, loser}
        for _, ply in ipairs(players) do
            local plyData = sql.QueryTyped("SELECT * FROM player_glickos WHERE steamid64 = ?", ply)
            local plyLastUsedMatchID = (plyData ~= false and plyData[1] and plyData[1]["lastmatchid"]) or 0
            local plyMatchData = sql.QueryTyped("SELECT * FROM match_data WHERE (winner_SteamID64 = ? OR loser_SteamID64 = ?) AND match_id > ? AND rated = ?", ply, ply, plyLastUsedMatchID, "1")
            local plyMatchesSinceLastRating = (plyData ~= false and plyData[1] and plyData[1]["matchessincelastrating"] or 0) + 1
            MatchesLeft[ply] = RatingPeriodInterval - plyMatchesSinceLastRating
            --
            sql.QueryTyped("INSERT OR IGNORE INTO player_glickos (steamid64, rating, rd, matchessincelastrating, lastmatchid) VALUES (?, 1500, 350, 0, 0)", ply)
            sql.QueryTyped("UPDATE player_glickos SET rating = ?, rd = ?, matchessincelastrating = ? WHERE steamid64 = ?", (plyData ~= false and plyData[1] and plyData[1]["rating"]) or 1500, (plyData ~= false and plyData[1] and plyData[1]["rd"]) or 350, plyMatchesSinceLastRating, ply)
            if plyMatchesSinceLastRating and (plyMatchesSinceLastRating >= RatingPeriodInterval) then
                newrating, newrd = CalculateNewGlicko(ply, plyMatchData, category)
                if newrating and newrd then --
                    UpdateGlicko(ply, newrating, newrd, category, matches_count)
                end
            end
        end
    end
end

local function GetMatchesLeft(steamid)
    return MatchesLeft[steamid]
end
--EndMatch("76561198004000007", 0, "76561198006000008", 20, "Duel")
--EndMatch("76561198004000004", 0, "76561198006000001", 20, "Duel")
--EndMatch("76561198004000002", 20, "76561198006000001", 0, "Duel")
--EndMatch("76561198004000001", 20, "76561198006000002", 0, "Duel")
--local results = sql.QueryTyped("SELECT * FROM match_data WHERE winner_SteamID64 = '76561198000000001'")
--PrintTable(results)
--CalculateNewGlicko("76561198000000002")
return UpdateDatabaseGlicko, GetMatchesLeft
