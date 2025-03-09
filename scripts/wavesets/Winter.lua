local RPX,_W=TUNING.modfns["workshop-2038128735"],UTIL.WAVESET
local GameplayHasTag,AddWaveTimer,SetLeashByID,PairRhinosByID,SetReverse=RPX.GameplayHasTag,RPX.AddWaveTimer,RPX.SetLeashByID,RPX.PairRhinosByID,RPX.SetReverse
local teampresets=RPX.teampresets
local ishard=GameplayHasTag("difficulty","hard")
local isexhard=GameplayHasTag("difficulty","extrahard")
local RPX,TUNING=RPX,TUNING
local GetUtil,GetCommon_Fns,GameplayHasTag,AddReforgedPrefab,SetCombatModifier,SetLeashByID=RPX.GetUtil,RPX.GetCommon_Fns,RPX.GameplayHasTag,RPX.AddReforgedPrefab,RPX.SetCombatModifier,RPX.SetLeashByID
local SpawnPrefab,FRAMES=_G.SpawnPrefab,_G.FRAMES
local _W=GetUtil("WAVESET")
local ForceTaunt,ApplyMultiBuild=GetCommon_Fns("ForceTaunt"),GetCommon_Fns("ApplyMultiBuild")
local SWINECLOPS,BOARRIOR,BOARILLA,SCORPEON,SNORTOISE=TUNING.FORGE.SWINECLOPS,TUNING.FORGE.BOARRIOR,TUNING.FORGE.BOARILLA,TUNING.FORGE.SCORPEON,TUNING.FORGE.SNORTOISE
local GetReforgedSettings = RPX.GetReforgedSettings
local MapTuning = RPX.MapTuning
local duplicator=GetReforgedSettings("gameplay","mutators").mob_duplicator
local map = GetReforgedSettings("gameplay","map")
local iswanda=false
local rhino_need_alive = false

local function LeashPitpigsToCrocs(spawnedmobs, croc)
    for i,mob_list in pairs(spawnedmobs or {}) do
        local mobs = _W.OrganizeMobs(mob_list)
        if mobs then
            _W.LeashMobs(croc or mobs.crocommander and mobs.crocommander[1], mobs.pitpig)
        end
    end
end

local function LeashPitpigsToNecro(spawnedmobs, croc)
	for i,mob_list in pairs(spawnedmobs or {}) do
        local mobs = _W.OrganizeMobs(mob_list)
        if mobs then
            _W.LeashMobs(croc or mobs.crocommander_necro and mobs.crocommander_necro[1], mobs.pitpig_zombie)
        end
    end
end

local AddBoarriorr=function(inst)
	inst:SetStateGraph("SGwinter_boarrior")
	inst.doing_banner = false
	inst.ice_continue = false
	inst.want_banner = false
	inst.components.combat:AddAttack("ice_attack",true,20)
	inst.components.combat:StartCooldown("ice_attack")

	local BoarDeath=function(inst,data)
		local pos = Vector3(0,0,0)
		local ents = TheSim:FindEntities(pos.x, 0, pos.z, 999, {"FX"})
		local ICE_LANCE_RADIUS = 3.9
		local AREAATTACK_MUST_TAGS = { "_combat" }
		local AREA_EXCLUDE_TAGS = { "INLIMBO", "notarget", "noattack", "flight", "invisible", "playerghost", "deerclops", "LA_mob"}

		local function OnUpdateIceCircle(inst)
			local x, y, z = inst.Transform:GetWorldPosition()
			for i, v in ipairs(TheSim:FindEntities(x, 0, z, inst.radius, nil, NOTAGS, FREEZETARGET_ONEOF_TAGS)) do
				if v:IsValid() and not (v.components.health ~= nil and v.components.health:IsDead()) then
					if v.components.burnable ~= nil and v.components.fueled == nil then
						v.components.burnable:Extinguish()
					end
					if v.components.freezable ~= nil and
						not v.components.freezable:IsFrozen() and
						v.components.freezable.coldness < v.components.freezable:ResolveResistance() * (inst.freezelimit or 1)
					then
						v.components.freezable:AddColdness(.1, 1, inst.freezelimit ~= nil)
					end
					if v.components.temperature ~= nil then
						local newtemp = math.max(v.components.temperature.mintemp, TUNING.DEER_ICE_TEMPERATURE)
						if newtemp < v.components.temperature:GetCurrent() then
							v.components.temperature:SetTemperature(newtemp)
						end
					end
					if v.components.grogginess ~= nil and
						not v.components.grogginess:IsKnockedOut() and
						v.components.grogginess.grog_amount < TUNING.DEER_ICE_FATIGUE
					then
						v.components.grogginess:AddGrogginess(TUNING.DEER_ICE_FATIGUE)
					end
				end
			end
		end

		local function impact_KillFX(inst)
			inst.components.updatelooper:RemoveOnUpdateFn(OnUpdateIceCircle)
			inst:ListenForEvent("animover", inst.Remove)
			inst.AnimState:PlayAnimation("pst")
		end

		for _,ent in pairs(ents) do
			if ent.prefab == "winter_impact_circle_fx" then
				impact_KillFX(ent)
			end
		end
	end

	local function EnterPhase3Trigger(inst)
		inst.components.healthtrigger:RemoveTrigger(TUNING.FORGE.BOARRIOR.PHASE3_TRIGGER)
		inst.components.combat:ToggleAttack("combo", true)
		inst.avoid_healing_circles = true
		inst.want_banner = true
		inst.sg:GoToState("banner_pre")
	end

	inst:ListenForEvent("death",BoarDeath)
	inst.components.healthtrigger:RemoveTrigger(TUNING.FORGE.BOARRIOR.PHASE3_TRIGGER)
	inst.components.healthtrigger:AddTrigger(TUNING.FORGE.BOARRIOR.PHASE3_TRIGGER, EnterPhase3Trigger)
end

AddReforgedPrefab("boarrior",AddBoarriorr)

local boarilla_wave={
	name="boarilla_wave",
	mob_spawns=_W.SetSpawn({_W.CreateSpawn({{{"boarilla"}}}),{1}}),
}

local boarilla_skeleton_wave={
	name="boarilla_skeleton_wave",
	mob_spawns=_W.SetSpawn({_W.CreateSpawn({{{"boarilla_skeleton"}}}),{3}}),
	onspawningfinished = function(self, spawnedmobs)
		for i,moblist in pairs(spawnedmobs) do 
			for mob in pairs(moblist) do 
				if mob.prefab=="boarilla_skeleton" then 
					mob.components.health:DoDelta(-(mob.components.health.maxhealth * 0.1))
				end
			end
		end
	end,
}


local reinforcements_mobs = {
	_W.CombineMobSpawns(
		{{{"snortoise"}}},
		_W.CreateMobSpawnFromPreset("square",_W.CreateMobList(_W.RepeatMob("pitpig",4)))
	),
	_W.CombineMobSpawns(
		{{{"snortoise_ghost"}}},
		_W.CreateMobSpawnFromPreset("square",_W.CreateMobList(_W.RepeatMob("pitpig_zombie",4)))
	)
}
local reinforcements={
	name="reinforcements",
	mob_spawns=_W.SetSpawn({_W.CreateSpawn(reinforcements_mobs[1]),{1}},{_W.CreateSpawn(reinforcements_mobs[2]),{3}})
}


