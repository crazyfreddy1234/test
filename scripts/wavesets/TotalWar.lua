 local RPX,_W=TUNING.modfns["workshop-2038128735"],UTIL.WAVESET
 local GetReforgedSettings,GameplayHasTag,AddReforgedPrefab,AddWaveTimer,SetLeashByID,AdvanceTriggers,PseudoSOS=RPX.GetReforgedSettings,RPX.GameplayHasTag,RPX.AddReforgedPrefab,RPX.AddWaveTimer,RPX.SetLeashByID,RPX.AdvanceTriggers
 local teampresets,PairRhinosByID=RPX.teampresets,RPX.PairRhinosByID
 local BroSetup = RPX.BroSetup

--MOB SPAWNS--

 local rhinopairs={{1,"r0s1",3,"r0s1"}}

 local AddSnortoise=function(inst)
	inst.components.combat:ToggleAttack("spin",true)
	inst.components.combat.ignorehitrange=true
 end

 local AddCrocommander=function(inst)

 end

 local AddHardCrocommander=function(inst)
	if not GameplayHasTag("difficulty","hard") then return inst end
	inst.reinforcements.min_followers=-1
 end
 
 AddReforgedPrefab("snortoise",AddSnortoise)
 AddReforgedPrefab("crocommander",AddCrocommander,AddHardCrocommander)

 local mob_spawns={}
 mob_spawns[1]={
 	_W.CreateMobSpawnFromPreset("square",_W.CreateMobList(_W.RepeatMob("pitpig",4))),
	{{{"scorpeon"}}},
	_W.CreateMobSpawnFromPreset("line",{"crocommander","snortoise"}),
 }

 mob_spawns[2]={
	{{{"rhinocebro"}}},
	_W.CreateMobSpawnFromPreset("squad",_W.CreateMobList("crocommander",_W.RepeatMob("pitpig",3))),
	_W.CreateMobSpawnFromPreset("line",{"scorpeon","snortoise"}),
	{{{"scorpeon"}}},
	_W.CreateMobSpawnFromPreset("line",_W.CreateMobList(_W.RepeatMob("pitpig",2))),
	_W.CreateMobSpawnFromPreset("square",_W.CreateMobList(_W.RepeatMob("pitpig",4))),
 }

 mob_spawns[3]={
	{{{"boarilla"}}},
	{{{"boarrior"}}},
	{{{"swineclops"}}},
	{{{"rhinocebro"}}},
 	{{{"rhinocebro2"}}},
	_W.CreateMobSpawnFromPreset("square",{"pitpig","crocommander","scorpeon","snortoise"}),
	_W.CreateMobSpawnFromPreset("line",{"crocommander","snortoise"}),
	_W.CreateMobSpawnFromPreset("square",_W.CreateMobList(_W.RepeatMob("pitpig",4))),
	{{{"crocommander"}}},
	_W.CreateMobSpawnFromPreset("square",_W.CreateMobList(_W.RepeatMob("pitpig",4))),
	_W.CreateMobSpawnFromPreset("triangle",{"pitpig","pitpig","scorpeon"}),
	_W.CreateMobSpawnFromPreset("line",{"scorpeon","crocommander"}),
	_W.CombineMobSpawns(
		{{{"crocommander"}}},
		_W.CreateMobSpawnFromPreset("circle",_W.CreateMobList(_W.RepeatMob("pitpig",6)))
 	)
 }

 local rhino_reinforce_4 = {
	name="rhino_reinforce_4",
	mob_spawns=_W.SetSpawn({_W.CreateSpawn(mob_spawns[2][6]),{1,2,3}}),
 }

 local rhino_reinforce_3 = {
	name="rhino_reinforce_3",
	mob_spawns=_W.SetSpawn({_W.CreateSpawn(mob_spawns[2][5]),{1,2,3}}),
	onspawningfinished = function(self, spawnedmobs)
		local function SpawnReinforcements(inst)
			self.timers.reinforcements=inst:DoTaskInTime(60,function()
				if self:GetCurrentRound()==2 then 
					self:QueueWave(nil,true,rhino_reinforce_4)
					SpawnReinforcements(inst)
				end
			end)
		end
		SpawnReinforcements(self.inst)
	end,
 }

 local rhino_reinforce_2 = {
	name="rhino_reinforce_2",
	mob_spawns=_W.SetSpawn({_W.CreateSpawn(mob_spawns[2][4]),{1,2,3}}),
	onspawningfinished = function(self, spawnedmobs)
		self.timers.queue_next_wave = self.inst:DoTaskInTime(3, function()
			self:QueueWave(nil,true,rhino_reinforce_3)
		end)
	end,
 }

 local rhino_reinforce_1 = {
	name="rhino_reinforce_1",
	mob_spawns=_W.SetSpawn({_W.CreateSpawn(mob_spawns[2][2]),{1,3}},{_W.CreateSpawn(mob_spawns[2][3]),{2}}),
	onspawningfinished = function(self, spawnedmobs)
		self.timers.queue_next_wave = self.inst:DoTaskInTime(3, function()
			self:QueueWave(nil,true,rhino_reinforce_2)
		end)
	end,
 }

 local boarilla_reinforce_1 = {
	name="boarilla_reinforce_1",
	mob_spawns=_W.SetSpawn({_W.CreateSpawn(mob_spawns[3][4]),{1}},{_W.CreateSpawn(mob_spawns[3][5]),{3}},{_W.CreateSpawn(mob_spawns[3][6]),{2}}),
	onspawningfinished = function(self, spawnedmobs)
		local organized_mobs = _W.OrganizeAllMobs(spawnedmobs)
	
		for i,rhinocebro in pairs(organized_mobs.rhinocebro) do
			local rhinocebro2 = organized_mobs.rhinocebro2[i]
			if rhinocebro2 then
				rhinocebro.bro = rhinocebro2
				rhinocebro2.bro = rhinocebro
			end
		end
	end,
 }

 local boarilla_reinforce_2 = {
	name="boarilla_reinforce_2",
	mob_spawns=_W.SetSpawn({_W.CreateSpawn(mob_spawns[3][7]),{1,3}})
 }

 local boarrior_reinforce = {
	name="boarrior_reinforce",
	mob_spawns=_W.SetSpawn({_W.CreateSpawn(mob_spawns[3][8]),{1,2,3}})
 }

 local swineclops_reinforce_3 = {
	name="swineclops_reinforce_3",
	mob_spawns=_W.SetSpawn({_W.CreateSpawn(mob_spawns[3][11]),{1,2,3}})
 }

 local swineclops_reinforce_2 = {
	name="swineclops_reinforce_2",
	mob_spawns=_W.SetSpawn({_W.CreateSpawn(mob_spawns[3][10]),{1,2,3}}),
	onspawningfinished = function(self, spawnedmobs)
		self.timers.queue_next_wave = self.inst:DoTaskInTime(3, function()
			self:QueueWave(nil,true,swineclops_reinforce_3)
		end)
	end,
 }

 local swineclops_reinforce_1 = {
	name="swineclops_reinforce_1",
	mob_spawns=_W.SetSpawn({_W.CreateSpawn(mob_spawns[3][9]),{1,2,3}}),
	onspawningfinished = function(self, spawnedmobs)
		self.timers.queue_next_wave = self.inst:DoTaskInTime(3, function()
			self:QueueWave(nil,true,swineclops_reinforce_2)
		end)
	end,
 }

 local swineclops_reinforce_4 = {
	name="swineclops_reinforce_4",
	mob_spawns=_W.SetSpawn({_W.CreateSpawn(mob_spawns[3][12]),{1,3}},{_W.CreateSpawn(mob_spawns[3][13]),{2}})
 }


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
	[1]={[1]={},[3]={}},
	[2]={[1]={},[2]={},[3]={},[4]={}},
}
 item_drops[1][1].random_mob={"moltendarts","splintmail","barbedhelm","crystaltiara","jaggedarmor","silkenarmor","featheredwreath"}
 item_drops[1][1].final_mob={"infernalstaff"}
 item_drops[1][3].final_mob={"firebomb","steadfastarmor","flowerheadband","wovengarland","noxhelm","clairvoyantcrown"}
 item_drops[1].round_end={"infernalstaff","jaggedgrandarmor","whisperinggrandarmor"}
 item_drops[2][1].final_mob={"silkengrandarmor","bacontome","clairvoyantcrown"}
 item_drops[2].round_end={"steadfastgrandarmor","blacksmithsedge","blacksmithsedge","resplendentnoxhelm","blossomedwreath","jaggedgrandarmor","silkengrandarmor"}
 
 local character_tier_opts={
 	[2]={round=1},
 	[3]={round=2,force_items={"moltendarts"}}
 }

 local heal_opts={
 	dupe_rate=0.2,
 	drops={heal={round=1,wave=2,type="final_mob",force_items={"livingstaff"}}}
 }

 local ApplyRandomItemDropSpread=function(item_drops)
 	
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
	[1]={speech="BOARLORD_ROUND1_START"},
}

 waveset_data[1].waves[1]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[1][1]),{1,3}})
 waveset_data[1].waves[2]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[1][2]),{2}})
 waveset_data[1].waves[3]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[1][1]),{2}},{_W.CreateSpawn(mob_spawns[1][3]),{1,3}})

 waveset_data[1].wavemanager.onspawningfinished[1]=function(self,spawnedmobs)
	AddWaveTimer(self,3,2)
