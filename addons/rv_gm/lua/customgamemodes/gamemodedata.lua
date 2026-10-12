local TEAM_RED, TEAM_BLUE = 1, 2
local gamemodedata = {
    ["gm_construct"] = {
        ["Spawns"] = {
            [TEAM_RED] = {
                --
                {Vector(-2657.5918, -2696.7729, 250.5143), Angle(0, 0, 0)},
                {Vector(-2115.724609, -2892.277100, 252.458130), Angle(0, 180, 0)}
            },
            [TEAM_BLUE] = {
                --
                {Vector(1530.274, 215.959, -143.2295), Angle(0, 180, 0)}
            }
        },
        ["Flags"] = {
            --
            [TEAM_RED] = Vector(-2400.0227, -2778.4871, 285.6617),
            [TEAM_BLUE] = Vector(1500.3245, 0.7712, -120.4699),
        },
        ["Hills"] = {
            --
            Vector(-1095.698853, 636.765564, -145.227905),
        }
    }
}
return gamemodedata
