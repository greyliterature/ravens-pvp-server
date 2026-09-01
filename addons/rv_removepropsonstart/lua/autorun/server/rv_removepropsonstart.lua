hook.Add("InitPostEntity", "RemovePropsAndEffects", function()
    for k, ent in ipairs(ents.FindByClass("prop_*")) do
        if ent:GetCreator() == NULL then ent:Remove() end
    end
    for k, ent in ipairs(ents.FindByClass("item_ammo_*")) do
        if ent:GetCreator() == NULL then ent:Remove() end
    end
    for k, ent in ipairs(ents.FindByClass("item_rpg_*")) do
        if ent:GetCreator() == NULL then ent:Remove() end
    end
    for k, ent in ipairs(ents.FindByClass("item_box_buckshot")) do
        if ent:GetCreator() == NULL then ent:Remove() end
    end
    for k, ent in ipairs(ents.FindByClass("item_health*")) do
        if ent:GetCreator() == NULL then ent:Remove() end
    end
    for k, ent in ipairs(ents.FindByClass("item_battery")) do
        if ent:GetCreator() == NULL then ent:Remove() end
    end
    for k, ent in ipairs(ents.FindByClass("info_particle_system")) do
        if ent:GetCreator() == NULL then ent:Remove() end
    end
end)
