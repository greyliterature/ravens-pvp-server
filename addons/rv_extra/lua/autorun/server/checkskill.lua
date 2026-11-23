local Goodhash = ""
hook.Add("InitPostEntity", "CheckSkill_ManifestFile", function()
    local ManifestHash = util.SHA256(file.Read("cfg/skill_manifest.cfg", "GAME"))
    if ManifestHash ~= GoodHash then
        ErrorNoHalt("skill_manifest.cfg was changed") 
    end
end)