local AddSwineclops=function(inst)
	local healthtrigger=inst.components.healthtrigger
	local ExitInfiniteComboTrigger=function(inst)
		healthtrigger:RemoveTrigger(1-SWINECLOPS.INFINITE_COMBO_TRIGGER)
		inst.components.combat:SetAttackOptions("combo",{max=4})
	end
	local ExitCombo2Trigger=function(inst)
		healthtrigger:RemoveTrigger(1-SWINECLOPS.COMBO_2_TRIGGER)
		inst.components.combat:SetAttackOptions("combo",{max=2})
		inst.want_to_stop = true
		ForceTaunt(inst)		
	end
	local ExitAttackAndGuardModeTrigger=function(inst)
		healthtrigger:RemoveTrigger(1-SWINECLOPS.ATTACK_AND_GUARD_MODE_TRIGGER)
		inst.components.combat:ToggleAttack("uppercut",false)
		inst.components.combat:ToggleAttack("buff",false)
		inst.modes.guard=false
	end
	local ExitAttackModeTrigger=function(inst)
		healthtrigger:RemoveTrigger(1-SWINECLOPS.ATTACK_MODE_TRIGGER)
		inst.components.combat:SetAttackOptions("combo",{max=0})
		inst.components.combat:ToggleAttack("tantrum",false)
		inst.modes.guard=true
		inst.modes.attack=false
	end
	healthtrigger:RemoveTrigger(SWINECLOPS.ATTACK_MODE_TRIGGER)
	healthtrigger:RemoveTrigger(SWINECLOPS.ATTACK_AND_GUARD_MODE_TRIGGER)
	healthtrigger:RemoveTrigger(SWINECLOPS.COMBO_2_TRIGGER)
	healthtrigger:RemoveTrigger(SWINECLOPS.INFINITE_COMBO_TRIGGER)
	healthtrigger:AddTrigger(1-SWINECLOPS.INFINITE_COMBO_TRIGGER,ExitInfiniteComboTrigger)
	healthtrigger:AddTrigger(1-SWINECLOPS.COMBO_2_TRIGGER,ExitCombo2Trigger)
	healthtrigger:AddTrigger(1-SWINECLOPS.ATTACK_AND_GUARD_MODE_TRIGGER,ExitAttackAndGuardModeTrigger)
	healthtrigger:AddTrigger(1-SWINECLOPS.ATTACK_MODE_TRIGGER,ExitAttackModeTrigger)
	inst.components.combat:SetAttackOptions("combo",{max=999})
	inst.components.combat:ToggleAttack("uppercut",true)
	inst.components.combat:ToggleAttack("buff",true)
	inst.components.combat:ToggleAttack("tantrum", true)
	inst.components.combat:SetCooldown("guard",6)
	inst.modes.attack=true
	inst.components.combat.ignorehitrange=true
	inst.want_to_stop = false
	inst:SetStateGraph("SGbutter_swineclops")
end

local function Disenrage(inst,data)
	if inst.enraged and not inst.tantrum_timer then 
		inst:RemoveEventCallback("newstate",Disenrage)
		inst.AnimState:SetBuild("lavaarena_beetletaur_hardmode")
		inst.enraged=false
		if inst.engraged_tantrum_timer then inst.engraged_tantrum_timer:Cancel() inst.engraged_tantrum_timer=nil end
	end
end

local AddHardSwineclops=function(inst)
	if not GameplayHasTag("difficulty","hard") then return inst end
	local ENRAGED_TRIGGER=0.5
	local healthtrigger=inst.components.healthtrigger
	local EnragedTrigger=function(inst)
		healthtrigger:RemoveTrigger(ENRAGED_TRIGGER)
		if inst.engraged_tantrum_timer then inst.engraged_tantrum_timer:Cancel() inst.engraged_tantrum_timer=nil end
		inst.enraged=false
		inst.components.combat:SetAttackOptions("combo",{max=2})
		inst:ListenForEvent("newstate",Disenrage)
	end
	healthtrigger:AddTrigger(ENRAGED_TRIGGER,EnragedTrigger)
	inst.AnimState:SetBuild("lavaarena_beetletaur_hardmode_enraged")
	inst.enraged=true
	

	inst.engraged_tantrum_timer=inst:DoTaskInTime(30,function(inst) 
		if inst.enraged then 
			inst.wants_to_tantrum=true 
		end 
	end)

	inst:SetStateGraph("SGbutter_swineclops_hard")
	inst.components.combat:SetCooldown("guard",6)
end

local LoseMorale=function(inst,data)
	local oldpercent,newpercent=data.oldpercent or 1,data.newpercent or 1
	if oldpercent>0.25 and newpercent<=0.25 then 
		SetCombatModifier(inst,"reverse",12/15)
	elseif oldpercent>0.5 and newpercent<=0.5 then 
		SetCombatModifier(inst,"reverse",13/15)
	elseif oldpercent>0.75 and newpercent<=0.75 then 
		SetCombatModifier(inst,"reverse",14/15)
	end
end

local AddRhinocebro=function(inst) inst:ListenForEvent("healthdelta",LoseMorale) end

