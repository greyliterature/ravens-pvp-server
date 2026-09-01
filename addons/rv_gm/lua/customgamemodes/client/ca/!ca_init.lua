--[[------------------------------
    init 
--------------------------------]]
local GamemodeVars = include("customgamemodes/gamemodevars.lua")
TEAM_RED = 1
TEAM_BLUE = 2
--[[------------------------------
    Teams 
--------------------------------]]
-- Returns blue, unless red has less players. Then it returns red.
local function GetLowestTeam()
    local LowestTeam = TEAM_BLUE
    local RedPlayers = #team.GetPlayers(TEAM_RED)
    local BluePlayers = #team.GetPlayers(TEAM_BLUE)
    if RedPlayers < BluePlayers then LowestTeam = TEAM_RED end
    return LowestTeam
end

--[[------------------------------
    Shared hook functions 
--------------------------------]]
local function ShouldRunHook() -- for making sure that some of the hooks dont run when the gamemode is ffa
    return -- this is not needed if the include system works perfectly
    --return GetGlobalString("CurrentGamemode", "FFA") ~= "FFA"
end

--[[------------------------------
        Fonts
--------------------------------]]
surface.CreateFont("RobotoBig", {
    font = "Roboto Bk",
    extended = false,
    size = ScrW() / 65.8461538,
    weight = 500,
    blursize = 0,
    scanlines = 0,
    antialias = true,
    underline = false,
    italic = false,
    strikeout = false,
    symbol = false,
    rotary = false,
    shadow = false,
    additive = false,
    outline = false,
})

surface.CreateFont("RobotoHeader", {
    font = "Roboto Bk",
    extended = false,
    size = ScrW() / 40.8461538,
    weight = 500,
    blursize = 0,
    scanlines = 0,
    antialias = true,
    underline = false,
    italic = false,
    strikeout = false,
    symbol = false,
    rotary = false,
    shadow = false,
    additive = false,
    outline = false,
})

surface.CreateFont("RobotoSecondaryHeader", {
    font = "Roboto Bk",
    extended = false,
    size = ScrW() / 55.8461538,
    weight = 500,
    blursize = 0,
    scanlines = 0,
    antialias = true,
    underline = false,
    italic = false,
    strikeout = false,
    symbol = false,
    rotary = false,
    shadow = false,
    additive = false,
    outline = false,
})

surface.CreateFont("RobotoWeaponInfo", {
    font = "Roboto Bk",
    extended = false,
    size = ScrW() / 80,
    weight = 500,
    blursize = 0,
    scanlines = 0,
    antialias = true,
    underline = false,
    italic = false,
    strikeout = false,
    symbol = false,
    rotary = false,
    shadow = false,
    additive = false,
    outline = false,
})

surface.CreateFont("HL2MPBig", {
    font = "HL2MP",
    extended = false,
    size = ScrW() * 0.065,
    weight = 500,
    blursize = 0,
    scanlines = 0,
    antialias = true,
    underline = false,
    italic = false,
    strikeout = false,
    symbol = false,
    rotary = false,
    shadow = false,
    additive = false,
    outline = false,
})

surface.CreateFont("SpacerFont", {
    font = "Roboto Bk",
    extended = false,
    size = ScrW() * 0.01,
    weight = 500,
    blursize = 0,
    scanlines = 0,
    antialias = true,
    underline = false,
    italic = false,
    strikeout = false,
    symbol = false,
    rotary = false,
    shadow = false,
    additive = false,
    outline = false,
})

--[[------------------------------
        Draw circle function
--------------------------------]]
function draw.Circle(x, y, radius, seg) -- https://wiki.facepunch.com/gmod/surface.DrawPoly#example
    local cir = {}
    table.insert(cir, {
        x = x,
        y = y,
        u = 0.5,
        v = 0.5
    })

    for i = 0, seg do
        local a = math.rad((i / seg) * -360)
        table.insert(cir, {
            x = x + math.sin(a) * radius,
            y = y + math.cos(a) * radius,
            u = math.sin(a) / 2 + 0.5,
            v = math.cos(a) / 2 + 0.5
        })
    end

    local a = math.rad(0) -- This is needed for non absolute segment counts
    table.insert(cir, {
        x = x + math.sin(a) * radius,
        y = y + math.cos(a) * radius,
        u = math.sin(a) / 2 + 0.5,
        v = math.cos(a) / 2 + 0.5
    })

    draw.NoTexture()
    surface.DrawPoly(cir)
end

--[[------------------------------
        Join Team popup
--------------------------------]]
local JoinTeamMenuColors = {
    Background = Color(50, 50, 50, 254),
    Header = Color(100, 100, 100, 255),
    WeaponIconConVarred = Color(240, 240, 178, 255),
    WeaponIconHovered = Color(240, 240, 240, 255),
    WeaponInfoBackground = Color(72, 72, 72, 255),
    WeaponInfoHeader = Color(239, 239, 239, 255),
    WeaponInfoText = Color(186, 186, 186, 255),
    HoveredGold = Color(252, 192, 80),
    JoinMatchWhite = Color(251, 215, 205),
    LightRed = Color(255, 35, 12),
    Red = Color(83, 33, 34),
    DarkRed = Color(84, 32, 32),
    Blue = Color(30, 30, 85),
    DarkBlue = Color(32, 32, 84),
    SpectateGrey = Color(31, 31, 31),
}

