
    --[[--------------------------------------
    panel tests
    ----------------------------------------]]
    surface.CreateFont("HL2MPSmall", {
        font = "HL2MP",
        extended = false,
        size = ScrW() * 0.04,
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

    surface.CreateFont("Roboto_Black", {
        font = "Roboto Bk",
        extended = false,
        size = 56,
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

    surface.CreateFont("Roboto_Medium", {
        font = "Roboto Lt",
        extended = false,
        size = 56,
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

    surface.CreateFont("Stratum_Bold", {
        font = "StratumNo2 BSD",
        extended = false,
        size = 56,
        weight = 700,
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

    surface.CreateFont("Stratum_Bold_Small", {
        font = "StratumNo2 BSD",
        extended = false,
        size = 36,
        weight = 700,
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

    surface.CreateFont("Stratum_Bold_Smaller", {
        font = "StratumNo2 BSD",
        extended = false,
        size = 20,
        weight = 700,
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

    surface.CreateFont("Stratum_Bold_Smallest", {
        font = "StratumNo2 BSD",
        extended = false,
        size = 12,
        weight = 700,
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

    --[[--]]
    surface.CreateFont("ChatFont_Small", {
        font = "Verdana",
        extended = false,
        size = 13,
        weight = 700,
        blursize = 0,
        scanlines = 0,
        antialias = true,
        underline = false,
        italic = false,
        strikeout = false,
        symbol = false,
        rotary = false,
        shadow = true,
        additive = false,
        outline = false,
    })

    --[[--------------------------------------
        Colors
    ----------------------------------------]]
    local color_grey = Color(75, 75, 75)
    local color_lightgrey = Color(125, 125, 125)
    local color_darken = Color(0, 0, 0, 200)
    local color_transparentish_black = Color(0, 0, 0, 200)
    local color_null = Color(0, 0, 0, 0)
    local color_csgogrey = Color(190, 186, 187)
    local color_csgodarkgrey = Color(124, 121, 114)
    local color_green = Color(83, 192, 83)
    local color_fadedyellow = Color(200, 200, 93)
    local color_fadedred = Color(132, 40, 36)
    --[[--------------------------------------
        Materials
    ----------------------------------------]]
    local Gradient = Material("vgui/gradient_up")
    local Gradient2 = Material("vgui/gradient_down")
    local Splash = CreateMaterial("leaderboard_splash_a229", "UnlitGeneric", {
        ["$basetexture"] = "gm_construct/grass_clouds",
        ["$basetexturetransform"] = "center .5 .5 scale 1 1 rotate 0 translate 0 0",
        ["Proxies"] = {
            ["TextureScroll"] = {
                ["texturescrollvar"] = "$basetexturetransform",
                ["texturescrollrate"] = "0.01",
                ["texturescrollangle"] = "30"
            }
        }
    })

    --[[--------------------------------------
        Helpers
    ----------------------------------------]]
    local function GetTextSize(font, text)
        surface.SetFont(font)
        return surface.GetTextSize(text)
    end

    --[[--------------------------------------
        UI
    ----------------------------------------]]
    local RNDX = include("autorun/rndx.lua")
    if IsValid(Panel) then Panel:Remove() end
    Panel = vgui.Create("DPanel")
    Panel:SetWide(ScrW() * 0.7)
    Panel:SetX((ScrW() - Panel:GetWide()) * 0.5)
    Panel:SetTall(ScrH() * 0.75)
    Panel:SetY((ScrH() - Panel:GetTall()) * 0.5)
    Panel:MakePopup()
    Panel:SetMouseInputEnabled(true)
    local OutlineThickness = 2
    local BlurPasses = 6
    function Panel.Paint(self, w, h)
        -- splash design inspired by:
        -- https://cdn.sanity.io/images/ccckgjf9/production/9f6e42788183ac704e81f4067da511b8347d6ac5-1440x1080.jpg?max-h=1080&max-w=1920&q=50&fit=scale&auto=format
        --surface.DrawTexturedRect(0, 0, w, h)
        surface.SetDrawColor(color_white)
        surface.SetMaterial(Splash)
        surface.DrawTexturedRect(0, 0, w, h)
        surface.SetDrawColor(Color(0, 128, 128, 240))
        surface.SetMaterial(Gradient)
        surface.DrawTexturedRect(0, 0, w, h)
        surface.SetDrawColor(Color(255, 128, 0, 120))
        surface.SetMaterial(Gradient2)
        surface.DrawTexturedRect(0, 0, w, h)
        local OutlineOffset = 15
        for i = 1, BlurPasses do
            -- the gpu will suffer a bit, but its ok, blur is necessary for good ui
            RNDX.Draw(0, 0 + i * OutlineOffset, 0 + i * OutlineOffset, w - i * OutlineOffset * 2, h - i * OutlineOffset * 2, color_white, RNDX.BLUR)
            -- if we dont offset by i * x, then the blur will bleed edges too hard
        end

        surface.SetDrawColor(color_darken)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(color_grey)
        surface.DrawOutlinedRect(0, 0, w, h, OutlineThickness) -- we need to hide this awful blur edge
    end

    function Panel.OnMousePressed(self, code)
        print("CLICK")
        Panel:Remove()
    end

    -- ui design inspired by https://steamhistory.net
    local MarginFromEdge = ScrW() * 0.007
    local AvatarSize = Panel:GetWide() * 0.075
    local PlayerInfoHolder = vgui.Create("DPanel", Panel)
    PlayerInfoHolder:SetPos(MarginFromEdge, MarginFromEdge)
    local PlayerNick = " ^8511^0scripture^5 @_@^8 #PVPE&L"
    local NickFont = "Stratum_Bold_Small"
    surface.SetFont(NickFont)
    local NickHolderGap = ScrW() * 0.01
    local MarginRightOfNickHolder = ScrW() * 0.005
    local AvatarMargin = ScrW() * 0.005
    local TextW, _ = surface.GetTextSize(PlayerNick)
    PlayerInfoHolder:SetSize(AvatarSize + NickHolderGap + AvatarMargin + MarginRightOfNickHolder + math.max(Panel:GetWide() * 0.15, TextW), AvatarSize + AvatarMargin * 2)
    function PlayerInfoHolder.Paint(self, w, h)
        surface.SetDrawColor(color_transparentish_black)
        surface.DrawRect(0, 0, w, h)
    end

    local Avatar = vgui.Create("AvatarImage", PlayerInfoHolder)
    Avatar:SetSteamID("76561198239588280")
    Avatar:SetPos(AvatarMargin, AvatarMargin)
    Avatar:SetSize(AvatarSize, AvatarSize)
    local NickHolder = vgui.Create("DPanel", PlayerInfoHolder)
    NickHolder.Text = PlayerNick
    NickHolder.Font = NickFont
    surface.SetFont(NickHolder.Font)
    NickHolder:SetX(Avatar:GetWide() + NickHolderGap)
    NickHolder:SetY(Avatar:GetY())
    NickHolder:SetWide(PlayerInfoHolder:GetWide())
    NickHolder:SetTall(PlayerInfoHolder:GetTall())
    function NickHolder:Paint(w, h)
        draw.DrawText(self.Text, self.Font, 0, 0, color_black, TEXT_ALIGN_LEFT)
    end

    local HeaderGap = ScrH() * 0.01
    local HeaderThickness = ScrH() * 0.002
    local Header = vgui.Create("DPanel", Panel)
    Header:SetY(PlayerInfoHolder:GetTall() + PlayerInfoHolder:GetY() + HeaderGap)
    Header:SetX(OutlineThickness) -- margining
    Header:SetTall(HeaderThickness)
    Header:SetWide(Panel:GetWide())
    function Header.Paint(self, w, h)
        surface.SetDrawColor(color_lightgrey)
        surface.DrawRect(0, 0, w, h)
    end

    --[[
    local SGrid = vgui.Create("SGrid", Panel)
    SGrid:SetTall(50)
    for i = 1, 5 do
        local InnerPanel = vgui.Create("DPanel")
        function InnerPanel.Paint(self, w, h)
            surface.SetDrawColor(ColorRand())
            surface.DrawRect(0, 0, w, h)
        end

        InnerPanel:SetWide(math.random(1, 25))
        SGrid:AddItem(InnerPanel)
    end
    --]]
    local function InfoHolder(parent, PanelWide, PanelTall, HeaderText, HeaderFont, HeaderColor, HeaderMarginX, HeaderMarginY)
        local panel = vgui.Create("DPanel", parent)
        panel:SetWide(PanelWide)
        panel:SetTall(PanelTall)
        function panel.Paint(self, w, h)
            surface.SetDrawColor(color_transparentish_black)
            surface.DrawRect(0, 0, w, h)
        end

        local header = vgui.Create("DPanel", panel)
        header:SetPos(HeaderMarginX, HeaderMarginY or 0)
        local _, TextH = GetTextSize(HeaderFont, HeaderText)
        header:SetWide(panel:GetWide())
        header:SetTall(TextH)
        function header:Paint(w, h)
            draw.DrawText(HeaderText, HeaderFont, 0, 0, HeaderColor, TEXT_ALIGN_LEFT)
        end
        return panel
    end

    local WeaponStats = InfoHolder(Panel, Panel:GetWide() * 0.5, 128, "Weapon Kills", "Stratum_Bold_Smaller", color_csgogrey, Panel:GetWide() * 0.01, Panel:GetTall() * 0.01)
    local Percents = {1 / 8, 1 / 8, 1 / 8, 1 / 8, 1 / 8, 1 / 8, 1 / 8, 1 / 8}
    local Labels = {{"Crowbar", "9MM", "357", "SMG", "AR2", "Shotgun", "Crossbow", "Grenade"},}
    local Colors = {
        [1] = {Color(128, 128, 0), Color(128, 0, 128), Color(0, 0, 128), Color(0, 128, 0), Color(128, 128, 128), Color(0, 0, 0, 255), Color(0, 255, 255)},
    }

    local BottomMarginFromEdge = MarginFromEdge --Panel:GetTall() * 0.03
    WeaponStats:SetSize(ScrW() * 0.23, ScrH() * 0.33)
    WeaponStats:SetPos((Panel:GetWide() - WeaponStats:GetWide()) - BottomMarginFromEdge, Panel:GetTall() - WeaponStats:GetTall() - BottomMarginFromEdge)
    local PieChart = vgui.Create("SPieChart", WeaponStats)
    --PieChart:SetPos(Panel:GetWide() * 0.25, Panel:GetTall() * 0.5)
    PieChart:SetPercents(Percents)
    PieChart:SetLabels(Labels[1])
    PieChart:SetColors(Colors[1])
    PieChart:SetInnerCirclePercentage(0.7)
    PieChart:SetOutlineThickness(2)
    --PieChart:SetBackgroundColor(color_white)
    local PieChartSize = ScrH() * 0.19
    PieChart:SetSize(PieChartSize, PieChartSize)
    PieChart:SetPos(WeaponStats:GetWide() * 0.05, WeaponStats:GetTall() * 0.25)
    local LabelHolder = vgui.Create("SLabelHolder", WeaponStats)
    LabelHolder:SetBackgroundColor(color_null)
    --LabelHolder:SetTall(LabelHolder:GetRowHeight() * 7)
    LabelHolder:SetLabelFont("Stratum_Bold_Smaller")
    LabelHolder:SetLabelBoxHeight(0.015)
    LabelHolder:SetLabelBoxWidth(0.015)
    LabelHolder:SetColumnCount(1)
    -- you have to set the font and anything that changes width BEFORE calling attach
    LabelHolder:SetWide(WeaponStats:GetWide() * 0.45)
    LabelHolder:Attach(PieChart) --, {1, 2, 3, 4})
    LabelHolder:SetX(PieChart:GetWide() * 1.3)
    LabelHolder:SetY(PieChart:GetY() + (PieChart:GetTall() - LabelHolder:GetTall()) * 0.3)
    LabelHolder:SetOverallAlignment(SGRID_ALIGN_LEFT)
    --[[
    -- MAKE THIS WORK LATER, SETTING AS TWO COLUMNS IS BETTER THAN MESSING WITH ARRANGEMENT
    local LabelHolder_2 = vgui.Create("SLabelHolder", WeaponStats)
    LabelHolder_2:SetBackgroundColor(color_null)
    LabelHolder_2:SetLabelFont("Stratum_Bold_Smallest")
    LabelHolder_2:SetLabelBoxHeight(0.01)
    LabelHolder_2:SetLabelBoxWidth(0.01)
    LabelHolder_2:SetColumnCount(1)
    LabelHolder_2:SetWide(WeaponStats:GetWide() * 0.276)
    LabelHolder_2:SetTall(PieChart:GetTall())
    LabelHolder_2:Attach(PieChart, {5, 6, 7, 8})
    LabelHolder_2:SetX(LabelHolder:GetX() + LabelHolder:GetWide())
    LabelHolder_2:SetY(LabelHolder:GetY())
    LabelHolder_2:SetOverallAlignment(SGRID_ALIGN_LEFT)
    --]]
    --[[
    function LabelHolder:Paint(w, h)
        surface.DrawRect(0, 0, w, h)
    end
    --]]
    --LabelHolder:SetY(PieChart:GetY() + PieChart:GetTall() + LabelHolderGap)
    --LabelHolder:SetX(PieChart:GetX() + (PieChart:GetWide() - LabelHolder:GetWide()) * 0.5)
    --LabelHolder:SetX(PieChart:GetX())
    --LabelHolder:SetJustify(PieChart:GetX())
    local MapPerformance = InfoHolder(Panel, Panel:GetWide() * 0.5, 128, "Map Win Rates", "Stratum_Bold_Smaller", color_csgogrey, Panel:GetWide() * 0.01, Panel:GetTall() * 0.01)
    MapPerformance:SetSize(ScrW() * 0.23, WeaponStats:GetTall())
    MapPerformance:SetY(Panel:GetTall() - MapPerformance:GetTall() - BottomMarginFromEdge)
    MapPerformance:SetX((WeaponStats:GetX() - MapPerformance:GetWide()) - BottomMarginFromEdge)
    local Percents_2 = {4.5, 2, 4, 4, 5, 7, 8, 8}
    local RadarChart = vgui.Create("SRadarChart", MapPerformance)
    local RadarChartSize = ScrH() * 0.3
    RadarChart:SetSize(RadarChartSize, RadarChartSize)
    local MarginDown = ScrH() * 0.013
    RadarChart:SetX((MapPerformance:GetWide() - RadarChart:GetWide()) * 0.5)
    RadarChart:SetY((MapPerformance:GetTall() - RadarChart:GetTall()) * 0.5 + MarginDown)
    --RadarChart:SetRadarColor()
    --RadarChart:SetSegmentCount(9)
    RadarChart:SetPercents(Percents_2)
    local IconWSIDs = {"105982362", "3667352947", "3769721895", "3751308439", "3751311698", "3707205770", "3705916707", "3769721895"}
    local IconMaterials = {}
    for i = 1, #IconWSIDs do
        steamworks.FileInfo(IconWSIDs[i], function(result)
            steamworks.Download(result.previewid, true, function(name)
                --
                IconMaterials[#IconMaterials + 1] = AddonMaterial(name)
            end)
        end)
    end

    local function HasLoadedEverything()
        return #IconMaterials == #IconWSIDs
    end

    local RectWidthPercentage = 0.15
    local RectDistPercentage = 0.4
    local function DrawMapRect(w, h, segmentX, segmentY, SegmentIndex)
        if not HasLoadedEverything() then return end
        local cx = w * 0.5 -- we know cx is always this so it doesnt have to be passed
        local cy = cx
        local distx, disty = segmentX - cx, segmentY - cy
        local newX = segmentX + distx * RectDistPercentage
        local newY = segmentY + disty * RectDistPercentage
        local RectWidth = w * RectWidthPercentage
        surface.SetMaterial(IconMaterials[SegmentIndex])
        surface.SetDrawColor(color_white)
        surface.DrawTexturedRect(newX - RectWidth * 0.5, newY - RectWidth * 0.5, RectWidth, RectWidth)
        surface.SetDrawColor(color_black)
        surface.DrawOutlinedRect(newX - RectWidth * 0.5, newY - RectWidth * 0.5, RectWidth, RectWidth, 1)
    end

    local LabelFuncs = {}
    for i = 1, #IconWSIDs do
        LabelFuncs[i] = function(w, h, segmentX, segmentY)
            -- 
            DrawMapRect(w, h, segmentX, segmentY, i)
        end
    end

    RadarChart:SetLabels(LabelFuncs)
    local MatchesPlayed = InfoHolder(Panel, Panel:GetWide() * 0.5, 128, "Matches Played", "Stratum_Bold_Smaller", color_csgogrey, Panel:GetWide() * 0.01, Panel:GetTall() * 0.01)
    MatchesPlayed:SetX(MapPerformance:GetX())
    MatchesPlayed:SetY(Header:GetY() + MarginFromEdge)
    MatchesPlayed:SetWide(ScrW() * 0.10)
    MatchesPlayed:SetTall(MapPerformance:GetY() - MatchesPlayed:GetY() - MarginFromEdge)
    local MatchesPlayed_number = 243
    local Wins = 0
    local Ties = 0
    local Losses = 7
    local DotsHeight = Panel:GetWide() * 0.01
    local DotsY = ScrH() * 0.19
    local DotsMargin = ScrH() * 0.015
    local DotRadius = ScrH() * 0.005
    local TextMargin = ScrW() * 0.007
    local function DrawDot(x, y)
        draw.NoTexture()
        draw.Circle(x, y, DotRadius, 255)
    end

    function MatchesPlayed.PaintOver(self, w, h)
        draw.DrawText(MatchesPlayed_number, "Stratum_Bold", Panel:GetWide() * 0.01, h * 0.1, color_csgogrey, TEXT_ALIGN_LEFT)
        surface.SetDrawColor(color_green)
        --draw.Circle(DotsMargin, DotsY, h * 0.02, 255)
        DrawDot(DotsMargin, DotsY)
        draw.SimpleText("Wins", "Stratum_Bold_Smaller", DotsHeight + TextMargin, DotsY + DotsMargin * 0, color_csgodarkgrey, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(Wins, "Stratum_Bold_Smaller", w - DotsMargin, DotsY + DotsMargin * 0, color_csgogrey, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(color_fadedyellow)
        DrawDot(DotsMargin, DotsY + DotsMargin * 1)
        draw.SimpleText("Ties", "Stratum_Bold_Smaller", DotsHeight + TextMargin, DotsY + DotsMargin * 1, color_csgodarkgrey, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(Ties, "Stratum_Bold_Smaller", w - DotsMargin, DotsY + DotsMargin * 1, color_csgogrey, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(color_fadedred)
        DrawDot(DotsMargin, DotsY + DotsMargin * 2)
        draw.SimpleText("Losses", "Stratum_Bold_Smaller", DotsHeight + TextMargin, DotsY + DotsMargin * 2, color_csgodarkgrey, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(Losses, "Stratum_Bold_Smaller", w - DotsMargin, DotsY + DotsMargin * 2, color_csgogrey, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    ----
    local SeperatorY = Panel:GetTall() * 0.01
    local ADM = InfoHolder(Panel, Panel:GetWide() * 0.5, 128, "ADM", "Stratum_Bold_Smaller", color_csgogrey, Panel:GetWide() * 0.01, Panel:GetTall() * 0.01)
    ADM:SetX(MatchesPlayed:GetX() + MatchesPlayed:GetWide())
    ADM:SetY(Header:GetY() + MarginFromEdge)
    ADM:SetWide(ScrW() * 0.10)
    ADM:SetTall(MapPerformance:GetY() - MatchesPlayed:GetY() - MarginFromEdge)
    local ADM_number = 76.9
    local Damage = 143532
    Damage = math.Truncate(Damage / 1000, 1) .. "k"
    local Joins = 4007
    function ADM.PaintOver(self, w, h)
        surface.SetDrawColor(color_csgogrey)
        surface.DrawRect(0, SeperatorY, 1, h - SeperatorY * 2)
        draw.DrawText(ADM_number, "Stratum_Bold", Panel:GetWide() * 0.01, h * 0.1, color_csgogrey, TEXT_ALIGN_LEFT)
        -- bottom
        draw.SimpleText("Damage", "Stratum_Bold_Smaller", TextMargin, DotsY + DotsMargin * 1, color_csgodarkgrey, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(Damage, "Stratum_Bold_Smaller", w - DotsMargin, DotsY + DotsMargin * 1, color_csgogrey, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        --
        draw.SimpleText("Times joined", "Stratum_Bold_Smaller", TextMargin, DotsY + DotsMargin * 2, color_csgodarkgrey, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(Joins, "Stratum_Bold_Smaller", w - DotsMargin, DotsY + DotsMargin * 2, color_csgogrey, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    local Kills_Death = InfoHolder(Panel, Panel:GetWide() * 0.5, 128, "Kills/Death", "Stratum_Bold_Smaller", color_csgogrey, Panel:GetWide() * 0.01, Panel:GetTall() * 0.01)
    Kills_Death:SetX(ADM:GetX() + ADM:GetWide())
    Kills_Death:SetY(Header:GetY() + MarginFromEdge)
    Kills_Death:SetWide(ScrW() * 0.10)
    Kills_Death:SetTall(MapPerformance:GetY() - MatchesPlayed:GetY() - MarginFromEdge)
    local Kills = 114
    local Deaths = 100
    local KD = math.Truncate(Kills / Deaths, 2)
    function Kills_Death.PaintOver(self, w, h)
        surface.SetDrawColor(color_csgogrey)
        surface.DrawRect(0, SeperatorY, 1, h - SeperatorY * 2)
        draw.DrawText(KD, "Stratum_Bold", Panel:GetWide() * 0.01, h * 0.1, color_csgogrey, TEXT_ALIGN_LEFT)
        -- bottom
        draw.SimpleText("Kills", "Stratum_Bold_Smaller", TextMargin, DotsY + DotsMargin * 1, color_csgodarkgrey, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(Kills, "Stratum_Bold_Smaller", w - DotsMargin, DotsY + DotsMargin * 1, color_csgogrey, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        --
        draw.SimpleText("Deaths", "Stratum_Bold_Smaller", TextMargin, DotsY + DotsMargin * 2, color_csgodarkgrey, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(Deaths, "Stratum_Bold_Smaller", w - DotsMargin, DotsY + DotsMargin * 2, color_csgogrey, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    local BestWeapon = InfoHolder(Panel, Panel:GetWide() * 0.5, 128, "Best Weapon", "Stratum_Bold_Smaller", color_csgogrey, Panel:GetWide() * 0.01, Panel:GetTall() * 0.01)
    BestWeapon:SetX(Kills_Death:GetX() + Kills_Death:GetWide())
    BestWeapon:SetY(Header:GetY() + MarginFromEdge)
    BestWeapon:SetWide(Panel:GetWide() - BestWeapon:GetX() - MarginFromEdge)
    BestWeapon:SetTall(MapPerformance:GetY() - MatchesPlayed:GetY() - MarginFromEdge)
    local WeaponToText = {
        weapon_357 = ".",
        weapon_ar2 = "2",
        weapon_crossbow = "1",
        weapon_pistol = "-",
        weapon_shotgun = "0",
        weapon_smg1 = "/",
    }

    local _WeaponStats = {
        {"weapon_357", 1.15, 38},
        --
        {"weapon_ar2", 0.6, 53},
        {"weapon_crossbow", 4.5, 264},
    }

    local WeaponsToDisplay = 3
    function BestWeapon.PaintOver(self, w, h)
        surface.SetDrawColor(color_csgogrey)
        surface.DrawRect(0, SeperatorY, 1, h - SeperatorY * 2)
        -- bottom
        draw.SimpleText("K/D", "Stratum_Bold_Smaller", w * 0.6, Panel:GetTall() * 0.01, color_csgodarkgrey, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        local MiniMargin = w * 0.025 -- Kills section is too close to the edge so move it a bit
        draw.SimpleText("Kills", "Stratum_Bold_Smaller", w - TextMargin - MiniMargin, Panel:GetTall() * 0.01, color_csgodarkgrey, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        for i = 1, WeaponsToDisplay do
            if _WeaponStats[i] then
                --
                local weap = _WeaponStats[i][1]
                local _KD = _WeaponStats[i][2]
                local _Kills = _WeaponStats[i][3]
                surface.SetFont("HL2MPSmall")
                local _, WeapH = surface.GetTextSize(WeaponToText[weap])
                local CurrentHeader = h * 0.3 * (i - 1) + Panel:GetTall() * 0.01 + WeapH * 1.05
                local LastHeader = h * 0.3 * (i - 2) + Panel:GetTall() * 0.01 + WeapH * 1.05
                --HeaderToRect - ((i == 1 and Panel:GetTall() * 0.01) or 0)
                draw.SimpleText(WeaponToText[weap], "HL2MPSmall", TextMargin, h * 0.3 * (i - 1) + Panel:GetTall() * 0.01 + h * 0.1, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                draw.SimpleText(_KD, "Stratum_Bold_Smaller", w * 0.6, (CurrentHeader + LastHeader) / 2, color_csgodarkgrey, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                draw.SimpleText(_Kills, "Stratum_Bold_Smaller", w - TextMargin - MiniMargin, (CurrentHeader + LastHeader) / 2, color_csgodarkgrey, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
                if i ~= WeaponsToDisplay then surface.DrawRect(TextMargin, h * 0.3 * (i - 1) + WeapH * 1.05 + Panel:GetTall() * 0.01, w - TextMargin * 2, 1) end
            end
        end
    end

    local MatchHistory = InfoHolder(Panel, Panel:GetWide() * 0.5, 128, "Match history", "Stratum_Bold_Smaller", color_csgogrey, Panel:GetWide() * 0.01, Panel:GetTall() * 0.01)
    MatchHistory:SetX(MarginFromEdge)
    MatchHistory:SetY(Header:GetY() + MarginFromEdge)
    MatchHistory:SetWide(MatchesPlayed:GetX() - MatchHistory:GetX() - MarginFromEdge)
    MatchHistory:SetTall(Panel:GetTall() - MatchHistory:GetY() - MarginFromEdge)
    -- {"105982362", "3667352947", "3769721895", "3751308439", "3751311698", "3707205770", "3705916707", "3769721895"}
    surface.SetFont("Stratum_Bold_Smaller")
    local _, TextH = surface.GetTextSize("Matches history")
    --MatchHistory:DockPadding(MarginFromEdge, Panel:GetWide() * 0.01 + TextH, MarginFromEdge, Panel:GetWide() * 0.01 + TextH)
    local MatchesHistory = {
        {
            map = "105982362",
            mapname = "gm_bigcity",
            winnersteamid64 = "765611982395",
            winnerscore = "16",
            loserscore = "9",
            losersteamid64 = "7656119877892",
            winnerglicko = 1300, -- this can be inferred from sql queries though, dont actually track this
            loserglicko = 15000,
        },
        {
            map = "105982362",
            mapname = "gm_bigcity",
            winnersteamid64 = "7656119877892",
            winnerscore = "20",
            loserscore = "7",
            losersteamid64 = "7656119823958",
            winnerglicko = 1300, -- this can be inferred from sql queries though, dont actually track this
            loserglicko = 15000,
        }
    }

    local MatchMapMaterials = {}
    for i = 1, #MatchesHistory do
        steamworks.FileInfo(MatchesHistory[i].map, function(result)
            steamworks.Download(result.previewid, true, function(name)
                --
                MatchMapMaterials[#MatchMapMaterials + 1] = AddonMaterial(name)
            end)
        end)
    end

    local function HasLoadedAllMatchMaps()
        return #MatchMapMaterials == #MatchesHistory
    end

    for i = 1, #MatchesHistory do
        local tbl = MatchesHistory[i]
        local MatchPanel = vgui.Create("DPanel", MatchHistory)
        --MatchPanel:Dock(TOP)
        local MatchPanelHeight = MatchHistory:GetTall() * 0.07
        MatchPanel:SetBackgroundColor(color_transparentish_black)
        MatchPanel:SetX(MarginFromEdge)
        MatchPanel:SetY(MatchPanelHeight * (i - 1) + Panel:GetWide() * 0.01 + TextH + ((i == 1 and 0) or MarginFromEdge * 0.5))
        MatchPanel:SetWide(MatchHistory:GetWide() - MarginFromEdge * 2)
        MatchPanel:SetTall(MatchPanelHeight)
        local MapRectSize = Panel:GetTall() * 0.03057
        function MatchPanel.Paint(self, w, h)
            if not HasLoadedAllMatchMaps() then return end
            surface.SetDrawColor(color_transparentish_black)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor((tbl.winnersteamid64 == LocalPlayer() and color_green) or (tbl.winnerscore == tbl.loserscore and color_fadedyellow) or color_fadedred)
            DrawDot(DotsMargin, h * 0.5)
            surface.SetDrawColor(color_white)
            surface.SetMaterial(MatchMapMaterials[i])
            surface.DrawTexturedRect(DotsMargin * 2, (h - MapRectSize) * 0.5, MapRectSize, MapRectSize)
            draw.SimpleText(tbl.mapname, "Stratum_Bold_Smaller", DotsMargin * 2 + w * 0.09, h * 0.5, color_csgodarkgrey, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(tbl.winnerscore .. " - " .. tbl.loserscore, "Stratum_Bold_Smaller", w * 0.5, h * 0.5, color_csgodarkgrey, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        local WinnerAvatar = vgui.Create("AvatarImage", MatchPanel)
        WinnerAvatar:SetSize(MapRectSize, MapRectSize)
        WinnerAvatar:SetSteamID(tbl.winnersteamid64)
        WinnerAvatar:SetPos(MatchPanel:GetWide() * 0.8, (MatchPanel:GetTall() - MapRectSize) * 0.5)
        WinnerAvatar:SetSize(MapRectSize, MapRectSize)
        WinnerAvatar:DrawOutlinedRect(3)
        function WinnerAvatar.PaintOver(self, w, h)
            surface.SetDrawColor(color_green)
            self:DrawOutlinedRect()
        end

        local LoserAvatar = vgui.Create("AvatarImage", MatchPanel)
        LoserAvatar:SetSize(MapRectSize, MapRectSize)
        LoserAvatar:SetSteamID(tbl.losersteamid64)
        LoserAvatar:SetPos(WinnerAvatar:GetX() + MapRectSize + MatchPanel:GetWide() * 0.01, (MatchPanel:GetTall() - MapRectSize) * 0.5)
        LoserAvatar:SetSize(MapRectSize, MapRectSize)
        LoserAvatar:DrawOutlinedRect(3)
        function LoserAvatar.PaintOver(self, w, h)
            surface.SetDrawColor(color_fadedred)
            self:DrawOutlinedRect()
        end
    end
end
