local swineclops_sg = deepcopy(require "stategraphs/SGswineclops")
local tuning_values = TUNING.FORGE.SWINECLOPS

local function GetMidRangeTarget(inst)
    local targets = {}
    if not inst:HasTag("brainwashed") then -- TODO remove? find a way for modders to be able to add something like this
        local jab_projectile_options = inst.components.combat:GetAttackOptions("jab_projectile")
        local min_range = jab_projectile_options.min_range
        local max_range = jab_projectile_options.max_range

        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, max_range, { "locomotor", "player" }, { "INLIMBO", "playerghost"})

        for _,ent in ipairs(ents) do
            if ent ~= inst.components.combat.target and inst.components.combat:CanTarget(ent) then
                local distance_to_target = distsq(ent:GetPosition(), inst:GetPosition()) or 0
                if distance_to_target > (min_range*min_range - ent:GetPhysicsRadius(0)) and distance_to_target < (max_range*max_range + ent:GetPhysicsRadius(0)) then
                    table.insert(targets, ent)
                end
            end
        end
    end
    return #targets > 0 and targets[math.random(1,#targets)]
end
local _oldDoAttack = swineclops_sg.events.doattack.fn
swineclops_sg.events.doattack.fn = function(inst, data)
    local found_state = false
    if not (inst.sg:HasStateTag("hit") or inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("nointerrupt")) then
        -- Add jab projectile attack to next attack if available
        if inst.enraged and inst.components.combat:IsAttackActive("guard") and inst.components.combat:IsAttackReady("jab_projectile") then
            local target = GetMidRangeTarget(inst)
            if target then
                inst.sg:GoToState("jab", {target = target})
                found_state = true
            end
        elseif inst.enraged and not inst.components.combat:IsAttackActive("guard") and inst.wants_to_tantrum then
            inst.sg:GoToState("enraged_tantrum")
        end
    end
    if not found_state then
        _oldDoAttack(inst, data)
    end
end

----------
-- Idle -- Adds a check to get enraged
----------
local idle_state = swineclops_sg.states.idle
local _oldOnEnter = idle_state.onenter
idle_state.onenter = function(inst, data)
    if inst.sg.mem.wants_to_enrage then -- TODO should this only happen in attack mode?
        inst.sg.mem.wants_to_enrage = nil
        inst.sg:GoToState("enraged_tantrum")
    else
        _oldOnEnter(inst, data)
    end
end

---------
-- Jab -- Jab can now occasionally send a projectile out
---------
local jab_state = swineclops_sg.states.jab
local _oldOnEnter = jab_state.onenter
jab_state.onenter = function(inst, data)
    -- Target given will cause this to be a projectile jab attack
    inst.sg.statemem.target = data and data.target
    if inst.sg.statemem.target then
        inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())
        inst.components.locomotor:Stop()
        inst.SoundEmitter:PlaySound(inst.sounds.swipe)
        inst.AnimState:PlayAnimation("block_counter")
        inst.components.combat:StartCooldown("jab_projectile")
    else
        _oldOnEnter(inst, data)
    end
end
local _oldJabTime = jab_state.timeline[1].fn
jab_state.timeline[1].fn = function(inst)
    _oldJabTime(inst)
    if inst.sg.statemem.target then
        local target_pos = inst.sg.statemem.target:GetPosition()
        inst:ForceFacePoint(target_pos)
        local punch_projectile = SpawnPrefab("moltendarts_projectile_explosive")
        punch_projectile.Transform:SetPosition(inst:GetPosition():Get())
        punch_projectile.components.projectile:AimedThrow(inst, inst, target_pos, tuning_values.DAMAGE, true)
        --punch_projectile.components.projectile:DelayVisibility(inst.projectiledelay)
        --caster.SoundEmitter:PlaySound("dontstarve/common/lava_arena/blow_dart")
    end
end

--------------
-- Uppercut -- Adds a flame trail that goes passed target location
--------------
local function SpawnFireTrail(inst) -- TODO sound? fire sound?
    local target_pos =  inst.components.combat.target and inst.components.combat.target:GetPosition()
    COMMON_FNS.SlamTrail(inst, target_pos, inst.components.combat:GetAttackOptions("uppercut"))
end
local uppercut_state = swineclops_sg.states.uppercut
local _oldOnEnter = uppercut_state.onenter
uppercut_state.onenter = function(inst, data)
    _oldOnEnter(inst, data)
    SpawnFireTrail(inst)