local AddBoarrior=function(inst)
	local boarrior_pigmobs = {}
	local boarrior_crocmobs = {}
	boarrior_pigmobs[1] = {
		_W.CombineMobSpawns(
			{{{"crocommander"}}},
			_W.CreateMobSpawnFromPreset("triangle",_W.CreateMobList(_W.RepeatMob("pitpig",3)))
		),
		_W.CreateMobSpawnFromPreset("circle",_W.CreateMobList("pitpig_zombie","pitpig_zombie","pitpig_zombie","pitpig_zombie","pitpig_zombie","pitpig_zombie"),{rotation=270})
	}

	boarrior_crocmobs[1] = {
		_W.CreateMobSpawnFromPreset("circle",_W.CreateMobList("pitpig","pitpig","pitpig","pitpig","pitpig","pitpig"),{rotation=270}),
		_W.CombineMobSpawns(
			{{{"crocommander_necro"}}},
			_W.CreateMobSpawnFromPreset("triangle",_W.CreateMobList(_W.RepeatMob("pitpig_zombie",3)))
		)
	}

	local function LeashPigsAndCroc(self, spawnedmobs, leader)
		for i,mob_list in pairs(spawnedmobs or {}) do
			local mobs = _W.OrganizeMobs(mob_list)
			if mobs and mobs.crocommander then
				for j=1,duplicator*2 do
					for k = (j*3)-2,j * 3 do
						if mobs.crocommander[j] and mobs.pitpig[k] then
							mobs.crocommander[j].components.leader:AddFollower(mobs.pitpig[k])
						end
					end
				end
			elseif mobs and mobs.crocommander_necro then
				for j=1,duplicator*2 do
					for k = (j*3)-2,j * 3 do
						if mobs.crocommander_necro[j] and mobs.pitpig_zombie[k] then
							mobs.crocommander_necro[j].components.leader:AddFollower(mobs.pitpig_zombie[k])
						end
					end
				end
			end
		end
	end

	local wave=inst.components.combat:GetAttackOptions("reinforcements").wave
 	wave.mob_spawns=_W.SetSpawn({_W.CreateSpawn(boarrior_pigmobs[1][1]),{1}},{_W.CreateSpawn(boarrior_pigmobs[1][2]),{3}})

	local healthtrigger=inst.components.healthtrigger
	local ExitPhase4Trigger=function(inst)
		healthtrigger:RemoveTrigger(1-BOARRIOR.PHASE4_TRIGGER)
		inst.components.combat:ToggleAttack("dash",false)
	end
	local ExitPhase3Trigger=function(inst)
		local pigs_wave = {
			name = "pigs",
			mob_spawns = _W.SetSpawn({_W.CreateSpawn(boarrior_pigmobs[1][1]),{1}},{_W.CreateSpawn(boarrior_pigmobs[1][2]),{3}}),
			onspawningfinished = function(self, spawnedmobs, leader)
				LeashPigsAndCroc(self, spawnedmobs, leader)
			end,		
		}	
		inst.components.combat:SetAttackOptions("reinforcements", {wave = pigs_wave})
		inst.components.healthtrigger:RemoveTrigger(1-BOARRIOR.PHASE3_TRIGGER)
		inst.components.combat:ToggleAttack("combo",false)
		inst.avoid_healing_circles=false
		inst.sg:GoToState("banner_pre")
	end
	local ExitPhase2Trigger=function(inst)
		local croc_wave = {
			name = "crocs",
			mob_spawns = _W.SetSpawn({_W.CreateSpawn(boarrior_crocmobs[1][1]),{1}},{_W.CreateSpawn(boarrior_crocmobs[1][2]),{3}}),
			onspawningfinished = function(self, spawnedmobs, leader)
				LeashPigsAndCroc(self, spawnedmobs, leader)
			end,		
		}		

		healthtrigger:RemoveTrigger(1-BOARRIOR.PHASE2_TRIGGER)
		inst.components.combat:ToggleAttack("spin",false)
		inst.components.combat:ReadyAttack("spin",false)
		inst.components.combat.attacks.reinforcements.opts.wave = croc_wave
		inst.components.combat.attacks.reinforcements.opts.banner_opts.prefab =  _G.UTIL.WAVESET.defaultbanner
		inst.components.combat.attacks.reinforcements.opts.banner_opts.max =  5
		if not ishard then
			inst.sg:GoToState("banner_pre")
		end
	end
	local ExitPhase1Trigger=function(inst)
		healthtrigger:RemoveTrigger(1-BOARRIOR.PHASE1_TRIGGER)
		inst.components.combat:ToggleAttack("slam",false)
		inst.components.combat:ToggleAttack("random_slam",false)
		inst.components.combat.ignorehitrange=false
	end
	healthtrigger:RemoveTrigger(BOARRIOR.PHASE1_TRIGGER)
	healthtrigger:RemoveTrigger(BOARRIOR.PHASE2_TRIGGER)
	healthtrigger:RemoveTrigger(BOARRIOR.PHASE3_TRIGGER)
	healthtrigger:RemoveTrigger(BOARRIOR.PHASE4_TRIGGER)
	healthtrigger:AddTrigger(1-BOARRIOR.PHASE4_TRIGGER,ExitPhase4Trigger)
	healthtrigger:AddTrigger(1-BOARRIOR.PHASE3_TRIGGER,ExitPhase3Trigger)
	healthtrigger:AddTrigger(1-BOARRIOR.PHASE2_TRIGGER,ExitPhase2Trigger)
	healthtrigger:AddTrigger(1-BOARRIOR.PHASE1_TRIGGER,ExitPhase1Trigger)
	inst.components.combat:ToggleAttack("slam",true)
	inst.components.combat:ToggleAttack("random_slam",true)
	inst.components.combat:ToggleAttack("combo",true)
	inst.components.combat:ToggleAttack("dash",true)
	inst.components.combat:AddAttack("spin",true,0)
	inst.components.combat.ignorehitrange=true
	inst.avoid_healing_circles=true
end

local AddHardBoarrior=function(inst)
	if not GameplayHasTag("difficulty","hard") then return inst end
	local boarrior_pigmobs = {}
	local boarrior_crocmobs = {}
	boarrior_pigmobs[1]= {
		_W.CombineMobSpawns(
			_W.CreateMobSpawnFromPreset("line",_W.CreateMobList(_W.RepeatMob("pitpig",2)),{distance=1,rotation=270}),
			_W.CreateMobSpawnFromPreset("circle",_W.CreateMobList(_W.RepeatMob("pitpig",6)),{rotation=270})
		),
		_W.CombineMobSpawns(
			_W.CreateMobSpawnFromPreset("line",_W.CreateMobList("pitpig",""),{distance=1,rotation=270}),
			_W.CreateMobSpawnFromPreset("circle",_W.CreateMobList("","pitpig","pitpig","pitpig","",""),{rotation=270})
		),
		_W.CombineMobSpawns(
			_W.CreateMobSpawnFromPreset("line",_W.CreateMobList(_W.RepeatMob("crocommander_necro",2)),{distance=1,rotation=270}),
			_W.CreateMobSpawnFromPreset("circle",_W.CreateMobList(_W.RepeatMob("pitpig_zombie",6)),{rotation=270})
		),

		_W.CreateMobSpawnFromPreset("circle",_W.CreateMobList("pitpig","pitpig","pitpig","pitpig","pitpig","pitpig"),{rotation=270}),
		_W.CombineMobSpawns(
			{{{"crocommander_necro"}}},
			_W.CreateMobSpawnFromPreset("triangle",_W.CreateMobList(_W.RepeatMob("pitpig_zombie",3)))
		)
	}

	boarrior_crocmobs[1]= {
		_W.CombineMobSpawns(
			_W.CreateMobSpawnFromPreset("line",_W.CreateMobList(_W.RepeatMob("crocommander",2)),{distance=1,rotation=270}),
			_W.CreateMobSpawnFromPreset("circle",_W.CreateMobList(_W.RepeatMob("pitpig",6)),{rotation=270})
		),
		_W.CombineMobSpawns(
			_W.CreateMobSpawnFromPreset("line",_W.CreateMobList("","pitpig_zombie"),{distance=1,rotation=270}),
			_W.CreateMobSpawnFromPreset("circle",_W.CreateMobList("pitpig_zombie","","","","pitpig_zombie","pitpig_zombie"),{rotation=270})
		),
		_W.CombineMobSpawns(
			_W.CreateMobSpawnFromPreset("line",_W.CreateMobList(_W.RepeatMob("pitpig_zombie",2)),{distance=1,rotation=270}),
			_W.CreateMobSpawnFromPreset("circle",_W.CreateMobList(_W.RepeatMob("pitpig_zombie",6)),{rotation=270})
		),

		_W.CombineMobSpawns(
			{{{"crocommander"}}},
			_W.CreateMobSpawnFromPreset("triangle",_W.CreateMobList(_W.RepeatMob("pitpig",3)))
		),
		_W.CreateMobSpawnFromPreset("circle",_W.CreateMobList("pitpig_zombie","pitpig_zombie","pitpig_zombie","pitpig_zombie","pitpig_zombie","pitpig_zombie"),{rotation=270})
	}

	local function LeashPigsAndCroc(self, spawnedmobs, leader)
		for i,mob_list in pairs(spawnedmobs or {}) do
			local mobs = _W.OrganizeMobs(mob_list)
			if mobs and mobs.crocommander then
				for j=1,duplicator*2 do
					for k = (j*3)-2,j * 3 do
						if mobs.crocommander[j] and mobs.pitpig[k] then
							mobs.crocommander[j].components.leader:AddFollower(mobs.pitpig[k])
						end
					end
				end
			elseif mobs and mobs.crocommander_necro then
				for j=1,duplicator*2 do
					for k = (j*3)-2,j * 3 do
						if mobs.crocommander_necro[j] and mobs.pitpig_zombie[k] then
							mobs.crocommander_necro[j].components.leader:AddFollower(mobs.pitpig_zombie[k])
						end
					end
				end
			end
		end
	end

	
	local healthtrigger=inst.components.healthtrigger
	local EnterPhase3Trigger=function(inst)
		healthtrigger:RemoveTrigger(BOARRIOR.PHASE3_TRIGGER)
		local croc_wave = {
			name = "crocs",
			mob_spawns = _W.SetSpawn({_W.CreateSpawn(boarrior_crocmobs[1][1]),{1}},{_W.CreateSpawn(boarrior_crocmobs[1][2]),{2}},{_W.CreateSpawn(boarrior_crocmobs[1][3]),{3}}),
			onspawningfinished = function(self, spawnedmobs, leader)
				LeashPigsAndCroc(self, spawnedmobs, leader)
			end,	
		}	
		local croc_wave_after = {
			name = "crocs_after",
			mob_spawns = _W.SetSpawn({_W.CreateSpawn(boarrior_crocmobs[1][4]),{1}},{_W.CreateSpawn(boarrior_crocmobs[1][5]),{3}}),
			onspawningfinished = function(self, spawnedmobs, leader)
				LeashPigsAndCroc(self, spawnedmobs, leader)
			end,	
		}


		inst.components.combat:SetAttackOptions("slam_trail",{trail_width=2})
		inst.components.combat:SetAttackOptions("spin",{can_move=false})
		inst.components.combat:ToggleAttack("reinforcements",true)
	    inst.components.combat:SetAttackOptions("reinforcements", {wave=croc_wave_after})

		inst:DoTaskInTime(3,function(inst) 
			inst.components.combat:SetAttackOptions("reinforcements", {wave = croc_wave_after})	
		end)
	end
	local EnterPhase4Trigger=function(inst)
		healthtrigger:RemoveTrigger(BOARRIOR.PHASE4_TRIGGER)
		inst.components.combat:ToggleAttack("reinforcements",true)
		local pigs_wave = {
			name = "pigs",
			mob_spawns = _W.SetSpawn({_W.CreateSpawn(boarrior_pigmobs[1][1]),{1}},{_W.CreateSpawn(boarrior_pigmobs[1][2]),{2}},{_W.CreateSpawn(boarrior_pigmobs[1][3]),{3}}),
			onspawningfinished = function(self, spawnedmobs, leader)
				LeashPigsAndCroc(self, spawnedmobs, leader)
			end,
		}
		local pigs_wave_after = {
			name = "pigs_after",
			mob_spawns = _W.SetSpawn({_W.CreateSpawn(boarrior_pigmobs[1][4]),{1}},{_W.CreateSpawn(boarrior_pigmobs[1][5]),{3}}),
			onspawningfinished = function(self, spawnedmobs, leader)
				LeashPigsAndCroc(self, spawnedmobs, leader)
			end,
		}
		inst.components.combat.attacks.reinforcements.opts.wave = pigs_wave_after
		inst.components.combat:SetCooldown("reinforcements",45)

		inst:DoTaskInTime(3,function(inst) 
			inst.components.combat.attacks.reinforcements.opts.wave = pigs_wave_after
		end)
	end

	healthtrigger:AddTrigger(BOARRIOR.PHASE3_TRIGGER,EnterPhase3Trigger)
	healthtrigger:AddTrigger(BOARRIOR.PHASE4_TRIGGER,EnterPhase4Trigger)

	local wave=inst.components.combat:GetAttackOptions("reinforcements").wave
 	wave.mob_spawns=_W.SetSpawn({_W.CreateSpawn(boarrior_crocmobs[1][1]),{1}},{_W.CreateSpawn(boarrior_crocmobs[1][2]),{2}},{_W.CreateSpawn(boarrior_crocmobs[1][3]),{3}})
	inst.components.combat:SetAttackOptions("slam_trail",{trail_width=3})
	inst.components.combat:SetAttackOptions("spin",{can_move=true})
	inst.components.combat:SetCooldown("reinforcements",45)
	inst:SetStateGraph("SGbutter_boarrior_hard")
