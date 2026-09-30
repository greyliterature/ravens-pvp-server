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
        HealthMargin = CreateConVar("rv_sv_heal_healthmargin", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY, "What percentage of a player's spawn health to heal (float)", 0),
        ArmorMargin = CreateConVar("rv_sv_heal_armormargin", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY, "What percentage of a player's spawn armor to heal (float)", 0),
        HealTimerDelay = CreateConVar("rv_sv_healtype_2_healtimerdelay", "0.1", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Delay between each heal in seconds", 0),
        HealthPerTick = CreateConVar("rv_sv_healtype_2_healthpertick", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY, "How much health to give player per tick", 0),
        ArmorPerTick = CreateConVar("rv_sv_healtype_2_armorpertick", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY, "How much armor to give player per tick", 0),
        EnterCombatStopHealing = CreateConVar("rv_sv_healtype_2_entercombatstophealing", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Whether or not to stop healing player when they enter combat", 0),
        RewardMargin = CreateConVar("rv_sv_heal_rewardmargin", "0.5", FCVAR_ARCHIVE + FCVAR_NOTIFY, "What percentage of a player's health must an enemy deal to be rewarded health", 0),
    }

    local HealTypes = {
        [1] = function(ply)
            -- classic
            ply:SetHealth(LoadoutConvars.SpawnHealth:GetInt() * HealConvars.HealthMargin:GetFloat())
            ply:SetArmor(LoadoutConvars.SpawnArmor:GetInt() * HealConvars.ArmorMargin:GetFloat())
        end,
        [2] = function(ply)
            -- zonemod
            ply.Healing = true
            local HealthTarget = LoadoutConvars.SpawnHealth:GetInt() * HealConvars.HealthMargin:GetFloat()
            local ArmorTarget = LoadoutConvars.SpawnArmor:GetInt() * HealConvars.ArmorMargin:GetFloat()
            local HealthCounts = (LoadoutConvars.SpawnHealth:GetInt() * HealConvars.HealthMargin:GetFloat()) / HealConvars.HealthPerTick:GetInt()
            local HealthHealed = 0
            local ArmorCounts = (LoadoutConvars.SpawnArmor:GetInt() * HealConvars.ArmorMargin:GetFloat()) / HealConvars.ArmorPerTick:GetInt()
            local ArmorHealed = 0
            timer.Create("HealReward" .. ply:UserID(), HealConvars.HealTimerDelay:GetFloat(), 0, function()
                if not ply.Healing then
                    timer.Remove("HealReward" .. ply:UserID())
                    return
                end

                local Double = 2
                if ply:Health() < HealthTarget and HealthHealed < HealthCounts then --
                    ply:SetHealth(math.Clamp(ply:Health() + HealConvars.HealthPerTick:GetInt(), 0, HealthTarget))
                    HealthHealed = HealthHealed + 1
                    Double = Double - 1
                end

                if ply:Armor() < ArmorTarget and ArmorHealed < ArmorCounts then --
                    ply:SetArmor(math.Clamp(ply:Armor() + HealConvars.ArmorPerTick:GetInt(), 0, ArmorTarget))
                    ArmorHealed = ArmorHealed + 1
                    Double = Double - 1
                end

                if Double == 2 then -- player reached both armor and health target, or they used up their HealCounts 
                    timer.Remove("HealReward" .. ply:UserID())
                end
            end)
        end,
        [3] = function(ply)
            -- medshot
            print("Finish this later")
        end,
    }

    hook.Add("PlayerHurt", "DamageContributions", function(victim, attacker, healthRemaining, damageTaken)
        if not IsValid(attacker) then return end
        victim.LastTickHealth = victim.LastTickHealth or victim:GetSpawnHealth()
        local LastTickHealth = victim.LastTickHealth
        victim.LastTickHealth = healthRemaining
        healthRemaining = math.max(healthRemaining, 0)
        local TrueDamageTaken = LastTickHealth - healthRemaining
        victim.DamageContributions = victim.DamageContributions or {}
        victim.DamageContributions[attacker] = (victim.DamageContributions[attacker] or 0) + TrueDamageTaken
        if HealConvars.EnterCombatStopHealing:GetBool() == true then --
            victim.Healing = nil
            attacker.Healing = nil
        end
    end)

    cvars.AddChangeCallback("rv_sv_healtype_entercombatstophealing", function(_, _, new)
        if new == "1" then --
            hook.Add("PlayerHurt", "RemoveHealTimer", HandleHealTimers)
        end
    end, "rv_sv_healtype_entercombatstophealing")

    local function HealPlayer(ply)
        local HealType = HealConvars.HealType:GetInt()
        if HealTypes[HealType] then
            HealTypes[HealType](ply)
            return
        end
    end

    hook.Add("AwardPlayerHealth", "AwardPlayerHealth", function(ply, victim)
        local ShouldAwardPlayerHealth = hook.Run("ShouldAwardPlayerHealth", ply)
        if ShouldAwardPlayerHealth == false then return end
        if victim.DamageContributions[ply] < victim:GetSpawnHealth() * HealConvars.RewardMargin:GetFloat() then return end
        HealPlayer(ply, victim)
    end)

    local RefillAmmo = nil
    local RefillConvars = {
        RefillType = CreateConVar("rv_sv_refill_refilltype", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Refill type per kill award", 0),
        RefillMargin = CreateConVar("rv_sv_refill_refillmargin", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY, "What percentage of a player's CURRENT clip to refill (float)", 0),
        RefillAllWeapons = CreateConVar("rv_sv_refill_refillallweapons", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Whether or not to refill all of a player's weapons", 0),
        RewardMargin = CreateConVar("rv_sv_refill_rewardmargin", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY, "What percentage of a player's health must an enemy deal to be rewarded ammo", 0),
    }

    local function ShotgunFix(ply, ammocount)
        local shotgun = ply:GetWeapon("weapon_shotgun")
        if shotgun:Clip1() == shotgun:GetMaxClip1() then -- 6 / 6 shots means the shotgun is probably pumped
            return
        end

        local current = ply:GetActiveWeapon()
        local lastweap = ply:GetInternalVariable("m_hLastWeapon")
        if not IsValid(lastweap) or lastweap:GetClass() == "weapon_shotgun" then lastweap = nil end
        ply:StripWeapon("weapon_shotgun")
        local weap = ply:Give("weapon_shotgun")
        weap:SetClip1(ammocount or weap:GetMaxClip1())
        ply:SelectWeapon(lastweap or weap)
        ply:SelectWeapon(current)
    end

    local RefillTypes = {
        [1] = function(ply)
            local weap = ply:GetActiveWeapon()
            if not IsValid(weap) then -- this shouldn't happen though, probably
                return
            end

            local AmmoType = weap:GetPrimaryAmmoType()
            if not BadAmmoTypes[AmmoType] then --
                ply:GiveAmmo(9999, AmmoType, true)
            end

            if weap:GetClass() == "weapon_shotgun" then
                ShotgunFix(ply)
            else
                weap:SetClip1(math.Clamp(weap:GetMaxClip1() * RefillConvars.RefillMargin:GetFloat(), weap:Clip1(), weap:GetMaxClip1()))
            end

            if RefillConvars.RefillAllWeapons:GetBool() == true then --
                RefillAmmo(ply)
                ShotgunFix(ply)
            end
        end,
    }

    RefillAmmo = function(ply)
        -- fill players mags and give infinite ammo
        for Index, AmmoType in ipairs(game.GetAmmoTypes()) do
            if not BadAmmoTypes[AmmoType] then
                ply:GiveAmmo(9999, Index, true)
            elseif BadAmmoTypes[AmmoType] then
                ply:RemoveAmmo(9999, AmmoType)
            end
        end

        ShotgunFix(ply)
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
    local function RefillPlayer(ply, victim)
        local ShouldHealPlayer = hook.Run("ShouldHealPlayer", ply)
        if ShouldHealPlayer == false then return end
        HealPlayer(ply, victim)
        local RefillType = RefillConvars.RefillType:GetInt()
        if RefillTypes[RefillType] then
            RefillTypes[RefillType](ply)
            return
        end

        RefillAmmo(ply)
    end

    hook.Add("AwardPlayerAmmo", "AwardPlayerAmmo", function(ply, victim)
        local ShouldAwardPlayerAmmo = hook.Run("ShouldAwardPlayerAmmo", ply)
        if ShouldAwardPlayerAmmo == false then return end
        if victim.DamageContributions[ply] < victim:GetMaxHealth() * RefillConvars.RewardMargin:GetFloat() then return end
        RefillPlayer(ply, victim)
    end)

    hook.Add("RefillAmmo", "RefillAmmo", function(ply)
        RefillAmmo(ply)
        return
    end)

    --[[
    hook.Add("ShouldRewardPlayer", "NoAmmo", function(ply)
        --
        return false
    end)
    --]]
    hook.Add("RewardPlayer", "RewardPlayer", function(ply, victim)
        local ShouldRewardPlayer = hook.Run("ShouldRewardPlayer", ply)
        if ShouldRewardPlayer == false then return end
        hook.Run("AwardPlayerHealth", ply, victim)
        hook.Run("AwardPlayerAmmo", ply, victim)
        victim.DamageContributions = {}
    end)

    hook.Add("PlayerDeath", "RewardPlayer", function(victim, _, attacker)
        if victim ~= attacker then --
            hook.Run("RewardPlayer", attacker, victim)
        end

        victim.LastTickHealth = nil
        victim.DamageContributions = {}
        attacker.DamageContributions = {}
    end)

    local PLAYERMETA = FindMetaTable("Player")
    local ENTMETA = FindMetaTable("Entity")
    if not ENTMETA.oldSetHealth then ENTMETA.oldSetHealth = ENTMETA.SetHealth end
    function ENTMETA:SetHealth(hp)
        ENTMETA.oldSetHealth(self, hp)
        self.LastTickHealth = hp
    end

    function PLAYERMETA:GetSpawnHealth()
        return LoadoutConvars.SpawnHealth:GetInt()
    end

    local Loadout = {
        ["weapon_357"] = 9999,
        ["weapon_ar2"] = 9999,
        ["weapon_crossbow"] = 9999,
        ["weapon_crowbar"] = 9999,
        ["weapon_frag"] = 0,
        ["weapon_physcannon"] = 9999,
        ["weapon_pistol"] = 9999,
        ["weapon_shotgun"] = 9999,
        ["weapon_smg1"] = 9999,
    }

    hook.Add("PlayerLoadout", "GiveSpawnWeapons", function(ply)
        local HookLoadout = hook.Run("GetCustomLoadout", ply) or Loadout
        for weapon, ammocount in pairs(HookLoadout) do
            local weap = ply:Give(weapon)
            if not IsValid(weap) then weap = ply:GetWeapon(weapon) end
            if not IsValid(weap) then continue end
            local AmmoType = weap:GetPrimaryAmmoType()
            ply:SetAmmo(ammocount, AmmoType)
        end

        timer.Simple(0, function() if LoadoutConvars.RefillAmmoOnSpawn:GetBool() == true and hook.Run("ShouldRefillAmmoOnSpawn", ply) ~= false then RefillAmmo(ply) end end)
        ply:SetMaxHealth(hook.Run("GetDamageLogicRules", ply, "MAXHEALTH") or LoadoutConvars.MaxHealth:GetInt())
        ply:SetHealth(hook.Run("GetDamageLogicRules", ply, "SPAWNHEALTH") or LoadoutConvars.SpawnHealth:GetInt())
        ply:SetMaxArmor(hook.Run("GetDamageLogicRules", ply, "MAXARMOR") or LoadoutConvars.MaxArmor:GetInt())
        ply:SetArmor(hook.Run("GetDamageLogicRules", ply, "SPAWNARMOR") or LoadoutConvars.SpawnArmor:GetInt())
        return true
    end)

    local function InformEnemyHealth(victim, attacker)
        victim:ChatPrintColor({"RV_OUTLINESCOLOR", attacker:Nick(), "COLOR_WHITE", " had ", "COLOR_GREEN", tostring(attacker:Health()), "COLOR_WHITE", " health remaining."})
    end

    hook.Add("PlayerDeath", "InformEnemyHealth", function(victim, _, attacker)
        if victim == attacker then return end
        local ShouldInformEnemyHealth = hook.Run("ShouldInformEnemyHealth", victim, attacker)
        if ShouldInformEnemyHealth == false then return end
        InformEnemyHealth(victim, attacker)
    end)
end
