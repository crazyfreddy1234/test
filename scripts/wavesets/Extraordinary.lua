local RPX,_W=TUNING.modfns["workshop-2038128735"],UTIL.WAVESET
local AddReforgedPrefab = RPX.AddReforgedPrefab
local GetReforgedSettings = RPX.GetReforgedSettings
local GetDupeGroups = RPX.GetDupeGroups
local GameplayHasTag = RPX.GameplayHasTag

local duplicator=GetReforgedSettings("gameplay","mutators").mob_duplicator
local ISHARD   = GameplayHasTag("difficulty","hard")
local ISEXHARD = GameplayHasTag("difficulty","extrahard")

local CROCOMMANDER = TUNING.FORGE.CROCOMMANDER
local SNORTOISE = TUNING.FORGE.SNORTOISE
local SCORPEON = TUNING.FORGE.SCORPEON
local BOARRIOR = TUNING.FORGE.BOARRIOR
local RHINOCEBRO = TUNING.FORGE.RHINOCEBRO
local SWINECLOPS = TUNING.FORGE.SWINECLOPS

local RPX,_W=TUNING.modfns["workshop-2038128735"],UTIL.WAVESET
local AddReforgedPrefab = RPX.AddReforgedPrefab
local GetReforgedSettings = RPX.GetReforgedSettings
local GetDupeGroups = RPX.GetDupeGroups
local GameplayHasTag = RPX.GameplayHasTag
local AddReforgedWorld = RPX.AddReforgedWorld

local duplicator=GetReforgedSettings("gameplay","mutators").mob_duplicator
local ISHARD   = GameplayHasTag("difficulty","hard")
local ISEXHARD = GameplayHasTag("difficulty","extrahard")

local CROCOMMANDER = TUNING.FORGE.CROCOMMANDER
local SNORTOISE = TUNING.FORGE.SNORTOISE
local SCORPEON = TUNING.FORGE.SCORPEON
local BOARRIOR = TUNING.FORGE.BOARRIOR
local RHINOCEBRO = TUNING.FORGE.RHINOCEBRO
local SWINECLOPS = TUNING.FORGE.SWINECLOPS

local CROCOMMANDER_NECRO = TUNING.HALLOWED_FORGE.CROCOMMANDER_NECRO
local SNORTOISE_GHOST = TUNING.HALLOWED_FORGE.SNORTOISE_GHOST
local SCORPEON_CULTIST = TUNING.HALLOWED_FORGE.SCORPEON_CULTIST
local BOARILLA_SKELETON = TUNING.HALLOWED_FORGE.BOARILLA_SKELETON
local BOARRIOR_SKELETON = TUNING.HALLOWED_FORGE.BOARRIOR_SKELETON
local RHINOCEBRO_FRANKEN = TUNING.HALLOWED_FORGE.RHINOCEBRO_FRANKEN
local SWINECLOPS_MUMMY = TUNING.HALLOWED_FORGE.SWINECLOPS_MUMMY

RHINOCEBRO.BUFF_DAMAGE_INCREASE = (RHINOCEBRO.BUFF_DAMAGE_INCREASE/5)

