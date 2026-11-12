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
        DefaultDuration = 15,
        CurrentEndDate = 0,
        Config = {
            BlacklistedMaps = {
                ["test_hardware"] = true,
            }
        }
    }

    function MapVote.StartVote(time)
        print("MapVote: Starting " .. CurTime())
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

    hook.Add("InitPostEntityStarted", "SendMapVoteToNewPlayers", function(ply, _)
        if MapVote.IsInProgress == true then
            MapVote.SendMapList(ply)
            MapVote.SendVoteStatus(ply)
            return
        end
    end)

    --[[-------------------------------------------------------
        SV NET STUFF
    ---------------------------------------------------------]]
    local PLAYERMETA = FindMetaTable("Player")
    local PlayerVotes = {}
    function MapVote.GetVoterList()
        return PlayerVotes
    end

    util.AddNetworkString("MapVote_votemap_announcement")
    function PLAYERMETA:VoteForMap(MapName, RemoveVote)
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
        PlayerVotes[self] = (RemoveVote == false and MapName) or nil
        print(self:Nick() .. ((RemoveVote == false and " voted for ") or " cleared vote of ") .. MapName)
        net.Start("MapVote_votemap_announcement")
        net.WriteBool(RemoveVote)
        net.WriteString(MapName)
        net.WritePlayer(self)
        net.Broadcast()
    end

    hook.Add("PlayerDisconnected", "RemoveVoteOnDisconnect", function(ply)
        ply:VoteForMap(PlayerVotes[ply], true)
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

    timer.Simple(0, function() MapVote.StartVote() end)
elseif CLIENT then
    if MapVote and IsValid(MapVote.Panel) then -- for autorefresh
        MapVote.Panel:Remove()
    end

    MapVote = {}
    --[[-------------------------------------------------------
        LOGIC / HELPER STUFF
    ---------------------------------------------------------]]
    function MapVote.GetMapList()
        return MapVote.maps
    end

    --[[-------------------------------------------------------
        NET STUFF
    ---------------------------------------------------------]]
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
    --
    local SixtyFour = ScrH() * 0.059259999 -- basically 64
    local IconSize = ScrH() * 0.15
    local RowGap = ScrH() * 0.005
    local HeaderSize = ScrH() * 0.05
    function MapVote.StartVote(endTime)
        print("OPEN")
        MapVote.EndTime = endTime
        if IsValid(MapVote.Panel) then
            print("yep")
            MapVote.Panel:Remove()
        end

        local OuterPanel = vgui.Create("DPanel")
        -- always make outer panel hold 6 icons + 2 rowgaps to account for horiz sgrid padding 
        -- and 2 headers
        OuterPanel:SetSize(IconSize * 6 + RowGap * 5 + RowGap * 2, ScrH() * 0.5 + HeaderSize * 2)
        OuterPanel:Center()
        if debugvgui == true then --
            OuterPanel:SetPos(math.random(0, ScrW()), math.random(0, ScrH()))
        end

        function OuterPanel.Paint(_, _, _)
        end

        OuterPanel:MakePopup()
        local TopHeader = vgui.Create("DPanel", OuterPanel)
        TopHeader:Dock(TOP)
        TopHeader:SetTall(HeaderSize)
        function TopHeader.Paint(_, w, h)
            surface.SetDrawColor(color_cod_black)
            surface.DrawRect(0, 0, w, h)
        end

        MapVote.Panel = OuterPanel
        local ScreenPanel = vgui.Create("DScrollPanel", OuterPanel)
        --ScreenPanel:MakePopup()
        ScreenPanel:Dock(TOP)
        ScreenPanel:SetWide(OuterPanel:GetWide())
        ScreenPanel:SetTall(ScrH() * 0.5)
        -- SCREENPANELS HEIGHT IS WRONG. there is a large margin below the bottom dropdown, which is ugly
        local VBar = ScreenPanel:GetVBar()
        function VBar.Paint(_, _, _)
        end

        function VBar.btnGrip.Paint(_, w, h)
        end

        function VBar.btnDown.Paint(_, w, h)
        end

        function VBar.btnUp.Paint(_, w, h)
        end

        VBar:SetWide(0) -- fixes annoying docking issues
        local VoteFrame = vgui.Create("DPanel", ScreenPanel)
        VoteFrame:SetSize(ScreenPanel:GetWide(), ScrH() * 0.7)
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
        function BottomHeader.Paint(_, w, h)
            surface.SetDrawColor(color_cod_black)
            surface.DrawRect(0, 0, w, h)
        end

        hook.Run("MapVote_VoteStarted")
        hook.Run("MapVote_VotePanelOpened")
    end
end
