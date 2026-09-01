-- Clientside FarZ / render distance, clamped down to highest render distance allowed by env_fog_controller / game default
if SERVER then
    util.AddNetworkString("FarZLimit")
    local fog_controller = ents.FindByClass("env_fog_controller")[1]
    local FarZLimit = 100000
    local r_mapextents = 16384 -- hardcoded value
    FarZLimit = IsValid(fog_controller) and fog_controller:GetInternalVariable("zfar") or r_mapextents * 1.73205080757
    hook.Add("PlayerInitialSpawn", "GiveFarZLimitOnJoin", function(ply, trans)
        net.Start("FarZLimit")
        net.WriteInt(FarZLimit, 32)
        net.Send(ply)
    end)
    --[[
    for k, ply in ipairs(player.GetAll()) do -- for autorefresh, delete later
        net.Start("FarZLimit")
        net.WriteInt(FarZLimit, 21)
        net.Send(ply)
    end
    --]]
end

if CLIENT then
    local FarZLimit = GetConVar("r_mapextents"):GetFloat() * 1.73205080757
    net.Receive("FarZLimit", function()
        FarZLimit = net.ReadInt(32)
        return
    end)

    local rv_farz = CreateClientConVar("rv_farz", FarZLimit, false, true, "controls the render distance", 0, FarZLimit)
    LocalFarZ = rv_farz:GetFloat()
    cvars.AddChangeCallback("rv_farz", function(convar, oldValue, newValue)
        LocalFarZ = math.Clamp(tonumber(newValue), 0, tonumber(FarZLimit)) -- make sure
    end, "rv_farz_callback")

    hook.Add("CalcView", "CustomFarZ", function(ply, pos, angles, fov)
        if FSpectate.isSpectating() or LocalFarZ == 0 or LocalFarZ > FarZLimit - 2 then return end
        local view = {
            zfar = LocalFarZ
        }
        return view
    end)
end