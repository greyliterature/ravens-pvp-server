local rv_gm = include("customgamemodes/client/gm_universal/gm_universal.lua")
--[[------------------------------
    Init
--------------------------------]]
local debugging = true
rv_gm.SetPlayerOutlineFlip(true)
rv_gm.RemoveConflictingHooks()
--[[------------------------------
    Rest
--------------------------------]]
if debugging ~= true then rv_gm.OpenJoinTeamPopup() end
local TEAM_RED, TEAM_BLUE = 1, 2
surface.CreateFont("Bahnschrift", {
    font = "Bahnschrift Light",
    extended = false,
    size = ScrW() / 85.8461538,
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

surface.CreateFont("Roboto Light", {
    font = "Roboto Lt",
    extended = false,
    size = ScrW() / 75.8461538,
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

local Colors = {
    HaloDarkBlue = Color(41, 62, 78),
    HaloLightBlue = Color(39, 72, 127),
    HaloLightLightBlue = Color(116, 184, 197),
    HaloScoreBlue = Color(0, 154, 204),
    HaloDarkRed = Color(92, 14, 15),
    HaloLightRed = Color(155, 24, 29),
    HaloLightLightRed = Color(228, 79, 73),
    HaloLightScoreRed = Color(255, 49, 50)
}

function draw.Circle(x, y, radius, seg) -- from https://wiki.facepunch.com/gmod/surface.DrawPoly#example
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

-- claude flag code thing
local FlagPolys = {
    {
        {
            x = 94,
            y = 18
        },
        {
            x = 101,
            y = 20
        },
        {
            x = 105,
            y = 24
        },
        {
            x = 100,
            y = 34
        },
        {
            x = 24,
            y = 18
        }
    },
    {
        {
            x = 24,
            y = 18
        },
        {
            x = 100,
            y = 34
        },
        {
            x = 103,
            y = 39
        }
    },
    {
        {
            x = 114,
            y = 39
        },
        {
            x = 135,
            y = 32
        },
        {
            x = 165,
            y = 66
        }
    },
    {
        {
            x = 103,
            y = 39
        },
        {
            x = 114,
            y = 39
        },
        {
            x = 165,
            y = 66
        }
    },
    {
        {
            x = 24,
            y = 18
        },
        {
            x = 103,
            y = 39
        },
        {
            x = 165,
            y = 66
        },
        {
            x = 125,
            y = 81
        },
        {
            x = 89,
            y = 73
        },
        {
            x = 82,
            y = 70
        },
        {
            x = 37,
            y = 30
        }
    },
    {
        {
            x = 125,
            y = 81
        },
        {
            x = 102,
            y = 87
        },
        {
            x = 87,
            y = 86
        },
        {
            x = 89,
            y = 73
        }
    },
    {
        {
            x = 65,
            y = 73
        },
        {
            x = 52,
            y = 79
        },
        {
            x = 50,
            y = 59
        }
    },
    {
        {
            x = 82,
            y = 70
        },
        {
            x = 65,
            y = 73
        },
        {
            x = 50,
            y = 59
        },
        {
            x = 44,
            y = 41
        }
    },
    {
        {
            x = 82,
            y = 70
        },
        {
            x = 44,
            y = 41
        },
        {
            x = 37,
            y = 30
        }
    },
    {
        {
            x = 9,
            y = 4
        },
        {
            x = 17,
            y = 6
        },
        {
            x = 16,
            y = 14
        }
    },
    {
        {
            x = 9,
            y = 4
        },
        {
            x = 16,
            y = 14
        },
        {
            x = 75,
            y = 140
        },
        {
            x = 66,
            y = 145
        },
        {
            x = 13,
            y = 19
        }
    },
    {
        {
            x = 13,
            y = 19
        },
        {
            x = 6,
            y = 10
        },
        {
            x = 9,
            y = 4
        }
    },
}

local FLAG_W, FLAG_H = 168, 148
local cache, cacheScale
function DrawFlag(x, y, scale, col)
    scale = scale or 1
    if cacheScale ~= scale then
        cache = {}
        for i, poly in ipairs(FlagPolys) do
            cache[i] = {}
            for j, v in ipairs(poly) do
                cache[i][j] = {
                    x = v.x * scale,
                    y = v.y * scale
                }
            end
        end

        cacheScale = scale
    end

    -- top-left corner so the icon is centered on x, y
    local ox = x - FLAG_W * scale * 0.5
    local oy = y - FLAG_H * scale * 0.5
    surface.SetDrawColor(col or Color(170, 190, 230))
    draw.NoTexture()
    for _, poly in ipairs(cache) do
        local moved = {}
        for j, v in ipairs(poly) do
            moved[j] = {
                x = v.x + ox,
                y = v.y + oy
            }
        end

        surface.DrawPoly(moved)
    end
end

--
local function GetTeamFlag(teamindex)
    for _, ent in ipairs(rv_gm.GetAllCTFFlags()) do
        if not IsValid(ent) then continue end
        if ent.TeamIndex == teamindex then return ent end
    end
end

local function GetTeamFlagBase(teamindex)
    for _, ent in ipairs(rv_gm.GetAllCTFFlagBases()) do
        if not IsValid(ent) then continue end
        if ent.TeamIndex == teamindex then return ent end
    end
end

local FlagHeightOffset = Vector(0, 0, 50)
local FlagYOffset = ScrH() * 0.04
local FlagScale = 0.15
local FlagBaseHeightOffset = Vector(0, 0, 5)
local color_kindawhite = Color(250, 250, 250, 128)
--
local FlagBlue = ColorAlpha(Colors.HaloLightLightBlue, 255)
local FlagBlueAlphad = ColorAlpha(Colors.HaloDarkBlue, 128)
local FlagRed = ColorAlpha(Colors.HaloLightLightRed, 255)
local FlagRedAlphad = ColorAlpha(Colors.HaloDarkRed, 128)
local DeliverGrey = Color(230, 230, 230, 128)
local Vignette = Material("vgui/white_additive_vignette")
AddGamemodeHook("HUDPaint", "DrawFlags", function()
    local myteam = LocalPlayer():Team()
    local MyTeamFlag = GetTeamFlag(myteam)
    local TheirTeamFlagBase = GetTeamFlagBase((myteam == TEAM_RED and TEAM_BLUE) or TEAM_RED)
    local MyTeamFlagBase = GetTeamFlagBase(myteam)
    if not MyTeamFlag or not MyTeamFlagBase then -- no need to check the other, if one doesnt exist neither do
        return
    end

    if MyTeamFlagBase.Text == "DELIVER" then
        local HeightOffset = FlagBaseHeightOffset
        local data = (MyTeamFlagBase:GetPos() + HeightOffset):ToScreen()
        surface.SetDrawColor((myteam == TEAM_BLUE and FlagBlue) or FlagRed)
        surface.SetMaterial(Vignette)
        surface.DrawTexturedRectRotated(data.x, data.y, FLAG_H * FlagScale * 1.7, FLAG_H * FlagScale * 1.7, 45)
        surface.SetDrawColor((myteam == TEAM_BLUE and FlagBlueAlphad) or FlagRedAlphad)
        draw.NoTexture()
        surface.DrawTexturedRectRotated(data.x, data.y, FLAG_H * FlagScale * 1.7, FLAG_H * FlagScale * 1.7, 45)
        draw.SimpleText(TheirTeamFlagBase.Text or "DELIVER", "Roboto Light", data.x, data.y - FlagYOffset, color_white, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(DeliverGrey)
        surface.DrawTexturedRectRotated(data.x, data.y, FLAG_H * FlagScale * 0.55, FLAG_H * FlagScale * 0.55, 45)
    end

    local TheirTeamFlag = GetTeamFlag((myteam == TEAM_RED and TEAM_BLUE) or TEAM_RED)
    if TheirTeamFlag then
        local HeightOffset = FlagHeightOffset
        local data = (TheirTeamFlag:GetPos() + HeightOffset):ToScreen()
        surface.SetDrawColor((myteam == TEAM_BLUE and FlagRed) or FlagBlue)
        surface.SetMaterial(Vignette)
        surface.DrawTexturedRectRotated(data.x, data.y, FLAG_H * FlagScale * 1.7, FLAG_H * FlagScale * 1.7, 45)
        surface.SetDrawColor((myteam == TEAM_BLUE and FlagRedAlphad) or FlagBlueAlphad)
        draw.SimpleText(TheirTeamFlag.Text or "CAPTURE", "Roboto Light", data.x, data.y - FlagYOffset, color_white, TEXT_ALIGN_CENTER)
        render.SetStencilEnable(true)
        render.ClearStencil()
        render.SetStencilTestMask(255)
        render.SetStencilWriteMask(255)
        render.SetStencilPassOperation(STENCILOPERATION_KEEP)
        render.SetStencilZFailOperation(STENCILOPERATION_KEEP)
        render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_NEVER)
        render.SetStencilReferenceValue(9)
        render.SetStencilFailOperation(STENCILOPERATION_REPLACE)
        draw.NoTexture()
        surface.DrawTexturedRectRotated(data.x, data.y, FLAG_H * FlagScale * 1.7, FLAG_H * FlagScale * 1.7, 45)
        render.SetStencilFailOperation(STENCILOPERATION_KEEP)
        render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
        if TheirTeamFlag.Text == "RETURNING" and draw.DrawArc then --
            surface.SetDrawColor(color_kindawhite)
            local ratio = (CurTime() - TheirTeamFlag.StartReturningTime) / GetGlobal3("FlagReturnDelay", 5)
            ratio = ratio * 360
            draw.DrawArc(data.x, data.y, FLAG_H * FlagScale * 1.1, 0, ratio)
        end

        render.SetStencilEnable(false)
        DrawFlag(data.x, data.y, 0.15, color_white)
    end

    if MyTeamFlagBase.Text ~= "DELIVER" or not MyTeamFlag.AtBase then
        if (MyTeamFlag.Text == "KILL" or MyTeamFlag.Text == "RETURNING") and not MyTeamFlag.Revealed then return end
        local HeightOffset = FlagHeightOffset
        local data = (MyTeamFlag:GetPos() + HeightOffset):ToScreen()
        draw.SimpleText(MyTeamFlag.Text or "DEFEND", "Roboto Light", data.x, data.y - FlagYOffset, color_white, TEXT_ALIGN_CENTER)
        surface.SetDrawColor((myteam == TEAM_BLUE and FlagBlue) or FlagRed)
        surface.SetMaterial(Vignette)
        draw.Circle(data.x, data.y, FLAG_H * FlagScale, 20)
        surface.SetDrawColor((myteam == TEAM_BLUE and FlagBlueAlphad) or FlagRedAlphad)
        draw.NoTexture()
        draw.Circle(data.x, data.y, FLAG_H * FlagScale, 20)
        DrawFlag(data.x, data.y, FlagScale, color_white)
        if MyTeamFlag.Text == "RETURNING" and draw.DrawArc then --
            surface.SetDrawColor(color_kindawhite)
            local ratio = (CurTime() - MyTeamFlag.StartReturningTime) / GetGlobal3("FlagReturnDelay", 5)
            ratio = ratio * 360
            draw.DrawArc(data.x, data.y, FLAG_H * FlagScale * 1.1, 0, ratio)
        end
    end
end)

hook.Add("rv_gm.PlayerPickedUpCTFEntity", "ChangeTextOnPickup", function(pickingupply, ent, pickedup)
    if pickingupply:Team() == ent.TeamIndex then --
        ent.AtBase = true
    end

    local myflag = GetTeamFlag(LocalPlayer():Team())
    local theirflag = GetTeamFlag((LocalPlayer():Team() == TEAM_RED and TEAM_BLUE) or TEAM_RED)
    local myflagbase = GetTeamFlagBase(LocalPlayer():Team())
    if ent == myflag then -- is it my flag
        if pickedup == true then
            if pickingupply:Team() == LocalPlayer():Team() then --
                ent.Text = "DEFEND"
            elseif pickingupply:Team() ~= LocalPlayer():Team() then
                ent.Text = "KILL"
            end
        elseif pickedup == false and not ent.AtBase then
            ent.Text = "RETURNING"
            ent.StartReturningTime = CurTime()
        end
    elseif ent == theirflag then
        -- is it their flag 
        if pickingupply == LocalPlayer() and pickedup == true then
            myflagbase.Text = "DELIVER"
        elseif pickingupply == LocalPlayer() and pickedup == false then
            if myflag.AtBase == true then --
                myflag.Text = "DEFEND"
                myflagbase.Text = ""
            end

            ent.Text = "RETURNING"
            ent.StartReturningTime = CurTime()
        elseif pickedup == true then
            if pickingupply:Team() == LocalPlayer():Team() then --
                ent.Text = "ESCORT"
            end
        elseif pickedup == false then
            ent.Text = "RETURNING"
            ent.StartReturningTime = CurTime()
        end
    end
end)

hook.Add("rv_gm.FlagRevealed", "SetFlagRevealed", function(ply, ent, revealed)
    if revealed == false then
        ent.Revealed = nil
        return
    end

    ent.Revealed = revealed
end)

AddGamemodeHook("rv_gm.FlagRTBed", "GetFlagRTB", function(ent)
    local myflag = GetTeamFlag(LocalPlayer():Team())
    local myflagbase = GetTeamFlagBase(LocalPlayer():Team())
    if ent ~= myflag then -- if its not myflag its theirflag
        myflagbase.Text = nil
        ent.Text = nil
    end

    if ent == myflag then -- if myflag was rtbed, we don't need RETURN or KILL to be shown anymore
        ent.Text = nil
    end

    ent.Revealed = nil
    ent.AtBase = true
end)

local Gradient_up = Material("vgui/gradient_up")
local Gradient_down = Material("vgui/gradient_down")
AddGamemodeHook("HUDPaint", "CTFUI", function()
    local TimeLeft = GetGlobal3("MatchTimeLimit", 0) - CurTime()
    local time = (rv_gm.IsMatchInProgress() == true and string.FormattedTime(TimeLeft, "%02i:%02i")) or "WARM-UP"
    draw.SimpleText(time, "ChatFont", ScrW() * 0.5, ScrH() * 0.9, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    --
    local RectWidth = ScrW() * 0.1
    local RectHeight = ScrH() * 0.020
    local RectX = ScrW() * 0.03
    local RectY = ScrH() * 0.9
    local CenterX = ScrW() * 0.5
    local MiniRectHeightPercentage = 0.35
    for i = 1, -1, -2 do
        -- Blue team
        surface.SetDrawColor((i == 1 and Colors.HaloLightBlue) or Colors.HaloLightRed)
        surface.DrawRect(CenterX - RectX * i - RectWidth * ((i == 1 and 1) or 0), RectY - RectHeight * 0.5, RectWidth, RectHeight * 1)
        surface.SetDrawColor((i == 1 and Colors.HaloScoreBlue) or Colors.HaloLightScoreRed)
        local teamscore = (i == 1 and team.GetScore(TEAM_BLUE)) or team.GetScore(TEAM_RED)
        if i == -1 then
            surface.DrawRect(CenterX - RectX * i - RectWidth * ((i == 1 and 1) or 0), RectY - RectHeight * 0.5, RectWidth * (teamscore / rv_gm.GetScoreLimit()), RectHeight * 1)
        else
            surface.DrawRect(CenterX - RectX * i - RectWidth * (teamscore / rv_gm.GetScoreLimit()), RectY - RectHeight * 0.5, RectWidth * (teamscore / rv_gm.GetScoreLimit()), RectHeight * 1)
        end

        surface.SetDrawColor((i == 1 and Colors.HaloDarkBlue) or Colors.HaloDarkRed)
        surface.SetMaterial(Gradient_down)
        surface.DrawTexturedRect(CenterX - RectX * i - RectWidth * ((i == 1 and 1) or 0), RectY - RectHeight * MiniRectHeightPercentage, RectWidth, RectHeight * MiniRectHeightPercentage)
        surface.SetMaterial(Gradient_up)
        surface.DrawTexturedRect(CenterX - RectX * i - RectWidth * ((i == 1 and 1) or 0), RectY, RectWidth, RectHeight * MiniRectHeightPercentage)
        -- left rect
        local LeftRectWidth = ScrW() * 0.0019
        surface.SetDrawColor((i == 1 and Colors.HaloLightLightBlue) or Colors.HaloLightLightRed)
        surface.DrawRect(CenterX - (RectX * i), RectY - RectHeight * 0.5, LeftRectWidth, RectHeight)
        -- Right rect
        local RightRectWidth = ScrW() * 0.0015
        --surface.SetDrawColor((i == 1 and Colors.HaloLightLightBlue) or Colors.HaloLightLightRed)
        surface.DrawRect(CenterX - RectX * i - RectWidth * i, RectY - RectHeight * 0.5, RightRectWidth, RectHeight)
        local TextOffset = ScrW() * 0.007
        local TextHeightOffset = ScrH() * 0.001 -- because it doesnt align this small font in the center properly for some reason
        draw.SimpleText(teamscore, "Bahnschrift", CenterX - RectX * i - TextOffset * i, RectY - TextHeightOffset, color_white, (i == 1 and TEXT_ALIGN_RIGHT) or TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
end)
