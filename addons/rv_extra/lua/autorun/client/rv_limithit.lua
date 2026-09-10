hook.Add("OnGamemodeLoaded", "ChangeLimitHit", function()
    local GMMETA = gmod.GetGamemode()
    function GMMETA:LimitHit(name) -- from https://github.com/Facepunch/garrysmod/blob/2ab95e5342f831ade3d9768a8d5c684b542d2d2e/garrysmod/gamemodes/sandbox/gamemode/cl_init.lua#L32
        local str = "#SBoxLimit_" .. name
        local translated = language.GetPhrase(str)
        if str == translated then
            -- No translation available, apply our own
            translated = language.FormatPhrase("hint.hitXlimit", language.GetPhrase(name))
        end

        self:AddNotify(translated, NOTIFY_ERROR, 6)
        surface.PlaySound("buttons/combine_button_locked.wav")
    end
end)