end

local AddBoarilla=function(inst)
	local healthtrigger=inst.components.healthtrigger
	local ExitSlamTrigger=function(inst)
		healthtrigger:RemoveTrigger(1-BOARILLA.SLAM_TRIGGER)
		inst.components.combat:ToggleAttack("slam",false)
	end
	local ExitRollPhase3Trigger=function(inst)
		healthtrigger:RemoveTrigger(1-BOARILLA.ROLL_TRIGGER_3)
		inst.components.combat:SetCooldown("roll",BOARILLA.ROLL_CD/2)
	end
	local ExitRollPhase2Trigger=function(inst)
		healthtrigger:RemoveTrigger(1-BOARILLA.ROLL_TRIGGER_2)
		inst.components.combat:SetCooldown("roll",BOARILLA.ROLL_CD)
	end
	local ExitRollPhase1Trigger=function(inst)
		healthtrigger:RemoveTrigger(1-BOARILLA.ROLL_TRIGGER_1)
		inst.components.combat:ToggleAttack("roll",false)
	end
	healthtrigger:RemoveTrigger(BOARILLA.ROLL_TRIGGER_1)
	healthtrigger:RemoveTrigger(BOARILLA.ROLL_TRIGGER_2)
	healthtrigger:RemoveTrigger(BOARILLA.ROLL_TRIGGER_3)
	healthtrigger:RemoveTrigger(BOARILLA.SLAM_TRIGGER)
	healthtrigger:AddTrigger(1-BOARILLA.SLAM_TRIGGER,ExitSlamTrigger)
	healthtrigger:AddTrigger(1-BOARILLA.ROLL_TRIGGER_3,ExitRollPhase3Trigger)
	healthtrigger:AddTrigger(1-BOARILLA.ROLL_TRIGGER_2,ExitRollPhase2Trigger)
	healthtrigger:AddTrigger(1-BOARILLA.ROLL_TRIGGER_1,ExitRollPhase1Trigger)
	inst.components.combat:ToggleAttack("roll",not inst.classic)
	inst.components.combat:SetCooldown("roll",BOARILLA.ROLL_CD)
	inst.components.combat:ToggleAttack("slam",true)
end

local AddScorpeon=function(inst)
	local healthtrigger=inst.components.healthtrigger
	local ExitEnragedTrigger=function(inst)
		healthtrigger:RemoveTrigger(1-SCORPEON.ENRAGED_TRIGGER)
		inst.components.combat:SetAttackPeriod(SCORPEON.ATTACK_PERIOD)
		inst.components.combat:ToggleAttack("spit",false)
		inst.sg:GoToState("taunt")
	end
	healthtrigger:RemoveTrigger(SCORPEON.ENRAGED_TRIGGER)
	healthtrigger:AddTrigger(1-SCORPEON.ENRAGED_TRIGGER,ExitEnragedTrigger)
	inst.components.combat:SetAttackPeriod(SCORPEON.ATTACK_PERIOD_ENRAGED)
	inst.components.combat:ToggleAttack("spit",true)
end

local AddHardScorpeon=function(inst)
	if not GameplayHasTag("difficulty","hard") then return inst end
	local SCORPEON_POISON_BOMB_TRIGGER=0.5
	local healthtrigger=inst.components.healthtrigger
	local ExitPoisonBombTrigger=function(inst)
		healthtrigger:RemoveTrigger(SCORPEON_POISON_BOMB_TRIGGER)
		inst.components.combat:ToggleAttack("spit_bomb",false)
		inst.sg.mem.wants_to_taunt=true
	end
	healthtrigger:RemoveTrigger(SCORPEON_POISON_BOMB_TRIGGER)
	healthtrigger:AddTrigger(1-SCORPEON_POISON_BOMB_TRIGGER,ExitPoisonBombTrigger)
	inst.components.combat:ToggleAttack("spit_bomb",true)
	inst.components.combat:ReadyAttack("spit_bomb",true)
