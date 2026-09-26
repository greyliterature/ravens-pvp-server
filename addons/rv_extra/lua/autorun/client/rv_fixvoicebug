local rv_fixvoicebug = CreateClientConVar("rv_fixvoicebug", "1")
hook.Add("NetworkEntityCreated", "FixVoiceBug", function(ent)
    if not ent:IsPlayer() then return end
    local ply = ent
    if ply == LocalPlayer() then
        -- perhaps this is an important distinction, and 
        -- the line should be removed, not sure
        return
    end

    print(((ply == LocalPlayer() and "You") or ply:Nick()) .. " has become valid")
    if rv_fixvoicebug:GetBool() == true then
        ply:SetMuted(true) -- the player was previously invalid, now valid,
        -- so we can use ply:SetMuted() to fix their CHUD element not 
        -- appearing correctly
        print("muted " .. ((ply == LocalPlayer() and "You") or ply:Nick()))
        timer.Simple(1, function()
            -- should this delay be this short? worth testing
            ply:SetMuted(false) -- we dont want to keep them muted, this will bring back the element in time
            print("unmuted " .. ((ply == LocalPlayer() and "You") or ply:Nick()))
        end)
    end
end)
