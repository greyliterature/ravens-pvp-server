--[[------------------------------
    init 
--------------------------------]]
local _ = include("customgamemodes/client/gm_universal/gm_universal.lua")
TEAM_RED = 1
TEAM_BLUE = 2
--[[------------------------------
    ScoreHud
--------------------------------]]
local JoinTeamMenuColors = {
    Background = Color(50, 50, 50, 254),
    Header = Color(100, 100, 100, 255),
    WeaponIconConVarred = Color(240, 240, 178, 255),
    WeaponIconHovered = Color(240, 240, 240, 255),
    WeaponInfoBackground = Color(72, 72, 72, 255),
    WeaponInfoHeader = Color(239, 239, 239, 255),
    WeaponInfoText = Color(186, 186, 186, 255),
    HoveredGold = Color(252, 192, 80),
    JoinMatchWhite = Color(251, 215, 205),
    LightRed = Color(255, 35, 12),
    Red = Color(83, 33, 34),
    DarkRed = Color(84, 32, 32),
    Blue = Color(30, 30, 85),
    DarkBlue = Color(32, 32, 84),
    SpectateGrey = Color(31, 31, 31),
}

local RNDX = include("autorun/rndx.lua")
local color_transparentishblack = Color(15, 15, 15, 200)
local color_yellow = Color(255, 177, 0, 255) -- same as scoreboard
local color_myteam_red_bigrect = JoinTeamMenuColors.LightRed:Copy()
local color_myteam_blue_bigrect = JoinTeamMenuColors.DarkBlue:Copy()
color_myteam_red_bigrect:AddBrightness(0.1)
color_myteam_blue_bigrect:AddBrightness(0.1)
color_myteam_red_bigrect.a = 200
color_myteam_blue_bigrect.a = 200
local color_myteam_red_livecountrect = JoinTeamMenuColors.LightRed:Copy()
local color_myteam_blue_livecountrect = JoinTeamMenuColors.DarkBlue:Copy()
color_myteam_red_livecountrect.a = 240
color_myteam_blue_livecountrect.a = 240
local Teams = {TEAM_RED, TEAM_BLUE}
AddGamemodeHook("HUDPaint", "ScoreHud", function()
    if GetGlobal3("MatchInProgress", false) == false then return end
    local MarginFromScreenEdge = ScrW() * 0.01
    local RectWidth = ScrW() * 0.15
    local RectHeight = ScrH() * 0.06
    local OutlineThickness = 1
    local FigmaRadii = 10
    if RNDX then
        RNDX.DrawOutlined(FigmaRadii, 0 + MarginFromScreenEdge - OutlineThickness, 0 + MarginFromScreenEdge - OutlineThickness, RectWidth + OutlineThickness * 2, RectHeight + OutlineThickness * 2, color_yellow, OutlineThickness)
        RNDX.Draw(FigmaRadii, 0 + MarginFromScreenEdge, 0 + MarginFromScreenEdge, RectWidth, RectHeight, color_transparentishblack)
    else
        surface.SetDrawColor(color_yellow)
        surface.DrawOutlinedRect(0 + MarginFromScreenEdge - OutlineThickness, 0 + MarginFromScreenEdge - OutlineThickness, RectWidth + OutlineThickness * 2, RectHeight + OutlineThickness * 2, OutlineThickness)
        surface.SetDrawColor(color_transparentishblack)
        surface.DrawRect(0 + MarginFromScreenEdge, 0 + MarginFromScreenEdge, RectWidth, RectHeight)
    end

    for i = 1, #Teams do
        local LiveCount = 0
        for _, ply in ipairs(team.GetPlayers(Teams[i])) do
            if ply:Alive() == true then --
                LiveCount = LiveCount + 1
            end
        end

        local TeamCardRadii = 8
        local PlayerTeam = LocalPlayer():Team()
        if RNDX then
            if Teams[i] == PlayerTeam then
                local MarginFromRectEdge = ScrW() * 0.002
                local col = (Teams[i] == TEAM_RED and color_myteam_red_bigrect) or color_myteam_blue_bigrect
                RNDX.Draw(TeamCardRadii, 0 + MarginFromScreenEdge + MarginFromRectEdge, 0 + MarginFromScreenEdge + RectHeight * 0.5 * (i - 1), RectWidth - MarginFromRectEdge * 2, RectHeight * 0.5, col)
            end
        else
            if Teams[i] == PlayerTeam then
                local MarginFromRectEdge = ScrW() * 0.002
                surface.SetDrawColor((Teams[i] == TEAM_RED and color_myteam_red_bigrect) or color_myteam_blue_bigrect)
                surface.DrawRect(0 + MarginFromScreenEdge + MarginFromRectEdge, 0 + MarginFromScreenEdge + RectHeight * 0.5 * (i - 1), RectWidth - MarginFromRectEdge * 2, RectHeight * 0.5)
            end
        end

        local LiveCountRectWidth = ScrW() * 0.025
        local AllowanceForLiveCount = LiveCountRectWidth + ScrW() * 0.003
        -- Red team
        draw.DrawText(team.GetName(Teams[i]), "RobotoBig", 0 + RectWidth * 0.09 + AllowanceForLiveCount, 0 + MarginFromScreenEdge + ((i - 1) * 30), color_white, TEXT_ALIGN_LEFT)
        -- score
        draw.DrawText(team.GetScore(Teams[i]), "RobotoBig", 0 + MarginFromScreenEdge + RectWidth * 0.96, 0 + MarginFromScreenEdge + ((i - 1) * 30), color_white, TEXT_ALIGN_RIGHT)
        -- live count box
        surface.SetDrawColor((Teams[i] == TEAM_RED and color_myteam_red_livecountrect) or color_myteam_blue_livecountrect)
        surface.DrawRect(0 + MarginFromScreenEdge * 1.45, 0 + MarginFromScreenEdge + RectHeight * 0.5 * (i - 1), LiveCountRectWidth, RectHeight * 0.5)
        -- live count little player icon
        local PlayerIconMarginX = ScrW() * 0.0015
        local PlayerIconPosX = 0 + MarginFromScreenEdge * 1.45 + PlayerIconMarginX
        local PlayerIconMarginY = ScrH() * 0.018
        local PlayerIconPosY = 0 + MarginFromScreenEdge + ((i - 1) * 30) + PlayerIconMarginY
        local PlayerIconRectWidth = ScrW() * 0.0114
        local PlayerIconRectHeight = ScrH() * 0.011
        local CircleRadius_rndx = ScrW() * 0.007
        local CircleRadius_no_rndx = ScrW() * 0.004
        local CircleOffsetCorrection = ScrW() * 0.00220 -- surface.drawpoly doesn't round coords, my playericonrectwidth isnt precise enough i guess, so manually center the circle better
        local CircleDownOffset = ScrH() * 0.002 -- embed it a bit in the rect
        local col = color_black
        if RNDX then
            local LiveCountRadii = 6
            RNDX.Draw(LiveCountRadii, PlayerIconPosX, PlayerIconPosY, PlayerIconRectWidth, PlayerIconRectHeight, col, RNDX.NO_BL + RNDX.NO_BR)
            RNDX.DrawCircle(PlayerIconRectWidth + PlayerIconPosX * 0.5 + CircleOffsetCorrection, PlayerIconPosY - CircleRadius_rndx * 0.5 + CircleDownOffset, CircleRadius_rndx, col, RNDX.SHAPE_CIRCLE)
        else
            surface.SetDrawColor(col)
            surface.DrawRect(PlayerIconPosX, PlayerIconPosY, PlayerIconRectWidth, PlayerIconRectHeight)
            draw.Circle(PlayerIconRectWidth + PlayerIconPosX * 0.5 + CircleOffsetCorrection, PlayerIconPosY - CircleRadius_no_rndx + CircleDownOffset, CircleRadius_no_rndx, 9)
        end

        -- 1 players alive
        draw.DrawText(LiveCount, "RobotoBig", 0 + MarginFromScreenEdge * 1.25 + LiveCountRectWidth, 0 + MarginFromScreenEdge + ((i - 1) * 30), color_white, TEXT_ALIGN_RIGHT)
    end
end)

