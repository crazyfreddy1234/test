require("stategraphs/commonforgestates")
local tuning_values = TUNING.FORGE.SWINECLOPS
-----------------------------------------------------
local function ShakeIfClose(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, .25, .015, .25, inst, 10)
end

local function ShakePound(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, 0.5, .03, .5, inst, 30)
end

local function ShakeRoar(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, 0.8, .03, .5, inst, 30)
end

local function DoPunchAOE(inst)
    COMMON_FNS.DoAOE(inst, nil, nil, {offset = 3, range = tuning_values.HIT_RANGE})
end

local function DoGroundPoundAOE(inst)
    COMMON_FNS.DoAOE(inst, nil, nil, {range = tuning_values.GROUNDPOUND_RANGE})
	COMMON_FNS.LaunchItems(inst, tuning_values.GROUNDPOUND_RANGE)
end

local function GroundPound(inst)
	ShakePound(inst)
	inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/bonehit2")
	inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/trails/bodyfall")
    inst.SoundEmitter:PlaySound(inst.sounds.hit_2)
    DoGroundPoundAOE(inst)
end

-- Checks if target is within Swineclops melee range.
local function IsTargetInMeleeRange(inst, target)
    return COMMON_FNS.IsTargetInRange(inst, target, nil, inst.components.combat.attackrange, {ignore_scaling = true})
end

-- Checks if target is outside Swineclops Body Slam range.
local function IsTargetInBodySlamRange(inst, target)
    local target = target or inst.components.combat.target
    local target_pos = target and target:GetPosition() or inst:GetPosition()
    local distance_to_target = distsq(target_pos, inst:GetPosition())
    local min_range = inst.components.combat.attackrange -- testing min range here since attackrange automatically receives scaling buffs, TODO might want to revise this
    return distance_to_target > min_range*min_range and COMMON_FNS.IsTargetInRange(inst, target, nil, tuning_values.ATTACK_BODY_SLAM_RANGE, {distance_override = distance_to_target})
end

local function ShouldBodySlam(inst)
    local target = inst.components.combat.target
    return not inst.components.combat:GetAttackOptions("guard").ShouldGuard(inst) and inst.sg.mem.wants_to_slam and inst.components.combat:IsAttackReady("body_slam") and (IsTargetInBodySlamRange(inst, target) or IsTargetInMeleeRange(inst, target))
end

local function DoBattleCryBuff(inst)
	-- Only apply buff if attack mode is available.
    if inst.modes.attack then
        inst._bufftype:set(2)
        inst.components.combat:AddDamageBuff("swineclops_battlecry_buff", tuning_values.BATTLECRY_BUFF, false)
        inst.components.combat.battlecryenabled = false -- Taunts are no longer available, instead only Forced Taunts occur which triggers Tantrum
    end
end

-- Returns true if the current combo should end.
local function EndCombo(inst, uppercut)
    local current_combo = inst.sg.statemem.current_combo
    local melee_range = IsTargetInMeleeRange(inst)
    -- Reset Body Slam if target ended a combo by running out of range.
    inst.sg.statemem.wants_to_slam = inst.sg.mem.wants_to_slam and melee_range
    -- End combo if completed or if target is dead or target is out of attack range.
    if current_combo >= inst.components.combat:GetAttackOptions("combo").max and not uppercut or not inst.components.combat:IsValidTarget(inst.sg.statemem.target) or not melee_range then
        inst.AnimState:PushAnimation("attack1_pst", false) -- TODO is there an attack2_pst for the other hand since it alternates between left and right punches
        return true
    end
    return false