local function LeashPigsAndThreeCroc(self, spawnedmobs)
	self.inst:DoTaskInTime(0,function()
		for i,mob_list in pairs(spawnedmobs or {}) do
			local mobs = _W.OrganizeMobs(mob_list)
			if mobs and mobs.pitpig then
				for j=1,duplicator*2 do
					local three_banners = {}
					table.insert(three_banners,"battlestandard_heal")
					table.insert(three_banners,"battlestandard_shield")
					table.insert(three_banners,"battlestandard_damager")
					for k = (j*3)-2,j * 3 do
						if mobs.crocommander[k] and not GameplayHasTag("difficulty","hard") then
							local random_banners = math.random(1,#three_banners)
							mobs.crocommander[k].components.combat:SetAttackOptions("banner",{banners = {three_banners[random_banners]}})
							table.remove(three_banners,random_banners)
						end
						if mobs.pitpig[j] and mobs.crocommander[k] then
							mobs.pitpig[j].components.leader:AddFollower(mobs.crocommander[k])
						end
					end
				end
			end
		end
	end)
end

local function LeashPigsAndTwoCroc(self, spawnedmobs)
	self.inst:DoTaskInTime(0,function()
		for i,mob_list in pairs(spawnedmobs or {}) do
			local mobs = _W.OrganizeMobs(mob_list)
			if mobs and mobs.pitpig then
				for j=1,duplicator do
					local three_banners = {}
					table.insert(three_banners,"battlestandard_heal")
					table.insert(three_banners,"battlestandard_shield")
					table.insert(three_banners,"battlestandard_damager")
					for k = (j*2)-1,j * 2 do
						if mobs.crocommander[k] and not GameplayHasTag("difficulty","hard") then
							local random_banners = math.random(1,#three_banners)
							mobs.crocommander[k].components.combat:SetAttackOptions("banner",{banners = {three_banners[random_banners]}})
							table.remove(three_banners,random_banners)
						end
						if mobs.pitpig[j] and mobs.crocommander[k] then
							mobs.pitpig[j].components.leader:AddFollower(mobs.crocommander[k])
						end
					end
				end
			end
		end
	end)
end

local function NextWaveTimerFN(self, wave)
	table.remove(self.health_triggers.boarillas, 1)
	self:QueueWave(wave)
end

local croc_wave = {
    name = "crocs",
    mob_spawns = _W.SetSpawn({_W.CreateSpawn(_W.CombineMobSpawns(_W.CreateMobSpawnFromPreset("triangle",{"crocommander","crocommander","pitpig"}))), {1,3}}),
    onspawningfinished = function(self, spawnedmobs, leader)
        LeashPigsAndTwoCroc(self, spawnedmobs)
    end,
}


--MOB SPAWN
local AddPitpig=function(inst)
	inst:AddComponent("leader")
end

local AddCrocommander=function(inst)
	local halfhealth = CROCOMMANDER.HEALTH / 2
	inst.components.health:SetMaxHealth(halfhealth)
end

local AddHardCrocommander=function(inst)
	if not GameplayHasTag("difficulty","hard") then return inst end
	inst.reinforcements.min_followers=-1
end

local AddCrocommander_Necro=function(inst)
	local halfhealth = CROCOMMANDER_NECRO.HEALTH / 2
	inst.components.health:SetMaxHealth(halfhealth)
end

 local AddSnortoise=function(inst)
	local halfhealth = SNORTOISE.HEALTH / 2
	local SPIN_TRIGGER = 0.6

	inst.components.health:SetMaxHealth(halfhealth)
	inst.components.locomotor.walkspeed=inst.components.locomotor.walkspeed*2

	local function SpinTrigger(inst)
		inst.components.healthtrigger:RemoveTrigger(SPIN_TRIGGER)
		inst.components.combat:ToggleAttack("spin", true)
		inst.components.combat.ignorehitrange = true
	end

	inst.components.healthtrigger:RemoveTrigger(SNORTOISE.SPIN_TRIGGER)
	inst.components.healthtrigger:AddTrigger(SPIN_TRIGGER, SpinTrigger)
 end

 local AddHardSnortoise=function(inst)
	if not ISEXHARD then return inst end

	local SPIN_TRIGGER = 0.6
	inst.components.healthtrigger:RemoveTrigger(SPIN_TRIGGER)

	inst.components.combat:ToggleAttack("spin", true)
	inst.components.combat.ignorehitrange = true
end

 local AddSnortoise_Ghost=function(inst)
	local halfhealth = SNORTOISE_GHOST.HEALTH/2
	local SPIN_TRIGGER = 0.5

	inst.components.health:SetMaxHealth(halfhealth)
	inst.components.locomotor.walkspeed=inst.components.locomotor.walkspeed*2

	local function SpinTrigger(inst)
		inst.components.healthtrigger:RemoveTrigger(SPIN_TRIGGER)
		inst.components.combat:ToggleAttack("spin_ghost", true)
		inst.components.combat.ignorehitrange = true
	end

	inst.components.healthtrigger:RemoveTrigger(SNORTOISE_GHOST.SPIN_SHOOT_TRIGGER)
    inst.components.healthtrigger:RemoveTrigger(SNORTOISE_GHOST.SPIN_TRIGGER)
    inst.components.healthtrigger:AddTrigger(SPIN_TRIGGER, SpinTrigger)

	inst.components.combat:ToggleAttack("spin_shoot", true)
    inst.components.combat.ignorehitrange = true

	if ISEXHARD then
		inst.components.healthtrigger:RemoveTrigger(SPIN_TRIGGER)

		inst.components.combat:ToggleAttack("spin_ghost", true)
		inst.components.combat.ignorehitrange = true
	end
 end

 local AddHardSnortoise_Ghost=function(inst)
	if not ISEXHARD then return inst end

	local SPIN_TRIGGER = 0.5
	inst.components.healthtrigger:RemoveTrigger(SPIN_TRIGGER)

	inst.components.combat:ToggleAttack("spin_ghost", true)
	inst.components.combat.ignorehitrange = true
end

 local AddScorpeon=function(inst)
	local halfuphealth = (SCORPEON.HEALTH*3/4)
	inst.components.health:SetMaxHealth(halfuphealth)
	inst.components.locomotor.walkspeed=inst.components.locomotor.walkspeed*1.5

	inst.components.combat:SetAttackPeriod(SCORPEON.ATTACK_PERIOD_ENRAGED)
	inst.components.combat:ToggleAttack("spit",true)
 end

 local AddHardScorpeon=function(inst)
	if not ISHARD then return inst end

	local NEW_SCORPEON_POISON_BOMB_TRIGGER = 0.66666
	local SCORPEON_POISON_BOMB_TRIGGER = 0.5
	
	local function PoisonBombTrigger(inst)
		inst.components.healthtrigger:RemoveTrigger(NEW_SCORPEON_POISON_BOMB_TRIGGER)
		inst.components.combat:ToggleAttack("spit_bomb")
		inst.sg.mem.wants_to_taunt = true
	end

	inst.components.healthtrigger:RemoveTrigger(SCORPEON_POISON_BOMB_TRIGGER)
	inst.components.healthtrigger:AddTrigger(NEW_SCORPEON_POISON_BOMB_TRIGGER, PoisonBombTrigger)

	if not ISEXHARD then return inst end
	inst.components.combat.ignorehitrange = true
end

 local AddScorpeon_Cultist=function(inst)
	local halfuphealth = (SCORPEON_CULTIST.HEALTH*3/4)
	local SHIELD_TRIGGER = 0.66666

	inst.components.health:SetMaxHealth(halfuphealth)
	inst.components.locomotor.walkspeed=inst.components.locomotor.walkspeed*1.5

	local function ShieldTrigger(inst)
		inst.components.healthtrigger:RemoveTrigger(SHIELD_TRIGGER)
		inst.components.spellmaster:EnableSpell("shield", true, true)
		_G.COMMON_FNS.ForceTaunt(inst)
	end

	inst.components.healthtrigger:RemoveTrigger(SCORPEON_CULTIST.PHASE_1_TRIGGER)
	inst.components.healthtrigger:RemoveTrigger(SCORPEON_CULTIST.PHASE_2_TRIGGER)
	inst.components.healthtrigger:AddTrigger(SHIELD_TRIGGER, ShieldTrigger)

	inst.components.combat:SetAttackPeriod(SCORPEON_CULTIST.ATTACK_PERIOD_ENRAGED)
    inst.components.spellmaster:EnableSpell("acid_meteor", true, true)
 end

 local AddBoarilla=function(inst)
	inst.components.health:DoDelta(-(inst.components.health.maxhealth * 0.1))
 end

 local AddBoarilla_Skeleton=function(inst)
	inst.components.health:DoDelta(-(inst.components.health.maxhealth * 0.1))
 end
 
 local AddBoarrior=function(inst)
	local phase1_trigger = 0.866666666
	local phase2_trigger = 0.666666666
	local phase3_trigger = 0.333333333
	local halfuphealth = (BOARRIOR.HEALTH*3/4)

	local function EnterPhase1Trigger(inst)
		inst.components.healthtrigger:RemoveTrigger(phase1_trigger)
		inst.components.combat:ToggleAttack("slam", true)
		inst.components.combat:ToggleAttack("random_slam", true)
		inst.components.combat.ignorehitrange = true
	end

	local function EnterPhase2Trigger(inst)
		inst.components.healthtrigger:RemoveTrigger(phase2_trigger)
		inst.components.combat:AddAttack("spin", true, 0)
		_G.COMMON_FNS.ForceTaunt(inst)
	end

	local function EnterPhase3Trigger(inst)
		inst.components.healthtrigger:RemoveTrigger(phase3_trigger)
		inst.components.combat:ToggleAttack("combo", true)
		inst.avoid_healing_circles = true
		inst.sg:GoToState("banner_pre")
	end

	inst.components.healthtrigger:RemoveTrigger(BOARRIOR.PHASE1_TRIGGER)
	inst.components.healthtrigger:RemoveTrigger(BOARRIOR.PHASE2_TRIGGER)
	inst.components.healthtrigger:RemoveTrigger(BOARRIOR.PHASE3_TRIGGER)
	inst.components.healthtrigger:RemoveTrigger(BOARRIOR.PHASE4_TRIGGER)

	inst.components.healthtrigger:AddTrigger(phase1_trigger, EnterPhase1Trigger)
	inst.components.healthtrigger:AddTrigger(phase2_trigger, EnterPhase2Trigger)
	inst.components.healthtrigger:AddTrigger(phase3_trigger, EnterPhase3Trigger)

	inst:ListenForEvent("doattack",function(inst)
		if inst.canonemoreattack == 0 or inst.canonemoreattack == 2 then 
			inst.canonemoreattack = 1
			inst.components.combat:SetAttackPeriod(0)
		elseif inst.canonemoreattack == 1 then
			inst.canonemoreattack = 2
			inst.components.combat:SetAttackPeriod(BOARRIOR.ATTACK_PERIOD)
		else 
			inst.canonemoreattack = 0
			inst.components.combat:SetAttackPeriod(BOARRIOR.ATTACK_PERIOD)
		end 
	end)

	inst.canonemoreattack = 0
	inst:SetStateGraph("SGmodifield_boarrior")
	inst.components.health:SetMaxHealth(halfuphealth)
 end

 local AddHardBoarrior=function(inst)
	if not ISHARD then return inst end

	local phase2_trigger = 0.333333333

	local function EnterPhase2Trigger(inst)
		inst.components.healthtrigger:RemoveTrigger(phase2_trigger)
		inst.components.combat:ToggleAttack("reinforcements", true)
		inst.components.combat:SetAttackOptions("slam_trail",{trail_width=3})
		inst.components.combat:SetAttackOptions("spin",{can_move=true})
	end

	inst.components.healthtrigger:RemoveTrigger(BOARRIOR.PHASE3_TRIGGER)
	inst.components.healthtrigger:RemoveTrigger(BOARRIOR.PHASE4_TRIGGER)

	inst.components.healthtrigger:AddTrigger(phase2_trigger, EnterPhase2Trigger)

	inst:SetStateGraph("SGmodifield_boarrior_hard")
	inst.components.combat:SetAttackOptions("reinforcements", {wave = croc_wave})
	inst.components.combat:SetCooldown("reinforcements",45)
 end

 local AddBoarrior_Skeleton=function(inst)
	local phase1_trigger = 0.866666666
	local phase2_trigger = 0.666666666
	local phase3_trigger = 0.333333333
	local halfuphealth = (BOARRIOR.HEALTH*3/4)

	local build = {
		base = "lavaarena_boarrior_skeleton",
		name = "hf_boarrior_skeleton",
		symbols = {
			{"spark", "hand", "head", "pelvis", "chest", "splash", "rock2", "shoulder", "rock"},
			{"arm", "nose", "swap_weapon", "mouth", "eyes", "swap_weapon_spin", "swipes"},
		},
	}

	local function SetEnraged(inst)
		inst:DoTaskInTime(20*FRAMES, function(inst)
			local fx = SpawnPrefab("hf_transform_fire")
			inst.SoundEmitter:PlaySound("dontstarve/common/lava_arena/portal_player")
			fx.entity:SetParent(inst.entity)
			fx.AnimState:SetScale(1.2, 1.2)
		
			inst:DoTaskInTime(10*FRAMES, function(inst)
				local fx2 = SpawnPrefab("hf_glow_pulse_fx")
				fx2.AnimState:SetMultColour(0, 1, 0, 1)
				fx2.Transform:SetPosition(inst:GetPosition():Get())
				
				_G.COMMON_FNS.ApplyMultiBuild(inst, build.symbols, "hf_boarrior_skeleton_enraged")
				inst.AnimState:SetLightOverride(0.5)
				inst.Light:Enable(true)
				inst.components.combat:ToggleAttack("projectiles", true)
				if not inst.components.health:IsDead() then
					TheWorld:PushEvent("add_light_phase", {name = "enraged_grave_guardian_" .. tostring(inst.GUID), color = {0,1,0,1}, mob_link = inst, priority = 5})
				end
			end)
		end)
	end

	local function EnterPhase1Trigger(inst)
		inst.components.healthtrigger:RemoveTrigger(phase1_trigger)
		inst.components.combat:ToggleAttack("slam", true)
		inst.components.combat:ToggleAttack("ranged_slam", true)
		inst.components.combat.ignorehitrange = true
	end

	local function EnterPhase2Trigger(inst)
		inst.components.healthtrigger:RemoveTrigger(phase2_trigger)
		inst.components.combat:AddAttack("spin", true, 0, nil, {max_projectiles = 5})
		COMMON_FNS.ForceTaunt(inst)	
		SetEnraged(inst)
	end

	local function EnterPhase3Trigger(inst)
		inst.components.healthtrigger:RemoveTrigger(phase3_trigger)
		inst.components.combat:ToggleAttack("combo", true)
		inst.components.combat:ToggleAttack("dash", true)
		inst.avoid_healing_circles = true
		inst.components.spellmaster:AddSpell("revive", {"spell_revive_area"}, {
			cast_time      = 1,
			duration       = 1,
			range          = 5,
			rotations      = 1,
			cooldown       = 15,
			priority       = 1,
			is_friendly    = true,
			get_targets_fn = false,
			magic_circle   = "magic_circle_necromancy",
			ready          = false,
			enabled        = false,
		})
		inst.sg:GoToState("banner_pre")
	end

	inst.components.healthtrigger:RemoveTrigger(BOARRIOR_SKELETON.PHASE1_TRIGGER)
	inst.components.healthtrigger:RemoveTrigger(BOARRIOR_SKELETON.PHASE2_TRIGGER)
	inst.components.healthtrigger:RemoveTrigger(BOARRIOR_SKELETON.PHASE3_TRIGGER)
	inst.components.healthtrigger:RemoveTrigger(BOARRIOR_SKELETON.PHASE4_TRIGGER)

	inst.components.healthtrigger:AddTrigger(phase1_trigger, EnterPhase1Trigger)
	inst.components.healthtrigger:AddTrigger(phase2_trigger, EnterPhase2Trigger)
	inst.components.healthtrigger:AddTrigger(phase3_trigger, EnterPhase3Trigger)

	inst:ListenForEvent("doattack",function(inst)
		if inst.canonemoreattack == 0 or inst.canonemoreattack == 2 then 
			inst.canonemoreattack = 1
			inst.components.combat:SetAttackPeriod(0)
		elseif inst.canonemoreattack == 1 then
			inst.canonemoreattack = 2
			inst.components.combat:SetAttackPeriod(BOARRIOR_SKELETON.ATTACK_PERIOD)
		else 
			inst.canonemoreattack = 0
			inst.components.combat:SetAttackPeriod(BOARRIOR_SKELETON.ATTACK_PERIOD)
		end 
	end)

	inst.canonemoreattack = 0

	inst.components.health:SetMaxHealth(halfuphealth)
 end

 local AddHardBoarrior_Skeleton=function(inst)
	if not ISHARD then return inst end

	local phase1_trigger = 0.866666666
	local phase2_trigger = 0.666666666
	local phase3_trigger = 0.333333333

	local function GraveGuardianPhase2(inst)
		inst.components.healthtrigger:RemoveTrigger(phase1_trigger)
		inst.components.combat:ToggleAttack("dash", true)
		inst.components.combat:SetAttackOptions("dash", {max = 1})
	end

	local function GraveGuardianPhase3(inst)
		inst.components.healthtrigger:RemoveTrigger(phase2_trigger)
		inst.components.combat:SetAttackOptions("dash", {max = 2})
	end

	local function GraveGuardianPhase4(inst)
		inst.components.healthtrigger:RemoveTrigger(phase3_trigger)
		inst.components.combat:SetAttackOptions("dash", {max = 3})
	end

	inst.components.healthtrigger:AddTrigger(phase1_trigger, GraveGuardianPhase2)
	inst.components.healthtrigger:AddTrigger(phase2_trigger, GraveGuardianPhase3)
	inst.components.healthtrigger:AddTrigger(phase3_trigger, GraveGuardianPhase4)
 end

 local AddRhinocebro=function(inst)
	inst.components.health:DoDelta(-(inst.components.health.maxhealth * 0.2))
 end

 local AddRhinocebro_Franken=function(inst)
	inst.components.health:DoDelta(-(inst.components.health.maxhealth * 0.2))
 end

 local AddSwineclops=function(inst)
	inst.components.health:DoDelta(-(inst.components.health.maxhealth * 0.1))
	inst.normalspeed = inst.components.locomotor.runspeed

	local function ReturnNormalSpeed()
		if inst.components.locomotor.runspeed ~= inst.normalspeed then
			inst.components.locomotor.runspeed = inst.normalspeed
		end
		inst:RemoveEventCallback("onhitother",ReturnNormalSpeed)
	end

	local function TeleportRandomPlayer(inst)
		if inst.teleport_timer == nil then return end

		if (inst.teleport_timer-1)%4 == 0 then
			local non_target = inst.components.combat.target
			local targets = {}

			for _,player in pairs(_G.AllNonSpectators) do
				if player ~= non_target and not player.components.health:IsDead() then
					table.insert(targets, player)
				end
			end

			if #targets > 0 then
				local poor_target = targets[math.random(1,#targets)]
				local x,y,z = poor_target.Transform:GetWorldPosition()
				inst.components.combat:SetTarget(poor_target)
				inst.components.locomotor.runspeed = inst.components.locomotor.runspeed*3
				inst:ListenForEvent("onhitother",ReturnNormalSpeed)
				--inst.slam_count = inst.slam_count + 1
				--[[
				inst.Transform:SetPosition(x, y, z)
				inst.sg:GoToState("body_slam")

				if inst.slam_count < 3 then
					inst.sg.mem.wants_to_guard = true
				end
				]]--
			end
		end
		inst.teleport_timer = inst.teleport_timer + 1
	end

	local function BuffType_Infernal_Dirty(inst)
		ReturnNormalSpeed()
		if inst._bufftype:value() == 1 and inst.random_task == nil then
			if inst.teleport_timer == nil then
				inst.teleport_timer = 0
			end
			inst.random_task = inst:DoPeriodicTask(1, TeleportRandomPlayer, nil)
		end
		--if inst.slam_count ~= nil and (inst.slam_count > 2 or (inst._bufftype:value() == 0 and inst.isslam ~= true)) then 
		if inst._bufftype:value() == 0 and inst.random_task ~= nil then
			_G.RemoveTask(inst.random_task)
			inst.components.combat:ToggleAttack("guard", false)
			inst.teleport_timer = nil
			inst.random_task = nil
		end
	end

	if not TheNet:IsDedicated() then 
        inst:ListenForEvent("bufftypedirty", BuffType_Infernal_Dirty)
	end
 end

 local AddHardSwineclops=function(inst)
	if not ISHARD then return inst end 

	local swineclops_maxhealth = 42500
	local SETMAXHEALTH_TRIGGER = 0.5
	local INFINITE_COMBO_TRIGGER = 0.5

	inst.components.healthtrigger:RemoveTrigger(SWINECLOPS.INFINITE_COMBO_TRIGGER)

	inst.components.healthtrigger:AddTrigger(SETMAXHEALTH_TRIGGER, function(inst)
		inst.components.healthtrigger:RemoveTrigger(SETMAXHEALTH_TRIGGER)
		inst.components.health:SetCurrentHealth(swineclops_maxhealth*0.9)

		if ISEXHARD then
			_G.TheWorld.state.temperature=95 

			local function UnlimitedInferno(inst,data) 
				local player_temperature = data.new
				local player_debuffable = inst.components.debuffable
				if (inst.hashealbuff ~= true) 
					and (player_temperature and player_temperature >= 70) 
					and (player_debuffable and not (player_debuffable:HasDebuff("healingcircle_regenbuff") or player_debuffable:HasDebuff("debuff_spice_regen")))
					and (not player_debuffable:HasDebuff("debuff_inferno")) then

					player_debuffable:AddDebuff("debuff_inferno", "debuff_inferno")
				end
			end

			local function CheckInHeal(inst)
				local player_debuffable = inst.components.debuffable
				local player_temperature = inst.components.temperature

				local function SetTemperatureCertain(inst,data)
					if inst.components.temperature:GetCurrent() == 64 or inst.hashealbuff ~= true then return end
					inst.components.temperature:SetTemperature(64)
				end

				if player_debuffable:HasDebuff("healingcircle_regenbuff") or player_debuffable:HasDebuff("debuff_spice_regen") then
					if inst.hashealbuff == true then return end
					inst:ListenForEvent("temperaturedelta", SetTemperatureCertain)
					inst.hashealbuff = true
					player_temperature:SetTemperature(64)
					player_debuffable:RemoveDebuff("debuff_inferno")
				else 
					inst:RemoveEventCallback("temperaturedelta", SetTemperatureCertain)
					inst.hashealbuff = false
				end
			end

			local function SetPlayerInfernal(inst,player)
				player.components.temperature:SetTemperature(64)
				player:ListenForEvent("temperaturedelta", UnlimitedInferno)
				player:ListenForEvent("client_debuffs_update", CheckInHeal)
			end

			for _,player in pairs(AllPlayers) do
				SetPlayerInfernal(inst,player)
			end
			TheWorld:ListenForEvent("ms_playerjoined", SetPlayerInfernal)
		end
		
		inst:DoTaskInTime(FRAMES,function()
			inst.components.healthtrigger:AddTrigger(INFINITE_COMBO_TRIGGER, function(inst)
				inst.components.healthtrigger:RemoveTrigger(INFINITE_COMBO_TRIGGER)
				inst.components.combat:SetAttackOptions("combo", {max = 999})
			end)
		end)
	end)

	inst:SetStateGraph("SGbutter_ordinary_swineclops_hard")

	if not ISEXHARD then return inst end
 end

 local AddSwineclops_Mummy=function(inst)
	inst.components.health:DoDelta(-(inst.components.health.maxhealth * 0.1))
 end

 local AddHardSwineclops_Mummy=function(inst)
	if not GameplayHasTag("difficulty","hard") then return inst end


 end

 local AddCursed_Helmet=function(inst)
	inst.components.health:DoDelta(-(inst.components.health.maxhealth * 0.1))
end

local AddHardCursed_Helmet=function(inst)
	if not GameplayHasTag("difficulty","hard") then return inst end

	
end
 
 AddReforgedPrefab("pitpig",AddPitpig)
 AddReforgedPrefab("crocommander",AddCrocommander,AddHardCrocommander)
 AddReforgedPrefab("snortoise",AddSnortoise,AddHardSnortoise)
 AddReforgedPrefab("scorpeon",AddScorpeon,AddHardScorpeon)
 AddReforgedPrefab("boarilla",AddBoarilla)
 AddReforgedPrefab("boarrior",AddBoarrior,AddHardBoarrior)
 AddReforgedPrefab("rhinocebro",AddRhinocebro)
 AddReforgedPrefab("rhinocebro2",AddRhinocebro)
 AddReforgedPrefab("rhinocebro3",AddRhinocebro)
 AddReforgedPrefab("swineclops",AddSwineclops,AddHardSwineclops)

 AddReforgedPrefab("crocommander_necro",AddCrocommander_Necro)
 AddReforgedPrefab("snortoise_ghost",AddSnortoise_Ghost,AddHardSnortoise_Ghost)
 AddReforgedPrefab("scorpeon_cultist",AddScorpeon_Cultist)
 AddReforgedPrefab("boarilla_skeleton",AddBoarilla_Skeleton,AddHardBoarrior_Skeleton)
 AddReforgedPrefab("boarrior_skeleton",AddBoarrior_Skeleton)
 AddReforgedPrefab("rhinocebro_franken",AddRhinocebro_Franken)
 AddReforgedPrefab("swineclops_mummy",AddSwineclops_Mummy,AddHardSwineclops_Mummy)
 AddReforgedPrefab("cursed_helmet",AddCursed_Helmet,AddHardCursed_Helmet)

 local AllMob = {
	pitpig={"pitpig","pitpig_zombie"},
	crocommander={"crocommander","crocommander_necro"},
	snortoise={"snortoise","snortoise_ghost"},
	scorpeon={"scorpeon","scorpeon_cultist"},
	boarilla={"boarilla","boarilla_skeleton"},
	boarrior={"boarrior","boarrior_skeleton"},
	rhinocebro={"rhinocebro","rhinocebro_franken"},
	rhinocebro2={"rhinocebro2","rhinocebro_franken"},
	swineclops={"swineclops","swineclops_mummy"}
}

 local function BasicOrHF(mob,count)
	local combinemob = {}
	
	if count then
		for i=1,count or 1 do 
			combinemob[i] = AllMob[mob][math.random(2)]
		end

		return combinemob
	else 
		return AllMob[mob][math.random(2)]
	end
 end

 local mob_spawns={}
 mob_spawns[1]={
	[1]={
		_W.CreateMobSpawnFromPreset("line",BasicOrHF("pitpig",2)),
		_W.CreateMobSpawnFromPreset("line",BasicOrHF("pitpig",2)),
		_W.CreateMobSpawnFromPreset("line",BasicOrHF("pitpig",2))
	},
	[2]={
		_W.CreateMobSpawnFromPreset("square",BasicOrHF("pitpig",4)),
		_W.CreateMobSpawnFromPreset("square",BasicOrHF("pitpig",4)),
		_W.CreateMobSpawnFromPreset("square",BasicOrHF("pitpig",4))
	}
 }

 mob_spawns[2]={
	[1]={
		_W.CreateMobSpawnFromPreset("squad",_W.CreateMobList(BasicOrHF("pitpig"),BasicOrHF("crocommander",3))),
		_W.CreateMobSpawnFromPreset("squad",_W.CreateMobList(BasicOrHF("pitpig"),BasicOrHF("crocommander",3))),
	},
	[2]={
		_W.CreateMobSpawnFromPreset("squad",_W.CreateMobList(BasicOrHF("pitpig"),BasicOrHF("crocommander",3))),
		_W.CreateMobSpawnFromPreset("squad",_W.CreateMobList(BasicOrHF("pitpig"),BasicOrHF("crocommander",3))),
	}
 }

 mob_spawns[3]={
	[1]={
		_W.CreateMobSpawnFromPreset("line",_W.CreateMobList(BasicOrHF("snortoise"),BasicOrHF("scorpeon"))),
		_W.CreateMobSpawnFromPreset("line",_W.CreateMobList(BasicOrHF("snortoise"),BasicOrHF("scorpeon")))
	},
	[2]={
		{{BasicOrHF("boarilla")}}
	}
 }

 mob_spawns[4]={
	[1]={
		[1]={
			{{BasicOrHF("boarilla")}}
		},
		[2]={
			{{BasicOrHF("boarilla")}}
		}
	},
	[2]={
		_W.CreateMobSpawnFromPreset("triangle",_W.CreateMobList(BasicOrHF("crocommander"),BasicOrHF("crocommander"),BasicOrHF("pitpig")),{rotation = 180}),
	},
	[3]={
		_W.CreateMobSpawnFromPreset("line",_W.CreateMobList(BasicOrHF("snortoise"),BasicOrHF("scorpeon"))),
		_W.CreateMobSpawnFromPreset("triangle",_W.CreateMobList(BasicOrHF("crocommander"),BasicOrHF("crocommander"),BasicOrHF("pitpig")),{rotation = 180}),
		_W.CreateMobSpawnFromPreset("line",_W.CreateMobList(BasicOrHF("snortoise"),BasicOrHF("scorpeon")))
	},
	[4]={
		[1]={
			{{BasicOrHF("boarrior")}}
		},
		[2]={
			{{BasicOrHF("boarrior")}}
		}
	}
 }

 mob_spawns[5]={
	[1]={
		[1]={
			{{BasicOrHF("rhinocebro")}}
		},
		[2]={
			{{BasicOrHF("rhinocebro2")}}
		}
	}
 }

 mob_spawns[6]={
	[1]={
		[1]={
			{{BasicOrHF("swineclops")}}
		}
	}
 }


--ITEM DROPS--

 local item_drops={
	[1]={[1]={},[2]={}},
	[2]={[1]={},[2]={}},
	[3]={[1]={}},
	[4]={[2]={}}
}

local BasicItem = {"silkenarmor", "crystaltiara", "jaggedarmor", "barbedhelm", "featheredwreath"}
local function RandomBasicItem(count)
	local randomitems = {}

	for i=1,count do 
		local randomitemnum = math.random(1,#BasicItem) or 1
		table.insert(randomitems,BasicItem[randomitemnum])
		table.remove(BasicItem,randomitemnum)
	end

	print(randomitems)

	return randomitems
end

 item_drops[1][1].random_mob=RandomBasicItem(1)
 item_drops[1][2].random_mob=RandomBasicItem(2)

 item_drops[2][1].random_mob=RandomBasicItem(1)
 item_drops[2][1].final_mob={"firebomb"}
 item_drops[2][2].random_mob=RandomBasicItem(1)
 item_drops[2].round_end={"whisperinggrandarmor","wovengarland","flowerheadband","noxhelm","infernalstaff","steadfastarmor","moltendarts"}

 item_drops[3][1].random_mob={"bacontome","jaggedgrandarmor"}
 if ISEXHARD then
	item_drops[3].round_end={"steadfastgrandarmor","blacksmithsedge","blacksmithsedge","clairvoyantcrown","hat_hf_binding_band"}
 else 
	item_drops[3].round_end={"steadfastgrandarmor","blacksmithsedge","blacksmithsedge","clairvoyantcrown"}
 end

 item_drops[4].round_end={"silkengrandarmor","jaggedgrandarmor"}

 local function ApplyRandomItemDropSpread(item_drops)
    _W.SpreadItemSetOverWaves(item_drops, {"splintmail"}, {{2,1},{2,2}}, "random_mob", 1)
	_W.SpreadItemSetOverWaves(item_drops, {"resplendentnoxhelm", "blossomedwreath"}, {{4,2},{4}}, "final_mob", 1)
 end
 
 local character_tier_opts={
 	[2]={round=2},
 	[3]={round=3,force_items={"moltendarts"}}
 }

 local heal_opts={
 	dupe_rate=0.2,
 	drops={heal={round=1,wave=1,type="final_mob",force_items={"livingstaff"}}}
 }

--WAVESET DATA--

 local waveset_data={
 	item_drops=item_drops,
 	item_drop_options={
 		character_tier_opts=character_tier_opts,
 		heal_opts=heal_opts,
  		generate_item_drop_list_fn=_W.GenerateItemDropList,
		random_item_spread_fn=ApplyRandomItemDropSpread,
 	},
 	endgame_speech={victory={speech="BOARLORD_ROUND7_PLAYER_VICTORY"},defeat={speech="BOARLORD_PLAYERS_DEFEATED_BATTLECRY"}}
 }

 waveset_data[1]={
 	waves={},
 	wavemanager={}
 }
 --[[
 waveset_data[1].wavemanager.dialogue={
	--[1]={speech="BOARLORD_ROUND1_START"},
	[2]={speech="BOARLORD_ROUND1_FIGHT_BANTER",is_banter=true}
}
]]--
 waveset_data[1].waves[1]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[1][1][1]),{1}},{_W.CreateSpawn(mob_spawns[1][1][2]),{2}},{_W.CreateSpawn(mob_spawns[1][1][3]),{3}})
 waveset_data[1].waves[2]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[1][2][1]),{1}},{_W.CreateSpawn(mob_spawns[1][2][2]),{2}},{_W.CreateSpawn(mob_spawns[1][2][3]),{3}})