--[[------------------------------
    Team indicators
--------------------------------]]
surface.CreateFont("TeamIndicatorFont", {
    font = "Arial",
    size = ScrW() * 0.1,
    antialias = false,
    outline = true
})

local chevronleft = {
    {
        x = ScreenScale(-25),
        y = ScreenScaleH(0)
    },
    {
        x = ScreenScale(0),
        y = ScreenScaleH(75)
    },
    {
        x = ScreenScale(0),
        y = ScreenScaleH(95)
    },
    {
        x = ScreenScale(-40),
        y = ScreenScaleH(0)
    },
}

local chevronright = {
    {
        x = ScreenScale(0),
        y = ScreenScaleH(95)
    },
    {
        x = ScreenScale(0),
        y = ScreenScaleH(75)
    },
    {
        x = ScreenScale(25),
        y = ScreenScaleH(0)
    },
    {
        x = ScreenScale(40),
        y = ScreenScaleH(0)
    },
}

local ChevronHeight = ScreenScaleH(95)
local color_healthy = Color(219, 224, 170) -- 75+ hp
local color_notsohealthy = Color(162, 128, 40) -- 50+ hp
local color_nothealthy = Color(184, 81, 40) -- 25+ hp 
local color_nothealthyatall = Color(140, 12, 27) -- 0+ hp
local color_losthealth = Color(179, 41, 55)
AddGamemodeHook("PostDrawTranslucentRenderables", "TeamIndicators", function()
    local fov = LocalPlayer():GetFOV()
    for _, ply in player.Iterator() do
        if ply == LocalPlayer() then continue end
        if ply:GetNoDraw() == true then continue end
        if ply:Alive() == false then continue end
        if ply:Team() ~= LocalPlayer():Team() then continue end
        --local pos = ply:GetPos() + ply:GetUp() * (ply:OBBMaxs().z + 20)
        -- chatgpt scaling stuff
        -- to keep the triangle above the players head always
        local dist = EyePos():Distance(ply:GetPos())
        local offset = ply:OBBMaxs().z + math.Clamp(dist * 0.03, 5, 40)
        local pos = ply:GetPos() + Vector(0, 0, offset)
        local scale = dist * (fov / 90) / 6000
        --
        local angle = (pos - EyePos()):GetNormalized():Angle()
        angle = Angle(0, angle.y, 0)
        angle:RotateAroundAxis(angle:Up(), -90)
        angle:RotateAroundAxis(angle:Forward(), 90)
        cam.Start3D2D(pos, angle, scale)
        cam.IgnoreZ(true)
        local HPIndicativeDrawColor = color_healthy
        local PlayerHealth = ply:Health()
        if PlayerHealth <= 0 then
            cam.IgnoreZ(false)
            cam.End3D2D()
            continue -- ply:IsAlive does not update in time?
        end

        if PlayerHealth >= 50 then
            HPIndicativeDrawColor = color_notsohealthy
        elseif PlayerHealth >= 25 then
            HPIndicativeDrawColor = color_nothealthy
        elseif PlayerHealth >= 0 then
            HPIndicativeDrawColor = color_nothealthyatall
        end

        if ply.LastHealth and PlayerHealth < ply.LastHealth then
            ply.LostHealthOverride = CurTime()
            HPIndicativeDrawColor = color_losthealth
        end

        if ply.LostHealthOverride and ply.LostHealthOverride + 0.2 > CurTime() then -- 
            HPIndicativeDrawColor = color_losthealth
        end

        ply.LastHealth = PlayerHealth
        -- chevron
        draw.NoTexture()
        surface.SetDrawColor(HPIndicativeDrawColor)
        surface.DrawPoly(chevronleft)
        surface.DrawPoly(chevronright)
        -- name
        surface.SetFont("TeamIndicatorFont")
        local TextW, TextH = surface.GetTextSize(ply:Nick())
        draw.SimpleText(ply:Nick(), "TeamIndicatorFont", -TextW / 2, -ChevronHeight - TextH, HPIndicativeDrawColor)
        -- hp indicator
        local HPSquareGap = ScreenScale(45)
        local SquareSize = ScreenScale(25)
        local StartPos = -(4 * HPSquareGap - (HPSquareGap - SquareSize)) / 2
        local OutlineThickness = ScreenScale(3)
        for i = 1, math.Clamp(math.ceil(PlayerHealth / 25), 1, 4) do
            surface.SetDrawColor(HPIndicativeDrawColor)
            surface.DrawRect(StartPos + (i - 1) * HPSquareGap, -ChevronHeight + -ScreenScaleH(5), SquareSize, SquareSize)
            surface.SetDrawColor(color_black)
            surface.DrawOutlinedRect(StartPos + (i - 1) * HPSquareGap, -ChevronHeight + -ScreenScaleH(5), SquareSize, SquareSize, OutlineThickness)
        end

        -- armor indicator
        cam.IgnoreZ(false)
        cam.End3D2D()
    end
end)

--[[------------------------------
    Remove conflicting hooks
--------------------------------]]
rv_gm.SetPlayerOutlineFlip(true)
hook.Remove("PrePlayerDraw", "DuelDollModel")
hook.Remove("PostPlayerDraw", "DuelDollModel")
hook.Remove("ShouldCollide", "MakePlayersNotCollide")
hook.Remove("ShouldCollide", "MakeDuelPlayersNotCollide")
--[[
        AddGamemodeHook("ShouldCollide", "ShouldCollideConflictFix", function(ent1, ent2)
            --
            return true
        end, PRE_HOOK_RETURN)
        --]]
for _, ply in player.Iterator() do
    if ply.Doll then --
        ply.Doll:Remove()
    end
end