end

local AddSnortoise=function(inst)
	local healthtrigger=inst.components.healthtrigger
	local ExitSpinTrigger=function(inst)
		healthtrigger:RemoveTrigger(1-SNORTOISE.SPIN_TRIGGER)
		inst.components.combat:ToggleAttack("spin",false)
		inst.components.combat.ignorehitrange=false
	end
	healthtrigger:RemoveTrigger(SNORTOISE.SPIN_TRIGGER)
	healthtrigger:AddTrigger(1-SNORTOISE.SPIN_TRIGGER,ExitSpinTrigger)
	inst.components.combat:ToggleAttack("spin",true)
	inst.components.combat.ignorehitrange=true
end

local AddBoarrior_Skeleton=function(inst)	
	local healthtrigger=inst.components.healthtrigger
	inst.banners = {}

	local ExitSpinTrigger=function(inst)
		healthtrigger:RemoveTrigger(TUNING.HALLOWED_FORGE.BOARRIOR_SKELETON.PHASE4_TRIGGER)
		inst.components.spellmaster:EnableSpell("revive", true, true)
		if not ishard then 
			inst.components.combat:SetAttackOptions("reinforcements", {banner_opts = {prefab = _G.UTIL.WAVESET.defaultbanner, max = 5, angle_offset = PI/2.25}})
		end
			
		if not ishard then
			inst.sg:GoToState("banner_pre")
		end
	end
	healthtrigger:RemoveTrigger(TUNING.HALLOWED_FORGE.BOARRIOR_SKELETON.PHASE4_TRIGGER)
	healthtrigger:AddTrigger(TUNING.HALLOWED_FORGE.BOARRIOR_SKELETON.PHASE4_TRIGGER,ExitSpinTrigger)
	inst:SetStateGraph("SGbutter_boarrior_skeleton")
end

local AddHardBoarrior_Skeleton=function(inst)
	if not ishard then return inst end
	inst.banners = {}

	local healthtrigger=inst.components.healthtrigger

	local EnterPhase3Trigger=function(inst)
		healthtrigger:RemoveTrigger(TUNING.HALLOWED_FORGE.BOARRIOR_SKELETON.PHASE3_TRIGGER)
		inst.components.combat:ToggleAttack("reinforcements",true)
		inst.components.combat:SetCooldown("reinforcements",45)
		inst.sg:GoToState("banner_pre")
		inst.components.combat:SetAttackOptions("reinforcements", {banner_opts = {prefab = _G.UTIL.WAVESET.defaultbanner, max = 4, angle_offset = PI/2}})
	end
	local EnterPhase4Trigger=function(inst)	
		healthtrigger:RemoveTrigger(TUNING.HALLOWED_FORGE.BOARRIOR_SKELETON.PHASE4_TRIGGER)
		inst.components.combat:ToggleAttack("reinforcements",true)
		inst.components.combat:SetCooldown("reinforcements",45)	
		if not ishard then
			inst.sg:GoToState("banner_pre")
		end
	end

	healthtrigger:AddTrigger(TUNING.HALLOWED_FORGE.BOARRIOR_SKELETON.PHASE3_TRIGGER,EnterPhase3Trigger)		
	healthtrigger:AddTrigger(TUNING.HALLOWED_FORGE.BOARRIOR_SKELETON.PHASE4_TRIGGER,EnterPhase4Trigger)
	inst.components.combat:SetCooldown("reinforcements",45)
	inst:SetStateGraph("SGbutter_boarrior_skeleton_hard")
end

local AddScorpeon_Cultist=function(inst)
	inst.components.combat:SetAttackPeriod(TUNING.HALLOWED_FORGE.SCORPEON_CULTIST.ATTACK_PERIOD_ENRAGED)
	inst.components.spellmaster:EnableSpell("acid_meteor", true, true)
end

local AddSnortoise_Ghost=function(inst)
	inst.components.combat:ToggleAttack("spin_shoot", true)
	inst.components.combat:ToggleAttack("spin_ghost", true)
    inst.components.combat.ignorehitrange = true
end

local AddRhinocebro_Franken=function(inst)
	local function IsTrueDeath(inst)
		local mobs = TheWorld.components.forgemobtracker:GetAllLiveMobs()
		for _,mob in pairs(mobs) do
			if mob.prefab == "rhinocebro_franken" and not (mob:IsValid() and mob.components.health:IsDead() and mob.has_revived) then
				return false
			end
		end
		if ishard then
			return not rhino_need_alive
		else
			return inst.has_revived
		end
	end
	inst.IsTrueDeath = IsTrueDeath
end

local AddRoach_Beetle=function(inst)
	inst.components.inventory.maxslots = 2
end

local AddPocketwatch_Reforged=function(inst)
	local function TimeWarp(inst, caster, pos)
		local x, y, z = pos:Get()
		local revert_targets = TheSim:FindEntities(x, y, z, inst.range, nil, COMMON_FNS.GetEnemyTags(inst), COMMON_FNS.GetAllyTags(inst))
		for _,target in pairs(revert_targets) do
			if target.components.health then
				local clock_fx = COMMON_FNS.CreateFX("pocketwatch_ground_fx", target, nil, {position = target:GetPosition()})
				local prev_health = target.components.health:GetHistoryPosition(true)
				if prev_health then
					if target.components.health:IsDead() and target.components.revivablecorpse and prev_health > 0 then
						target.components.revivablecorpse:AddCharge(inst, prev_health, nil, 1)
					elseif not target.components.health:IsDead() then
						local heal_fx = COMMON_FNS.CreateFX("pocketwatch_heal_fx", target, nil, {position = target:GetPosition()})
						local current_health = target.components.health:GetPercent()
						local heal = (prev_health - current_health) * target.components.health.maxhealth
						target.components.health:DoDelta(heal, nil, "time_warp", true, caster, true)
					end
				end
			end
		end

		local mults, adds, flats = caster and caster.components.buffable and caster.components.buffable:GetStatBuffs({"spell_duration"}) or 1,1,0
		local freeze_targets = TheSim:FindEntities(x, y, z, inst.range, nil, COMMON_FNS.GetAllyTags(inst), COMMON_FNS.GetEnemyTags(inst))
		for _,target in pairs(freeze_targets) do
			if target:IsValid() and not (target.components.health and target.components.health:IsDead()) and target.components.timelockable then
				local clock_fx = COMMON_FNS.CreateFX("pocketwatch_ground_fx", target, nil, {position = target:GetPosition()})
			end
		end
	
		inst.components.rechargeable:StartRecharge()
		inst.components.aoespell:OnSpellCast(caster)
	end

	inst.components.aoespell:SetAOESpell(TimeWarp)
end

local AddCrocommander=function(inst)

end

local AddHardCrocommander=function(inst)
	if not GameplayHasTag("difficulty","hard") then return inst end
	inst.reinforcements.min_followers=-1
end

local AddCrocommander_Rapidfire=function(inst)

end

local AddHardCrocommander_Rapidfire=function(inst)
	if not GameplayHasTag("difficulty","hard") then return inst end
	inst.reinforcements.min_followers=-1
end

local AddCursed_Helmet=function(inst)
	inst:AddTag("nosleep")
	inst.components.health:DoDelta(-(inst.components.health.maxhealth * 0.1))
end

