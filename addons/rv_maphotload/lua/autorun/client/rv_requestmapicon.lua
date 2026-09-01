net.Receive("SendMapIconRequest", function(len, ply)
    local wsid = net.ReadString()
    steamworks.FileInfo(wsid, function(data)
        if data then
            net.Start("GetMapIcon")
            net.WriteString(data.previewurl)
            net.SendToServer()
        end
    end)
end)
