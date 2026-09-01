-- Glicko system in lua based on the paper by Dr. Mark E. Glickman 
-- https://www.glicko.net/glicko/glicko.pdf
-- to do: 
-- explain everything
-- add back notation comments
-- rewrite it to not be weird arrays? 
local pi = math.pi -- To clutter notation less
--[[------------------
    Constants
--------------------]]
local StartingRating = 1500
local StartingRD = 350
local c = 10 -- Used by the paper. I do not have the data to determine a different c for my case. 
-- "I would therefore recommend that an RD never drop below a threshold value,
-- such as 30, so that ratings can change appreciably even in a relatively short time."
local RDThreshold = 30
--[[------------------
    Glicko calculations
--------------------]]
Glickos = {}
local function GetGlicko(steamid64, category)
    Glickos[steamid64] = Glickos[steamid64] or {}
    -- Database (would be too awkward to put in the database.lua)
    local SQLGlickoTable = sql.QueryTyped("SELECT rating, rd, matchessincelastrating FROM player_glickos WHERE steamid64 = ?", steamid64)
    local SQLRating = SQLGlickoTable[1] and SQLGlickoTable[1]["rating"]
    local SQLRD = SQLGlickoTable[1] and SQLGlickoTable[1]["rd"]
    --local SQLMatchesSinceLastRating = (SQLGlickoTable[1] and SQLGlickoTable[1]["matchessincelastrating"]) or RatingPeriodInterval
    --local SQLMatchesTable = sql.QueryTyped("SELECT MAX(ratingperiod) FROM match_data")
    --local SQLLastRatingPeriod = SQLMatchesTable[1] and SQLMatchesTable[1]["ratingperiod"]
    -----
    --local LuaCachedRating = Glickos[steamid64][(category or "") .. "Rating"]
    --local LuaCachedRD = Glickos[steamid64][(category or "") .. "RD"]
    --local NewRating = SQLRating or LuaCachedRating or StartingRating
    local CachedRating = SQLRating or Glickos[steamid64][(category or "") .. "Rating"] or StartingRating
    local CachedRD = SQLRD or Glickos[steamid64][(category or "") .. "RD"] or StartingRD
    --local NewRD = (SQLMatchesSinceLastRating >= RatingPeriodInterval) and math.min(math.sqrt(CachedRD ^ 2 + (constant or c) ^ 2), StartingRD) or CachedRD
    --PrintTable(Glickos)
    --Glickos[steamid64][(category or "") .. "Rating"] = NewRating
    --Glickos[steamid64][(category or "") .. "RD"] = NewRD
    return CachedRD, CachedRating
end

local function CalculateNewGlicko(ply, matches, category, constant) -- always use a steamid64 for this (obviously easily changable to steamid32, but i don't have a need for a smaller database right now)
    print("num matches: " .. #matches)
    local OpponentRatings = {}
    local OpponentRDs = {}
    local MatchOutcomes = {}
    for _, data in pairs(matches) do
        local opponent = nil
        local outcome = nil
        if data.winner_SteamID64 == ply then
            opponent = data.loser_SteamID64
            outcome = 1
        elseif data.loser_SteamID64 == ply then
            opponent = data.winner_SteamID64
            outcome = 0
        elseif data.winnerscore == data.loserscore then
            outcome = 0.5
        else
            continue
        end

        local opponentrd, opponentrating = GetGlicko(opponent, category, constant)
        OpponentRatings[#OpponentRatings + 1] = opponentrating
        OpponentRDs[#OpponentRDs + 1] = opponentrd
        MatchOutcomes[#MatchOutcomes + 1] = outcome
    end

    --[[--------
        Step 1
    ----------]]
    -- "If the player is unrated set the rating to 1500 and the RD to 350.""
    -- "Otherwise, use the player’s rating from the last period, and calculate the new RD
    -- from the RD at the last period (RD_old) by the formula
    -- RD = min(sqrt(RD^2_old + c^2, 350))
    -- where c is a constant that governs the increase in uncertainty between rating periods"
    local PlayerRD, PlayerRating = GetGlicko(ply, category, constant)
    --[[--------
        Step 2
    ----------]]
    local r = PlayerRating
    local RD = math.min(math.sqrt(PlayerRD ^ 2 + (constant or c) ^ 2), StartingRD)
    local q = math.log(10) / 400
    local function g(RD_num)
        return 1 / math.sqrt(1 + 3 * q ^ 2 * (RD_num ^ 2) / pi ^ 2)
    end

    local function E(j)
        return 1 / (1 + 10 ^ (-g(OpponentRDs[j]) * (r - OpponentRatings[j]) / 400))
    end

    local m = OpponentRatings
    local dSquared = 0
    for j = 1, #m do
        dSquared = dSquared + g(OpponentRDs[j]) ^ 2 * E(j) * (1 - E(j))
    end

    dSquared = (q ^ 2 * dSquared) ^ -1
    local PrimeSum = 0
    for j = 1, #m do
        PrimeSum = PrimeSum + g(OpponentRDs[j]) * (MatchOutcomes[j] - E(j))
    end

    local rPrime = r + (q / (1 / RD ^ 2 + 1 / dSquared) * PrimeSum)
    local RDPrime = math.max(math.sqrt((1 / RD ^ 2 + 1 / dSquared) ^ -1), RDThreshold)
    print(rPrime, ply)
    return rPrime, RDPrime
end
return CalculateNewGlicko, GetGlicko
