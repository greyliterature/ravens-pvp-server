-- this file is just used to track changes, it's not finished, it doesn't even run (relies on another library i'm working on still)
    --[[--------------------------------------
    panel tests
    ----------------------------------------]]
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
    Panel:SetWide(ScrW() * 0.45)
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
        function header.Paint(self, w, h)
        end

        function header:Paint(w, h)
            draw.DrawText(HeaderText, HeaderFont, 0, 0, HeaderColor, TEXT_ALIGN_LEFT)
        end
        return panel
    end

    local WeaponStats = InfoHolder(Panel, 256, 128, "Weapon kills", "Stratum_Bold_Smaller", color_csgogrey, Panel:GetWide() * 0.01, Panel:GetTall() * 0.01)
    local Percents = {1 / 4, 1 / 4, 1 / 4, 1 / 4}
    local Labels = {"Acc", "test", "label"}
    local Colors = {Color(128, 128, 0), Color(128, 0, 128), Color(0, 0, 128), Color(0, 128, 0), Color(128, 128, 128)}
    local PieChart = vgui.Create("SPieChart", WeaponStats)
    --PieChart:SetPos(Panel:GetWide() * 0.25, Panel:GetTall() * 0.5)
    PieChart:SetPercents(Percents)
    PieChart:SetLabels(Labels)
    PieChart:SetColors(Colors)
    PieChart:SetInnerCirclePercentage(0.7)
    PieChart:SetOutlineThickness(2)
    PieChart:SetBackgroundColor(color_white)
    local PieChartSize = WeaponStats:GetWide() * 0.35
    PieChart:SetSize(PieChartSize, PieChartSize)
    PieChart:SetPos(WeaponStats:GetWide() * 0.05, WeaponStats:GetTall() * 0.25)
    local LabelHolder = vgui.Create("SLabelHolder", WeaponStats)
    local LabelHolderGap = ScrH() * 0.02
    LabelHolder:SetBackgroundColor(color_null)
    --LabelHolder:SetTall(LabelHolder:GetRowHeight() * 7)
    LabelHolder:SetLabelFont("Stratum_Bold_Smallest")
    LabelHolder:SetLabelBoxHeight(0.01)
    LabelHolder:SetLabelBoxWidth(0.01)
    -- you have to set the font and anything that changes width BEFORE calling attach
    LabelHolder:SetWide(WeaponStats:GetWide() * 0.51)
    LabelHolder:Attach(PieChart)
    LabelHolder:SetPos(PieChart:GetWide() * 1.3, PieChart:GetY() + (PieChart:GetTall() - LabelHolder:GetTall()) * 0.5)
    --[[
    function LabelHolder:Paint(w, h)
        surface.DrawRect(0, 0, w, h)
    end
    --]]
    --LabelHolder:SetY(PieChart:GetY() + PieChart:GetTall() + LabelHolderGap)
    --LabelHolder:SetX(PieChart:GetX() + (PieChart:GetWide() - LabelHolder:GetWide()) * 0.5)
    --LabelHolder:SetX(PieChart:GetX())
    --LabelHolder:SetJustify(PieChart:GetX())
    LabelHolder:SetOverallAlignment(SGRID_ALIGN_LEFT)
end
