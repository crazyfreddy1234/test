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
local tuning_values = TUNING.INFORGE.BOARILLA
local ROLL_MAX_ROTATION = 3.5

local function ShakeIfClose(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, .5, .02, .2, inst, 30)
end

local function ShakePound(inst)
	inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/bodyfall_dirt")
    ShakeAllCameras(CAMERASHAKE.FULL, 1.2, .03, .7, inst, 30)
end

local function ShakeRoar(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, 0.8, .03, .5, inst, 30)
end

local function RollingCondition(inst)
	return inst.sg:HasStateTag("rolling")
end

local function RollAOE(inst)
	COMMON_FNS.DoAOE(inst, nil, tuning_values.DAMAGE, {range = 3, invulnerability_time = 1}) -- TODO tuning, also does not get damage from buffs like banners....use our buff system to get damage...
end

local function OnRollComplete(inst)
	inst.roll_thread = nil
end

local actionhandlers = {
    ActionHandler(ACTIONS.GOHOME, "action"),
	ActionHandler(ACTIONS.ATTACK, "attack"),
}

local events = {
	CommonForgeHandlers.OnAttacked(),
	CommonForgeHandlers.OnKnockback(),
	CommonForgeHandlers.OnEnterShield(),
	CommonForgeHandlers.OnExitShield(),
	CommonForgeHandlers.OnSleep(),
	CommonHandlers.OnDeath(),
	CommonHandlers.OnLocomote(true,false),
    CommonForgeHandlers.OnFreeze(),
	CommonForgeHandlers.OnFossilize(),
	CommonForgeHandlers.OnTimeLock(),
    EventHandler("doattack", function(inst, data)
		if not inst.components.health:IsDead() and not (inst.sg:HasStateTag("hit") or inst.sg:HasStateTag("busy")) then
			if inst.components.combat:IsAttackReady("sniper_dps") then
				inst.sg:GoToState("sniper_dps", data.target)
			else
				inst.sg:GoToState("attack", data.target)
			end
		end
	end),
}

