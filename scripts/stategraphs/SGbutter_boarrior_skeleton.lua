local boarrior_sg = deepcopy(require "stategraphs/SGboarrior")
boarrior_sg.name = "boarrior_skeleton"
local tuning_values = TUNING.HALLOWED_FORGE.BOARRIOR_SKELETON

------------
-- Events --
------------
local boarrior_events = boarrior_sg.events

-- Checks if target is within Grave Guardians melee range.
local function IsTargetInMeleeRange(inst, target)
    return COMMON_FNS.IsTargetInRange(inst, target, nil, inst.components.combat.attackrange, {ignore_scaling = true})
end

-- Checks if target is outside Grave Guardians basic attack range.
local function IsTargetInSlamRange(inst, target)
    local slam_options = inst.components.combat:GetAttackOptions("slam")
    return COMMON_FNS.IsTargetInRange(inst, target, slam_options.min_range, slam_options.max_range)
end

-- Attempts to slam a random valid target that is not the current target
local function AttemptSlam(inst)
    if inst.sg.mem.last_ranged_attacker and inst.components.combat:IsAttackReady("ranged_slam") then
        local target = IsTargetInSlamRange(inst, inst.sg.mem.last_ranged_attacker) and inst.sg.mem.last_ranged_attacker
        if target then
            inst.sg:GoToState("attack_slam", {target = target, forced = true})
            inst.sg.mem.last_ranged_attacker = nil
            return true
        end
    end
    return false
end

local function SpawnBanners(inst)
    COMMON_FNS.SpawnEntsInCircle(inst, inst.components.combat:GetAttackOptions("reinforcements").banner_opts, inst.banners)
end

boarrior_events.doattack.fn = function(inst, data)
    if not inst.components.health:IsDead() and not (inst.sg:HasStateTag("hit") or inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("nointerrupt")) then
        if inst.components.combat:IsAttackReady("slam") and IsTargetInSlamRange(inst, data.target) then
            inst.sg:GoToState("attack_slam", {target = data.target})
        elseif IsTargetInMeleeRange(inst, data.target) and not AttemptSlam(inst) then
            if inst.components.combat:IsAttackReady("spin") then
                inst.sg:GoToState("attack_spin")
            else
                inst.sg:GoToState("attack", {target = data.target})
            end
        --elseif inst.components.combat:IsAttackReady("dash") then
            --inst.sg:GoToState("dash", data.target)
        elseif inst.components.combat:IsAttackActive("projectiles") then
            inst.sg:GoToState("attack", data.target)
        end
    end
end
boarrior_events.dospell = EventHandler("dospell", function(inst, data)
    if not inst.components.health:IsDead() and not inst.sg.mem.wants_to_cast_spell then
        if (inst.sg:HasStateTag("hit") or not inst.sg:HasStateTag("busy")) then
            inst.sg:GoToState("necromance", data)
            inst.sg.mem.wants_to_cast_spell = nil
            inst.sg.mem.spell_targets = nil
        else
            inst.sg.mem.wants_to_cast_spell = data.spell_index
            inst.sg.mem.spell_targets = data.targets
        end
    end
end)

------------
-- States --
------------
local boarrior_states = boarrior_sg.states

local function RemoveAllAfterImages(inst, fade)
    for _,afterimage in pairs(inst.afterimages or {}) do
        if fade then
            afterimage:Fade()
        else
            afterimage:Remove()
        end
    end
    inst.afterimages = nil
    if inst.afterimage_base then
        if fade then
            inst.afterimage_base:Fade()
        else
            inst.afterimage_base:Remove()
        end
        inst.afterimage_base = nil
    end
end

local idle_state = boarrior_states.idle
local _oldOnEnterIdle = idle_state.onenter
idle_state.onenter = function(inst, data)
    RemoveAllAfterImages(inst) -- Remove any lingering after images if it was interrupted
    if inst.sg.mem.wants_to_cast_spell then
        inst.sg:GoToState("attack_spell", {spell_index = inst.sg.mem.wants_to_cast_spell, targets = inst.sg.mem.spell_targets})
        inst.sg.mem.wants_to_cast_spell = nil
        inst.sg.mem.spell_targets = nil
    else
        _oldOnEnterIdle(inst, data)
    end
