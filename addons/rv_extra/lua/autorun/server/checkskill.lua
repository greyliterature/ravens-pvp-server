local GoodHash = "4735011c7536b83331b0955fd4de6565051d50aef8c06d1192bd6c668d4e84d4"
hook.Add("InitPostEntity", "CheckSkill_ManifestFile", function()
    local ManifestHash = util.SHA256(file.Read("cfg/skill_manifest.cfg", "GAME"))
    if ManifestHash ~= GoodHash then
        ErrorNoHalt("skill_manifest.cfg was changed") 
    end
end)
