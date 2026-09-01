-- local ENV = include("rv_env/sv_rv_env.lua")
local ENV = {
    GITHUB_TOKEN="",
    DUELS_WEBHOOK="",
    INVITES = {
        TOKEN="",
        INVITE_CHANNEL="",
        INVITE_LOG_WEBHOOK="",
    }
}

if game.IsDedicated() == false then -- helpful reminder
    ErrorNoHalt("Remember to delete rv_env/lua/sv_rv_env.lua if you are going to join a server")
end

return ENV
