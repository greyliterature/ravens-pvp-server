local function GetCrosshairColor()
	return Color(GetConVarNumber("cl_crosshaircolor_r"), GetConVarNumber("cl_crosshaircolor_g"), GetConVarNumber("cl_crosshaircolor_b"), GetConVarNumber("cl_crosshairalpha"))
end

local function DrawCrosshairRect(color, x0, y0, x1, y1, bAdditive) -- from garrys mod crosshair_setup code
	if GetConVarNumber("cl_crosshair_drawoutline") ~= 0 then
		local flThick = GetConVarNumber("cl_crosshair_outlinethickness")
		surface.SetDrawColor(0, 0, 0, color.a)
		surface.DrawRect(x0 - flThick, y0 - flThick, (x1 + flThick) - x0 + flThick, (y1 + flThick) - y0 + flThick)
	end

	surface.SetDrawColor(color.r, color.g, color.b, color.a)
	if bAdditive then
		surface.DrawTexturedRect(x0, y0, x1 - x0, y1 - y0)
	else
		surface.DrawRect(x0, y0, x1 - x0, y1 - y0)
	end
end

local additiveTex = Material("vgui/white_additive")
local crosshairMat = Material("gui/crosshair.png")
local w = ScrW()
local h = ScrH()
local function DrawSimpleCrosshairPreview(x, y) -- from garrys mod crosshair_setup code
	local color = GetCrosshairColor()
	local bAdditive = GetConVarNumber("cl_crosshairusealpha") == 0
	if bAdditive then
		surface.SetMaterial(additiveTex)
		color.a = 200
	end

	if GetConVarNumber("cl_crosshairstyle") == 0 then
		surface.SetFont("Crosshairs")
		surface.SetTextColor(255, 208, 64, 255)
		local width, height = surface.GetTextSize("Q")
		surface.SetTextPos(x - width / 2, y - height / 2)
		surface.DrawText("Q")
	elseif GetConVarNumber("cl_crosshairstyle") == 1 then
		local crosshairColor = GetCrosshairColor()
		surface.SetDrawColor(crosshairColor.r, crosshairColor.g, crosshairColor.b, crosshairColor.a)
		surface.SetMaterial(crosshairMat)
		surface.DrawTexturedRect(x - 32, y - 32, 64, 64)
	else
		local iBarSize = math.Round(ScreenScaleH(GetConVarNumber("cl_crosshairsize")))
		local iBarThickness = math.max(1, math.Round(ScreenScaleH(GetConVarNumber("cl_crosshairthickness"))))
		local iInnerCrossDist = GetConVarNumber("cl_crosshairgap")
		-- draw horizontal crosshair lines
		local iInnerLeft = x - iInnerCrossDist - iBarThickness / 2
		local iInnerRight = iInnerLeft + 2 * iInnerCrossDist + iBarThickness
		local iOuterLeft = iInnerLeft - iBarSize
		local iOuterRight = iInnerRight + iBarSize
		local y0 = y - iBarThickness / 2
		local y1 = y0 + iBarThickness
		DrawCrosshairRect(color, iOuterLeft, y0, iInnerLeft, y1, bAdditive)
		DrawCrosshairRect(color, iInnerRight, y0, iOuterRight, y1, bAdditive)
		-- draw vertical crosshair lines
		local iInnerTop = y - iInnerCrossDist - iBarThickness / 2
		local iInnerBottom = iInnerTop + 2 * iInnerCrossDist + iBarThickness
		local iOuterTop = iInnerTop - iBarSize
		local iOuterBottom = iInnerBottom + iBarSize
		local x0 = x - iBarThickness / 2
		local x1 = x0 + iBarThickness
		if GetConVarNumber("cl_crosshair_t") == 0 then DrawCrosshairRect(color, x0, iOuterTop, x1, iInnerTop, bAdditive) end
		DrawCrosshairRect(color, x0, iInnerBottom, x1, iOuterBottom, bAdditive)
		-- draw dot
		if GetConVarNumber("cl_crosshairdot") ~= 0 then
			x0 = x - iBarThickness / 2
			x1 = x0 + iBarThickness
			y0 = y - iBarThickness / 2
			y1 = y0 + iBarThickness
			DrawCrosshairRect(color, x0, y0, x1, y1, bAdditive)
		end
	end
end

local toscreen = 0
local dontdraw = false
local rv_extras_recoil_crosshair = CreateClientConVar("rv_extras_recoil_crosshair", 0, true, false, "Crosshair that shows recoil / viewpunch", 0, 1)
local rv_extras_recoil_crosshairbool = rv_extras_recoil_crosshair:GetBool()
cvars.AddChangeCallback("rv_extras_recoil_crosshair", function(convar, oldValue, newValue)
	rv_extras_recoil_crosshairbool = tobool(newValue)
	return
end, "rv_extras_recoil_crosshair")

hook.Add("HUDPaint", "RecoilCrosshair", function()
	if rv_extras_recoil_crosshairbool == false then return end
	toscreen = (EyePos() + LocalPlayer():GetAimVector() * 1.5):ToScreen()
	if math.abs(toscreen.x - 960) > 0.09 or math.abs(toscreen.y - 540) > 0.09 then -- prevents the crosshair from jittering (because of imprecision?)
		dontdraw = true
		DrawSimpleCrosshairPreview(toscreen.x, toscreen.y)
	else
		dontdraw = false
	end
end)

hook.Add("HUDShouldDraw", "HideCrosshair", function(name)
	if name == "CHudCrosshair" and dontdraw == true and rv_extras_recoil_crosshairbool == true then -- 
		return false
	end
end)