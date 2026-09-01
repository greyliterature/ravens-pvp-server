local ENV = include("rv_env/sv_rv_env.lua")
--
local UpdateDatabaseGlicko, GetMatchesleft = include("autorun/server/rv_glickodatabase.lua")
local _, GetGlicko = include("autorun/server/rv_glicko.lua")
--TODO: 
-- ADD RATE LIMITS!!!!!!!!!!!!
util.AddNetworkString("DuelRequest")
util.AddNetworkString("DuelRSVP")
util.AddNetworkString("ChatPrint")
util.AddNetworkString("SendHUD")
util.AddNetworkString("ClearHUD")
--local TEAM_DUEL = 1337
local DuelTeamIndexes = {
    1337 -- A cache of all newly created duels team indexes
}

for i = 1, #DuelTeamIndexes do
    TeamIndex = DuelTeamIndexes[i]
    team.SetUp(TeamIndex, "Duel" .. TeamIndex - 1336, color_white, true)
    for _, ply in player.Iterator() do
        SendTeams(ply)
    end
end

local function GetFreeDuelArena()
    for i = 1, #DuelTeamIndexes do
        if #team.GetPlayers(DuelTeamIndexes[i]) == 0 then
            return DuelTeamIndexes[i]
        elseif #team.GetPlayers(DuelTeamIndexes[i]) ~= 0 and i == #DuelTeamIndexes then
            -- If there are no free teams, make one.
            local NewTeamIndex = DuelTeamIndexes[i] + 1
            team.SetUp(NewTeamIndex, "Duel" .. NewTeamIndex - 1336, color_white, true)
            DuelTeamIndexes[#DuelTeamIndexes + 1] = NewTeamIndex
            for _, ply in player.Iterator() do -- Have to send the teams again since one was just created
                SendTeams(ply)
            end
            return NewTeamIndex
        end
    end
end

--[[hook.Add("CreateTeams", "Make_TEAM_DUEL", function()
    --
    team.SetUp(TEAM_DUEL, "Duels", {}, true)
end)
--]]
local DuelMaxScore = 20
local function SendDuelRequest(CallingPly, InvitedPly)
    CallingPly.OptedIn = tobool(CallingPly:GetInfoNum("rv_optin", 0))
    InvitedPly.OptedIn = tobool(InvitedPly:GetInfoNum("rv_optin", 0))
    ColoredChatPrint({colortable.color_pickle, "Sent duel request to ", colortable.color_watermelon, InvitedPly:Nick()}, CallingPly)
    ColoredChatPrint({colortable.color_watermelon, InvitedPly.invitedby:Nick(), colortable.color_pickle, " cordially invites you to a duel to ", colortable.color_watermelon, tostring(DuelMaxScore), colortable.color_pickle, ".", "\nType ", colortable.color_watermelon, "!a ", colortable.color_pickle, "to accept and ", colortable.color_darkred, "!d ", colortable.color_pickle, "to decline.", colortable.color_lightpickle, "\nYou" .. " opted in: ", (InvitedPly.OptedIn and colortable.color_watermelon) or colortable.color_darkred, tostring(tobool(InvitedPly.OptedIn)), colortable.color_lightpickle, "\n" .. InvitedPly.invitedby:Nick() .. " opted in: ", (InvitedPly.invitedby.OptedIn and colortable.color_watermelon) or colortable.color_darkred, tostring(tobool(InvitedPly.invitedby.OptedIn))}, InvitedPly)
    --[[
    -- This isn't used at all. I was probably trying to make some kind of ULX style popup?
    net.Start("DuelRequest")
    net.WriteString(callingply:Nick())
    net.Send(InvitedPly)
    --]]
end

local function SendHUD(ply)
    net.Start("SendHUD")
    local NumberOfKeys = #team.GetPlayers(ply:Team())
    net.WriteUInt(NumberOfKeys, 16)
    for _, teammember in ipairs(team.GetPlayers(ply:Team())) do
        net.WriteString(teammember:Nick())
        net.WriteInt(teammember.DuelScore, 16)
    end

    --net.Send(self)
    net.Send(team.GetPlayers(ply:Team()))
end

local function ClearHUD(ply)
    net.Start("ClearHUD")
    net.Send(ply)
end

local function RequestDuel(CallingPly, InvitedPlyName) -- add a score variable too
    if not IsValid(CallingPly) then return end
    -- Cache names in cases of disconnect
    local CallingPlyNick = CallingPly:Nick()
    local InvitedPlyNick = nil
    if not InvitedPlyName then return end
    if CallingPly.InDuel then
        CallingPly:ChatPrint("You are already in a duel.")
        return
    end

    local InvitedPly = nil
    for _, ply in player.Iterator() do
        if string.find(string.lower(ply:Nick()), string.lower(InvitedPlyName)) then --
            InvitedPly = ply
        end
    end

    if not InvitedPly then
        CallingPly:ChatPrint("Could not find player to invite.")
        return
    end

    if InvitedPly.InDuel then
        CallingPly:ChatPrint("That player is already in a duel.")
        return
    end

    if InvitedPly.invitedby then
        CallingPly:ChatPrint("That player has already been requested to join a duel.")
        return
    end

    if InvitedPly == CallingPly then
        CallingPly:ChatPrint("Can't request a duel to yourself.")
        return
    end

    InvitedPlyNick = InvitedPly:Nick()
    InvitedPly.invitedby = CallingPly
    timer.Simple(10, function()
        -- Time out the invitation after 15 seconds to free another player
        if not IsValid(InvitedPly) then return end
        if InvitedPly.invitedby then
            if IsValid(InvitedPly) and not InvitedPly.InDuel then InvitedPly:ChatPrint("Duel request from " .. CallingPlyNick .. " expired.") end
            if IsValid(CallingPly) and not CallingPly.InDuel then CallingPly:ChatPrint("Duel request to " .. InvitedPlyNick .. " expired.") end
        end

        InvitedPly.invitedby = nil
    end)

    SendDuelRequest(CallingPly, InvitedPly)
end

--RequestDuel(Entity(2), "ture")
--[[
-- I have no made it function with multiple duels running at the same time, hopefully this isn't needed.

hook.Add("PlayerCanDuel", "CheckDuelsFull", function(ply, requestedteam)
    --
    if team == TEAM_GHOST and #team.GetPlayers(TEAM_GHOST) >= 2 then --
        return false
    end
end)
--]]
function team.GetOtherPlayers(plytoexclude)
    local OtherPlayers = {}
    for _, ply in pairs(team.GetPlayers(plytoexclude:Team())) do
        if ply ~= plytoexclude then --
            OtherPlayers[#OtherPlayers + 1] = ply
        end
    end
    return OtherPlayers
end

local DuelsRunning = {}
local function EndDuel(winner, loser, arenanumber, reason)
    if not IsValid(winner) or not IsValid(loser) then return end
    DuelsRunning[winner] = nil
    -- Cache the names for cases of disconnect forfeiture
    local WinnerNick = winner:Nick()
    local LoserNick = loser:Nick()
    local WinnerSteamID64 = winner:SteamID64()
    local LoserSteamID64 = loser:SteamID64()
    local WinnerScore = winner.DuelScore
    local LoserScore = loser.DuelScore
    local ShouldUpdateGlickos = loser.OptedIn == true and winner.OptedIn == true
    for k, ply in ipairs(team.GetPlayers(arenanumber)) do
        ply.OldRating = select(2, GetGlicko(ply:SteamID64(), "Duel"))
        if k == 1 then UpdateDatabaseGlicko(WinnerSteamID64, winner.DuelScore, LoserSteamID64, loser.DuelScore, "Duel", reason == "(Player forfeited)" or reason == "(Player disconnected)", ShouldUpdateGlickos) end
        ply.NewRating = select(2, GetGlicko(ply:SteamID64(), "Duel"))
        ply.NewRD = select(1, GetGlicko(ply:SteamID64(), "Duel"))
        ply:SetNWString("DuelRating", tostring(math.Truncate(ply.NewRating, 0)))
        ply:SetNWInt("ArenaNumber", 0)
    end

    if ShouldUpdateGlickos then
        GetMapPreviewUrl(CurrentMapWSID, function(UrlReceived)
            local json = {
                content = "",
                embeds = {
                    {
                        title = "Match between " .. WinnerNick .. " and " .. LoserNick .. " completed. " .. (reason or ""),
                        color = 5814783,
                        fields = {
                            {
                                name = "Winner",
                                value = "[" .. WinnerNick .. "]" .. "(" .. "https://steamcommunity.com/profiles/" .. WinnerSteamID64 .. ")" .. " (Score: " .. WinnerScore .. ") (Rating: " .. math.Truncate(winner.NewRating, 0) .. ", RD: " .. math.Truncate(winner.NewRD, 0) .. ")"
                            },
                            {
                                name = "Loser",
                                value = "[" .. LoserNick .. "]" .. "(" .. "https://steamcommunity.com/profiles/" .. LoserSteamID64 .. ")" .. " (Score: " .. LoserScore .. ") (Rating: " .. math.Truncate(loser.NewRating, 0) .. ", RD: " .. math.Truncate(loser.NewRD, 0) .. ")"
                            },
                            {
                                name = "Map",
                                value = game.GetMap()
                            }
                        },
                        thumbnail = {
                            url = UrlReceived or ""
                        }
                    }
                }
            }

            SendWebhook(ENV.DUELS_WEBHOOK, json, "Gmod Duel Webhook")
        end)
    end

    for _, ply in ipairs(team.GetPlayers(arenanumber)) do
        if not IsValid(ply) then continue end
        local plyMatchesLeft = GetMatchesleft(ply:SteamID64())
        timer.Simple(0, function()
            if not IsValid(ply) then return end
            local GlickoChangeMessage = {"is unchanged because you or your opponent is not opted in with ", colortable.color_green, "!optin", colortable.color_white, "."}
            if ShouldUpdateGlickos then --
                if ply.NewRating > ply.OldRating then
                    GlickoChangeMessage = {colortable.color_lightgreen, "increased ", colortable.color_white, "by ", colortable.color_green, tostring(math.Truncate(ply.NewRating - ply.OldRating, 0))}
                elseif ply.NewRating < ply.OldRating then
                    GlickoChangeMessage = {colortable.color_lightred, "decreased ", colortable.color_white, "by ", colortable.color_green, tostring(math.Truncate(math.abs(ply.NewRating - ply.OldRating), 0))}
                else
                    GlickoChangeMessage = {colortable.color_white, "is ", colortable.color_green, tostring(math.Truncate(ply.NewRating, 0), (ply.NewRating == 1500 and "(starting rating).") or ""), colortable.color_white, "\nNext rating in ", colortable.color_green, plyMatchesLeft or "", colortable.color_white, (plyMatchesLeft and (plyMatchesLeft == 1 and " match") or " matches") or ""}
                end
            end

            ColoredChatPrint({colortable.color_white, "Your rating ", unpack(GlickoChangeMessage)}, ply)
        end)
    end

    timer.Simple(0, function()
        if IsValid(winner) and IsValid(loser) then
            -- 
            ColoredChatPrint({colortable.color_lightgreen, WinnerNick, color_white, " (Score: " .. WinnerScore .. ")" .. " defeats ", colortable.color_lightgreen, LoserNick, color_white, " (Score: " .. LoserScore .. ") " .. "in " .. "duel " .. "to ", colortable.color_green, tostring(DuelMaxScore) .. ((reason and " " .. reason) or "")})
        end

        for _, ply in ipairs(team.GetPlayers(arenanumber)) do
            if not IsValid(ply) then continue end
            ClearHUD(ply) -- i dont care about optimization right now
            ply.LastScore = ply.DuelScore
            ply.DuelScore = 0
            ply.InDuel = nil
            ply:SetNWBool("Duelling", false)
            ply:SetNWInt("DuelScore", 0)
            if ply:Alive() then ply:Spawn() end
            ply:SetTeam(TEAM_UNASSIGNED)
        end
    end)
end

local function StartDuel(CallingPly, InvitedPly)
    DuelsRunning[CallingPly] = true
    for _, ply in player.Iterator() do
        ply:SetCustomCollisionCheck(true)
        ply:CollisionRulesChanged()
    end

    if not IsValid(CallingPly) or not IsValid(InvitedPly) then return end
    local BestArenaIndex = GetFreeDuelArena() -- The lowest duel arena free of any players
    local Players = {CallingPly, InvitedPly}
    for _, ply in ipairs(Players) do
        ply:SetTeam(BestArenaIndex)
        ply.invitedby = nil -- Must clear their invitations
        ply:Spawn()
        ply.DuelScore = 0
        ply.LastScore = 0
        ply.InDuel = true
        ply.OptedIn = tobool(ply:GetInfoNum("rv_optin", 0))
        ply:SetNWBool("Duelling", true)
        SendHUD(ply)
        ply:SetNWInt("ArenaNumber", BestArenaIndex)
    end

    ColoredChatPrint({colortable.color_white, "Starting duel to ", colortable.color_lightgreen, tostring(DuelMaxScore), colortable.color_white, " between ", colortable.color_lightgreen, CallingPly:Nick(), colortable.color_white, " and ", colortable.color_lightgreen, InvitedPly:Nick()})
    hook.Add("PlayerDeath", "TrackDuelDeaths", function(victim, inflictor, attacker)
        if not victim:IsPlayer() or not attacker:IsPlayer() then return end
        if victim.InDuel and attacker:Team() == victim:Team() then
            local OtherPlayer = nil
            if victim == attacker then --
                OtherPlayer = team.GetOtherPlayers(attacker)[1]
                if OtherPlayer then OtherPlayer.DuelScore = (OtherPlayer.DuelScore or 0) + 1 end
            elseif victim ~= attacker then
                attacker.DuelScore = (attacker.DuelScore or 0) + 1
            end

            if OtherPlayer and OtherPlayer.DuelScore and OtherPlayer.DuelScore >= DuelMaxScore then --
                EndDuel(OtherPlayer, victim, victim:Team())
                return
            end

            if attacker.DuelScore >= DuelMaxScore then --
                EndDuel(attacker, victim, victim:Team())
                return
            end

            victim:SetNWInt("DuelScore", victim.DuelScore)
            attacker:SetNWInt("DuelScore", attacker.DuelScore)
            SendHUD(attacker) -- i dont care about optimization right now
            SendHUD(victim)
        end
    end)
end

local function DuelRSVP(ply, RSVPResult)
    RSVPResult = (RSVPResult == "!a" and true) or (RSVPResult == "!d" and false)
    if ply.InDuel then --
        ply:ChatPrint("You are already in a duel.")
        ply.invitedby = nil
    end

    if not ply.invitedby then
        timer.Simple(0, function()
            --
            ply:ChatPrint("You do not have any duel requests.")
        end)
        return
    end

    if RSVPResult == true then --
        StartDuel(ply.invitedby, ply)
        --[[
        -- I have now made it function with multiple duels running at the same time, hopefully this isn't needed.
        elseif RSVPResult == true and DuelRunning == true then
            timer.Simple(0, function()
                -- 
                ply:ChatPrint("Someone else started a duel before you accepted.")
            end)
        --]]
    end
end

local function ForfeitDuel(forfeiter)
    if not forfeiter.InDuel then
        forfeiter:ChatPrint("You aren't in a duel.")
        return
    end

    EndDuel(team.GetOtherPlayers(forfeiter)[1], forfeiter, forfeiter:Team(), "(Player forfeited)")
end

CreateConVar("rv_optin", "0", {FCVAR_USERINFO}, "Opt in to duel Glicko system.", 0, 1)
local function OptIntoGlicko(ply)
    if ply.InDuel then
        ply:ChatPrint("You can't opt in or out of ratings while in a duel.")
        return
    end

    ply.OptedIn = tobool(ply:GetInfoNum("rv_optin", 0))
    local NewOptInStatus = not ply.OptedIn
    ply:ConCommand("rv_optin " .. ((NewOptInStatus == true and "1") or "0"))
    ColoredChatPrint({"Opted " .. ((NewOptInStatus == true and "in to ") or "out of ") .. "glicko changes."}, ply)
end

local ChatCommands = {
    ["!duel"] = function(ply, ...) RequestDuel(ply, ...) end,
    ["!a"] = function(ply, ...) DuelRSVP(ply, ...) end,
    ["!d"] = function(ply, ...) DuelRSVP(ply, ...) end,
    ["!forfeit"] = function(ply, ...) ForfeitDuel(ply, ...) end,
    ["!optin"] = function(ply, ...) OptIntoGlicko(ply, ...) end,
}

hook.Add("PlayerSay", "HandleChatCommands", function(sender, text, teamChat)
    text = string.lower(text)
    local exploded = string.Explode(" ", text)
    local command = exploded[1]
    local args = exploded
    if #args > 1 then table.remove(args, 1) end
    table.RemoveByValue(args, "")
    local func = ChatCommands[command]
    if func then --
        func(sender, unpack(args))
    end
end)

hook.Add("PlayerSpawn", "SetCollisionRulesOnSpawn", function(ply)
    if DuelRunning == true then
        ply:SetCustomCollisionCheck(true)
        ply:CollisionRulesChanged()
    end
end)

hook.Add("ScalePlayerDamage", "RestrictTeamDamage", function(ply, hitgroup, dmginfo)
    if not dmginfo:GetAttacker():IsPlayer() then return end
    if ply:Team() ~= dmginfo:GetAttacker():Team() then
        dmginfo:SetDamage(0)
        return true
    end
end)

local InvalidFallback = 134634196349634 -- A player's arenanumber should never be set to this number. If the fallback of the player == InvalidFallback then the nwint didnt get set
hook.Add("ShouldCollide", "MakePlayersNotCollide", function(ent1, ent2)
    if ent1:GetNWInt("ArenaNumber", InvalidFallback) == InvalidFallback or ent2:GetNWInt("ArenaNumber", InvalidFallback) == InvalidFallback then return end
    return ent1:GetNWInt("ArenaNumber", 0) == ent2:GetNWInt("ArenaNumber", 0)
end)

hook.Add("PlayerDisconnected", "ForfeitDuelOnLeave", function(ply)
    if ply.InDuel then
        EndDuel(team.GetOtherPlayers(ply)[1], ply, ply:Team(), "(Player disconnected)")
        return
    end
end)

hook.Add("PlayerInitialSpawn", "InitDuelGlicko", function(ply, trans)
    if tobool(ply:GetInfoNum("rv_optin", 0)) == true then
        ply:SetNWString("DuelRating", tostring(math.Truncate(select(2, GetGlicko(ply:SteamID64(), "Duel")))))
        return
    end
end)