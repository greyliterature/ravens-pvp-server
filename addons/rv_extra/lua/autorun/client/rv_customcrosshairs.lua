local ShapeTable = {
    -- this should be a full STRING, not a table. it will be defined in a txt file.
    "SETCOLOR 255 0 0",
    "RECT 0.375 0.375 0.25 0.25", -- make this a convar where its "use resolution percentages"
    "HOLLOWCIRCLE 0.54 0.5 0.1 255 0 255"
}

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
            surface.DrawCircle(centerX, centerY, radius, R, G, B, A)
        end
    },
    ["ROTATEDRECT"] = {}
}

local function StringToDrawFunction(str)
    local split = string.Split(str, " ")
    local ShapeType = split[1]
    table.remove(split, 1)
    local ShapeInfoTable = StringToDrawFunctionTable[ShapeType]
    local args = split
    for i = 1, #args do
        local arg = args[i]
        args[i] = ShapeInfoTable["expectedconversions"][i](arg)
    end

    ShapeInfoTable["function"](unpack(args))
end

hook.Add("HUDPaint", "CustomCrosshairTest", function()
    for _, ShapeString in ipairs(ShapeTable) do
        StringToDrawFunction(ShapeString)
    end
    --surface.DrawRect(0.1 * ScrW(), 0.1  * ScrH(), 0.5 * ScrW(), 0.5 * ScrW())
    return
end)