waveset_data[2]={
	waves={},
	wavemanager={onspawningfinished={}}
}

waveset_data[2].wavemanager.dialogue={
	--[1]={speech="BOARLORD_ROUND2_START"},
	--[2]={speech="BOARLORD_ROUND2_FIGHT_BANTER",is_banter=true}
}

waveset_data[2].waves[1]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[2][1][1]),{1}},{_W.CreateSpawn(mob_spawns[2][1][2]),{3}})
waveset_data[2].waves[2]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[2][2][1]),{1}},{_W.CreateSpawn(mob_spawns[2][2][2]),{3}})

waveset_data[2].wavemanager.onspawningfinished[1]=function(self,spawnedmobs)
	--LeashPigsAndThreeCroc(self,spawnedmobs)
end

waveset_data[2].wavemanager.onspawningfinished[2]=function(self,spawnedmobs)
	--LeashPigsAndThreeCroc(self,spawnedmobs)
end

waveset_data[3]={
	waves={},
	wavemanager={onspawningfinished={}}
}

waveset_data[3].wavemanager.dialogue={
	--[1]={speech="BOARLORD_ROUND4_FIGHT_BANTER",is_banter=true},
	--[2]={speech="BOARLORD_ROUND4_TRAILS_INTRO"}
}

waveset_data[3].waves[1]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[3][1][1]),{1}},{_W.CreateSpawn(mob_spawns[3][1][2]),{3}})
waveset_data[3].waves[2]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[3][2]),{2}})


