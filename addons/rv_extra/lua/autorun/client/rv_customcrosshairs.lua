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
            function(radius) return ScrH() * tonumber(radius) end,
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
            function(x) return ScrW() * tonumber(x) end,
            function(y) return ScrH() * tonumber(y) end,
            function(radius) return ScrW() * tonumber(radius) end,
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
            SetMaskToggle(true)
        end,
    },
    ["#MASKSTART"] = {
        ["expectedconversions"] = {},
        --
        ["function"] = function()
            --
            StartMask()
        end,
    },
    ["#MASKEND"] = {
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
            function(x) return ScrW() * tonumber(x) end,
            function(y) return ScrH() * tonumber(y) end,
            function(radius) return ScrH() * tonumber(radius) end,
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
        for _, str in ipairs(tbl) do
            if string.find(str, "#DEFINENAME") then
                --
                local split = string.Split(str, " ")
                shapetitle = split[2]
                CachedShapes[shapetitle] = {}
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

    PrintTable(CachedShapes)
end

local DefaultCrosshairs = {
    ["1"] = [[//#DEFINENAME 1 // this line isnt used currently, ignore it
SETCOLOR 255 0 0 255
TEXT 'RECT_x_y_w_h' ChatFont 0.15 0.2 1 1
RECT 0.10 0.25 0.1 0.05
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
OUTLINEDCIRCLE 0.33 0.58 0.1 0.007]],
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
CreateClientConVar("rv_custom_crosshairs_selected_crosshair", "0", true, false, "Which crosshair to use, 0 = disabled")
local SelectedCrosshair = GetConVar("rv_custom_crosshairs_selected_crosshair"):GetString()
cvars.AddChangeCallback("rv_custom_crosshairs_selected_crosshair", function(convar, old, new)
    --
    SelectedCrosshair = new
end, "rv_custom_crosshairs_selected_crosshair")

hook.Add("HUDPaint", "CustomCrosshairTest", function()
    if SelectedCrosshair == "0" then return end
    if not CachedShapes[SelectedCrosshair] then return end
    for _, ShapeFuncTable in ipairs(CachedShapes[SelectedCrosshair]) do
        -- this could be optimized further by passing a table and going arg by arg in the function itself, but dont care currently
        ShapeFuncTable["function"](unpack(ShapeFuncTable["args"]))
        --StringToDrawFunction(ShapeString)
    end
    --surface.DrawRect(0.1 * ScrW(), 0.1  * ScrH(), 0.5 * ScrW(), 0.5 * ScrW())
    return
end)
