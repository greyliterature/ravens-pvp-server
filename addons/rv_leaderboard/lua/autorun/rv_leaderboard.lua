--[[--------------------------------------
    sql s2c
----------------------------------------]]
local Queries = {
    ["MATCH_DATA"] = {
        query = "SELECT * FROM match_data WHERE winner_SteamID64 = ? OR loser_SteamID64 = ? LIMIT 10",
        expectedargs = {"string", "string"},
        expectedresponse = {
            ["category"] = "String", --
            ["forfeited"] = "Bool",
            ["loserscore"] = {
                "UInt", --
                5
            },
            ["loserglicko"] = {
                "Int", --
                14,
            },
            ["loser_SteamID64"] = "UInt64",
            ["map"] = "String",
            ["mapwsid"] = {
                "UInt", -- not sure how large wsids are
                14
            },
            ["match_id"] = {
                "UInt", --
                10
            },
            ["matchdate"] = "UInt64", -- https://en.wikipedia.org/wiki/Year_2038_problem
            ["winner_SteamID64"] = "UInt64",
            ["winnerscore"] = {
                "UInt", --
                5
            },
            ["rated"] = "Bool",
            ["winnerglicko"] = {
                "Int", --
                14
            },
        }
    },
    ["MATCHES_PLAYED"] = {
        query = "WITH me AS (SELECT ? AS id) SELECT COUNT(*) AS matchesplayed, COALESCE(SUM(winner_SteamID64 = me.id), 0) AS matcheswon, COALESCE(SUM(loser_SteamID64 = me.id), 0) AS matcheslost, COALESCE(SUM(winnerscore = loserscore), 0) AS matchestied FROM match_data, me WHERE winner_SteamID64 = me.id OR loser_SteamID64 = me.id",
        expectedargs = {"String"},
        expectedresponse = {
            ["matcheslost"] = {
                "UInt", --
                10
            },
            ["matchesplayed"] = {
                "UInt", --
                10
            },
            ["matcheswon"] = {
                "UInt", --
                10
            },
            ["matchestied"] = {
                "UInt", --
                10
            }
        },
    },
    ["MAPS_PLAYED"] = {
        query = "WITH me as (SELECT ? as steamid) SELECT map, mapwsid, COALESCE(SUM(winner_SteamID64 = me.steamid), 0) AS won, COALESCE(SUM(loser_SteamID64 = me.steamid), 0) AS lost FROM match_data, me WHERE winner_SteamID64 = me.steamid OR loser_SteamID64 = me.steamid GROUP BY map, mapwsid LIMIT 75",
        expectedargs = {"String"},
        expectedresponse = {
            ["map"] = "String",
            ["mapwsid"] = "String",
            ["won"] = {
                "UInt", --
                10
            },
            ["lost"] = {
                "UInt", --
                10
            }
        }
    },
    ["PLAYER_INFO"] = {
        query = "SELECT damage, kills, deaths, timesjoined FROM player_info WHERE steamid32 = ?",
        expectedargs = {"String"},
        expectedresponse = {
            ["damage"] = {
                "UInt", --
                10,
            },
            ["kills"] = {
                "UInt", --
                10
            },
            ["deaths"] = {
                "UInt", --
                10
            },
            ["timesjoined"] = {
                "UInt", --
                10,
            }
        }
    },
    ["WEAPON_KILLS"] = {
        query = "SELECT weapon_kills.weaponclass, weapon_kills.kills AS kills, COALESCE(weapon_deaths.deaths, 0) AS deaths FROM weapon_kills LEFT JOIN weapon_deaths ON weapon_kills.steamid32 = weapon_deaths.steamid32 AND weapon_kills.weaponclass = weapon_deaths.weaponclass WHERE weapon_kills.steamid32 = ? LIMIT 100",
        expectedargs = {"String"},
        expectedresponse = {
            ["deaths"] = {
                "UInt", --
                14
            },
            ["kills"] = {
                "UInt", --
                14
            },
            ["weaponclass"] = "String",
        }
    },
}

