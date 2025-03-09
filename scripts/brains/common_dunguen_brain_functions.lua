require "behaviours/chaseandattack"
require "behaviours/chaseandattack_forge"
require "behaviours/faceentity"
require "behaviours/follow"
require "behaviours/wander"
--require "behaviours/panic"

---------------
-- Mob Brain --
---------------
local MOB_MAX_CHASE_TIME = 8
local MAX_WANDER_DISTANCE = 5
local MAX_WANDER_DISTANCE_STANDSTILL = 0

local function GetWanderPoint(inst)
	if inst.home_pos then
		local pos_num = inst.home_pos     
		return TheWorld.DungeonCenterPos[pos_num] or TheWorld.components.lavaarenaevent and TheWorld.components.lavaarenaevent:GetArenaCenterPoint() or nil
	else
    	return TheWorld.components.lavaarenaevent and TheWorld.components.lavaarenaevent:GetArenaCenterPoint() or nil
	end
end

--local function GetLeader(inst)
--   return inst.components.follower ~= nil and inst.components.follower.leader or nil
--end

--local function GetNewTarget(inst)
--	inst.components.combat:TryRetarget()
--end

-- Adds ChaseAndAttack and Wander nodes to the pet
-- Can adjust default parameters by giving your own tuning_values
local function CreateCommonMobBrainNodes(inst, tuning_values, behavior_values)
	tuning_values = tuning_values or {}
	behavior_values = behavior_values or {}
	return {
		--WhileNode(function() return inst.components.health.takingfiredamage end, "OnFire", Panic(inst)), -- TODO these mobs had it: pitpig, croc, scorp,
		WhileNode(function() return not behavior_values.chaseandattack_condition_fn or behavior_values.chaseandattack_condition_fn(inst) end, "Forge Chase And Attack", ChaseAndAttack_Forge(inst, tuning_values.MAX_CHASE_TIME or MOB_MAX_CHASE_TIME, behavior_values.findavoidanceobjectsfn, behavior_values.avoid_dist)),
		WhileNode(function() return (not behavior_values.wander_condition_fn or behavior_values.wander_condition_fn(inst)) and not (inst.sg:HasStateTag("keepmoving") or inst.sg:HasStateTag("posing")) end, "Wander", Wander(inst, behavior_values.GetWanderPoint or GetWanderPoint, inst.standstill and MAX_WANDER_DISTANCE_STANDSTILL or tuning_values.MAX_WANDER_DISTANCE or MAX_WANDER_DISTANCE)), -- TODO include a custom condition fn?
	}
end

---------------
-- Pet Brain --
---------------
local PET_MAX_CHASE_TIME = 20
local MIN_FOLLOW_DIST = 0
local MAX_FOLLOW_DIST = 3
local TARGET_FOLLOW_DIST = 2

local function GetFaceTargetFn(inst)
    return inst.components.follower.leader
end

local function KeepFaceTargetFn(inst, target)
    return inst.components.follower.leader == target
end

-- Adds ChaseAndAttack, Follow, and FaceEntity nodes to the pet
-- Can adjust default parameters by giving your own tuning_values
local function CreateCommonPetBrainNodes(inst, tuning_values)
	tuning_values = tuning_values or {}
	return {
		ChaseAndAttack(inst, tuning_values.MAX_CHASE_TIME or PET_MAX_CHASE_TIME),
		Follow(inst, function() return inst.components.follower.leader end, tuning_values.MIN_FOLLOW_DIST or MIN_FOLLOW_DIST, tuning_values.TARGET_FOLLOW_DIST or TARGET_FOLLOW_DIST, tuning_values.MAX_FOLLOW_DIST or MAX_FOLLOW_DIST),
		IfNode(function() return inst.components.follower.leader ~= nil end, "HasLeader", FaceEntity(inst, GetFaceTargetFn, KeepFaceTargetFn ))
	}
end

-------------
-- General --
-------------
local function AddCommonBrainNodes(inst, create_brain_nodes_fn, tuning_values, behavior_values, nodes)
	if not nodes then return create_brain_nodes_fn(inst, tuning_values, behavior_values) end
	for _,node in pairs(create_brain_nodes_fn(inst, tuning_values, behavior_values)) do
		table.insert(nodes, node)
	end
	return nodes
end

local DEFAULT_MOB_PERIOD = 0.25
local function CreateMobBehaviorRoot(inst, tuning_values, behavior_values, custom_nodes, period)
	return PriorityNode(AddCommonBrainNodes(inst, CreateCommonMobBrainNodes, tuning_values, behavior_values, custom_nodes), period or DEFAULT_MOB_PERIOD)
end
local DEFAULT_PET_PERIOD = 1 -- TODO Why do we have this set to 1?
local function CreatePetBehaviorRoot(inst, tuning_values, custom_nodes, period)
	return PriorityNode(AddCommonBrainNodes(inst, CreateCommonPetBrainNodes, tuning_values, custom_nodes), period or DEFAULT_PET_PERIOD)
end

return {
	CreateMobBehaviorRoot = CreateMobBehaviorRoot,
	CreatePetBehaviorRoot = CreatePetBehaviorRoot,
}
