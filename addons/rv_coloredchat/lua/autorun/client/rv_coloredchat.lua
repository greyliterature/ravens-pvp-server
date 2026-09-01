hook.Add("OnPlayerChat", "ColoredText", function(ply, text, teamChat, isDead)
    if not IsValid(ply) then return end
    surface.PlaySound("common/talk.wav")
    local ColoredText = FindColorInText(text)
    local ColoredName = FindColorInText(ply:Nick())
    if ColoredText or ColoredName then
        local NewText = {}
        if isDead == true then
            local DeadTable = {colortable.color_dead, language.GetPhrase("chat.dead") .. " "}
            table.Add(NewText, DeadTable)
        end

        if teamChat == true then
            local TeamTable = {colortable.color_team, language.GetPhrase("chat.team") .. " "}
            table.Add(NewText, TeamTable)
        end

        local NickTable = {team.GetColor(ply:Team())}
        if ColoredName then
            table.Add(NickTable, ColoredName)
        else
            table.insert(NickTable, ply:Nick())
        end

        table.Add(NewText, NickTable)
        --
        local MessageTable = {color_white, ": "}
        if ColoredText then
            table.Add(MessageTable, ColoredText)
        else
            table.insert(MessageTable, text)
        end

        table.Add(NewText, MessageTable)
        --
        -- Finish
        chat.AddText(unpack(NewText))
        return true
    end
end)