end

---------------
-- Body Slam -- Now creates fissures upon impact.
---------------
local SPAWN_DISTANCE_FROM_EDGE = 3
local SPAWN_DISTANCE_FROM_BLOCKER = 5
local function SpawnGroundTrailCondition(inst, offset)
    local scale = inst.components.scaler.scale or 1
    local pos = inst:GetPosition() + (offset or _G.Point(0,0,0))
    return not (_G.TheWorld.Map:GetNearestPointOnWater(pos.x, pos.z, SPAWN_DISTANCE_FROM_EDGE*scale, 1) or _G.TheWorld.Map:IsGroundTargetBlocked(pos, SPAWN_DISTANCE_FROM_EDGE*scale))
end

local FISSURE_RADIUS = TUNING.ANTLION_SINKHOLE.UNEVENGROUND_RADIUS
local function ReplaceExistingFissures(inst, pos)
    local scale = inst.components.scaler.scale or 1
    for _,ent in pairs(TheSim:FindEntities(pos.x, 0, pos.z, FISSURE_RADIUS * scale, {"antlion_sinkhole"})) do
        ent:Remove()
    end
end

local MAX_RADIUS_CHECK = 5
local function FindValidLocationForFissure(inst)
    if SpawnGroundTrailCondition(inst) then
        return Point(0,0,0)
    else
        local increment = 0.5
        local radius = increment
        local offset
        while not offset and radius <= MAX_RADIUS_CHECK do
            offset = FindValidPositionByFan((inst.Transform:GetRotation() + 180) * _G.DEGREES, radius, nil, function(offset) return SpawnGroundTrailCondition(inst, offset) end)
            radius = radius + increment
            if offset then
                return offset
            end
        end
    end
end

local body_slam_state = swineclops_sg.states.body_slam
local _oldOnEnter = body_slam_state.onenter
body_slam_state.onenter = function(inst, data)
    _oldOnEnter(inst, data)
end
local _oldGroundPoundTime = body_slam_state.timeline[2].fn
body_slam_state.timeline[2].fn = function(inst)
    _oldGroundPoundTime(inst)
    local fissure_offset = FindValidLocationForFissure(inst)
    if fissure_offset then
        local pos = inst:GetPosition() + fissure_offset
        ReplaceExistingFissures(inst, pos)
        local crater = SpawnPrefab(inst.enraged and "lava_fissure" or "fissure")
        crater.Transform:SetPosition(pos:Get())
        crater.components.scaler:SetSource(inst)
        if crater.SetOwner then
            crater:SetOwner(inst)
        end
        local fx = COMMON_FNS.CreateFX("groundpound_fx", nil, inst)
        fx.Transform:SetPosition(pos:Get())
        local ring_fx = COMMON_FNS.CreateFX("groundpoundring_fx", nil, inst)
        ring_fx.Transform:SetPosition(pos:Get())
    end
end

-------------
-- Tantrum -- Once enraged, then always do enraged tantrum
-------------
local tantrum_state = swineclops_sg.states.tantrum
local _oldOnEnter = tantrum_state.onenter
tantrum_state.onenter = function(inst, data)
    if inst.enraged then
        inst.sg:GoToState("enraged_tantrum")
    else
        _oldOnEnter(inst, data)
    end
end

---------------------
-- Enraged Tantrum --
---------------------
--[[
TODO
stun will cause attack buff to trigger or reset tantrum
    test this
--]]
local function ShakePound(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, 0.5, .03, .5, inst, 30)
end
local function DoGroundPoundAOE(inst)
    COMMON_FNS.DoAOE(inst, nil, nil, {range = tuning_values.GROUNDPOUND_RANGE})
    COMMON_FNS.LaunchItems(inst, tuning_values.GROUNDPOUND_RANGE)
end

local RANDOM_SEGS = 20 -- has 27 geysers spawn
local SEG_ANGLE = 360 / RANDOM_SEGS
local function GetRandomAngle(inst)
    if inst.angles == nil then
        inst.angles = {}
        local offset = math.random() * 360
        for i = 0, RANDOM_SEGS - 1 do
            table.insert(inst.angles, offset + i * SEG_ANGLE)
        end
    end
    local rnd = math.random()
    rnd = rnd * rnd
    local angle = table.remove(inst.angles, math.max(1, math.ceil(rnd * rnd * RANDOM_SEGS)))
    table.insert(inst.angles, angle)
    return angle * DEGREES
