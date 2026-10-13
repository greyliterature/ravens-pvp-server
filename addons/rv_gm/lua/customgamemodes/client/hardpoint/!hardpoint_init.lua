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
----
local MarginFromEdgeX = ScrW() * 0.01
local MarginFromEdgeY = ScrH() * 0.02
local TopRectMarginW = ScrW() * 0.02
local TopRectMarginH = ScrH() * 0.02
local ScoreTextMarginW = ScrW() * 0.003
local MarginBetweenRects = ScrH() * 0.02
local HardPointMargin = ScrH() * 0.005
--
local BackgroundRectW = ScrW() * 0.13
local BackgroundRectH = ScrH() * 0.075
local ScoreRectH = ScrH() * 0.015
--
---- colors 
local color_RectBackground = Color(25, 25, 25, 230)
local color_pfBlue = Color(0, 100, 170)
local color_pfDarkBlue = Color(0, 40, 90)
local color_pfRed = Color(170, 10, 0)
local color_pfDarkRed = Color(90, 10, 0)
---- icons
local LockIcon = Material("icon16/lock_delete.png")
local LockSize = ScrW() * 0.01
hook.Add("HUDPaint", "ShowHardpoint", function()
    -- show hardpoints
    for _, hardpoint in ipairs(rv_gm.GetAllTriggerParents()) do
        if not IsValid(hardpoint) then continue end
        if CurTime() < GetGlobal3("HardPointUnlockDate", 0) then
            local data = hardpoint:GetPos():ToScreen()
            surface.SetMaterial(LockIcon)
            surface.SetDrawColor(color_white)
            surface.DrawTexturedRect(data.x, data.y, LockSize, LockSize)
        else
        end
    end

    -- "HARDPOINT"
    draw.SimpleText("Hard Point", "ChatFont", 0 + MarginFromEdgeX, ScrH() - MarginFromEdgeY - BackgroundRectH - HardPointMargin, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
    surface.SetDrawColor(color_RectBackground)
    surface.DrawRect(0 + MarginFromEdgeX, ScrH() - MarginFromEdgeY - BackgroundRectH, BackgroundRectW, BackgroundRectH)
    local TimeLeft = GetGlobal3("MatchTimeLimit", 0) - CurTime()
    local time = (rv_gm.IsMatchInProgress() == true and string.FormattedTime(TimeLeft, "%02i:%02i")) or "WARM-UP"
    draw.SimpleText(time, "ChatFont", 0 + MarginFromEdgeX + BackgroundRectW * 0.5, ScrH() - MarginFromEdgeY - BackgroundRectH, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    -- score rects
    -- blue team
    surface.SetDrawColor(color_pfDarkBlue)
    surface.DrawRect(0 + MarginFromEdgeX + TopRectMarginW, ScrH() - MarginFromEdgeY - BackgroundRectH + TopRectMarginH, BackgroundRectW - TopRectMarginW * 2, ScoreRectH)
    draw.SimpleText("BL", "ChatFont", 0 + MarginFromEdgeX + TopRectMarginW - ScoreTextMarginW, ScrH() - MarginFromEdgeY - BackgroundRectH + TopRectMarginH + ScoreRectH * 0.5, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    local BlueScore = team.GetScore(TEAM_BLUE)
    draw.SimpleText(BlueScore, "ChatFont", 0 + MarginFromEdgeX + BackgroundRectW - TopRectMarginW + ScoreTextMarginW, ScrH() - MarginFromEdgeY - BackgroundRectH + TopRectMarginH + ScoreRectH * 0.5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    surface.SetDrawColor(color_pfBlue)
    local BlueRatio = math.Clamp(BlueScore / 250, 0, 1)
    surface.DrawRect(0 + MarginFromEdgeX + TopRectMarginW, ScrH() - MarginFromEdgeY - BackgroundRectH + TopRectMarginH, (BackgroundRectW - TopRectMarginW * 2) * BlueRatio, ScoreRectH)
    -- red team
    surface.SetDrawColor(color_pfDarkRed)
    surface.DrawRect(0 + MarginFromEdgeX + TopRectMarginW, ScrH() - MarginFromEdgeY - BackgroundRectH + TopRectMarginH + MarginBetweenRects, BackgroundRectW - TopRectMarginW * 2, ScoreRectH)
    draw.SimpleText("RD", "ChatFont", 0 + MarginFromEdgeX + TopRectMarginW - ScoreTextMarginW, ScrH() - MarginFromEdgeY - BackgroundRectH + TopRectMarginH + ScoreRectH * 0.5 + MarginBetweenRects, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    local RedScore = team.GetScore(TEAM_RED)
    draw.SimpleText(RedScore, "ChatFont", 0 + MarginFromEdgeX + BackgroundRectW - TopRectMarginW + ScoreTextMarginW, ScrH() - MarginFromEdgeY - BackgroundRectH + TopRectMarginH + ScoreRectH * 0.5 + MarginBetweenRects, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    surface.SetDrawColor(color_pfRed)
    local RedRatio = math.Clamp(RedScore / 250, 0, 1)
    surface.DrawRect(0 + MarginFromEdgeX + TopRectMarginW, ScrH() - MarginFromEdgeY - BackgroundRectH + TopRectMarginH + MarginBetweenRects, (BackgroundRectW - TopRectMarginW * 2) * RedRatio, ScoreRectH)
end)
