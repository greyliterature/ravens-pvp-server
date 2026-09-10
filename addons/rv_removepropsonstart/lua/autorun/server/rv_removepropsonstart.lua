local IgnoreUniversalBlacklist = false -- debug
local MapSettings = {
    ["UniversalBlacklist"] = {
        ["GetClass"] = {
            "prop_.*", -- 
            "item_ammo_.*",
            "item_rpg_.*",
            "item_box_buckshot",
            "item_health",
            "item_battery",
            "info_particle_system",
            "item_item_crate"
        }
    },
    ["PerMapSettings"] = {
        ["ttt_warhawk_g2"] = {
            ["Blacklists"] = {},
            ["Whitelists"] = {
                ["GetClass"] = {"prop_door_rotating"},
                ["MapCreationID"] = {
                    "2305", -- the fence
                    "1537" -- the fence's padlock
                }
            }
        }
    },
}

local function FindStringInArray(Array, str)
    for i = 1, #Array do
        if string.find(str, Array[i]) then --
            return true
        end
    end
    return false
end

local function RemoveBadEnts()
    for _, ent in ents.Iterator() do
        if ent:MapCreationID() == "-1" then -- not a map ent 
            continue
        end

        local MarkedForRemoval = false
        if IgnoreUniversalBlacklist ~= true then
            for GetterType, tbl in pairs(MapSettings["UniversalBlacklist"]) do -- check if in universal blacklist and mark for removal
                if FindStringInArray(tbl, ent[GetterType](ent)) then MarkedForRemoval = true end
            end
        end

        local Unslated = false
        if MapSettings["PerMapSettings"][game.GetMap()] then
            for GetterType, tbl in pairs(MapSettings["PerMapSettings"][game.GetMap()]["Blacklists"]) do
                if FindStringInArray(tbl, ent[GetterType](ent)) then -- if its a whitelisted ent type then its unmarked for removal
                    MarkedForRemoval = true
                end
            end

            if MarkedForRemoval == true then
                for GetterType, tbl in pairs(MapSettings["PerMapSettings"][game.GetMap()]["Whitelists"]) do -- check if in permapsettings whitelist and unmark for removal
                    if FindStringInArray(tbl, ent[GetterType](ent)) then -- if its a whitelisted ent type then its unmarked for removal
                        Unslated = true
                        MarkedForRemoval = false
                    end
                end
            end
        end

        if MarkedForRemoval == true then
            print("Removing ", ent:GetClass(), " at ", ent:GetPos(), " with model ", ent:GetModel())
            ent:Remove()
        elseif MarkedForRemoval == false and Unslated == true then
            -- only print exceptions
            print("Not removing ", ent:GetClass(), " at ", ent:GetPos(), " with model ", ent:GetModel())
        end
    end
end

RemoveBadEnts() -- autorefresh
hook.Add("PostCleanupMap", "RemoveProps", RemoveBadEnts)
hook.Add("InitPostEntity", "RemovePropsAndEffects", RemoveBadEnts)
