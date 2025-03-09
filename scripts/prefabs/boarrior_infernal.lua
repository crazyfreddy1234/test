local assets = {
	Asset("ANIM", "anim/boarrior_infernal.zip"),
	Asset("ANIM", "anim/lavaarena_boarrior_basic.zip"),
    Asset("ANIM", "anim/fossilized.zip"),
}
local prefabs = {}
local tuning_values = TUNING.FORGE.BOARRIOR
local sound_path = "dontstarve/creatures/lava_arena/boarrior/"
--------------------------------------------------------------------------
-- Attack Functions
--------------------------------------------------------------------------
-- Apply knockback to basic attack hits
local function OnHitOther(inst, target)
	if not inst.is_doing_special then -- TODO use state tag checks?
		COMMON_FNS.KnockbackOnHit(inst, target, 5, tuning_values.ATTACK_KNOCKBACK) -- TODO tuning
	end
end

-- TODO
-- Spawn delay might be off, animation just doesn't seem right
 -- Note: Does not gain aggro from slam hits
local function DoSlamTrail(inst, target_pos, trailend)
	local trail_options = inst.components.combat:GetAttackOptions("slam_trail")
	local function GetSlamTrailPrefab(inst, current_slot, current_trail, max_trails)
		return trailend and "lavaarena_groundlift" or "lavaarena_groundliftrocks"
	end
	trail_options.prefab = GetSlamTrailPrefab
	local function GetSlamTrailDamage(inst, current_slot, current_trail, max_trails)
		return tuning_values.SLAM_DAMAGE * (trailend and 1 or 0.5)
	end
	trail_options.damage = GetSlamTrailDamage
	COMMON_FNS.SlamTrail(inst, target_pos, trail_options)
end

local _W = _G.UTIL.WAVESET
local pitpig_wave = {
    name = "pitpigs",
    mob_spawns = _W.SetSpawn({_W.CreateSpawn(_W.CreateMobSpawnFromPreset("square", _W.CreateMobList(_W.RepeatMob("pitpig", 4)))), {1,2,3}}),
}
--------------------------------------------------------------------------
-- Phases (Health Triggers)
--------------------------------------------------------------------------
local function EnterPhase1Trigger(inst)
	inst.components.healthtrigger:RemoveTrigger(tuning_values.PHASE1_TRIGGER)
	inst.components.combat:ToggleAttack("slam", true)
	inst.components.combat:ToggleAttack("random_slam", true)
	inst.components.combat.ignorehitrange = true
	--inst.components.attack_radius_display:AddCircle("slam", tuning_values.ATTACK_SLAM_RANGE, WEBCOLOURS.ORANGE)
end

local function EnterPhase2Trigger(inst)
	inst.components.healthtrigger:RemoveTrigger(tuning_values.PHASE2_TRIGGER)
	inst.components.combat:AddAttack("spin", true, 0)
	_G.COMMON_FNS.ForceTaunt(inst) -- TODO does this always occur? does it occur for other triggers as well?
end

local function EnterPhase3Trigger(inst)
	inst.components.healthtrigger:RemoveTrigger(tuning_values.PHASE3_TRIGGER)
	inst.components.combat:ToggleAttack("combo", true)
	inst.avoid_healing_circles = true
	inst.sg:GoToState("banner_pre")
end

local function EnterPhase4Trigger(inst)
	inst.components.healthtrigger:RemoveTrigger(tuning_values.PHASE4_TRIGGER)
	inst.components.combat:ToggleAttack("dash", true)
end
--------------------------------------------------------------------------
-- Physics Functions
--------------------------------------------------------------------------
local physics = {
	mass   = 500,
	radius = 1.5,
	shadow = {5.25,1.75},
}
local function PhysicsInit(inst)
	MakeCharacterPhysics(inst, physics.mass, physics.radius)
	inst.DynamicShadow:SetSize(unpack(physics.shadow))
    inst.Transform:SetFourFaced()
end
--------------------------------------------------------------------------
-- Pristine Function
--------------------------------------------------------------------------
local function PristineFN(inst)
	COMMON_FNS.AddTags(inst, "epic") -- TODO did not have the monster tag, it is added in the CommonMobFN, is that a problem?
	------------------------------------------
	--inst:AddComponent("attack_radius_display")
	--inst.components.attack_radius_display:AddCircle("melee_range", tuning_values.ATTACK_RANGE, WEBCOLOURS.RED)
	--inst.components.attack_radius_display:AddOffsetCircle("melee", nil, 2, tuning_values.AOE_HIT_RANGE, WEBCOLOURS.TURQUOISE)
