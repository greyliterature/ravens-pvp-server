local function GetMapWSID(mapname)
    local CurrentMap = sql.QueryTyped("SELECT wsid FROM hotloaded_maps WHERE mapname = ?", mapname .. ".bsp")
    if CurrentMap ~= false and CurrentMap[1] then return CurrentMap[1]["wsid"] end
    for _, v in ipairs(engine.GetAddons()) do
        if v.Mounted == false then continue end
        local files, _ = file.Find("maps/*.bsp", v.title)
        for _, bspname in ipairs(files) do
            if bspname == mapname .. ".bsp" then return v.wsid end
        end
    end
end

-- Make map icons table
sql.QueryTyped("CREATE TABLE IF NOT EXISTS map_icons (mapID TEXT UNIQUE, MapPreviewUrl TEXT )")
util.AddNetworkString("GetMapIcon")
util.AddNetworkString("SendMapIconRequest")
local VanillaMapUrls = {
    -- there was a workshop addon for this i think. should use that later
    ["gm_construct"] = "https://i1.sndcdn.com/artworks-VywksQLWOwlBgiIh-0DHYbg-t1080x1080.jpg",
    ["gm_flatgrass"] = "https://gcdn.thunderstore.io/live/repository/icons/localpcnerd-gm_flatgrass-1.1.0.png.256x256_q95_crop.png",
}

function GetMapPreviewUrl(mapid, callback)
    if VanillaMapUrls[game.GetMap()] then --
        callback(VanillaMapUrls[game.GetMap()])
        return
    end

    if not mapid or mapid == "" then --
        callback(nil)
        return
    end

    if MapPreviewUrl and #MapPreviewUrl ~= 0 then
        callback(MapPreviewUrl)
        return
    end

    CurrentMapWSID = GetMapWSID(game.GetMap())
    local MapQuery = sql.QueryTyped("SELECT MapPreviewUrl FROM map_icons WHERE mapID = ?", CurrentMapWSID)
    if not isbool(MapQuery) and MapQuery[1] then --
        MapPreviewUrl = MapQuery[1]["MapPreviewUrl"]
        callback(MapPreviewUrl)
    elseif not MapQuery[1] then
        local Admins = {}
        for _, ply in player.Iterator() do
            if ply:IsAdmin() then Admins[#Admins + 1] = ply end
        end

        if #Admins > 0 then --
            print("Map preview url missing. Deferring to random admin.") -- this is a very bad idea. should be replaced with something better later
            net.Start("SendMapIconRequest")
            net.WriteString(CurrentMapWSID)
            local Admin = Admins[math.random(1, #Admins)]
            net.Send(Admin)
            print("Sent to " .. Admin:Nick())
            --
            net.Receive("GetMapIcon", function(len, ply)
                if not ply:IsAdmin() then --
                    print(ply:Nick() .. " tried to set map icon while not being admin.")
                    return
                end

                print("Getting map icon from " .. ply:Nick())
                MapPreviewUrl = net.ReadString()
                if MapPreviewUrl and #MapPreviewUrl > 0 then --
                    print("MapPreviewUrl set to: " .. MapPreviewUrl)
                    sql.QueryTyped("INSERT OR REPLACE INTO map_icons ( mapID, MapPreviewUrl ) VALUES ( ?, ? )", CurrentMapWSID, MapPreviewUrl)
                end

                callback()
                return
            end)
        end
    end
end

hook.Add("InitPostEntity", "SetServerName", function()
    -- 
    RunConsoleCommand("hostname", "raven's awesome pvp 128 tick" .. ((game.GetMap() and " @ " .. game.GetMap()) or ""))
end)