 local RPX,_W=TUNING.modfns["workshop-2038128735"],UTIL.WAVESET
 local GetReforgedSettings,GameplayHasTag,AddReforgedPrefab,AddWaveTimer,SetLeashByID,AdvanceTriggers,PseudoSOS=RPX.GetReforgedSettings,RPX.GameplayHasTag,RPX.AddReforgedPrefab,RPX.AddWaveTimer,RPX.SetLeashByID,RPX.AdvanceTriggers
 local teampresets,PairRhinosByID=RPX.teampresets,RPX.PairRhinosByID
 local BroSetup = RPX.BroSetup


--MOB SPAWNS--

 local rhinopairs={{1,"r0s1",3,"r0s1"}}

 local mob_spawns={}
 mob_spawns[1]={
 	_W.CreateMobSpawnFromPreset("line",_W.CreateMobList(_W.RepeatMob("pitpig",2))),
	_W.CreateMobSpawnFromPreset("square",_W.CreateMobList(_W.RepeatMob("pitpig",4)))
 }
 mob_spawns[2]={
 	_W.CreateMobSpawnFromPreset("squad",_W.CreateMobList("crocommander",_W.RepeatMob("pitpig",3))),
	{{{"pitpig"}}}
 }

 mob_spawns[3]={
 	{
 		_W.CreateMobSpawnFromPreset("line",{"scorpeon","snortoise"}),
 		_W.CreateMobSpawnFromPreset("triangle",_W.CreateMobList("snortoise",_W.RepeatMob("scorpeon",2)),{rotation=240})		
 	},
	{
		_W.CreateMobSpawnFromPreset("triangle",_W.CreateMobList(_W.RepeatMob("pitpig",3)),{rotation=180})
	},
 	_W.CreateMobSpawnFromPreset("line",{"snortoise","scorpeon"},{rotation=180}),
 	_W.CreateMobSpawnFromPreset("squad",_W.CreateMobList("boarilla",_W.RepeatMob("pitpig",3)))
 }


 mob_spawns[4]={
	_W.CreateMobSpawnFromPreset("squad",_W.CreateMobList("boarilla",_W.RepeatMob("pitpig",3))),
	{
		_W.CreateMobSpawnFromPreset("line",{"scorpeon","snortoise"}),
		{{{"crocommander"},{"pitpig",1,1},{"pitpig",1,2}},{{2,3,180}}},
	},
	{	
		_W.CreateMobSpawnFromPreset("squad",_W.CreateMobList("crocommander",_W.RepeatMob("pitpig",3))),
		{{{"crocommander"},{"pitpig",1,1},{"pitpig",1,2}},{{2,3,180}}},
	},
 	_W.CreateMobSpawnFromPreset("squad",_W.CreateMobList("boarrior",_W.RepeatMob("pitpig",3))),
	_W.CreateMobSpawnFromPreset("line",_W.CreateMobList(_W.RepeatMob("pitpig",2))),
	{{{"crocommander"},{"pitpig",1,1},{"pitpig",1,2}},{{2,3,180}}},
 }
 mob_spawns[5]={
	_W.CreateMobSpawnFromPreset("squad",_W.CreateMobList("rhinocebro",_W.RepeatMob("pitpig",3))),
	_W.CreateMobSpawnFromPreset("squad",_W.CreateMobList("rhinocebro2",_W.RepeatMob("pitpig",3))),
	_W.CreateMobSpawnFromPreset("squad",_W.CreateMobList("crocommander",_W.RepeatMob("pitpig",3))),
 }
 mob_spawns[6]={
	_W.CreateMobSpawnFromPreset("squad",_W.CreateMobList("swineclops",_W.RepeatMob("pitpig",3))),
	{
		_W.CreateMobSpawnFromPreset("triangle",_W.CreateMobList(_W.RepeatMob("pitpig",3))),
		_W.CreateMobSpawnFromPreset("squad",_W.CreateMobList("snortoise",_W.RepeatMob("pitpig",3)),{rotation=180})
	},
	{
		{{{"pitpig"}}},
		_W.CreateMobSpawnFromPreset("line",_W.CreateMobList("snortoise","pitpig"),{rotation=180})
	}
}



  --PRE

 local AddSnortoise=function(inst)
	inst.components.combat:ToggleAttack("spin",true)
	inst.components.combat.ignorehitrange=true
 end
 AddReforgedPrefab("snortoise",AddSnortoise)


 AddReforgedPrefab("crocommander",nil,function(inst) inst:HardNoInit() if inst.reinforcements then inst.reinforcements.min_followers=-1 end end)

 
	
 

 --FNS


 local function LeashPitpigsToCrocs(spawnedmobs)
    for i,mob_list in pairs(spawnedmobs) do
        local mobs = _W.OrganizeMobs(mob_list)
        if mobs then
            _W.LeashMobs(mobs.crocommander and mobs.crocommander[1], mobs.pitpig)
        end
    end
 end