end
-----------------------------------------------------
local events = {
    CommonForgeHandlers.OnAttacked(),
    CommonForgeHandlers.OnKnockback(),
    CommonForgeHandlers.OnVictoryPose(),
    CommonHandlers.OnDeath(),
    CommonForgeHandlers.OnFossilize(),
    CommonForgeHandlers.OnFreeze(),
    CommonForgeHandlers.OnTimeLock(),
    EventHandler("doattack", function(inst, data)
		if not inst.components.health:IsDead() and (inst.sg:HasStateTag("hit") or not inst.sg:HasStateTag("busy")) then
            -- TODO might need to remove this, don't think Swine slams heal aura while in guard mode unless he gets in it, need to find counterexamples. In the webber 6 man at 8:53ish the Swine walks around the Heal Aura because the target is not in attack range and then somehow gets into the heal aura and THEN slams.
            if not inst.want_to_stop and inst.wants_to_tantrum and not inst.components.combat:IsAttackActive("guard") and not inst.components.combat:GetAttackOptions("guard").ShouldGuard(inst) and not (inst.sg:HasStateTag("hit") or inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("nointerrupt")) then
                inst.sg:GoToState("tantrum")
                inst.wants_to_tantrum = nil
                inst:DoTaskInTime(30, function(inst)
                    if not inst.want_to_stop then
                        inst.wants_to_tantrum = true
                    end
                end)
            elseif data.target:HasTag("_isinheals") and inst.components.combat:IsAttackReady("body_slam") then
                inst.sg:GoToState("body_slam", data)
			elseif inst.components.combat:IsAttackActive("guard") then
				inst.sg:GoToState("jab")
			else
                local current_time = GetTime()
                if inst.modes.guard and (current_time - inst.components.combat.laststartattacktime) > 5 and not ((current_time - (inst.last_taunt_time or 0)) < 5) then -- TODO might be "lastdoattacktime", tuning
                    --inst.sg.mem.wants_to_guard = true
                    inst.sg:GoToState("block_pre")
				elseif (inst.components.combat:IsAttackReady("body_slam") or inst.sg.mem.wants_to_slam) and IsTargetInBodySlamRange(inst, data.target) then
					inst.sg:GoToState("body_slam", data)
				elseif IsTargetInMeleeRange(inst, data.target) then
					inst.sg:GoToState("attack", data)
				end
			end
		end
	end),
   EventHandler("gotosleep", function(inst)
        if not (inst.sg:HasStateTag("taunting") or inst:HasTag("fossilized") or inst.sg:HasStateTag("hiding") or (inst.components.health and inst.components.health:IsDead())) and inst.components.debuffable and inst.components.debuffable:CanBeDebuffedByDebuff("sleep") then
            -- Queue a Body Slam to occur after current attack.
            if inst.sg:HasStateTag("attack") then -- Body Slam does not have the "attacking" tag
                inst.sg.mem.wants_to_slam = true -- TODO should the cooldown be checked here? or checked in idle?
                --inst.components.sleeper.isasleep = false
            elseif not (inst.sg:HasStateTag("nofreeze") or inst.sg:HasStateTag("nointerrupt") or inst:HasTag("fire" or inst.sg.currentstate.name == "sleep")) then -- TODO what is "nofreeze", do we want nofreeze and fire to be in the first if statement? Also if these checks are supposed to prevent sleeping entirely then they should be in the sleeper component. So add nofreeze to that if that prevents sleeping.
                inst.sg:GoToState(inst.sg.currentstate.name == "sleeping" and "sleeping" or not inst.sg:HasStateTag("sleeping") and inst.components.combat:IsAttackReady("body_slam") and "body_slam" or "sleep") -- TODO might not need the cooldown check for body slam since swine should almost always slam right?
            end
        end
   end),
	EventHandler("locomote", function(inst, data)
        local is_moving = inst.sg:HasStateTag("moving")
        local is_running = inst.sg:HasStateTag("running")
        local is_idling = inst.sg:HasStateTag("idle")

        local should_move = inst.components.locomotor:WantsToMoveForward()
        local should_run = inst.components.combat:IsAttackActive("guard")

        if is_moving and not should_move then
            inst.sg:GoToState(is_running and "run_stop" or "walk_stop")
        elseif is_idling and should_move then
            inst.sg:GoToState(should_run and "run_start" or "walk_start")
        end
    end),
}

