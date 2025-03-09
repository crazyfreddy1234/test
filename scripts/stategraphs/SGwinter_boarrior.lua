--[[
Copyright (C) 2018 Forged Forge

This file is part of Forged Forge.

The source code of this program is shared under the RECEX
SHARED SOURCE LICENSE (version 1.0).
The source code is shared for referrence and academic purposes
with the hope that people can read and learn from it. This is not
Free and Open Source software, and code is not redistributable
without permission of the author. Read the RECEX SHARED
SOURCE LICENSE for details
The source codes does not come with any warranty including
the implied warranty of merchandise.
You should have received a copy of the RECEX SHARED SOURCE
LICENSE in the form of a LICENSE file in the root of the source
directory. If not, please refer to
<https://raw.githubusercontent.com/Recex/Licenses/master/SharedSourceLicense/LICENSE.txt>
]]
require("stategraphs/commonforgestates")
local tuning_values = TUNING.FORGE.BOARRIOR

-- Randomly returns a target in midrange that is not the current target, if no targets are in midrange then returns nil
local function GetMidRangeTarget(inst)
	local slam_options = inst.components.combat:GetAttackOptions("random_slam")
	local targets = COMMON_FNS.GetTargetsWithinRange(inst, slam_options.min_range, slam_options.max_range, {include_tags = {"player"}}) -- Random Slam only targets players.
	return #targets > 0 and targets[math.random(1,#targets)]
end

local function AttemptDash(inst)
	if inst.components.combat:IsAttackReady("dash") and inst.components.combat.target and not inst.components.combat:CanAttack(inst.components.combat.target) then
		inst.sg:GoToState("dash")
	end
end

-- Attempts to slam a random valid target that is not the current target
local function AttemptSlam(inst)
	if inst.components.combat:IsAttackReady("random_slam") then
		local target = GetMidRangeTarget(inst)
		if target then
			inst.sg:GoToState("attack_slam", {target = target, forced = true})
			return true
		end
	end
	return false
end

local function ShakeIfClose(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, .5, .02, .2, inst, 30)
end

local function ShakeRoar(inst) -- TODO does it have different shakes or are all shakes the same?
    ShakeAllCameras(CAMERASHAKE.FULL, 0.7, .03, .5, inst, 30)
end

local actionhandlers = { -- TODO are these needed?
    ActionHandler(ACTIONS.GOHOME, "action"),
	ActionHandler(ACTIONS.ATTACK, function(inst)
		return inst.components.combat:IsAttackReady("slam") and "attack_slam" or "attack"
	end),
}

local function SetBanner(inst)
	local wave = TheWorld.components.lavaarenaevent
	local current_round = wave and wave:GetCurrentRound()
	return wave and wave.waveset_data[current_round] and wave.waveset_data[current_round].banner or "battlestandard_heal"
end

-- Spawn banners in a circle in a random order
local function SpawnBanners(inst)
    COMMON_FNS.SpawnEntsInCircle(inst, inst.components.combat:GetAttackOptions("reinforcements").banner_opts, inst.banners)
end

-- Checks if target is within Boarriors melee range.
local function IsTargetInMeleeRange(inst, target)
	return COMMON_FNS.IsTargetInRange(inst, target, nil, inst.components.combat.attackrange, {ignore_scaling = true})
end

-- Checks if target is outside Boarriors basic attack range.
local function IsTargetInSlamRange(inst, target)
	local slam_options = inst.components.combat:GetAttackOptions("slam")
	return COMMON_FNS.IsTargetInRange(inst, target, slam_options.min_range, slam_options.max_range)
end

local ICE_LANCE_RADIUS = 3.9
local AREAATTACK_MUST_TAGS = { "_combat" }
local AREA_EXCLUDE_TAGS = { "INLIMBO", "notarget", "noattack", "flight", "invisible", "playerghost", "deerclops", "LA_mob"}

