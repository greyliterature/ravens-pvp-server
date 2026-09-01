local PlayersDrawn = 0
local OutlineCandidates = {}
CreateClientConVar("rv_outlines", 1, true, false, "Whether or not to draw the outlines on players", 0, 1)
CreateClientConVar("rv_outlinesdot", 0.75, true, false, "Dot product for outlines, if the player is too far away from your crosshair they won't be outlined.", 0, 1)
CreateClientConVar("rv_outlinesmaxplayers", 3, true, false, "Maximum players to be outlined, players closer to your crosshair take higher priority.", 1, 100)
CreateClientConVar("rv_outlinescolor", "255 0 255 255", true, true, "Color of outlines. 1 - 255 <r g b a>")
CreateClientConVar("rv_outlinesthickness", "1", true, false, "Thickness of outlines.", 1, 1000)
rv_outlinescolorstringcolor = Color(string.Split(GetConVar("rv_outlinescolor"):GetString(), " ")[1], string.Split(GetConVar("rv_outlinescolor"):GetString(), " ")[2], string.Split(GetConVar("rv_outlinescolor"):GetString(), " ")[3], string.Split(GetConVar("rv_outlinescolor"):GetString(), " ")[4] or 255)
cvars.AddChangeCallback("rv_outlinescolor", function(convar_name, value_old, value_new)
	local Split = string.Split(GetConVar("rv_outlinescolor"):GetString(), " ")
	rv_outlinescolorstringcolor = Color(Split[1], Split[2], Split[3], Split[4] or 255)
end, "rv_outlinescolor")

local rv_outlinesdotfloat = GetConVar("rv_outlinesdot"):GetFloat()
cvars.AddChangeCallback("rv_outlinesdot", function(convar_name, value_old, value_new) rv_outlinesdotfloat = tonumber(value_new) end, "rv_outlinesdot")
local rv_outlinesmaxplayersint = GetConVar("rv_outlinesmaxplayers"):GetInt()
cvars.AddChangeCallback("rv_outlinesmaxplayers", function(convar_name, value_old, value_new) rv_outlinesmaxplayersint = tonumber(value_new) end, "rv_outlinesmaxplayers")
rv_outlinesthicknessint = GetConVar("rv_outlinesthickness"):GetInt()
cvars.AddChangeCallback("rv_outlinesthickness", function(convar_name, value_old, value_new) rv_outlinesthicknessint = tonumber(value_new) end, "rv_outlinesthickness")
rv_outlinesbool = tobool(GetConVar("rv_outlines"):GetBool())
local function rv_drawoutlines()
	if rv_outlinesbool == false then -- unnecessary but whatever
		return
	end

	PlayersDrawn = 0
	OutlineCandidates = {}
	thickness = rv_outlinesthicknessint
	local ShouldDraw = nil
	for _, ply in player.Iterator() do
		if not IsValid(ply) then continue end
		if not ply:Alive() then continue end
		if ply == LocalPlayer() then continue end
		if ply:GetNoDraw() == true then continue end
		local DistToTarg = (ply:GetPos() - LocalPlayer():GetShootPos()):GetNormalized()
		local dot = LocalPlayer():GetAimVector():Dot(DistToTarg)
		ShouldDraw = dot >= rv_outlinesdotfloat
		if ShouldDraw then OutlineCandidates[ply] = dot end
	end

	for candidate, v in SortedPairsByValue(OutlineCandidates, true) do
		if not IsValid(candidate) then continue end
		ShouldDraw = PlayersDrawn < rv_outlinesmaxplayersint
		local IsInSameDuel = candidate:Team() == LocalPlayer():Team()
		if ShouldDraw and IsInSameDuel then
			outline.Add(candidate, rv_outlinescolorstringcolor, 2, rv_outlinesthicknessint)
			PlayersDrawn = PlayersDrawn + 1
		end
	end
end

cvars.AddChangeCallback("rv_outlines", function(convar_name, value_old, value_new)
	rv_outlinesbool = tobool(value_new)
	if rv_outlinesbool == true then
		hook.Add("PreDrawOutlines", "rv_outlines", rv_drawoutlines)
	else
		hook.Remove("PreDrawOutlines", "rv_outlines")
	end
end, "rv_outlines")

-- for initial run
if rv_outlinesbool == true then hook.Add("PreDrawOutlines", "rv_outlines", rv_drawoutlines) end
