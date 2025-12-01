local _W = _G.UTIL.WAVESET
local boarilla_tuning = TUNING.INFORGE.LIFEBLOOM_BOARILLA

----------------
-- MOB SPAWNS --
----------------
local mob_spawns = {}

mob_spawns[1] = {
    {{{"boarilla"}}},
    {{{"snortoise"}}}
}

mob_spawns[2] = {
    {{{"pitpig"}}}
}

----------------
-- ITEM DROPS --
----------------

local item_drops = {
    [1] = {},
    [2] = {},
}

local function ApplyRandomItemDropSpread(item_drops)
    --[[
    -- RANDOM: Round 1 Wave 2-4 - 3 | Round 2 Wave 1-2 - 2
    _W.SpreadItemSetOverWaves(item_drops, {"barbedhelm", "crystaltiara", "jaggedarmor", "silkenarmor", "featheredwreath"}, {{1,2},{1,3},{1,4},{2,1},{2,2}}, "random_mob", 1)
    -- RANDOM: Round 2 Wave 1-2
    _W.SpreadItemSetOverWaves(item_drops, {"splintmail"}, {{2,1},{2,2}}, "random_mob", 1)
    -- RANDOM: Round 3 Wave 1 | Round 4 Wave 1
    _W.SpreadItemSetOverWaves(item_drops, {"flowerheadband", "wovengarland"}, {{3,1},{4,1}}, "random_mob", 1)
    ]]--
end

local character_tier_opts = {
    [1] = {round = 2},
    --[3] = {round = 4, force_items = {"moltendarts"}},

}
local heal_opts = {
    dupe_rate = 0.2,
    drops = {
        heal = {round = 1, wave = 1, type = "final_mob", force_items = {"livingstaff"}}
    },
}

----------------
-- CUSTOM FNS --
----------------
-- Leashes all pitpigs to the first croc on each spawner
local function LeashPitpigsToCrocs(spawnedmobs)
    for i,mob_list in pairs(spawnedmobs) do
        local mobs = _W.OrganizeMobs(mob_list)
        if mobs then
            _W.LeashMobs(mobs.crocommander and mobs.crocommander[1], mobs.pitpig)
        end
    end
end

-- Sets the appearance of the boarilla
local function SetBoarillasVariance(boarillas, variation)
    local non_duped_boarilla_count = 0
    for i,boarilla in pairs(boarillas) do
        if not boarilla.duplicator_source then
            non_duped_boarilla_count = non_duped_boarilla_count + 1
            boarilla:SetVariation(variation or non_duped_boarilla_count)
        end
    end
end

------------------
-- WAVESET DATA --
------------------

local function CheckMobAfterOneFrame(spawnedmobs, mob_name)
    local name_mobs = {}
    for i, moblist in pairs(spawnedmobs) do
        for mob in pairs(moblist) do
            if mob.prefab == mob_name then
                table.insert(name_mobs,mob)
            end
        end
    end
    return name_mobs
end


local function PhaseImmuneDamage(inst, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
    return inst.sg:HasStateTag("hiding")
end

local function ChangeState_Boarilla(spawnedmobs)
    local all_boarillas = CheckMobAfterOneFrame(spawnedmobs, "boarilla")

    for i,boarilla in pairs(all_boarillas) do
        boarilla:SetStateGraph("SGlifebloom_boarilla")
        boarilla:SetBrain(require("brains/lifebloom_boarillabrain"))

        boarilla.components.health:SetMaxHealth(boarilla_tuning.HEALTH)
        boarilla.components.combat:SetDefaultDamage(boarilla_tuning.DAMAGE)

        boarilla.components.health.redirect = PhaseImmuneDamage
    end
end

local function ChangeState_Snortoise(spawnedmobs, self)
    local all_snortioses = CheckMobAfterOneFrame(spawnedmobs, "snortoise")

    for i,snortoise in pairs(all_snortioses) do
        snortoise:SetStateGraph("SGlifebloom_snortoise")

        snortoise.components.combat:ToggleAttack("spin",true)
        snortoise.components.combat.ignorehitrange=true

        snortoise:ListenForEvent("death",function(inst)
            local other_mobs = TheSim:FindEntities(0, 0, 0, 999, {"LA_mob"})
            local is_snortoise_all_dead = true

            for i,mob in pairs(other_mobs) do
                if mob.prefab == "snortoise" and not mob.components.health:IsDead() then
                    is_snortoise_all_dead = false
                end
            end

            if is_snortoise_all_dead then
                _G.TheWorld.components.lavaarenaevent:QueueWave(nil,true,{
                    name="boarilla_reinforce_1",
                    mob_spawns=_W.SetSpawn({_W.CreateSpawn(mob_spawns[1][2]),{1,2,3}}),
                    onspawningfinished = function(self, spawnedmobs)
                        ChangeState_Snortoise(spawnedmobs)
                    end,
                })
            end
        end)
    end
end

local boarilla_reinforce_1 = {
    name="boarilla_reinforce_1",
    mob_spawns=_W.SetSpawn({_W.CreateSpawn(mob_spawns[1][2]),{1,2,3}}),
    onspawningfinished = function(self, spawnedmobs)
        ChangeState_Snortoise(spawnedmobs)
    end,
}

local waveset_data = {
    { -- Round 1
        waves = {
            _W.SetSpawn({_W.CreateSpawn(mob_spawns[1][1]), {2}}), 
        },
        wavemanager = {
            dialogue = {
                --[1] = {speech = "BOARLORD_ROUND1_START"},
            },
            onspawningfinished = {
                [1] = function(self, spawnedmobs)
                    ChangeState_Boarilla(spawnedmobs)
                    ChangeState_Snortoise(spawnedmobs,self)
                    
                    self.inst:DoTaskInTime(0,function()
                        local boaril = _W.OrganizeAllMobs(spawnedmobs).boarilla
                        local bl=#boaril
                        self.health_triggers.boaril = {
                            [1]={total_percent=bl*0.5,fn=function()
                                self:QueueWave(nil,true,boarilla_reinforce_1)
                            end},
                        }
                        _W.AddHealthTriggers(self.health_triggers.boaril, unpack(boaril))
                    end)
                end,
            },
        },
    },{ -- Round 2
        waves = {
            _W.SetSpawn({_W.CreateSpawn(mob_spawns[2][1]), {1,3}}),
        },
        wavemanager = {
            dialogue = {
                --[1] = {speech = "BOARLORD_ROUND2_START"},
                --[2] = {speech = "BOARLORD_ROUND2_FIGHT_BANTER", is_banter = true},
            },
            onspawningfinished = {},
        },
    },
    item_drops = item_drops,
    item_drop_options = {
        character_tier_opts = character_tier_opts,
        heal_opts           = heal_opts,
        generate_item_drop_list_fn = _W.GenerateItemDropList,
        random_item_spread_fn      = ApplyRandomItemDropSpread,
    },
    endgame_speech = {
        victory = {
            speech = "BOARLORD_ROUND4_PLAYER_VICTORY",
        },
        defeat = {
            speech = "BOARLORD_PLAYERS_DEFEATED_BATTLECRY",
        },
    },
}

return waveset_data
