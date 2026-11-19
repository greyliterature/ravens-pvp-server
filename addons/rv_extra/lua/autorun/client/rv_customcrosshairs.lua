local ShapeTable = {
    -- this should be a full STRING, not a table. it will be defined in a txt file.
    "#DEFINENAME 1",
    "//#USERESOLUTIONASCOORDINATES 1",
    "#MASKSTART",
    "FILLEDCIRCLE 0.5 0.5 0.2 0",
    "#MASKEND true",
    "SETCOLOR 255 0 0 255",
    "RECT 0.375 0.375 0.25 0.25", -- make this a convar where its "use resolution percentages"
    "HOLLOWCIRCLE 0.54 0.5 0.1 255 0 255 // EXAMPLE COMMENT",
    "SETTEXTURE decals/smile",
    "SETCOLOR 55 0 0 255",
    "ROTATEDRECT 0.375 0.375 0.25 0.25 0",
    "SETCOLOR 0 255 0 255",
    "RECT 0 0 0.2 0.2",
    "SETCOLOR 55 0 0 255",
    "SCISSORRECT 0.05 0.05 0.15 0.15 true",
    "RECT 0 0 0.2 0.2",
    "SCISSORRECT 0 0 0 0 false",
    "SETCOLOR 125 125 0",
    "SETNOTEXTURE",
    "POLYGON 0.5 0.5 0.1 10",
    "//CREATEMATERIAL",
    "SETCOLOR 0 0 255 255",
    "ROUNDEDRECT 0.1 0.1 0.1 0.1 0.1",
    "IGNORETHIS, DEBUG TEST || THISLINESHOULDNEVERERROR",
    "#ENDSTENCIL",
}

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
    ["HOLLOWCIRCLE"] = {
        ["expectedconversions"] = {
            --
            function(centerX) return ScrW() * tonumber(centerX) end,
            function(centerY) return ScrH() * tonumber(centerY) end,
            function(radius) return ScrH() * tonumber(radius) end,
            function(R) return tonumber(R) end,
            function(G) return tonumber(G) end,
            function(B) return tonumber(B) end,
            function(A) return tonumber(A) end,
        },
        ["function"] = function(centerX, centerY, radius, R, G, B, A)
            --
            surface.DrawCircle(centerX, centerY, radius, R, G, B, A or 255)
        end,
        ["expectedargumentcount"] = 6
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
    ["ROTATEDRECT"] = {
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
            function(x) return ScrW() * x end,
            function(y) return ScrH() * y end,
            function(w) return ScrW() * w end,
            function(h) return ScrH() * h end,
            function(enabled) return tobool(enabled) end,
        },
        ["function"] = function(x, y, w, h, enabled)
            --
            render.SetScissorRect(x, y, w, h, enabled)
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
                RNDX.Draw(radius, x, y, w, h, nil, flags or 0)
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
            function(thickness) return ScrH() * tonumber(thickness) end,
            function(flags) return tonumber(flags) end,
        },
        ["function"] = function(x, y, radius, thickness, flags)
            --
            RNDX.DrawCircle(x, y, radius, nil, thickness, flags or 0)
        end,
        ["expectedargumentcount"] = 4
    },
    ["OUTLINEDRECT"] = {},
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
    ["SETNOTEXTURE"] = {
        ["expectedconversions"] = {}, --
        ["function"] = draw.NoTexture
    },
    ["OVAL"] = {},
}

local CachedShapes = {}
local color_red = Color(255, 0, 0, 255)
local function CacheShapes()
    for _, str in ipairs(ShapeTable) do
        if string.find(str, "#DEFINENAME") then
            -- encoder, handle it properly later
            -- probably put it in a table defined by the name
            continue
        end

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

        print(str)
        for i = 1, #args do
            local arg = args[i]
            args[i] = ShapeInfoTable["expectedconversions"][i](arg)
        end

        local HighestIndex = table.insert(CachedShapes, {})
        CachedShapes[HighestIndex]["function"] = ShapeInfoTable["function"]
        CachedShapes[HighestIndex]["args"] = args
    end
end

CacheShapes()
hook.Add("HUDPaint", "CustomCrosshairTest", function()
    for _, ShapeFuncTable in ipairs(CachedShapes) do
        ShapeFuncTable["function"](unpack(ShapeFuncTable["args"])) -- this could be optimized further by passing a table and going arg by arg in the function itself, but dont care currently
        --StringToDrawFunction(ShapeString)
    end
    --surface.DrawRect(0.1 * ScrW(), 0.1  * ScrH(), 0.5 * ScrW(), 0.5 * ScrW())
    return
end)
