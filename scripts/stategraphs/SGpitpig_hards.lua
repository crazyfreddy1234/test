local pitpig_sg = deepcopy(require "stategraphs/SGboarrior")


local function GetMidRangeTarget(inst)
	local slam_options = inst.components.combat:GetAttackOptions("random_slam")
	local targets = COMMON_FNS.GetTargetsWithinRange(inst, slam_options.min_range, slam_options.max_range, {include_tags = {"player"}}) -- Random Slam only targets players.
	return #targets > 0 and targets[math.random(1,#targets)]
end

local function IsTargetInMeleeRange(inst, target)
	return COMMON_FNS.IsTargetInRange(inst, target, nil, inst.components.combat.attackrange, {ignore_scaling = true})
end

local function AttemptSlam(inst)
    local target = GetMidRangeTarget(inst)
    if inst.components.combat:IsAttackReady("random_slam") then
        inst.sg:GoToState("attack_slam", {target = target, forced = true})
        return true
    end
	return false
end

local function IsTargetInSlamRange(inst, target)
	local slam_options = inst.components.combat:GetAttackOptions("slam")
	return COMMON_FNS.IsTargetInRange(inst, target, slam_options.min_range, slam_options.max_range)
end

local MAX_DASHES = 3
local state_idle = pitpig_sg.states.idle
local attack_state_attack1 = pitpig_sg.states.attack
local attack_state_attack2 = pitpig_sg.states.attack2
local attack_state_attack3 = pitpig_sg.states.attack3
local attack_spin_state = pitpig_sg.states.attack_spin
local attack_slam_state = pitpig_sg.states.attack_slam
local attack_state_dash = pitpig_sg.states.dash
local state_walk_stop = pitpig_sg.states.walk_stop

local _oldOnEnterIdle = state_idle.onenter
local _oldOnEnterAttack1 = attack_state_attack1.onenter
local _oldOnEnterAttack2 = attack_state_attack2.onenter
local _oldOnEnterAttack3 = attack_state_attack3.onenter
local _oldOnEnterSpin = attack_spin_state.onenter
local _oldOnEnterSlam = attack_slam_state.onenter
local _oldOnEnterDash = attack_state_dash.onenter
local _oldOnEnterWalkStop = state_walk_stop.onenter

local randomslap = false

local attack_count_MAX = 4
local attack_count = 0

state_idle.onenter = function(inst, data)
    _oldOnEnterIdle(inst)
    attack_count = 0
end

attack_state_attack1.onenter = function(inst, data)
    _oldOnEnterAttack1(inst, data)  
    if not inst.components.combat:IsAttackReady("combo") then
        attack_count = attack_count + 1
    end
end
attack_state_attack2.onenter = function(inst, target)
    _oldOnEnterAttack2(inst, target)   
end
attack_state_attack3.onenter = function(inst, target)
    _oldOnEnterAttack3(inst, target)   
    attack_count = attack_count + 1
end
attack_spin_state.onenter = function(inst, data)
    _oldOnEnterSpin(inst, data)
    attack_count = attack_count + 1
end
attack_slam_state.onenter = function(inst, data)
    _oldOnEnterSlam(inst, data)
    if randomslap then
        randomslap = false
    else
        attack_count = attack_count + 1
    end
end

attack_state_dash.onenter = function(inst)
    _oldOnEnterDash(inst) 
end

attack_state_attack1.events.animqueueover.fn = function(inst, data)
    if attack_count >= attack_count_MAX or not inst.sg.statemem.target_hit then
        inst.sg:GoToState("idle")
        attack_count = 0
    else
        if inst.components.combat:IsAttackReady("combo") and inst.sg.statemem.target and not inst.sg.statemem.target.components.health:IsDead() and COMMON_FNS.IsTargetInRange(inst, inst.sg.statemem.target, nil, inst.components.combat.hitrange, {ignore_scaling = true}) then
            inst.sg:GoToState("attack2", inst.sg.statemem.target)
        elseif AttemptSlam(inst) then
            AttemptSlam(inst)
            randomslap = true
        elseif inst.components.combat:IsAttackReady("slam") and IsTargetInSlamRange(inst, data.target) then 
            inst.sg:GoToState("attack_slam", {target = data.target})
        elseif IsTargetInMeleeRange(inst, data.target) and not AttemptSlam(inst) then
            if inst.components.combat:IsAttackReady("spin") then
                inst.sg:GoToState("attack_spin")
            elseif not inst.components.combat:IsAttackReady("combo") then
                inst.sg:GoToState("attack", {target = data.target})
            end
        elseif inst.components.combat:IsAttackReady("dash") then
            inst.sg:GoToState("dash", data.target)
        else 
            inst.sg:GoToState("idle")
            attack_count = 0
        end
    end
