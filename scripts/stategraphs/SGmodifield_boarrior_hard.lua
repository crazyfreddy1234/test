local boarrior_sg = deepcopy(require "stategraphs/SGboarrior")
boarrior_sg.name = "modifield_boarrior_hard"
local tuning_values = TUNING.FORGE.BOARRIOR

local function SpawnEntsRandomInCircle(inst, opts, current_ents)
    local options = {
        pos          = TheWorld.components.lavaarenaevent:GetArenaCenterPoint() or inst.Transform:GetPosition(),
        offset       = 13.5,
        angle_offset = PI/4,
        prefab       = "battlestandard_damager",
        max          = 4,
        delay_per_spawn = 4*FRAMES,
        duplicates      = false,
    }
    current_ents = current_ents or {}
    -- Load custom options
    MergeTable(options, opts or {}, true)
    -- Generate Positions
    local positions = {}
    for i = 1, options.max do
        local current_angle = 2 * PI / options.max * i + options.angle_offset
        local angled_offset = Vector3(options.offset * math.cos(current_angle), 0, options.offset * math.sin(current_angle))
        local pos = options.pos + angled_offset
        -- Check to see if ent already exists in this position
        local is_valid_pos = true
        if not options.duplicates then
            for _,ent in pairs(current_ents) do
                local ent_pos = ent:GetPosition()
                for i,val in pairs(ent_pos) do
                    ent_pos[i] = Round(val,100)
                end
                local is_same_pos = ent_pos.x == pos.x and ent_pos.y == pos.y and ent_pos.z == pos.z
                is_valid_pos = is_valid_pos and (ent:GetDistanceSqToPoint(pos) > 0.1)
            end
        end
        if is_valid_pos then
            table.insert(positions, pos)
        end
    end
    -- Spawn ents in random order
    local four_banners = {}
    table.insert(four_banners,"battlestandard_heal")
    table.insert(four_banners,"battlestandard_shield")
    table.insert(four_banners,"battlestandard_damager")
    table.insert(four_banners,"battlestandard_speed")
    for i = 1, #positions do
        local rand = math.random(#positions)
        local pos = positions[rand]
        table.remove(positions, rand)
        inst:DoTaskInTime(options.delay_per_spawn*(i-1), function(inst)
            local randomnum = math.random(1,#four_banners)
            local prefab = options.max > 4 and "battlestandard_damager" or four_banners[randomnum]
            table.remove(four_banners,randomnum)
            if #four_banners <= 0 then
                table.insert(four_banners,"battlestandard_heal")
                table.insert(four_banners,"battlestandard_shield")
                table.insert(four_banners,"battlestandard_damager")
                table.insert(four_banners,"battlestandard_speed")
            end
            local ent = SpawnPrefab(prefab)
            ent.Transform:SetPosition(pos:Get())
            current_ents[ent] = ent
            ent:ListenForEvent("onremove", function()
                current_ents[ent] = nil
            end)
        end)
    end

    return current_ents
end

local function SpawnBanners(inst)
    SpawnEntsRandomInCircle(inst, inst.components.combat:GetAttackOptions("reinforcements").banner_opts, inst.banners)
end

---------------------------
-- Update Attack Pattern -- Boarrior now calls for reinforcements (of increasing strength) as a periodic attack.
---------------------------
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
banner_state.onenter = function(inst, data)
    inst.components.sleeper:SetResistance(9999)
    inst.Physics:Stop()
    inst.AnimState:PlayAnimation("banner_pre")
    if not inst.banner_call_timer then
        inst:DoTaskInTime(2, SpawnBanners) -- TODO tuning?
        TheWorld.components.lavaarenaevent:QueueWave(nil, true, inst.components.combat:GetAttackOptions("reinforcements").wave) -- TODO should this be an event pushed instead of a function call?
        inst.banner_call_timer = inst:DoTaskInTime(5, function(inst) -- TODO tuning?
            inst.banner_call_timer = nil
        end)
    end
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

COMMON_FNS.ApplyStategraphPostInits(boarrior_sg)
return boarrior_sg