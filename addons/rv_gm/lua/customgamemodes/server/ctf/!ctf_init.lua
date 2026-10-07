local rv_gm = include("../gm_universal/gm_universal.lua")
local TEAM_RED, TEAM_BLUE = 1, 2
team.SetUp(TEAM_RED, "Red Team", Color(255, 0, 0), true)
team.SetUp(TEAM_BLUE, "Blue Team", Color(0, 0, 255), true)
--
local function CreateDollFlag(vec, teamindex)
end

rv_gm.SetAllToSpectate(true)
rv_gm.EnableTeamJoins(true)
rv_gm.SetTimeLimit(600)
--[[----------------------------------------------------------------------
THE TIME LIMIT SHOULD ONLY START WHEN THE MATCH ACTUALLY STARTS, NOT IMMEDIATELY ON LOAD.
MAKE SOMETHING THAT DIFFERENTIATES WARMUP AND MATCH
------------------------------------------------------------------------]]
rv_gm.SetTeamIndexes({TEAM_RED, TEAM_BLUE})
rv_gm.SetScoreLimit(3)
hook.Add("ShouldSpectateOnJoin", "SetSpectateOnJoin", function(ply)
    return true --
end)

hook.Add("rv_gm.MatchEnded", "MatchEnded", function()
    --
    print("MATCH ENDED")
end)
