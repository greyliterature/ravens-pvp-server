local GamemodeData = include("../../gamemodedata.lua")
if not GamemodeData[game.GetMap()] then --
    return false, "NO DATA"
end

if not GamemodeData[game.GetMap()].Flags then --
    return false, "NO FLAGS"
end
