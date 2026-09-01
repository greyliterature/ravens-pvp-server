if CLIENT then
    local DiscordInviteReceived = false
    local DiscordInvite = ""
    local RequirementMet = false
    --
    local RNDX = include("rndx.lua")
    -- Fonts
    surface.CreateFont("TimesNewRomanTitle", {
        font = "Times New Roman",
        extended = false,
        size = 36,
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

    surface.CreateFont("TimesNewRomanHeader", {
        font = "Times New Roman",
        extended = false,
        size = 26,
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

    surface.CreateFont("TimesNewRomanBody", {
        font = "Times New Roman",
        extended = false,
        size = 26,
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

    surface.CreateFont("TimesNewRomanUnderlined", {
        font = "Times New Roman",
        extended = false,
        size = 26,
        weight = 500,
        blursize = 0,
        scanlines = 0,
        antialias = true,
        underline = true,
        italic = false,
        strikeout = false,
        symbol = false,
        rotary = false,
        shadow = false,
        additive = false,
        outline = false,
    })

    surface.CreateFont("TimesNewRomanSubTitle", {
        font = "Times New Roman",
        extended = false,
        size = 17,
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

    ----
    -- Colors
    local TextYellow = Color(255, 172, 8, 255)
    local ScrollBarLightYellow = Color(221, 157, 0, 255)
    local ScrollBarDarkishYellow = Color(185, 100, 0, 255)
    local ScrollBarDarkYellow = Color(181, 117, 0, 255)
    local ScrollBarDarkestYellow = Color(151, 87, 0, 120)
    local ScrollBarDarkerestYellow = Color(151, 87, 0, 40)
    local PanelBlack = Color(0, 0, 0, 170)
    local ButtonBlack = Color(0, 0, 0, 170)
    --local color_red = Color(255, 0, 0, 255)
    ----
    local function GetTextSize(font, text)
        surface.SetFont(font)
        local w, h = surface.GetTextSize(text)
        local _, NewlinesNumber = string.gsub(text, "\n", "")
        return w, h * (NewlinesNumber + 1)
    end

    local MainPanel = nil
    local Admins = {}
    local CommitData = {}
    local function ShowMOTD()
        if IsValid(MainPanel) then MainPanel:Remove() end
        MainPanel = vgui.Create("DPanel") -- what everything is parented to
        MainPanel:SetSize(ScrW() * 0.6, ScrH() * 0.7)
        MainPanel:SetPos((ScrW() - MainPanel:GetWide()) * 0.5, (ScrH() - MainPanel:GetTall()) * 0.5)
        MainPanel:MakePopup()
        function MainPanel.Paint()
        end

        local TopPanel = vgui.Create("DPanel", MainPanel) -- holds server header
        TopPanel:Dock(TOP)
        --TopPanel:SetBackgroundColor(PanelBlack)
        TopPanel:SetTall(MainPanel:GetTall() * 0.10)
        local _, textH = GetTextSize("Trebuchet24", GetHostName())
        function TopPanel.Paint(self, w, h)
            if not RNDX then
                surface.SetDrawColor(PanelBlack)
                surface.DrawRect(0, 0, w, h)
            else
                surface.SetDrawColor(PanelBlack)
                RNDX.Draw(TopPanel:GetTall() * 0.25, 0, 0, w, h, PanelBlack, RNDX.NO_BL + RNDX.NO_BR + RNDX.MANUAL_COLOR)
            end

            draw.DrawText(GetHostName(), "Trebuchet24", w * 0.05, (h - textH) * 0.5, TextYellow)
        end

        -- Thanks s0lum for dmodelpanel code
        local coolhoob2 = vgui.Create("DModelPanel", TopPanel) -- woa h wooweee look at him gooooo !
        coolhoob2:SetSize(TopPanel:GetTall() * 0.99, TopPanel:GetTall() * 0.99)
        coolhoob2:SetPos(0, (TopPanel:GetTall() - TopPanel:GetTall() * 0.99) * 0.5)
        coolhoob2:SetModel("models/player/Group01/female_01.mdl")
        coolhoob2:SetAnimated(true)
        local mdl = coolhoob2:GetEntity()
        mdl:SetColor(TextYellow)
        mdl:SetMaterial("debug/debugportals")
        function coolhoob2:PreDrawModel(ent)
            render.SuppressEngineLighting(true)
            local r = TextYellow.r / 255
            local g = TextYellow.g / 255
            local b = TextYellow.b / 255
            render.SetColorModulation(r, g, b)
        end

        function coolhoob2:LayoutEntity()
            coolhoob2:SetCamPos(Vector(50, 50, 50))
            if not mdl.SeqStart or CurTime() > (mdl.SeqStart + mdl.SeqDuration) then
                local idx = mdl:LookupSequence("taunt_dance")
                mdl.SeqDuration = mdl:SequenceDuration(idx)
                mdl.SeqStart = CurTime()
                mdl:ResetSequence(idx)
            end

            mdl:SetCycle((CurTime() - mdl.SeqStart) / mdl.SeqDuration)
        end

        local MiddlePanel = vgui.Create("DScrollPanel", MainPanel) -- middle content panel
        MiddlePanel:Dock(TOP)
        MiddlePanel:SetBackgroundColor(PanelBlack)
        MiddlePanel:SetTall(MainPanel:GetTall() * 0.8)
        MiddlePanel:GetCanvas():DockPadding(MainPanel:GetWide() * 0.05, 0, MainPanel:GetWide() * 0.05, 0)
        function MiddlePanel.Paint(self, w, h)
            if not RNDX then
                surface.SetDrawColor(PanelBlack)
                surface.DrawRect(0, 0, w, h)
            else
                surface.SetDrawColor(PanelBlack)
                RNDX.Draw(0, 0, 0, w, h, PanelBlack, RNDX.NO_BL + RNDX.NO_BR + RNDX.MANUAL_COLOR)
            end
        end

        -- MiddlePanel Texts
        local MiddlePanelText = {
            -- Make an empty line with a certain font size if you want spacing. too lazy to add proper spacing.
            {"Rules", "TimesNewRomanTitle", TEXT_ALIGN_LEFT, color_white},
            {"     1. No cheating", "TimesNewRomanBody", TEXT_ALIGN_LEFT, color_white},
            {"     2. No bigotry", "TimesNewRomanBody", TEXT_ALIGN_LEFT, color_white},
            {"     3. No teaming", "TimesNewRomanBody", TEXT_ALIGN_LEFT, color_white},
            {"Useful commands", "TimesNewRomanTitle", TEXT_ALIGN_LEFT, color_white},
            {"    !hotload wsid (Superadmin only) - Load any map.", "TimesNewRomanBody", TEXT_ALIGN_LEFT, color_white},
            {"              Example: !hotload 3044043514 --> Hotloaded dm_villa_b3.bsp", "TimesNewRomanSubTitle", TEXT_ALIGN_LEFT, color_white},
            {"              (Ask an admin and they might load a map for you)", "TimesNewRomanSubTitle", TEXT_ALIGN_LEFT, color_white},
            {"     rv_handicap  -  Percent damage you give to other players. (1 - 100)", "TimesNewRomanBody", TEXT_ALIGN_LEFT, color_white},
            {"     rv_spawnweapon  -  Weapon you spawn holding. (Default 357)", "TimesNewRomanBody", TEXT_ALIGN_LEFT, color_white},
            {"     rv_farz  -  Clientside render distance. (Default max)", "TimesNewRomanBody", TEXT_ALIGN_LEFT, color_white},
            {"     rv_outlines  -  Whether or not to outline enemy players. (0 / 1)", "TimesNewRomanBody", TEXT_ALIGN_LEFT, color_white},
            {"     rv_targetid  -  Whether or not to draw the HP and names of enemies. (0 / 1)", "TimesNewRomanBody", TEXT_ALIGN_LEFT, color_white},
            {"     rv_hitsounds_*  -  All the Hitsound commands.", "TimesNewRomanBody", TEXT_ALIGN_LEFT, color_white},
            {"     !t TL Message  -  Translate message to target language and send it to chat.", "TimesNewRomanBody", TEXT_ALIGN_LEFT, color_white},
            {"              Example: !t ru hello  --> привет", "TimesNewRomanSubTitle", TEXT_ALIGN_LEFT, color_white},
            {"Admins", "TimesNewRomanTitle", TEXT_ALIGN_LEFT, color_white},
            {" ", "TimesNewRomanSubTitle", TEXT_ALIGN_LEFT, color_white},
            {"Latest Commits", "TimesNewRomanTitle", TEXT_ALIGN_LEFT, color_white},
        }

        for i = 1, #MiddlePanelText do
            if MiddlePanelText[i][1] == "Latest Commits" then CommitsIndex = i end
            if MiddlePanelText[i][1] == "Admins" then AdminsIndex = i end
        end

        for i = #CommitData, 1, -1 do
            if not CommitsIndex then return end
            table.insert(MiddlePanelText, CommitsIndex + 1, {"     " .. CommitData[i], "TimesNewRomanBody", TEXT_ALIGN_LEFT, color_white})
        end

        for name, steamID in pairs(Admins) do
            if not AdminsIndex then return end
            table.insert(MiddlePanelText, AdminsIndex + 1, {"     " .. name, "TimesNewRomanUnderlined", TEXT_ALIGN_LEFT, color_white, "https://steamcommunity.com/profiles/" .. util.SteamIDTo64(steamID)})
        end

        if DiscordInviteReceived == true then
            table.insert(MiddlePanelText, #MiddlePanelText + 1, {"Discord", "TimesNewRomanTitle", TEXT_ALIGN_LEFT, color_white})
            table.insert(MiddlePanelText, #MiddlePanelText + 1, {"     " .. "https://" .. DiscordInvite, (RequirementMet == true and "TimesNewRomanUnderlined") or "TimesNewRomanBody", TEXT_ALIGN_LEFT, color_white, (RequirementMet == true and ("https:// " .. DiscordInvite)) or false})
        end

        table.insert(MiddlePanelText, #MiddlePanelText + 1, {"", "TimesNewRomanSubTitle", TEXT_ALIGN_LEFT, color_white})
        for i = 1, #MiddlePanelText do -- Format the text based on its prefixed text, easier than make custom VGUI for this.
            local TextLabel = vgui.Create("DLabel", MiddlePanel)
            TextLabel:Dock(TOP)
            TextLabel:SetText("")
            local text, font, xAlign, col, link = unpack(MiddlePanelText[i])
            TextLabel.Text = text
            local TextW, TextH = GetTextSize(font or "Trebuchet24", TextLabel.Text)
            TextLabel:SetTall(TextH)
            function TextLabel.Paint(self, w, h)
                if link then
                    local mousex, _ = self:CursorPos()
                    if self:IsHovered() and mousex <= TextW then -- holy hell just let me setsize independent of docktop
                        self:SetCursor("hand")
                    else
                        self:SetCursor("arrow")
                    end
                end

                draw.DrawText(self.Text, font, 0, 0, col or color_white, xAlign)
            end

            if link then
                TextLabel:SetMouseInputEnabled(true)
                function TextLabel.DoClick(self, w, h)
                    local mousex, _ = self:CursorPos()
                    if mousex <= TextW then -- holy hell just let me setsize on docktop
                        gui.OpenURL(link)
                    end
                end
            end
        end

        local MiddleScrollBar = MiddlePanel:GetVBar()
        MiddleScrollBarButtonH = nil
        function MiddleScrollBar.Paint(self, w, h)
            if MiddleScrollBarButtonH then -- MiddleScrollBar.btnUp doesn't give the correct value...
                surface.SetDrawColor(ScrollBarDarkishYellow)
                surface.DrawOutlinedRect(0, 0 + MiddleScrollBarButtonH, w, h - MiddleScrollBarButtonH * 2) -- Need to make the boxes meet up to the arrow buttons
            end
        end

        function MiddleScrollBar.btnUp.Paint(self, w, h)
            local UpTriangle = {
                -- https://wiki.facepunch.com/gmod/surface.DrawPoly#example
                {
                    x = (w - w * 0.75) / 2,
                    y = h * 0.75
                },
                {
                    x = (w - w * 0.75) / 2 + (w * 0.375),
                    y = h * 0.3
                },
                {
                    x = (w - w * 0.75 + 0) / 2 + w * 0.75,
                    y = h * 0.75
                }
            }

            if not MiddleScrollBarButtonH then MiddleScrollBarButtonH = h end
            surface.SetDrawColor(ScrollBarDarkYellow)
            surface.DrawPoly(UpTriangle)
            --draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 255))
        end

        function MiddleScrollBar.btnGrip.Paint(self, w, h)
            surface.SetDrawColor(ScrollBarLightYellow)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            surface.SetDrawColor(ScrollBarDarkerestYellow)
            if self.Depressed == true then surface.SetDrawColor(ScrollBarDarkestYellow) end
            surface.DrawRect(0, 0, self:GetWide(), self:GetTall())
        end

        function MiddleScrollBar.btnDown.Paint(self, w, h)
            local DownTriangle = {
                {
                    x = (w - w * 0.75) / 2,
                    y = h * 0.3
                },
                {
                    x = (w - w * 0.75) / 2 + (w * 0.375),
                    y = h * 0.75
                },
                {
                    x = (w - w * 0.75 + 0) / 2 + w * 0.75,
                    y = h * 0.3
                }
            }

            if not MiddleScrollBarButtonH then MiddleScrollBarButtonH = h end
            surface.SetDrawColor(ScrollBarDarkYellow)
            surface.DrawPoly(DownTriangle)
            --draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 255))
        end

        local BottomPanel = vgui.Create("DPanel", MainPanel) -- my buttn holder
        BottomPanel:Dock(TOP)
        --BottomPanel:SetBackgroundColor(PanelBlack)
        BottomPanel:SetTall(MainPanel:GetTall() * 0.10)
        function BottomPanel.Paint(self, w, h)
            if not RNDX then
                surface.SetDrawColor(PanelBlack)
                surface.DrawRect(0, 0, w, h)
            else
                surface.SetDrawColor(PanelBlack)
                RNDX.Draw(TopPanel:GetTall() * 0.25, 0, 0, w, h, PanelBlack, RNDX.NO_TL + RNDX.NO_TR + RNDX.MANUAL_COLOR)
            end
        end

        local CloseButton = vgui.Create("DButton", BottomPanel)
        CloseButton:SetText("")
        CloseButton:SetSize(MainPanel:GetWide() * 0.15, BottomPanel:GetTall() * 0.45)
        CloseButton:SetPos(MainPanel:GetWide() * 0.04, 0)
        CloseButton.Text = "OK"
        local TextW, TextH = GetTextSize("Trebuchet24", CloseButton.Text)
        function CloseButton.Paint(self, w, h)
            if self:IsHovered() then --
                surface.SetDrawColor(TextYellow)
                surface.DrawOutlinedRect((w - w * 0.93) * 0.5, (h - h * 0.85) * 0.5, w * 0.93, h * 0.85, 1)
            end

            surface.SetDrawColor(ButtonBlack)
            surface.DrawRect(0, 0, w, h)
            draw.DrawText(self.Text, "Trebuchet24", (w - TextW) * 0.5, (h - TextH) * 0.5, TextYellow)
        end

        function CloseButton.DoClick(self)
            MainPanel:Remove()
        end
    end

    net.Receive("SendDiscordInvite", function(len, ply)
        DiscordInvite = net.ReadString()
        RequirementMet = net.ReadBool()
        DiscordInviteReceived = true
    end)

    net.Receive("SendCommitData", function(len, ply)
        --
        CommitData = net.ReadTable()
    end)

    net.Receive("SendAdminMOTDInfo", function(len, ply)
        Admins = net.ReadTable()
        timer.Create("MakeSureCommitDataIsReceived", 0.5, 50, function()
            --
            if #CommitData > 0 then --
                timer.Remove("MakeSureCommitDataIsReceived")
                ShowMOTD()
            end
        end)
    end)

    hook.Add("OnPlayerChat", "ShowMOTDOnChat", function(ply, text, teamChat, isDead)
        if ply ~= LocalPlayer() then return end
        if text == "!motd" then ShowMOTD() end
    end)
end