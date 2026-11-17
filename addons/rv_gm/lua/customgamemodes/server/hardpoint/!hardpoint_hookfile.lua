local GamemodeData = include("../../gamemodedata.lua")
if not GamemodeData[game.GetMap()] then --
    return false, "NO DATA"
end

if not GamemodeData[game.GetMap()].HardPoints then --
    return false, "NO HILLS"
end
