local _W = _G.UTIL.WAVESET

----------------
-- MOB SPAWNS --
----------------
local mob_spawns = {
    [1] = {
        {{{"pitpig"},}},                                                                        
        _W.CreateMobSpawnFromPreset("line", _W.CreateMobList(_W.RepeatMob("pitpig", 2))),       
        _W.CreateMobSpawnFromPreset("triangle", _W.CreateMobList(_W.RepeatMob("pitpig", 3))),   
        _W.CreateMobSpawnFromPreset("square", _W.CreateMobList(_W.RepeatMob("pitpig", 4))),     
    }, [2] = {
        --_W.CreateMobSpawnFromPreset("flag", _W.CreateMobList("crocommander", _W.RepeatMob("pitpig", 3))),
        _W.CombineMobSpawns(_W.CreateMobSpawnFromPreset("triangle", _W.CreateMobList(_W.RepeatMob("pitpig", 3))), {{{"crocommander"},}}) 
    }, [3] = {
        _W.CreateMobSpawnFromPreset("line", _W.CreateMobList(_W.RepeatMob("snortoise", 2))),    
        _W.CreateMobSpawnFromPreset("triangle", _W.CreateMobList(_W.RepeatMob("snortoise", 3)), {rotation = 180}),
    }, [4] = {
        _W.CreateMobSpawnFromPreset("line", _W.CreateMobList(_W.RepeatMob("scorpeon", 2))), 
        _W.CreateMobSpawnFromPreset("triangle", _W.CreateMobList(_W.RepeatMob("scorpeon", 3)), {rotation = 180}),
        _W.CreateMobSpawnFromPreset("line", {"snortoise", "scorpeon"}),
        {{{"boarilla"},}},
    }
}

----------------
-- ITEM DROPS --
----------------

local item_drops = {
    [1] = {
        [3] = {
            --final_mob = {"livingstaff"}
        },
    },
    [2] = {
        [2] = {
            final_mob = {"moltendarts"}
        },
    },
    [3] = {
        [1] = {
            random_mob = {"noxhelm", _W.ChooseRandomItem("silkenarmor", "jaggedarmor")},
            final_mob = {"steadfastarmor", "infernalstaff"},
        },
    },
}

local function ApplyRandomItemDropSpread(item_drops)
    -- RANDOM: Round 1 Wave 2-4 - 3 | Round 2 Wave 1-2 - 2
    _W.SpreadItemSetOverWaves(item_drops, {"barbedhelm", "crystaltiara", "jaggedarmor", "silkenarmor", "featheredwreath"}, {{1,2},{1,3},{1,4},{2,1},{2,2}}, "random_mob", 1)
    -- RANDOM: Round 2 Wave 1-2
    _W.SpreadItemSetOverWaves(item_drops, {"splintmail"}, {{2,1},{2,2}}, "random_mob", 1)
    -- RANDOM: Round 3 Wave 1 | Round 4 Wave 1
    _W.SpreadItemSetOverWaves(item_drops, {"flowerheadband", "wovengarland"}, {{3,1},{4,1}}, "random_mob", 1)
end

local character_tier_opts = {
    [1] = {round = 2},
    [2] = {round = 3},
    [3] = {round = 4, force_items = {"moltendarts"}},

}
local heal_opts = {
    dupe_rate = 0.2,
    drops = {
        heal = {round = 1, wave = 3, type = "final_mob", force_items = {"livingstaff"}}
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
local waveset_data = {
    { -- Round 1
        waves = {
            _W.SetSpawn({_W.CreateSpawn(mob_spawns[1][1]), {1,2,3}}), -- Wave 1
            _W.SetSpawn({_W.CreateSpawn(mob_spawns[1][2]), {1,2,3}}), -- Wave 2
            _W.SetSpawn({_W.CreateSpawn(mob_spawns[1][3]), {1,3}}, {_W.CreateSpawn(mob_spawns[1][3], 180), {2}}), -- Wave 3
            _W.SetSpawn({_W.CreateSpawn(mob_spawns[1][4]), {1,2,3}}), -- Wave 4
        },
        wavemanager = {
            dialogue = {
                [1] = {speech = "BOARLORD_ROUND1_START"},
                [4] = {speech = "BOARLORD_ROUND1_FIGHT_BANTER", is_banter = true},
            },
        },
    },{ -- Round 2
        waves = {
            _W.SetSpawn({_W.CreateSpawn(mob_spawns[2][1]), {1,3}}), -- Wave 1
            _W.SetSpawn({_W.CreateSpawn(mob_spawns[2][1]), {1,3}}), -- Wave 2
        },
        wavemanager = {
            dialogue = {
                [1] = {speech = "BOARLORD_ROUND2_START"},
                [2] = {speech = "BOARLORD_ROUND2_FIGHT_BANTER", is_banter = true},
            },
            onspawningfinished = {
                [1] = function(self, spawnedmobs)
                    LeashPitpigsToCrocs(spawnedmobs)
                end,
                [2] = function(self, spawnedmobs)
                    LeashPitpigsToCrocs(spawnedmobs)
                end,
            },
        },
    },{ -- Round 3
        waves = {
            _W.SetSpawn({_W.CreateSpawn(mob_spawns[3][1]), {1,3}}, {_W.CreateSpawn(mob_spawns[3][2]), {2}}), -- Wave 1
        },
        wavemanager = {
            dialogue = {
                [1] = {speech = "BOARLORD_ROUND3_START"},
            },
        },
    },{ -- Round 4
        waves = {
            _W.SetSpawn({_W.CreateSpawn(mob_spawns[4][1]), {1,3}}, {_W.CreateSpawn(mob_spawns[4][2]), {2}}), -- Wave 1
            _W.SetSpawn({_W.CreateSpawn(mob_spawns[4][3]), {1,3}}), -- Wave 2
            _W.SetSpawn({_W.CreateSpawn(mob_spawns[4][4]), {2}}),   -- Wave 3
        },
        wavemanager = {
            dialogue = {
                [1] = {speech = "BOARLORD_ROUND4_START"},
                [2] = {speech = "BOARLORD_ROUND4_FIGHT_BANTER", is_banter = true},
                [3] = {pre_delay = 0, speech = "BOARLORD_ROUND4_TRAILS_INTRO"},
            },
            onspawningfinished = {
                [2] = function(self, spawnedmobs)
                    -- Spawn wave 3 15 seconds after wave 2
                    self.timers.queue_next_wave = self.inst:DoTaskInTime(15, function()
                        self:QueueWave(3)
                    end)
                end,
                [3] = function(self, spawnedmobs)
                    -- Remove timer if wave was triggered before timer completed
                    RemoveTask(self.timers.queue_next_wave)
                    -- Give each Boarilla a unique look
                    local boarillas = _W.OrganizeAllMobs(spawnedmobs).boarilla
                    SetBoarillasVariance(boarillas, 3)
                end,
            },
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
