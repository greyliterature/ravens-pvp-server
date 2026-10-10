rv_gm = {}
--[[------------------------------
    Init
--------------------------------]]
local TEAM_RED, TEAM_BLUE = 1, 2
--[[------------------------------
    Match system
--------------------------------]]
function rv_gm.GetScoreLimit()
    return GetGlobal3("MatchScoreLimit", 10)
end

function rv_gm.IsMatchInProgress()
    return GetGlobal3("MatchInProgress", false)
end

--[[------------------------------
    Triggers
--------------------------------]]
local TriggerParents = {}
function rv_gm.GetAllTriggerParents()
    return TriggerParents
end

net.Receive("TriggerParentMade", function(_, _)
    local triggerparent = net.ReadEntity()
    TriggerParents[#TriggerParents + 1] = triggerparent
    print("got ", triggerparent)
end)

AddGamemodeHook("PostDrawOpaqueRenderables", "ShowTriggers", function()
    for i, infoparent in ipairs(rv_gm.GetAllTriggerParents()) do
        if not IsValid(infoparent) then
            TriggerParents[i] = nil
            continue
        end

        local mins, maxes = infoparent:GetCollisionBounds()
        local pos, angs = infoparent:GetPos(), infoparent:GetAngles()
        local infoparentcolor = infoparent:GetColor()
        infoparentcolor.a = 255
        render.DrawWireframeBox(pos, angs, mins, maxes, infoparentcolor, true)
    end
end)

--[[------------------------------
    Remove conflicting hooks (FFA)
--------------------------------]]
function rv_gm.SetPlayerOutlineFlip(bool)
    PlayerTeamOutlineFlip = bool
end

function rv_gm.RemoveConflictingHooks()
    hook.Remove("PrePlayerDraw", "DuelDollModel")
    hook.Remove("PostPlayerDraw", "DuelDollModel")
    hook.Remove("ShouldCollide", "MakePlayersNotCollide")
    hook.Remove("ShouldCollide", "MakeDuelPlayersNotCollide")
    for _, ply in player.Iterator() do
        if ply.Doll then --
            ply.Doll:Remove()
        end
    end
end

--[[------------------------------
    CTF (shared because maybe its needed in another mode)
--------------------------------]]
local CTFEntities = {}
local CTFFlags = {}
local CTFFlagBases = {}
local DollFlagModel = "models/maxofs2d/companion_doll.mdl"
local FlagBaseModel = "models/props_c17/gravestone_cross001b.mdl"
net.Receive("CTFEntityCreated", function(_, _)
    local CTFEntity = net.ReadEntity()
    if not IsValid(CTFEntity) then return end
    local TeamIndex = net.ReadUInt(7)
    print("Got info for " .. CTFEntity:EntIndex(), CTFEntity:GetModel())
    if CTFEntity:GetModel() == DollFlagModel then
        CTFEntity.AtBase = true
        CTFFlags[#CTFFlags + 1] = CTFEntity
    elseif CTFEntity:GetModel() == FlagBaseModel then
        CTFFlagBases[#CTFFlagBases + 1] = CTFEntity
    else
        ErrorNoHaltWithStack("Unaccounted CTF ent model")
    end

    CTFEntity.TeamIndex = TeamIndex
    CTFEntities[#CTFEntities + 1] = CTFEntity
end)

net.Receive("InitCTFEntities", function(_, _)
    CTFEntities = {}
    CTFFlags = {}
    CTFFlagBases = {}
    local NumKeys = net.ReadUInt(6)
    for i = 1, NumKeys do
        local CTFEntity = net.ReadEntity()
        local TeamIndex = net.ReadUInt(7)
        if CTFEntity:GetModel() == DollFlagModel then
            CTFFlags[#CTFFlags + 1] = CTFEntity
        elseif CTFEntity:GetModel() == FlagBaseModel then
            CTFFlagBases[#CTFFlagBases + 1] = CTFEntity
        else
            ErrorNoHaltWithStack("Unaccounted CTF ent model")
        end

        CTFEntity.TeamIndex = TeamIndex
        CTFEntities[#CTFEntities + 1] = CTFEntity
    end
end)

function rv_gm.GetAllCTFFlags()
    return CTFFlags
end

function rv_gm.GetAllCTFFlagBases()
    return CTFFlagBases
end

function rv_gm.GetAllCTFEntities()
    return CTFEntities
end

net.Receive("PlayerPickedUpCTFEntity", function(_, _)
    local PickedUp = net.ReadBool()
    local ent = net.ReadEntity()
    local ply = net.ReadPlayer()
    ent.PickedUpPly = (PickedUp == true and ply) or nil
    if ent.PickedUpPly and ent.PickedUpPly:Team() == ent.TeamIndex then
        ent.AtBase = true
    elseif ent.PickedUpPly and ent.PickedUpPly:Team() ~= ent.TeamIndex then
        ent.AtBase = nil
    end

    hook.Run("rv_gm.PlayerPickedUpCTFEntity", ply, ent, PickedUp)
end)

net.Receive("RevealFlag", function(_, _)
    local revealedply = net.ReadPlayer()
    local ent = net.ReadEntity()
    local Revealed = net.ReadBool()
    hook.Run("rv_gm.FlagRevealed", revealedply, ent, Revealed)
end)

net.Receive("DollRTBed", function(_, _)
    local doll = net.ReadEntity()
    hook.Run("rv_gm.FlagRTBed", doll)
end)

--[[------------------------------
    Join team menu
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

-- Returns blue, unless red has less players. Then it returns red.
local function GetLowestTeam()
    local LowestTeam = TEAM_BLUE
    local RedPlayers = #team.GetPlayers(TEAM_RED)
    local BluePlayers = #team.GetPlayers(TEAM_BLUE)
    if RedPlayers < BluePlayers then LowestTeam = TEAM_RED end
    return LowestTeam
end

local rv_spawnweapon = CreateClientConVar("rv_spawnweapon", "weapon_357", true, true, "what weapon to pull out on spawn (an alternative to cl_defaultweapon)")
local debugging = true
local JoinTeamPopup = (debugging == true and true) or false
function rv_gm.OpenJoinTeamPopup()
    JoinTeamPopup = true
    local RankedMatch = GetGlobal3("RankedMatch") --GamemodeVars.RankedMatch
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
        {GetGlobal3("CurrentGamemode") .. " - " .. game.GetMap(), "RobotoBig"},
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

AddGamemodeHook("PlayerButtonDown", "JoinTeamPopup", function(ply, button)
    if JoinTeamPopup == false then return end
    if button == KEY_F4 then
        rv_gm.OpenJoinTeamPopup()
        hook.Remove("HUDPaint", "TeamJoinMenuReminder")
    end
end)

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
AddGamemodeHook("HUDPaint", "NotifsHUD", function()
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
    Lock attacks (for match / round start delay)
--------------------------------]]
net.Receive("LockAttacks", function(len, _)
    local StartDate = net.ReadFloat()
    AddGamemodeHook("StartCommand", "LockAttacks", function(ply, cmd)
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
return rv_gm