local function DoIceLanceAOE(inst, pt, targets)
	inst.components.combat.ignorehitrange = true
	local dist = math.sqrt(inst:GetDistanceSqToPoint(pt))
	local ents = TheSim:FindEntities(pt.x, 0, pt.z, ICE_LANCE_RADIUS, AREAATTACK_MUST_TAGS, AREA_EXCLUDE_TAGS)
	for i, v in ipairs(ents) do
		if not targets[v] and v:IsValid() and not v:IsInLimbo() and
			not (v.components.health ~= nil and v.components.health:IsDead()) and
			inst.components.combat:CanTarget(v)
		then
			local wasfrozen = v.components.freezable ~= nil and v.components.freezable:IsFrozen()
			inst.components.combat:DoAttack(v)
			if wasfrozen then
				v:PushEvent("knockback", { knocker = inst, radius = dist + ICE_LANCE_RADIUS })
			end
			targets[v] = true
		end
	end
	if not inst.components.combat:IsAttackReady("slam") then inst.components.combat.ignorehitrange = false end
end

local boarrior_sg = deepcopy(require "stategraphs/SGboarrior")
local Death_State = boarrior_sg.states.death
local _oldDeathEnter = Death_State.onenter
Death_State.onenter = function(inst)
	_oldDeathEnter(inst)
	inst.want_banner = false
	inst.ice_continue = false
end

local events = {
	CommonForgeHandlers.OnAttacked(),
    CommonForgeHandlers.OnKnockback(),
	CommonHandlers.OnDeath(),
	CommonForgeHandlers.OnSleep(),
	CommonForgeHandlers.OnFossilize(),
	CommonForgeHandlers.OnTimeLock(),
    --CommonHandlers.OnFreeze(),
    EventHandler("doattack", function(inst, data)
		if not inst.components.health:IsDead() and not (inst.sg:HasStateTag("hit") or inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("nointerrupt")) then -- TODO common if branch? so common fn?
			if inst.components.combat:IsAttackReady("ice_attack") then
				inst.sg:GoToState("banner_pre")
				inst.components.combat:StartCooldown("ice_attack")
			elseif inst.components.combat:IsAttackReady("slam") and IsTargetInSlamRange(inst, data.target) then -- TODO there is a range gap between the slam and melee range where it will prevent boarrior from attacking.
				inst.sg:GoToState("attack_slam", {target = data.target})
			elseif IsTargetInMeleeRange(inst, data.target) and not AttemptSlam(inst) then
				if inst.components.combat:IsAttackReady("spin") then
					inst.sg:GoToState("attack_spin")
				else
					inst.sg:GoToState("attack", {target = data.target})
				end
			elseif inst.components.combat:IsAttackReady("dash") then
				inst.sg:GoToState("dash", data.target)
			end
		end
	end),
    CommonHandlers.OnLocomote(false,true),
}

local banner_call_timer = 2

