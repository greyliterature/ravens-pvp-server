local debugvgui = true
--
local CalculateRowCount = nil
local mapvote_colortable = nil
if CLIENT then -- simplegrid
    --@ returns n amount of rows required to fit x number of items under constraint y width
    CalculateRowCount = function(squaresize, width, numitems)
        local columncount = math.floor(width / squaresize)
        local rowcount = math.ceil(numitems / columncount)
        return rowcount
    end

    if debugvgui == true then
        mapvote_colortable = {}
        mapvote_colortable.color_red = Color(255, 0, 0)
        mapvote_colortable.color_blue = Color(0, 0, 255)
        mapvote_colortable.color_yellow = Color(255, 255, 0)
        mapvote_colortable.color_transparentishpurple = Color(255, 0, 255, 0)
    end
end

if SERVER then -- SMapvoteIcon
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
    util.AddNetworkString("rv_mapvote_request_map_wsid")
    util.AddNetworkString("rv_mapvote_request_map_wsid_response")
    net.Receive("rv_mapvote_request_map_wsid", function(len, ply)
        if MapVoteInProgress == false then return end
        local mapname = net.ReadString() -- THIS SHOULD TAKE A CATEGORY AS THE ARGUMENT, SO PEOPLE CANT SPAM REQUEST EVERY SINGLE MAP, AND HAVE A CATEGORY RATE LIMIT
        AlreadyRequestedWSIDs[ply] = AlreadyRequestedWSIDs[ply] or {}
        if AlreadyRequestedWSIDs[ply][mapname] then -- dont lag the server if the player already knows the wsid
            return
        end

        AlreadyRequestedWSIDs[ply][mapname] = true
        local wsid = GetMapWSID(mapname)
        print(wsid, mapname, "HIII")
        assert(wsid ~= nil, "Failed to get wsid of " .. mapname)
        net.Start("rv_mapvote_request_map_wsid_response")
        net.WriteString(mapname)
        -- this is unnecessary but i dont feel like writing a system for predicting this clientside, shouldnt be expensive enough to care
        net.WriteString(wsid)
        net.Send(ply)
    end)