waveset_data[3].wavemanager.onspawningfinished[1]=function(self,spawnedmobs)
	self.timers.queue_next_wave = self.inst:DoTaskInTime(15, function()
		self:QueueWave(2)
	end)
end

waveset_data[3].wavemanager.onspawningfinished[2]=function(self,spawnedmobs)
	RemoveTask(self.timers.queue_next_wave)
end

waveset_data[4]={
	waves={},
	wavemanager={onspawningfinished={}}
}

waveset_data[4].wavemanager.dialogue={
	--[1] = {pre_delay = 3.5, speech = "BOARLORD_ROUND5_START"},
	--[2] = {pre_delay = 0.5, speech = "BOARLORD_ROUND5_FIGHT_BANTER1", is_banter = true},
	--[3] = {pre_delay = 0.5, speech = "BOARLORD_ROUND5_FIGHT_BANTER2", is_banter = true},
	--[4] = {pre_delay = 3.5, speech = "BOARLORD_ROUND5_BOARRIOR_INTRO"}
}

waveset_data[4].waves[1]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[4][1][1]),{1}},{_W.CreateSpawn(mob_spawns[4][1][2]),{3}})
waveset_data[4].waves[2]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[4][2][1]),{2}})
waveset_data[4].waves[3]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[4][3][1]),{1}},{_W.CreateSpawn(mob_spawns[4][3][2]),{2}},{_W.CreateSpawn(mob_spawns[4][3][3]),{3}})
waveset_data[4].waves[4]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[4][4][1]),{1}},{_W.CreateSpawn(mob_spawns[4][4][2]),{3}})

