local debugvgui = false
--
-- this should be in some sort of table later
local colorTextPrimary = Color(205, 214, 255) -- https://github.com/greyliterature/map_vote/blob/3e18c15656596f705442bc47dc6283f0027ac770/lua/mapvote/client/modules/style_config.lua#L7 
--
local mapvote_colortable = nil
if CLIENT and debugvgui == true then
    mapvote_colortable = {}
    mapvote_colortable.color_red = Color(255, 0, 0)
    mapvote_colortable.color_blue = Color(0, 0, 255)
    mapvote_colortable.color_yellow = Color(255, 255, 0)
    mapvote_colortable.color_transparentishpurple = Color(255, 0, 255, 0)
end

local ERROR_DOWNLOADING_MAT = Material("maps/thumb/noicon.png")
local MapVoteRateLimit = include("autorun/shared/vguilogic_smapvoteicon.lua")
local MapsToPanel = {}
local MapNameToWSID = {}
local MapMaterials = {}
-- panel is for the queue system table to remember
local TimeoutDelay = 5
local function RequestMapWSID(panel, mapname) -- should this be batched? is net messages 1 by 1 sig worse than a large net message? probably
    print("MapVote: Requesting WSID for " .. mapname)
    if MapMaterials[mapname] then
        print("Returning mapmaterial cache for " .. mapname)
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
    net.Start("MapVote_request_map_wsid")
    net.WriteString(mapname)
    net.SendToServer()
    timer.Create(mapname .. "Timeout", TimeoutDelay, 1, function()
        if MapMaterials[mapname] then return end
        print("MapWSID request timed out for " .. mapname)
        MapMaterials[mapname] = ERROR_DOWNLOADING_MAT
    end)
end

local SearchPaths = {
    -- from https://github.com/greyliterature/map_vote/blob/3e18c15656596f705442bc47dc6283f0027ac770/lua/mapvote/client/modules/thumb_downloader.lua#L6
    "maps/thumb",
    "maps/thumb/",
    "maps/",
}

-- no thumb_cache because i dont see a current need for that 
local thumbFilePathCache = {}
function getMapThumbnailFilePath(name) -- https://github.com/greyliterature/map_vote/blob/3e18c15656596f705442bc47dc6283f0027ac770/lua/mapvote/client/modules/thumb_downloader.lua#L27
    if thumbFilePathCache[name] then return thumbFilePathCache[name] end
    for _, path in ipairs(SearchPaths) do
        -- finding all the paths in bulk this way is faster than using file.Exists
        local thumbs = file.Find(path .. "*", "GAME")
        for _, thumb in ipairs(thumbs) do
            local extensionName = string.sub(thumb, -3, -1)
            if extensionName == "png" or extensionName == "jpg" then
                local mapName = string.sub(thumb, 1, -5)
                thumbFilePathCache[mapName] = path .. thumb
            end
        end
    end
    return thumbFilePathCache[name]
end

local MapToPanels = {}
net.Receive("MapVote_request_map_wsid_response", function(_, _)
    local mapname = net.ReadString()
    local wsid = net.ReadString()
    MapNameToWSID[mapname] = wsid
    print("HIIIiii", wsid)
    local MapPanels = MapToPanels[mapname] -- this should always be valid 
    if MapMaterials[mapname] or wsid == "" then
        --error("No WSID for " .. mapname)
        for _, MapPanel in pairs(MapPanels) do
            if not IsValid(MapPanel) then continue end
            MapPanel.MapMaterial = MapMaterials[mapname] or ERROR_DOWNLOADING_MAT
        end
        return
    end

    steamworks.FileInfo(wsid, function(result)
        -- https://wiki.facepunch.com/gmod/steamworks.Download#example
        steamworks.Download(result.previewid, true, function(name)
            print("got preview image for " .. name .. " " .. mapname .. " " .. wsid)
            local MapMaterial = AddonMaterial(name)
            for _, MapPanel in pairs(MapPanels) do
                if not IsValid(MapPanel) then continue end
                if MapPanel.MapMaterial then continue end
                MapPanel.MapMaterial = AddonMaterial(name)
                MapMaterials[mapname] = MapMaterial
            end
        end)
    end)
end)

net.Receive("MapVote_votemap_announcement", function(_, _)
    local RemoveVote = net.ReadBool()
    local MapName = net.ReadString()
    local ply = net.ReadPlayer()
    local MapPanels = MapToPanels[MapName]
    for _, MapPanel in pairs(MapPanels) do
        if not IsValid(MapPanel) then continue end
        if RemoveVote == false then
            print("vote")
            MapPanel:VoteForMap(ply, true)
        else
            print("remove")
            MapPanel:RemoveVoteForMap(ply, true)
        end
    end

    hook.Run("MapVote_PlayerVotedForMap", ply, RemoveVote, MapName, MapPanel)
end)