end
--------------------------------------------------------------------------
local mob_values = {
	physics         = physics,
	physics_init_fn = PhysicsInit,
	pristine_fn     = PristineFN,
	stategraph      = "SGboarrior_infernal",
	brain           = require("brains/boarriorbrain"),
	sounds = {
		step            = sound_path .. "step",
		taunt           = sound_path .. "taunt",
		taunt_2         = sound_path .. "taunt_2",
		grunt           = sound_path .. "grunt",
		hit             = sound_path .. "hit",
		stun            = sound_path .. "stun",
		swipe_pre       = sound_path .. "swipe_pre",
		swipe           = sound_path .. "swipe",
		bonehit1        = sound_path .. "bonehit1",
		bonehit2        = sound_path .. "bonehit2",
		spin            = sound_path .. "spin",
		banner_call_a   = sound_path .. "banner_call_a",
		banner_call_b   = sound_path .. "banner_call_b",
		attack_5        = sound_path .. "attack_5",
		attack_5_fire_1 = sound_path .. "attack_5_fire_1",
		attack_5_fire_2 = sound_path .. "attack_5_fire_2",
		death           = sound_path .. "death",
		death_bodyfall  = sound_path .. "death_bodyfall",
		bone_drop       = sound_path .. "bone_drop",
		bone_drop_stick = sound_path .. "bone_drop_stick",
		sleep_in        = sound_path .. "sleep_in",
		sleep_out       = sound_path .. "sleep_out",
		bodyfall        = sound_path .. "bodyfall",
	},
}
--------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.CommonMobFN("boarrior", "lavaarena_boarrior_basic", mob_values, tuning_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	COMMON_FNS.AddSymbolFollowers(inst, "head", Vector3(0, -350, 0), "large", {symbol = "pelvis"}, {symbol = "pelvis"})
	------------------------------------------
	COMMON_FNS.SetupBossFade(inst, 5)
	------------------------------------------
	local attacks = {
		slam           = {cooldown = tuning_values.SLAM_CD, opts = {min_range = tuning_values.ATTACK_SLAM_MIN_RANGE, max_range = tuning_values.ATTACK_SLAM_MAX_RANGE}},
		slam_trail     = {active = true, cooldown = 0, opts = {range = tuning_values.SLAM_RANGE}},
		random_slam    = {cooldown = tuning_values.ATTACK_RANDOM_SLAM_CD, opts = {min_range = tuning_values.ATTACK_SLAM_MIN_RANGE, max_range = tuning_values.ATTACK_SLAM_MAX_RANGE}},
		combo          = {cooldown = 0},
		dash           = {cooldown = 0},
		reinforcements = {cooldown = 0, opts = {wave = pitpig_wave, banner_opts = {prefab = _G.UTIL.WAVESET.defaultbanner, max = tuning_values.MAX_BANNERS}}},
	}
	inst.components.combat:AddAttacks(attacks)
	------------------------------------------
	inst:AddComponent("healthtrigger")
	inst.components.healthtrigger:AddTrigger(tuning_values.PHASE1_TRIGGER, EnterPhase1Trigger)
	inst.components.healthtrigger:AddTrigger(tuning_values.PHASE2_TRIGGER, EnterPhase2Trigger)
	inst.components.healthtrigger:AddTrigger(tuning_values.PHASE3_TRIGGER, EnterPhase3Trigger)
	inst.components.healthtrigger:AddTrigger(tuning_values.PHASE4_TRIGGER, EnterPhase4Trigger)
	------------------------------------------
	inst.banners = {}
	inst.avoid_healing_circles = false
	inst.knockback = tuning_values.ATTACK_KNOCKBACK
	inst.DoSlamTrail = DoSlamTrail
	inst.hit_recovery = 0.75 -- TODO not used?
	inst.recentlycharged = {}
	inst.Physics:SetCollisionCallback(COMMON_FNS.OnCollideDestroyObject)
	------------------------------------------
	inst.components.combat.playerdamagepercent = 1 -- TODO needed?
	inst.components.combat.battlecryenabled = false
	inst.components.combat.onhitotherfn = OnHitOther
	------------------------------------------
	--MakeMediumBurnableCharacter(inst, "bod")
	------------------------------------------
    return inst
end

return ForgePrefab("boarrior_infernal", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/reforged.xml", "boarrior_icon.tex")