end
attack_state_attack2.events.animqueueover.fn = function(inst, data)
    if attack_count >= attack_count_MAX or not inst.sg.statemem.target_hit then
        inst.sg:GoToState("idle")
        attack_count = 0
    else
        if inst.sg.statemem.target and not inst.sg.statemem.target.components.health:IsDead() and COMMON_FNS.IsTargetInRange(inst, inst.sg.statemem.target, nil, inst.components.combat.hitrange, {ignore_scaling = true}) then
            inst.sg:GoToState("attack3", inst.sg.statemem.target)
        elseif AttemptSlam(inst) then
            AttemptSlam(inst)
            randomslap = true
        elseif inst.components.combat:IsAttackReady("slam") and IsTargetInSlamRange(inst, data.target) then 
            inst.sg:GoToState("attack_slam", {target = data.target})
        elseif IsTargetInMeleeRange(inst, data.target) and not AttemptSlam(inst) then
            if inst.components.combat:IsAttackReady("spin") then
                inst.sg:GoToState("attack_spin")
            end
        elseif inst.components.combat:IsAttackReady("dash") then
            inst.sg:GoToState("dash", data.target)
        else 
            inst.sg:GoToState("idle")
            attack_count = 0
        end
    end
end
attack_state_attack3.events.animqueueover.fn = function(inst, data)
    if attack_count >= attack_count_MAX or not inst.sg.statemem.target_hit then
        inst.sg:GoToState("idle")
        attack_count = 0
    else
        if AttemptSlam(inst) then
            AttemptSlam(inst)
            randomslap = true
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
        else 
            inst.sg:GoToState("idle")
            attack_count = 0
        end
    end
end
attack_spin_state.events.animover.fn = function(inst, data)
    if attack_count >= attack_count_MAX or not inst.sg.statemem.target_hit then
        inst.sg:GoToState("idle")
        attack_count = 0
    else       
        if AttemptSlam(inst) then
            AttemptSlam(inst)
            randomslap = true
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
        else 
            inst.sg:GoToState("idle")
            attack_count = 0
        end
    end
end
attack_slam_state.events.animqueueover.fn = function(inst, data)
    if attack_count >= attack_count_MAX or not inst.sg.statemem.target_hit then
        inst.sg:GoToState("idle")
        attack_count = 0
    else
        if AttemptSlam(inst) then
            AttemptSlam(inst)
            randomslap = true
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
        else 
            inst.sg:GoToState("idle")
            attack_count = 0
        end
    end
end


attack_state_attack1.events.onhitother = EventHandler("onhitother", function(inst)
    inst.sg.statemem.target_hit = true
end)
attack_state_attack2.events.onhitother = EventHandler("onhitother", function(inst)
    inst.sg.statemem.target_hit = true
end)
attack_state_attack3.events.onhitother = EventHandler("onhitother", function(inst)
    inst.sg.statemem.target_hit = true
end)
attack_spin_state.events.onhitother = EventHandler("onhitother", function(inst)
    inst.sg.statemem.target_hit = true
end)
attack_slam_state.events.onhitother = EventHandler("onhitother", function(inst)
    inst.sg.statemem.target_hit = true
end)
attack_slam_state.events.animover = EventHandler("animover", function(inst)
    inst.sg.statemem.target_hit = true
end)





COMMON_FNS.ApplyStategraphPostInits(pitpig_sg)
return pitpig_sg
