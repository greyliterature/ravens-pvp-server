CreateClientConVar("rv_optin", "0", true, true, "Opt in to duel Glicko system.", 0, 1)
local PlayerTable = nil
local function ShowHud()
    local i = 0
    for ply, score in pairs(PlayerTable) do
        i = i + 1
        draw.SimpleText(ply .. ": " .. score, "Trebuchet24", 70, 70 + (i - 1) * 20)
    end
end

net.Receive("SetUpTeam", function()
    --
    team.SetUp(net.ReadUInt(16), net.ReadString(), net.ReadColor(true), net.ReadBool)
end)

net.Receive("SendHUD", function()
    PlayerTable = {}
    local NumberOfKeys = net.ReadUInt(16)
    for i = 1, NumberOfKeys do
        local ply = net.ReadString() -- When teambased, this is InnerTeam
        local Score = net.ReadInt(16) -- Remains as score
        PlayerTable[ply] = Score
    end

    hook.Add("HUDPaint", "ShowHud", ShowHud)
end)

net.Receive("ClearHUD", function()
    --
    hook.Remove("HUDPaint", "ShowHud")
end)

hook.Add("PrePlayerDraw", "DuelDollModel", function(ply, flags)
    if ply == LocalPlayer() then return end
    ply:SetNoDraw(ply:Team() ~= LocalPlayer():Team() and (ply:Team() ~= TEAM_RED and ply:Team() ~= TEAM_BLUE and (LocalPlayer():Team() == TEAM_RED or LocalPlayer():Team() == TEAM_BLUE)))
end)

hook.Add("PostPlayerDraw", "DuelDollModel", function(ply)
    if ply == LocalPlayer() then return end
    if (ply:Team() == TEAM_RED or ply:Team() == TEAM_BLUE) and (LocalPlayer():Team() == TEAM_RED or LocalPlayer():Team() == TEAM_BLUE) then return end
    if ply:Team() == LocalPlayer():Team() then
        if ply.Doll then --
            if IsValid(ply.Doll) then ply.Doll:Remove() end
            ply:SetColor(color_white)
            ply.Doll = nil
        end
        return
    end

    if not IsValid(ply) or not ply:Alive() then return end
    if not ply.Doll then
        ply.Doll = ClientsideModel("models/maxofs2d/companion_doll.mdl")
        ply.Doll:SetNoDraw(true)
        ply:SetColor(color_black)
    end

    local newang = ply:EyeAngles()
    newang.x = 0
    ply.Doll:SetPos(ply:GetPos())
    ply.Doll:SetAngles(newang)
    ply.Doll:SetupBones()
    ply.Doll:DrawModel()
end)

local InvalidFallback = 134634196349634 -- A player's arenanumber should never be set to this number. If the fallback of the player == InvalidFallback then the nwint didnt get set
hook.Add("ShouldCollide", "MakePlayersNotCollide", function(ent1, ent2)
    if ent1:GetNWInt("ArenaNumber", InvalidFallback) == InvalidFallback or ent2:GetNWInt("ArenaNumber", InvalidFallback) == InvalidFallback then return end
    return ent1:GetNWInt("ArenaNumber", 0) == ent2:GetNWInt("ArenaNumber", 0)
end)