local states = {

	State{
        name = "sniper_dps", -- TODO falls asleep as it lands which cancels the slam, need to set nosleep tag at the correct frame
        tags = {"attack", "busy", "pre_attack"},

		onenter = function(inst, target)
			if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("attack")
            inst.components.combat:StartAttack()

            if target and target:IsValid() then
				inst:FacePoint(target:GetPosition())
				inst.sg.statemem.target = target
			end
			
            if fns.onenter then
                fns.onenter(inst)
            end
		end,

		onexit = function(inst)

		end,

		timeline = {

		},

        events = {

        },
    },
	
	State{
        name = "attack_slam", -- TODO falls asleep as it lands which cancels the slam, need to set nosleep tag at the correct frame
        tags = {"attack", "busy", "jumping", "keepmoving", "pre_attack"},

		onenter = function(inst, target)
			inst.components.combat:StartAttack()
			inst.components.locomotor:Stop()
			ToggleOffCharacterCollisions(inst)
			inst.AnimState:PlayAnimation("attack1")
			if target and target:IsValid() then
				inst:FacePoint(target:GetPosition()) -- TODO doesn't startattack face target? hmmm maybe if boarilla loses target during slam?
				inst.sg.statemem.target = target
			end
		end,

		onexit = function(inst)
			inst.components.item_launcher:Enable(false)
			ToggleOnCharacterCollisions(inst)
			inst.components.combat:StartCooldown("slam")
		end,

		timeline = {
			TimeEvent(10*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.grunt)
				COMMON_FNS.JumpToPosition(inst, inst.sg.statemem.target and inst.sg.statemem.target:GetPosition(), 13) -- TODO should it be 15 frames???
				inst.sg:RemoveStateTag("pre_attack")
			end),
			TimeEvent(12*FRAMES, function(inst)
				if inst.components.combat.target and inst.components.combat.target:IsValid() then
					inst:FacePoint(inst.components.combat.target:GetPosition()) -- TODO is this needed?
				end
			end),
			TimeEvent(18*FRAMES, function(inst)
				inst.components.locomotor:Stop()
			end),
			TimeEvent(20*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.attack1)
				ShakePound(inst)
			end),
			TimeEvent(23*FRAMES, function(inst)
				inst.components.item_launcher:Enable(true) -- TODO attack hits on this frame? but the sound is 3 frames earlier?
				COMMON_FNS.DoAOE(inst, nil, tuning_values.DAMAGE, {range = 3, stimuli = "strong"}) -- TODO why offset???
				ToggleOnCharacterCollisions(inst)
			end),
		},

        events = {
            EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
			end),
        },
    },

	State{
        name = "attack_roll_pre",
        tags = {"busy", "attack", "keepmoving", "pre_attack"},

		onenter = function(inst, target)
			inst.components.locomotor:Stop()
			inst.sg.statemem.target = target or inst.components.combat.target

			inst.components.combat:StartAttack()

			inst.AnimState:PlayAnimation("roll_pre")

			-- Start Cooldown
			-- If roll has been interrupted before leaving this state then cut the cooldown in half and force Roll to be unavailable.
			if inst.components.combat:InCooldown("roll") then
				inst.components.combat.ignorehitrange = false
				inst.components.combat:StartCooldown("roll", inst.components.combat:GetTotalCooldown("roll", true)/2)
			else
				inst.components.combat:StartCooldown("roll")
			end
		end,

		onexit = function(inst)
			inst.components.item_launcher:Enable(false)
		end,

		timeline = {},

        events = {
            EventHandler("animover", function(inst)
				inst.components.combat.ignorehitrange = false
				inst.attack_roll_timer = inst:DoTaskInTime(tuning_values.ROLL_DURATION, function(inst)
					inst.attack_roll_timer = nil
				end)
				inst.sg:GoToState("attack_roll_loop", inst.sg.statemem.target)
			end),
        },
    },

	State{
        name = "attack_roll_loop",
        tags = {"attack", "busy", "rolling", "delaysleep", "nofreeze", "keepmoving", "pre_attack"},

		onenter = function(inst, target)
			inst.sg.statemem.target = target

			ToggleOffCharacterCollisions(inst)
			inst.Physics:SetMotorVelOverride(inst.components.locomotor.walkspeed*1.2, 0, 0) -- TODO tuning??? speed? or mult?
			inst.components.item_launcher:Enable(true)

			inst.AnimState:PlayAnimation("roll_loop")
			if not inst.roll_thread then
				inst.roll_thread = CreateConditionThread(inst, "attack_roll_aoe", 0, 0.1, RollingCondition, RollAOE, OnRollComplete)
			end
		end,

		onupdate = function(inst)
			if not inst.sg.statemem.target_hit and inst.sg.statemem.target and inst.components.combat:IsValidTarget(inst.sg.statemem.target) then
				local current_rotation = inst.Transform:GetRotation()
				local angle_to_target = inst:GetAngleToPoint(inst.sg.statemem.target:GetPosition())
				local angle = (current_rotation - angle_to_target + 180) % 360 - 180 -- -180 <= angle < 180, 181 = -179
				local next_rotation = math.abs(angle) <= ROLL_MAX_ROTATION and angle or ROLL_MAX_ROTATION * (angle < 0 and -1 or 1)
				inst.Transform:SetRotation(current_rotation - next_rotation)
			end
		end,

		onexit = function(inst)
			ToggleOnCharacterCollisions(inst)
			inst.components.item_launcher:Enable(false)
		end,

		timeline = {
			TimeEvent(0, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.step)
				ShakeIfClose(inst)
			end),
			TimeEvent(6*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.step)
				ShakeIfClose(inst)
			end),
			TimeEvent(12*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.step)
				ShakeIfClose(inst)
			end),
		},

        events = {
            EventHandler("animover", function(inst)
				if inst.attack_roll_timer and not inst.sg.statemem.target_hit and inst.sg.statemem.target and inst.components.combat:IsValidTarget(inst.sg.statemem.target) and not inst.sg.mem.sleep_duration then
					inst.sg:GoToState("attack_roll_loop", inst.sg.statemem.target)
				else
					RemoveTask(inst.attack_roll_timer)
					inst.sg:GoToState("attack_roll_pst", inst.sg.statemem.target)
				end
			end),
			EventHandler("onattackother", function(inst, data)
				if data.target == inst.sg.statemem.target then
					inst.sg.statemem.target_hit = true
				end
			end),
        },
    },

	State{
        name = "attack_roll_pst",
        tags = {"busy", "attack", "rolling", "keepmoving", "delaysleep", "pre_attack"},

		onenter = function(inst, target)
			inst.sg.statemem.target = target
			inst.AnimState:PlayAnimation("roll_pst")
			ToggleOffCharacterCollisions(inst)
			inst.Physics:SetMotorVelOverride(inst.components.locomotor.walkspeed*1.2, 0, 0) -- TODO tuning??? speed? or mult?
		end,

		timeline = {
			TimeEvent(0, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.step)
				ShakeIfClose(inst)
			end),
			TimeEvent(6*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.step)
				ShakeIfClose(inst)
			end),
			TimeEvent(9*FRAMES, function(inst)
				if not inst.components.sleeper:IsAsleep() and inst.components.combat:IsAttackActive("slam") and inst.components.combat:IsValidTarget(inst.sg.statemem.target) then
					inst.sg:GoToState("attack_slam", inst.sg.statemem.target)
				end
			end),
			TimeEvent(12*FRAMES, function(inst) -- TODO was 11, double check frame
				inst.SoundEmitter:PlaySound(inst.sounds.step)
				ShakeIfClose(inst)
				inst.components.locomotor:Stop() -- TODO shouldn't this be in an earlier frame?
				ToggleOnCharacterCollisions(inst)
				inst.sg:RemoveStateTag("rolling")
			end),
		},

        events = {
            EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
        },
    },
}

