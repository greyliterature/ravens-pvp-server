-- TODO
-- holding a shape over the grid should make CurrentShape transparent and preview the shape on the grid like hammer
-- editing shapes should be based on the midpoint and click throughable until you get the one you want
-- when clicking to edit the shape it should be right clickable and also change to a random color temporarily
-- add shapes
local function WhatPanelTrace(PanelToIgnore) -- check what panels the cursor is within the bounds of, and choose the frontmost one
    local TrueHoveredPanel = nil
    local ValidPanels = {} -- list of panels to go through with zpos score
    local cursorx, cursory = input.GetCursorPos()
    for _, panel in ipairs(vgui.GetAll()) do
        if panel == PanelToIgnore then continue end
        if panel:IsVisible() == false then continue end
        if not IsValid(panel) then continue end
        local parent = panel:GetParent()
        if IsValid(parent) and parent:IsVisible() == false then continue end
        local x, y = panel:LocalToScreen(0, 0)
        local xextent, yextent = panel:GetWide(), panel:GetTall()
        if cursorx <= x + xextent and cursorx >= x and cursory <= y + yextent and cursory >= y then --
            ValidPanels[#ValidPanels + 1] = panel
        end
    end

    if not TrueHoveredPanel then
        local BestZPos = math.huge * -1
        for _, panel in ipairs(ValidPanels) do
            local PanelZPos = panel:GetZPos()
            if PanelZPos > BestZPos then
                TrueHoveredPanel = panel
                BestZPos = PanelZPos
            end
        end
    end
    return TrueHoveredPanel
end

--timer.Simple(1, function() WhatPanelTrace():Remove() end)
local color_green = Color(0, 255, 0)
local color_red = Color(255, 0, 0)
local color_hammer_grey = Color(82, 82, 82)
local color_black_transparentish = Color(0, 0, 0, 240)
--
local background_1 = Material("gui/crosshair_bg2.png")
concommand.Add("rv_custom_crosshair_setup", function()
    if IsValid(MegaPanel) then
        print("yep removed`")
        MegaPanel:Remove()
    end

    MegaPanel = vgui.Create("DPanel")
    MegaPanel:SetSize(ScrW(), ScrH())
    MegaPanel:SetMouseInputEnabled(true)
    MegaPanel:SetZPos(-1000)
    MegaPanel:SetBackgroundColor(color_black_transparentish)
    function MegaPanel.OnMousePressed(self, keycode)
        print("yeee")
        self:Remove()
    end

    local frame = vgui.Create("DFrame", MegaPanel)
    frame:SetSize(ScrW() * 0.4, ScrH() * 0.513)
    --frame:Center()
    frame:SetPos(0, 0) -- debugging reasons
    frame:MakePopup()
    frame:SetZPos(-1)
    frame.Test = true
    function frame.OnRemove()
        MegaPanel:Remove()
    end

    function frame.OnClose()
        print("yeup")
        MegaPanel:Remove() -- shouldnt need isvalid check
    end

    local preview = vgui.Create("DImage", frame)
    preview:Dock(LEFT)
    local _, top, _, bottom = frame:GetDockPadding()
    --preview:SetPos(left, top)
    preview:SetTall(math.ceil(frame:GetTall() - bottom - top - 1))
    preview:SetWide(preview:GetTall())
    preview:SetZPos(1)
    preview:SetMouseInputEnabled(true)
    local _Matrix = {}
    local MatrixSize = 16
    --[[
    for x = 1, MatrixSize do
        local NewIndex = #_Matrix + 1
        _Matrix[NewIndex] = {}
        for y = 1, MatrixSize do
            _Matrix[NewIndex][#_Matrix[NewIndex] + 1] = "E"
        end
    end
    --]]
    local PreviewShapes = {}
    local function ShapeTableToDrawFunction(shapetable, w, h)
        if shapetable["Shape"] == "Rectangle" then
            surface.SetDrawColor(shapetable.Color)
            surface.DrawRect(shapetable["X"], shapetable["Y"], w or shapetable["W"], h or shapetable["H"])
        else
        end
    end

    local OutlineThickness = 1 -- a line is 1 pixel
    function preview.Paint(self, w, h)
        --[[
        if true then
            surface.SetDrawColor(ColorRand())
            surface.DrawRect(0, 0, w, h)
            return
        end
        --]]
        surface.SetDrawColor(color_white)
        surface.SetMaterial(background_1)
        surface.DrawTexturedRect(0, 0, w, h)
        surface.SetDrawColor(color_black_transparentish)
        surface.DrawRect(0, 0, w, h)
        for x = 1, MatrixSize do
            if x * w / MatrixSize == w * 0.5 then --
                surface.SetDrawColor(color_red)
            else
                surface.SetDrawColor(color_hammer_grey)
            end

            surface.DrawRect(x * w / MatrixSize, 0, 1, h)
            --surface.DrawLine(x * w / MatrixSize, 0, x * w / MatrixSize, h)
            for y = 1, MatrixSize do
                if y * w / MatrixSize == w * 0.5 then --
                    surface.SetDrawColor(color_red)
                else
                    surface.SetDrawColor(color_hammer_grey)
                end

                --surface.DrawLine(0, y * w / MatrixSize, w, y * w / MatrixSize)
                surface.DrawRect(0, y * w / MatrixSize, w, 1)
            end
        end

        surface.DrawLine(0 + 1, 0, 0 + 1, h)
        surface.DrawLine(w - 1, 0, w - 1, h)
        surface.DrawLine(0, 0 + 1, w, 0 + 1)
        surface.DrawLine(0, h - 1, w, h - 1)
        --[[
        for shapetable, _ in pairs(PreviewShapes) do
            ShapeTableToDrawFunction(shapetable)
        end
        --]]
    end

    local GridSize = math.floor(preview:GetWide() / MatrixSize)
    preview:SetSize(GridSize * MatrixSize, GridSize * MatrixSize)
    frame:SetTall(preview:GetTall() + top + bottom) -- sigh
    local GridEnabled = true
    local function AlignToGrid(x, y)
        if GridEnabled == false then return x, y end
        return math.floor(x / GridSize) * GridSize, math.floor(y / GridSize) * GridSize
    end

    local SelectedPanel = nil
    local SelectedPosition = nil
    local LastAnchorPoints = {}
    function preview.AddShape(self, shapetable)
        print("added shape")
        local shapepanel = vgui.Create("DPanel", self)
        function shapepanel.InsetWithOutlines(truthfulself)
            if GridEnabled == false then return end
            --truthfulself:SetPos(truthfulself:GetX() + OutlineThickness, truthfulself:GetY() + OutlineThickness)
            --truthfulself:SetSize(truthfulself:GetWide(), truthfulself:GetTall() - OutlineThickness)
        end

        local gridx, gridy = AlignToGrid(shapetable["X"], shapetable["Y"])
        shapepanel:SetPos(gridx + OutlineThickness, gridy + OutlineThickness)
        shapepanel:SetSize(GridSize - OutlineThickness, GridSize - OutlineThickness)
        shapepanel:SetZPos(100)
        shapepanel.IsShape = true
        --shapepanel:InsetWithOutlines()
        shapepanel.shapetable = shapetable
        shapetable["X"], shapetable["Y"] = 0, 0 -- because were manually painting within the panel itself, its 0 0
        function shapepanel.Paint(trueself, w, h)
            ShapeTableToDrawFunction(trueself.shapetable, w, h)
        end

        local AnchorPointSize = ScrW() * 0.005
        local AnchorPointParent = preview
        local function MoveAnchorPoints(panel, anchorpointtype, currentanchorpoint)
            local panelx, panely = panel:GetX(), panel:GetY()
            local panelwidth, panelheight = panel:GetWide(), panel:GetTall()
            local anchorpoints = {
                topleft = {panelx - AnchorPointSize, panely - AnchorPointSize},
                topright = {panelx + panelwidth, panely - AnchorPointSize},
                bottomleft = {panelx - AnchorPointSize, panely + panelheight},
                bottomright = {panelx + panelwidth, panely + panelheight},
                centerleft = {panelx - AnchorPointSize, panely + panelheight * 0.5 - AnchorPointSize * 0.5},
                centerright = {panelx + panelwidth, panely + panelheight * 0.5 - AnchorPointSize * 0.5},
                centerbottom = {panelx + panelwidth * 0.5 - AnchorPointSize * 0.5, panely + panelheight},
                centertop = {panelx + panelwidth * 0.5 - AnchorPointSize * 0.5, panely - AnchorPointSize},
            }

            for _, pnl in ipairs(LastAnchorPoints) do
                if not IsValid(pnl) then continue end
                if pnl == currentanchorpoint then continue end
                print(anchorpoints[pnl.Position][1], anchorpoints[pnl.Position][1], "HEYY")
                pnl:SetPos(anchorpoints[pnl.Position][1], anchorpoints[pnl.Position][2])
            end
        end

        local MinimumShapeSize = 16
        local function MakeAnchorPoints(panel, anchorpointtype)
            for _, pnl in ipairs(LastAnchorPoints) do
                if not IsValid(pnl) then continue end
                pnl:Remove()
            end

            local panelx, panely = panel:GetX(), panel:GetY()
            local panelwidth, panelheight = panel:GetWide(), panel:GetTall()
            local anchorpoints = {
                sizing = {
                    topleft = {panelx - AnchorPointSize, panely - AnchorPointSize},
                    topright = {panelx + panelwidth, panely - AnchorPointSize},
                    bottomleft = {panelx - AnchorPointSize, panely + panelheight},
                    bottomright = {panelx + panelwidth, panely + panelheight},
                },
                dragging = {
                    centerleft = {panelx - AnchorPointSize, panely + panelheight * 0.5 - AnchorPointSize * 0.5},
                    centerright = {panelx + panelwidth, panely + panelheight * 0.5 - AnchorPointSize * 0.5},
                    centerbottom = {panelx + panelwidth * 0.5 - AnchorPointSize * 0.5, panely + panelheight},
                    centertop = {panelx + panelwidth * 0.5 - AnchorPointSize * 0.5, panely - AnchorPointSize},
                }
            }

            function panel.OnRemove()
                for _, pnl in ipairs(LastAnchorPoints) do
                    if not IsValid(pnl) then continue end
                    pnl:Remove()
                end
            end

            for point, tbl in pairs((anchorpointtype == "drag" and anchorpoints["dragging"]) or anchorpoints["sizing"]) do
                local anchorpoint = vgui.Create("DPanel", AnchorPointParent)
                anchorpoint:SetSize(AnchorPointSize, AnchorPointSize)
                anchorpoint:SetPos(tbl[1], tbl[2])
                anchorpoint:SetZPos(-1)
                anchorpoint:SetMouseInputEnabled(true)
                anchorpoint.IsAnchorPoint = true
                anchorpoint.Position = point
                function anchorpoint.OnMousePressed(truthfulestself, keyCode)
                    if keyCode ~= MOUSE_LEFT then return end
                    print("i was clicked!!", truthfulestself.Position)
                    SelectedPosition = truthfulestself.Position
                    local cursorx, cursory = self:CursorPos()
                    truthfulestself.OldCursorPos = {cursorx, cursory}
                    truthfulestself.StartPos = {SelectedPanel:GetX(), SelectedPanel:GetY()}
                end

                function anchorpoint.Think(truthfullyself)
                    if not SelectedPosition then return end
                    if truthfullyself.Position ~= SelectedPosition then return end
                    if anchorpointtype == "drag" then
                        local oldcursorx, oldcursory = truthfullyself.OldCursorPos[1], truthfullyself.OldCursorPos[2]
                        local currentcursorx, currentcursory = self:CursorPos()
                        local offsetx, offsety = currentcursorx - oldcursorx, currentcursory - oldcursory
                        if SelectedPosition == "centerbottom" then
                            SelectedPanel:SetY(select(2, AlignToGrid(0, truthfullyself.StartPos[2] + offsety)) + OutlineThickness)
                        elseif SelectedPosition == "centertop" then
                            SelectedPanel:SetY(select(2, AlignToGrid(0, truthfullyself.StartPos[2] + offsety)) + OutlineThickness)
                        elseif SelectedPosition == "centerleft" then
                            SelectedPanel:SetX(select(1, AlignToGrid(truthfullyself.StartPos[1] + offsetx, 0)) + OutlineThickness)
                        elseif SelectedPosition == "centerright" then
                            SelectedPanel:SetX(select(1, AlignToGrid(truthfullyself.StartPos[1] + offsetx, 0)) + OutlineThickness)
                        end

                        print(preview:GetWide(), SelectedPanel:GetX() + SelectedPanel:GetWide())
                        -- dont move the thing past the panel bounds, 
                        -- dont do this for sizing though, causes issues, and also unexpected behavior (ish?)
                        SelectedPanel:SetPos(math.min(preview:GetWide() - SelectedPanel:GetWide(), SelectedPanel:GetX()), math.min(preview:GetTall() - SelectedPanel:GetTall(), SelectedPanel:GetY()))
                        MoveAnchorPoints(panel)
                    else
                        if SelectedPosition == "bottomright" then
                            local SelectedPanelX, SelectedPanelY = SelectedPanel:GetPos()
                            truthfullyself:SetPos(AlignToGrid(self:CursorPos()))
                            SelectedPanel:SetSize(math.max(MinimumShapeSize, truthfullyself:GetX() - SelectedPanelX), math.max(MinimumShapeSize, truthfullyself:GetY() - SelectedPanelY))
                        end

                        SelectedPanel:SetSize(math.Clamp(select(1, AlignToGrid(self:CursorPos())) - SelectedPanel:GetX(), GridSize - OutlineThickness, preview:GetWide() - SelectedPanel:GetX()), math.Clamp(select(2, AlignToGrid(self:CursorPos())) - SelectedPanel:GetY(), GridSize - OutlineThickness, preview:GetTall() - SelectedPanel:GetY()))
                        MoveAnchorPoints(panel)
                    end
                end

                LastAnchorPoints[#LastAnchorPoints + 1] = anchorpoint
            end
        end

        shapepanel.edittype = nil
        function shapepanel.OnMousePressed(truthfullyself, keycode)
            if keycode == MOUSE_LEFT then --
                if shapepanel.edittype == true then
                    MakeAnchorPoints(truthfullyself, "drag")
                else
                    MakeAnchorPoints(truthfullyself)
                end

                shapepanel.edittype = not shapepanel.edittype
                --self.Dragging = true just replace this with a right click and "drag selected" context menu option, this is too annoying
                SelectedPanel = truthfullyself
            end
        end

        function shapepanel.OnMouseReleased(_, keycode)
            if keycode == MOUSE_LEFT then --
                --self.Dragging = nil
                print("RELEASE")
                --self.Selected = false
            end
        end
        --[[
        function shapepanel.Think(truestself)
            if self.Dragging == true then --
                local GridX, GridY = AlignToGrid(self:ScreenToLocal(input.GetCursorPos()))
                truestself:SetPos(GridX + OutlineThickness, GridY + OutlineThickness)
                truestself:InsetWithOutlines()
            end
        end
        --]]
        --PreviewShapes[shapetable] = true
    end

    hook.Add("VGUIMousePressed", "SelectedPanel", function(panel, mouseCode)
        -- remember to hook.remove this later
        if panel.IsAnchorPoint == true then return end
        if panel.IsShape == true then return end
        if IsValid(SelectedPanel) then SelectedPanel.edittype = nil end
        SelectedPanel = nil
        SelectedPosition = nil -- the anchorpoints
        for _, pnl in ipairs(LastAnchorPoints) do
            if not IsValid(pnl) then continue end
            pnl:Remove()
        end
    end)

    hook.Add("VGUI")
    local LastMouseDown = nil
    -- why do i have to do this? is there really no mousereleased hook?
    hook.Add("Think", "SelectedPanel", function()
        local MouseDown = input.IsMouseDown(MOUSE_LEFT)
        if MouseDown == false and LastMouseDown == true then
            print("RELEASED!!!")
            SelectedPosition = nil
        end

        local KeyDown = input.IsKeyDown(KEY_DELETE)
        if KeyDown == true and IsValid(SelectedPanel) then --
            SelectedPanel:Remove()
        end

        LastMouseDown = input.IsMouseDown(MOUSE_LEFT)
    end)

    --[[
    function preview.EditShape(self, shapetable, element, newvalue)
        PreviewShapes[shapetable][element] = newvalue
    end

    function preview.RemoveShape(self, shapetable)
        PreviewShapes[shapetable] = nil
    end
    --]]
    --[[
    timer.Simple(0.12, function()
        if not IsValid(preview) then return end
        local OneGridSize = preview:GetWide() / #_Matrix
        print(OneGridSize)
        for x = 1, #_Matrix do
            local row = vgui.Create("DPanel", preview)
            row:SetWide(preview:GetWide())
            row:SetTall(OneGridSize)
            row:Dock(TOP)
            row:SetPos(0, 0)
            function row.Paint(_, _, _)
            end

            for y = 1, #_Matrix[x] do
                local panel = vgui.Create("DPanel", row)
                panel:Dock(LEFT)
                panel:SetSize(OneGridSize, OneGridSize)
                local OutlineSize = 1
                -- will need to use drawlines instead of outlined rect if i want it to look like hammer with thicker gridlines on even numbers
                function panel.Paint(self, w, h)
                    surface.SetDrawColor(color_black_transparentish)
                    surface.DrawRect(0, 0, w, h)
                    surface.SetDrawColor(color_hammer_grey)
                    surface.DrawOutlinedRect(0, 0, w, h, OutlineSize)
                end
            end
        end
    end)
--]]
    local settings = vgui.Create("DPanel", frame)
    settings:Dock(FILL)
    settings:DockPadding(5, 0, 0, 0)
    settings:SetBackgroundColor(color_black)
    local MarginX = ScrW() * 0.01
    local MarginY = ScrH() * 0.02
    local ButtonSizes = GridSize -- shared between all the buttons
    local RectButton = vgui.Create("DPanel", settings)
    RectButton:SetPos(MarginX, MarginY)
    RectButton:SetSize(ButtonSizes, ButtonSizes)
    RectButton:SetMouseInputEnabled(true)
    local CurrentShape = nil
    function RectButton.OnMousePressed(self, keycode)
        if keycode == MOUSE_LEFT then --
            print("i think i was clicked")
            if IsValid(CurrentShape) then CurrentShape:Remove() end
            CurrentShape = vgui.Create("DPanel", MegaPanel) -- set parent to mega panel so that it removes itself later
            CurrentShape:SetZPos(100000)
            CurrentShape:SetBackgroundColor(color_red)
            CurrentShape:SetSize(ButtonSizes, ButtonSizes)
            CurrentShape:SetMouseInputEnabled(true)
            CurrentShape:OnMousePressed(MOUSE_LEFT)
            --CurrentShape:MakePopup()
            function CurrentShape.Think(trueself)
                local hoveredpanel = vgui.GetHoveredPanel()
                if hoveredpanel == trueself or not IsValid(hoveredpanel) then return end
                trueself:SetParent(hoveredpanel)
                trueself:SetPos(hoveredpanel:LocalCursorPos())
            end

            function CurrentShape.OnMouseReleased(truestself, truekeycode)
                if truekeycode == MOUSE_LEFT then
                    local CurrentlyHoveredPanel = WhatPanelTrace(truestself) -- the real one, not the one masked by currentshape
                    truestself:Remove()
                    if not IsValid(CurrentlyHoveredPanel) then
                        print("Sad")
                        return
                    end

                    if CurrentlyHoveredPanel ~= preview then
                        print("SAD")
                        print(CurrentlyHoveredPanel)
                        return
                    end

                    local x, y = CurrentlyHoveredPanel:CursorPos()
                    print("heyo")
                    CurrentlyHoveredPanel:AddShape({
                        ["Shape"] = "Rectangle",
                        ["X"] = x,
                        ["Y"] = y,
                        ["W"] = 16, -- make this dynamic later
                        ["H"] = 16,
                        ["Color"] = color_white
                    })
                    return
                end
            end
        end
    end

    function RectButton.Paint(_, w, h)
        surface.SetDrawColor(color_green)
        surface.DrawRect(0, 0, w, h)
    end

    local RectLabel = vgui.Create("DPanel", settings)
    RectLabel:SetPos(MarginX + ButtonSizes + MarginX, MarginY)
    RectLabel:SetSize(ButtonSizes, ButtonSizes)
    RectLabel.Text = "Rectangle"
    surface.SetFont("DermaDefault")
    RectLabel:SetWide(select(1, surface.GetTextSize(RectLabel.Text)))
    function RectLabel.Paint(self, w, h)
        draw.SimpleText(self.Text, "DermaDefault", 0, h * 0.5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
end)

timer.Simple(0, function() RunConsoleCommand("rv_custom_crosshair_setup") end)
