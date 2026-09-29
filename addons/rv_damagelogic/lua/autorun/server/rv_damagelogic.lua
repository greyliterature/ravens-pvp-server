if SERVER then
    local BadAmmoTypes = {
        ["SMG1_Grenade"] = true,
        ["AR2AltFire"] = true,
    }

    local LoadoutConvars = {
        RefillAmmoOnSpawn = CreateConVar("rv_sv_refill_ammo_on_spawn", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Whether or not to set players ammo to full on spawn", 0),
        MaxHealth = CreateConVar("rv_sv_maxhealth", "150", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Max health for players", 0),
        SpawnHealth = CreateConVar("rv_sv_spawnhealth", "100", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Spawn health for players", 0),
        MaxArmor = CreateConVar("rv_sv_maxarmor", "50", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Max armor for players", 0),
        SpawnArmor = CreateConVar("rv_sv_spawnarmor", "50", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Spawn armor for players", 0),
    }

    local HealConvars = {
        HealType = CreateConVar("rv_sv_healtype", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Heal type per kill reward", 0),
    }

    local RefillConvars = {}
    local HealTypes = {
        [1] = function(ply) ply:SetHealth(LoadoutConvars.SpawnHealth:GetInt()) end,
    }

    local function HealPlayer(ply)
        local HealType = HealConvars.HealType:GetInt()
        if HealTypes[HealType] then
            HealTypes[HealType](ply)
            return
        end
    end

    hook.Add("HealPlayer", "HealPlayer", function(ply)
        local ShouldHealPlayer = hook.Run("ShouldHealPlayer", ply)
        if ShouldHealPlayer == false then return end
        HealPlayer(ply)
    end)

    local function RefillAmmo(ply) -- fill players mags and give infinite ammo
        for Index, AmmoType in ipairs(game.GetAmmoTypes()) do
            if not BadAmmoTypes[AmmoType] then
                ply:GiveAmmo(9999, Index, true)
            elseif BadAmmoTypes[AmmoType] then
                ply:RemoveAmmo(9999, AmmoType)
            end
        end

        for _, weapon in ipairs(ply:GetWeapons()) do
            weapon:SetClip1(weapon:GetMaxClip1())
        end
    end

    --[[
    hook.Add("ShouldRefillPlayerAmmo", "NoAmmo", function(ply)
        --
        return false
    end)
    --]]
    hook.Add("RefillAmmo", "RefillAmmo", function(ply)
        local ShouldRefillPlayerAmmo = hook.Run("ShouldRefillPlayerAmmo", ply)
        if ShouldRefillPlayerAmmo == false then return end
        RefillAmmo(ply)
    end)

    --[[
    hook.Add("ShouldRewardPlayer", "NoAmmo", function(ply)
        --
        return false
    end)
    --]]
    hook.Add("RewardPlayer", "RewardPlayer", function(ply)
        local ShouldRewardPlayer = hook.Run("ShouldRewardPlayer", ply)
        if ShouldRewardPlayer == false then return end
        hook.Run("HealPlayer", ply)
        hook.Run("RefillAmmo", ply)
    end)

    hook.Add("PlayerDeath", "RewardPlayer", function(victim, _, attacker)
        if victim ~= attacker then --
            hook.Run("RewardPlayer", attacker)
        end
    end)

    local Loadout = {
        "weapon_357", --formatterexpandtable 
        "weapon_ar2",
        "weapon_crossbow",
        "weapon_crowbar",
        "weapon_frag",
        "weapon_physcannon",
        "weapon_pistol",
        "weapon_shotgun",
        "weapon_smg1",
    }

    hook.Add("PlayerLoadout", "GiveSpawnWeapons", function(ply)
        for i = 1, #Loadout do
            ply:Give(Loadout[i])
        end

        if LoadoutConvars.RefillAmmoOnSpawn:GetBool() == true then RefillAmmo(ply) end
        ply:SetMaxHealth(LoadoutConvars.MaxHealth:GetInt())
        ply:SetHealth(LoadoutConvars.SpawnHealth:GetInt())
        ply:SetMaxArmor(LoadoutConvars.MaxArmor:GetInt())
        ply:SetArmor(LoadoutConvars.SpawnArmor:GetInt())
    end)
end
