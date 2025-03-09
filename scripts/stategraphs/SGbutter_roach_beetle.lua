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
local tuning_values = TUNING.INFORGE.ROACH_BEETLE

local actionhandlers = {
    ActionHandler(ACTIONS.PICKUP, "eat"),
}

local events = {
    CommonForgeHandlers.OnAttacked(),
	CommonForgeHandlers.OnKnockback(),
	CommonHandlers.OnDeath(),
    CommonHandlers.OnLocomote(true,false), --weevole has walk anims, final build will use "run animations"
    CommonForgeHandlers.OnFreeze(),
	CommonForgeHandlers.OnFossilize(true),
	CommonForgeHandlers.OnTimeLock(),
	EventHandler("flipped", function(inst, data) -- TODO common handler?
		if not inst.components.health:IsDead() then
			inst.sg:GoToState("flip_start")
			if TheWorld and TheWorld.components.stat_tracker and data.flipper then
				TheWorld.components.stat_tracker:AdjustStat("turtillusflips", data.flipper, 1)
			end
		end
	end),
	EventHandler("doattack", function(inst, data)
		if not inst.components.health:IsDead() and (not (inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("hit")) or inst.sg:HasStateTag("canattack")) then
            inst.sg:GoToState("attack", data.target)
		end
	end),
}

local function StopTimer(inst)
	if inst.explode_timer ~= nil then
		inst.explode_remaining_time = GetTaskRemaining(inst.explode_timer)
		RemoveTask(inst, "explode_timer")
	end
end

local states = {
	State{
        name = "eat",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.Physics:Stop()
			inst.SoundEmitter:PlaySound(inst.sounds.attack_pre)
            inst.AnimState:PlayAnimation("bite")
        end,

        onexit = function(inst)
        	inst:ClearBufferedAction()
        end,
        
        events = {
            EventHandler("animover", function(inst)
				inst:PerformBufferedAction()
                inst.sg:GoToState("idle")
            end),
        },
    },
	
	State{
        name = "land",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.Physics:Stop()
			inst.SoundEmitter:PlaySound(inst.sounds.shell)
            inst.AnimState:PlayAnimation("flip_pre", false)
			inst.AnimState:PushAnimation("flip_loop", false)
			inst.AnimState:PushAnimation("flip_loop", false)
			inst.AnimState:PushAnimation("flip_loop", false)
			inst.AnimState:PushAnimation("flip_pst", false)
        end,
        
        events = {
            EventHandler("animqueueover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
}

CommonForgeStates.AddIdle(states, nil, "idle_loop",nil,nil,{
	onenter = function(inst)
		if inst.explode_remaining_time ~= nil then
			inst.explode_timer = inst:DoTaskInTime(inst.explode_remaining_time,function(inst)
				if not inst.components.health:IsDead() then
					local pos = inst:GetPosition()
					local scale = inst.Transform:GetScale()
					local targets = COMMON_FNS.EQUIPMENT.GetAOETargets(inst, pos, tuning_values.RADIUS*scale, nil, COMMON_FNS.GetAllyTags(inst))
					local explosion = COMMON_FNS.CreateFX("firebomb_explosion")
		
					explosion.Transform:SetPosition(inst.Transform:GetWorldPosition())
		
					for _,target in pairs(targets) do
						inst.components.combat:DoAttack(target, nil, nil, nil, nil, tuning_values.EXPLODE_DAMAGE)
					end
					
					inst.SoundEmitter:PlaySound("dontstarve/common/blackpowder_explo")
					inst.components.health:SetAbsorptionAmount(0)
					inst.components.health:DoDelta(-inst.components.health.currenthealth)
				end
			end)
			inst.explode_remaining_time = nil
		end
	end
})
CommonForgeStates.AddCombatStates(states, {
	attacktimeline = { -- Bite
		TimeEvent(0*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.attack_pre)
		end),
		TimeEvent(10*FRAMES, function(inst)
			inst.components.combat:DoAttack()
            inst.sg:RemoveStateTag("pre_attack")
		end),
	},
},{
	attack = "bite",
})
CommonStates.AddWalkStates(states, {
	runtimeline = {
		TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.step) end),
		TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.step) end),
		TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.step) end),
		TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.step) end),
		TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.step) end),
		TimeEvent(16*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.step) end),
		TimeEvent(19*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.step) end),
	},
})
CommonStates.AddRunStates(states, {
	runtimeline = {
		TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.step) end),
		TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.step) end),
		TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.step) end),
		TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.step) end),
		TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.step) end),
		TimeEvent(16*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.step) end),
		TimeEvent(19*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.step) end),
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
},{
	onsleep = function(inst)
		StopTimer(inst)
	end,
})
CommonForgeStates.AddHitState(states)
CommonForgeStates.AddDeathState(states, {
	TimeEvent(0*FRAMES, function(inst)
		inst.SoundEmitter:PlaySound(inst.sounds.death)
	end),
})
local taunt_timeline = {
	TimeEvent(0*FRAMES, function(inst)
		inst.SoundEmitter:PlaySound(inst.sounds.taunt)
	end),
}
CommonForgeStates.AddFlipStates(states, TUNING.FORGE.SNORTOISE.FLIP_TIME)
CommonForgeStates.AddTauntState(states, taunt_timeline)
CommonForgeStates.AddSpawnState(states, taunt_timeline)
CommonForgeStates.AddKnockbackState(states)
CommonForgeStates.AddStunStates(states, nil, {stun = "stun_loop", stopstun = "stun_pst"}, nil, {
    onstun = function(inst)
        inst.components.health:SetAbsorptionAmount(0)
		inst:DoTaskInTime(0,function()
			inst.components.health:SetAbsorptionAmount(1)
		end)
    end,
})
CommonStates.AddFrozenStates(states)
CommonForgeStates.AddFossilizedStates(states,nil,nil,nil,{
	fossilized_onenter = function(inst)
		StopTimer(inst)
	end
})
CommonForgeStates.AddTimeLockStates(states,nil,nil,nil,{
	onenter = function(inst)
		StopTimer(inst)
	end
})

return StateGraph("roach_beetle", states, events, "spawn", actionhandlers)
