if SERVER then
    local LastTick = 0
    hook.Add("Think", "WriteServerTPS", function()
        local CurrTick = SysTime()
        local ServerTPS = 1 / (CurrTick - LastTick)
        LastTick = CurrTick
        Entity(0):SetNWFloat("ServerTPS", ServerTPS)
    end)

    local WhitelistedCountries = {
        ["ad"] = true,
        ["ae"] = true,
        ["af"] = true,
        ["ag"] = true,
        ["ai"] = true,
        ["al"] = true,
        ["am"] = true,
        ["an"] = true,
        ["ao"] = true,
        ["ar"] = true,
        ["as"] = true,
        ["at"] = true,
        ["au"] = true,
        ["aw"] = true,
        ["ax"] = true,
        ["az"] = true,
        ["ba"] = true,
        ["bb"] = true,
        ["bd"] = true,
        ["be"] = true,
        ["bf"] = true,
        ["bg"] = true,
        ["bh"] = true,
        ["bi"] = true,
        ["bj"] = true,
        ["bm"] = true,
        ["bn"] = true,
        ["bo"] = true,
        ["br"] = true,
        ["bs"] = true,
        ["bt"] = true,
        ["bv"] = true,
        ["bw"] = true,
        ["by"] = true,
        ["bz"] = true,
        ["ca"] = true,
        ["catalonia"] = true,
        ["cc"] = true,
        ["cd"] = true,
        ["cf"] = true,
        ["cg"] = true,
        ["ch"] = true,
        ["ci"] = true,
        ["ck"] = true,
        ["cl"] = true,
        ["cm"] = true,
        ["cn"] = true,
        ["co"] = true,
        ["cr"] = true,
        ["cs"] = true,
        ["cu"] = true,
        ["cv"] = true,
        ["cx"] = true,
        ["cy"] = true,
        ["cz"] = true,
        ["de"] = true,
        ["dj"] = true,
        ["dk"] = true,
        ["dm"] = true,
        ["do"] = true,
        ["dz"] = true,
        ["ec"] = true,
        ["ee"] = true,
        ["eg"] = true,
        ["eh"] = true,
        ["england"] = true,
        ["er"] = true,
        ["es"] = true,
        ["et"] = true,
        ["europeanunion"] = true,
        ["fam"] = true,
        ["fi"] = true,
        ["fj"] = true,
        ["fk"] = true,
        ["fm"] = true,
        ["fo"] = true,
        ["fr"] = true,
        ["ga"] = true,
        ["gb"] = true,
        ["gd"] = true,
        ["ge"] = true,
        ["gf"] = true,
        ["gh"] = true,
        ["gi"] = true,
        ["gl"] = true,
        ["gm"] = true,
        ["gn"] = true,
        ["gp"] = true,
        ["gq"] = true,
        ["gr"] = true,
        ["gs"] = true,
        ["gt"] = true,
        ["gu"] = true,
        ["gw"] = true,
        ["gy"] = true,
        ["hk"] = true,
        ["hm"] = true,
        ["hn"] = true,
        ["hr"] = true,
        ["ht"] = true,
        ["hu"] = true,
        ["id"] = true,
        ["ie"] = true,
        ["il"] = true,
        ["in"] = true,
        ["io"] = true,
        ["iq"] = true,
        ["ir"] = true,
        ["is"] = true,
        ["it"] = true,
        ["jm"] = true,
        ["jo"] = true,
        ["jp"] = true,
        ["ke"] = true,
        ["kg"] = true,
        ["kh"] = true,
        ["ki"] = true,
        ["km"] = true,
        ["kn"] = true,
        ["kp"] = true,
        ["kr"] = true,
        ["kw"] = true,
        ["ky"] = true,
        ["kz"] = true,
        ["la"] = true,
        ["lb"] = true,
        ["lc"] = true,
        ["li"] = true,
        ["lk"] = true,
        ["lr"] = true,
        ["ls"] = true,
        ["lt"] = true,
        ["lu"] = true,
        ["lv"] = true,
        ["ly"] = true,
        ["ma"] = true,
        ["mc"] = true,
        ["md"] = true,
        ["me"] = true,
        ["mg"] = true,
        ["mh"] = true,
        ["mk"] = true,
        ["ml"] = true,
        ["mm"] = true,
        ["mn"] = true,
        ["mo"] = true,
        ["mp"] = true,
        ["mq"] = true,
        ["mr"] = true,
        ["ms"] = true,
        ["mt"] = true,
        ["mu"] = true,
        ["mv"] = true,
        ["mw"] = true,
        ["mx"] = true,
        ["my"] = true,
        ["mz"] = true,
        ["na"] = true,
        ["nc"] = true,
        ["ne"] = true,
        ["nf"] = true,
        ["ng"] = true,
        ["ni"] = true,
        ["nl"] = true,
        ["no"] = true,
        ["np"] = true,
        ["nr"] = true,
        ["nu"] = true,
        ["nz"] = true,
        ["om"] = true,
        ["pa"] = true,
        ["pe"] = true,
        ["pf"] = true,
        ["pg"] = true,
        ["ph"] = true,
        ["pk"] = true,
        ["pl"] = true,
        ["pm"] = true,
        ["pn"] = true,
        ["pr"] = true,
        ["ps"] = true,
        ["pt"] = true,
        ["pw"] = true,
        ["py"] = true,
        ["qa"] = true,
        ["re"] = true,
        ["ro"] = true,
        ["rs"] = true,
        ["ru"] = true,
        ["rw"] = true,
        ["sa"] = true,
        ["sb"] = true,
        ["sc"] = true,
        ["scotland"] = true,
        ["sd"] = true,
        ["se"] = true,
        ["sg"] = true,
        ["sh"] = true,
        ["si"] = true,
        ["sj"] = true,
        ["sk"] = true,
        ["sl"] = true,
        ["sm"] = true,
        ["sn"] = true,
        ["so"] = true,
        ["sr"] = true,
        ["st"] = true,
        ["sv"] = true,
        ["sy"] = true,
        ["sz"] = true,
        ["tc"] = true,
        ["td"] = true,
        ["tf"] = true,
        ["tg"] = true,
        ["th"] = true,
        ["tj"] = true,
        ["tk"] = true,
        ["tl"] = true,
        ["tm"] = true,
        ["tn"] = true,
        ["to"] = true,
        ["tr"] = true,
        ["tt"] = true,
        ["tv"] = true,
        ["tw"] = true,
        ["tz"] = true,
        ["ua"] = true,
        ["ug"] = true,
        ["um"] = true,
        ["us"] = true,
        ["uy"] = true,
        ["uz"] = true,
        ["va"] = true,
        ["vc"] = true,
        ["ve"] = true,
        ["vg"] = true,
        ["vi"] = true,
        ["vn"] = true,
        ["vu"] = true,
        ["wales"] = true,
        ["wf"] = true,
        ["ws"] = true,
        ["ye"] = true,
        ["yt"] = true,
        ["za"] = true,
        ["zm"] = true,
        ["zw"] = true
    }

    for _, ply in player.Iterator() do
        local PlayerCountry = ply:GetInfo("rv_country")
        if not WhitelistedCountries[PlayerCountry] then --
            PlayerCountry = ""
        end

        ply:SetNWString("Country", PlayerCountry)
    end

    hook.Add("PlayerSpawn", "SetCountryOnSpawn", function(ply, trans)
        local PlayerCountry = ply:GetInfo("rv_country")
        if not WhitelistedCountries[PlayerCountry] then --
            PlayerCountry = ""
        end

        ply:SetNWString("Country", PlayerCountry)
    end)