local states = {
    State{
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            if inst.sg.mem.wants_to_taunt and inst.modes.attack then -- TODO does swineclops ever Tantrum before sleeping? he has definitely taunted prior.
                if inst.components.combat:IsAttackActive("tantrum") and (not inst.components.combat:IsAttackActive("buff") or inst.components.combat:HasDamageBuff("swineclops_battlecry_buff")) then
                    inst.sg:GoToState("tantrum")
                else
                    inst.sg:GoToState("taunt")
                end
			elseif ShouldBodySlam(inst) then -- TODO Might need this because we want to Body Slam after an attack finishes? Might be highest priority? But Taunt might still be higher hmmm. Guard has higher priority
                inst.sg:GoToState("body_slam", {target = inst.components.combat.target})
            elseif inst.sg.mem.sleep_duration then -- TODO this should probably be the lowest priority?
                local isasleep = inst.components.sleeper:IsAsleep()
                inst.components.sleeper:GoToSleep(inst.sg.mem.sleep_duration) -- Reset the sleep time due to Body Slam occurring prior to Sleep
                 -- Sometimes isasleep is true before GoToSleep is called and will not trigger sleep, so trigger it manually.
                if isasleep then
                    inst.sg:GoToState("sleep")
                end
            elseif inst.components.combat:GetAttackOptions("guard").ShouldGuard(inst) then -- TODO this should have the lowest priority? Slams don't need sleep check and after slamming swine should sleep before putting guard up...
                inst.sg:GoToState("block_pre")
            elseif inst.components.combat:GetAttackOptions("guard").ShouldBreakGuard(inst) then
                inst.sg:GoToState("block_pst")
            else
                if inst.components.combat:IsAttackActive("guard") then
                    inst.AnimState:PlayAnimation("block_loop", true)
                else
                    inst.AnimState:PlayAnimation("idle_loop", true)
                end
            end
        end,

        timeline = {
            TimeEvent(9*FRAMES, function(inst)
                if inst.components.combat:IsAttackActive("guard") then
				    inst.SoundEmitter:PlaySound(inst.sounds.stun)
                end
			end),
        },

        onexit = function(inst) -- TODO set all wants_to to nil?
            inst.sg.mem.wants_to_guard = nil -- TODO maybe not because if swine wants to guard but then goes to sleep swine will not guard on wake because of this. Is there an example of Swine waking up and not slamming but instead guarding?
            inst.sg.mem.wants_to_taunt = nil
        end,

        events = {
            EventHandler("animover", function(inst)
                -- End Guard
                if inst.components.combat:GetAttackOptions("guard").ShouldBreakGuard(inst) then
                    inst.sg:GoToState("block_pst")
                end
            end)
        },
    },

	State{
        name = "jab",
        tags = {"attack", "busy"},

		onenter = function(inst)
            inst.components.combat:StartAttack()
            inst.components.locomotor:Stop()
    		inst.SoundEmitter:PlaySound(inst.sounds.swipe)
            inst.AnimState:PlayAnimation("block_counter")
    	end,

        timeline = {
            TimeEvent(6*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.attack)
				DoPunchAOE(inst)
			end),
        },

        events = {
			EventHandler("onhitother", function(inst)
				 inst.SoundEmitter:PlaySound(inst.sounds.attack)
			end),
            CommonForgeHandlers.IdleOnAnimOver(),
        },
    },

    State{
        name = "attack", -- initial punch (left hook)
        tags = {"attack", "busy"},

		onenter = function(inst, data)
            inst.components.combat:StartAttack()
            inst.components.locomotor:Stop()
    		inst.SoundEmitter:PlaySound(inst.sounds.swipe)
            inst.sg.statemem.current_combo = (data and data.current_combo or 0) + 1
            inst.sg.statemem.target = data and data.target or inst.components.combat.target
            inst.AnimState:PlayAnimation("attack1", false)
    	end,

        onexit = function(inst)
            inst.sg.mem.wants_to_slam = nil -- Remove any queued Body Slams because Body Slam is forced at the end of the combo if the right conditions are met. If they are not met Swine should not Body Slam from queue.
        end,

        timeline = {
            TimeEvent(6*FRAMES, DoPunchAOE),
        },

        events = {
			EventHandler("onmissother", function(inst) -- TODO do we want this? if so should it be in the other combo attacks?
				inst.AnimState:PushAnimation("attack1_pst", false)
			end),
            EventHandler("animover", function(inst)
                if inst.sg.statemem.end_combo then
                    -- using statemem check just in case the regular wants_to_slam gets reset during the ending animation.
                    inst.sg:GoToState(inst.sg.statemem.wants_to_slam and "body_slam" or "idle")
                elseif not EndCombo(inst) then
                    inst.sg:GoToState("attack_combo_right_hook", {current_combo = inst.sg.statemem.current_combo, target = inst.sg.statemem.target})
                else
                    inst.sg.statemem.end_combo = true
                end
			end),
        },
    },

	State{
        name = "attack_combo_right_hook",
        tags = {"attack", "busy"},

		onenter = function(inst, data)
            inst.components.combat:StartAttack()
            inst.components.locomotor:Stop()
    		inst.sg.statemem.current_combo = (data and data.current_combo or 0) + 1
            inst.sg.statemem.target = data and data.target or inst.components.combat.target
    		inst.SoundEmitter:PlaySound(inst.sounds.swipe)
            inst.AnimState:PlayAnimation("attack2", false)
    	end,

        onexit = function(inst)
            inst.sg.mem.wants_to_slam = nil -- Remove any queued Body Slams because Body Slam is forced at the end of the combo if the right conditions are met. If they are not met Swine should not Body Slam from queue.
        end,

        timeline = {
            TimeEvent(7*FRAMES, DoPunchAOE),
        },

        events = {
			EventHandler("animover", function(inst)
                if inst.sg.statemem.end_combo then
                    inst.sg:GoToState(inst.sg.statemem.wants_to_slam and "body_slam" or "idle")
                elseif not EndCombo(inst, inst.components.combat:IsAttackActive("uppercut")) then
                    local max_combo = inst.components.combat:GetAttackOptions("combo").max
                    inst.sg:GoToState(inst.sg.statemem.current_combo >= max_combo and inst.components.combat:IsAttackActive("uppercut") and "uppercut" or inst.sg.statemem.current_combo < max_combo and "attack_combo_left_hook", {current_combo = inst.sg.statemem.current_combo, target = inst.sg.statemem.target})
                else
                    inst.sg.statemem.end_combo = true
                end
			end),
        },
    },

	State{
        name = "attack_combo_left_hook",
        tags = {"attack", "busy"},

		onenter = function(inst, data)
            inst.components.combat:StartAttack()
            inst.components.locomotor:Stop()
    		inst.sg.statemem.current_combo = (data and data.current_combo or 0) + 1
            inst.sg.statemem.target = data and data.target or inst.components.combat.target
    		inst.SoundEmitter:PlaySound(inst.sounds.swipe)
            inst.AnimState:PlayAnimation("attack1b", false)
    	end,

        onexit = function(inst)
            inst.sg.mem.wants_to_slam = nil -- Remove any queued Body Slams because Body Slam is forced at the end of the combo if the right conditions are met. If they are not met Swine should not Body Slam from queue.
        end,

        timeline = {
            TimeEvent(7*FRAMES, DoPunchAOE),
        },

        events = {
			EventHandler("animover", function(inst)
                if inst.sg.statemem.end_combo then
                    inst.sg:GoToState(inst.sg.statemem.wants_to_slam and "body_slam" or "idle")
                elseif not EndCombo(inst) then
                    inst.sg:GoToState("attack_combo_right_hook", {current_combo = inst.sg.statemem.current_combo, target = inst.sg.statemem.target})
                else
                    inst.sg.statemem.end_combo = true
                end
			end),
        },
    },

    State{
        name = "uppercut",
        tags = {"attack", "busy", "knockback"}, -- TODO should we use a "knockback" tag to dictate knockback for all attacks? could add universal onhitother to all mobs that check knockback somehow

        onenter = function(inst, data)
            inst.components.combat:StartAttack()
            inst.components.locomotor:Stop()
            inst.SoundEmitter:PlaySound(inst.sounds.swipe)
            inst.AnimState:PlayAnimation("attack3", false)
        end,

        onexit = function(inst)
            inst.sg.mem.wants_to_slam = nil -- Prevent Body Slams right after Uppercuts
        end,

        timeline = {
            TimeEvent(3*FRAMES, DoPunchAOE), -- this does knockback
        },

        events = {
            CommonForgeHandlers.IdleOnAnimOver(),
        },
    },

	State{
        name = "body_slam",
        tags = {"busy", "slamming", "nofreeze", "keepmoving"},

		onenter = function(inst, data)
            inst.components.locomotor:Stop()
            inst.components.combat:StartAttack()
    		inst.SoundEmitter:PlaySound(inst.sounds.jump)
			inst.AnimState:PlayAnimation(inst.components.combat:IsAttackActive("guard") and "bellyflop_block_pre" or "bellyflop_pre", false)
            inst.AnimState:PushAnimation("bellyflop", false)
            local target = data and data.target or inst.components.combat.target
            if inst:HasTag("_isinheals") or target and target:IsValid() and target:HasTag("_isinheals") then
                local heal_auras = COMMON_FNS.GetHealAuras(inst)
                if heal_auras and heal_auras[1] then
                    inst.sg.statemem.override_pos = heal_auras and heal_auras[1] and heal_auras[1]:GetPosition()
                end
            elseif target and target:IsValid() then
                inst:FacePoint(target:GetPosition())
                inst.sg.statemem.target = target
            end
    	end,

    	onexit = function(inst)
    		ToggleOnCharacterCollisions(inst)
        end,

        timeline = {
    		TimeEvent(6*FRAMES, function(inst)
                COMMON_FNS.JumpToPosition(inst, inst.sg.statemem.override_pos or inst.sg.statemem.target and inst.sg.statemem.target:GetPosition(), 25)
				inst.sg:AddStateTag("nostun") --should not be stunned by meteors, etc.
				inst.components.combat:StartCooldown("body_slam")
				inst.sg.mem.wants_to_slam = nil
			end),
    		TimeEvent(23*FRAMES, function(inst)
    			GroundPound(inst)
    			ToggleOnCharacterCollisions(inst)
                inst.components.locomotor:Stop()
                inst.Physics:Stop()
    			inst.components.combat:GetAttackOptions("guard").BreakGuard(inst)
    		end),
        },

        events = {
            CommonForgeHandlers.IdleOnAnimOver(),
        },
    },

	State{
        name = "tantrum",
        tags = {"busy", "nointerrupt", "nofreeze"},

        onenter = function(inst, force)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt2")
            inst.sg:AddStateTag("nosleep")
            inst.sg:AddStateTag("nointerrupt")
        end,

        timeline = {
            TimeEvent(8*FRAMES, GroundPound),
            TimeEvent(11*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(inst.sounds.hit_2)
            end),
            TimeEvent(14*FRAMES, GroundPound),
            TimeEvent(24*FRAMES, GroundPound),
        },

        events = {
            CommonForgeHandlers.IdleOnAnimOver(),
        },
    },

    State{
		name = "hit", -- TODO possible to use hit common state???
        tags = {"busy", "hit"},

        onenter = function(inst)
            inst.Physics:Stop()
            local anim = "hit"
            local sound = inst.sounds.hit
            if inst.components.combat:IsAttackActive("guard") then -- TODO better way? only other way I see is "and"ing it with each variable...
                anim = "block_hit"
                sound = inst.sounds.hit_2
                inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/bonehit2") -- TODO is this sound really there?
            end
            inst.AnimState:PlayAnimation(anim)
			inst.sg.mem.last_hit_time = GetTime()
			inst.SoundEmitter:PlaySound(sound)
        end,

        --[[ TODO does guard only trigger after being hit? if so then uncomment this and remove guard check in idle? might need to move this to animover instead.
        onexit = function(inst)
            if inst.sg.mem.wants_to_guard then
                inst.sg:GoToState("block_pre")
            end
        end,--]]

		timeline = {
            TimeEvent(8*FRAMES, function(inst)
                if not inst.components.combat:IsAttackActive("guard") then
                    inst.SoundEmitter:PlaySound(inst.sounds.step)
                end
            end),
        },

        events = {
            CommonForgeHandlers.IdleOnAnimOver(),
        },
    },

	State{
		name = "block_pre",
        tags = {"busy"},

        onenter = function(inst, force)
			inst.Physics:Stop()
			inst.components.combat:GetAttackOptions("guard").EnterGuardMode(inst)
			inst.AnimState:PlayAnimation("block_pre")
        end,

		timeline = {
			TimeEvent(0*FRAMES, function(inst) -- TODO correct frame?
                inst.SoundEmitter:PlaySound(inst.sounds.hit_2)
            end),
        },

        events = {
            CommonForgeHandlers.IdleOnAnimOver(),
        },
    },

    State {
        name = "block_pst",
        tags = {"busy"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("block_pst")
            inst.components.combat:GetAttackOptions("guard").BreakGuard(inst)
        end,

        timeline = {},

        events = {
            CommonForgeHandlers.IdleOnAnimOver(),
        },
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
			inst.components.armorbreak_debuff:RemoveDebuff()
            if inst._bufftype then
                inst._bufftype:set(0)
            end
			if COMMON_FNS.FindDouble(inst, {"epic", "LA_mob"}) < 1 then -- TODO better way?
				inst:EnableCameraFocus(true)
			end
            if inst.components.combat:IsAttackActive("guard") then
                inst.components.combat:GetAttackOptions("guard").BreakGuard(inst)
            end
			inst:AddTag("NOCLICK")
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            ChangeToObstaclePhysics(inst)
			inst.Physics:ClearCollidesWith(COLLISION.ITEMS)
			inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
        end,

		timeline = {
			TimeEvent(0, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/death")
                ShakePound(inst)
            end),
			TimeEvent(13*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/slurtle/shatter")
            end),
			TimeEvent(43*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/bonehit2")
				ShakePound(inst)
			end),
			TimeEvent(62*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.hit_2)
				ShakePound(inst)
			end),
        },
    },

	State{
		name = "pose", -- TODO create common state for this? Rhinobros have this state?
        tags = {"busy", "posing" , "idle"},

        onenter = function(inst)
			inst.Physics:Stop()
			if COMMON_FNS.FindDouble(inst, {"epic", "LA_mob"}) < 1 then
				inst:EnableCameraFocus(true)
			end
			inst.AnimState:PlayAnimation("end_pose_pre", false)
			inst.AnimState:PushAnimation("end_pose_loop", true)
        end,

		timeline = {
			TimeEvent(11*FRAMES, function(inst)
				if not TheNet:IsDedicated() then
					inst:PushEvent("beetletaur._spawnflower")
				end
			end),
        },
    },
}