--ITEM DROPS--

 local item_drops={
	[1]={[1]={}},
 	[2]={[1]={}},
 	[3]={},
 	[4]={},
 	[5]={}
 }
 item_drops[1][1].final_mob={"firebomb","moltendarts"}
 item_drops[2][1].random_mob={"noxhelm","silkengrandarmor"}
 item_drops[2][1].final_mob={"whisperinggrandarmor","steadfastarmor","infernalstaff"}
 item_drops[3].round_end={"steadfastgrandarmor","clairvoyantcrown","blacksmithsedge"}
 item_drops[4].round_end={"jaggedgrandarmor","silkengrandarmor"}

 local character_tier_opts={
 	[1]={round=1},
 	[2]={round=2},
 	[3]={round=3,force_items={"moltendarts"}}
 }

 local heal_opts={
 	dupe_rate=0.2,
 	drops={heal={round=1,wave=1,type="final_mob",force_items={"livingstaff"}}}
 }

 local AddGolemOrJagged=function(item_set,waves,item_count)
 	if item_count==1 then 
 		table.insert(item_set,"bacontome")
 		table.insert(item_set,"jaggedgrandarmor")
 		table.insert(waves,{3,1})
 		table.insert(waves,{3,1})
 		table.insert(waves,{3,2})
 	end
 end

 local ApplyRandomItemDropSpread=function(item_drops)
 	_W.SpreadItemSetOverWaves(item_drops,{"barbedhelm","crystaltiara","jaggedarmor","silkenarmor","featheredwreath"},{{1,1},{1,1},{1,2},{1,2},{1,2}},"random_mob",1)
 	_W.SpreadItemSetOverWaves(item_drops,{"splintmail"},{{2,1}},"random_mob",1)
 	_W.SpreadItemSetOverWaves(item_drops,{"flowerheadband","wovengarland"},{{2,1}},"random_mob",1,AddGolemOrJagged)
 	_W.SpreadItemSetOverWaves(item_drops,{"resplendentnoxhelm","blossomedwreath"},{{4,3},{4}},"final_mob",1)
 end