local AddHardCursed_Helmet=function(inst)
	if not GameplayHasTag("difficulty","hard") then return inst end
	inst:AddTag("nosleep")
	local function KillCorpseRhino(inst, data)
		rhino_need_alive = false
	end

	inst:ListenForEvent("death",KillCorpseRhino)
end

local AddSwineclops_Mummy=function(inst)
	inst.components.combat:SetCooldown("guard",10)
	inst:AddTag("nosleep")

	local function RemoveNoSleepTag(inst, data)
		inst:RemoveTag("nosleep")
	end

	inst:ListenForEvent("death",RemoveNoSleepTag)
end

local AddHardSwineclops_Mummy=function(inst)
	inst.components.combat:SetCooldown("guard",10)
	inst:AddTag("nosleep")

	local function RemoveNoSleepTag(inst, data)
		inst:RemoveTag("nosleep")
	end

	inst:ListenForEvent("death",RemoveNoSleepTag)
end

local AddGravestone_Spawner=function(inst)
	inst.components.health:SetMaxHealth(500)
end

local AddObelisk_Sandstorm=function(inst)
	inst.components.health:SetMaxHealth(500)
end

local AddBoarilla_Skeleton=function(inst)
	local function IsTrueDeath(inst)
		local mobs = TheWorld.components.forgemobtracker:GetAllLiveMobs()
		local all_mobs_dead = #mobs > 0
		for _,mob in pairs(mobs) do
			all_mobs_dead = all_mobs_dead and (not mob:IsValid() or mob.components.health:IsDead())
		end
		if ishard and TheWorld.components.lavaarenaevent:GetCurrentRound() == 3 then
			return not rhino_need_alive
		else
			return all_mobs_dead
		end
	end

	inst.IsTrueDeath = IsTrueDeath

	local function DeleteTask(inst, data)
		if inst.auto_rez_timer then
			RemoveTask(inst, "auto_rez_timer")
		end
	end

	inst:ListenForEvent("respawnfromcorpse",DeleteTask)
end

AddReforgedPrefab("swineclops",AddSwineclops,AddHardSwineclops)
AddReforgedPrefab("rhinocebro2",AddRhinocebro)
AddReforgedPrefab("rhinocebro",AddRhinocebro)
AddReforgedPrefab("boarilla",AddBoarilla)
AddReforgedPrefab("scorpeon",AddScorpeon,AddHardScorpeon)
AddReforgedPrefab("snortoise",AddSnortoise)
AddReforgedPrefab("crocommander",AddCrocommander,AddHardCrocommander)

AddReforgedPrefab("crocommander_rapidfire",AddCrocommander_Rapidfire,AddHardCrocommander_Rapidfire)

AddReforgedPrefab("scorpeon_cultist",AddScorpeon_Cultist)
AddReforgedPrefab("snortoise_ghost",AddSnortoise_Ghost)
AddReforgedPrefab("rhinocebro_franken",AddRhinocebro_Franken)
AddReforgedPrefab("boarilla_skeleton",AddBoarilla_Skeleton)
AddReforgedPrefab("boarrior_skeleton",AddBoarrior_Skeleton,AddHardBoarrior_Skeleton)
AddReforgedPrefab("swineclops_mummy",AddSwineclops_Mummy,AddHardSwineclops_Mummy)
AddReforgedPrefab("roach_beetle",AddRoach_Beetle)
AddReforgedPrefab("cursed_helmet",AddCursed_Helmet,AddHardCursed_Helmet)

AddReforgedPrefab("pocketwatch_reforged",AddPocketwatch_Reforged)
AddReforgedPrefab("gravestone_spawner",AddGravestone_Spawner)
AddReforgedPrefab("obelisk_sandstorm",AddObelisk_Sandstorm)


--MOB SPAWNS--

 local rhinopairs={{1,"r0s1",3,"r0s1"}}

 local mob_spawns={}

 mob_spawns[1]={
 	{{{"boarrior"}}},
	_W.CreateMobSpawnFromPreset("line",{"crocommander","boarilla"}),
 	{{{"rhinocebro"}}},
 	{{{"rhinocebro2"}}}

 }
 mob_spawns[2]={
	{{{"boarrior"}}},
	{{{"boarrior_skeleton"}}},
	_W.CreateMobSpawnFromPreset("line",{"snortoise","scorpeon"}),
	_W.CreateMobSpawnFromPreset("triangle",{"crocommander","crocommander_rapidfire","crocommander_necro"},{rotation=300}),
	_W.CreateMobSpawnFromPreset("line",{"snortoise_ghost","scorpeon_cultist"}),
	{{{"rhinocebro_franken"}}},
 }
 mob_spawns[3]={
	{{{"swineclops_mummy"}}},
	_W.CreateMobSpawnFromPreset("line",{"crocommander_necro","boarilla_skeleton"}),
	{{{"rhinocebro_franken"}}},
 }


--ITEM DROPS--

 local item_drops={
	[0]={},
	[1]={[1]={},[2]={},},
 	[2]={[1]={},[2]={},
	[3]={
		final_mob = {
			rhinocebro_franken   = {"hf_lightning_staff"}
		},
	}},
 	[3]={[1]={}},
 	[4]={},
 	[5]={}
 }

 item_drops[0].round_end   ={"barbedhelm","jaggedarmor","silkengrandarmor","crystaltiara","blacksmithsedge","wovengarland","pocketwatch_reforged","infernalstaff","whisperinggrandarmor","featheredwreath","bacontome","moltendarts"}
 item_drops[2].round_end   ={"hf_ectospear","armor_hf_swine","hat_hf_boarrior_helm","armor_hf_recharger_medium","hf_grave_axe"}
 if map == "hf_eye_arena" then
	item_drops[1].round_end = {"steadfastarmor","flowerheadband","jaggedgrandarmor","hf_candle_staff","resplendentnoxhelm","blossomedwreath"}
 else
	item_drops[1].round_end = {"steadfastarmor","flowerheadband","jaggedgrandarmor","resplendentnoxhelm","blossomedwreath"}
 end

 for k,v in pairs(AllNonSpectators) do 
	local ritems=v.reforged_items
	if ritems then 
		for tier,items in pairs(ritems) do 
			for i,item in ipairs(items) do 
				if item=="pocketwatch_reforged" then 
					items[i]="" 
					iswanda = true
				end 
			end
		end
	end
end

 local heal_opts={
 	dupe_rate=0.2,   
 	drops={["heal"]={round=0,force_items={"livingstaff"}}}
 }


 local function LeashBoarillaToCrocs(spawnedmobs)
    for i,mob_list in pairs(spawnedmobs) do
        local mobs = _W.OrganizeMobs(mob_list)
        if mobs then
            _W.LeashMobs(mobs.crocommander and mobs.crocommander[1], mobs.boarilla)
        end
    end
end

local function LeashSkulliaToNecro(spawnedmobs)
    for i,mob_list in pairs(spawnedmobs) do
        local mobs = _W.OrganizeMobs(mob_list)
        if mobs and mobs.crocommander_necro and mobs.boarilla_skeleton then 
            _W.LeashMobs(mobs.crocommander_necro and mobs.crocommander_necro[1], mobs.boarilla_skeleton)
        end
    end
end