CommonStates.AddRunStates(states, {
    runtimeline = {
        TimeEvent(5*FRAMES, function(inst) -- TODO did this have a step sound in the onenter fn??? check the steam version
            inst.SoundEmitter:PlaySound(inst.sounds.step)
            ShakeIfClose(inst)
        end),
        TimeEvent(15*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.step)
            ShakeIfClose(inst)
        end),
    },
    endtimeline = {
        TimeEvent(2*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.step)
            ShakeIfClose(inst)
        end),
        TimeEvent(4*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.step)
            ShakeIfClose(inst)
        end),
    },
})
CommonStates.AddWalkStates(states, {
    walktimeline = {
        TimeEvent(0, function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.step)
        end),
        TimeEvent(15*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.step)
            ShakeIfClose(inst)
        end),
    },
    endtimeline = {
        TimeEvent(7*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.step)
            ShakeIfClose(inst)
        end),
    },
})
CommonForgeStates.AddSleepStates(states, {
    starttimeline = {
        TimeEvent(8*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.step)
        end),
        TimeEvent(30*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.step)
        end),
    },
    sleeptimeline = {
        TimeEvent(0, function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.sleep_in)
        end),
        TimeEvent(30*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.sleep_out)
        end),
    },
    waketimeline = {
        TimeEvent(23*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.step)
            ShakeIfClose(inst)
        end),
    },
},{
    onsleep = function(inst, data)
        inst.sg.mem.wants_to_slam = true
        if inst.components.combat:IsAttackActive("guard") then
            inst.components.combat:GetAttackOptions("guard").BreakGuard(inst)
        end
		ToggleOnCharacterCollisions(inst) --TODO this is here to fix sliding, somehow they're reaching the sleepstate without this being called.
    end,
})

