local _W = _G.UTIL.WAVESET
local boarilla_tuning = TUNING.INFORGE.LIFEBLOOM_BOARILLA

----------------
-- MOB SPAWNS --
----------------
local mob_spawns = {}

mob_spawns[1] = {
    {{{"boarilla"}}}
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
    for i, moblist in pairs(spawnedmobs) do
        for mob in pairs(moblist) do
            print(mob.prefab)
            if mob.prefab == mob_name then
                return mob
            end
        end
        return false
    end
end

local function ChangeState_Boarilla(spawnedmobs)
    local boarilla = CheckMobAfterOneFrame(spawnedmobs, "boarilla")

    if boarilla then
        boarilla:SetStateGraph("SGlifebloom_boarilla")
        boarilla:SetBrain(require("brains/lifebloom_boarillabrain"))

        boarilla.components.health:SetMaxHealth(boarilla_tuning.HEALTH)
        boarilla.components.combat:SetDefaultDamage(boarilla_tuning.DAMAGE)
    end
end

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