local rv_spawnweapon = CreateClientConVar("rv_spawnweapon", "weapon_357", true, true, "what weapon to pull out on spawn (an alternative to cl_defaultweapon)")
local function OpenJoinTeamPopup()
    local RankedMatch = GamemodeVars.RankedMatch
    if IsValid(JoinTeamPanel) then JoinTeamPanel:Remove() end
    JoinTeamPanel = vgui.Create("DPanel")
    JoinTeamPanel:MakePopup()
    JoinTeamPanel:SetMouseInputEnabled(true)
    JoinTeamPanel:SetWide(ScrW() * 0.75)
    JoinTeamPanel:SetTall(ScrH() * 0.7)
    JoinTeamPanel:SetPos((ScrW() - JoinTeamPanel:GetWide()) / 2, (ScrH() - JoinTeamPanel:GetTall()) / 2)
    local HorizontalPadding = JoinTeamPanel:GetWide() * 0.04
    JoinTeamPanel:DockPadding(HorizontalPadding, 0, HorizontalPadding, 0)
    function JoinTeamPanel.Paint(self, w, h)
        surface.SetDrawColor(JoinTeamMenuColors.Background)
        surface.DrawRect(0, 0, w, h)
    end

    -- Unranked Match
    local MatchPanel = vgui.Create("DPanel", JoinTeamPanel)
    MatchPanel:Dock(TOP)
    MatchPanel:SetTall(JoinTeamPanel:GetTall() * 0.5)
    MatchPanel:SetWide(JoinTeamPanel:GetWide() - HorizontalPadding * 2)
    local HeaderRectThickness = JoinTeamPanel:GetTall() * 0.01
    local HeaderRectHeightOffset = JoinTeamPanel:GetTall() * 0.06
    local HeaderTextHeightOffset = JoinTeamPanel:GetTall() * 0.03
    function MatchPanel.Paint(self, w, h)
        draw.SimpleText((RankedMatch == true and "Rated match") or "Unrated match", "RobotoBig", 0, HeaderRectHeightOffset - HeaderTextHeightOffset, JoinTeamMenuColors.Header, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(JoinTeamMenuColors.Header)
        surface.DrawRect(0, 0 + HeaderRectHeightOffset, w, HeaderRectThickness)
    end

    local MatchButtonsPanel = vgui.Create("DPanel", MatchPanel)
    local MatchButtonsPanelWidePos = MatchPanel:GetWide() * 0.7
    --local MatchButtonsPanelWidth = JoinTeamPanel:GetWide() - MatchButtonsPanelWidePos - HorizontalPadding * 2
    local MatchButtonsPanelWidth = JoinTeamPanel:GetWide() - MatchButtonsPanelWidePos - HorizontalPadding * 2
    MatchButtonsPanel:SetWide(MatchButtonsPanelWidth)
    MatchButtonsPanel:SetPos(MatchPanel:GetWide() - MatchButtonsPanel:GetWide(), MatchPanel:GetTall() * 0.25)
    MatchButtonsPanel:SetTall(MatchPanel:GetTall() * 0.7)
    function MatchButtonsPanel.Paint(self, w, h)
        --surface.SetDrawColor(Color(255, 0, 0, 255))
        --surface.DrawRect(0, 0, w, h)
    end

    -- Buttons
    local OutlineThickness = math.floor(MatchButtonsPanel:GetWide() * 0.01)
    local ButtonGap = OutlineThickness * 1.5
    --JOIN MATCH
    local JoinMatchButton = vgui.Create("DLabel", MatchButtonsPanel)
    JoinMatchButton:SetText("")
    JoinMatchButton:Dock(TOP)
    JoinMatchButton:SetTall(MatchButtonsPanel:GetTall() * 0.55)
    JoinMatchButton:SetWide(MatchButtonsPanel:GetWide())
    JoinMatchButton:SetMouseInputEnabled(true)
    surface.SetFont("RobotoBig")
    local TextW, TextH = surface.GetTextSize("JOIN MATCH")
    function JoinMatchButton.Paint(self, w, h)
        surface.SetDrawColor(JoinTeamMenuColors.LightRed)
        surface.DrawRect(0 + OutlineThickness + ButtonGap, 0 + OutlineThickness, w - OutlineThickness - ButtonGap, h - OutlineThickness)
        if self:IsHovered() == true then
            surface.SetDrawColor(JoinTeamMenuColors.HoveredGold)
            surface.DrawOutlinedRect(0 + ButtonGap, 0, w - ButtonGap, h, OutlineThickness)
        end

        draw.DrawText("JOIN MATCH", "RobotoBig", (w - TextW) / 2, (h - TextH) / 2, JoinTeamMenuColors.JoinMatchWhite, TEXT_ALIGN_LEFT)
    end

    function JoinMatchButton.DoClick(self)
        JoinTeamPanel:Remove()
        if LocalPlayer():Team() == TEAM_RED or LocalPlayer():Team() == TEAM_BLUE then -- if they press JOIN MATCH and they are already on a team, nothing needs to run
            return
        end

        net.Start("RequestTeamJoin")
        net.WriteInt(GetLowestTeam(), 32)
        net.SendToServer()
    end

    --JOIN RED / JOIN BLUE
    local JoinRedBluePanel = vgui.Create("DPanel", MatchButtonsPanel)
    JoinRedBluePanel:DockMargin(0, ButtonGap, 0, 0)
    JoinRedBluePanel:Dock(TOP)
    JoinRedBluePanel:SetTall(MatchButtonsPanel:GetTall() * 0.2)
    JoinRedBluePanel:SetWide(MatchButtonsPanel:GetWide())
    function JoinRedBluePanel.Paint(self, w, h)
    end

    local Teams = {
        [TEAM_RED] = "JOIN RED",
        [TEAM_BLUE] = "JOIN BLUE",
    }

    for TeamInt, text in ipairs(Teams) do
        surface.SetFont("RobotoBig")
        local textW, textH = surface.GetTextSize(text)
        local JoinTeamButton = vgui.Create("DLabel", JoinRedBluePanel)
        JoinTeamButton:SetText("")
        JoinTeamButton:SetMouseInputEnabled(true)
        JoinTeamButton:Dock(LEFT)
        JoinTeamButton:SetWide(JoinRedBluePanel:GetWide() * 0.5)
        function JoinTeamButton.Paint(self, w, h)
            surface.SetDrawColor((TeamInt == TEAM_RED and JoinTeamMenuColors.DarkRed) or JoinTeamMenuColors.DarkBlue)
            surface.DrawRect(0 + OutlineThickness + ButtonGap, 0 + OutlineThickness, w - OutlineThickness - ButtonGap, h - OutlineThickness)
            if self:IsHovered() == true then
                surface.SetDrawColor(JoinTeamMenuColors.HoveredGold)
                surface.DrawOutlinedRect(0 + ButtonGap, 0, w - ButtonGap, h, OutlineThickness)
            end

            draw.DrawText(text, "RobotoBig", (w - textW) / 2, (h - textH) / 2, JoinTeamMenuColors.JoinMatchWhite, TEXT_ALIGN_LEFT)
        end

        function JoinTeamButton.DoClick(self)
            JoinTeamPanel:Remove()
            if LocalPlayer():Team() == TeamInt then -- if the player presses to join the team they are on, nothing needs to run
                return
            end

            net.Start("RequestTeamJoin")
            net.WriteInt(TeamInt, 32)
            net.SendToServer()
        end
    end

    --SPECTATE
    local SpectateButton = vgui.Create("DLabel", MatchButtonsPanel)
    SpectateButton:DockMargin(0, ButtonGap, 0, 0)
    SpectateButton:Dock(TOP)
    SpectateButton:SetTall(MatchButtonsPanel:GetTall() * 0.2)
    SpectateButton:SetWide(MatchButtonsPanel:GetWide())
    SpectateButton:SetText("")
    SpectateButton:SetMouseInputEnabled(true)
    surface.SetFont("RobotoBig")
    function SpectateButton.Paint(self, w, h)
        surface.SetDrawColor(JoinTeamMenuColors.SpectateGrey)
        surface.DrawRect(0 + OutlineThickness + ButtonGap, 0 + OutlineThickness, w - OutlineThickness - ButtonGap, h - OutlineThickness)
        if self:IsHovered() == true then
            surface.SetDrawColor(JoinTeamMenuColors.HoveredGold)
            surface.DrawOutlinedRect(0 + ButtonGap, 0, w - ButtonGap, h, OutlineThickness)
        end

        local textW, textH = surface.GetTextSize("SPECTATE")
        draw.DrawText("SPECTATE", "RobotoBig", (w - textW) / 2, (h - textH) / 2, JoinTeamMenuColors.JoinMatchWhite, TEXT_ALIGN_LEFT)
    end

    function SpectateButton.DoClick(self)
        JoinTeamPanel:Remove()
        if LocalPlayer():Team() == TEAM_SPECTATOR then -- if the player is already spectating, nothing needs to run
            return
        end

        net.Start("RequestTeamJoin")
        net.WriteInt(TEAM_SPECTATOR, 32)
        net.SendToServer()
    end

    --
    -- Clan arena - Asylum
    local LambdaLogo = vgui.Create("DLabel", MatchPanel)
    LambdaLogo:SetFont("HL2MPBig")
    LambdaLogo:SetPos(MatchPanel:GetWide() * 0.03 - MatchPanel:GetWide() * 0.03, MatchPanel:GetTall() * 0.34) -- equals 0 x
    local lambdatext = "," -- grav gun
    surface.SetFont(LambdaLogo:GetFont())
    LambdaLogo:SetSize(MatchPanel:GetWide() * 0.105, MatchPanel:GetWide() * 0.105)
    LambdaLogo:SetText("")
    function LambdaLogo.Paint(self, w, h)
        surface.SetDrawColor(color_black)
        local CircleRadius = w * 0.5
        draw.Circle(w / 2, h / 2, CircleRadius, 50)
        draw.DrawText(lambdatext, self:GetFont(), 0, h * 0.26, color_white)
        surface.SetDrawColor(Color(255, 0, 0))
        --surface.DrawRect(0, (h - 6) / 2, w, 6)
    end

    local GamemodeInfoText = vgui.Create("DLabel", MatchPanel)
    --RoundInfoText:SetFont("RobotoBig")
    GamemodeInfoText:SetPos(MatchPanel:GetWide() * 0.14 - MatchPanel:GetWide() * 0.03, MatchPanel:GetTall() * 0.37)
    local gamemodeinfotext = {
        {"Clan Arena - " .. game.GetMap(), "RobotoBig"},
        --
        {"", "SpacerFont"},
        {"Round limit : " .. "First to " .. GetGlobalInt("RoundLimit", "10"), "RobotoBig"},
        {"", "SpacerFont"},
        {#player.GetAll() .. "/" .. game.MaxPlayers() .. " Players", "RobotoBig"}
    }

    --surface.SetFont(RoundInfoText:GetFont())
    --TextW, TextH = surface.GetTextSize(roundinfotext)
    --RoundInfoText:SetSize(TextW, TextH)
    GamemodeInfoText:SetSize(MatchPanel:GetWide(), MatchPanel:GetTall())
    GamemodeInfoText:SetText("")
    function GamemodeInfoText.Paint(self, w, h)
        local LastTextSizes = 0
        for i = 1, #gamemodeinfotext do
            local font = gamemodeinfotext[i][2]
            if i > 1 then
                surface.SetFont(font)
                LastTextSizes = LastTextSizes + select(2, surface.GetTextSize(gamemodeinfotext[i - 1][1]))
            end

            draw.DrawText(gamemodeinfotext[i][1], font, 0, LastTextSizes, JoinTeamMenuColors.Header, TEXT_ALIGN_LEFT)
        end
    end

    local ServerInfoText = vgui.Create("DLabel", MatchPanel)
    ServerInfoText:SetPos(0, MatchPanel:GetTall() * 0.75)
    local RedScore = team.GetScore(TEAM_RED)
    local BlueScore = team.GetScore(TEAM_BLUE)
    local ScoreText = "Teams are tied at " .. RedScore
    if RedScore > BlueScore then
        ScoreText = "Red is leading " .. RedScore .. " - " .. BlueScore
    elseif BlueScore > RedScore then
        ScoreText = "Blue is leading " .. BlueScore .. " - " .. RedScore
    end

    local serverinfotext = {
        {"This match is hosted by " .. GetHostName(), "RobotoBig"},
        --
        --{"", "SpacerFont"},
        {((MatchInProgress == true and "ONGOIN - ") or "MATCH WARMUP - ") .. ScoreText, "RobotoBig"}
    }

    ServerInfoText:SetSize(MatchPanel:GetWide(), MatchPanel:GetTall())
    ServerInfoText:SetText("")
    function ServerInfoText.Paint(self, w, h)
        local LastTextSizes = 0
        for i = 1, #serverinfotext do
            local font = serverinfotext[i][2]
            if i > 1 then
                surface.SetFont(font)
                LastTextSizes = LastTextSizes + select(2, surface.GetTextSize(serverinfotext[i - 1][1]))
            end

            draw.DrawText(serverinfotext[i][1], font, 0, LastTextSizes, JoinTeamMenuColors.Header, TEXT_ALIGN_LEFT)
        end
    end

    -- Weapon Loadouts
    local LoadoutPanel = vgui.Create("DPanel", JoinTeamPanel)
    LoadoutPanel:Dock(TOP)
    LoadoutPanel:SetWide(JoinTeamPanel:GetWide())
    LoadoutPanel:SetTall(JoinTeamPanel:GetTall() * 0.5)
    function LoadoutPanel.Paint(self, w, h)
        draw.SimpleText("Spawn Weapon", "RobotoBig", 0, HeaderRectHeightOffset - HeaderTextHeightOffset, JoinTeamMenuColors.Header, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(JoinTeamMenuColors.Header)
        surface.DrawRect(0, 0 + HeaderRectHeightOffset, w, HeaderRectThickness)
    end

    local WeaponsPanel = vgui.Create("DPanel", LoadoutPanel)
    local WeaponsPanelHeightPos = LoadoutPanel:GetTall() * 0.25
    WeaponsPanel:SetPos(0, WeaponsPanelHeightPos)
    WeaponsPanel:SetWide(LoadoutPanel:GetWide() * 0.75)
    local TextHeightOffset = LoadoutPanel:GetTall() * 0.21 -- because the weapon icons are set too far up
    WeaponsPanel:SetTall(LoadoutPanel:GetTall() * 0.4 - TextHeightOffset)
    WeaponsPanel:SetZPos(-10000)
    function WeaponsPanel.Paint(self, w, h)
        --surface.SetDrawColor(color_white)
        --surface.DrawRect(0, 0, w, h)
    end

    local Weapons = {
        {"weapon_357", ".", "WeaponInfo", "357. Magnum", false},
        -- makeformatterexpandtable
        {"weapon_ar2", "2", "WeaponInfo", "AR2", false},
        {"weapon_crossbow", "1", "WeaponInfo", "Crossbow", false},
        {"weapon_pistol", "-", "WeaponInfo", "9mm Pistol", false},
        {"weapon_shotgun", "0", "WeaponInfo", "SPAS-12", false},
        {"weapon_smg1", "/", "WeaponInfo", "SMG-1", false},
    }

    local WeaponDisplays = {}
    local AlreadySelectedWeapon = rv_spawnweapon:GetString()
    local SelectedWeaponName = nil
    local SelectedWeaponInfo = nil -- for the WeaponInfo on IsHovered() 
    local ClickedWeapon = nil
    for _, tbl in ipairs(Weapons) do
        local WeaponDisplay = vgui.Create("DLabel", WeaponsPanel)
        WeaponDisplay:SetZPos(100000)
        WeaponDisplay:SetText("")
        WeaponDisplay:SetFont("HL2MPBig")
        surface.SetFont("HL2MPBig")
        TextW, _ = surface.GetTextSize(tbl[2])
        WeaponDisplay:SetSize(TextW, WeaponsPanel:GetTall())
        WeaponDisplay:Dock(LEFT)
        WeaponDisplay:SetMouseInputEnabled(true)
        local HoverTime = nil
        function WeaponDisplay.Paint(self, w, h)
            local Hovered = false
            if self:IsHovered() then
                Hovered = true
                SelectedWeaponInfo = tbl[3]
                SelectedWeaponName = tbl[4]
                if not HoverTime then --
                    HoverTime = CurTime()
                end

                tbl[5] = true
            else
                tbl[5] = false
            end

            if tbl[5] == false and SelectedWeaponName == tbl[4] then
                SelectedWeaponInfo = nil
                SelectedWeaponName = nil
            end

            --if tbl[2] == "." then --
            --surface.SetDrawColor(Color(255, 0, 0))
            --surface.DrawRect(0, 0, w, h)
            --end
            --if ClickedWeapon ~= tbl[4] and Hovered == true then ClickedWeapon = tbl[4] end
            JoinTeamMenuColors.WeaponIconHovered.a = (HoverTime and (CurTime() - HoverTime) * 1000) or 0
            if Hovered == false then HoverTime = nil end
            local WeaponIconColor = (Hovered and JoinTeamMenuColors.WeaponIconHovered) or color_black
            if AlreadySelectedWeapon == tbl[1] then
                if ClickedWeapon ~= tbl[4] then --
                    WeaponIconColor.a = 255
                end

                if Hovered == false or ClickedWeapon == tbl[4] then --
                    WeaponIconColor = JoinTeamMenuColors.WeaponIconConVarred
                end
            end

            draw.DrawText(tbl[2], self:GetFont(), 0, 0, WeaponIconColor)
        end

        function WeaponDisplay.DoClick(self, w, h)
            ClickedWeapon = tbl[4]
            RunConsoleCommand("rv_spawnweapon", tbl[1])
            AlreadySelectedWeapon = tbl[1]
        end

        WeaponDisplays[#WeaponDisplays + 1] = WeaponDisplay
    end

    local WeaponInfoPanel = vgui.Create("DPanel", LoadoutPanel)
    WeaponInfoPanel:SetPos(MatchButtonsPanelWidePos, WeaponsPanelHeightPos)
    WeaponInfoPanel:SetSize(MatchButtonsPanelWidth, LoadoutPanel:GetTall() * 0.4)
    local WeaponInfoPanelDockPadding = WeaponInfoPanel:GetWide() * 0.02
    WeaponInfoPanel:DockPadding(WeaponInfoPanelDockPadding, WeaponInfoPanelDockPadding, WeaponInfoPanelDockPadding, WeaponInfoPanelDockPadding)
    function WeaponInfoPanel.Paint(self, w, h)
        if not SelectedWeaponInfo or not SelectedWeaponName then return end
        surface.SetDrawColor(JoinTeamMenuColors.WeaponInfoBackground)
        surface.DrawRect(0, 0, w, h)
    end

    local WeaponInfoText = vgui.Create("DPanel", WeaponInfoPanel)
    WeaponInfoText:Dock(FILL)
    function WeaponInfoText.Paint(self, w, h)
        if not SelectedWeaponInfo or not SelectedWeaponName then return end
        draw.DrawText(SelectedWeaponName, "RobotoWeaponInfo", 0, 0, JoinTeamMenuColors.WeaponInfoHeader)
        local HeaderGap = h * 0.2
        draw.DrawText(SelectedWeaponInfo, "RobotoWeaponInfo", 0, 0 + HeaderGap, JoinTeamMenuColors.WeaponInfoText)
    end
end

--[[
net.Receive("OpenJoinTeamPopup", function(len, ply)
    --
    RankedMatch = net.ReadBool()
    OpenJoinTeamPopup()
end)
--]]
OpenJoinTeamPopup()
AddGamemodeHook("InitPostEntity", "JoinTeamPopupOnInit", function()
    if ShouldRunHook() == false then return end
    OpenJoinTeamPopup()
end)

AddGamemodeHook("PlayerButtonDown", "JoinTeamPopup", function(ply, button)
    if ShouldRunHook() == false then return end
    if button == KEY_F4 then
        OpenJoinTeamPopup()
        hook.Remove("HUDPaint", "TeamJoinMenuReminder")
    end
end)

--[[
    -- autorefresh debug stuff
    if IsValid(JoinTeamPanel) then JoinTeamPanel:Remove() end
    OpenJoinTeamPopup()
    --]]
--[[------------------------------
        Notifs HUD
--------------------------------]]
local Header = nil
local Notifs = {}
local NotifEndTimes = {}
local ShouldFadeLastNotif = false
local NotifColor = Color(255, 255, 255)
local LastNotifTime = 0
net.Receive("SendNotif", function(len, ply)
    Notifs = {}
    NotifEndTimes = {}
    local NumberOfKeys = net.ReadUInt(5)
    for i = 1, NumberOfKeys do
        local NotifText = net.ReadString()
        local NotifEndTime = net.ReadFloat()
        Notifs[#Notifs + 1] = NotifText
        NotifEndTimes[#NotifEndTimes + 1] = NotifEndTime
    end

    ShouldFadeLastNotif = net.ReadBool()
    NotifColor.a = 255 -- Reset alpha before drawing new notifs
    if ShouldFadeLastNotif == true then
        LastNotifTime = CurTime()
    else
        LastNotifTime = nil
    end

    Header = net.ReadString() -- "Clan Arena"
    if #Header == 0 then Header = nil end
end)

local HeaderOffset = ScrH() * 0.1
local NotifOffset = ScrH() * 0.25
NotifStartTimes = {}
--hook.Remove("HUDPaint", "NotifsHUD")
AddGamemodeHook("HUDPaint", "NotifsHUD", function()
    if ShouldRunHook() == false then return end
    if table.IsEmpty(Notifs) then return end
    if ShouldFadeLastNotif == true then
        NotifColor.a = (LastNotifTime and (NotifEndTimes[1] - CurTime()) * 1000) or 0
        if CurTime() > NotifEndTimes[1] then
            LastNotifTime = nil
            ShouldFadeLastNotif = false
        end
    end

    if Header then
        surface.SetFont("RobotoHeader")
        draw.DrawText(Header, "RobotoHeader", ScrW() * 0.5, HeaderOffset, NotifColor, TEXT_ALIGN_CENTER)
    end

    draw.DrawText(Notifs[1], "RobotoSecondaryHeader", ScrW() * 0.5, NotifOffset, NotifColor, TEXT_ALIGN_CENTER)
    if CurTime() > NotifEndTimes[1] then
        table.remove(Notifs, 1)
        table.remove(NotifEndTimes, 1)
    end
end)

--[[------------------------------
    ScoreHud
--------------------------------]]
local color_transparentishgrey = Color(128, 128, 128, 240)
local Teams = {TEAM_RED, TEAM_BLUE}
AddGamemodeHook("HUDPaint", "ScoreHud", function()
    if ShouldRunHook() == false then return end
    if GetGlobal3("MatchInProgress", false) == false then return end
    local MarginFromScreenEdge = ScrW() * 0.01
    local RectWidth = ScrW() * 0.09
    local RectHeight = ScrH() * 0.06
    surface.SetDrawColor(color_transparentishgrey)
    surface.DrawRect(0 + MarginFromScreenEdge, 0 + MarginFromScreenEdge, RectWidth, RectHeight)
    for i = 1, #Teams do
        draw.DrawText(team.GetName(Teams[i]), "RobotoBig", 0 + MarginFromScreenEdge + RectWidth * 0.05, 0 + MarginFromScreenEdge + ((i - 1) * 30), color_white, TEXT_ALIGN_LEFT)
        draw.DrawText(team.GetScore(Teams[i]), "RobotoBig", 0 + MarginFromScreenEdge + RectWidth * 0.8, 0 + MarginFromScreenEdge + ((i - 1) * 30), color_white, TEXT_ALIGN_LEFT)
    end
end)

--[[------------------------------
    Lock attacks (for match / round start delay)
--------------------------------]]
net.Receive("LockAttacks", function(len, _)
    local StartDate = net.ReadFloat()
    AddGamemodeHook("StartCommand", "LockAttacks", function(ply, cmd)
        if ShouldRunHook() == false then return end
        if CurTime() > StartDate then
            if cmd:KeyDown(IN_ATTACK) then --
                cmd:AddKey(IN_ATTACK)
            end

            if cmd:KeyDown(IN_ATTACK2) then --
                cmd:AddKey(IN_ATTACK2)
            end

            hook.Remove("StartCommand", "LockAttacks")
            return
        end

        if cmd:KeyDown(IN_ATTACK) then cmd:RemoveKey(IN_ATTACK) end
        if cmd:KeyDown(IN_ATTACK2) then cmd:RemoveKey(IN_ATTACK2) end
    end)
end)

--[[------------------------------
        Match start
 --------------------------------]]
--[[
net.Receive("MatchStarted", function(len, ply)
    --
    MatchInProgress = net.ReadBool()
end)
--]]
--[[------------------------------
        Player spectate
--------------------------------]]
AddGamemodeHook("FSpectate_canShowBeams", "NoBeams", function()
    if LocalPlayer():Team() == TEAM_SPECTATOR then --
        return nil
    end
    return false
end)

AddGamemodeHook("FSpectate_canShowESP", "NoESP", function()
    if LocalPlayer():Team() == TEAM_SPECTATOR then --
        return nil
    end
    return false
end)

--[[
AddGamemodeHook("FSpectate_canThirdPerson", "NoThirdperson", function()
    --
    return ((LocalPlayer():Team() == TEAM_SPECTATOR and nil) or false)
end)
--]]
AddGamemodeHook("FSpectate_canFreeRoam", "NoFreeRoam", function()
    if LocalPlayer():Team() == TEAM_SPECTATOR then --
        return nil
    end
    return false
end)

AddGamemodeHook("FSpectate_canSpectatePlayer", "OnlySpectateTeam", function(ply)
    if LocalPlayer():Team() == TEAM_SPECTATOR then return end
    if not IsValid(ply) then return end
    if not ply:IsPlayer() then return end
    return ply:Team() == LocalPlayer():Team()
end)

--[[------------------------------
        ReadyUp
--------------------------------]]
local ReadiedUp = false
local LastReadyUpTime = 0 -- ply = CurTime()
local ReadyUpRateLimit = 1 -- seconds
AddGamemodeHook("PlayerButtonDown", "ReadyUpBind", function(ply, button)
    if ShouldRunHook() == false then return end
    if button ~= KEY_F3 then return end
    if GetGlobal3("MatchInProgress", false) == true then
        ReadiedUp = false
        return
    end

    if LastReadyUpTime + ReadyUpRateLimit > CurTime() then -- 
        return
    end

    LastReadyUpTime = CurTime()
    if ply:Team() ~= TEAM_RED and ply:Team() ~= TEAM_BLUE then return end
    ReadiedUp = not ReadiedUp
    net.Start("ReadyUp")
    net.SendToServer()
end)

--[[------------------------------
    SendSound
--------------------------------]]
net.Receive("SendSound", function(len, ply)
    local StartDate = net.ReadFloat()
    local SoundName = net.ReadString()
    local StartDelay = StartDate - CurTime()
    if StartDate < 0 then --
        StartDelay = 0
    end

    timer.Simple(StartDelay, function()
        -- 
        surface.PlaySound(SoundName)
    end)
end)

--[[------------------------------
    RemindersHUD
--------------------------------]]
AddGamemodeHook("HUDPaint", "TeamJoinMenuReminder", function()
    if LocalPlayer():Team() ~= TEAM_SPECTATOR then --
        hook.Remove("HUDPaint", "TeamJoinMenuReminder")
    end

    draw.DrawText("Press F4 to open team menu", "RobotoSecondaryHeader", ScrW() * 0.5, ScrH() * 0.2, color_white, TEXT_ALIGN_CENTER)
end)

local function CeilZero(x) -- math.ceil does not round up for 0
    if x == 0 then return 1 end
    return math.ceil(x)
end

AddGamemodeHook("HUDPaint", "ReadyUpReminder", function()
    if GetGlobal3("MatchInProgress", false) == true or LocalPlayer():Team() == TEAM_SPECTATOR then return end
    if ReadiedUp == false then
        draw.DrawText("Press f3 to Ready-up.", "RobotoSecondaryHeader", ScrW() * 0.5, ScrH() * 0.2, color_white, TEXT_ALIGN_CENTER)
    else
        local ReadyUpRatio = GamemodeVars.ReadyUpRatio[2]
        local ReadyUpCount = GetGlobal3("ReadyUpCount", 0)
        local ValidPlayers = #team.GetPlayers(TEAM_RED) + #team.GetPlayers(TEAM_BLUE)
        draw.DrawText(ReadyUpCount .. " / " .. CeilZero(ReadyUpRatio * ValidPlayers) .. " players ready. " .. "Press f3 to unready yourself.", "RobotoSecondaryHeader", ScrW() * 0.5, ScrH() * 0.2, colortable.color_green, TEXT_ALIGN_CENTER)
    end
end)

--[[------------------------------
    Team indicators
--------------------------------]]
surface.CreateFont("TeamIndicatorFont", {
    font = "Arial",
    size = ScrW() * 0.1,
    antialias = false,
    outline = true
})

local chevronleft = {
    {
        x = ScreenScale(-25),
        y = ScreenScaleH(0)
    },
    {
        x = ScreenScale(0),
        y = ScreenScaleH(75)
    },
    {
        x = ScreenScale(0),
        y = ScreenScaleH(95)
    },
    {
        x = ScreenScale(-40),
        y = ScreenScaleH(0)
    },
}

local chevronright = {
    {
        x = ScreenScale(0),
        y = ScreenScaleH(95)
    },
    {
        x = ScreenScale(0),
        y = ScreenScaleH(75)
    },
    {
        x = ScreenScale(25),
        y = ScreenScaleH(0)
    },
    {
        x = ScreenScale(40),
        y = ScreenScaleH(0)
    },
}

local ChevronHeight = ScreenScaleH(95)
local color_healthy = Color(219, 224, 170) -- 75+ hp
local color_notsohealthy = Color(162, 128, 40) -- 50+ hp
local color_nothealthy = Color(184, 81, 40) -- 25+ hp 
local color_nothealthyatall = Color(140, 12, 27) -- 0+ hp
local color_losthealth = Color(179, 41, 55)
AddGamemodeHook("PostDrawTranslucentRenderables", "TeamIndicators", function()
    local fov = LocalPlayer():GetFOV()
    for _, ply in player.Iterator() do
        if ply == LocalPlayer() then continue end
        if ply:GetNoDraw() == true then continue end
        if ply:Alive() == false then continue end
        if ply:Team() ~= LocalPlayer():Team() then continue end
        --local pos = ply:GetPos() + ply:GetUp() * (ply:OBBMaxs().z + 20)
        -- chatgpt scaling stuff
        -- to keep the triangle above the players head always
        local dist = EyePos():Distance(ply:GetPos())
        local offset = ply:OBBMaxs().z + math.Clamp(dist * 0.03, 5, 40)
        local pos = ply:GetPos() + Vector(0, 0, offset)
        local scale = dist * (fov / 90) / 6000
        --
        local angle = (pos - EyePos()):GetNormalized():Angle()
        angle = Angle(0, angle.y, 0)
        angle:RotateAroundAxis(angle:Up(), -90)
        angle:RotateAroundAxis(angle:Forward(), 90)
        cam.Start3D2D(pos, angle, scale)
        cam.IgnoreZ(true)
        local HPIndicativeDrawColor = color_healthy
        local PlayerHealth = ply:Health()
        if PlayerHealth <= 0 then
            cam.IgnoreZ(false)
            cam.End3D2D()
            continue -- ply:IsAlive does not update in time?
        end

        if PlayerHealth >= 50 then
            HPIndicativeDrawColor = color_notsohealthy
        elseif PlayerHealth >= 25 then
            HPIndicativeDrawColor = color_nothealthy
        elseif PlayerHealth >= 0 then
            HPIndicativeDrawColor = color_nothealthyatall
        end

        if ply.LastHealth and PlayerHealth < ply.LastHealth then
            ply.LostHealthOverride = CurTime()
            HPIndicativeDrawColor = color_losthealth
        end

        if ply.LostHealthOverride and ply.LostHealthOverride + 0.2 > CurTime() then -- 
            HPIndicativeDrawColor = color_losthealth
        end

        ply.LastHealth = PlayerHealth
        -- chevron
        draw.NoTexture()
        surface.SetDrawColor(HPIndicativeDrawColor)
        surface.DrawPoly(chevronleft)
        surface.DrawPoly(chevronright)
        -- name
        surface.SetFont("TeamIndicatorFont")
        local TextW, TextH = surface.GetTextSize(ply:Nick())
        draw.SimpleText(ply:Nick(), "TeamIndicatorFont", -TextW / 2, -ChevronHeight - TextH, HPIndicativeDrawColor)
        -- hp indicator
        local HPSquareGap = ScreenScale(45)
        local SquareSize = ScreenScale(25)
        local StartPos = -(4 * HPSquareGap - (HPSquareGap - SquareSize)) / 2
        local OutlineThickness = ScreenScale(3)
        for i = 1, math.Clamp(math.ceil(PlayerHealth / 25), 1, 4) do
            surface.SetDrawColor(HPIndicativeDrawColor)
            surface.DrawRect(StartPos + (i - 1) * HPSquareGap, -ChevronHeight + -ScreenScaleH(5), SquareSize, SquareSize)
            surface.SetDrawColor(color_black)
            surface.DrawOutlinedRect(StartPos + (i - 1) * HPSquareGap, -ChevronHeight + -ScreenScaleH(5), SquareSize, SquareSize, OutlineThickness)
        end

        -- armor indicator
        cam.IgnoreZ(false)
        cam.End3D2D()
    end
end)

--[[------------------------------
    Remove conflicting hooks
--------------------------------]]
local rv_outlinesconvar = CreateClientConVar("rv_outlines", 1, true, false, "Whether or not to draw the outlines on players", 0, 1)
local rv_outlinesdotconvar = CreateClientConVar("rv_outlinesdot", 0.75, true, false, "Dot product for outlines, if the player is too far away from your crosshair they won't be outlined.", 0, 1)
local rv_outlinesmaxplayersconvar = CreateClientConVar("rv_outlinesmaxplayers", 3, true, false, "Maximum players to be outlined, players closer to your crosshair take higher priority.", 1, 100)
local rv_outlinescolorconvar = CreateClientConVar("rv_outlinescolor", "255 0 255 255", true, true, "Color of outlines. 1 - 255 <r g b a>")
local rv_outlinesthicknessconvar = CreateClientConVar("rv_outlinesthickness", "1", true, false, "Thickness of outlines.", 1, 1000)
rv_outlinescolorstringcolor = Color(string.Split(rv_outlinescolorconvar:GetString(), " ")[1], string.Split(rv_outlinescolorconvar:GetString(), " ")[2], string.Split(rv_outlinescolorconvar:GetString(), " ")[3], string.Split(rv_outlinescolorconvar:GetString(), " ")[4] or 255)
cvars.AddChangeCallback("rv_outlinescolor", function(convar_name, value_old, value_new)
    local Split = string.Split(GetConVar("rv_outlinescolor"):GetString(), " ")
    rv_outlinescolorstringcolor = Color(Split[1], Split[2], Split[3], Split[4] or 255)
end, "rv_outlinescolor")

local rv_outlinesdotfloat = rv_outlinesdotconvar:GetFloat()
cvars.AddChangeCallback("rv_outlinesdot", function(convar_name, value_old, value_new) rv_outlinesdotfloat = tonumber(value_new) end, "rv_outlinesdot")
local rv_outlinesmaxplayersint = rv_outlinesmaxplayersconvar:GetInt()
cvars.AddChangeCallback("rv_outlinesmaxplayers", function(convar_name, value_old, value_new) rv_outlinesmaxplayersint = tonumber(value_new) end, "rv_outlinesmaxplayers")
rv_outlinesthicknessint = rv_outlinesthicknessconvar:GetInt()
cvars.AddChangeCallback("rv_outlinesthickness", function(convar_name, value_old, value_new) rv_outlinesthicknessint = tonumber(value_new) end, "rv_outlinesthickness")
rv_outlinesbool = tobool(rv_outlinesconvar:GetBool())
hook.Remove("PrePlayerDraw", "DuelDollModel")
hook.Remove("PostPlayerDraw", "DuelDollModel")
hook.Remove("ShouldCollide", "MakePlayersNotCollide")
hook.Remove("ShouldCollide", "MakeDuelPlayersNotCollide")
--[[
        AddGamemodeHook("ShouldCollide", "ShouldCollideConflictFix", function(ent1, ent2)
            --
            return true
        end, PRE_HOOK_RETURN)
        --]]
for _, ply in player.Iterator() do
    if ply.Doll then --
        ply.Doll:Remove()
    end
end

local function rv_drawoutlines()
    if ShouldRunHook() == false then return end
    if rv_outlinesbool == false then -- unnecessary but whatever
        return
    end

    PlayersDrawn = 0
    OutlineCandidates = {}
    thickness = rv_outlinesthicknessint
    local ShouldDraw = nil
    for _, ply in player.Iterator() do
        if not IsValid(ply) then continue end
        if not ply:Alive() then continue end
        if ply == LocalPlayer() then continue end
        if ply:GetNoDraw() == true then continue end
        local DistToTarg = (ply:GetPos() - LocalPlayer():GetShootPos()):GetNormalized()
        local dot = LocalPlayer():GetAimVector():Dot(DistToTarg)
        ShouldDraw = dot >= rv_outlinesdotfloat
        if ShouldDraw then OutlineCandidates[ply] = dot end
    end

    for candidate, v in SortedPairsByValue(OutlineCandidates, true) do
        if not IsValid(candidate) then continue end
        ShouldDraw = PlayersDrawn < rv_outlinesmaxplayersint
        local IsInSameDuel = candidate:Team() ~= LocalPlayer():Team()
        if ShouldDraw and IsInSameDuel then
            outline.Add(candidate, rv_outlinescolorstringcolor, 2, rv_outlinesthicknessint)
            PlayersDrawn = PlayersDrawn + 1
        end
    end
end

AddGamemodeHook("PreDrawOutlines", "rv_outlines", rv_drawoutlines, PRE_HOOK_RETURN)