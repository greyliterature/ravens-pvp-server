if SERVER then AddCSLuaFile("autorun/shared/ulx_mapvote.lua") end
-- https://github.com/CFC-Servers/map_vote/blob/5e6f3bf828dcfc17c9bfd3ad6a460e5ea0670ed5/lua/mapvote/server/modules/rtv.lua#L4
hook.Add("InitPostEntity", "RemoveULXVotemap", function()
    if SERVER then
        if not ULib or not ulx then return end
        for k, v in pairs(ulx.cmdsByCategory["Voting"]) do
            if v.cmd == "ulx votemap" then ulx.cmdsByCategory["Voting"][k] = nil end
        end

        ULib.removeSayCommand("!votemap")
    end

    include("autorun/shared/ulx_mapvote.lua")
end)

local debugvgui = false
--
local mapvote_colortable = nil
if CLIENT and debugvgui == true then
    mapvote_colortable = {}
    mapvote_colortable.color_red = Color(255, 0, 0)
    mapvote_colortable.color_blue = Color(0, 0, 255)
    mapvote_colortable.color_yellow = Color(255, 255, 0)
    mapvote_colortable.color_transparentishpurple = Color(255, 0, 255, 0)
end

if SERVER then
    MapVote = {
        IsInProgress = false,
        DefaultDuration = 3630,
        CurrentEndDate = 0,
        Config = {
            BlacklistedMaps = {
                ["test_hardware"] = true,
            }
        },
        AutoRTVTime = 3630,
        VoteCancelRateLimit = 0.1,
        VoteCancelRatio = 0.75,
        PlayerVotes = {},
        PlayerSkipVotes = {}
    }

    SetGlobal3("Int", "MapVote_VoteCancelRatio", MapVote.VoteCancelRatio)
    function MapVote.StartVote(time)
        local TimeString = os.date("%H:%M:%S", os.time())
        print("MapVote: Starting at " .. CurTime() .. ", " .. TimeString)
        time = time or MapVote.DefaultDuration
        local EndDate = CurTime() + time
        timer.Create("MapVote_VoteFinishTimer", time, 1, function()
            if not MapVote.IsInProgress then return end
            MapVote.FinishVote()
            return
        end)

        MapVote.CurrentEndDate = EndDate
        MapVote.IsInProgress = true
        MapVote.SendMapList()
        MapVote.SendVoteStatus()
    end

    timer.Simple(0, function() MapVote.StartVote() end)
    function MapVote.SetAutoRTVTimer(time)
        time = time or MapVote.AutoRTVTime
        local NiceTime = string.NiceTime(time)
        timer.Create("MapVote_AutoRTVTimer", time, 0, function()
            if MapVote.IsInProgress == true then -- in case someone configs it stupidly
                print("MapVote: Map vote already in progress, not autoRTVing")
                return
            end

            PrintMessage(HUD_PRINTTALK, "Changing maps as we've been on the same map for " .. NiceTime)
            MapVote.StartVote()
        end)

        print("MapVote: Made AutoRTVTimer, time: " .. NiceTime)
    end

    if MapVote.AutoRTVTime then
        print("yea")
        MapVote.SetAutoRTVTimer()
    end

    --[[
    local VoterTestTable = {
        ["Bob"] = "gm_construct",
        ["Billy"] = "gm_construct",
        ["Joe"] = "gm_flatgrass",
        ["Rachel"] = "gm_flatgrass",
        ["Johny"] = "test_hardware"
    }
    --]]
    function MapVote.GetWinningMap() -- this is inefficient (but it doesn't really matter)
        local VoterList = VoterTestTable or MapVote.GetVoterList()
        if table.Count(VoterList) == 0 then
            print("MapVote: GetWinningMap(): no one voted!!!")
            return
        end

        local Scores = {}
        for _, mapname in pairs(VoterList) do
            Scores[mapname] = (Scores[mapname] or 0) + 1
        end

        local RankedScores = {}
        for mapname, score in pairs(Scores) do
            RankedScores[#RankedScores + 1] = {
                mapname = mapname,
                score = score
            }
        end

        table.sort(RankedScores, function(a, b)
            --
            return a.score > b.score
        end)

        local WinningMaps = {}
        local HighestScore = RankedScores[1].score
        PrintTable(RankedScores)
        for i = 1, #RankedScores do -- allow ties
            local mapname = RankedScores[i].mapname
            local score = RankedScores[i].score
            if score < HighestScore then break end
            WinningMaps[#WinningMaps + 1] = mapname
        end
        return WinningMaps
    end

    function MapVote.ResetVotes()
        MapVote.PlayerVotes = {}
    end

    util.AddNetworkString("MapVote_VoteEnded")
    function MapVote.EndVoteEarly()
        MapVote.IsInProgress = false
        net.Start("MapVote_VoteEnded")
        net.Broadcast()
        timer.Remove("MapVote_VoteFinishTimer")
    end

    function MapVote.CancelVote() -- https://github.com/greyliterature/map_vote/blob/3e18c15656596f705442bc47dc6283f0027ac770/lua/mapvote/server/modules/map_vote.lua#L107-L119
        if not MapVote.IsInProgress then return end
        MapVote.ResetVotes()
        MapVote.EndVoteEarly()
        PrintMessage(HUD_PRINTTALK, "Map vote finished because " .. table.Count(MapVote.PlayerSkipVotes) .. " players voted to cancel")
    end

    function MapVote.FinishVote()
        local PlayableMaps = MapVote.GetMapList()
        local FallbackMap = PlayableMaps[math.random(1, #PlayableMaps)]
        local WinningMaps = MapVote.GetWinningMap() -- its a table, since there can be ties
        local RandomWinningMap = (WinningMaps and WinningMaps[math.random(1, #WinningMaps)]) or nil
        print("MapVote: " .. ((RandomWinningMap == nil and "Falling back ") or "Changing ") .. "map to " .. (RandomWinningMap or FallbackMap))
        --RunConsoleCommand("changelevel" .. RandomWinningMap)
    end

    MapVote._maps = nil
    function MapVote.GetMapList() -- from cfc version
        if MapVote._maps then -- this return might be a bad idea if there are hotloaded maps, we will hve to see
            return MapVote._maps
        end

        local maps = file.Find("maps/*.bsp", "GAME") -- make this include hotloaded too, and make that its own category
        for i, map in ipairs(maps) do
            local Subbed = map:sub(1, -5) -- strip .bsp
            if MapVote.Config.BlacklistedMaps[Subbed] then
                print("Not adding " .. map .. " to map list, blacklisted")
                continue
            end

            maps[i] = Subbed
        end

        MapVote._maps = maps
        return maps
    end

    util.AddNetworkString("MapVote_SendMapList")
    function MapVote.SendMapList(ply)
        local maps = MapVote.GetMapList()
        net.Start("MapVote_SendMapList")
        net.WriteTable(maps)
        net[(ply and "Send") or "Broadcast"](ply)
    end

    util.AddNetworkString("MapVote_VoteStarted")
    function MapVote.SendVoteStatus(ply)
        net.Start("MapVote_VoteStarted")
        net.WriteFloat(MapVote.CurrentEndDate)
        net[(ply and "Send") or "Broadcast"](ply)
    end

    function MapVote.SendCancellers(ply)
        net.Start("MapVote_SendCancellers")
        net.WriteUInt(table.Count(MapVote.PlayerSkipVotes), MAX_PLAYER_BITS)
        net.Send(ply)
    end

    hook.Add("InitPostEntityStarted", "SendMapVoteToNewPlayers", function(ply, _)
        if MapVote.IsInProgress == true then
            MapVote.SendMapList(ply)
            MapVote.SendVoteStatus(ply)
            MapVote.SendCancellers(ply)
            return
        end
    end)

    --[[-------------------------------------------------------
        SV NET STUFF
    ---------------------------------------------------------]]
    local PLAYERMETA = FindMetaTable("Player")
    function MapVote.GetVoterList()
        return MapVote.PlayerVotes
    end

    util.AddNetworkString("MapVote_votemap_announcement")
    function PLAYERMETA:VoteForMap(MapName, RemoveVote)
        if not MapName then
            -- when a bot is kicked without voting for a map, this function errors. it is functionally 
            -- the same by returning anyway, because if the voter didnt vote, there is nothing to remove
            -- so we dont need any special handling
            return
        end

        local CanVoteForMap = hook.Run("MapVote_CanPlayerVoteForMap", self, MapName, RemoveVote)
        if CanVoteForMap == false then return end
        if MapVote.Config.BlacklistedMaps[MapName] then
            error(self:Nick() .. " tried voting for " .. MapName .. ", which is blacklisted")
            return
        end

        if MapVote.IsInProgress ~= true then
            error(self:Nick() .. " tried voting for " .. MapName .. " but there is not vote in progress")
            return
        end

        hook.Run("MapVote_PlayerVotedForMap", self, MapName, RemoveVote)
        MapVote.PlayerVotes[self] = (RemoveVote == false and MapName) or nil
        print(self:Nick() .. ((RemoveVote == false and " voted for ") or " cleared vote of ") .. MapName)
        net.Start("MapVote_votemap_announcement")
        net.WriteBool(RemoveVote)
        net.WriteString(MapName)
        net.WritePlayer(self)
        net.Broadcast()
    end

    hook.Add("PlayerDisconnected", "RemoveVoteOnDisconnect", function(ply)
        ply:VoteForMap(MapVote.PlayerVotes[ply], true)
        return
    end)

    local MapVoteRateLimit = include("autorun/shared/vguilogic_smapvoteicon.lua")
    util.AddNetworkString("rv_mapvote_vote_map")
    local PlayerVoteTimes = {}
    net.Receive("rv_mapvote_vote_map", function(_, ply)
        PlayerVoteTimes[ply] = PlayerVoteTimes[ply] or 0
        if PlayerVoteTimes[ply] + MapVoteRateLimit > CurTime() then
            print("MapVote: " .. ply:Nick() .. " vote rate limited")
            return
        end

        PlayerVoteTimes[ply] = CurTime()
        local RemoveVote = net.ReadBool()
        local MapName = net.ReadString()
        ply:VoteForMap(MapName, RemoveVote)
    end)

    util.AddNetworkString("MapVote_VoteToCancel_Announcement")
    util.AddNetworkString("MapVote_VoteToCancel")
    local PlayerSkipVotesRateLimitTracking = {}
    net.Receive("MapVote_VoteToCancel", function(_, ply)
        if not MapVote.IsInProgress then return end
        PlayerSkipVotesRateLimitTracking[ply] = PlayerSkipVotesRateLimitTracking[ply] or 0
        if MapVote.VoteCancelRateLimit + PlayerSkipVotesRateLimitTracking[ply] > CurTime() then return end
        PlayerSkipVotesRateLimitTracking[ply] = CurTime()
        MapVote.PlayerSkipVotes[ply] = (MapVote.PlayerSkipVotes[ply] == nil and true) or nil -- toggle their cancel
        print("MapVote: " .. ply:Nick() .. ((MapVote.PlayerSkipVotes[ply] == true and " un") or " ") .. "voted to cancel the vote")
        if table.Count(MapVote.PlayerSkipVotes) > MapVote.VoteCancelRatio * player.GetCount() then --
            MapVote.CancelVote()
        end

        net.Start("MapVote_VoteToCancel_Announcement")
        net.WriteUInt((MapVote.PlayerSkipVotes[ply] and 1) or 0, 1)
        net.Broadcast()
    end)
elseif CLIENT then
    if MapVote and IsValid(MapVote.Panel) then -- for autorefresh
        MapVote.Panel:Remove()
    end

    MapVote = {
        NumberOfCancellers = 0,
        VoteCancelRatio = 0.75,
    }

    --[[-------------------------------------------------------
        LOGIC / HELPER STUFF
    ---------------------------------------------------------]]
    function MapVote.GetMapList()
        return MapVote.maps
    end

    --[[-------------------------------------------------------
        NET STUFF
    ---------------------------------------------------------]]
    local PREFIX_NUM_CHARS = string.len("MapVote_")
    hook.Add("Global3VarChanged", "ConfigNetworking", function(VarType, VarIndex, VarNewValue)
        if string.sub(VarIndex, 1, PREFIX_NUM_CHARS) ~= "MapVote_" then return end
        local subbed = string.sub(VarIndex, PREFIX_NUM_CHARS + 1)
        print("yepp", subbed, "HI")
        MapVote[subbed] = tonumber(VarNewValue) -- should tonumber this with an if statement probably
    end)

    net.Receive("MapVote_VoteStarted", function(_, _)
        local EndDate = net.ReadFloat()
        MapVote.StartVote(EndDate)
        print("HI!!!")
        return
    end)

    net.Receive("MapVote_SendMapList", function(_, _)
        print("HII!!")
        local maps = net.ReadTable() -- make this not bad later
        print("got maps: ")
        MapVote.maps = maps
    end)

    net.Receive("MapVote_VoteEnded", function(_, _)
        MapVote.CancelVote()
        return
    end)

    net.Receive("MapVote_VoteToCancel_Announcement", function(_, _)
        local uint = net.ReadUInt(1)
        local increment = (uint == 0 and -1) or 1
        MapVote.IncrementCancelCheckboxes(increment)
        MapVote.UpdateCheckBoxes()
    end)

    net.Receive("MapVote_SendCancellers", function(_, _)
        local NumCancellers = net.ReadUInt(MAX_PLAYER_BITS)
        MapVote.NumberOfCancellers = NumCancellers
        MapVote.UpdateCheckBoxes()
    end)

    --[[-------------------------------------------------------
       MISC VGUI STUFF
    ---------------------------------------------------------]]
    local fontCreated = {}
    function MapVote.iconFont(size) -- https://github.com/greyliterature/map_vote/blob/3e18c15656596f705442bc47dc6283f0027ac770/lua/mapvote/client/vgui/map_icon.lua#L6
        -- no smaller  than 10
        size = math.max(size, 10)
        if fontCreated["MapVote_MapIcon" .. size] then return "MapVote_MapIcon" .. size end
        local name = "MapVote_MapIcon" .. size
        surface.CreateFont(name, {
            font = "Roboto",
            size = size,
            weight = 600,
            antialias = true,
            shadow = true,
            outline = true,
        })

        fontCreated[name] = true
        return name
    end

    --[[-------------------------------------------------------
        FRAME STUFF
    ---------------------------------------------------------]]
    function MapVote.FinishVote(mapIndex)
        if not IsValid(MapVote.Panel) then return end
        MapVote.Panel:SetMinimized(false)
        MapVote.Panel:SetVisible(true)
        --MapVote.Panel.voteArea:Flash( mapIndex )
    end

    function MapVote.CancelVote()
        if IsValid(MapVote.Panel) then MapVote.Panel:Remove() end
        hook.Run("MapVote_VoteCancelled")
    end

    -- the map networking would no longer be needed with this categories table, should only network x number of maps that aren't categorized
    local MapToCategory = {
        ["gm_c17map"] = "MyCoolCategory1",
        ["fof_city17"] = "MyCoolCategory2"
    }

    function MapVote.VoteToCancel()
        net.Start("MapVote_VoteToCancel")
        net.SendToServer()
    end

    function MapVote.MakeCheckBoxes(parent, numcheckboxes)
        if not IsValid(parent) then
            print("return me sad")
            return
        end

        print("YES MAKING!!")
        local CheckBoxSize = 32
        local CheckBoxSpacing = ScrW() * 0.0075
        local CheckBoxGrid = vgui.Create("SGrid", parent)
        CheckBoxGrid:SetSize(parent:GetWide(), CheckBoxSize)
        CheckBoxGrid:SetPos(0, (parent:GetTall() - CheckBoxSize) * 0.5)
        CheckBoxGrid:SetRowHeight(CheckBoxSize)
        CheckBoxGrid:SetOverallAlignment(SGRID_ALIGN_LEFT)
        CheckBoxGrid:SetBackgroundColor(color_transparent)
        MapVote.CheckBoxes = MapVote.CheckBoxes or {}
        for i = #MapVote.CheckBoxes, 1, -1 do
            if IsValid(MapVote.CheckBoxes[i]) then
                MapVote.CheckBoxes[i]:Remove()
                MapVote.CheckBoxes[i] = nil
            end
        end

        MapVote.CheckBoxes = {}
        local NumPlayers = MapVote.PlayerCount
        for i = 1, numcheckboxes or NumPlayers do
            local SpacerPanel = vgui.Create("DPanel", parent)
            SpacerPanel:SetSize(CheckBoxSpacing)
            CheckBoxGrid:AddItem(SpacerPanel)
            function SpacerPanel.Paint(_, _, _)
            end

            local CheckBox = vgui.Create("SCheckBox", parent)
            -- this will break at about 21 players, 
            -- the grid has to be resized vertically to account for more players
            -- however, i dont care, as it wont affect me
            CheckBox:SetBool((i <= MapVote.NumberOfCancellers and true) or false)
            CheckBox:SetWide(CheckBoxSize)
            CheckBox:SetFunction(nil)
            MapVote.CheckBoxes[#MapVote.CheckBoxes + 1] = CheckBox
            CheckBoxGrid:AddItem(CheckBox)
        end
        --MapVote.CheckBoxGrid = CheckBoxGrid
    end

    function MapVote.UpdateCheckBoxes()
        if not MapVote.CheckBoxes or #MapVote.CheckBoxes == 0 then return end
        for i = 1, #MapVote.CheckBoxes do
            if i <= MapVote.NumberOfCancellers then --
                MapVote.CheckBoxes[i]:SetBool(true)
            else
                MapVote.CheckBoxes[i]:SetBool(false)
            end
        end
    end

    MapVote.PlayerCount = player.GetCount()
    gameevent.Listen("player_disconnect")
    gameevent.Listen("player_connect")
    hook.Add("player_disconnect", "UpdateCheckboxes", function()
        print("WAN")
        MapVote.PlayerCount = MapVote.PlayerCount - 1
        MapVote.MakeCheckBoxes(MapVote.BottomHeader)
    end)

    hook.Add("player_activate", "UpdateCheckboxes", function()
        print("TOO")
        MapVote.PlayerCount = MapVote.PlayerCount + 1
        MapVote.MakeCheckBoxes(MapVote.BottomHeader)
    end)

    MapVote.UpdateCheckBoxes()
    function MapVote.IncrementCancelCheckboxes(increment)
        MapVote.NumberOfCancellers = MapVote.NumberOfCancellers + increment
    end

    local DropDowns = {} -- "category" = panel
    local Voters = {}
    function MapVote.ChangeVote(ply, mapIndex, voteMult)
        if not IsValid(ply) then return end
        if not IsValid(MapVote.Panel) then return end
        local identifier = ply:SteamID64()
        if ply:IsBot() then
            -- dont use steamid object for bots to allow testing UI locally
            identifier = ply
        end

        --if IsValid(MapVote.Panel.OpenGrid) then MapVote.Panel.OpenGrid:SetVote(identifier, mapIndex, voteMult) end
        local currentMaps = MapVote.GetMapList()
        local mapname = currentMaps[mapIndex]
        local category = MapToCategory[mapname] or "Uncategorized"
        local CategoryDropDown = DropDowns[category]
        print(mapIndex, "HI!")
        local PlayersLastCategoryDropDown = Voters[identifier]
        if IsValid(PlayersLastCategoryDropDown) then PlayersLastCategoryDropDown:RemoveVote(identifier) end
        Voters[identifier] = CategoryDropDown
        CategoryDropDown:SetVote(identifier, mapIndex, voteMult)
    end

    --@ returns n amount of rows required to fit x number of items under constraint y width
    local function CalculateRowCount(squaresize, width, numitems)
        local columncount = math.floor(width / squaresize)
        columncount = math.max(columncount, 1)
        local rowcount = math.ceil(numitems / columncount)
        return rowcount
    end

    -- col
    local color_cod_light_black = Color(35, 35, 35, 254)
    local color_cod_black = Color(0, 0, 0, 254)
    local color_cod_lighter_black = Color(0, 0, 0, 200)
    local color_transparentish_black = Color(0, 0, 0, 155)
    --
    local SixtyFour = ScrH() * 0.059259999 -- basically 64
    local IconSize = ScrH() * 0.15
    local RowGap = ScrH() * 0.005
    local HeaderSize = ScrH() * 0.05
    function MapVote.StartVote(EndTime)
        print("OPEN")
        MapVote.EndTime = EndTime -- is this necessary?
        if IsValid(MapVote.Panel) then MapVote.Panel:Remove() end
        local ScreenPanel = vgui.Create("DPanel")
        ScreenPanel:SetSize(ScrW(), ScrH())
        ScreenPanel:SetMouseInputEnabled(true)
        ScreenPanel:MakePopup(true)
        ScreenPanel:SetBackgroundColor(color_transparentish_black)
        function ScreenPanel.OnMousePressed(self, _)
            self:Remove()
        end

        timer.Create("AutoRemoveVotePanel", EndTime - CurTime(), 1, function()
            if not IsValid(ScreenPanel) then return end
            print("removing")
            ScreenPanel:Remove()
        end)

        MapVote.Panel = ScreenPanel
        local OuterPanel = vgui.Create("DPanel", ScreenPanel)
        -- always make outer panel hold 6 icons + 2 rowgaps to account for horiz sgrid padding 
        -- and 2 headers
        OuterPanel:SetSize(IconSize * 6 + RowGap * 5 + RowGap * 2, ScrH() * 0.5 + HeaderSize * 2)
        OuterPanel:Center()
        if debugvgui == true then --
            OuterPanel:SetPos(math.random(0, ScrW()), math.random(0, ScrH()))
        end

        function OuterPanel.Paint(_, _, _)
        end

        --OuterPanel:MakePopup()
        local TopHeader = vgui.Create("DPanel", OuterPanel)
        TopHeader:Dock(TOP)
        TopHeader:SetTall(HeaderSize)
        function TopHeader.Paint(_, w, h)
            local TimeString = os.date("%M:%S", EndTime - CurTime())
            surface.SetDrawColor(color_cod_black)
            surface.DrawRect(0, 0, w, h)
            draw.SimpleText(TimeString, MapVote.iconFont(40), w * 0.02, h * 0.5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        local ScrollPanel = vgui.Create("DScrollPanel", OuterPanel)
        --ScrollPanel:MakePopup()
        ScrollPanel:Dock(TOP)
        ScrollPanel:SetWide(OuterPanel:GetWide())
        ScrollPanel:SetTall(ScrH() * 0.5)
        -- SCROLLPANELS HEIGHT IS WRONG. there is a large margin below the bottom dropdown, which is ugly
        local VBar = ScrollPanel:GetVBar()
        function VBar.Paint(_, _, _)
        end

        function VBar.btnGrip.Paint(_, w, h)
        end

        function VBar.btnDown.Paint(_, w, h)
        end

        function VBar.btnUp.Paint(_, w, h)
        end

        VBar:SetWide(0) -- fixes annoying docking issues
        local VoteFrame = vgui.Create("DPanel", ScrollPanel)
        VoteFrame:SetSize(ScrollPanel:GetWide(), ScrH() * 0.7)
        VoteFrame:SetY(0, 0)
        VoteFrame:CenterHorizontal()
        VoteFrame:Dock(FILL)
        --VoteFrame:MakePopup()
        function VoteFrame.Paint(_, w, h)
            if debugvgui == true then
                surface.SetDrawColor(mapvote_colortable.color_blue)
                surface.DrawRect(0, 0, w, h)
            end

            surface.SetDrawColor(color_cod_light_black)
            surface.DrawRect(0, 0, w, h)
        end

        local TopDropDock = ScrH() * 0.01
        local Categories = {}
        for mapIndex, mapName in ipairs(MapVote.GetMapList()) do
            local category = MapToCategory[mapName] or "Uncategorized"
            Categories[category] = Categories[category] or {}
            Categories[category][#Categories[category] + 1] = mapName
        end

        DropDowns = {}
        for mapIndex, mapName in ipairs(MapVote.GetMapList()) do
            local category = MapToCategory[mapName] or "Uncategorized"
            if not DropDowns[category] then
                local DropDown = vgui.Create("SDropDown", VoteFrame)
                DropDown:Dock(TOP)
                DropDown:SetWide(VoteFrame:GetWide())
                DropDown:DockMargin(0, 0, 0, TopDropDock)
                DropDown:SetTall(SixtyFour * 0.5)
                print(DropDown, "HIIIIIIIIII")
                DropDown:SetCategoryTitle(category)
                DropDown:SetBackgroundColor(color_cod_lighter_black)
                print("HII")
                DropDown:SetMaps(Categories[category])
                local RowCount = CalculateRowCount(IconSize + RowGap, DropDown:GetWide(), table.Count(Categories[category]))
                local ExpandedSize = RowCount * IconSize + (RowCount - 1) * RowGap + RowGap
                DropDown:SetExpandedSize(ExpandedSize)
                DropDowns[category] = DropDown
                function DropDown:FullyExpandedHook()
                    if IsValid(self.Grid) then return end
                    local Grid = vgui.Create("SGrid", DropDown)
                    Grid:SetOverallAlignment(SGRID_ALIGN_LEFT)
                    Grid:DockMargin(RowGap, RowGap, 0, RowGap)
                    Grid:SetWide(DropDown:GetWide())
                    Grid:Dock(TOP)
                    self.Grid = Grid
                    function Grid.Paint(_, w, h)
                        if debugvgui == true then
                            surface.SetDrawColor(mapvote_colortable.color_red)
                            surface.DrawRect(0, 0, w, h)
                        end
                    end

                    for mapindex, mapname in ipairs(Categories[category]) do
                        print("HI", mapindex, mapname)
                        if (MapToCategory[mapname] or "Uncategorized") ~= category then -- this is inefficient but it works, whatever
                            continue
                        end

                        print(mapname, "HAAHAH")
                        local SpacerPanel = vgui.Create("DPanel", row)
                        function SpacerPanel.Paint(_, w, h)
                            if debugvgui == true then
                                surface.SetDrawColor(mapvote_colortable.color_yellow)
                                surface.DrawRect(0, 0, w, h)
                            end
                        end

                        SpacerPanel:SetWide(RowGap)
                        local VoteIcon = vgui.Create("SVoteIcon", Grid) -- requires parent only because of autorefresh being annoying
                        VoteIcon:SetMap(mapname)
                        VoteIcon:GetThumbnail()
                        function VoteIcon.DoClick(_)
                            print("hi")
                            MapVote.Net.changeVote(mapIndex)
                        end

                        self.maps[mapname].panel = VoteIcon
                        --VoteIcon:DownloadMap()
                        VoteIcon:SetSize(IconSize, IconSize)
                        Grid:SetRowHeight(IconSize)
                        Grid:AddItem(VoteIcon)
                        Grid:AddItem(SpacerPanel)
                    end

                    Grid:Show()
                end

                function DropDown:FullyMinimizedHook()
                    if IsValid(self.Grid) then
                        print("Removed")
                        self.Grid:Remove()
                    end
                end
                --[[--]]
            end
        end

        local BottomHeader = vgui.Create("DPanel", OuterPanel)
        BottomHeader:Dock(TOP)
        BottomHeader:SetTall(HeaderSize)
        BottomHeader:SetWide(OuterPanel:GetWide())
        function BottomHeader.Paint(_, w, h)
            surface.SetDrawColor(color_cod_black)
            surface.DrawRect(0, 0, w, h)
        end

        MapVote.BottomHeader = BottomHeader
        MapVote.MakeCheckBoxes(BottomHeader, math.ceil(player.GetCount() * MapVote.VoteCancelRatio))
        function ScreenPanel.OnKeyCodePressed(self, keyCode)
            if keyCode == KEY_SPACE then
                MapVote.VoteToCancel()
                print("ye")
            end
        end

        hook.Run("MapVote_VoteStarted")
        hook.Run("MapVote_VotePanelOpened")
    end
end