local states = {
	State{
		name = "banner_pre",
        tags = {"busy", "nointerrupt"},

        onenter = function(inst, cb)
            inst.components.sleeper:SetResistance(9999)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("banner_pre")
			if inst.want_banner then
				banner_call_timer = 5
				inst:DoTaskInTime(2, SpawnBanners)
				TheWorld.components.lavaarenaevent:QueueWave(nil, true, inst.components.combat:GetAttackOptions("reinforcements").wave)
				inst.ice_continue = true
				inst.doing_banner = true
				inst.want_banner = false
				inst:DoTaskInTime(2, function(inst)
					inst.doing_banner = nil
				end)
			else 
				if not inst.banner_call_timer then
					banner_call_timer = 2
				end
			end
			inst.banner_call_timer = inst:DoTaskInTime(banner_call_timer, function(inst) -- TODO tuning?                   
				if not inst.doing_banner then
					inst.banner_call_timer = nil
				end
			end)
        end,

		timeline = {},

        events = {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("banner_loop")
			end),
        },
    },

	State{
		name = "banner_loop",
        tags = {"busy", "nointerrupt", "nofreeze"},

        onenter = function(inst, cb)
			inst.components.sleeper:SetResistance(9999)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("banner_loop", true)
        end,

		timeline = {
			TimeEvent(0, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.banner_call_a)
				local ice_circle = SpawnPrefab("deerclops_icelance_ping_fx")
				
				ice_circle.Transform:SetScale(0.75, 0.75, 0.75)
				ice_circle.AnimState:SetMultColour(255, 0, 0, 1)
				ice_circle.AnimState:SetAddColour(1, 0, 0, 0)
				ice_circle.AnimState:SetLightOverride(1)
				ice_circle.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
				ice_circle.disc.AnimState:SetMultColour(255, 0, 0, 1)
				ice_circle.disc.AnimState:SetAddColour(1, 0, 0, 0)

				local players = {}
				for _,player in pairs(AllPlayers) do
					if not player.components.health:IsDead() then
						table.insert(players,player)
					end
				end

			--[[
				local function GetRangeTarget(inst)
					local targets = COMMON_FNS.GetTargetsWithinRange(inst, 0, 10000, {include_tags = {"player"}}) -- Random Slam only targets players.
					return #targets > 0 and targets[math.random(1,#targets)]
				end
				local target = GetRangeTarget(inst)
				local pos = target and target:GetPosition() or _G.Vector3(0,0,0)
			]]--

				local pos = players and players[math.random(1,#players)]:GetPosition() or _G.Vector3(0,0,0)
				ice_circle.Transform:SetPosition(pos:Get())
				local ice_circle_pos = ice_circle:GetPosition()	
				inst:DoTaskInTime(2,function(inst, data) 
					if inst:IsValid() and not inst.components.health:IsDead() then
						local ice_fx = SpawnPrefab("winter_impact_circle_fx")
						ice_fx.Transform:SetScale(0.75, 0.75, 0.75)
						ice_fx.Transform:SetPosition(ice_circle_pos:Get())
						inst.sg.statemem.targets = {}
						if inst.ice_continue then
							ice_fx:DoTaskInTime(2*_G.FRAMES, function()
								_G.RemoveTask(ice_fx, "deathtimer")
							end)
						end

						ice_fx:ListenForEvent("death",function()
							ice_fx:Remove()
						end, inst)
						
						DoIceLanceAOE(inst, ice_circle_pos, inst.sg.statemem.targets)
					end
				end)
				ice_circle:DoTaskInTime(3,function(inst, data)
					ice_circle:KillFX(true)
				end)
				ice_circle:ListenForEvent("death",function()
					ice_circle:KillFX(true)
				end, inst)
			end),
        },

        events = {
			EventHandler("animover", function(inst)
				if inst.banner_call_timer then
					inst.sg:GoToState("banner_loop")
				else
					inst.sg:GoToState("banner_pst")
				end
			end),
        },
    },

	State{
		name = "banner_pst",
        tags = {"busy"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("banner_pst")
        end,

		timeline = {},

		onexit = function(inst)
            inst.components.sleeper:SetResistance(1)
        end,

        events = {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
        },
    },

    State{
        name = "attack", --swipe
        tags = {"attack", "busy", "pre_attack"},

		onenter = function(inst, data)
			inst.components.combat:StartAttack() -- TODO should this be in each swipe of the combo? it looks like the attack period starts on the first attack, Leo double check this.
			inst.components.locomotor:Stop()
			-- Reset the spin attack
            inst.components.combat:ToggleAttack("spin", true)
			inst.sg.statemem.target = data and data.target or inst.components.combat.target
			if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
				inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())
			end
			inst.SoundEmitter:PlaySound(inst.sounds.swipe_pre)
			inst.AnimState:PlayAnimation("attack1")
		end,

		timeline = {
			TimeEvent(8*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.swipe)
			end),
            TimeEvent(11*FRAMES, function(inst)
				COMMON_FNS.DoAOE(inst, nil, tuning_values.DAMAGE, {offset = tuning_values.FRONT_AOE_OFFSET, range = tuning_values.AOE_HIT_RANGE})
				if not inst.components.combat:IsAttackReady("combo") or inst.sg.statemem.target and (inst.sg.statemem.target.components.health:IsDead() or not COMMON_FNS.IsTargetInRange(inst, inst.sg.statemem.target, nil, inst.components.combat.hitrange, {ignore_scaling = true})) then -- TODO should this be here or in the eventhandler?
					inst.AnimState:PushAnimation("attack1_pst", false)
                    inst.sg:RemoveStateTag("pre_attack")
				end
			end),
		},

        events = {
            EventHandler("animqueueover", function(inst)
				if inst.components.combat:IsAttackReady("combo") and inst.sg.statemem.target and not inst.sg.statemem.target.components.health:IsDead() and COMMON_FNS.IsTargetInRange(inst, inst.sg.statemem.target, nil, inst.components.combat.hitrange, {ignore_scaling = true}) then
					inst.sg:GoToState("attack2", inst.sg.statemem.target)
				else
					inst.sg:GoToState("idle")
				end
			end),
        },
    },

	State{
        name = "attack2", --swipe
        tags = {"attack", "busy", "pre_attack"},

		onenter = function(inst, target)
			inst.sg.statemem.target = target
			if inst.sg.statemem.target then
				inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())
			end
			inst.components.locomotor:Stop()
			inst.SoundEmitter:PlaySound(inst.sounds.swipe_pre)
			inst.AnimState:PlayAnimation("attack2")
			inst.Physics:SetMotorVelOverride(10,0,0)
		end,

		timeline = {
            TimeEvent(4*FRAMES, function(inst)
				COMMON_FNS.DoAOE(inst, nil, tuning_values.DAMAGE, {offset = tuning_values.FRONT_AOE_OFFSET, range = tuning_values.AOE_HIT_RANGE})
				if inst.sg.statemem.target and (inst.sg.statemem.target.components.health:IsDead() or not COMMON_FNS.IsTargetInRange(inst, inst.sg.statemem.target, nil, inst.components.combat.hitrange, {ignore_scaling = true})) then -- TODO should this be here or in the eventhandler?
					inst.AnimState:PushAnimation("attack2_pst", false)
                    inst.sg:RemoveStateTag("pre_attack")
				end
			end),
			TimeEvent(6*FRAMES, function(inst)
				inst.Physics:ClearMotorVelOverride()
				inst.components.locomotor:Stop()
				inst.SoundEmitter:PlaySound(inst.sounds.swipe)
			end),
		},

        events = {
            EventHandler("animqueueover", function(inst)
				if inst.sg.statemem.target and not inst.sg.statemem.target.components.health:IsDead() and COMMON_FNS.IsTargetInRange(inst, inst.sg.statemem.target, nil, inst.components.combat.hitrange, {ignore_scaling = true}) then
					inst.sg:GoToState("attack3", inst.sg.statemem.target)
				else
					inst.sg:GoToState("idle")
				end
			end),
        },
    },

	State{
        name = "attack3", --final swipe
        tags = {"attack", "busy", "pre_attack"},

		onenter = function(inst, target)
			inst.sg.statemem.target = target
			inst.components.locomotor:Stop()
			inst.SoundEmitter:PlaySound(inst.sounds.swipe_pre)
			inst.AnimState:PlayAnimation("attack3")
			if inst.sg.statemem.target then
				inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())
			end
			inst.Physics:SetMotorVelOverride(10,0,0)
		end,

		timeline = {
			TimeEvent(6*FRAMES, function(inst)
				inst.Physics:ClearMotorVelOverride()
				inst.components.locomotor:Stop()
				ShakeIfClose(inst)
				COMMON_FNS.DoAOE(inst, nil, tuning_values.DAMAGE, {offset = tuning_values.FRONT_AOE_OFFSET, range = tuning_values.AOE_HIT_RANGE})
				inst.SoundEmitter:PlaySound(inst.sounds.swipe)
				inst.SoundEmitter:PlaySound(inst.sounds.taunt_2)
                inst.sg:RemoveStateTag("pre_attack")
			end),
		},

        events = {
            EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
			end),
        },
    },

	State{
        name = "attack_slam",
        tags = {"attack", "busy", "pre_attack"},

		onenter = function(inst, data)
			inst.is_doing_special = true --To prevent knockback effects
			inst.Transform:SetEightFaced()
			inst.components.locomotor:Stop()
			inst.SoundEmitter:PlaySound(inst.sounds.grunt)

			-- Reset attacks
			if not (data and data.forced) then
                inst.components.combat:ToggleAttack("spin", true)
			elseif data and data.forced then
                inst.components.combat:StartCooldown("random_slam")
			end

			inst.AnimState:PlayAnimation("attack5")
			inst.sg.statemem.target = data and data.target or inst.components.combat.target
			if inst.sg.statemem.target then
				if inst.sg.statemem.target == inst.components.combat.target then
					inst.components.combat:StartAttack() -- sets last attack time and faces target
				elseif inst.sg.statemem.target:IsValid() then
					inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())
				end
			end
		end,

		onexit = function(inst)
			inst.Transform:SetFourFaced()
			--Leo: TODO: simply just make the trails do no knockback on their own.
			inst:DoTaskInTime(0.25, function(inst) --Leo: Give a little bit of time after the state ends before setting it to nil.
				inst.is_doing_special = nil -- TODO how does this prevent knockback effects?
			end)
		end,

		timeline = {
			TimeEvent(12*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.attack_5)
			end),
			TimeEvent(15*FRAMES, function(inst)
				if inst.sg.statemem.target then
					inst.sg.statemem.target_pos = inst.sg.statemem.target:GetPosition()
					inst:FacePoint(inst.sg.statemem.target_pos)
					COMMON_FNS.DoAOE(inst, nil, tuning_values.DAMAGE, {offset = tuning_values.FRONT_AOE_OFFSET, range = tuning_values.AOE_HIT_RANGE})
					if inst.components.combat:IsAttackReady("slam_trail") then
						inst:DoSlamTrail(inst.sg.statemem.target_pos)
					end
				end
				inst.sg:AddStateTag("nointerrupt") -- TODO check that this is the correct frame? probably is since the attack occurs on this frame
                inst.sg:RemoveStateTag("pre_attack")
				ShakeIfClose(inst)
			end),
			TimeEvent(35*FRAMES, function(inst)
				if inst.sg.statemem.target_pos then
					COMMON_FNS.DoAOE(inst, nil, tuning_values.DAMAGE, {offset = tuning_values.FRONT_AOE_OFFSET, range = tuning_values.AOE_HIT_RANGE})
					if inst.components.combat:IsAttackReady("slam_trail") then
						inst:DoSlamTrail(inst.sg.statemem.target_pos, true)
					end
				end
				inst.sg:RemoveStateTag("nointerrupt")
				ShakeIfClose(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.attack_5_fire_1)
			end),
			TimeEvent(37*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.attack_5_fire_2)
			end),
		},

        events = {
            EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
			end),
        },
    },

	State{
		name = "attack_spin",
        tags = {"busy", "pre_attack"},

        onenter = function(inst, cb)
            inst.components.combat:ToggleAttack("spin", false)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("attack4")
			inst.components.combat:StartAttack()
        end,

		timeline = {
			TimeEvent(0*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.spin)
			end),
			TimeEvent(13*FRAMES, function(inst)
				inst.components.combat:DoAreaAttack(inst, inst.components.combat.hitrange, nil, nil, nil, COMMON_FNS.GetAllyTags(inst))
                inst.sg:RemoveStateTag("pre_attack")
			end),
			TimeEvent(31*FRAMES, function(inst)
				inst.components.combat:DoAreaAttack(inst, inst.components.combat.hitrange, nil, nil, nil, COMMON_FNS.GetAllyTags(inst))
			end),
        },

        events ={
			EventHandler("onhitother", function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.swipe)
			end),
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
        },
    },

	State{
        name = "dash",
        tags = { "nointerrupt", "moving", "canrotate", "attack" }, -- "attack" tag added to prevent boarrior attacking middash

        onenter = function(inst)
            inst.AnimState:PlayAnimation("dash")
			inst.SoundEmitter:PlaySound(inst.sounds.grunt)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
        end,

		onexit = function(inst)
			inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "dash")
		end,

		timeline = {
			TimeEvent(2*FRAMES, function(inst)
				inst.components.locomotor:SetExternalSpeedMultiplier(inst, "dash", 5)
				inst.components.locomotor:WalkForward()
			end),
			TimeEvent(13*FRAMES, function(inst)
				ShakeIfClose(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.step)
			end),
		},

        events = {
            EventHandler("animover", function(inst)
				inst.components.locomotor:StopMoving()
				inst.sg:GoToState("idle")
			end),
        },
    },
}