--WAVESET DATA--

 local waveset_data={
 	item_drops=item_drops,
 	item_drop_options={
 		character_tier_opts=character_tier_opts,
 		heal_opts=heal_opts,
  		generate_item_drop_list_fn=_W.GenerateItemDropList,
 		random_item_spread_fn=ApplyRandomItemDropSpread
 	},
 	endgame_speech={victory={speech="BOARLORD_ROUND7_PLAYER_VICTORY"},defeat={speech="BOARLORD_PLAYERS_DEFEATED_BATTLECRY"}}
 }
 
 waveset_data[1]={
 	waves={},
 	wavemanager={onspawningfinished={}}
 }

 waveset_data[1].wavemanager.dialogue={
	[1]={speech="BOARLORD_ROUND1_START"},[2]={speech="BOARLORD_ROUND1_FIGHT_BANTER",is_banter=true}
}

 for i=1,2 do 
 	waveset_data[1].waves[i]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[1][i]),{1,2,3}})
 end
 waveset_data[1].waves[1]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[1][1]),{1,3}},{_W.CreateSpawn(mob_spawns[1][1],180),{2}})

 waveset_data[2]={
 	waves={},
	wavemanager={onspawningfinished={}}
 }
 waveset_data[2].wavemanager.dialogue={
	[1]={speech="BOARLORD_ROUND2_START"}
}
 	waveset_data[2].waves[1]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[2][1]),{1,3}})
	waveset_data[2].waves[2]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[2][2]),{1,2,3}})
	waveset_data[2].wavemanager.onspawningfinished[1]=function(self,spawnedmobs)
		LeashPitpigsToCrocs(spawnedmobs)
		AddWaveTimer(self,6,2)
 	end

	waveset_data[2].wavemanager.onspawningfinished[2]=function(self,spawnedmobs)
 		RemoveTask(self.timers.queue_next_wave)
	end

 waveset_data[3]={
 	waves={},
 	wavemanager={onspawningfinished={}}
 }
 waveset_data[3].wavemanager.dialogue={
 	[1]={speech="BOARLORD_ROUND4_START"},
 	[3]={speech="BOARLORD_ROUND4_FIGHT_BANTER",is_banter=true},
 	[4]={pre_delay=0,speech="BOARLORD_ROUND4_TRAILS_INTRO"}
 }
 waveset_data[3].waves[1]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[3][1][1]),{1,3}},{_W.CreateSpawn(mob_spawns[3][1][2]),{2}})
 waveset_data[3].waves[2]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[3][2][1], 180), {1,3}}, {_W.CreateSpawn(mob_spawns[3][2][1], 180), {2}})
 waveset_data[3].wavemanager.onspawningfinished[1]=function(self,spawnedmobs)
	AddWaveTimer(self,6,2)
 end
 waveset_data[3].wavemanager.onspawningfinished[2]=function(self,spawnedmobs)
	RemoveTask(self.timers.queue_next_wave)
 end
 waveset_data[3].waves[3]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[3][3]),{1,3}})
 waveset_data[3].waves[4]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[3][4]),{2}})
 waveset_data[3].wavemanager.onspawningfinished[3]=function(self,spawnedmobs)
 	AddWaveTimer(self,15,4)
 end
 waveset_data[3].wavemanager.onspawningfinished[4]=function(self,spawnedmobs)
 	RemoveTask(self.timers.queue_next_wave)
 end

 waveset_data[4]={
 	waves={},
 	wavemanager={onspawningfinished={}}
 }
 waveset_data[4].wavemanager.dialogue={
 	[1]={pre_delay=3.5,speech="BOARLORD_ROUND5_START"},
 	[2]={pre_delay=0.5,speech="BOARLORD_ROUND5_FIGHT_BANTER1",is_banter=true},
 	[4]={pre_delay=0.5,speech="BOARLORD_ROUND5_FIGHT_BANTER2",is_banter=true},
	[6]={pre_delay=3.5,speech="BOARLORD_ROUND5_BOARRIOR_INTRO"}
 }
 waveset_data[4].waves[1]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[4][1]),{2}})
 waveset_data[4].waves[2]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[4][2][1]),{1,3}})
 waveset_data[4].waves[3]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[4][2][2]),{2}})
 waveset_data[4].waves[4]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[4][3][1]),{1,3}})
 waveset_data[4].waves[5]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[4][3][2]),{2}})
 waveset_data[4].waves[6]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[4][4]),{2}})
 waveset_data[4].waves[7]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[4][5]),{1,2,3}})
 waveset_data[4].waves[8]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[4][6]),{2}})


 waveset_data[4].wavemanager.onspawningfinished = {
    [1]=function(self,spawnedmobs)
        local boarillas = _W.OrganizeAllMobs(spawnedmobs).boarilla
        local bs=#boarillas
        self.health_triggers.boarillas = {
            [1]={total_percent=bs*0.9,fn=function()
                self:QueueWave(2)
            end},
            [2]={total_percent=bs*0.5,fn=function()
                if self:GetCurrentWave() == 2 then
                    self:QueueWave(3)
                end
                self:QueueWave(4)
            end},
            [3]={total_percent=bs*0.25,fn=function()
                if self:GetCurrentWave() == 4 then
                    self:QueueWave(5)
                end
                self:QueueWave(6)
            end},
        }
        _W.AddHealthTriggers(self.health_triggers.boarillas, unpack(boarillas))
    end,
    [2]=function(self,spawnedmobs)
        self.timers.queue_next_wave = self.inst:DoTaskInTime(6, function()
            self:QueueWave(3)
        end)
    end,
    [3]=function(self,spawnedmobs)
		LeashPitpigsToCrocs(spawnedmobs)
        RemoveTask(self.timers.queue_next_wave)
    end,
    [4]=function(self,spawnedmobs)
		LeashPitpigsToCrocs(spawnedmobs)
        self.timers.queue_next_wave = self.inst:DoTaskInTime(6, function()
            self:QueueWave(5)
        end)
    end,
    [5]=function(self,spawnedmobs)
		LeashPitpigsToCrocs(spawnedmobs)
        RemoveTask(self.timers.queue_next_wave)		
	end,
	[6]=function(self,spawnedmobs)
		local boarriors = _W.OrganizeAllMobs(spawnedmobs).boarrior
		local br=#boarriors
			self.health_triggers.boarriors = {
				[1]={total_percent=br*0.75,fn=function()
					self:QueueWave(7)
				end},
				[2]={total_percent=br*0.25,fn=function()
					self:QueueWave(8)
				end},
			}
		_W.AddHealthTriggers(self.health_triggers.boarriors, unpack(boarriors))
	end,
	[8]=function(self,spawnedmobs)
		LeashPitpigsToCrocs(spawnedmobs)
	end,
}
 	
