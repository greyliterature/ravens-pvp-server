local rv_gm = include("../gm_universal/gm_universal.lua")
local debugging = true
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

local Gradient_up = Material("vgui/gradient_up")
local Gradient_down = Material("vgui/gradient_down")
hook.Add("HUDPaint", "CTFUI", function()
    local TimeLeft = GetGlobal3("MatchTimeLimit") - CurTime()
    local time = string.FormattedTime(TimeLeft, "%02i:%02i")
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