CommonForgeStates.AddIdle(states)
CommonStates.AddWalkStates(states, {
	walktimeline = {
		TimeEvent(0, function(inst)
			ShakeIfClose(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
		TimeEvent(10*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.grunt)
		end),
		TimeEvent(20*FRAMES, function(inst)
			ShakeIfClose(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
	},
	endtimeline = {
		TimeEvent(0, function(inst)
			ShakeIfClose(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
	}
})
CommonForgeStates.AddSleepStates(states, {
	starttimeline = {
		TimeEvent(11*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
		TimeEvent(12*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.bone_drop)
		end),
		TimeEvent(19*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
		TimeEvent(20*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.bone_drop)
		end),
	},
	sleeptimeline = {
		TimeEvent(20*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.sleep_out)
		end),
    },
	waketimeline = {
		TimeEvent(0, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.grunt)
		end),

		TimeEvent(5*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.bone_drop)
		end),
		TimeEvent(7*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
	},
})
CommonForgeStates.AddHitState(states, nil, nil, {
    EventHandler("animover", function(inst)
        if inst.banner_call_timer then
            inst.sg:GoToState("banner_pre")
        else
            inst.sg:GoToState("idle")
        end
    end),
})
CommonForgeStates.AddDeathState(states, {
	TimeEvent(30*FRAMES, function(inst)
		inst.SoundEmitter:PlaySound(inst.sounds.bonehit1)
	end),
	TimeEvent(50*FRAMES, function(inst)
		inst.SoundEmitter:PlaySound(inst.sounds.bonehit1)
	end),
	TimeEvent(55*FRAMES, function(inst)
		ShakeRoar(inst)
		inst.SoundEmitter:PlaySound(inst.sounds.death_bodyfall)
	end),
	TimeEvent(70*FRAMES, function(inst)
		inst.SoundEmitter:PlaySound(inst.sounds.bonehit2)
	end),
}, "death2", nil, {
    onenter = function(inst)
        inst:AddTag("NOCLICK")
        ChangeToObstaclePhysics(inst)
        inst.Physics:ClearCollidesWith(COLLISION.FLYERS)
        inst.SoundEmitter:PlaySound(inst.sounds.death)
    end,
})
local taunt_timeline = {
	TimeEvent(15*FRAMES, function(inst)
		ShakeRoar(inst)
		inst.SoundEmitter:PlaySound(inst.sounds.taunt)
	end),
}
CommonForgeStates.AddTauntState(states, taunt_timeline, nil, {
	EventHandler("animover", function(inst)
		if inst.banner_call_timer then -- TODO can he taunt when in banner_pre????
			inst.sg:GoToState("banner_pre")
		else
			inst.sg:GoToState("idle")
		end
	end),
})
CommonForgeStates.AddSpawnState(states, taunt_timeline)
CommonForgeStates.AddStunStates(states, {
	stuntimeline = {
		TimeEvent(0, function(inst)
			inst.components.sleeper:SetResistance(1) --incase banner state gets interrupted at the exact moment the last banner call ends. TODO doesn't onexit still get called for the banner state????
		end),
		TimeEvent(5*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.stun)
		end),
		TimeEvent(10*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.stun)
		end),
		TimeEvent(15*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.stun)
		end),
		TimeEvent(20*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.stun)
		end),
		TimeEvent(25*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.stun)
		end),
		TimeEvent(30*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.stun)
		end),
		TimeEvent(35*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.stun)
		end),
		TimeEvent(40*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.stun)
		end),
	},
}, nil, nil, nil, {
	stopstun = {
		EventHandler("animover", function(inst)
			if inst.banner_call_timer then
				inst.sg:GoToState("banner_pre")
			else
				if inst.sg.stun_stimuli and (inst.sg.stun_stimuli == "explosive") then
					inst.sg:GoToState("taunt")
				else
					inst.sg:GoToState("idle")
				end
			end
			inst.sg.stun_stimuli = nil
		end),
	},
})
CommonForgeStates.AddActionState(states, {
	TimeEvent(0, function(inst)
		inst.SoundEmitter:PlaySound(inst.sounds.step)
	end),
}, "walk_pst") -- TODO what is this?
CommonForgeStates.AddKnockbackState(states)
--CommonStates.AddFrozenStates(states)
CommonForgeStates.AddFossilizedStates(states, {
	fossilizedtimeline = { -- TODO sound seems a bit off and the last hits don't seem to make sound
		TimeEvent(22*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/fossilized_hit")
		end),
		TimeEvent(33*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/fossilized_hit")
		end),
		TimeEvent(44*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/fossilized_hit")
		end),
		TimeEvent(55*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/fossilized_hit")
		end),
		TimeEvent(66*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/fossilized_hit")
		end),
		TimeEvent(77*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/fossilized_hit")
		end),
		TimeEvent(88*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/fossilized_hit")
		end),
		TimeEvent(99*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/fossilized_hit")
		end),
		TimeEvent(110*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/fossilized_hit")
		end),
		TimeEvent(121*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/fossilized_hit")
		end),
	},
},{},{
	fossilized = "dontstarve/common/lava_arena/fossilized_pre_2",
},{
	fossilized_onenter = function(inst, data)
        inst.AnimState:PushAnimation("fossilized_loop", true)
    end,
})
CommonForgeStates.AddTimeLockStates(states)

return StateGraph("boarrior", states, events, "spawn", actionhandlers)
