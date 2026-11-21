-- todo:
-- allow multiple files in the folder that loads the crosshair
local ShapeTable = {}
local RNDX = include("autorun/rndx.lua")
local function StartMask()
    render.SetStencilEnable(true)
    render.ClearStencil()
    render.SetStencilTestMask(255)
    render.SetStencilWriteMask(255)
    render.SetStencilPassOperation(STENCILOPERATION_KEEP)
    render.SetStencilZFailOperation(STENCILOPERATION_KEEP)
    render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_NEVER)
    render.SetStencilReferenceValue(9)
    render.SetStencilFailOperation(STENCILOPERATION_REPLACE)
end

local function MaskUse(Cut)
    render.SetStencilFailOperation(STENCILOPERATION_KEEP)
    render.SetStencilCompareFunction((Cut == true and STENCILCOMPARISONFUNCTION_NOTEQUAL) or STENCILCOMPARISONFUNCTION_EQUAL)
end

function draw.Circle(x, y, radius, seg)
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

    surface.DrawPoly(cir)
end

local StringToDrawFunctionTable = {
    ["RECT"] = {
        ["expectedconversions"] = {
            --
            function(X) return ScrW() * tonumber(X) end,
            function(Y) return ScrH() * tonumber(Y) end,
            function(W) return ScrW() * tonumber(W) end,
            function(H) return ScrH() * tonumber(H) end,
        },
        ["function"] = function(x, y, w, h)
            --
            surface.DrawRect(x, y, w, h)
        end
    },
    ["HOLLOWCIRCLE"] = {
        ["expectedconversions"] = {
            --
            function(centerX) return ScrW() * tonumber(centerX) end,
            function(centerY) return ScrH() * tonumber(centerY) end,
            function(radius) return ScrH() * tonumber(radius) end,
        },
        ["function"] = function(centerX, centerY, radius)
            --
            surface.DrawCircle(centerX, centerY, radius, surface.GetDrawColor())
        end,
    },
    ["ROTATEDTEXTUREDRECT"] = {
        ["expectedconversions"] = {
            --
            function(x) return ScrW() * x end,
            function(y) return ScrH() * y end,
            function(w) return ScrW() * w end,
            function(h) return ScrH() * h end,
            function(rotation) return tonumber(rotation) end,
        },
        ["function"] = function(x, y, w, h, rotation)
            --
            surface.DrawTexturedRectRotated(x, y, w, h, rotation)
        end
    },
    ["ROUNDEDRECT"] = {
        ["expectedconversions"] = {
            --
            function(radius) return ScrH() * radius end,
            function(x) return ScrW() * tonumber(x) end,
            function(y) return ScrH() * tonumber(y) end,
            function(w) return ScrW() * tonumber(w) end,
            function(h) return ScrH() * tonumber(h) end,
            function(flags) return tonumber(flags) end,
        },
        ["function"] = function(radius, x, y, w, h, flags)
            if RNDX then --
                RNDX.Draw(radius, x, y, w, h, surface.GetDrawColor(), flags)
            end
        end,
        ["expectedargumentcount"] = 4
    },
    ["FILLEDCIRCLE"] = {
        ["expectedconversions"] = {
            --
            function(x) return ScrW() * tonumber(x) end,
            function(y) return ScrH() * tonumber(y) end,
            function(radius) return math.Round(ScrH() * tonumber(radius)) * 2 end,
            function(flags) return tonumber(flags) end,
        },
        ["function"] = function(x, y, radius, flags)
            --
            RNDX.DrawCircle(x, y, radius, surface.GetDrawColor(), flags or 0)
        end,
        ["expectedargumentcount"] = 3
    },
    ["POLYGON"] = {
        ["expectedconversions"] = {
            -- 
            function(x) return math.Round(ScrW() * tonumber(x)) end,
            function(y) return math.Round(ScrH() * tonumber(y)) end,
            function(radius) return ScrH() * tonumber(radius) end,
            function(vertices) return tonumber(vertices) end,
        },
        ["function"] = function(x, y, radius, vertices)
            -- 
            draw.Circle(x, y, radius, vertices)
        end,
    },
    ["SETCOLOR"] = {
        ["expectedconversions"] = {
            --
            function(R) return tonumber(R) end,
            function(G) return tonumber(G) end,
            function(B) return tonumber(B) end,
            function(A) return tonumber(A) end
        },
        ["function"] = function(r, g, b, a)
            --
            surface.SetDrawColor(r, g, b, a or 255)
        end,
        ["expectedargumentcount"] = 3
    },
    ["SETTEXTURE"] = {
        ["expectedconversions"] = {
            --
            function(texture) return Material(texture) end,
        },
        --
        ["function"] = function(texture)
            --
            surface.SetMaterial(texture)
        end
    },
    ["#STARTSTENCIL"] = {
        ["expectedconversions"] = {},
        --
        ["function"] = function()
            --
            StartMask()
        end,
    },
    ["#STARTMASK"] = {
        ["expectedconversions"] = {},
        --
        ["function"] = function()
            --
            StartMask()
        end,
    },
    ["#ENDMASK"] = {
        ["expectedconversions"] = {
            --
            function(cut) return tobool(cut) end
        },
        --
        ["function"] = function(cut)
            --
            MaskUse(cut)
        end,
    },
    ["#ENDSTENCIL"] = {
        ["expectedconversions"] = {},
        --
        ["function"] = function()
            --
            render.SetStencilEnable(false)
        end,
    },
    ["SCISSORRECT"] = {
        ["expectedconversions"] = {
            --
            function(x) return ScrW() * tonumber(x) end,
            function(y) return ScrH() * tonumber(y) end,
            function(w) return ScrW() * tonumber(w) end,
            function(h) return ScrH() * tonumber(h) end,
            function(enabled) return tobool(enabled) end,
        },
        ["function"] = function(x, y, w, h, enabled)
            --
            render.SetScissorRect(x, y, w, h, enabled)
        end
    },
    ["OUTLINEDRECT"] = {
        ["expectedconversions"] = {
            --
            function(x) return ScrW() * tonumber(x) end,
            function(y) return ScrH() * tonumber(y) end,
            function(w) return ScrW() * tonumber(w) end,
            function(h) return ScrH() * tonumber(h) end,
            function(thickness) return ScrW() * tonumber(thickness) end,
        },
        ["function"] = function(x, y, w, h, thickness)
            --
            surface.DrawOutlinedRect(x, y, w, h, thickness)
        end,
    },
    ["OUTLINEDCIRCLE"] = {
        ["expectedconversions"] = {
            --
            function(x) return math.Round(ScrW() * tonumber(x)) end,
            function(y) return math.Round(ScrH() * tonumber(y)) end,
            function(radius) return math.Round(ScrH() * tonumber(radius)) * 2 end,
            function(thickness) return ScrW() * tonumber(thickness) end,
            function(flags) return tonumber(flags) end,
        },
        ["function"] = function(x, y, radius, thickness, flags)
            --
            RNDX.DrawCircleOutlined(x, y, radius, surface.GetDrawColor(), thickness, flags or 0)
        end,
        ["expectedargumentcount"] = 4,
    },
    ["SETNOTEXTURE"] = {
        ["expectedconversions"] = {}, --
        ["function"] = draw.NoTexture
    },
    ["LINE"] = {
        ["expectedconversions"] = {
            --
            function(startx) return ScrW() * tonumber(startx) end,
            function(starty) return ScrH() * tonumber(starty) end,
            function(endx) return ScrW() * tonumber(endx) end,
            function(endy) return ScrH() * tonumber(endy) end,
        },
        ["function"] = function(startx, starty, endx, endy)
            --
            surface.DrawLine(startx, starty, endx, endy)
        end,
    },
    ["TEXT"] = {
        ["expectedconversions"] = {
            --
            function(text) return string.Replace(text, "_", " ") end,
            function(font) return font end,
            function(x) return ScrW() * x end,
            function(y) return ScrH() * y end,
            function(xalign) return tonumber(xalign) end,
            function(yalign) return tonumber(yalign) end,
        },
        --
        ["function"] = function(text, font, x, y, xalign, yalign)
            --
            draw.SimpleText(text, font, x, y, surface.GetDrawColor(), xalign, yalign)
        end,
    },
    ["OVAL"] = {},
}