end

local function SpawnAfterImage(inst)
    local dash_options = inst.components.combat:GetAttackOptions("dash")
    local targets = COMMON_FNS.GetTargetsWithinRange(inst, dash_options.min_range, dash_options.max_range)
    if #targets > 0 then
        local target = targets[math.random(1,#targets)]
        inst.sg.statemem.dash_target = target
        inst.sg.statemem.dash_target_pos = target:GetPosition()

        inst.afterimages = {}
        local afterimage_base = SpawnPrefab("boarrior_skeleton_afterimage_base")
        afterimage_base:SetSource(inst)
        inst.afterimage_base = afterimage_base
        afterimage_base.Transform:SetPosition(inst:GetPosition():Get())
        afterimage_base.sg:GoToState("attack_dash", {target_pos = inst.sg.statemem.dash_target_pos})
    end
end

local function LaunchAttackProjectile(inst, alt, angle_override)
    if not inst.components.combat:IsAttackActive("projectiles") then return end
    local projectile_opts = inst.components.combat:GetAttackOptions("projectiles")
    local scaler = math.random()*2.5 - 1.25
    local offset = 2
    local angle = angle_override or -inst.Transform:GetRotation() * DEGREES
    local pos = inst:GetPosition()
    local spawn_pos = pos + Vector3(math.cos(angle), 0, math.sin(angle))*offset
    local range = 10
    local final_pos = spawn_pos + Vector3(math.cos(angle), 0, math.sin(angle))*range
    local swipe_proj = SpawnPrefab("hf_axe_swipe")
	if alt then
		swipe_proj.AnimState:SetScale(-1.2, 1.2)
		swipe_proj.alt = true
	end
    swipe_proj.Transform:SetPosition(spawn_pos:Get())
    swipe_proj.components.projectile:AimedThrow(inst, inst, final_pos, projectile_opts.damage)
    if projectile_opts.boomerang then
        local _oldProjOnMiss = swipe_proj.components.projectile.onmiss
        swipe_proj.components.projectile.onmiss = function(...)
            local start_pos = swipe_proj:GetPosition()
            if _oldProjOnMiss then
                _oldProjOnMiss(...)
            end
            if start_pos then
                local boomerang_proj = SpawnPrefab("hf_axe_swipe")
                if alt then
                    boomerang_proj.AnimState:SetScale(-1.2, 1.2)
                    boomerang_proj.alt = true
                end
                boomerang_proj.Transform:SetPosition(start_pos:Get())
                boomerang_proj.components.projectile:AimedThrow(inst, inst, pos, projectile_opts.damage)
                boomerang_proj.components.projectile.start = start_pos
                boomerang_proj.components.projectile.start_pos = start_pos
            end
        end
    end
end

local attack_state = boarrior_states.attack
local _oldOnEnterAttack = attack_state.onenter
attack_state.onenter = function(inst, data)
    _oldOnEnterAttack(inst, data)
    if inst.components.combat:IsAttackReady("dash") then
        SpawnAfterImage(inst)
        inst.sg.statemem.dash_count = data and data.dash_count or 0
    end
end
local _oldAttackFN = attack_state.timeline[2].fn
attack_state.timeline[2].fn = function(inst)
    _oldAttackFN(inst)
    LaunchAttackProjectile(inst)
end
local attack_event_animqueueover = attack_state.events.animqueueover
local _oldAttackAnimQueueOver = attack_event_animqueueover.fn
attack_event_animqueueover.fn = function(inst)
    if inst.sg.statemem.dash_target_pos then
        inst.sg:GoToState("attack_dash", {target = inst.sg.statemem.dash_target, target_pos = inst.sg.statemem.dash_target_pos, dash_count = inst.sg.statemem.dash_count})
    else
        _oldAttackAnimQueueOver(inst)
    end
end

local attack2_state = boarrior_states.attack2
local _oldAttack2FN = attack2_state.timeline[1].fn
attack2_state.timeline[1].fn = function(inst)
    _oldAttack2FN(inst)
    LaunchAttackProjectile(inst, true)
end

local attack3_state = boarrior_states.attack3
local _oldAttack3FN = attack3_state.timeline[1].fn
attack3_state.timeline[1].fn = function(inst)
    _oldAttack3FN(inst)
    LaunchAttackProjectile(inst)
end

local function LaunchSpinProjectiles(inst)
    if not inst.components.combat:IsAttackActive("projectiles") then return end
    local pos = inst:GetPosition()
    local max = (inst.components.combat:GetAttackOptions("spin") or {}).max_projectiles or 5
    local start_angle = -inst.Transform:GetRotation()
    for i=1,max do
        LaunchAttackProjectile(inst, nil, (start_angle + 360/max*i)*DEGREES)
    end
end
local attack_spin_state = boarrior_states.attack_spin
--[[local _oldAttackSpinOnEnter = attack_spin_state.onenter
attack_spin_state.onenter = function(inst)
    _oldAttackSpinOnEnter(inst)
    LaunchSpinProjectile(inst)
end--]]
local _oldAttackSpinFN = attack_spin_state.timeline[2].fn
attack_spin_state.timeline[2].fn = function(inst)
    _oldAttackSpinFN(inst)
    LaunchSpinProjectiles(inst)
end

local attack_slam_state = boarrior_states.attack_slam
local _oldOnEnterAttackSlam = attack_slam_state.onenter
attack_slam_state.onenter = function(inst, data)
    inst.components.combat:StartCooldown(data and data.forced and "ranged_slam" or "slam")
    _oldOnEnterAttackSlam(inst, data)
    if inst.sg.mem.gravestone and inst.sg.mem.gravestone:IsValid() then
        inst.sg.mem.gravestone.components.health:Kill()
    end
    inst.sg.mem.gravestone = nil
end

local function SummonCondition(inst)
    return inst.banner_call_timer ~= nil
end
local summon_angle_order = {} -- TODO have a specific order that the gravepigs are summoned at that recycles? maybe calculate how many would spawn with the current settings and do an order with that?
local function Summon(inst)
    local VALID_GROUND_RANGE = 3
    local function IsValidGround(pt)
        return not TheWorld.Map:IsGroundTargetBlocked(pt, VALID_GROUND_RANGE)
    end
    local summon_opts = inst.components.combat:GetAttackOptions("reinforcements").summon_opts
    local angle = math.random(360) * DEGREES
    local radius = math.random(summon_opts.min_radius, summon_opts.max_radius)
    local offset = FindWalkableOffset(inst:GetPosition(), angle, radius, nil, nil, nil, IsValidGround)
    if offset then
        local event = TheWorld.components.lavaarenaevent
        local gravepig = COMMON_FNS.SpawnMob(summon_opts.prefab, inst:GetPosition() + offset, event and event.current_round, "summon", 0, false)
    end
end
local banner_pre_state = boarrior_states.banner_pre
banner_pre_state.onenter = function(inst)
    inst.components.sleeper:SetResistance(9999)
    inst.Physics:Stop()
    inst.AnimState:PlayAnimation("banner_pre")
    if not inst.banner_call_timer then
        local summon_opts = inst.components.combat:GetAttackOptions("reinforcements").summon_opts
        inst:DoTaskInTime(2, SpawnBanners)
        inst.banner_call_timer = inst:DoTaskInTime(summon_opts.duration, function(inst)
            inst.banner_call_timer = nil
        end)
        
    end
end

local function AfterImageCondition(inst)
    return inst.sg.currentstate.name == "dash"
end

local function AfterImage(inst)
    local afterimage = COMMON_FNS.CreateFX("boarrior_skeleton_afterimage")
    afterimage.Transform:SetPosition(inst:GetPosition():Get())
    afterimage.AnimState:PlayAnimation("dash")
    afterimage.AnimState:SetTime(inst.AnimState:GetCurrentAnimationTime())
    afterimage.AnimState:Pause()
    afterimage.Transform:SetRotation(inst.Transform:GetRotation())
    afterimage:SetSource(inst)
    afterimage:Fade()
end


local dash_state = boarrior_states.dash
local _oldOnEnterDash = dash_state.onenter
dash_state.onenter = function(inst, data)
    _oldOnEnterDash(inst, data)
    CreateConditionThread(inst, "dash_afterimage", 0, 0.1, AfterImageCondition, AfterImage)
end

local function RemoveAfterImage(inst)
    local current_anim_time = inst.AnimState:GetCurrentAnimationTime() + 0.01 -- Round up slightly to ensure no rounding issues on frames.
    for i=#inst.afterimages,1,-1 do
        local afterimage = inst.afterimages[i]
        if current_anim_time > afterimage.AnimState:GetCurrentAnimationTime() then
            afterimage:Remove()
            table.remove(inst.afterimages, i)
        end
    end
end

local function ShakeIfClose(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, .5, .02, .2, inst, 30)
end

local death_state = boarrior_states.death
local _oldOnEnterDeath = death_state.onenter
death_state.onenter = function(inst, data)
    RemoveAllAfterImages(inst)
    _oldOnEnterDeath(inst, data)
end

local states = {
    State{
        name = "necromance",
        tags = {"busy", "nointerrupt", "spell"},

        onenter = function(inst, data)
            inst.SoundEmitter:PlaySound(inst.sounds.taunt)
            inst.AnimState:PlayAnimation("taunt", false)
            --inst.AnimState:PlayAnimation("banner_pre", false)
            --inst.AnimState:PushAnimation("banner_loop", false)
            --inst.AnimState:PushAnimation("banner_pst", false)
            inst.Physics:Stop()
            inst.sg.statemem.spell_index = data.spell_index
            inst.sg.statemem.spell_targets = data.targets
        end,

        timeline = {
            TimeEvent(21*FRAMES, function(inst)
                inst.components.spellmaster:CastSpell(inst.sg.statemem.spell_index, inst.sg.statemem.spell_targets)
            end)
        },

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
    State{
        name = "attack_dash",
        tags = { "nointerrupt", "keepmoving", "canrotate", "attack", "busy"},

        onenter = function(inst, data)
            inst.AnimState:PlayAnimation("dash")
            inst.SoundEmitter:PlaySound(inst.sounds.grunt)
            inst.SoundEmitter:PlaySound(inst.sounds.step)

            inst.sg.statemem.target = data and data.target
            inst.components.combat:SetTarget(inst.sg.statemem.target)
            inst.sg.statemem.target_pos = data and data.target_pos or inst.sg.statemem.target and inst.sg.statemem.target:GetPosition() or Vector3(0,0,0)
            inst:ForceFacePoint(inst.sg.statemem.target_pos)
            inst.components.locomotor:GoToPoint(inst.sg.statemem.target_pos)

            inst.sg.statemem.dash_count = (data and data.dash_count or 0) + 1
            if inst.components.combat:GetAttackOptions("dash").max <= inst.sg.statemem.dash_count then
                inst.components.combat:StartCooldown("dash")
            end
        end,

        onupdate = function(inst)
            RemoveAfterImage(inst)
        end,

        onexit = function(inst)
            inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "dash")
            RemoveAllAfterImages(inst)
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
                inst.sg:GoToState("attack", {target = inst.sg.statemem.target, dash_count = inst.sg.statemem.dash_count})
            end),
        },
    },
}

COMMON_FNS.AddStatesToStategraph(boarrior_sg, states)
COMMON_FNS.ApplyStategraphPostInits(boarrior_sg)

return boarrior_sg