end

waveset_data[1].wavemanager.onspawningfinished[2]=function(self,spawnedmobs)
	RemoveTask(self.timers.queue_next_wave)
	self.inst:DoTaskInTime(0,function()
		local scor = _W.OrganizeAllMobs(spawnedmobs).scorpeon
			local sc=#scor or 1
			self.health_triggers.scor = {
				[1]={total_percent=sc*0.5,fn=function()
					self:QueueWave(3)
				end},
			}
		_W.AddHealthTriggers(self.health_triggers.scor, unpack(scor))
	end)
end

waveset_data[2]={
	waves={},
	wavemanager={onspawningfinished={}}
}

waveset_data[2].wavemanager.dialogue={
	[1]={speech="BOARLORD_ROUND4_START"},
}

waveset_data[2].waves[1]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[2][1]),{2}})

waveset_data[2].wavemanager.onspawningfinished[1]=function(self,spawnedmobs)
	self.inst:DoTaskInTime(0,function()
		local rhino = _W.OrganizeAllMobs(spawnedmobs).rhinocebro
			local rh=#rhino or 1
			self.health_triggers.rhino = {
				[1]={total_percent=rh*0.5,fn=function()
					self:QueueWave(nil,true,rhino_reinforce_1)
				end},
			}
		_W.AddHealthTriggers(self.health_triggers.rhino, unpack(rhino))
	end)