local CachedShapes = {}
local color_red = Color(255, 0, 0, 255)
local function CacheShapes()
    for shapetitle, tbl in pairs(ShapeTable) do
        CachedShapes[shapetitle] = {}
        for _, str in ipairs(tbl) do
            str = string.Trim(str)
            --[[
            if string.find(str, "#DEFINENAME") then
                --
                local split = string.Split(str, " ")
                shapetitle = split[2]
                continue
            end

            if not shapetitle then continue end
            --]]
            local firstcommentindex, _, _ = string.find(str, "//")
            if firstcommentindex then --
                str = utf8.sub(str, 1, firstcommentindex - 1)
            end

            if str == "" then -- caused by lines that are purely a comment 
                continue
            end

            str = string.Trim(str) -- trim again because comments
            local split = string.Split(str, " ")
            local ShapeType = split[1]
            table.remove(split, 1)
            local ShapeInfoTable = StringToDrawFunctionTable[ShapeType]
            if not ShapeInfoTable then
                MsgC("UNDEFINED SHAPE: " .. str .. "\n")
                continue
            end

            local args = split
            if #args < #ShapeInfoTable["expectedconversions"] and (ShapeInfoTable["expectedargumentcount"] and #args < ShapeInfoTable["expectedargumentcount"] or not ShapeInfoTable["expectedargumentcount"]) then
                -- make an error here
                MsgC(color_red, "Amount of args does not match expected amount of args for shape / function " .. str .. "\nExpected args: " .. (ShapeInfoTable["expectedargumentcount"] or #ShapeInfoTable["expectedconversions"]) .. "\nGiven: " .. #args .. "\n")
                continue
            elseif #args > #ShapeInfoTable["expectedconversions"] then
                MsgC(color_red, "Args overflow: " .. str .. "\nExpected args: " .. (ShapeInfoTable["expectedargumentcount"] or #ShapeInfoTable["expectedconversions"]) .. "\nGiven: " .. #args .. "\n")
                continue
            end

            for i = 1, #args do
                local arg = args[i]
                args[i] = ShapeInfoTable["expectedconversions"][i](arg)
            end

            local HighestIndex = table.insert(CachedShapes[shapetitle], {})
            CachedShapes[shapetitle][HighestIndex]["function"] = ShapeInfoTable["function"]
            CachedShapes[shapetitle][HighestIndex]["args"] = args
        end
    end
end

local DefaultCrosshairs = {
    ["1"] = [[//#DEFINENAME 1 // this line isnt used currently, ignore it
SETCOLOR 255 0 0 255
TEXT 'RECT_x_y_w_h' ChatFont 0.15 0.2 1 1
RECT 0.1 0.25 0.1 0.05
TEXT 'HOLLOWCIRCLE_centerx_center_y_radius' ChatFont 0.33 0.2 1 1
HOLLOWCIRCLE 0.33 0.275 0.05
TEXT 'ROTATEDTEXTUREDRECT_x_y_w_h_rotation' ChatFont 0.53 0.2 1 1
SETTEXTURE effects/tvscreen_noise002a
ROTATEDTEXTUREDRECT 0.53 0.27 0.15 0.07 10
TEXT 'ROUNDEDRECT_cornerradius_x_y_w_h_flags' ChatFont 0.73 0.2 1 1
ROUNDEDRECT 0.1 0.65 0.23 0.15 0.1
TEXT 'FILLEDCIRCLE_x_y_radius_flags' ChatFont 0.15 0.36 1 1
FILLEDCIRCLE 0.15 0.43 0.075
TEXT 'POLYGON_x_y_radius_numvertices' ChatFont 0.33 0.36 1 1
POLYGON 0.33 0.43 0.025 6
TEXT 'TEXT_font_x_y_xalign_yalign' ChatFont 0.53 0.36 1 1
TEXT words_MUST_be_separated_with_underscores ChatFont 0.53 0.43 1 1
TEXT 'LINE_startx_starty_endx_endy' ChatFont 0.73 0.36 1 1
LINE 0.65 0.43 0.83 0.46
TEXT 'OUTLINEDRECT_x_y_w_h_thickness' ChatFont 0.15 0.5 1 1
OUTLINEDRECT 0.09 0.54 0.12 0.10 0.01
TEXT 'OUTLINEDCIRCLE_x_y_radius_thickness_flags' ChatFont 0.33 0.5 1 1
OUTLINEDCIRCLE 0.33 0.58 0.05 0.007]],
    ["owcircle"] = [[SETCOLOR 0 255 255 255
OUTLINEDCIRCLE 0.5 0.5 0.004 0.0009]]
}

-- make this later
local function WriteCrosshairFiles()
    if not file.IsDir("ravens/customcrosshairs", "DATA") then --
        file.CreateDir("ravens/customcrosshairs")
    end

    for name, str in pairs(DefaultCrosshairs) do
        --
        local filepath = "ravens/customcrosshairs/" .. name .. ".txt"
        if file.Exists(filepath, "DATA") then continue end
        file.Write(filepath, str)
    end
end

local function ReadCrosshairFiles()
    local files, _ = file.Find("ravens/customcrosshairs/*.txt", "DATA")
    for _, filename in ipairs(files) do
        local filecontent = file.Read("ravens/customcrosshairs/" .. filename)
        ShapeTable[string.StripExtension(filename)] = string.Explode("\n", filecontent)
    end
end

WriteCrosshairFiles()
ReadCrosshairFiles()
CacheShapes()
--
CreateClientConVar("rv_custom_crosshairs_selected_crosshair", "0", true, false, "Which crosshair to use, 0 = disabled")
local SelectedCrosshair = GetConVar("rv_custom_crosshairs_selected_crosshair"):GetString()
local function DrawCustomCrosshair()
    if not CachedShapes[SelectedCrosshair] then return end
    if not LocalPlayer():Alive() then return end
    for _, ShapeFuncTable in ipairs(CachedShapes[SelectedCrosshair]) do
        -- this could be optimized further by passing a table and going arg by arg in the function itself, but dont care currently
        ShapeFuncTable["function"](unpack(ShapeFuncTable["args"]))
    end
end

if SelectedCrosshair ~= "0" then
    hook.Add("HUDPaint", "CustomCrosshairTest", DrawCustomCrosshair)
    hook.Add("HUDShouldDraw", "HideNormalCrosshair", function(name) if name == "CHudCrosshair" then return false end end)
end

cvars.AddChangeCallback("rv_custom_crosshairs_selected_crosshair", function(convar, old, new)
    SelectedCrosshair = new
    if SelectedCrosshair ~= "0" then
        hook.Add("HUDPaint", "CustomCrosshairTest", DrawCustomCrosshair)
        hook.Add("HUDShouldDraw", "HideNormalCrosshair", function(name) if name == "CHudCrosshair" then return false end end)
    else
        hook.Remove("HUDPaint", "CustomCrosshairTest")
        hook.Remove("HUDShouldDraw", "HideNormalCrosshair")
    end
end, "rv_custom_crosshairs_selected_crosshair")

local color_grey = Color(120, 120, 120)
local color_green = Color(0, 255, 0, 255)
local color_lightgreen = Color(0, 128, 0, 255)
local color_blackish = Color(40, 40, 40)
local color_dark = Color(15, 15, 15)
local color_magenta = Color(255, 0, 0)
CustomCrosshairPanel = CustomCrosshairPanel or nil
local function CrosshairGUI()
    if IsValid(CustomCrosshairPanel) then CustomCrosshairPanel:Remove() end
    CustomCrosshairPanel = vgui.Create("DFrame")
    CustomCrosshairPanel:SetSize(ScrW() * 0.3, ScrH() * 0.4)
    CustomCrosshairPanel:CenterVertical()
    CustomCrosshairPanel:SetX(ScrW() - CustomCrosshairPanel:GetWide())
    CustomCrosshairPanel:MakePopup()
    function CustomCrosshairPanel.OnRemove(_)
        hook.Remove("HUDPaint", "CustomCrosshairsDrawCenter")
    end

    function CustomCrosshairPanel.OnClose(self)
        self:Remove()
    end

    CustomCrosshairPanel:SetTitle("Custom crosshair setup")
    local TextPanel = vgui.Create("DTextEntry", CustomCrosshairPanel)
    TextPanel:Dock(LEFT)
    TextPanel:SetWide(CustomCrosshairPanel:GetWide() * 0.7)
    TextPanel:SetMultiline(true)
    TextPanel:SetText(table.concat(ShapeTable[SelectedCrosshair], "\n"))
    --[[
    function TextPanel.OnEntry(self, value)
    end
    --]]
    TextPanel:SetTextColor(color_green)
    TextPanel:SetCursorColor(color_white)
    function TextPanel.Paint(self, w, h)
        if self:HasFocus() then
            surface.SetDrawColor(color_dark)
        else
            surface.SetDrawColor(color_black)
        end

        surface.DrawRect(0, 0, w, h)
        self:DrawTextEntryText(self:GetTextColor(), self:GetHighlightColor(), self:GetCursorColor())
    end

    local Divider = vgui.Create("DPanel", CustomCrosshairPanel)
    Divider:Dock(LEFT)
    Divider:SetWide(ScrW() * 0.002)
    Divider:SetBackgroundColor(color_grey)
    local ButtonsPanel = vgui.Create("DPanel", CustomCrosshairPanel)
    ButtonsPanel:Dock(FILL)
    ButtonsPanel:SetBackgroundColor(color_black)
    local RefreshButtonsPanel = vgui.Create("DPanel", ButtonsPanel)
    RefreshButtonsPanel:Dock(TOP)
    RefreshButtonsPanel:SetBackgroundColor(color_blackish)
    local RefreshHUDButton = vgui.Create("DImageButton", RefreshButtonsPanel)
    RefreshHUDButton:SetImage("icon16/arrow_refresh.png")
    RefreshHUDButton:SetSize(RefreshButtonsPanel:GetTall(), RefreshButtonsPanel:GetTall())
    function RefreshHUDButton.DoClick()
        ShapeTable[SelectedCrosshair] = string.Explode("\n", TextPanel:GetText())
        CacheShapes()
    end

    local LabelMargin = ScrW() * 0.005
    local RefreshHUDLabel = vgui.Create("DLabel", RefreshButtonsPanel)
    RefreshHUDLabel:SetTextColor(color_green)
    RefreshHUDLabel:SetX(RefreshHUDButton:GetX() + RefreshHUDButton:GetWide() + LabelMargin)
    RefreshHUDLabel:SetText("Refresh HUD")
    local SelectedCrosshairPanel = vgui.Create("DComboBox", ButtonsPanel)
    SelectedCrosshairPanel:Dock(TOP)
    --SelectedCrosshairPanel:SetBackgroundColor(color_blackish) -- make it do this later
    local function AddSelectedCrosshairOptions()
        SelectedCrosshairPanel:Clear()
        for crosshairname, _ in pairs(ShapeTable) do
            SelectedCrosshairPanel:AddChoice(crosshairname)
        end

        SelectedCrosshairPanel:SetValue("Selected crosshair: " .. SelectedCrosshair)
    end

    function SelectedCrosshairPanel.OnSelect(self, _, value, _)
        RunConsoleCommand("rv_custom_crosshairs_selected_crosshair", value)
        self:SetValue("Selected crosshair: " .. value)
        SelectedCrosshair = value
        TextPanel:SetText(table.concat(ShapeTable[value], "\n"))
    end

    AddSelectedCrosshairOptions()
    local WriteToFilePanel = vgui.Create("DPanel", ButtonsPanel)
    WriteToFilePanel:Dock(TOP)
    WriteToFilePanel:SetBackgroundColor(color_blackish)
    local DockMargin = ScrH() * 0.00463
    WriteToFilePanel:DockMargin(0, DockMargin, 0, 0)
    local WriteToFileText = vgui.Create("DTextEntry", WriteToFilePanel)
    WriteToFileText:Dock(FILL)
    WriteToFileText:DockMargin(DockMargin * 0.75, DockMargin * 0.75, DockMargin * 0.75, DockMargin * 0.75)
    WriteToFileText:SetPlaceholderText("Write to file " .. SelectedCrosshair .. ".txt" .. " (enter)")
    WriteToFileText:SetTextColor(color_green)
    WriteToFileText:SetCursorColor(color_white)
    WriteToFileText:SetPlaceholderColor(color_lightgreen)
    function WriteToFileText.Paint(self, w, h)
        if self:HasFocus() then
            surface.SetDrawColor(color_dark)
        else
            surface.SetDrawColor(color_black)
        end

        surface.DrawRect(0, 0, w, h)
        if self:GetText() == "" and not self:HasFocus() then
            draw.SimpleText(self:GetPlaceholderText(), self:GetFont(), 0, h * 0.5, self:GetPlaceholderColor(), 0, TEXT_ALIGN_CENTER)
            return
        end

        self:DrawTextEntryText(self:GetTextColor(), self:GetHighlightColor(), self:GetCursorColor())
    end

    function WriteToFileText.OnGetFocus(self)
        self:SetText(SelectedCrosshair .. ".txt")
    end

    function WriteToFileText.OnEnter(self, value)
        --value  = string.trim
        local TextPanelText = TextPanel:GetText()
        file.Write("ravens/customcrosshairs/" .. value, TextPanelText)
        ReadCrosshairFiles()
        AddSelectedCrosshairOptions()
        CacheShapes()
        RunConsoleCommand("rv_custom_crosshairs_selected_crosshair", string.StripExtension(value))
    end

    local RefreshFilesButtonsPanel = vgui.Create("DPanel", ButtonsPanel)
    RefreshFilesButtonsPanel:Dock(TOP)
    RefreshFilesButtonsPanel:SetBackgroundColor(color_blackish)
    RefreshFilesButtonsPanel:DockMargin(0, DockMargin, 0, 0)
    local RefreshFilesButton = vgui.Create("DImageButton", RefreshFilesButtonsPanel)
    RefreshFilesButton:SetImage("icon16/arrow_refresh.png")
    RefreshFilesButton:SetSize(RefreshFilesButtonsPanel:GetTall(), RefreshFilesButtonsPanel:GetTall())
    function RefreshFilesButton.DoClick()
        ReadCrosshairFiles()
        AddSelectedCrosshairOptions()
        CacheShapes()
    end

    local RefreshFilesLabel = vgui.Create("DLabel", RefreshFilesButtonsPanel)
    RefreshFilesLabel:SetTextColor(color_green)
    RefreshFilesLabel:SetX(RefreshFilesButton:GetX() + RefreshFilesButton:GetWide() + LabelMargin)
    RefreshFilesLabel:SetText("Refresh files")
    local DrawCenterPanel = vgui.Create("DPanel", ButtonsPanel)
    DrawCenterPanel:Dock(TOP)
    DrawCenterPanel:SetBackgroundColor(color_blackish)
    DrawCenterPanel:DockMargin(0, DockMargin, 0, 0)
    local DrawCenterCheckbox = vgui.Create("DCheckBox", DrawCenterPanel)
    DrawCenterCheckbox:SetSize(DrawCenterPanel:GetTall(), DrawCenterPanel:GetTall())
    function DrawCenterCheckbox.OnChange(self, bVal)
        if bVal == true then
            hook.Add("HUDPaint", "CustomCrosshairsDrawCenter", function()
                surface.SetDrawColor(color_magenta)
                surface.DrawRect(ScrW() * 0.5 - 1, 0, 2, ScrH())
                surface.DrawRect(0, ScrH() * 0.5 - 1, ScrW(), 2)
            end)
        else
            hook.Remove("HUDPaint", "CustomCrosshairsDrawCenter")
        end
    end

    DrawCenterCheckbox:SetValue(true)
    DrawCenterLabel = vgui.Create("DLabel", DrawCenterPanel)
    DrawCenterLabel:SetTextColor(color_green)
    DrawCenterLabel:SetX(DrawCenterCheckbox:GetX() + DrawCenterCheckbox:GetWide() + LabelMargin)
    DrawCenterLabel:SetText("Show center")
end

concommand.Add("rv_custom_crosshairs_menu", function()
    CrosshairGUI()
    return
end)