elseif CLIENT then
    -- SMapvoteIcon
    local MapsToPanel = {}
    local MapNameToWSID = {}
    local MapMaterials = {}
    --@ panel is for the queue system table to remember
    local function RequestMapWSID(panel, mapname) -- should this be batched? is net messages 1 by 1 sig worse than a large net message? probably
        if MapMaterials[mapname] then
            --print("RET", MapMaterials[mapname])
            panel.MapMaterial = MapMaterials[mapname]
            return
        end

        --[[
            -- this didnt work properly
            if MapNameToWSID[mapname] then -- cached in server response netmessage
                panel.MapMaterial = MapsToPanel[mapname].MapMaterial
                return
            end
            --]]
        MapsToPanel[mapname] = panel
        net.Start("rv_mapvote_request_map_wsid")
        net.WriteString(mapname)
        net.SendToServer()
    end

    local ERROR_DOWNLOADING_MAT = Material("maps/thumb/noicon.png")
    net.Receive("rv_mapvote_request_map_wsid_response", function(_, _)
        local mapname = net.ReadString()
        local wsid = net.ReadString()
        MapNameToWSID[mapname] = wsid
        print("HIIIiii", wsid)
        local MapPanel = MapsToPanel[mapname] -- this should always be valid 
        if not IsValid(MapPanel) then -- fix not being valid because of autorefresh (can be removed later?)
            print("NOT VALID!")
            return
        end

        if MapMaterials[mapname] or wsid == "" then
            print("RET", "AAA")
            MapPanel.Mapmaterial = MapMaterials[mapname]
            return
        end

        --MapMaterials[mapname] = ERROR_DOWNLOADING_MAT
        if MapPanel.MapMaterial then
            print("2")
            return
        end

        if wsid == "" then
            print("SAD!")
            MapPanel.MapMaterial = ERROR_DOWNLOADING_MAT
            return
        end

        steamworks.FileInfo(wsid, function(result)
            -- https://wiki.facepunch.com/gmod/steamworks.Download#example
            steamworks.Download(result.previewid, true, function(name)
                print("got preview image for " .. name .. " " .. mapname .. " " .. wsid)
                local MapMaterial = AddonMaterial(name)
                MapPanel.MapMaterial = AddonMaterial(name)
                MapMaterials[mapname] = MapMaterial
            end)
        end)
    end)

    -- SVoteIcon
    local PANEL = {}
    function PANEL:Init()
        self.Map = nil
        self.WSID = nil -- is this important to store?
        self.MapMaterial = nil
        self:SetMouseInputEnabled(true)
        self.Votes = {}
        self.Grid = vgui.Create("SGrid", self)
        self.Grid:Dock(FILL)
        self.Grid:SetOverallAlignment(SGRID_ALIGN_RIGHT)
        function self.Grid.Paint(_, w, h)
            if debugvgui == true then
                surface.SetDrawColor(mapvote_colortable.color_transparentishpurple)
                surface.DrawRect(0, 0, w, h)
            end
        end

        function self.Grid.OnMousePressed(_, keyCode)
            self:OnMousePressed(keyCode)
        end
    end

    function PANEL:IsMapAlreadyRegistered(mapname) -- this is a helper function that doesn't really belong on the object, but i dont know wheree else to puts it
        return MapMaterials[mapname]
    end

    function PANEL:SetMap(mapname)
        self.Map = mapname
    end

    function PANEL:DownloadMap()
        RequestMapWSID(self, self.Map) -- request, which also handles setting the self.MapMaterial
    end

    function PANEL:Paint(w, h)
        surface.SetDrawColor(color_white)
        surface.SetMaterial(self.MapMaterial or ERROR_DOWNLOADING_MAT)
        surface.DrawTexturedRect(0, 0, w, h)
        if debugvgui == true then -- for showing if the bottom renders fully  
            surface.SetDrawColor(ColorRand())
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end
    end

    local PlayerPanelVotes = {}
    local PlayerAvatars = {}
    function PANEL:RemoveVoteForMap(ply)
        if not self.Votes[ply] then return end
        self.Votes[ply] = nil
        self.Grid:RemoveItem(PlayerAvatars[ply])
        PlayerPanelVotes[ply] = nil
        PlayerAvatars[ply] = nil
    end

    function PANEL:VoteForMap(ply)
        if PlayerPanelVotes[ply] == self then return end
        if PlayerPanelVotes[ply] then --
            PlayerPanelVotes[ply]:RemoveVoteForMap(ply)
        end

        PlayerPanelVotes[ply] = self
        self.Votes[ply] = true
        print(ply, "voted for ", self)
        --self:AddToVoterPanel(ply)
        local IconSize = self:GetTall() * 0.2 -- this shouldnt be static, but ignorable for now
        local Avatar = vgui.Create("AvatarImage", self.Grid)
        Avatar:SetPlayer(ply, 184)
        Avatar:SetWide(IconSize)
        self.Grid:AddItem(Avatar)
        self.Grid:SetRowHeight(IconSize)
        PlayerAvatars[ply] = Avatar
        print(self.Grid)
    end

    function PANEL:Debug_VoteEveryone()
        for _, ply in player.Iterator() do
            self:VoteForMap(ply)
        end
    end

    function PANEL:OnMousePressed(keyCode)
        if keyCode ~= MOUSE_LEFT then return end
        if debugvgui == true then
            self:Debug_VoteEveryone()
            return
        end

        self:VoteForMap(LocalPlayer())
    end

    vgui.Register("SVoteIcon", PANEL, "DPanel")
end