--WAVESET DATA--

 local waveset_data={
 	item_drops=item_drops,
 	item_drop_options={
 		heal_opts=heal_opts,
  		generate_item_drop_list_fn=_W.GenerateItemDropList,
 	},
 	endgame_speech={victory={speech="REFORGED.DIALOGUE.Reflection.BOARLORD_PLAYER_VICTORY"},defeat={speech="REFORGED.DIALOGUE.Reflection.BOARLORD_PLAYERS_DEFEATED_BATTLECRY"}}
 }


 waveset_data[1]={
 	waves={},
 	wavemanager={
		dialogue={
			--[1]={speech="REFORGED.DIALOGUE.Reflection.BOARLORD_ROUND1_START"},
			--[3]={speech="REFORGED.DIALOGUE.Reflection.BOARLORD_ROUND1_3_START"}
		},
		onspawningfinished={}
	}
 }

 waveset_data[1].waves[1]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[1][1]),{2}})
 waveset_data[1].waves[2]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[1][2]),{2}})
 waveset_data[1].waves[3]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[1][3]),{1}},{_W.CreateSpawn(mob_spawns[1][4]),{3}})

 waveset_data[1].wavemanager.onspawningfinished[2]=function(self,spawnedmobs)
	LeashBoarillaToCrocs(spawnedmobs)

	local item_count = 4
	local othercrocdead = 0
	local items = {"firebomb","silkenarmor","splintmail","noxhelm"}

	for _,player in pairs(AllPlayers) do
        for tier,player_items in pairs(player.reforged_items or {}) do
            for i,item in pairs(player_items) do
				item_count = item_count + 1
            	items[item_count] = item
            end
        end
    end

	local CrocsDrop=function(inst)
		if othercrocdead == duplicator-1 then
			for k,item in pairs(items) do 
				if item then
					for j=1,duplicator do
						COMMON_FNS.DropItem(inst:GetPosition(),item)						
					end
					items[k]=nil
				end
			end					
		else
			othercrocdead = othercrocdead + 1
		end		
	end

	for i,moblist in pairs(spawnedmobs) do 
		for mob in pairs(moblist) do 
			if mob.prefab=="crocommander" then 
				mob:ListenForEvent("truedeath",CrocsDrop)
			end
		end
	end
 end

 waveset_data[1].wavemanager.onspawningfinished[3]=function(self,spawnedmobs)
	local organized_mobs = _W.OrganizeAllMobs(spawnedmobs)
	
	for i,rhinocebro in pairs(organized_mobs.rhinocebro) do
		local rhinocebro2 = organized_mobs.rhinocebro2[i]
		if rhinocebro2 then
			rhinocebro.bro = rhinocebro2
			rhinocebro2.bro = rhinocebro
		end
	end

	for i,moblist in pairs(spawnedmobs) do 
		for mob in pairs(moblist) do 
			if mob.prefab=="rhinocebro" or mob.prefab=="rhinocebro2" then 
				mob.components.health:DoDelta(-(mob.components.health.maxhealth * 0.6))
			end
		end
	end
 end

 waveset_data[2]={
 	waves={},
 	wavemanager={
		dialogue={
			[1]={speech="REFORGED.DIALOGUE.Reflection.BOARLORD_ROUND2_START"}
		},
		onspawningfinished={}
	}
 }
 waveset_data[2].waves[1]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[2][1]),{1}},{_W.CreateSpawn(mob_spawns[2][2]),{3}})
 waveset_data[2].waves[2]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[2][3]),{1}},{_W.CreateSpawn(mob_spawns[2][4]),{2}},{_W.CreateSpawn(mob_spawns[2][5]),{3}})
 waveset_data[2].waves[3]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[2][6]),{2}})

 waveset_data[2].wavemanager.onspawningfinished[1]=function(self,spawnedmobs)
	local OnHealthDelta = function(inst, data)
		local hp = data.newpercent
		local cause = data.cause
		if cause ~= "update" then
			for i,moblist in pairs(spawnedmobs) do 
				for mob in pairs(moblist) do 
					if inst ~= mob then
						mob.components.health:DoDelta(-(mob.components.health.maxhealth * (data.oldpercent - data.newpercent)), nil, "update")
					end
				end
			end
		end
	end

	local DieTogether= function(inst, data)
		for i,moblist in pairs(spawnedmobs) do 
			for mob in pairs(moblist) do 
				if not mob.components.health:IsDead() and mob.prefab=="boarrior" or mob.prefab=="boarrior_skeleton" then 
					mob.components.health:DoDelta(-mob.components.health.currenthealth)
				end
			end
		end
	end

	local ClapTogether=function(inst, data)
		for i,moblist in pairs(spawnedmobs) do 
			for mob in pairs(moblist) do 
				if not mob.components.health:IsDead() and mob.prefab=="boarrior" or mob.prefab=="boarrior_skeleton" then 
					mob.sg:GoToState("banner_pre")
					mob.components.combat:StartCooldown("reinforcements")
				end
			end
		end
	end

	for i,moblist in pairs(spawnedmobs) do 
        for mob in pairs(moblist) do 
			if mob.prefab=="boarrior" then 
				local boarrior={}
				local random_health_trigger = tonumber(string.format("0.%d",math.random(33333,41666)))
				
				table.insert(boarrior,mob)

				if ishard then
					self.health_triggers.boarrior={
						[1]={total_percent=0.75,fn=function() self:QueueWave(2) end},
						[2]={total_percent=random_health_trigger,fn=function() 
							self:QueueWave(nil,true,boarilla_wave)
						end},
						[3]={total_percent=0.25,fn=function() 
							if self.timers.reinforcements then self.timers.reinforcements:Cancel() end
							self:QueueWave(3) 
						end},
						[4]={total_percent=0.5-random_health_trigger,fn=function() 
							self:QueueWave(nil,true,boarilla_skeleton_wave)
						end}
					}
				else
					self.health_triggers.boarrior={
						[1]={total_percent=0.75,fn=function() self:QueueWave(2) end},
						[2]={total_percent=0.25,fn=function() self:QueueWave(3) end}
					}
				end
				_W.AddHealthTriggers(self.health_triggers.boarrior,unpack(boarrior))

				
				mob.components.health:SetMaxHealth((TUNING.FORGE.BOARRIOR.HEALTH*2)*duplicator)
				mob.components.health:DoDelta(-(mob.components.health.maxhealth / (100 - (TUNING.HALLOWED_FORGE.BOARRIOR_SKELETON.PHASE1_TRIGGER*100))), nil, "update")
				mob:ListenForEvent("healthdelta", OnHealthDelta)
				mob:ListenForEvent("truedeath",DieTogether)
				mob:ListenForEvent("boarrior_clap",ClapTogether)
			elseif mob.prefab=="boarrior_skeleton" then
				mob.components.combat:SetAttackOptions("reinforcements", {banner_opts = {prefab = _G.UTIL.WAVESET.defaultbanner, max = TUNING.FORGE.BOARRIOR.MAX_BANNERS, angle_offset = PI/2}})
				
				mob.components.health:SetMaxHealth((TUNING.FORGE.BOARRIOR.HEALTH*2)*duplicator)
				mob.components.health:DoDelta(-(mob.components.health.maxhealth / (100 - (TUNING.HALLOWED_FORGE.BOARRIOR_SKELETON.PHASE1_TRIGGER*100))), nil, "update")
				
				mob:ListenForEvent("healthdelta", OnHealthDelta)
				mob:ListenForEvent("truedeath",DieTogether)
				mob:ListenForEvent("boarriorskeleton_clap",ClapTogether)
			end
		end
	end
	
 end