CommonForgeStates.AddIdle(states)
CommonStates.AddRunStates(states, {
	runtimeline = {
		TimeEvent(0, function(inst)
			inst.components.locomotor:WalkForward()
            inst.SoundEmitter:PlaySound(inst.sounds.run)
        end),
        TimeEvent(2*FRAMES, function(inst)
			inst.components.locomotor:RunForward()
            inst.SoundEmitter:PlaySound(inst.sounds.step)
            ShakeIfClose(inst)
        end),
		TimeEvent(11*FRAMES, function(inst)
			inst.components.locomotor:WalkForward()
		end),
	},
	endtimeline = {
		TimeEvent(0, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
	},
})
CommonForgeStates.AddSleepStates(states, {
	sleeptimeline = {
		TimeEvent(0, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.sleep_in)
		end),
		TimeEvent(20*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.sleep_out)
		end),
    },
	waketimeline = {
		TimeEvent(1*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
	},
},{
	onsleep = function(inst)
		ToggleOnCharacterCollisions(inst) --TODO Fixes sliding, find out the real fix
	end,
})
CommonForgeStates.AddCombatStates(states, {
    attacktimeline = {
		TimeEvent(7*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.swish)
		end),
		TimeEvent(13*FRAMES, function(inst)
			COMMON_FNS.DoAOE(inst, nil, tuning_values.DAMAGE, {offset = tuning_values.FRONT_AOE_OFFSET, range = tuning_values.HIT_RANGE, stimuli = "strong"})
			inst.SoundEmitter:PlaySound(inst.sounds.attack2)
			inst.sg:RemoveStateTag("pre_attack")
		end),
    },
    deathtimeline = {
		TimeEvent(11*FRAMES, function(inst)
			ShakeIfClose(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.bodyfall)
			inst.SoundEmitter:PlaySound(inst.sounds.hide_pre)
		end),
    },
},{
    attack = "attack2",
}, nil, {
	onenter_attack = function(inst)
		inst.SoundEmitter:PlaySound(inst.sounds.grunt)
	end,
	onenter_death = function(inst)
		inst.SoundEmitter:PlaySound(inst.sounds.taunt)
	end,
})
local taunt_timeline = {
	TimeEvent(20*FRAMES, function(inst)
		ShakeRoar(inst)
		inst.SoundEmitter:PlaySound(inst.sounds.step)
		inst.SoundEmitter:PlaySound(inst.sounds.taunt)
	end),
}
CommonForgeStates.AddTauntState(states, taunt_timeline)
CommonForgeStates.AddSpawnState(states, taunt_timeline)
CommonForgeStates.AddKnockbackState(states)
CommonForgeStates.AddStunStates(states, {
	stuntimeline = {
		TimeEvent(5*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.hit)
		end),
		TimeEvent(10*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.hit)
		end),
		TimeEvent(15*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.hit)
		end),
		TimeEvent(20*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.hit)
		end),
		TimeEvent(25*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.hit)
		end),
		TimeEvent(30*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.hit)
		end),
		TimeEvent(35*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.hit)
		end),
		TimeEvent(40*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.hit)
		end),
	},
}, nil, {
	stun = "grunt",
	hit = "grunt",
})
CommonForgeStates.AddHideStates(states, {
    starttimeline = {
		TimeEvent(7*FRAMES, function(inst) --TODO need to verify the accuracy of this
			inst.sg:AddStateTag("nointerrupt")
		end),
		TimeEvent(10*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.hide_pre) -- TODO change name, hide_pre to start_hiding?
        end),
    },
    endtimeline = {
        TimeEvent(10*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.hide_pst) -- TODO change name, hide_pst to stop_hiding?
        end),
    },
})
--CommonStates.AddFrozenStates(states)
CommonForgeStates.AddFossilizedStates(states, {
	fossilizedtimeline = {
		TimeEvent(8*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.sleep_out)
		end),
		TimeEvent(39*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.sleep_out)
		end),
		TimeEvent(71*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.sleep_out)
		end),
	},
},{
    fossilized = "fossilized_loop",
},{
	fossilized = "dontstarve/common/lava_arena/fossilized_pre_2",
},{
	fossilized_onenter = function(inst, data)
        inst.AnimState:PushAnimation("fossilized_loop", true)
    end,
})
CommonForgeStates.AddTimeLockStates(states)

return StateGraph("boarilla", states, events, "spawn", actionhandlers)