end

if CLIENT then
    surface.CreateFont("ScoreboardDefaultScaled", {
        font = "Helvetica",
        size = ScrH() * 0.0203741, -- 22 pixels 1920x1080
        weight = 800
    })

    surface.CreateFont("HudDefaultScaled", {
        font = "Verdana",
        size = ScrH() * 0.0182, -- 11 pixels 1920x1080
        weight = 700,
        antialias = true,
    })

    surface.CreateFont("BudgetLabelScaled", {
        font = "Courier New",
        size = ScrH() * 0.015, -- 14 pixels 1920x1080
        weight = 700,
        antialias = true,
    })

    CreateClientConVar("rv_country", "", true, true, "Your country to display in scoreboard.")
    local RNDX = include("rndx.lua")
    surface.CreateFont("VerdanaScaled", {
        font = "Verdana Bold",
        extended = false,
        size = ScrH() * 0.0167, -- 18 pixels 1920x1080
        weight = 1000,
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

    local color_blue = Color(134, 177, 220, 255)
    local color_lightblue = Color(184, 227, 270, 255)
    local color_darkblue = Color(84, 127, 170, 255)
    --local color_darkbluetransparent = Color(4, 20, 60, 120)
    local color_blacktransparent = Color(0, 0, 0, 120)
    local color_yellow = Color(255, 177, 0, 255)
    local Frame = nil
    CreateClientConVar("rv_scoreboard", "1", true, false, "Whether or not to display custom scoreboard", 0, 1)
    hook.Add("ScoreboardShow", "rv_scoreboard", function()
        --local CurrentGamemode = Entity(0):GetNWString("CurrentGamemode")
        if GetConVar("rv_scoreboard"):GetBool() == false or not draw.DrawRing then return end
        gui.EnableScreenClicker(true)
        local players = select(2, player.Iterator())
        table.sort(players, function(a, b) return a:Frags() > b:Frags() end)
        local PlayerCount = #players
        local TopPanelHeight = ScrH() * 0.03
        local BottomPanelHeight = ScrH() * 0.01
        local PlayerCardHeight = ScrH() * 0.24 * 0.1
        local HeaderStart = ScrH() * 0.024
        local PlayerCardMargin = ScrH() * 0.0056
        local MiddlePanelHeight = PlayerCardHeight + (PlayerCount * HeaderStart + PlayerCardMargin * PlayerCount)
        local FrameHeight = TopPanelHeight + BottomPanelHeight + MiddlePanelHeight -- TopPanelHeight = BottomPanelHeight
        Frame = vgui.Create("DPanel")
        Frame:SetSize(ScrW() * 0.6, FrameHeight)
        Frame:SetPos((ScrW() - Frame:GetWide()) * 0.5, (ScrH() - Frame:GetTall()) * 0.5)
        Frame:DockPadding(ScrW() * 0.005, 0, ScrW() * 0.005, 0)
        function Frame.Paint(self, w, h)
            if RNDX then
                RNDX.DrawOutlined(15, 0, 0, w, h, color_white, 1)
                RNDX.Draw(15, 0 + 1, 0 + 1, w - 2, h - 2, color_blacktransparent) --, "vgui/gradient-u")
            else
                surface.SetDrawColor(color_white)
                surface.DrawOutlinedRect(0, 0, w, h, 2)
                surface.SetDrawColor(color_blacktransparent)
                surface.DrawRect(0, 0, w, h)
            end
        end

        local TopPanel = vgui.Create("DPanel", Frame)
        TopPanel:Dock(TOP)
        TopPanel:SetSize(0, TopPanelHeight)
        surface.SetFont("HudDefaultScaled")
        local HeaderThickness = ScrH() * 0.0012 -- thickness of all headers
        surface.SetFont("HudDefaultScaled")
        local _, TextH = surface.GetTextSize(GetHostName())
        function TopPanel.Paint(self, w, h)
            --surface.SetDrawColor(Color(0, 255, 255, 255))
            --surface.DrawRect(0, 0, w, h)
            draw.DrawText(GetHostName(), "HudDefaultScaled", 0, (h - TextH) * 0.5, color_yellow, TEXT_ALIGN_LEFT)
            surface.SetFont("BudgetLabelScaled")
            surface.SetDrawColor(color_black)
            surface.DrawRect(0, TextH * 1.7, w, HeaderThickness)
            if not Entity(0) then -- Is this even possible?
                return
            end

            local ServerTPS = math.Truncate(Entity(0):GetNWFloat("ServerTPS"), 3)
            TextW, TextH = surface.GetTextSize("sv: " .. ServerTPS)
            draw.DrawText("sv: " .. ServerTPS, "BudgetLabelScaled", w - TextW * 1.1, (h - TextH) * 0.5, color_yellow, TEXT_ALIGN_LEFT)
        end

        local MiddlePanel = vgui.Create("DPanel", Frame)
        MiddlePanel:Dock(TOP)
        MiddlePanel:SetSize(0, ScrH() * 0.24)
        MiddlePanel:SetMouseInputEnabled(true)
        if MiddlePanel:GetTall() < MiddlePanelHeight then
            --
            MiddlePanel:SetTall(MiddlePanelHeight)
        end

        --MiddlePanel:DockPadding(0, HeaderStart + HeaderThickness, 0, 0)
        function MiddlePanel.Paint(self, w, h)
            --[[
        surface.SetDrawColor(Color(255, 0, 0, 255))
        surface.DrawRect(0, 0, w, h)
        surface.SetFont("VerdanaScaled")

        --]]
            --draw.DrawText("Players - " .. player.GetCount(), "VerdanaScaled", 0, (HeaderStart - TextH) / 2, color_blue, TEXT_ALIGN_LEFT)
            --draw.DrawText("Kills", "VerdanaScaled", 100, (HeaderStart - TextH) / 2, color_blue, TEXT_ALIGN_LEFT)
            surface.SetDrawColor(color_blue)
            surface.DrawRect(0, 0 + HeaderStart, w, HeaderThickness)
        end

        local HeaderPanel = vgui.Create("DPanel", TopPanel)
        HeaderPanel:Dock(LEFT)
        HeaderPanel:SetSize(TopPanel:GetWide(), TopPanel:GetTall() * 0.5)
        function HeaderPanel.Paint(self, w, h)
            --surface.SetDrawColor(Color(0, 128, 0, 255))
            --surface.DrawRect(0, 0, w, h)
            --draw.DrawText(GetHostName(), "HudDefaultScaled", 0, (h - TextH) * 0.5, Color(255, 177, 0, 255), TEXT_ALIGN_LEFT)
        end

        local HeadersHolder = vgui.Create("DPanel", MiddlePanel)
        HeadersHolder:Dock(TOP)
        HeadersHolder:SetTall(HeaderStart + HeaderThickness)
        function HeadersHolder.Paint(self, w, h)
        end

        local PlayersHeader = vgui.Create("DPanel", HeadersHolder)
        PlayersHeader:Dock(LEFT)
        --PlayersHeader:SetSize(TopPanel:GetWide(), TopPanel:GetTall() * 0.5)
        --PlayersHeader:SetSize(MiddlePanel:GetWide(), HeaderStart)
        local PlayersHeaderWidth = Frame:GetWide() * 0.3
        PlayersHeader:SetWide(PlayersHeaderWidth)
        PlayersHeader:SetTall(HeaderStart)
        --PlayersHeader:SetBackgroundColor(Color(0, 255, 0, 255))
        function PlayersHeader.Paint(self, w, h)
            --surface.SetDrawColor(Color(0, 0, 0, 255))
            --surface.DrawRect(0, 0, w, h)
            surface.SetFont("VerdanaScaled")
            _, TextH = surface.GetTextSize("Players - " .. #team.GetPlayers(TEAM_UNASSIGNED))
            draw.DrawText("Players - " .. #team.GetPlayers(TEAM_UNASSIGNED), "VerdanaScaled", 0, (h - TextH) / 2, color_blue, TEXT_ALIGN_LEFT)
        end

        local GlickoHeader = vgui.Create("DPanel", HeadersHolder)
        GlickoHeader:Dock(LEFT)
        GlickoHeader:SetWide(PlayersHeaderWidth)
        function GlickoHeader.Paint(self, w, h)
            --surface.SetDrawColor(Color(0, 0, 128, 255))
            --surface.DrawRect(0, 0, w, h)
            surface.SetFont("VerdanaScaled")
            _, TextH = surface.GetTextSize("Duel SR")
            draw.DrawText("Duel SR", "VerdanaScaled", w / 2, (h - TextH) / 2, color_blue, TEXT_ALIGN_CENTER)
        end

        local SecondaryHeaderSize = Frame:GetWide() * 0.11
        local KillsHeader = vgui.Create("DPanel", HeadersHolder)
        KillsHeader:Dock(LEFT)
        KillsHeader:SetWide(SecondaryHeaderSize)
        function KillsHeader.Paint(self, w, h)
            --surface.SetDrawColor(Color(0, 0, 128, 255))
            --surface.DrawRect(0, 0, w, h)
            surface.SetFont("VerdanaScaled")
            _, TextH = surface.GetTextSize("Kills")
            draw.DrawText("Kills", "VerdanaScaled", w / 2, (h - TextH) / 2, color_blue, TEXT_ALIGN_CENTER)
        end

        local DeathsHeader = vgui.Create("DPanel", HeadersHolder)
        DeathsHeader:Dock(LEFT)
        DeathsHeader:SetWide(SecondaryHeaderSize)
        function DeathsHeader.Paint(self, w, h)
            --surface.SetDrawColor(Color(255, 0, 255, 255))
            --surface.DrawRect(0, 0, w, h)
            surface.SetFont("VerdanaScaled")
            _, TextH = surface.GetTextSize("Deaths")
            draw.DrawText("Deaths", "VerdanaScaled", w / 2, (h - TextH) / 2, color_blue, TEXT_ALIGN_CENTER)
        end

        local PingHeader = vgui.Create("DPanel", HeadersHolder)
        PingHeader:Dock(LEFT)
        PingHeader:SetWide(SecondaryHeaderSize)
        function PingHeader.Paint(self, w, h)
            --surface.SetDrawColor(Color(0, 255, 255, 255))
            --surface.DrawRect(0, 0, w, h)
            surface.SetFont("VerdanaScaled")
            _, TextH = surface.GetTextSize("Ping")
            draw.DrawText("Ping", "VerdanaScaled", w / 2, (h - TextH) / 2, color_blue, TEXT_ALIGN_CENTER)
        end

        local teams = team.GetAllTeams()
        for teamnumber, _ in SortedPairs(teams) do
            if teamnumber ~= TEAM_UNASSIGNED and #team.GetPlayers(teamnumber) > 0 and teamnumber ~= TEAM_CONNECTING then --and teamnumber ~= TEAM_SPECTATOR then
                local TeamHeader = vgui.Create("DPanel", MiddlePanel)
                TeamHeader:SetTall(HeaderStart)
                TeamHeader:Dock(TOP)
                MiddlePanel:SetTall(MiddlePanel:GetTall() + TeamHeader:GetTall())
                Frame:SetTall(Frame:GetTall() + TeamHeader:GetTall())
                function TeamHeader.Paint(self, w, h)
                    surface.SetFont("VerdanaScaled")
                    _, TextH = surface.GetTextSize(team.GetName(teamnumber) .. " - " .. #team.GetPlayers(teamnumber))
                    draw.DrawText(team.GetName(teamnumber) .. " - " .. #team.GetPlayers(teamnumber), "VerdanaScaled", 0, (h - TextH) / 2, (teamnumber ~= TEAM_SPECTATOR and color_yellow) or color_blue, TEXT_ALIGN_LEFT)
                    surface.SetDrawColor((teamnumber ~= TEAM_SPECTATOR and color_yellow) or color_blue)
                    surface.DrawRect(0, h - HeaderThickness, w, HeaderThickness)
                end
            end

            for _, ply in ipairs(team.GetPlayers(teamnumber)) do
                if not IsValid(ply) then continue end
                --if Frame:GetTall() < BottomPanel:GetTall() + MiddlePanel:GetTall() + TopPanel:GetTall() then Frame:SetTall(Frame:GetTall() + PlayerCardHeight) end
                local PlayerCard = vgui.Create("DPanel", MiddlePanel)
                PlayerCard:Dock(TOP)
                PlayerCard:DockMargin(0, PlayerCardMargin, 0, 0)
                PlayerCard:SetWide(MiddlePanel:GetWide())
                PlayerCard:SetTall(PlayerCardHeight)
                --PlayerCard:SetZPos(10000)
                PlayerCard:SetMouseInputEnabled(true)
                --PlayerCard:SetBackgroundColor(color_black)
                function PlayerCard.Paint(self, w, h)
                    --surface.SetDrawColor(color_white)
                    --surface.DrawRect(0, 0, w, h)
                end

                --function PlayerCard.Paint(self, w, h)
                --draw.DrawText(" " .. ply:Nick(), "ScoreboardDefaultScaled", 0, (i - 1) * 20, color_blue, TEXT_ALIGN_LEFT)
                --end
                local SpacerPanel = vgui.Create("DPanel", PlayerCard)
                SpacerPanel:Dock(LEFT)
                SpacerPanel:SetWide(PlayerCard:GetWide() * 0.1)
                function SpacerPanel.Paint(self, w, h)
                end

                local PlayerAvatar = vgui.Create("AvatarImage", PlayerCard)
                PlayerAvatar:Dock(LEFT)
                PlayerAvatar:SetSize(PlayerCard:GetTall(), PlayerCard:GetTall())
                PlayerAvatar:SetPlayer(ply, 184)
                function PlayerAvatar.Think(self, w, h)
                    if self:IsHovered() then
                        self:SetCursor("hand")
                    else
                        self:SetCursor("arrow")
                    end
                end

                function PlayerAvatar.OnMousePressed(self, keyCode)
                    if not IsValid(ply) then return end
                    if keyCode == MOUSE_RIGHT then
                        local menu = DermaMenu(false, PlayerCard)
                        local OpenProfileButton = menu:AddOption("Open profile", function() gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64()) end)
                        OpenProfileButton:SetIcon("icon16/book_open.png")
                        local SteamIDButton = menu:AddOption("Copy SteamID", function() SetClipboardText(ply:SteamID()) end)
                        SteamIDButton:SetIcon("icon16/page_copy.png")
                        local SpectateButton = menu:AddOption("Spectate", function()
                            FSpectate.spectateEntity(ply)
                        end)

                        SpectateButton:SetIcon("icon16/eye.png")
                        if LocalPlayer():IsAdmin() and ply ~= LocalPlayer() then
                            local KickButton = menu:AddOption("Kick", function() RunConsoleCommand("ulx", "kick", ply:Nick()) end)
                            KickButton:SetIcon("icon16/cancel.png")
                        end

                        menu:Open()
                    end
                end

                local NameHolder = vgui.Create("DPanel", PlayerCard)
                --NameHolder:SetPos(0, 0)
                local NameHolderWidth = PlayersHeaderWidth - SpacerPanel:GetWide() - MiddlePanel:GetWide()
                NameHolder:Dock(LEFT)
                NameHolder:SetSize(NameHolderWidth - PlayerAvatar:GetWide(), PlayerCard:GetTall())
                --NameHolder:SetBackgroundColor(color_white)
                surface.SetFont("ScoreboardDefaultScaled")
                local ReadyUpStatus = (CurrentGamemode == "CA" and ((ply:GetNWBool("Ready") == true and " (R)") or " (NR)")) or ""
                local PlayerName = " " .. (IsValid(ply) and ((FindColorInText(ply:Nick(), true) and table.concat(FindColorInText(ply:Nick(), true)) or ply:Nick()) .. ReadyUpStatus) or "Connecting")
                local NickW, NickH = surface.GetTextSize(PlayerName)
                function NameHolder.Paint(self, w, h)
                    --if not IsValid(ply) then return end
                    --surface.SetDrawColor(Color(255, 255, 0, 255))
                    --surface.DrawRect(0, 0, w, h)
                    draw.DrawText(PlayerName, "ScoreboardDefaultScaled", 0, (h - NickH) / 2, (ply == LocalPlayer() and color_lightblue) or color_blue, TEXT_ALIGN_LEFT)
                end

                function NameHolder.Think(self, w, h)
                    if self:IsHovered() then
                        self:SetCursor("hand")
                    else
                        self:SetCursor("arrow")
                    end
                end

                function NameHolder.OnMousePressed(self, keyCode)
                    if not IsValid(ply) then return end
                    if keyCode == MOUSE_RIGHT then
                        local menu = DermaMenu(false, PlayerCard)
                        local OpenProfileButton = menu:AddOption("Open profile", function() gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64()) end)
                        OpenProfileButton:SetIcon("icon16/book_open.png")
                        local SteamIDButton = menu:AddOption("Copy SteamID", function() SetClipboardText(ply:SteamID()) end)
                        SteamIDButton:SetIcon("icon16/page_copy.png")
                        local SpectateButton = menu:AddOption("Spectate", function()
                            net.Start("FSpectateTarget")
                            net.WriteEntity(ply)
                            net.SendToServer()
                        end)

                        SpectateButton:SetIcon("icon16/eye.png")
                        if LocalPlayer():IsAdmin() and ply ~= LocalPlayer() then
                            local KickButton = menu:AddOption("Kick", function() RunConsoleCommand("ulx", "kick", ply:Nick()) end)
                            KickButton:SetIcon("icon16/cancel.png")
                        end

                        menu:Open()
                    end
                end

                local GlickoHolder = vgui.Create("DPanel", PlayerCard)
                GlickoHolder:Dock(LEFT)
                GlickoHolder:SetSize(NameHolderWidth, 200)
                function GlickoHolder.Paint(self, w, h)
                    --surface.SetDrawColor(Color(128, 0, 255, 255))
                    --surface.DrawRect(0, 0, w, h)
                    if not IsValid(ply) then return end
                    surface.SetFont("VerdanaScaled")
                    local DuelRating = ply:GetNWString("DuelRating", "-")
                    _, TextH = surface.GetTextSize(DuelRating)
                    draw.DrawText(DuelRating, "VerdanaScaled", w / 2, (h - TextH) / 2, color_blue, TEXT_ALIGN_CENTER)
                end

                local PlayerCountry = ply:GetNWString("Country", "")
                local CountryFlag = nil
                surface.SetFont("ScoreboardDefaultScaled")
                local _, NickAverageBottom = surface.GetTextSize("a") -- the size of "a" is basically the ideal height of the nick to center on excluding "y" and "t"
                if PlayerCountry ~= "" then
                    CountryFlag = vgui.Create("DImage", PlayerCard)
                    CountryFlag:SetImage("materials/flags16/" .. PlayerCountry .. ".png")
                    CountryFlag:SetSize(NameHolder:GetTall() * 0.75, NameHolder:GetTall() * 0.55)
                    --local NickAverageBottom = ScrH() * 0.0203741 -- around 22 pixels
                    CountryFlag:SetPos(math.min(NickW + PlayerAvatar:GetWide() + NameHolder:GetWide() * 0.03, NameHolder:GetWide() * 1.25), NickAverageBottom - CountryFlag:GetTall() - 2) -- 2 pixels because the surface.gettextsize is inaccurate somehow by 2
                end

                local MuteButton = vgui.Create("DButton", PlayerCard)
                MuteButton:SetSize(NameHolder:GetWide() * 0.1, NameHolder:GetWide() * 0.08) -- make this relative to scrh and scrw later
                MuteButton:SetPos(math.min(NickW + PlayerAvatar:GetWide() + NameHolder:GetWide() * 0.04 + (((CountryFlag and IsValid(CountryFlag)) and CountryFlag:GetWide() * 1.1) or 0), NameHolder:GetWide() * 1.5), ((NameHolder:GetTall() - MuteButton:GetTall()) / 2) + 2) -- this needs to be relative too
                MuteButton:SetText("")
                MuteButton.DoClick = function()
                    if not IsValid(ply) then return end
                    if not ply:IsMuted() then
                        ply:SetMuted(true)
                    else
                        ply:SetMuted(false)
                    end
                end

                MuteButton.OnMouseWheeled = function(self, scrollDelta)
                    if not IsValid(ply) then return end
                    ply:SetVoiceVolumeScale(ply:GetVoiceVolumeScale() + scrollDelta * 0.05)
                    return true
                end

                --local MuteButtonX, MuteButtonY = MuteButton:GetPos()
                local MuteCircle1 = draw.DrawCircle(0, MuteButton:GetTall() * 0.5, ScrH() * 0.010, nil, true)
                local MuteArc1 = draw.DrawArc(0, MuteButton:GetTall() * 0.5, ScrH() * 0.012, 65, 115, true)
                local MuteCircle2 = draw.DrawCircle(0, MuteButton:GetTall() * 0.5, ScrH() * 0.015, nil, true)
                local MuteArc2 = draw.DrawArc(0, MuteButton:GetTall() * 0.5, ScrH() * 0.017, 55, 125, true)
                MuteButton.Paint = function(self, w, h)
                    if not IsValid(ply) then return end
                    if self:IsHovered() then --
                        self:SetCursor("hand")
                    end

                    surface.SetDrawColor((ply:GetVoiceVolumeScale() ~= 0 and not ply:IsMuted()) and color_lightblue or color_darkblue)
                    local RectHeight = h * 0.6875 - h * 0.4125
                    local RectWidth = w * 0.1575 -- magic number from the Y of the bottom left of the trapezoid
                    surface.DrawRect(0, (h - RectHeight) / 2, RectWidth, RectHeight)
                    local Trapezoid = {
                        {
                            x = w * 0.4375 * 1.1 * 0.5 - RectWidth,
                            y = h * 0.25 * 1.1 * 1.5
                        },
                        {
                            x = w * 0.75 * 0.5 - RectWidth,
                            y = h * 0.125 * 1.5
                        },
                        {
                            x = w * 0.75 * 0.5 - RectWidth,
                            y = h * (1 - 0.125 * 1.5)
                        },
                        {
                            x = w * 0.4375 * 1.1 * 0.5 - RectWidth,
                            y = h * (1 - 0.25 * 1.1 * 1.5)
                        },
                    }

                    draw.NoTexture()
                    surface.DrawPoly(Trapezoid)
                    -- mutebutton bands
                    if ply:GetVoiceVolumeScale() > 0.5 and not ply:IsMuted() then
                        draw.DrawRing(MuteCircle2, MuteArc2)
                        --draw.DrawRing(0, h / 2, 25, 2, 55, 125, nil, nil)
                    end

                    if ply:GetVoiceVolumeScale() > 0 and not ply:IsMuted() then
                        draw.DrawRing(MuteCircle1, MuteArc1)
                        --draw.DrawRing(0, h / 2, 17, 2, 65, 115, nil, nil)
                    end
                end

                local KillsHolder = vgui.Create("DPanel", PlayerCard)
                KillsHolder:Dock(LEFT)
                KillsHolder:SetSize(SecondaryHeaderSize)
                function KillsHolder.Paint(self, w, h)
                    --surface.SetDrawColor(Color(128, 0, 255, 255))
                    --surface.DrawRect(0, 0, w, h)
                    if not IsValid(ply) then return end
                    local IsDuelling = ply:GetNWBool("Duelling", false)
                    local DuelScore = nil
                    if IsDuelling then --
                        DuelScore = ply:GetNWInt("DuelScore", 0)
                    end

                    surface.SetFont("VerdanaScaled")
                    _, TextH = surface.GetTextSize(ply:Frags())
                    draw.DrawText((not IsDuelling and ply:Frags()) or DuelScore .. "(" .. ply:Frags() .. ")", "VerdanaScaled", w / 2, (h - TextH) / 2, color_blue, TEXT_ALIGN_CENTER)
                end

                local DeathsHolder = vgui.Create("DPanel", PlayerCard)
                DeathsHolder:Dock(LEFT)
                DeathsHolder:SetSize(SecondaryHeaderSize)
                function DeathsHolder.Paint(self, w, h)
                    --surface.SetDrawColor(Color(128, 128, 255, 255))
                    --surface.DrawRect(0, 0, w, h)
                    if not IsValid(ply) then return end
                    surface.SetFont("VerdanaScaled")
                    _, TextH = surface.GetTextSize(ply:Deaths())
                    draw.DrawText(ply:Deaths(), "VerdanaScaled", w / 2, (h - TextH) / 2, color_blue, TEXT_ALIGN_CENTER)
                end

                local PingHolder = vgui.Create("DPanel", PlayerCard)
                PingHolder:Dock(LEFT)
                PingHolder:SetSize(SecondaryHeaderSize)
                function PingHolder.Paint(self, w, h)
                    --surface.SetDrawColor(Color(128, 128, 128, 255))
                    --surface.DrawRect(0, 0, w, h)
                    if not IsValid(ply) then return end
                    surface.SetFont("VerdanaScaled")
                    _, TextH = surface.GetTextSize(ply:Ping())
                    draw.DrawText(ply:Ping(), "VerdanaScaled", w / 2, (h - TextH) / 2, color_blue, TEXT_ALIGN_CENTER)
                end
            end
        end

        local BottomPanel = vgui.Create("DPanel", Frame)
        BottomPanel:Dock(TOP)
        BottomPanel:SetSize(0, BottomPanelHeight)
        function BottomPanel.Paint(self, w, h)
        end
        return true
    end)

    hook.Add("ScoreboardHide", "rv_scoreboard", function()
        --
        gui.EnableScreenClicker(false)
        if IsValid(Frame) then Frame:Remove() end
    end)
end
