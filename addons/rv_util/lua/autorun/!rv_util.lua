colortable = {
    color_white = Color(255, 255, 255),
    color_black = Color(0, 0, 0),
    color_transparentblack = Color(0, 0, 0, 250),
    color_transparentgrey = Color(35, 35, 35, 254),
    color_lightred = Color(230, 0, 0),
    color_red = Color(255, 0, 0),
    color_qlred = Color(83, 33, 34),
    color_qllightred = Color(180, 45, 22),
    color_darkred = Color(229, 0, 70),
    color_transparentdarkred = Color(229, 0, 70, 220),
    color_blue = Color(0, 0, 255),
    color_qlblue = Color(30, 30, 85),
    color_orange = Color(255, 128, 0),
    color_511orange = Color(255, 100, 26),
    color_qlorange = Color(237, 169, 73),
    color_yellow = Color(255, 255, 0),
    color_darkyellow = Color(203, 203, 0),
    color_pickle = Color(199, 219, 156),
    color_lightpickle = Color(239, 249, 196),
    color_watermelon = Color(120, 200, 65),
    color_lightgreen = Color(125, 255, 131),
    color_green = Color(0, 255, 0),
    color_cyan = Color(0, 255, 255, 255),
    color_lightblue = Color(188, 188, 255),
    color_dead = Color(255, 24, 35),
    color_magenta = Color(255, 0, 255),
    color_team = Color(24, 162, 35),
}

if SERVER then
    util.AddNetworkString("ChatPrint")
    function ColoredChatPrint(text, ply)
        net.Start("ChatPrint", false)
        net.WriteTable(text)
        if IsValid(ply) then
            net.Send(ply)
        else
            net.Broadcast()
        end
    end
end

--local color_white = Color(255,255,255)
local colors = {
    ["0"] = colortable.color_black,
    ["1"] = colortable.color_red,
    ["2"] = colortable.color_green,
    ["3"] = colortable.color_yellow,
    ["4"] = colortable.color_blue,
    ["5"] = colortable.color_cyan,
    ["6"] = colortable.color_magenta,
    ["7"] = colortable.color_white,
    ["8"] = colortable.color_511orange,
}