waveset_data[4].wavemanager.onspawningfinished[1]=function(self,spawnedmobs)
	
	self.timers.queue_next_wave = self.inst:DoTaskInTime(300, function()
		NextWaveTimerFN(self, 2)
	end)
--[[
	local boarillas = _W.OrganizeAllMobs(spawnedmobs).boarilla
	self.health_triggers.boarillas = {
		[1] = {total_percent = 0.6*#boarillas , single_percent = 0.4, fn = function() self:QueueWave(2) end},
		[2] = {single_percent = 0, all_percent = 0.4, fn = function() self:QueueWave(3) end},
		[3] = {total_percent = 0.2, fn = function() self:QueueWave(4) end}
	}
	_W.AddHealthTriggers(self.health_triggers.boarillas, unpack(boarillas))
	]]--
end

waveset_data[4].wavemanager.onspawningfinished[2]=function(self,spawnedmobs)
	RemoveTask(self.timers.queue_next_wave)
	self.timers.queue_next_wave = self.inst:DoTaskInTime(300, function()
		NextWaveTimerFN(self, 3)
	end)
	--LeashPigsAndTwoCroc(self,spawnedmobs)
end

waveset_data[4].wavemanager.onspawningfinished[3]=function(self,spawnedmobs)
	RemoveTask(self.timers.queue_next_wave)
	self.timers.queue_next_wave = self.inst:DoTaskInTime(300, function()
		NextWaveTimerFN(self, 4)
	end)
	--LeashPigsAndTwoCroc(self,spawnedmobs)
end

waveset_data[4].wavemanager.onspawningfinished[3]=function(self,spawnedmobs)
	RemoveTask(self.timers.queue_next_wave)
end

waveset_data[5]={
	waves={},
	wavemanager={onspawningfinished={}}
}

waveset_data[5].wavemanager.dialogue={
	--[1] = {pre_delay = 3.5, speech = "BOARLORD_ROUND6_START"}
}

waveset_data[5].waves[1]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[5][1][1]),{1}},{_W.CreateSpawn(mob_spawns[5][1][2]),{3}})

waveset_data[5].wavemanager.onspawningfinished[1]=function(self,spawnedmobs)
	--[[
	local rhino1s=GetDupeGroups(spawnedmobs[1])
	local rhino3s=GetDupeGroups(spawnedmobs[2])
	local rhino2s=GetDupeGroups(spawnedmobs[3])

	for k,v in pairs(rhino3s) do 
		local bro3=v[1]
		if bro3.prefab=="rhinocebro3" then 
			if rhino1s[k] and rhino2s[k] then 
				local bro1,bro2=rhino1s[k][1],rhino2s[k][1]
				bro1.bro=bro2
				bro2.bro=bro3
				bro3.bro=bro1
				bro1.reviver=bro3
				bro2.reviver=bro1
				bro3.reviver=bro2
			end
		end
	end
	]]--
end

waveset_data[6]={
	waves={},
	wavemanager={onspawningfinished={}}
}

waveset_data[6].wavemanager.dialogue={
	--[1] = {pre_delay = 3.5, speech = "BOARLORD_ROUND7_START"}
}

waveset_data[6].waves[1]=_W.SetSpawn({_W.CreateSpawn(mob_spawns[6][1][1]),{2}})

 return waveset_data