waveset_data[2].wavemanager.onspawningfinished[2]=function(self,spawnedmobs)

	for i,mob_list in pairs(spawnedmobs or {}) do
        local mobs = _W.OrganizeMobs(mob_list)
        if mobs then
            _W.LeashMobs(mobs.crocommander_rapidfire and mobs.crocommander_rapidfire[1], mobs.crocommander_necro)
			_W.LeashMobs(mobs.crocommander_rapidfire and mobs.crocommander_rapidfire[1], mobs.crocommander)
        end
    end

	local otherscordead = 1
	local scoralldead = false

	local othercrodead  = 1
	local croalldead = false

	local othersnordead = 1
	local snoralldead = false
	local final_item = {}

	if map == "hf_eye_arena" then
		final_item = {"hf_bone_mace","hat_hf_strongdamager","hf_fire_flask"}
	else
		final_item = {"hf_bone_mace","hf_fire_flask"}
	end

	local ScorpeonsDrop=function(inst)
		local items={"hf_eye_staff", "hf_hex_darts", "armor_hf_cultist","hat_hf_cultist_crown","hat_hf_binding_band"}

		if otherscordead == 2 * duplicator then
			if snoralldead and croalldead then
				for k,item in pairs(final_item) do 
					COMMON_FNS.DropItem(inst:GetPosition(),item)
					final_item[k]=nil
				end		
			else
				scoralldead = true
			end		

			for k,item in pairs(items) do 
				COMMON_FNS.DropItem(inst:GetPosition(),item)
				items[k]=nil
			end					
		else
			otherscordead = otherscordead + 1
		end
		
	end
	
	local SnortoisesDrop=function(inst)
		local items={"armor_hf_ghost"}

		if othersnordead == 2 * duplicator then
			if scoralldead and croalldead then
				for k,item in pairs(final_item) do 
					COMMON_FNS.DropItem(inst:GetPosition(),item)
					final_item[k]=nil
				end	
			else
				snoralldead = true	
			end	

			for k,item in pairs(items) do 
				COMMON_FNS.DropItem(inst:GetPosition(),item)
				items[k]=nil
			end			
		else
			othersnordead = othersnordead + 1
		end
	end
	
	local CrocommandersDrop=function(inst)
		local items={"armor_hf_necro"}

		if othercrodead == 3 * duplicator then
			if snoralldead and scoralldead then
				for k,item in pairs(final_item) do 
					COMMON_FNS.DropItem(inst:GetPosition(),item)
					final_item[k]=nil
				end	
			else
				croalldead = true	
			end			

			for k,item in pairs(items) do 
				COMMON_FNS.DropItem(inst:GetPosition(),item)
				items[k]=nil
			end	
		else
			othercrodead = othercrodead + 1
		end
	end

	for i,moblist in pairs(spawnedmobs) do 
        for mob in pairs(moblist) do 
			if mob.prefab=="scorpeon" or mob.prefab=="scorpeon_cultist" then
				mob:ListenForEvent("truedeath",ScorpeonsDrop)
			elseif mob.prefab=="snortoise" or mob.prefab=="snortoise_ghost" then
				mob:ListenForEvent("truedeath",SnortoisesDrop)
			elseif mob.prefab=="crocommander" or mob.prefab=="crocommander_rapidfire" or mob.prefab=="crocommander_necro" then
				mob:ListenForEvent("truedeath",CrocommandersDrop)
			end
		end
	end
end

waveset_data[2].wavemanager.onspawningfinished[3]=function(self,spawnedmobs)
	for i,moblist in pairs(spawnedmobs) do 
		for mob in pairs(moblist) do 
			if mob.prefab=="rhinocebro_franken" then 
				mob.components.health:DoDelta(-(mob.components.health.maxhealth * 0.8))
			end
		end
	end
end



 waveset_data[3]={
 	waves={},
 	wavemanager={
		dialogue={
			[1] = {speech="REFORGED.DIALOGUE.Reflection.BOARLORD_ROUND3_START"},
			[3] = {speech="REFORGED.DIALOGUE.Reflection.BOARLORD_ROUND3_3_START"}
		},
		onspawningfinished={}
	}
 }
 waveset_data[3].waves[1]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[3][1]),{2}})
 waveset_data[3].waves[2]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[3][2]),{2}})
 waveset_data[3].waves[3]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[3][3]),{1}},{_W.CreateSpawn(mob_spawns[3][3]),{3}})

 waveset_data[3].wavemanager.onspawningfinished[1]=function(self,spawnedmobs)
	rhino_need_alive = true

	for i,moblist in pairs(spawnedmobs) do 
		for mob in pairs(moblist) do 
			mob.components.health:DoDelta(-(mob.components.health.maxhealth * 0.25))
		end
	end
	local mummy = _W.OrganizeAllMobs(spawnedmobs).swineclops_mummy
	self.health_triggers.mummy={
		[1]={total_percent=0.5*duplicator,fn=function() self:QueueWave(2) end},
		[2]={total_percent=0.1*duplicator,fn=function() self:QueueWave(3) end}
	}
	_W.AddHealthTriggers(self.health_triggers.mummy,unpack(mummy))
	
 end



 waveset_data[3].wavemanager.onspawningfinished[2]=function(self,spawnedmobs)
	LeashSkulliaToNecro(spawnedmobs)

	local function DropItemfn(inst,items)
		for k,item in pairs(items) do 
			if item then
				for j=1,duplicator do
					COMMON_FNS.DropItem(inst:GetPosition() or TheWorld.center.Transform:GetWorldPosition(),item)						
				end
				items[k]=nil
			end
		end	
 	end

	local function BannerDeath(inst, data)
		local mindcontrol_tome_item = {"hf_mindcontrol_tome"}
		local pos = Vector3(0,0,0)
		local ents_count = #TheSim:FindEntities(pos.x, 0, pos.z, 999, {"battlestandard"})

		if ents_count <= 0 then
			DropItemfn(inst,mindcontrol_tome_item)
		end
	end

	local function NecroDeath(inst, data)
		local pocketwatch_item={"pocketwatch_reforged"}
		local binding_banc_item={"hat_hf_binding_band"}
		local mindcontrol_tome_item={"hf_mindcontrol_tome"}
		local petrifyingtome_item={"petrifyingtome"}

		DropItemfn(inst,petrifyingtome_item)
		DropItemfn(inst,binding_banc_item)

		if iswanda then
			DropItemfn(inst,pocketwatch_item)
		end

		if ishard then
			if isexhard then
				local pos = Vector3(0,0,0)
				local ents = TheSim:FindEntities(pos.x, 0, pos.z, 999, {"battlestandard"})
				local ents_count = #TheSim:FindEntities(pos.x, 0, pos.z, 999, {"battlestandard"})

				if ents_count > 0 then
					for _,ent in pairs(ents) do
						ent:ListenForEvent("onremove",BannerDeath)
					end
				else
					DropItemfn(inst,mindcontrol_tome_item)
				end
			else	
				DropItemfn(inst,mindcontrol_tome_item)
			end
		end
	end

	for i,moblist in pairs(spawnedmobs) do 
		for mob in pairs(moblist) do 
			if mob.prefab=="boarilla_skeleton" then 
				mob.components.health:DoDelta(-(mob.components.health.maxhealth * 0.1))
			elseif mob.prefab=="crocommander_necro" then
				mob:ListenForEvent("death",NecroDeath)
			end 
		end
	end

	
 end

 waveset_data[3].wavemanager.onspawningfinished[3]=function(self,spawnedmobs)
	rhino_need_alive = true
	for i,moblist in pairs(spawnedmobs) do 
		for mob in pairs(moblist) do 
			if mob.prefab=="rhinocebro_franken" then 
				mob.components.health:DoDelta(-(mob.components.health.maxhealth * 0.8))
			end
		end
	end
 end


 return waveset_data