-- SVoteIcon
local PANEL = {}
local HeartSize = ScrW() * 0.01
local color_dark_blue = Color(0, 0, 10, 253)
function PANEL:Init()
    self.Map = nil
    self.WSID = nil -- is this important to store?
    self.MapMaterial = nil
    self:SetMouseInputEnabled(true)
    self.Votes = {}
    self.Grid = vgui.Create("SGrid", self)
    self.Grid:Dock(FILL)
    self.Grid:SetOverallAlignment(SGRID_ALIGN_RIGHT)
    self.PlayerAvatars = {}
    function self.Grid.Paint(_, w, h)
        if debugvgui == true then
            surface.SetDrawColor(mapvote_colortable.color_transparentishpurple)
            surface.DrawRect(0, 0, w, h)
        end
    end

    function self.Grid.OnMousePressed(_, keyCode)
        self:OnMousePressed(keyCode)
    end

    timer.Simple(0, function()
        if not IsValid(self) then return end
        local Heart = vgui.Create("DImageButton", self)
        Heart:SetImage("icon16/heart_add.png")
        Heart:SetSize(HeartSize, HeartSize)
        Heart:SetPos(self:GetWide() - HeartSize, self:GetTall() - HeartSize)
        Heart:IsMouseInputEnabled(true)
        self.Heart = Heart
        function Heart.DoClick(_)
            self:OnHeartPress()
        end
    end)

    local MapNamePanel = vgui.Create("DPanel", self)
    MapNamePanel:Dock(BOTTOM)
    function MapNamePanel.Paint(selfself, w, h)
        surface.SetDrawColor(color_dark_blue)
        surface.DrawRect(0, 0, w, h)
        draw.SimpleText(selfself.Text or "N/A", MapVote.iconFont(20), w * 0.02, h * 0.5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    self.MapNamePanel = MapNamePanel
end

function PANEL:OnHeartPress()
    -- override me
end

function PANEL:IsMapAlreadyRegistered(mapname) -- this is a helper function that doesn't really belong on the object, but i dont know wheree else to puts it
    return MapMaterials[mapname]
end

function PANEL:SetMap(mapname)
    MapToPanels[mapname] = MapToPanels[mapname] or {}
    table.insert(MapToPanels[mapname], self)
    self.MapNamePanel.Text = mapname
    self.Map = mapname
end

function PANEL:GetMapName()
    return self.Map
end

function PANEL:GetThumbnail()
    local FilePath = getMapThumbnailFilePath(self:GetMapName())
    if FilePath then -- https://github.com/greyliterature/map_vote/blob/3e18c15656596f705442bc47dc6283f0027ac770/lua/mapvote/client/modules/thumb_downloader.lua#L51
        self.MapMaterial = Material(FilePath)
        print("Got thumb file path for " .. self:GetMapName(), self.MapMaterial)
        return
    end

    print("yep")
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

    local baseFontSize = w * 0.10 -- https://github.com/greyliterature/map_vote/blob/3e18c15656596f705442bc47dc6283f0027ac770/lua/mapvote/client/vgui/map_icon.lua#L94
    draw.SimpleText(self:GetMapName(), MapVote.iconFont(baseFontSize), 0, 0, colorTextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
end

local PlayerVotes = {} -- ply = mapnaem
-- forced arg is used by the net.receive callback to force past the localplayer return
function PANEL:RemoveVoteForMap(ply, forced)
    if not self.Votes[ply] then return end
    if ply == LocalPlayer() and forced == nil then
        net.Start("rv_mapvote_vote_map")
        net.WriteBool(true) -- bool of whether or not we're removing the vote
        net.WriteString(self:GetMapName())
        net.SendToServer()
        return
    end

    self.Votes[ply] = nil
    local LastAvatar = self.PlayerAvatars[ply]
    if IsValid(LastAvatar) then
        self.Grid:RemoveItem(LastAvatar)
        LastAvatar:Remove()
    end

    self.PlayerAvatars[ply] = nil
    PlayerVotes[ply] = nil
end

local LastVoteTime = 0
-- forced arg is used by the net.receive callback to force past the localplayer return
function PANEL:VoteForMap(ply, forced)
    local LastVotedMap = PlayerVotes[ply]
    if LastVotedMap and LastVotedMap ~= self:GetMapName() then
        for _, panel in pairs(MapToPanels[LastVotedMap]) do
            if IsValid(panel) then panel:RemoveVoteForMap(ply, true) end
        end
    end

    if ply == LocalPlayer() and not forced then
        if LastVoteTime + MapVoteRateLimit > CurTime() then -- this is just for prediction, and is also done serverside 
            return
        end

        LastVoteTime = CurTime()
        net.Start("rv_mapvote_vote_map")
        local RequestRemove = PlayerVotes[ply] == self:GetMapName()
        print(RequestRemove, "hi")
        net.WriteBool(RequestRemove) -- bool of whether or not we're removing the vote
        net.WriteString(self:GetMapName())
        net.SendToServer()
        return
    end

    PlayerVotes[ply] = self:GetMapName()
    if self.PlayerAvatars[ply] then return end
    self.Votes[ply] = true
    local IconSize = self:GetTall() * 0.2 -- this shouldnt be static, but ignorable for now
    local Avatar = vgui.Create("AvatarImage", self.Grid)
    Avatar:SetPlayer(ply, 184)
    Avatar:SetWide(IconSize)
    self.Grid:AddItem(Avatar)
    self.Grid:SetRowHeight(IconSize)
    self.PlayerAvatars[ply] = Avatar
end

function PANEL:SetVoters(votertbl)
    for _, tbl in ipairs(self.Grid.Items) do
        local PanelObject = tbl[1]
        if IsValid(PanelObject) then self.Grid:RemoveItem(PanelObject) end
    end

    for _, ply in ipairs(votertbl) do
        self:VoteForMap(ply, true)
    end
end

function PANEL:Debug_VoteEveryone()
    for _, ply in player.Iterator() do
        self:VoteForMap(ply)
    end
end

function PANEL:OnMousePressed(keyCode)
    if keyCode ~= MOUSE_LEFT then return end
    if debugvgui == true then
        --self:Debug_VoteEveryone()
        --return
    end

    self:VoteForMap(LocalPlayer())
end

vgui.Register("SVoteIcon", PANEL, "DPanel")