if CLIENT then
    do
        -- SDropDown
        local PANEL = {}
        local TriangHeight = ScrH() * 0.007
        local TriangLength = ScrW() * 0.004
        local offset = 0
        function PANEL:Init()
            --[[
                figure out what selfs to delete here later, copy pasted from when work on mapvote version
            --]]
            self.avatarSize = 50
            self.maps = {}
            self.rows = {}
            self.votes = {}
            self.avatarIconPadding = 1
            self.FullyMinimized = true
            self.Minimizing = false
            --self.MinimizedSize = self:GetTall() + ExponentialOffset
            self.Expanding = false
            self.FullyExpanded = false
            self.ExpandedSize = 400 -- size to hold all maps
            self:SetMouseInputEnabled(true)
            self.DropDownTriangleTable = {{}, {}, {}}
        end

        function PANEL:GetMinimizedSize() -- the size of the top dropdown "frame" (not really a frame but looks like one)
            return self.MinimizedSize
        end

        local ExponentialOffset = 3 -- counter approaching
        function PANEL:SetExpandedSize(tallness)
            self.ExpandedSize = tallness + ExponentialOffset
        end

        function PANEL:PerformLayout(width, tallness)
            self.DropDownTriangleTable[1].x = width * 0.98 + offset
            self.DropDownTriangleTable[2].x = (width - TriangLength) * 0.98 + offset
            self.DropDownTriangleTable[3].x = (width + TriangLength) * 0.98 + offset
            self.DropDownTriangleTable[1].y = (self.MinimizedSize + ExponentialOffset) * 0.5 + TriangHeight * 0.5 + offset
            self.DropDownTriangleTable[2].y = (self.MinimizedSize + ExponentialOffset) * 0.5 - TriangHeight * 0.5 + offset
            self.DropDownTriangleTable[3].y = (self.MinimizedSize + ExponentialOffset) * 0.5 - TriangHeight * 0.5 + offset
        end

        function PANEL:GetExpandedSize()
            return self.ExpandedSize
        end

        function PANEL:SetCategory(Category)
            self.Category = category
        end

        function PANEL:GetCategory()
            return self.Category()
        end

        local function ExpDecay(a, b, decay, dt) -- from styledstrike glide github, cant get link because writing by hand
            -- REPLACE THIS LATER exponentials are annoying to deal with
            return b + (a - b) * math.exp(-decay * dt)
        end

        function PANEL:Think()
            if not self.FirstThink then -- doing this in PANEL:Init() messes up for some reason
                self.FirstThink = true
                PANEL.oldSetTall = vgui.GetControlTable("DPanel")["SetTall"]
                self.MinimizedSize = self:GetTall() - ExponentialOffset
                self:DockPadding(0, self.MinimizedSize, 0, 0)
                self:SetExpandedSize(self.MinimizedSize + self:GetExpandedSize() - ExponentialOffset) -- this leaves some space on the bottom but for now we wont care
                function PANEL:SetTall(tallness, dynamiccall)
                    self.oldSetTall(self, tallness)
                    if not dynamiccall then -- only set minimizedsize for non dynamic settalls
                        self.MinimizedSize = tallness - ExponentialOffset
                    end
                end
            end

            if self.Expanding == true then
                if self:GetTall() >= self.ExpandedSize - ExponentialOffset then
                    self.Expanding = false
                    self:FullyExpandedHook() -- a hook
                    self.FullyExpanded = true
                end

                self:SetTall(ExpDecay(self:GetTall(), self.ExpandedSize, 15, FrameTime()), true)
            end

            if self.Minimizing == true then
                self.FullyExpanded = false
                self.Expanding = false
                if self:GetTall() <= self.MinimizedSize + ExponentialOffset then
                    self.Minimizing = false
                    self.FullyMinimized = true
                    self:FullyMinimizedHook()
                end

                self:SetTall(ExpDecay(self:GetTall(), self.MinimizedSize, 7, FrameTime()), true)
            end
        end

        function PANEL:Paint(w, h)
            surface.SetDrawColor(color_black)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(color_white)
            if not self.DropDownTriangleTable[1].x then -- simple check
                return
            end

            draw.NoTexture()
            surface.DrawPoly(self.DropDownTriangleTable)
        end

        function PANEL:Expand()
            self.Minimizing = false
            self.Expanding = not self.Expanding
            if self.Expanding == false then --
                self.Minimizing = true
            end

            self.ExpandStartTime = CurTime()
        end

        function PANEL:Minimize()
            self.Expanding = false
            self.Minimizing = true
            self.ExpandStartTime = CurTime()
        end

        function PANEL:OnMousePressed(keyCode)
            if keyCode == MOUSE_LEFT then
                if not self.FullyExpanded then
                    print("1")
                    self:Expand()
                elseif self.FullyExpanded then
                    print("2")
                    self:Minimize()
                end
            end
        end

        --[[
        -- override this
        function PANEL:DoClick()
        end
        --]]
        vgui.Register("SDropDown", PANEL, "DPanel")
    end

    do
        print("HI")
        local Categories = {
            -- the map networking would no longer be needed with this categories table, should only network x number of maps that aren't categorized
            [1] = {
                ["name"] = "MyCoolCategory1",
                ["maps"] = {"gm_c17map", "gm_c17map", "gm_c17map", "gm_c17map", "gm_c17map", "gm_c17map", "gm_c17map", "gm_c17map", "gm_c17map", "gm_c17map",}
            },
            [2] = {
                ["name"] = "MyCoolCategory2",
                ["maps"] = {"fof_city17"}
            },
        }

        local IconSize = ScrH() * 0.15
        local RowGap = ScrH() * 0.005
        local function Pop() -- THERE NEEDS TO BE A DROPUP MODIFIER MENU FOR GAMEMODES!
            if IsValid(ScreenPanel) then ScreenPanel:Remove() end
            ScreenPanel = vgui.Create("DPanel") -- make this use panel:parenttohud instead or gethudpanel
            ScreenPanel:SetSize(ScrW(), ScrH())
            local VoteFrame = vgui.Create("DPanel", ScreenPanel)
            VoteFrame:SetSize(IconSize * 8 + RowGap * 8, ScrH() * 0.7)
            VoteFrame:SetY(ScrH() * 0.1)
            VoteFrame:CenterHorizontal()
            VoteFrame:MakePopup()
            function VoteFrame.Paint(_, w, h)
                if debugvgui == true then
                    surface.SetDrawColor(mapvote_colortable.color_blue)
                    surface.DrawRect(0, 0, w, h)
                end
            end

            local TopDropDock = ScrH() * 0.01
            local SixtyFour = ScrH() * 0.059259999 -- basically 64
            for _, tbl in ipairs(Categories) do
                local DropDown = vgui.Create("SDropDown", VoteFrame)
                DropDown:Dock(TOP)
                DropDown:SetWide(VoteFrame:GetWide())
                DropDown:DockMargin(0, 0, 0, TopDropDock)
                DropDown:SetTall(SixtyFour * 0.4)
                local RowCount = CalculateRowCount(IconSize + RowGap, DropDown:GetWide(), #tbl.maps)
                local ExpandedSize = RowCount * IconSize + (RowCount - 1) * RowGap
                DropDown:SetExpandedSize(ExpandedSize)
                local Grid = nil
                function DropDown:FullyExpandedHook()
                    Grid = vgui.Create("SGrid", DropDown)
                    Grid:SetOverallAlignment(SGRID_ALIGN_LEFT)
                    Grid:DockMargin(0, DropDown:GetTall(), 0, 0)
                    Grid:SetWide(DropDown:GetWide())
                    Grid:SetPos(0, 0 + DropDown:GetMinimizedSize())
                    --Grid:Hide()
                    function Grid.Paint(_, w, h)
                        if debugvgui == true then
                            surface.SetDrawColor(mapvote_colortable.color_red)
                            surface.DrawRect(0, 0, w, h)
                        end
                    end

                    for i = 1, #tbl.maps do
                        local SpacerPanel = vgui.Create("DPanel", row)
                        function SpacerPanel.Paint(_, w, h)
                            if debugvgui == true then
                                surface.SetDrawColor(mapvote_colortable.color_yellow)
                                surface.DrawRect(0, 0, w, h)
                            end
                        end

                        SpacerPanel:SetWide(RowGap)
                        local VoteIcon = vgui.Create("SVoteIcon", row) -- requires parent only because of autorefresh being annoying
                        VoteIcon:SetMap(tbl.maps[i])
                        if not VoteIcon:IsMapAlreadyRegistered(tbl.maps[i]) then -- if the map is already registered it won't lag the player, set them all at the same time, its fine
                            timer.Simple((i - 1) * 0.5, function()
                                if not IsValid(VoteIcon) then return end
                                -- dont lag player so bad, and also let mapmaterials cache do its job
                                -- this should be replaced by a proper queue system
                                VoteIcon:DownloadMap()
                                return
                            end)
                        else
                            VoteIcon:DownloadMap()
                        end

                        VoteIcon:SetSize(IconSize, IconSize)
                        Grid:SetRowHeight(IconSize)
                        Grid:AddItem(VoteIcon)
                        Grid:AddItem(SpacerPanel)
                    end

                    Grid:Show()
                end

                function DropDown:FullyMinimizedHook()
                    if IsValid(Grid) then
                        print("Removed")
                        Grid:Remove()
                    end
                end
            end
        end

        --[[
        local SGrid = vgui.Create("SGrid", GridFrame)
        SGrid:SetTall(GridFrame:GetTall())
        --]]
        Pop()
    end
end
