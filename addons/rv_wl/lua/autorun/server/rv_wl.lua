-- Based on the research paper A Bayesian Approximation Method for Online Ranking by Ruby C. Weng and Chih-Jen Lin, 
-- https://jmlr.csail.mit.edu/papers/volume12/weng11a/weng11a.pdf
local WL = {}
--
-- Symbolage:
-- ∀ᵢ means "for all i"
-- "β²ᵢ uncertainty about the performance of team 𝑖" -- from notation table, not my notes
-- "r(i) rank of team i in a game; smaller is better; see Section 2.1" -- from notation table, not my notes  
--
-- Constants: (should just be euler's number used)
local e = 2.718281828459045
-- Defaults:
-- These defaults are defined in section 6.1 of the paper
-- Also defined in section 4.2 of https://proceedings.neurips.cc/paper_files/paper/2006/file/f44ee263952e65b3610b8ba51229d1f9-Paper.pdf
local DEFAULT_μ = 25 -- mew 
local DEFAULT_σ² = (25 / 3) ^ 2 -- variance
local β = 25 / 6 -- additional stdev, should always be squared to get variance
local κ = 0.00000001 -- "a small positive value to avoid σ2 i becoming negative; see (28) and (44)"
--[[---------------------------------------------
    Algorithm 1
-----------------------------------------------]]
function WL.Bradley_Terry_Full(GameResult)
    -- Step 1. "Given a game result and the current μᵢⱼ, σ²ᵢⱼ, ∀ᵢ, ∀ⱼ. Given β² and κ > 0. Decide a way to set γ_q in (50)
    -- (50) is shown in step 3.1
    -- Step 2. "For i = 1, ..., k, set"
    -- k is the number of teams
    local k = #GameResult.Teams
    -- "μᵢ = Σⁿⱼ₌₁ μᵢⱼ , σ²ᵢ = Σⁿⱼ₌₁ σ²ᵢⱼ." 
    -- ᵢ is the team index
    -- ⱼ is the a certain opponent index
    -- μᵢ is the team's rating 
    local μ = {} -- ratings of μ_i
    local σ² = {} -- stdevs of u_i, remember to square this always to get variance
    for i = 1, k do
        local TeamTable = GameResult.Teams[i]
        μ[i] = {}
        σ²[i] = {}
        local players = {}
        for ply, _ in pairs(TeamTable.Players) do -- ignore this, i want it to look more like the research paper, this lets me iterate through nilled keys
            players[#players + 1] = ply
        end

        for j = 1, #players do
            local ply = players[j]
            local PlayerTable = TeamTable.Players[ply] or {}
            do
                -- set defaults
                if not PlayerTable.μ then --
                    PlayerTable.μ = DEFAULT_μ
                end

                if not PlayerTable.σ² then --
                    PlayerTable.σ² = DEFAULT_σ²
                end
            end

            μ[i][j] = PlayerTable.μ
            σ²[i][j] = PlayerTable.σ²
        end
    end

    local Scores = {} -- {teamindex, score}
    do
        -- set rankings per team [r(i)]
        -- this could be more efficient, just don't feel like making my own ranking method
        for i = 1, k do
            local TeamTable = GameResult.Teams[i]
            local score = TeamTable.Score
            Scores[i] = {i, score}
        end

        table.sort(Scores, function(a, b)
            return a[2] > b[2] --
        end)
    end

    local function r(i)
        for rank = 1, #Scores do
            local TeamIndex = Scores[rank][1]
            if TeamIndex == i then
                local MyScore = Scores[rank][2]
                local LastRank = rank
                for m = rank, 1, -1 do -- go back down to check tying ranks
                    local TheirScore = Scores[m][2]
                    if TheirScore ~= MyScore then --
                        return LastRank
                    elseif m == 1 then
                        return 1
                    end

                    LastRank = m
                end
            end
        end
    end

    local Mews = {}
    local Variances = {}
    do
        -- get total means / variances
        for i = 1, k do
            for j = 1, #μ[i] do
                Mews[i] = (Mews[i] or 0) + μ[i][j]
                Variances[i] = (Variances[i] or 0) + σ²[i][j]
            end
        end
    end

    -- Step 3. "For i = 1, ..., k,"
    local c = {}
    local p̂ = {}
    local δ = {}
    local η = {}
    local Ω = {}
    local ∆ = {}
    local γ = {}
    for i = 1, k do
        --      3.1. "Team skill update: obtain Ωᵢ and ∆ᵢ in (27) and (28) by the following steps."
        --          3.1.1 "For q = 1, ..., k, q =/ i,"
        c[i] = {}
        p̂[i] = {}
        for q = 1, k do
            if q == i then
                continue -- where q =/ i
            end

            -- "c_iq = (σ²ᵢ + σ²_q + 2β²)^1/2"
            c[i][q] = (Variances[i] + Variances[q] + 2 * β ^ 2) ^ (1 / 2)
            -- "γ_q in (50) is set as σ_i/c_iq for BT-full." [Said in section 6.1] (this algorithm is BT full)
            γ[q] = math.sqrt(Variances[i]) / c[i][q]
            -- "p̂_iq = e^(μ_i / c_iq) / (e^(μ_i / c_iq) + e^μ_q / c_iq)"
            p̂[i][q] = e ^ (Mews[i] / c[i][q]) / (e ^ (Mews[i] / c[i][q]) + e ^ (Mews[q] / c[i][q]))
            p̂_qi = 1 - p̂[i][q]
            -- "δ_q = (σ²₁ / c_iq) * (s - p̂_iq)"
            -- "Where
            --[[
                s = {
                    1: r(q) > r(i)
                    1/2: r(q) = r(i)
                    0: r(q) < r(i) 
                }"
            --]]
            local s = nil
            if r(q) > r(i) then
                s = 1
            elseif r(q) == r(i) then
                s = 1 / 2
            elseif r(q) < r(i) then
                s = 0
            end

            δ[q] = (Variances[i] / c[i][q]) * (s - p̂[i][q])
            --"η_q = γ_q(σ_i / c_iq)^2 * p̂_iq * p̂_qi"
            η[q] = γ[q] * (math.sqrt(Variances[i]) / c[i][q]) ^ 2 * p̂[i][q] * p̂_qi
            -- Step 3.1.2 
            -- "Calculate"
            -- "Ω_i = Σδ_q"
            Ω[i] = (Ω[i] or 0) + δ[q]
            -- "∆_i = Ση_q"
            ∆[i] = (∆[i] or 0) + η[q]
        end

        -- Step 3.2 "Individual skill update"
        -- now we're out of that inner for loop
        -- 
        -- "For j = 1, ... , n_i,"
        -- "u_ij <- u_ij + (σ²_ij / σ²_i) * Ω_i"
        -- "σ_ij <- σ²_ij * max(1 - (σ²_ij / σ²_i) * ∆_i, κ)"
        local n = #μ[i]
        for j = 1, n do
            μ[i][j] = μ[i][j] + (σ²[i][j] / Variances[i]) * Ω[i]
            σ²[i][j] = σ²[i][j] * math.max(1 - (σ²[i][j] / Variances[i]) * ∆[i], κ)
        end
    end

    local PlayerTable = {}
    do
        -- playertable for returning
        for i = 1, k do
            local TeamTable = GameResult.Teams[i]
            PlayerTable[i] = {}
            local j = 1
            for ply, _ in pairs(TeamTable.Players) do -- this makes the player table out of order but it shouldn't really matter
                PlayerTable[i][ply] = {}
                PlayerTable[i][ply][1] = μ[i][j]
                PlayerTable[i][ply][2] = σ²[i][j]
                j = j + 1
            end
        end
    end
    return PlayerTable
end

--[[---------------------------------------------
    Algorithm 4
-----------------------------------------------]]
local PlayerCache = {}
-- {["mew"] = mew, ["variance"] = variance}
sql.QueryTyped("CREATE TABLE IF NOT EXISTS player_plratings ( steamid32 TEXT UNIQUE, mew DOUBLE, variance DOUBLE )")
function WL.GetPlayerPLR(ply) -- take from cache or sql query if not cached, or give default variance mew 
    local steamid32 = ply
    if not isstring(ply) and ply:IsPlayer() then --
        steamid32 = ply:SteamID()
    end

    if util.SteamIDTo64(steamid32) == 0 then
        error("Invalid SteamID32")
        return
    end

    local PlayerTable = PlayerCache[steamid32]
    local mew, variance = (PlayerTable and PlayerTable["mew"]) or nil, (PlayerTable and PlayerTable["variance"]) or nil
    if not mew or not variance then
        local query = sql.QueryTyped("SELECT mew, variance FROM player_plratings WHERE steamid32 = ?", steamid32)
        if query[1] then --
            mew, variance = query[1]["mew"], query[1]["variance"]
        end
    end

    mew, variance = mew or DEFAULT_μ, variance or DEFAULT_σ²
    PlayerCache[steamid32] = {
        ["mew"] = mew,
        ["variance"] = variance
    }
    return mew, variance
end

function WL.UpdatePlayerPLR(ply, newmew, newvariance)
    local steamid32 = ply
    if not isstring(ply) and ply:IsPlayer() then --
        steamid32 = ply:SteamID()
    end

    if util.SteamIDTo64(steamid32) == 0 then
        error("Invalid SteamID32")
        return
    end

    PlayerCache[steamid32] = {
        ["mew"] = newmew,
        ["variance"] = newvariance
    }

    sql.QueryTyped("INSERT INTO player_plratings ( steamid32, mew, variance ) VALUES( ?, ?, ? ) ON CONFLICT(steamid32) DO UPDATE SET mew=excluded.mew, variance=excluded.variance", steamid32, newmew, newvariance) -- https://www.sqlite.org/lang_upsert.html
end

function WL.PlackettLuce(GameResult)
    -- Step 1. "Given a game result and the current μᵢⱼ, σ²ᵢⱼ, ∀ᵢ, ∀ⱼ. Given β² and κ > 0. Decide a way to set γ_q in (50)
    -- (50) is shown in step 3.1
    -- Step 2. "For i = 1, ..., k, set"
    -- k is the number of teams
    local k = #GameResult.Teams
    -- "μᵢ = Σⁿⱼ₌₁ μᵢⱼ , σ²ᵢ = Σⁿⱼ₌₁ σ²ᵢⱼ." 
    -- ᵢ is the team index
    -- ⱼ is the a certain opponent index
    -- μᵢ is the team's rating 
    local μ = {} -- ratings of μ_i
    local σ² = {} -- stdevs of u_i, remember to square this always to get variance
    for i = 1, k do
        local TeamTable = GameResult.Teams[i]
        μ[i] = {}
        σ²[i] = {}
        local players = {}
        for ply, _ in pairs(TeamTable.Players) do -- ignore this, i want it to look more like the research paper, this lets me iterate through nilled keys
            players[#players + 1] = ply
        end

        for j = 1, #players do
            local ply = players[j]
            local PlayerTable = TeamTable.Players[ply] or {}
            do
                -- set defaults
                local mew, variance = WL.GetPlayerPLR(ply)
                PlayerTable.μ = mew
                PlayerTable.σ² = variance
            end

            μ[i][j] = PlayerTable.μ
            σ²[i][j] = PlayerTable.σ²
        end
    end

    local Scores = {} -- {teamindex, score}
    do
        -- set rankings per team [r(i)]
        -- this could be more efficient, just don't feel like making my own ranking method
        for i = 1, k do
            local TeamTable = GameResult.Teams[i]
            local score = TeamTable.Score
            Scores[i] = {i, score}
        end

        table.sort(Scores, function(a, b)
            return a[2] > b[2] --
        end)
    end

    local function r(i)
        for rank = 1, #Scores do
            local TeamIndex = Scores[rank][1]
            if TeamIndex == i then
                local MyScore = Scores[rank][2]
                local LastRank = rank
                for m = rank, 1, -1 do -- go back down to check tying ranks
                    local TheirScore = Scores[m][2]
                    if TheirScore ~= MyScore then --
                        return LastRank
                    elseif m == 1 then
                        return 1
                    end

                    LastRank = m
                end
            end
        end
    end

    local Mews = {}
    local Variances = {}
    do
        -- get total means / variances
        for i = 1, k do
            for j = 1, #μ[i] do
                Mews[i] = (Mews[i] or 0) + μ[i][j]
                Variances[i] = (Variances[i] or 0) + σ²[i][j]
            end
        end
    end

    -- Step 3. "Find and store"
    -- "c = (∑ σ²ᵢ + β²)^1/2"
    local c = 0
    for i = 1, k do
        c = c + (Variances[i] + β ^ 2)
    end

    c = c ^ (1 / 2)
    -- "A_q = |{s : r(s) = r(q)}|, q = 1, ..., k"
    local A_q = {}
    for q = 1, k do
        for s = 1, k do
            if r(s) == r(q) then --
                A_q[q] = (A_q[q] or 0) + 1
            end
        end
    end

    -- "∑ e^(θₛ / c), q = 1, ..., k, where C_q = {i: r(i) ≥ r(q)}"
    local C = {}
    for q = 1, k do
        for s = 1, k do
            if r(s) >= r(q) then --
                local θₛ = Mews[s]
                C[q] = (C[q] or 0) + e ^ (θₛ / c)
            end
        end
    end

    local p̂ = {}
    local δ = {}
    local η = {}
    local Ω = {}
    local ∆ = {}
    local γ = {}
    -- step 3.1 Team skill update:
    for i = 1, k do
        -- 3.1.1
        p̂[i] = {}
        for q = 1, k do
            -- step 3.1 Team skill update:
            local θᵢ = Mews[i]
            γ[q] = math.sqrt(Variances[i]) / c
            p̂[i][q] = e ^ (θᵢ / c) / C[q]
            local multiple_δ = nil
            if q == i then
                multiple_δ = 1 - p̂[i][q]
            elseif r(q) <= r(i) then
                multiple_δ = -1 * p̂[i][q]
            elseif r(q) > r(i) then
                multiple_δ = 0
            end

            δ[q] = Variances[i] / c * A_q[i] * multiple_δ
            local multiple_η = nil
            if r(q) <= r(i) then
                multiple_η = p̂[i][q] * (1 - p̂[i][q])
            elseif r(q) > r(i) then
                multiple_η = 0
            end

            η[q] = ((γ[q] * Variances[i]) / (c ^ 2 * A_q[q])) * multiple_η
            Ω[i] = (Ω[i] or 0) + δ[q]
            -- "∆_i = Ση_q"
            ∆[i] = (∆[i] or 0) + η[q]
        end

        -- Step 3.2 "Individual skill update"
        -- now we're out of that inner for loop
        -- 
        -- "For j = 1, ... , n_i,"
        -- "u_ij <- u_ij + (σ²_ij / σ²_i) * Ω_i"
        -- "σ_ij <- σ²_ij * max(1 - (σ²_ij / σ²_i) * ∆_i, κ)"
        local n = #μ[i]
        for j = 1, n do
            μ[i][j] = μ[i][j] + (σ²[i][j] / Variances[i]) * Ω[i]
            σ²[i][j] = σ²[i][j] * math.max(1 - (σ²[i][j] / Variances[i]) * ∆[i], κ)
        end
    end

    local PlayerTable = {}
    do
        -- playertable for returning
        for i = 1, k do
            local TeamTable = GameResult.Teams[i]
            PlayerTable[i] = {}
            local j = 1
            for ply, _ in pairs(TeamTable.Players) do -- this makes the player table out of order but it shouldn't really matter
                PlayerTable[i][ply] = {}
                PlayerTable[i][ply][1] = μ[i][j]
                PlayerTable[i][ply][2] = σ²[i][j]
                WL.UpdatePlayerPLR(ply, μ[i][j], σ²[i][j])
                j = j + 1
            end
        end
    end
    return PlayerTable
end
--[[---------------------------------------------
    Testing
-----------------------------------------------]]
--[[
local GameResult = {
    Teams = {
        [1] = {
            Score = 20,
            Players = {
                ["STEAM_0:1"] = {
                    μ = nil,
                    σ² = nil,
                    β = nil,
                },
                ["STEAM_0:1:16"] = {
                    μ = nil,
                    σ² = nil,
                    β = nil,
                },
                ["STEAM_0:0:50"] = {
                    μ = nil,
                    σ² = nil,
                    β = nil,
                },
                ["STEAM_0:1:0114"] = {
                    μ = nil,
                    σ² = nil,
                    β = nil,
                },
                ["STEAM_0:1:7936"] = {
                    μ = nil,
                    σ² = nil,
                    β = nil,
                },
            },
        },
        [2] = {
            Score = 0,
            Players = {
                ["STEAM_0:0:949"] = {
                    μ = nil,
                    σ² = nil,
                    β = nil,
                },
                ["BOT"] = {
                    μ = nil,
                    σ² = nil,
                    β = nil,
                },
                ["STEAM_0:1:86"] = {
                    μ = nil,
                    σ² = nil,
                    β = nil,
                },
                ["STEAM_0:0:9"] = {
                    μ = nil,
                    σ² = nil,
                    β = nil,
                },
                ["STEAM_0:0:06866"] = {
                    μ = nil,
                    σ² = nil,
                    β = nil,
                },
            },
        },
    }
}

PrintTable(WL.PlackettLuce(GameResult))
--]]
--PrintTable(WL.Bradley_Terry_Full(GameResult))
-- output (variance is used for the lua version instead of stdev like the #f code uses):
--[[
[1]:
		["Player1"]:
				[1]	=	26.285861249684
				[2]	=	68.303463030188
		["Player11"]:
				[1]	=	26.285861249684
				[2]	=	68.303463030188
		["Player2"]:
				[1]	=	26.285861249684
				[2]	=	68.303463030188
		["Player3"]:
				[1]	=	26.285861249684
				[2]	=	68.303463030188
		["Player4"]:
				[1]	=	26.285861249684
				[2]	=	68.303463030188
[2]:
		["Player10"]:
				[1]	=	23.714138750316
				[2]	=	68.303463030188
		["Player6"]:
				[1]	=	23.714138750316
				[2]	=	68.303463030188
		["Player7"]:
				[1]	=	23.714138750316
				[2]	=	68.303463030188
		["Player8"]:
				[1]	=	23.714138750316
				[2]	=	68.303463030188
		["Player9"]:
				[1]	=	23.714138750316
				[2]	=	68.303463030188
--]]
-- 
--
-- sample.data (same as the lua table, but with one player on each team to test):
--[[
1 -- num_game
10 -- num_total_players
2 -- num_teams_of_a_game
20 -- team_score
5 -- num_team_players
1 -- player_id
0 -- team_score 
5 -- num_team_players
5 -- player_id
--]]
-- ouput from #f code:
--
-- $ ./rank 0 ../data/sample.data
-- Algo 1 (BT model (full))
-- [mu] 26.28586 [sigma] 8.26459 [mu] 23.71414 [sigma] 8.26459
--
-- $ ./rank 1 ../data/sample.data 
-- Algo 2 (BT model (partial))
-- [mu] 26.28586 [sigma] 8.26459 [mu] 23.71414 [sigma] 8.26459
--
-- $ ./rank 3 ../data/sample.data 
-- Algo 3 (TM model (full))
-- [mu] 27.05800 [sigma] 8.15692 [mu] 22.94200 [sigma] 8.15692
--
-- $ ./rank 2 ../data/sample.data 
-- Algo 4 (PL model)
-- [mu] 26.28586 [sigma] 8.26459 [mu] 23.71414 [sigma] 8.26459
--
-- PrintTable(WL.PlackettLuce(GameResult))
-- output:
--[[
[1]:
		["Player1"]:
				[1]	=	26.285861249684
				[2]	=	68.303463030188
		["Player11"]:
				[1]	=	26.285861249684
				[2]	=	68.303463030188
		["Player2"]:
				[1]	=	26.285861249684
				[2]	=	68.303463030188
		["Player3"]:
				[1]	=	26.285861249684
				[2]	=	68.303463030188
		["Player4"]:
				[1]	=	26.285861249684
				[2]	=	68.303463030188
[2]:
		["Player10"]:
				[1]	=	23.714138750316
				[2]	=	68.303463030188
		["Player6"]:
				[1]	=	23.714138750316
				[2]	=	68.303463030188
		["Player7"]:
				[1]	=	23.714138750316
				[2]	=	68.303463030188
		["Player8"]:
				[1]	=	23.714138750316
				[2]	=	68.303463030188
		["Player9"]:
				[1]	=	23.714138750316
				[2]	=	68.303463030188

--]]
-- $ ./rank 5 ../data/sample.data 
-- Algo 5 (Glicko model)
-- [mu] 25.19030 [sigma] 8.33333 [mu] 8.33094 [sigma] 0.00000
-- Glick sample data (had to change team sizes to 1 and number of players to 2):
--[[
1
2
2
20
1
1
0
1
5
--]]
return WL
