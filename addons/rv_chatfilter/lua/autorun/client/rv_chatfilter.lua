net.Receive("ChatMessage", function()
    local Text = net.ReadTable()
    timer.Simple(0, function()
        --
        chat.AddText(unpack(Text))
    end)
end)
