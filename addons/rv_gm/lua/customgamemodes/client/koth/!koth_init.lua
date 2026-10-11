local rv_gm = include("customgamemodes/client/gm_universal/gm_universal.lua")
print("HEYO")
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
surface.CreateFont("Roboto_Zero", {
    font = "Roboto Lt",
    extended = false,
    size = ScrW() / 55.8461538,
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

surface.CreateFont("Roboto_Control", {
    font = "Roboto Lt",
    extended = false,
    size = ScrW() / 100.8461538,
    weight = 600,
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

local TextMarginX = ScrW() * 0.002
local TextMarginY = ScrH() * 0.0015
local MaxDigits = 3
----
local TEAM_RED, TEAM_BLUE = 1, 2
local MarginX = ScrW() * 0.01
local MarginY = ScrH() * 0.03
local RectWidth = ScrW() * 0.1
local RectHeight = ScrH() * 0.067
local TopRectHeight = ScrH() * 0.015
local BottomRectHeight = ScrH() * 0.017
--
local IconWidth = ScrH() * 0.01
local IconHeight = ScrH() * 0.01
local IconMarginX = ScrW() * 0.002
--local IconMarginY = ScrW() * 0.002
--
local PeopleIconMarginY = ScrH() * 0.012
local PeopleIconRectWidth = ScrW() * 0.006
local PeopleIconRectHeight = ScrH() * 0.0075
local PeopleIconCircleRadius = ScrW() * 0.004
local PeopleIconCircleMarginY = ScrH() * 0.004
local PeopleIconCircleCorrectionX = ScrW() * 0.003
--
local PeopleRectX = ScrW() * 0.035
--local PeopleRectWidth = RectWidth * 0.5
----
--local color_transparentishblack = Color(0, 0, 0, 128)
local color_wdblue = Color(86, 187, 253)
local color_wdlonestarblue = Color(50, 119, 157)
local color_wdvalkyrared = Color(240, 69, 48)
local color_wdred = Color(255, 90, 69)
local color_wdblackred = Color(113, 59, 57)
local color_wdsuperblackred = Color(40, 6, 2)
local color_wdsuperblackblue = Color(12, 27, 33)
local color_wdcontested = Color(160, 162, 17)
local color_wdblackblue = Color(39, 59, 113)
local color_wdgreytop = Color(74, 74, 74)
local color_wdblack = Color(43, 43, 43)
local color_wdbottom = Color(153, 153, 153)
--
local color_wdzerogrey = Color(83, 83, 83, 100)
local color_wdzerocontrollingteamwhite = Color(240, 240, 240, 100)
local color_wdtextred = Color(144, 96, 72)
local color_wdtextblue = Color(124, 128, 127)
local color_wdcontrollingtextred = Color(253, 195, 184)
local color_wdcontrollingtextblue = Color(205, 241, 246)
-- 
local color_wdpeopleblack = Color(23, 23, 23, 100)
----
local gradient_up = Material("gui/gradient_up")
----
local triangle = {
    {
        x = MarginX + RectWidth * 0.5 + IconMarginX,
        y = ScrH() - MarginY - RectHeight + (TopRectHeight - IconHeight) * 0.5
    },
    {
        x = MarginX + RectWidth * 0.5 + IconMarginX + IconWidth,
        y = ScrH() - MarginY - RectHeight + (TopRectHeight - IconHeight) * 0.5
    },
    {
        x = MarginX + RectWidth * 0.5 + IconMarginX + IconWidth * 0.5,
        y = ScrH() - MarginY - RectHeight + (TopRectHeight - IconHeight) * 0.5 + IconHeight
    }
}

local RNDX = include("autorun/rndx.lua")
----
local CONTROLLING_TEAM_NOPLAYERS = 95316
local CONTROLLING_TEAM_CONTESTED = 953493
AddGamemodeHook("HUDPaint", "KOTHProgressBar", function()
    --surface.SetDrawColor(color_transparentishblack)
    --surface.DrawRect(0 + MarginX, ScrH() - MarginY - RectHeight, RectWidth, RectHeight)
    local redscore = team.GetScore(TEAM_RED)
    local bluescore = team.GetScore(TEAM_BLUE)
    local ControllingTeam = GetGlobal3("ControllingTeam", 9999)
    if ControllingTeam == 9999 then --
        ControllingTeam = nil
    end

    -- top left rect
    surface.SetDrawColor((ControllingTeam == TEAM_BLUE and color_wdblue) or color_wdgreytop)
    surface.DrawRect(0 + MarginX, ScrH() - MarginY - RectHeight, RectWidth * 0.5, TopRectHeight)
    surface.SetDrawColor(color_wdlonestarblue)
    surface.DrawRect(0 + MarginX + IconMarginX, ScrH() - MarginY - RectHeight + (TopRectHeight - IconHeight) * 0.5, IconWidth, IconHeight)
    -- top right rect
    surface.SetDrawColor((ControllingTeam == TEAM_RED and color_wdred) or color_wdgreytop)
    surface.DrawRect(0 + MarginX + RectWidth * 0.5, ScrH() - MarginY - RectHeight, RectWidth * 0.5, TopRectHeight)
    draw.NoTexture()
    surface.SetDrawColor(color_wdvalkyrared)
    surface.DrawPoly(triangle)
    -- left (blue) team text rect
    surface.SetDrawColor(color_wdblack)
    surface.DrawRect(0 + MarginX, ScrH() - MarginY - RectHeight + TopRectHeight, RectWidth * 0.5, TopRectHeight * 2)
    surface.SetDrawColor((ControllingTeam == TEAM_BLUE and color_wdblackblue) or color_wdblack)
    surface.SetMaterial(gradient_up)
    surface.DrawTexturedRect(0 + MarginX, ScrH() - MarginY - RectHeight, RectWidth * 0.5, TopRectHeight + TopRectHeight * 2 + BottomRectHeight)
    do
        local NumDigits = #tostring(bluescore)
        local DigitsStr = "000"
        if bluescore ~= 0 then -- if redscore is 0 then we fill with 000, otherwise pad 
            DigitsStr = ""
            for i = 1, MaxDigits - NumDigits do
                DigitsStr = DigitsStr .. "0"
            end
        end

        surface.SetFont("Roboto_Zero")
        local DigitsTextW, _ = surface.GetTextSize("000")
        draw.SimpleText(DigitsStr, "Roboto_Zero", 0 + MarginX + TextMarginX, ScrH() - MarginY - RectHeight + TopRectHeight + TopRectHeight * 2 - TextMarginY, (ControllingTeam == TEAM_RED and color_wdzerocontrollingteamwhite) or color_wdzerogrey, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
        draw.SimpleText(bluescore, "Roboto_Zero", 0 + MarginX + TextMarginX + DigitsTextW, ScrH() - MarginY - RectHeight + TopRectHeight + TopRectHeight * 2 - TextMarginY, (ControllingTeam == TEAM_BLUE and color_wdcontrollingtextblue) or color_wdtextblue, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
        -- left people rect
        surface.SetDrawColor(color_wdpeopleblack)
        local CurrentLeftPeopleRectX = 0 + MarginX + PeopleRectX
        local LeftRightSideX = 0 + MarginX + RectWidth * 0.5
        surface.DrawRect(CurrentLeftPeopleRectX, ScrH() - MarginY - RectHeight + TopRectHeight, LeftRightSideX - CurrentLeftPeopleRectX, TopRectHeight * 2)
        -- left people icon
        --surface.SetDrawColor(color_wdcontrollingtextred)
        if RNDX then --
            RNDX.Draw(6, CurrentLeftPeopleRectX + ((LeftRightSideX - CurrentLeftPeopleRectX) - PeopleIconRectWidth) * 0.5, ScrH() - MarginY - RectHeight + TopRectHeight + PeopleIconMarginY, PeopleIconRectWidth, PeopleIconRectHeight, color_wdcontrollingtextblue, RNDX.NO_BL + RNDX.NO_BR)
            RNDX.DrawCircle(CurrentLeftPeopleRectX + ((LeftRightSideX - CurrentLeftPeopleRectX) - PeopleIconCircleRadius) - PeopleIconCircleCorrectionX, ScrH() - MarginY - RectHeight + TopRectHeight + PeopleIconMarginY - PeopleIconCircleMarginY, PeopleIconCircleRadius, color_wdcontrollingtextblue)
        end
    end

    -- right (red) team text rect
    surface.SetDrawColor(color_wdblack)
    surface.DrawRect(0 + MarginX + RectWidth * 0.5, ScrH() - MarginY - RectHeight + TopRectHeight, RectWidth * 0.5, TopRectHeight * 2)
    surface.SetDrawColor((ControllingTeam == TEAM_RED and color_wdblackred) or color_wdblack)
    surface.SetMaterial(gradient_up)
    surface.DrawTexturedRect(0 + MarginX + RectWidth * 0.5, ScrH() - MarginY - RectHeight, RectWidth * 0.5, TopRectHeight + TopRectHeight * 2 + BottomRectHeight)
    do
        local NumDigits = #tostring(redscore)
        local DigitsStr = "000"
        if redscore ~= 0 then -- if redscore is 0 then we fill with 000, otherwise pad 
            DigitsStr = ""
            for i = 1, MaxDigits - NumDigits do
                DigitsStr = DigitsStr .. "0"
            end
        end

        surface.SetFont("Roboto_Zero")
        local DigitsTextW, _ = surface.GetTextSize("000")
        draw.SimpleText(DigitsStr, "Roboto_Zero", 0 + MarginX + RectWidth * 0.5 + TextMarginX, ScrH() - MarginY - RectHeight + TopRectHeight + TopRectHeight * 2 - TextMarginY, (ControllingTeam == TEAM_RED and color_wdzerocontrollingteamwhite) or color_wdzerogrey, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
        draw.SimpleText(redscore, "Roboto_Zero", 0 + MarginX + RectWidth * 0.5 + TextMarginX + DigitsTextW, ScrH() - MarginY - RectHeight + TopRectHeight + TopRectHeight * 2 - TextMarginY, (ControllingTeam == TEAM_RED and color_wdcontrollingtextred) or color_wdtextred, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
        -- right people rect
        surface.SetDrawColor(color_wdpeopleblack)
        local CurrentPeopleRectX = 0 + MarginX + RectWidth * 0.5 + PeopleRectX
        local RightSideX = 0 + MarginX + RectWidth
        surface.DrawRect(CurrentPeopleRectX, ScrH() - MarginY - RectHeight + TopRectHeight, RightSideX - CurrentPeopleRectX, TopRectHeight * 2)
        -- right people icon
        --surface.SetDrawColor(color_wdcontrollingtextred)
        if RNDX then --
            RNDX.Draw(6, CurrentPeopleRectX + ((RightSideX - CurrentPeopleRectX) - PeopleIconRectWidth) * 0.5, ScrH() - MarginY - RectHeight + TopRectHeight + PeopleIconMarginY, PeopleIconRectWidth, PeopleIconRectHeight, color_wdcontrollingtextred, RNDX.NO_BL + RNDX.NO_BR)
            RNDX.DrawCircle(CurrentPeopleRectX + ((RightSideX - CurrentPeopleRectX) - PeopleIconCircleRadius) - PeopleIconCircleCorrectionX, ScrH() - MarginY - RectHeight + TopRectHeight + PeopleIconMarginY - PeopleIconCircleMarginY, PeopleIconCircleRadius, color_wdcontrollingtextred)
        end
    end

    -- bottom rect
    surface.SetDrawColor((ControllingTeam == TEAM_BLUE and color_wdsuperblackblue) or (ControllingTeam == TEAM_RED and color_wdsuperblackred) or color_wdgreytop)
    surface.DrawRect(0 + MarginX, ScrH() - MarginY - RectHeight + TopRectHeight + TopRectHeight * 2, RectWidth, BottomRectHeight)
    local StartTime = GetGlobal3("HillStartTime", 0)
    local TimeToScore = GetGlobal3("TimeToScoreHill", 1)
    local TimeElapsed = CurTime() - StartTime
    local ratio = math.Clamp(TimeElapsed / TimeToScore, 0, 1)
    local col = color_wdcontested
    if ControllingTeam ~= CONTROLLING_TEAM_CONTESTED and rv_gm.IsMatchInProgress() == false then
        col = color_wdbottom
    elseif ControllingTeam == TEAM_BLUE then
        col = color_wdblue
    elseif ControllingTeam == TEAM_RED then
        col = color_wdred
    elseif ControllingTeam == CONTROLLING_TEAM_NOPLAYERS then
        col = color_wdbottom
    end

    surface.SetDrawColor(col)
    surface.DrawRect(0 + MarginX, ScrH() - MarginY - RectHeight + TopRectHeight + TopRectHeight * 2, RectWidth * ratio, BottomRectHeight)
    local controlstr = "NONE"
    if ControllingTeam ~= CONTROLLING_TEAM_NOPLAYERS then
        if ControllingTeam == CONTROLLING_TEAM_CONTESTED then --
            controlstr = "CONTESTED"
        else
            controlstr = string.upper(team.GetName(ControllingTeam))
        end
    end

    draw.SimpleText("CONTROL: " .. controlstr, "Roboto_Control", 0 + MarginX, ScrH() - MarginY - RectHeight + TopRectHeight + TopRectHeight * 2 + BottomRectHeight * 0.5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end)
