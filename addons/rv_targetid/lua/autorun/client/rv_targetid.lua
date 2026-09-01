local rv_targetid = CreateClientConVar("rv_targetid", 1, true, false, "Whether or not to draw TargetID while looking at a player (hp and names)", 0, 1)

local rv_targetidbool = tobool(rv_targetid:GetBool())
cvars.AddChangeCallback("rv_targetid", function(convar_name, value_old, value_new)
    rv_targetidbool = tobool(value_new)
end, "rv_targetid")

hook.Add("HUDDrawTargetID", "rv_targetid", function()
    return rv_targetidbool == false or nil
end)
