local function GetMapWSID(mapname) -- copy pasted from https://github.com/greyliterature/ravens-pvp-server/blob/f8cac2289072ca737d27308025075ff8d983dfa6/addons/rv_maphotload/lua/autorun/server/rv_maphotload.lua#L1-L11
    local CurrentMap = sql.QueryTyped("SELECT wsid FROM hotloaded_maps WHERE mapname = ?", mapname .. ".bsp")
    if CurrentMap ~= false and CurrentMap[1] then return CurrentMap[1]["wsid"] end
    for _, v in ipairs(engine.GetAddons()) do
        if v.Mounted == false then continue end
        local files, _ = file.Find("maps/*.bsp", v.title)
        for _, bspname in ipairs(files) do
            print(bspname)
            if bspname == mapname .. ".bsp" then return v.wsid end
        end
    end
end

local MapVoteInProgress = true -- make this do dynamic later
local AlreadyRequestedWSIDs = {}
util.AddNetworkString("MapVote_request_map_wsid")
util.AddNetworkString("MapVote_request_map_wsid_response")
net.Receive("MapVote_request_map_wsid", function(len, ply)
    if MapVoteInProgress == false then return end
    local mapname = net.ReadString() -- THIS SHOULD TAKE A CATEGORY AS THE ARGUMENT, SO PEOPLE CANT SPAM REQUEST EVERY SINGLE MAP, AND HAVE A CATEGORY RATE LIMIT
    AlreadyRequestedWSIDs[ply] = AlreadyRequestedWSIDs[ply] or {}
    if AlreadyRequestedWSIDs[ply][mapname] then -- dont lag the server if the player already knows the wsid
        return
    end

    AlreadyRequestedWSIDs[ply][mapname] = true
    local wsid = GetMapWSID(mapname)
    print(wsid, mapname, "HIII")
    if wsid == nil then --
        print("Failed to get wsid of " .. mapname)
    end

    net.Start("MapVote_request_map_wsid_response")
    net.WriteString(mapname)
    -- this is unnecessary but i dont feel like writing a system for predicting this clientside, shouldnt be expensive enough to care
    net.WriteString(wsid or "")
    net.Send(ply)
end)