function FindColorInText(text, ignorecolor)
    --local SplitText = string.Split(text, "")
    text = utf8.force(text)
    local ColorFound = false
    local ColoredText = {}
    local SplitText = {}
    for _, c in utf8.codes(text) do
        SplitText[#SplitText + 1] = utf8.char(c)
    end

    for i = 1, #SplitText do
        local LastCharacter = SplitText[i - 1]
        local Character = SplitText[i]
        local NextCharacter = SplitText[i + 1]
        if NextCharacter and colors[NextCharacter] and (Character == "^" and string.find(NextCharacter, "%d")) then
            if ignorecolor ~= true then --
                ColoredText[#ColoredText + 1] = colors[NextCharacter]
            end

            ColorFound = true
            continue
        end

        if LastCharacter and colors[Character] and (LastCharacter == "^" and string.find(Character, "%d")) then --
            continue
        end

        ColoredText[#ColoredText + 1] = Character
    end
    return (ColorFound == true and ColoredText) or nil
end

if CLIENT then
    net.Receive("ChatPrint", function()
        --
        local Text = net.ReadTable()
        timer.Simple(0, function()
            --
            chat.AddText(unpack(Text))
        end)
    end)
end

-- part of this function's code is possibly from https://github.com/Be1zebub, but I can't find out which part of it is borrowed, or from what repository. Probably from this repository: https://github.com/Be1zebub/Small-GLua-Things
-- just in case here is the license:
--[[
MIT License

Copyright (c) 2021-2025 Beelzebub

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
-]]
local WebhookRateLimit = 5
local LastTime = 0
local LastAvailableTime = nil
function SendWebhook(WebhookLink, content, WebhookName)
    local toJson = util.TableToJSON(content)
    toJson = string.Replace(toJson, "`", "\\\\`")
    if CurTime() > LastTime + WebhookRateLimit then
        LastTime = CurTime()
        print("Sending content to " .. WebhookName)
        reqwest({
            method = "post",
            type = "application/json; charset=utf-8",
            headers = {
                ["User-Agent"] = WebhookName,
            },
            url = WebhookLink,
            body = toJson,
            failed = function(error)
                --
                ErrorNoHalt("SendWebhook HTTP Errored: ", error, "\n")
            end,
            success = function(code, response)
                if code ~= 204 then --
                    ErrorNoHalt("SendWebhook HTTP Errored: ", code, response, "\n")
                end
            end
        })
    else
        LastAvailableTime = (LastAvailableTime and LastAvailableTime + WebhookRateLimit) or (CurTime() + WebhookRateLimit)
        timer.Simple(LastAvailableTime + WebhookRateLimit - CurTime(), function()
            print("Sending content to " .. WebhookName)
            reqwest({
                method = "post",
                type = "application/json; charset=utf-8",
                headers = {
                    ["User-Agent"] = WebhookName,
                },
                url = WebhookLink,
                body = toJson,
                failed = function(error)
                    --
                    ErrorNoHalt("SendWebhook HTTP Errored: ", error, "\n")
                end,
                success = function(code, response)
                    if code ~= 204 then --
                        ErrorNoHalt("SendWebhook HTTP Errored: ", code, response, "\n")
                    end
                end
            })
        end)
    end
end

function GetDeveloperMode()
    return GetConVar("developer"):GetBool() == true
end

QueuedFunctions = {}
function MakeQueue(func, RateLimit, identifier)
    QueuedFunctions[identifier] = QueuedFunctions[identifier] or {}
    QueuedFunctions[identifier].QueueCount = ((QueuedFunctions[identifier].QueueCount and QueuedFunctions[identifier].QueueCount) or 0) + 1
    QueuedFunctions[identifier].LastTime = (QueuedFunctions[identifier].LastTime and QueuedFunctions[identifier].LastTime) or 0
    if CurTime() > QueuedFunctions[identifier].LastTime + RateLimit then
        QueuedFunctions[identifier].LastTime = CurTime()
        QueuedFunctions[identifier].LastAvailableTime = CurTime() + RateLimit
        QueuedFunctions[identifier].QueueCount = QueuedFunctions[identifier].QueueCount - 1
        --print(QueuedFunctions[identifier].QueueCount .. " more queued functions with identifier " .. "\"" .. identifier .. "\"" .. " left.") 
        func()
    else
        QueuedFunctions[identifier].LastAvailableTime = (QueuedFunctions[identifier].LastAvailableTime and QueuedFunctions[identifier].LastAvailableTime + RateLimit) or (CurTime() + RateLimit)
        timer.Simple(QueuedFunctions[identifier].LastAvailableTime + RateLimit - CurTime(), function()
            QueuedFunctions[identifier].QueueCount = QueuedFunctions[identifier].QueueCount - 1
            if GetDeveloperMode() then print(QueuedFunctions[identifier].QueueCount .. " more queued functions with identifier " .. "\"" .. identifier .. "\"" .. " left.") end
            func()
        end)
    end
end

if SERVER then
    util.AddNetworkString("SetUpTeam")
    util.AddNetworkString("SendMultipleTeams")
    if not team.NewSetUp then
        local Teams = {}
        local oldTeamSetUp = team.SetUp
        function team.NewSetUp(...)
            local args = {...}
            print(unpack(args))
            oldTeamSetUp(unpack(args))
            Teams[#Teams + 1] = args
            net.Start("SetUpTeam")
            net.WriteUInt(args[1], 16)
            net.WriteString(args[2])
            net.WriteColor(args[3])
            net.WriteBool(args[4])
            net.Broadcast()
        end

        function team.SetUp(...)
            team.NewSetUp(...)
        end
    end

    --team.SetUp(1003, "red", color_white, true)
    function SendTeams(ply)
        if not IsValid(ply) then return end
        timer.Simple(1, function()
            if not IsValid(ply) then return end
            for i, v in pairs(team.GetAllTeams()) do
                local teamnumber = i
                print("Sending " .. ply:Nick() .. " " .. string.format([[team.SetUp(%s, team.GetName(%s), team.GetColor(%s), team.Joinable(%s))]], teamnumber, teamnumber, teamnumber, teamnumber))
                net.Start("SetUpTeam")
                net.WriteUInt(teamnumber, 16)
                net.WriteString(team.GetName(teamnumber))
                net.WriteColor(Color(255, 255, 100, 255), true)
                net.WriteBool(team.Joinable(teamnumber))
                net.Send(ply)
            end
        end)
    end

    local function SendAllTeams(ply)
        net.Start("SendMultipleTeams")
        net.WriteUInt(table.Count(team.GetAllTeams()), 16)
        for i, v in pairs(team.GetAllTeams()) do
            local teamnumber = i
            net.WriteUInt(teamnumber, 16)
            net.WriteString(team.GetName(teamnumber))
            net.WriteColor(team.GetColor(teamnumber), true)
            net.WriteBool(team.Joinable(teamnumber))
        end

        net.Send(ply)
    end

    hook.Add("PlayerInitialSpawn", "SendTeamsOnInitialSpawn", function(ply, trans)
        --
        SendAllTeams(ply)
    end)
end

if CLIENT then
    net.Receive("SendMultipleTeams", function(len, ply)
        local NumberOfKeys = net.ReadUInt(16)
        for i = 1, NumberOfKeys do
            local TeamNumber = net.ReadUInt(16)
            local TeamName = net.ReadString()
            local TeamColor = net.ReadColor()
            local TeamJoinable = net.ReadBool()
            team.SetUp(TeamNumber, TeamName, TeamColor, TeamJoinable)
            print(TeamNumber, TeamName, TeamColor, TeamJoinable)
        end
    end)

    net.Receive("SetUpTeam", function()
        team.SetUp(net.ReadUInt(16), net.ReadString(), net.ReadColor(true), net.ReadBool)
        return
    end)
end

_G["SetGlobal3Vars"] = {} -- shared for SetGlobal3* and GetGlobal3*
function GetGlobal3(VarIndex, Fallback) -- the type probably doesn't matter to exist clientside
    return _G["SetGlobal3Vars"][VarIndex] or Fallback
end

if SERVER then
    local function GetBitCount(x, IntType)
        if IntType ~= "UInt" and IntType ~= "Int" then return end
        if type(x) ~= "number" then return end
        if x >= 0 and IntType == "UInt" then
            if x == 0 then return 1 end
            return math.floor(math.log(x, 2)) + 1
        elseif x < 0 and IntType == "UInt" then
            ErrorNoHalt("x is not an unsigned integer, but is assigned as such")
        end

        if IntType == "Int" then
            if x == 0 then return 2 end
            return math.floor(math.log(math.abs(x), 2)) + 2
        end
    end

    util.AddNetworkString("Global3VarChange")
    function SetGlobal3(VarType, VarIndex, VarNewValue)
        _G["SetGlobal3Vars"][VarIndex] = {VarNewValue, VarType}
        net.Start("Global3VarChange")
        net.WriteString(VarType)
        net.WriteString(VarIndex)
        local BitCount = ((VarType == "Int" or VarType == "UInt") and GetBitCount(VarNewValue, VarType)) or 0
        net.WriteUInt(BitCount, 6) -- 6, because 5 bits can only go to 31, the UInt and Int can go only up to 32 bits.
        net["Write" .. VarType](VarNewValue, BitCount)
        net.Broadcast()
    end

    --SetGlobal3("Int", "MyCoolInt", 30)
    local AccountedForPlayers = {}
    util.AddNetworkString("InitPostEntityStarted")
    util.AddNetworkString("InitGlobal3Vars")
    net.Receive("InitPostEntityStarted", function(len, ply)
        if AccountedForPlayers[ply] then return end
        AccountedForPlayers[ply] = true
        net.Start("InitGlobal3Vars")
        local NumberOfKeys = table.Count(SetGlobal3Vars)
        PrintTable(SetGlobal3Vars)
        local NumKeysBitCount = GetBitCount(NumberOfKeys, "UInt")
        net.WriteUInt(NumKeysBitCount, 6)
        net.WriteUInt(NumberOfKeys, NumKeysBitCount)
        for VarIndex, tbl in pairs(SetGlobal3Vars) do
            local VarValue = tbl[1]
            local VarType = tbl[2]
            local BitCount = ((VarType == "Int" or VarType == "UInt") and GetBitCount(VarValue, VarType)) or 0
            net.WriteString(VarIndex)
            net.WriteString(VarType)
            net.WriteUInt(BitCount, 6)
            net["Write" .. VarType](VarValue, BitCount)
        end

        net.Send(ply)
    end)
    --[[
    hook.Add("PlayerInitialSpawn", "RenetworkGlobal3Vars", function(ply, trans)
        net.Start("InitGlobal3Vars")
        local NumberOfKeys = table.Count(SetGlobal3Vars)
        PrintTable(SetGlobal3Vars)
        local NumKeysBitCount = GetBitCount(NumberOfKeys, "UInt")
        net.WriteUInt(NumKeysBitCount, 6)
        net.WriteUInt(NumberOfKeys, NumKeysBitCount)
        for VarIndex, tbl in pairs(SetGlobal3Vars) do
            local VarValue = tbl[1]
            local VarType = tbl[2]
            local BitCount = ((VarType == "Int" or VarType == "UInt") and GetBitCount(VarValue, VarType)) or 0
            net.WriteString(VarIndex)
            net.WriteString(VarType)
            net.WriteUInt(BitCount, 6)
            net["Write" .. VarType](VarValue, BitCount)
        end

        net.Send(ply)
    end)
    --]]
elseif CLIENT then
    hook.Add("InitPostEntity", "InitPostEntityStarted", function()
        net.Start("InitPostEntityStarted")
        net.SendToServer()
    end)

    net.Receive("Global3VarChange", function(len, ply)
        local VarType = net.ReadString()
        local VarIndex = net.ReadString()
        local BitCount = net.ReadUInt(6)
        local VarNewValue = net["Read" .. VarType](BitCount)
        _G["SetGlobal3Vars"][VarIndex] = VarNewValue
        hook.Run("Global3VarChanged", VarType, VarIndex, VarNewValue)
    end)

    net.Receive("InitGlobal3Vars", function(len, ply)
        local NumKeysBitCount = net.ReadUInt(6)
        local NumberOfKeys = net.ReadUInt(NumKeysBitCount)
        for i = 1, NumberOfKeys do
            local VarIndex = net.ReadString()
            local VarType = net.ReadString()
            local BitCount = net.ReadUInt(6)
            local VarValue = net["Read" .. VarType](VarValue, BitCount)
            SetGlobal3Vars[VarIndex] = VarValue
            hook.Run("Global3VarChanged", VarType, VarIndex, VarValue, true)
        end
    end)
    --[[
    hook.Add("Global3VarChanged", "Global3VarChanged_example", function(VarType, VarIndex, VarNewValue, init)
        if init == true then
            print("Global3Var received for first time:", VarType, VarIndex, VarNewValue)
        else
            print("Global3Var Changed: ", VarType, VarIndex, VarNewValue)
        end

        PrintTable(SetGlobal3Vars)
    end)
    --]]
end

print("rv_util loaded :)")