if SERVER then
    util.AddNetworkString("sql.AskServer")
    util.AddNetworkString("sql.Reply")
    local RateLimit = 5
    local RateLimits = {}
    net.Receive("sql.AskServer", function(len, ply)
        RateLimits[ply] = RateLimits[ply] or {}
        local querycode = net.ReadString()
        RateLimits[ply][querycode] = RateLimits[ply][querycode] or 0
        if RateLimits[ply][querycode] + RateLimit > CurTime() then
            print("Rate limiting sql.askserver for " .. ply:Nick() .. ", " .. ply:SteamID())
            return
        end

        RateLimits[ply][querycode] = CurTime()
        local query = Queries[querycode].query
        if not query then return end
        local args = {}
        local expectedargs = Queries[querycode].expectedargs
        for i = 1, #expectedargs do
            local expectedarg = expectedargs[i]
            expectedarg = string.upper(string.sub(expectedarg, 1, 1)) .. string.sub(expectedarg, 2) -- string -> String for: net.WriteString
            args[#args + 1] = net["Read" .. expectedarg]()
        end

        -- response
        local result = sql.QueryTyped(query, unpack(args))
        net.Start("sql.Reply")
        local NumSQLResultKeys = #result
        net.WriteUInt(NumSQLResultKeys, 8)
        net.WriteString(querycode) -- client has to know what hes getting back 
        for i = 1, NumSQLResultKeys do
            local resulttbl = result[i]
            for responsename, responsetype in pairs(Queries[querycode].expectedresponse) do
                local UIntBitCount = nil
                if istable(responsetype) then -- its a UInt table
                    UIntBitCount = responsetype[2]
                    responsetype = responsetype[1]
                end

                --if querycode == "MAPS_PLAYED" then print(responsetype, responsename) end
                net["Write" .. responsetype](resulttbl[responsename], UIntBitCount)
            end
        end

        net.Send(ply)
    end)
elseif CLIENT then
    sql.AskServerCallbackQueue = sql.AskServerCallbackQueue or {}
    local CallbackQueue = sql.AskServerCallbackQueue
    function sql.AskServer(querycode, argstbl, callback)
        if not Queries[querycode] then
            print(querycode)
            return
        end

        CallbackQueue[querycode] = callback
        net.Start("sql.AskServer")
        net.WriteString(querycode)
        for i = 1, #argstbl do
            local expectedarg = Queries[querycode].expectedargs[i]
            expectedarg = string.upper(string.sub(expectedarg, 1, 1)) .. string.sub(expectedarg, 2) -- string -> String for: net.WriteString
            net["Write" .. expectedarg](argstbl[i])
        end

        net.SendToServer()
    end

    net.Receive("sql.Reply", function(_, _)
        local NumSQLResultKeys = net.ReadUInt(8)
        local querycode = net.ReadString() -- client has to know what hes getting back 
        local resulttbl = {}
        for i = 1, NumSQLResultKeys do
            resulttbl[#resulttbl + 1] = {}
            for responsename, responsetype in pairs(Queries[querycode].expectedresponse) do
                local UIntBitCount = nil
                if istable(responsetype) then -- its a UInt table
                    UIntBitCount = responsetype[2]
                    responsetype = responsetype[1]
                end

                resulttbl[#resulttbl][responsename] = net["Read" .. responsetype](UIntBitCount)
            end
        end

        CallbackQueue[querycode](querycode, resulttbl)
    end)
end

--[[--------------------------------------
    panel tests
----------------------------------------]]
if CLIENT then
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
    local function OpenLeaderboard(CurrentlyOpenedProfile)
        if IsValid(LeaderBoardPanel) then LeaderBoardPanel:Remove() end
        LeaderBoardPanel = vgui.Create("DPanel")
        local Panel = LeaderBoardPanel
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
        local PlayerNick = ""
        steamworks.RequestPlayerInfo(CurrentlyOpenedProfile, function(steamName)
            PlayerNick = steamName -- 
        end)

        local NickFont = "Stratum_Bold_Small"
        surface.SetFont(NickFont)
        local NickHolderGap = ScrW() * 0.01
        local MarginRightOfNickHolder = ScrW() * 0.005
        local AvatarMargin = ScrW() * 0.005
        local TextW, _ = surface.GetTextSize(PlayerNick)
        PlayerInfoHolder:SetSize(AvatarSize + NickHolderGap + AvatarMargin + MarginRightOfNickHolder + TextW, AvatarSize + AvatarMargin * 2)
        function PlayerInfoHolder.Paint(self, w, h)
            surface.SetDrawColor(color_transparentish_black)
            surface.DrawRect(0, 0, w, h)
        end

        local Avatar = vgui.Create("AvatarImage", PlayerInfoHolder)
        Avatar:SetSteamID(CurrentlyOpenedProfile)
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
        local Percents = {}
        local Labels = {}
        local Colors = {Color(128, 128, 0), Color(128, 0, 128), Color(0, 0, 128), Color(0, 128, 0), Color(128, 128, 128), Color(0, 255, 255),}
        local BottomMarginFromEdge = MarginFromEdge --Panel:GetTall() * 0.03
        WeaponStats:SetSize(ScrW() * 0.23, ScrH() * 0.33)
        WeaponStats:SetPos((Panel:GetWide() - WeaponStats:GetWide()) - BottomMarginFromEdge, Panel:GetTall() - WeaponStats:GetTall() - BottomMarginFromEdge)
        local PieChart = vgui.Create("SPieChart", WeaponStats)
        --PieChart:SetPos(Panel:GetWide() * 0.25, Panel:GetTall() * 0.5)
        PieChart:SetColors(Colors)
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
        --LabelHolder:Attach(PieChart)
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
        local Percents_2 = {}
        local RadarChart = vgui.Create("SRadarChart", MapPerformance)
        local RadarChartSize = ScrH() * 0.3
        RadarChart:SetSize(RadarChartSize, RadarChartSize)
        RadarChart:SetTargetNumber(1)
        local MarginDown = ScrH() * 0.013
        RadarChart:SetX((MapPerformance:GetWide() - RadarChart:GetWide()) * 0.5)
        RadarChart:SetY((MapPerformance:GetTall() - RadarChart:GetTall()) * 0.5 + MarginDown)
        --RadarChart:SetRadarColor()
        --RadarChart:SetSegmentCount(9)
        RadarChart:SetPercents(Percents_2)
        local IconWSIDs = {}
        local IconMaterials = {}
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
            if not IconMaterials[SegmentIndex] then return end
            surface.SetMaterial(IconMaterials[SegmentIndex])
            surface.SetDrawColor(color_white)
            surface.DrawTexturedRect(newX - RectWidth * 0.5, newY - RectWidth * 0.5, RectWidth, RectWidth)
            surface.SetDrawColor(color_black)
            surface.DrawOutlinedRect(newX - RectWidth * 0.5, newY - RectWidth * 0.5, RectWidth, RectWidth, 1)
        end

        local FailCode = "18446744073709551615"
        local MaxSegments = 8
        sql.AskServer("MAPS_PLAYED", {CurrentlyOpenedProfile}, function(querycode, resulttbl)
            for i = 1, math.min(#resulttbl, MaxSegments) do
                local map = resulttbl[i].map
                local wsid = resulttbl[i].mapwsid
                local wins = resulttbl[i].won
                local losses = resulttbl[i].lost
                Percents_2[i] = wins / math.max(1, wins + losses)
                IconWSIDs[i] = wsid
                if map == "gm_construct" then
                    IconMaterials[i] = Material("maps/thumb/gm_construct.png")
                    continue
                elseif map == "gm_flatgrass" then
                    IconMaterials[i] = Material("maps/thumb/gm_flatgrass.png")
                    continue
                end

                steamworks.FileInfo(wsid, function(result)
                    if result.previewid == FailCode then
                        IconMaterials[i] = Material("maps/thumb/noicon.png")
                        return
                    end

                    RadarChart:SetPercents(Percents_2)
                    steamworks.Download(result.previewid, true, function(name)
                        --
                        IconMaterials[i] = AddonMaterial(name)
                    end)
                end)
            end

            local LabelFuncs = {}
            for i = 1, #IconWSIDs do
                LabelFuncs[i] = function(w, h, segmentX, segmentY)
                    -- 
                    DrawMapRect(w, h, segmentX, segmentY, i)
                end
            end

            RadarChart:SetLabels(LabelFuncs)
            RadarChart:SetPercents(Percents_2)
        end)

        local MatchesPlayed = InfoHolder(Panel, Panel:GetWide() * 0.5, 128, "Matches Played", "Stratum_Bold_Smaller", color_csgogrey, Panel:GetWide() * 0.01, Panel:GetTall() * 0.01)
        MatchesPlayed:SetX(MapPerformance:GetX())
        MatchesPlayed:SetY(Header:GetY() + MarginFromEdge)
        MatchesPlayed:SetWide(ScrW() * 0.10)
        MatchesPlayed:SetTall(MapPerformance:GetY() - MatchesPlayed:GetY() - MarginFromEdge)
        local Played = "N/A"
        local Wins = "N/A"
        local Ties = "N/A"
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
            draw.DrawText(Played, "Stratum_Bold", Panel:GetWide() * 0.01, h * 0.1, color_csgogrey, TEXT_ALIGN_LEFT)
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

        sql.AskServer("MATCHES_PLAYED", {CurrentlyOpenedProfile}, function(querycode, resulttbl)
            Wins = resulttbl[1].matcheswon
            Ties = resulttbl[1].matchestied
            Losses = resulttbl[1].matcheslost
            Played = resulttbl[1].matchesplayed
        end)

        ----
        local SeperatorY = Panel:GetTall() * 0.01
        local ADM = InfoHolder(Panel, Panel:GetWide() * 0.5, 128, "ADG", "Stratum_Bold_Smaller", color_csgogrey, Panel:GetWide() * 0.01, Panel:GetTall() * 0.01)
        ADM:SetX(MatchesPlayed:GetX() + MatchesPlayed:GetWide())
        ADM:SetY(Header:GetY() + MarginFromEdge)
        ADM:SetWide(ScrW() * 0.10)
        ADM:SetTall(MapPerformance:GetY() - MatchesPlayed:GetY() - MarginFromEdge)
        local ADM_number = "N/A"
        local Damage = "N/A"
        local TimesJoined = "N/A"
        function ADM.PaintOver(self, w, h)
            surface.SetDrawColor(color_csgogrey)
            surface.DrawRect(0, SeperatorY, 1, h - SeperatorY * 2)
            draw.DrawText(ADM_number, "Stratum_Bold", Panel:GetWide() * 0.01, h * 0.1, color_csgogrey, TEXT_ALIGN_LEFT)
            -- bottom
            draw.SimpleText("Damage", "Stratum_Bold_Smaller", TextMargin, DotsY + DotsMargin * 1, color_csgodarkgrey, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(Damage, "Stratum_Bold_Smaller", w - DotsMargin, DotsY + DotsMargin * 1, color_csgogrey, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            --
            draw.SimpleText("Times joined", "Stratum_Bold_Smaller", TextMargin, DotsY + DotsMargin * 2, color_csgodarkgrey, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(TimesJoined, "Stratum_Bold_Smaller", w - DotsMargin, DotsY + DotsMargin * 2, color_csgogrey, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end

        local Kills_Death = InfoHolder(Panel, Panel:GetWide() * 0.5, 128, "Kills/Death", "Stratum_Bold_Smaller", color_csgogrey, Panel:GetWide() * 0.01, Panel:GetTall() * 0.01)
        Kills_Death:SetX(ADM:GetX() + ADM:GetWide())
        Kills_Death:SetY(Header:GetY() + MarginFromEdge)
        Kills_Death:SetWide(ScrW() * 0.10)
        Kills_Death:SetTall(MapPerformance:GetY() - MatchesPlayed:GetY() - MarginFromEdge)
        local Kills = "N/A"
        local Deaths = "N/A"
        local KD = "N/A"
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

        sql.AskServer("PLAYER_INFO", {util.SteamIDFrom64(CurrentlyOpenedProfile)}, function(querycode, resulttbl)
            --
            PrintTable(resulttbl)
            if #resulttbl == 0 then return end
            Damage = resulttbl[1]["damage"]
            TimesJoined = math.max(1, resulttbl[1]["timesjoined"])
            if isnumber(TimesJoined) and isnumber(Damage) then --
                ADM_number = math.Truncate(Damage / TimesJoined, 2)
            end

            Damage = math.Truncate(Damage / 1000, 1) .. "k"
            Kills = resulttbl[1]["kills"]
            Deaths = resulttbl[1]["deaths"]
            KD = math.Truncate(Kills / (Deaths == 0 and 1) or Deaths, 2)
        end)

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

        local WeaponToNiceName = {
            weapon_crowbar = "Crowbar",
            weapon_pistol = "9MM",
            weapon_357 = "357",
            weapon_smg1 = "SMG",
            weapon_ar2 = "AR2",
            weapon_shotgun = "Shotgun",
            weapon_crossbow = "Crossbow",
            weapon_frag = "Grenade"
        }

        local _WeaponStats = {}
        sql.AskServer("WEAPON_KILLS", {util.SteamIDFrom64(CurrentlyOpenedProfile)}, function(querycode, resulttbl)
            local killssum = 0
            for i = 1, #resulttbl do
                local kills = resulttbl[i]["kills"]
                local deaths = math.max(1, resulttbl[i]["deaths"])
                _WeaponStats[i] = {
                    resulttbl[i]["weaponclass"], --
                    kills / deaths,
                    kills,
                }

                killssum = killssum + kills
            end

            table.sort(_WeaponStats, function(a, b) return a[2] > b[2] end)
            -- piechart
            for i = 1, #_WeaponStats do
                local kills = _WeaponStats[i][2]
                local weaponclass = _WeaponStats[i][1]
                Percents[#Percents + 1] = kills / killssum
                Labels[#Labels + 1] = WeaponToNiceName[weaponclass]
            end

            PieChart:SetPercents(Percents)
            PieChart:SetLabels(Labels)
            LabelHolder:Attach(PieChart)
            PrintTable(Percents)
        end)

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
        local MatchesHistory = {}
        local MatchMapMaterials = {}
        local function HasLoadedAllMatchMaps()
            return #MatchMapMaterials == #MatchesHistory
        end

        sql.AskServer("MATCH_DATA", {CurrentlyOpenedProfile, CurrentlyOpenedProfile}, function(querycode, resulttbl)
            MatchesHistory = resulttbl
            for i = 1, #MatchesHistory do
                local map = MatchesHistory[i].map
                local wsid = MatchesHistory[i].mapwsid
                steamworks.FileInfo(wsid, function(result)
                    if map == "gm_construct" then
                        MatchMapMaterials[#MatchMapMaterials + 1] = Material("maps/thumb/gm_construct.png")
                        return
                    elseif map == "gm_flatgrass" then
                        MatchMapMaterials[#MatchMapMaterials + 1] = Material("maps/thumb/gm_flatgrass.png")
                        return
                    end

                    if result.previewid == FailCode then
                        MatchMapMaterials[#MatchMapMaterials + 1] = Material("maps/thumb/noicon.png")
                        return
                    end

                    steamworks.Download(result.previewid, true, function(name)
                        --
                        MatchMapMaterials[#MatchMapMaterials + 1] = AddonMaterial(name)
                    end)
                end)
            end

            --
            MatchHistory:DockPadding(MarginFromEdge, Panel:GetWide() * 0.01 + TextH, MarginFromEdge, 0)
            for i = 1, #MatchesHistory do
                local tbl = MatchesHistory[i]
                local MatchPanel = vgui.Create("DPanel", MatchHistory)
                --MatchPanel:Dock(TOP)
                local MatchPanelHeight = MatchHistory:GetTall() * 0.07
                MatchPanel:SetBackgroundColor(color_transparentish_black)
                MatchPanel:SetX(MarginFromEdge)
                --MatchPanel:SetY(MatchPanelHeight * (i - 1) + Panel:GetWide() * 0.01 + TextH ((i == #MatchesHistory and 0) or Panel:GetWide() * 0.01))
                MatchPanel:Dock(TOP)
                MatchPanel:DockMargin(0, Panel:GetWide() * 0.003, 0, 0)
                MatchPanel:SetWide(MatchHistory:GetWide() - MarginFromEdge * 2)
                MatchPanel:SetTall(MatchPanelHeight)
                local MapRectSize = Panel:GetTall() * 0.03057
                function MatchPanel.Paint(self, w, h)
                    if not HasLoadedAllMatchMaps() then return end
                    surface.SetDrawColor(color_transparentish_black)
                    surface.DrawRect(0, 0, w, h)
                    surface.SetDrawColor((tbl.winner_SteamID64 == CurrentlyOpenedProfile and color_green) or (tbl.winnerscore == tbl.loserscore and color_fadedyellow) or color_fadedred)
                    DrawDot(DotsMargin, h * 0.5)
                    surface.SetDrawColor(color_white)
                    surface.SetMaterial(MatchMapMaterials[i])
                    surface.DrawTexturedRect(DotsMargin * 2, (h - MapRectSize) * 0.5, MapRectSize, MapRectSize)
                    draw.SimpleText(tbl.map, "Stratum_Bold_Smaller", DotsMargin * 2 + w * 0.09, h * 0.5, color_csgodarkgrey, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(tbl.winnerscore .. " - " .. tbl.loserscore, "Stratum_Bold_Smaller", w * 0.5, h * 0.5, color_csgodarkgrey, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end

                local WinnerAvatar = vgui.Create("AvatarImage", MatchPanel)
                WinnerAvatar:SetSize(MapRectSize, MapRectSize)
                WinnerAvatar:SetSteamID(tbl.winner_SteamID64)
                WinnerAvatar:SetPos(MatchPanel:GetWide() * 0.8, (MatchPanel:GetTall() - MapRectSize) * 0.5)
                WinnerAvatar:SetSize(MapRectSize, MapRectSize)
                WinnerAvatar:DrawOutlinedRect(3)
                function WinnerAvatar.PaintOver(self, w, h)
                    surface.SetDrawColor(color_green)
                    self:DrawOutlinedRect()
                end

                local LoserAvatar = vgui.Create("AvatarImage", MatchPanel)
                LoserAvatar:SetSize(MapRectSize, MapRectSize)
                LoserAvatar:SetSteamID(tbl.loser_SteamID64)
                LoserAvatar:SetPos(WinnerAvatar:GetX() + MapRectSize + MatchPanel:GetWide() * 0.01, (MatchPanel:GetTall() - MapRectSize) * 0.5)
                LoserAvatar:SetSize(MapRectSize, MapRectSize)
                LoserAvatar:DrawOutlinedRect(3)
                function LoserAvatar.PaintOver(self, w, h)
                    surface.SetDrawColor(color_fadedred)
                    self:DrawOutlinedRect()
                end
            end
        end)
    end

    hook.Add("OnPlayerChat", "OpenStats", function(ply, text, _, _)
        if ply ~= LocalPlayer() then return end
        if text == "!stats" then --
            OpenLeaderboard(LocalPlayer():SteamID64())
        end
    end)
end

--[[--------------------------------------
    server tracking
----------------------------------------]]
if SERVER then
    sql.QueryTyped("CREATE TABLE IF NOT EXISTS player_info ( steamid32 TEXT UNIQUE, damage INTEGER DEFAULT 0, kills INTEGER DEFAULT 0, deaths INTEGER DEFAULT 0, timesjoined INTEGER DEFAULT 0 )")
    sql.QueryTyped("CREATE TABLE IF NOT EXISTS weapon_kills ( steamid32 TEXT, weaponclass TEXT, kills INTEGER DEFAULT 0, PRIMARY KEY (steamid32, weaponclass) )")
    sql.QueryTyped("CREATE TABLE IF NOT EXISTS weapon_deaths ( steamid32 TEXT, weaponclass TEXT, deaths INTEGER DEFAULT 0, PRIMARY KEY (steamid32, weaponclass) )")
    -- damage and weapon traccing
    local DamageBatches = {}
    local WeaponKillBatches = {}
    local WeaponDeathBatches = {}
    local KillBatches = {}
    local DeathBatches = {}
    hook.Add("PostEntityTakeDamage", "TrackPlayerDamage", function(ent, dmginfo, wasdamagetaken)
        if not ent:IsPlayer() then return end
        if wasdamagetaken == false then return end
        local attacker = dmginfo:GetAttacker()
        if not attacker:IsPlayer() then return end
        local attacker_steamid32 = attacker:SteamID()
        DamageBatches[attacker_steamid32] = (DamageBatches[attacker_steamid32] or 0) + dmginfo:GetDamage()
        if ent:Alive() == false or ent:Health() <= 0 then --
            local weapused = dmginfo:GetWeapon()
            local ent_steamid32 = ent:SteamID()
            if IsValid(weapused) then --
                local weaponclass = weapused:GetClass()
                WeaponKillBatches[attacker_steamid32] = WeaponKillBatches[attacker_steamid32] or {}
                WeaponKillBatches[attacker_steamid32][weaponclass] = (WeaponKillBatches[attacker_steamid32][weaponclass] or 0) + 1
                WeaponDeathBatches[ent_steamid32] = WeaponDeathBatches[ent_steamid32] or {}
                WeaponDeathBatches[ent_steamid32][weaponclass] = (WeaponDeathBatches[ent_steamid32][weaponclass] or 0) + 1
            end

            KillBatches[attacker_steamid32] = (KillBatches[attacker_steamid32] or 0) + 1
            DeathBatches[ent_steamid32] = (DeathBatches[ent_steamid32] or 0) + 1
        end
    end)

    local JoinBatches = {}
    gameevent.Listen("player_connect")
    hook.Add("player_connect", "TrackJoinTimes", function(data)
        local steamid = data.networkid
        JoinBatches[steamid] = (JoinBatches[steamid] or 0) + 1
        return
    end)

    --[[-write the memory into sql-]]
    -- sql.QueryTyped("UPDATE player_glickos SET matchesplayed = matchesplayed + 1 WHERE steamid64 = ? OR steamid64 = ?", winner_steamid64, loser_steamid64)
    local BatchClearDelay = 240
    local BatchRunCount = 500 -- limiting the for loop is probably a good idea to not lag the server ever BatchClearDelay seconds
    timer.Create("SendBatchesSQL", BatchClearDelay, 0, function()
        print("Writing batch to sql")
        local i = 0
        sql.QueryTyped("BEGIN;")
        for steamid32, damagecount in pairs(DamageBatches) do
            if i >= BatchRunCount then break end
            print("Updating " .. steamid32)
            sql.QueryTyped("INSERT INTO player_info (steamid32, damage) VALUES(?, ?) ON CONFLICT(steamid32) DO UPDATE SET damage=damage + ?", steamid32, damagecount, damagecount)
            DamageBatches[steamid32] = nil
            i = i + 1
        end

        for steamid32, killcount in pairs(KillBatches) do
            if i >= BatchRunCount then break end
            print("Updating " .. steamid32)
            sql.QueryTyped("INSERT INTO player_info (steamid32, kills) VALUES(?, ?) ON CONFLICT(steamid32) DO UPDATE SET kills=kills + ?", steamid32, killcount, killcount)
            KillBatches[steamid32] = nil
            i = i + 1
        end

        for steamid32, deathcount in pairs(DeathBatches) do
            if i >= BatchRunCount then break end
            print("Updating " .. steamid32)
            sql.QueryTyped("INSERT INTO player_info (steamid32, kills) VALUES(?, ?) ON CONFLICT(steamid32) DO UPDATE SET kills=kills + ?", steamid32, deathcount, deathcount)
            DeathBatches[steamid32] = nil
            i = i + 1
        end

        for steamid32, tbl in pairs(WeaponKillBatches) do
            if i >= BatchRunCount then break end
            for weaponclass, killcount in pairs(tbl) do
                sql.QueryTyped("INSERT INTO weapon_kills (steamid32, weaponclass, kills) VALUES (?, ?, ?) ON CONFLICT(steamid32, weaponclass) DO UPDATE SET kills = kills + excluded.kills", steamid32, weaponclass, killcount)
                WeaponKillBatches[steamid32][weaponclass] = nil
            end

            WeaponKillBatches[steamid32] = nil
            i = i + 1
        end

        for steamid32, tbl in pairs(WeaponDeathBatches) do
            if i >= BatchRunCount then break end
            for weaponclass, deathcount in pairs(tbl) do
                sql.QueryTyped("INSERT INTO weapon_deaths (steamid32, weaponclass, deaths) VALUES (?, ?, ?) ON CONFLICT(steamid32, weaponclass) DO UPDATE SET deaths = deaths + excluded.deaths", steamid32, weaponclass, deathcount)
                WeaponDeathBatches[steamid32][weaponclass] = nil
            end

            WeaponDeathBatches[steamid32] = nil
            i = i + 1
        end

        for steamid32, count in pairs(JoinBatches) do
            --sql.QueryTyped("INSERT OR IGNORE INTO player_info (steamid32) VALUES (?)", steamid32)
            --sql.QueryTyped("UPDATE player_info SET damage = damage + ? WHERE steamid32 = ?", damagecount, steamid32)
            sql.QueryTyped("INSERT INTO player_info (steamid32, timesjoined) VALUES(?, ?) ON CONFLICT(steamid32) DO UPDATE SET timesjoined=excluded.timesjoined", steamid32, count)
        end

        print("Finished writing batch" .. "(" .. i .. ")")
        sql.QueryTyped("COMMIT;")
    end)
end
