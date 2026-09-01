util.AddNetworkString("ChatMessage")
BadWords = {
    ["retard"] = "ridiculous friend",
    ["retarded"] = "ridiculous",
    ["fag"] = "friend",
    ["faggot"] = "fugazi",
    ["kike"] = "kite",
    ["nigga"] = "buddy",
    ["nigger"] = "neighbor",
    ["/VIgger"] = "neighbor",
    ["chink"] = "sink",
    ["killyourself"] = "kissyourself",
    ["kys"] = "ily",
    ["kill yourself"] = "kiss yourself",
    ["heil"] = "hi",
    ["tnd"] = "lgbt",
    ["troon"] = "spoon",
    ["tranny"] = "granny",
    ["negro"] = "grey",
    ["hitler"] = "garry",
    ["1488"] = "1337",
    ["jewish"] = "newish",
    ["gook"] = "cook",
    ["exechack"] = "LIFEHACK BIIIITCH",
    ["rape"] = "hug",
    ["raped"] = "hugged",
}

-- gpt because im not making patterns myself
local LeetMap = {
    a = "[aA@4]",
    b = "[bB8]",
    c = "[cC%(<]",
    d = "[dD%)]",
    e = "[eE3]",
    f = "[fF]",
    g = "[gG69]",
    h = "[hH#]",
    i = "[iI1!|]",
    j = "[jJ]",
    k = "[kK]",
    l = "[lL1|]",
    m = "[mM]",
    n = "[nN]",
    o = "[oO0]",
    p = "[pP]",
    q = "[qQ]",
    r = "[rR]",
    s = "[sS5$]",
    t = "[tT7+]",
    u = "[uU]",
    v = "[vV]",
    w = "[wW]",
    x = "[xX]",
    y = "[yY]",
    z = "[zZ2]"
}

local function MakePattern(word)
    local pattern = ""
    for i = 1, #word do
        local char = string.sub(word, i, i)
        local group = LeetMap[char] or char
        -- Allow non-alphanumeric characters between letters
        pattern = pattern .. group
        if i < #word then pattern = pattern .. "[^%w]*" end
    end
    return pattern
end

local function SortedBadWords()
    local words = {}
    for word, replacement in pairs(BadWords) do
        table.insert(words, {
            word = word,
            replacement = replacement
        })
    end

    table.sort(words, function(a, b)
        return #a.word > #b.word -- longest first
    end)
    return words
end

local function SendChatMessage(message, excludedply, originalmessage)
    local MessageToOthers = {team.GetColor(excludedply:Team()), excludedply:Nick(), Color(255, 255, 255, 255), ": " .. message,}
    local MessageToSelf = {team.GetColor(excludedply:Team()), excludedply:Nick(), Color(255, 255, 255, 255), ": " .. originalmessage}
    local ColoredText = FindColorInText(originalmessage)
    local ColoredName = FindColorInText(excludedply:Nick())
    if ColoredText or ColoredName then
        local NewText = {}
        if isDead == true then
            local DeadTable = {color_dead, language.GetPhrase("chat.dead") .. " "}
            table.Add(NewText, DeadTable)
        end

        --
        local NickTable = {team.GetColor(excludedply:Team())}
        if ColoredName then
            table.Add(NickTable, ColoredName)
        else
            table.insert(NickTable, excludedply:Nick())
        end

        table.Add(NewText, NickTable)
        --
        MessageToOthers = table.Copy(NewText)
        local MessageTable = {color_white, ": "}
        table.Add(MessageToOthers, MessageTable)
        local ColoredMessage = FindColorInText(message)
        if ColoredMessage then
            table.Add(MessageToOthers, ColoredMessage)
        else
            table.insert(MessageToOthers, message)
        end

        MessageToSelf = table.Copy(NewText)
        table.Add(MessageToSelf, MessageTable)
        local ColoredOriginalMessage = FindColorInText(originalmessage)
        if ColoredOriginalMessage then
            table.Add(MessageToSelf, ColoredOriginalMessage)
        else
            table.insert(MessageToSelf, originalmessage)
        end
    end

    for _, ply in ipairs(player.GetAll()) do
        if ply == excludedply then
            net.Start("ChatMessage")
            net.WriteTable(MessageToSelf)
            net.Send(ply)
        else
            net.Start("ChatMessage")
            net.WriteTable(MessageToOthers)
            net.Send(ply)
        end
    end
end

function ulx.anotify(calling_ply, message)
    for _, ply in ipairs(player.GetAll()) do
        if ply:IsAdmin() or ply:IsSuperAdmin() then
            net.Start("ChatMessage")
            net.WriteTable({"(ADMINS) *** " .. calling_ply:Nick() .. " tried saying: " .. message})
            net.Send(ply)
        end
    end
end

hook.Add("PlayerSay", "ChatFilter", function(sender, text, teamChat)
    if sender:GetUserGroup() == "DOLLMODE" then return end
    local original = text
    local lowered = string.lower(text)
    local containsBadWord = false
    for badWord, _ in pairs(BadWords) do
        local pattern = MakePattern(badWord)
        if string.find(lowered, pattern) then
            containsBadWord = true
            break
        end
    end

    if containsBadWord == false then return end
    local sortedWords = SortedBadWords()
    for _, entry in ipairs(sortedWords) do
        local pattern = MakePattern(entry.word)
        local startPos, endPos = string.find(lowered, pattern)
        while startPos do
            original = string.sub(original, 1, startPos - 1) .. entry.replacement .. string.sub(original, endPos + 1)
            lowered = string.lower(original)
            startPos, endPos = string.find(lowered, pattern)
        end
    end

    ulx.anotify(sender, text)
    SendChatMessage(original, sender, text)
    return ""
end, POST_HOOK_RETURN)
