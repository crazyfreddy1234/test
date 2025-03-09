local boarrior_sg = deepcopy(require "stategraphs/SGboarrior")
boarrior_sg.name = "boarrior_hard"
local tuning_values = TUNING.FORGE.BOARRIOR

local _oldDoAttack = boarrior_sg.events.doattack.fn
boarrior_sg.events.doattack.fn = function(inst, data)
    if not (inst.sg:HasStateTag("hit") or inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("nointerrupt")) and inst.components.combat:IsAttackReady("reinforcements") then
        inst.sg:GoToState("banner_pre")
    else
        _oldDoAttack(inst, data)
    end
end

----------
-- Spin -- Makes Boarrior move towards target while spinning.
----------
-- TODO
-- Change the state to be like boarilla rolling where boarrior spins for a set duration, so more than just one anim, and does damage on throughout just like boarilla, and has no collision.
local function SpinningCondition(inst)
    return inst.sg.currentstate.name == "attack_spin"
end

local SPIN_MOVEMENT_SPEED = 10
local function SpinMovement(inst)
    local target = inst.components.combat.target
    if target and target:IsValid() and not target.components.health:IsDead() then
        inst:ForceFacePoint(target:GetPosition())
        inst.Physics:SetMotorVelOverride(SPIN_MOVEMENT_SPEED,0,0)
    else
        inst.Physics:ClearMotorVelOverride()
    end
end
local spin_state = boarrior_sg.states.attack_spin
local _oldOnEnter = spin_state.onenter
spin_state.onenter = function(inst, data)
    _oldOnEnter(inst, data)
    if inst.components.combat:GetAttackOptions("spin").can_move then
        CreateConditionThread(inst, "attack_spin_movement", 0, 0.1, SpinningCondition, SpinMovement)
    end
end

------------
-- Banner -- Boarrior summons an additional banner for each time banners are summoned (to max).
------------
local MAX_BANNERS = 7
local ATTACK_BANNER_CD = {pitpigs = 30, crocs = 45}
local banner_state = boarrior_sg.states.banner_pre
local _oldOnEnter = banner_state.onenter
banner_state.onenter = function(inst, data)
    _oldOnEnter(inst, data)
    inst.components.combat:StartCooldown("reinforcements")
end

local banner_pst_state = boarrior_sg.states.banner_pst
local _oldOnEnterBannerPst = banner_pst_state.onenter
banner_pst_state.onenter = function(inst, data)
    _oldOnEnterBannerPst(inst, data)
    -- Increase the amount of banners summoned by 1 (to max) every time banners are summoned.
    local current_max_banners = inst.components.combat:GetAttackOptions("reinforcements").banner_opts.max
    inst.components.combat:SetAttackOptions("reinforcements", {banner_opts = {max = math.min((current_max_banners or tuning_values.MAX_BANNERS) + 1, MAX_BANNERS)}})
end

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
local state_idle = boarrior_sg.states.idle
local attack_state_attack1 = boarrior_sg.states.attack
local attack_state_attack2 = boarrior_sg.states.attack2
local attack_state_attack3 = boarrior_sg.states.attack3
local attack_spin_state = boarrior_sg.states.attack_spin
local attack_slam_state = boarrior_sg.states.attack_slam
local attack_state_dash = boarrior_sg.states.dash
local state_walk_stop = boarrior_sg.states.walk_stop

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

COMMON_FNS.ApplyStategraphPostInits(boarrior_sg)
return boarrior_sg
