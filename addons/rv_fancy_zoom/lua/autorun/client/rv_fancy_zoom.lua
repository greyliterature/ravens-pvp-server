local animation_start = CurTime()
local ZOOMING_IN = false
local animation_progress = 0
concommand.Add("rv_toggle_zoom", function()
    ZOOMING_IN = not ZOOMING_IN
    animation_start = CurTime()
    animation_progress = 1 - animation_progress
end)

--[[---------------------
    Convars
-----------------------]]
local rv_extras_fancy_zoom = CreateClientConVar("rv_extras_fancy_zoom", 0, true, false, "Whether or not to replace TOGGLE_ZOOM with rv_TOGGLE_ZOOM", 0, 1)
local rv_extras_fancy_zoombool = rv_extras_fancy_zoom:GetBool()
cvars.AddChangeCallback("rv_extras_fancy_zoom", function(convar, oldValue, newValue)
    rv_extras_fancy_zoombool = tobool(newValue)
    return
end, "rv_extras_fancy_zoom")

local rv_extras_fancy_zoom_finalfov = CreateClientConVar("rv_extras_fancy_zoom_finalfov", 25, true, false, "Final FOV when zooming in with rv_fancy_zoom", 1, 100)
local rv_extras_fancy_zoom_finalint = rv_extras_fancy_zoom_finalfov:GetInt()
cvars.AddChangeCallback("rv_extras_fancy_zoom_finalfov", function(convar, oldValue, newValue)
    rv_extras_fancy_zoom_finalint = tonumber(newValue)
    return
end, "rv_extras_fancy_zoom_finalfov")

local rv_extras_fancy_zoom_in_speed = CreateClientConVar("rv_extras_fancy_zoom_in_speed", 0.25, true, false, "How quickly rv_fancy_zoom zoomes in", 0, 20)
local rv_extras_fancy_zoom_in_speedfloat = rv_extras_fancy_zoom_in_speed:GetFloat()
cvars.AddChangeCallback("rv_extras_fancy_zoom_in_speed", function(convar, oldValue, newValue)
    rv_extras_fancy_zoom_in_speedfloat = tonumber(newValue)
    return
end, "rv_extras_fancy_zoom_in_speed")

local rv_extras_fancy_zoom_out_speed = CreateClientConVar("rv_extras_fancy_zoom_out_speed", 0.25, true, false, "How quickly rv_fancy_zoom zoomes out", 0, 20)
local rv_extras_fancy_zoom_out_speedfloat = rv_extras_fancy_zoom_out_speed:GetFloat()
cvars.AddChangeCallback("rv_extras_fancy_zoom_out_speed", function(convar, oldValue, newValue)
    rv_extras_fancy_zoom_out_speedfloat = tonumber(newValue)
    return
end, "rv_extras_fancy_zoom_out_speed")

hook.Add("PlayerBindPress", "ZOOMING_VALUE", function(ply, bind, pressed, code)
    if rv_extras_fancy_zoombool == false then return end
    bind = string.lower(bind)
    if bind == "+zoom" then
        RunConsoleCommand("rv_toggle_zoom")
        return true
    end

    if bind == "toggle_zoom" then --
        return true
    end
end)

local LastTime = 0
hook.Add("PlayerButtonDown", "TOGGLE_ZOOM", function(ply, button)
    if LastTime == CurTime() then return end
    LastTime = CurTime()
    local keybind = input.LookupKeyBinding(button) or ""
    if string.lower(keybind) == "toggle_zoom" then --
        RunConsoleCommand("rv_toggle_zoom")
    end
end)

local CurrentFOV = GetConVar("fov_desired"):GetInt()
hook.Add("CalcView", "TOGGLE_ZOOM", function(ply, pos, angles, fov)
    if FSpectate.isSpectating() or rv_extras_fancy_zoombool == false then return end
    CurrentFOV = CurrentFOV or fov
    animation_progress = (CurTime() - animation_start) / ((ZOOMING_IN == true and rv_extras_fancy_zoom_in_speedfloat) or rv_extras_fancy_zoom_out_speedfloat)
    local animated_value = (ZOOMING_IN == true and Lerp(animation_progress, fov, rv_extras_fancy_zoom_finalint)) or Lerp(animation_progress, CurrentFOV, fov)
    CurrentFOV = animated_value
    local view = {
        fov = animated_value,
    }
    return view
end)

hook.Add("AdjustMouseSensitivity", "ZoomSens", function(defaultSensitivity, localFOV, defaultFOV)
    if rv_extras_fancy_zoombool == false or not CurrentFOV then return end
    local ratio = math.tan(math.rad(CurrentFOV / 2)) / math.tan(math.rad(defaultFOV / 2))
    local k = ratio --^ 0.75
    return k
end)

local rv_extras_fancy_zoom_swap_instant = CreateClientConVar("rv_extras_fancy_zoom_swap_instant", 1, true, false, "Whether or not to instantly zoom out on swap weapon (like default suitzoom)", 0, 1)
local rv_extras_fancy_zoom_swap_instantbool = rv_extras_fancy_zoom_swap_instant:GetBool()
cvars.AddChangeCallback("rv_extras_fancy_zoom_swap_instant", function(convar, oldValue, newValue)
    rv_extras_fancy_zoom_swap_instantbool = tobool(newValue)
    return
end, "rv_extras_fancy_zoom_swap_instant")

hook.Add("PlayerSwitchWeapon", "ResetZoomOnSwapWeapon", function()
    -- i dont think i need to check for what weapon they switch to?
    if rv_extras_fancy_zoom_swap_instantbool == false then animation_start = CurTime() end
    ZOOMING_IN = false
end)