waveset_data[5]={
	waves={},
	wavemanager={onspawningfinished={}}
}
waveset_data[5].wavemanager.dialogue={
	[1]={speech="BOARLORD_ROUND6_START"}
}
	waveset_data[5].waves[1]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[5][1]),{1}},{_W.CreateSpawn(mob_spawns[5][2]),{3}})
	waveset_data[5].waves[2]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[5][3]),{1,3}})
		
	waveset_data[5].wavemanager.onspawningfinished[1]=function(self,spawnedmobs)
		PairRhinosByID(spawnedmobs,rhinopairs)
		local mobs = _W.OrganizeAllMobs(spawnedmobs)
		TableConcat(mobs.rhinocebro, mobs.rhinocebro2)
		local rhinos = mobs.rhinocebro
		local rh=#rhinos
		self.health_triggers.rhinos = {
			[1]={total_percent=rh*0.2,fn=function()
			self:QueueWave(2)
			end}
		}
	_W.AddHealthTriggers(self.health_triggers.rhinos, unpack(rhinos))
    end

	waveset_data[5].wavemanager.onspawningfinished[2]=function(self,spawnedmobs)
		LeashPitpigsToCrocs(spawnedmobs)
	end	

 waveset_data[6]={
 	waves={},
 	wavemanager={onspawningfinished={}}
 }
 waveset_data[6].wavemanager.dialogue={
	[1]={pre_delay=3.5,speech="BOARLORD_ROUND7_START"},
	[2]={pre_delay=0.5,speech="BOARLORD_ROUND5_FIGHT_BANTER1",is_banter=true},
    --[3]={pre_delay=3.5,speech="BOARLORD_ROUND4_FIGHT_BANTER",is_banter=true}
 }

 waveset_data[6].waves[1]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[6][1]),{2}})
 waveset_data[6].waves[2]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[6][2][1]),{1,2,3}},{_W.CreateSpawn(mob_spawns[6][2][2]),{2}})
 waveset_data[6].waves[3]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[6][3][1]),{1,2,3}},{_W.CreateSpawn(mob_spawns[6][2][2]),{2}})

 waveset_data[6].wavemanager.onspawningfinished = {
    [1]=function(self,spawnedmobs)
        local swine = _W.OrganizeAllMobs(spawnedmobs).swineclops
        local sw=#swine
        self.health_triggers.swine = {
            [1]={total_percent=sw*0.8,fn=function()
                self:QueueWave(2)
            end},
            [2]={total_percent=sw*0.25,fn=function()
                self:QueueWave(3)
            end},
        }
        _W.AddHealthTriggers(self.health_triggers.swine, unpack(swine))
    end,
 }

 return waveset_data