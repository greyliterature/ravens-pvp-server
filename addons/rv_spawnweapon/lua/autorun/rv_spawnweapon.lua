CreateClientConVar("rv_spawnweapon", "weapon_357", true, true, "what weapon to pull out on spawn (an alternative to cl_defaultweapon)")
local JustSpawned = {}
gameevent.Listen("player_spawn")
hook.Add("player_spawn", "rv_spawnweapon", function(data)
    local ply = Player(data.userid)
    if SERVER then
        local RequestedWeap = ply:GetInfo("rv_spawnweapon")
        if list.GetEntry("Weapon", RequestedWeap) then ply:Give(RequestedWeap) end
    end

    if CLIENT and ply ~= LocalPlayer() then return end
    JustSpawned[ply] = true
end)

hook.Add("StartCommand", "rv_spawnweapon", function(ply, cmd)
    if not JustSpawned[ply] then return end
    if not ply:Alive() then return end
    JustSpawned[ply] = nil
    local weap = ply:GetInfo("rv_spawnweapon")
    weap = ply:GetWeapon(weap)
    if not IsValid(weap) then return end
    cmd:SelectWeapon(weap)
end)