end

waveset_data[3]={
	waves={},
	wavemanager={onspawningfinished={}}
}

waveset_data[3].wavemanager.dialogue={
	[1]={pre_delay=3.5,speech="BOARLORD_ROUND5_START"},
}

waveset_data[3].waves[1]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[3][1]),{1}},{_W.CreateSpawn(mob_spawns[3][2]),{3}},{_W.CreateSpawn(mob_spawns[3][3]),{2}})


waveset_data[3].wavemanager.onspawningfinished[1]=function(self,spawnedmobs)
	if self.timers.reinforcements then self.timers.reinforcements:Cancel() end

	self.inst:DoTaskInTime(0,function()
		local boaril = _W.OrganizeAllMobs(spawnedmobs).boarilla
			local bl=#boaril
			self.health_triggers.boaril = {
				[1]={total_percent=bl*0.5,fn=function()
					self:QueueWave(nil,true,boarilla_reinforce_1)
				end},
				[2]={total_percent=0,fn=function()
					self:QueueWave(nil,true,boarilla_reinforce_2)
				end},
			}
		_W.AddHealthTriggers(self.health_triggers.boaril, unpack(boaril))

		local boarr = _W.OrganizeAllMobs(spawnedmobs).boarrior
			local bo=#boarr
			self.health_triggers.boarr = {
				[1]={total_percent=bo*0.75,fn=function()
					self:QueueWave(nil,true,boarrior_reinforce)
				end},
				[2]={total_percent=bo*0.25,fn=function()
					self:QueueWave(nil,true,boarrior_reinforce)
				end},
				[3]={total_percent=0,fn=function()
					self:QueueWave(nil,true,boarrior_reinforce)
				end},
			}
		_W.AddHealthTriggers(self.health_triggers.boarr, unpack(boarr))

		local swine = _W.OrganizeAllMobs(spawnedmobs).swineclops
			local sw=#swine
			self.health_triggers.swine = {
				[1]={total_percent=sw*0.75,fn=function()
					self:QueueWave(nil,true,swineclops_reinforce_1)
				end},
				[2]={total_percent=sw*0.25,fn=function()
					self:QueueWave(nil,true,swineclops_reinforce_4)
				end},
			}
		_W.AddHealthTriggers(self.health_triggers.swine, unpack(swine))
	end)
end

 return waveset_data