local function PlayChestPoundSounds(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/bonehit2")
    inst.SoundEmitter:PlaySound(inst.sounds.hit_2)
end

local taunt_timeline = {
    TimeEvent(0, function(inst)
        inst.last_taunt_time = GetTime()
    end),
    TimeEvent(5*FRAMES, function(inst) -- TODO 5 frames is a placeholder until we find the correct frame the attack buff is applied.
        DoBattleCryBuff(inst)
    end),
    TimeEvent(10*FRAMES, function(inst)
        inst.SoundEmitter:PlaySound(inst.sounds.taunt)
        ShakeRoar(inst)
    end),
    TimeEvent(24*FRAMES, PlayChestPoundSounds),
    TimeEvent(28*FRAMES, PlayChestPoundSounds),
    TimeEvent(32*FRAMES, PlayChestPoundSounds),
    TimeEvent(36*FRAMES, PlayChestPoundSounds),
}
CommonForgeStates.AddSpawnState(states, taunt_timeline)
CommonForgeStates.AddTauntState(states, taunt_timeline, nil, nil, {
    onexit = function(inst)
        inst.components.combat.battlecryenabled = false -- Remove ability to taunt after taunting. Resets from guard.
    end
})
CommonForgeStates.AddKnockbackState(states)
CommonForgeStates.AddStunStates(states, {
	stuntimeline = {
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
}, nil, nil, {
	onstun = function(inst)
		inst.components.combat:GetAttackOptions("guard").BreakGuard(inst)
	end,
})
CommonForgeStates.AddKnockbackState(states)
--CommonStates.AddFrozenStates(states)
CommonForgeStates.AddFossilizedStates(states, {
    unfossilizedtimeline = {
        TimeEvent(9*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/fossilized_break")
        end),
    },
},{
    unfossilized = {"fossilized_pst_r", "fossilized_pst_l"}
},{},{
    fossilized_onenter = function(inst, data)
        inst.AnimState:PushAnimation("fossilized_shake", true) -- TODO double check anim and no sound???
    end,
    unfossilizing_onexit = function(inst)
        inst.SoundEmitter:KillSound("shakeloop")
    end,
    unfossilized_onenter = function(inst)
        inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength(), function(inst)
            inst.components.fossilizable:SpawnUnfossilizeFx()
        end)
    end
})
CommonForgeStates.AddTimeLockStates(states)

return StateGraph("swineclops", states, events, "spawn")