end
local function SpawnGeyser(inst, pos, should_loop)
    local geyser = SpawnPrefab("geyser")
    geyser.components.scaler:SetSource(inst)
    geyser.Transform:SetPosition(pos:Get())
    geyser:Start(inst, should_loop)
    return geyser
end
local MIN_OFFSET = 3 -- TODO should there be random variance in offset?
local MAX_OFFSET = 5
-- Spawn geyser on a random valid entity
local function CreateGeyser(inst)
    local pos = inst:GetPosition()
    if inst.enraged then
        -- Only get targets that have health
        local targets = {}
        for _,ent in pairs(TheSim:FindEntities(pos.x, 0, pos.z, 255, {"_combat"}, COMMON_FNS.CommonExcludeTags(inst))) do
            if ent.components.health then
                table.insert(targets, ent)
            end
        end
        -- Choose random target
        if #targets > 0 then
            local target = targets[math.random(1, #targets)]
            if target then
                SpawnGeyser(inst, target:GetPosition())
            end
        end
    else
        if not inst.geysers then inst.geysers = {} end
        local scale = inst.components.scaler.scale
        local current_pos = inst:GetPosition()
        local angle = GetRandomAngle(inst)
        local offset = GetRandomMinMax(MIN_OFFSET, MAX_OFFSET) * scale
        local pos = Point(current_pos.x + offset*math.cos(angle), 0, current_pos.z + offset*math.sin(angle))
        local offset_decrement = 0.5 * scale
        offset = offset - offset_decrement
        -- Keep checking points until a valid one is found.
        while not TheWorld.Map:IsAboveGroundAtPoint(pos:Get()) and offset >= 0 do
            pos = Point(current_pos.x + offset*math.cos(angle), 0, current_pos.z + offset*math.sin(angle))
            offset = offset - offset_decrement
        end
        -- If not valid point found then do not spawn a geyser.
        if TheWorld.Map:IsAboveGroundAtPoint(pos:Get()) then
            table.insert(inst.geysers, SpawnGeyser(inst, pos, true))
        end
    end
end

local function RemoveAllGeysers(inst)
    for _,geyser in pairs(inst.geysers or {}) do
        geyser:Stop()
    end
end

local function GroundPound(inst)
    ShakePound(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/bonehit2")
    inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/trails/bodyfall")
    inst.SoundEmitter:PlaySound(inst.sounds.hit_2)
    DoGroundPoundAOE(inst)
    CreateGeyser(inst)
end
local ENRAGED_TANTRUM_DURATION = 10
local ENRAGED_TANTRUM_COOLDOWN = 60
swineclops_sg.states["enraged_tantrum"] = State{
    name = "enraged_tantrum",
    tags = {"busy", "nointerrupt", "nofreeze"},

    onenter = function(inst, data)
        inst.Physics:Stop()
        inst.AnimState:PlayAnimation("taunt2")
        if not inst.tantrum_timer then
            inst.tantrum_timer = inst:DoTaskInTime(ENRAGED_TANTRUM_DURATION, function()
                inst.tantrum_timer = nil
                inst.sg.statemem.end_tantrum = true
            end)
        end
        inst.wants_to_tantrum = nil
        if not inst.enraged then
            inst.sg:AddStateTag("nostun")
            inst.sg:AddStateTag("nosleep")
            inst.sg:AddStateTag("nointerrupt")
        end
    end,

    onexit = function(inst)
        if inst.components.health:IsDead() then
            RemoveAllGeysers(inst)
        end
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
        EventHandler("animover", function(inst)
            if inst.sg.statemem.end_tantrum then
                if not inst.enraged then
                    inst.enraged = true
                    inst.AnimState:SetBuild("lavaarena_beetletaur_hardmode_enraged")
                end
                RemoveAllGeysers(inst)
                inst.engraged_tantrum_timer = inst:DoTaskInTime(ENRAGED_TANTRUM_COOLDOWN, function(inst)
                    inst.wants_to_tantrum = true
                    inst.enraged_tantrum_timer = nil
                end)
                inst.sg:GoToState("idle")
            else
                inst.sg:GoToState("enraged_tantrum")
            end
        end),
    },
}













local function ShakePound(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, 0.5, .03, .5, inst, 30)
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

local function SpawnGeyser(inst, pos, should_loop)
    local geyser = SpawnPrefab("geyser")
    geyser.components.scaler:SetSource(inst)
    geyser.Transform:SetPosition(TheWorld.center.Transform:GetWorldPosition())
    geyser:Start(inst, should_loop)
    geyser:DoTaskInTime(2, function(inst)
        geyser:Stop()
    end) 
    return geyser
end

local function OnHitOther_Poison(inst, target)   
	target.components.debuffable:AddDebuff("scorpeon_dot", "scorpeon_dot")
end

local function OnHitOther_Knockback(inst, target)
    COMMON_FNS.KnockbackOnHit(inst, target, 5, 12)
end

local function OnHitOther_Fire(inst, target)
    target.components.debuffable:AddDebuff("debuff_fire", "debuff_fire")
end

local tantrum_count = 1
local tantrum_count_MAX = 3
local snortoise_army = {}
local random_turtle_number = 1

local idle_state = swineclops_sg.states.idle
local _oldOnEnter = idle_state.onenter
idle_state.onenter = function(inst, data)
    if inst.sg.mem.wants_to_spawntrutle then 
        inst.sg.mem.wants_to_spawntrutle = nil
        tantrum_count_MAX = 2
        inst.sg:GoToState("turtlespawn_tantrum")
    elseif inst.sg.mem.wants_to_spawnAlltrutle then
        inst.sg.mem.wants_to_spawnAlltrutle = nil
        tantrum_count_MAX = 3
        inst.sg:GoToState("turtlespawn_tantrum")
    else
        _oldOnEnter(inst, data)
    end
end

swineclops_sg.states["turtlespawn_tantrum"] = State{
    name = "turtlespawn_tantrum",
    tags = {"busy", "nointerrupt", "nofreeze"},

    onenter = function(inst, data)
        SpawnGeyser(inst)
        inst.Physics:Stop()
        inst.AnimState:PlayAnimation("taunt2")

        inst.sg:AddStateTag("nostun")
        inst.sg:AddStateTag("nosleep")
        inst.sg:AddStateTag("nointerrupt")
    end,

    onexit = function(inst)

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
        EventHandler("animover", function(inst)   
            
            local cutesnortoise = SpawnPrefab("snortoise")
            cutesnortoise:SetStateGraph("SGrandom_snortoise_poison")
            cutesnortoise.components.health:SetMaxHealth(1000)
            
            if random_turtle_number == 1 then
                cutesnortoise.components.colouradder:PushColour("acid_coat", 0.1, 0.5, 0.1, 1)
                cutesnortoise.components.combat.onhitotherfn = OnHitOther_Poison
                random_turtle_number = random_turtle_number + 1
            elseif random_turtle_number == 2 then
                cutesnortoise.AnimState:SetSymbolMultColour("leg",0.1,0.1,0.1,1)
                cutesnortoise.AnimState:SetSymbolMultColour("head",0.1,0.1,0.1,1)
                cutesnortoise.AnimState:SetSymbolMultColour("body",0.1,0.1,0.1,1)
                cutesnortoise.AnimState:SetSymbolMultColour("shell",0.1,0.1,0.1,1)
                cutesnortoise.AnimState:SetSymbolMultColour("mouth",0.1,0.1,0.1,1)
                cutesnortoise.AnimState:SetSymbolMultColour("eye",1,0,0,1)
                cutesnortoise.components.combat.onhitotherfn = OnHitOther_Knockback
                random_turtle_number = random_turtle_number + 1
            else 
                cutesnortoise.AnimState:SetMultColour(1,0,0,1)
                cutesnortoise.components.combat.onhitotherfn = OnHitOther_Fire
                random_turtle_number = 1
            end

            
            cutesnortoise.Transform:SetPosition(TheWorld.center.Transform:GetWorldPosition())
            snortoise_army[tantrum_count] = cutesnortoise
            tantrum_count = tantrum_count + 1

            if tantrum_count > tantrum_count_MAX then
                for i=1,tantrum_count-1 do
                    snortoise_army[i].sg.mem.spin_attack = true
                    snortoise_army[i].sg:GoToState("idle")
                end

                inst.sg:GoToState("taunt")
                tantrum_count = 1
            else
                inst.sg:GoToState("turtlespawn_tantrum")
            end
        end),
    },
}

COMMON_FNS.ApplyStategraphPostInits(swineclops_sg)
return swineclops_sg
