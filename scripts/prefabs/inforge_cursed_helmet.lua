local assets = {
    Asset("ANIM", "anim/hf_cursed_helmet.zip"), --TODO: This actually gets loaded here properly due to the helm projectile. Maybe remove from hf_assets?
}
local prefabs = {}
local tuning_values = TUNING.HALLOWED_FORGE.CURSED_HELMET
local sound_path = "hf/creatures/cursed_helmet/"
--------------------------------------------------------------------------
-- Camera Functions
--------------------------------------------------------------------------
local function OnCameraFocusDirty(inst)
    if inst._camerafocus:value() then
        if inst:HasTag("NOCLICK") then
            --death
            TheFocalPoint.components.focalpoint:StartFocusSource(inst, nil, nil, 6, 22, 3)
        else
            --pose
            TheFocalPoint.components.focalpoint:StartFocusSource(inst, nil, nil, 60, 60, 3)
            TheCamera:SetDistance(30)
            TheCamera:SetControllable(false)
        end
    else
        TheFocalPoint.components.focalpoint:StopFocusSource(inst)
        TheCamera:SetControllable(true)
    end
end

local function EnableCameraFocus(inst, enable)
    if enable ~= inst._camerafocus:value() then
        inst._camerafocus:set(enable)
        if not TheNet:IsDedicated() then
            OnCameraFocusDirty(inst)
        end
    end
end
--------------------------------------------------------------------------
-- Projectile Functions
--------------------------------------------------------------------------
local function OnBlackHoleChargeComplete(inst, caster)
    local pos = inst:GetPosition()
    local angle = -caster:GetAngleToPoint(pos) * DEGREES
    local offset = Vector3(math.cos(angle), 0, math.sin(angle)) * 5 -- TODO options?
    inst.components.projectile:AimedThrow(inst, caster, pos + offset)
end

local function OnBlackHolePullComplete(inst, caster)
    local options = {
        prefab = "hf_cursed_projectile",
        max    = 4,
        delay  = 0,
    }
    -- Load custom options
    MergeTable(options, caster.components.combat:GetAttackOptions("black_hole_projectile") or {}, true)
    inst:DoTaskInTime(options.delay, function()
        local pos = inst:GetPosition()
        local start_angle = -inst.Transform:GetRotation()
        local angle_per_projectile = 360/options.max
        for i=1,options.max do
            local projectile = SpawnPrefab(options.prefab)
            projectile.Transform:SetPosition(pos:Get())
            local angle = (start_angle + angle_per_projectile * i) * DEGREES
            local offset = Vector3(math.cos(angle), 0, math.sin(angle))
            projectile.components.projectile:AimedThrow(projectile, caster, pos + offset, options.damage)
        end
    end)
end
--------------------------------------------------------------------------
-- Spell Functions
--------------------------------------------------------------------------
local function RemoveAnnihilationProtection(inst, target)
    inst.components.spellmaster:ForceEndSpell("annihilation_protection", nil, true)
end

local function AnnihilationPosition(magic_circle, caster, target)
    magic_circle.Transform:SetPosition(caster:GetPosition():Get())
end

local function AnnihilationProtectionPosition(magic_circle, caster, target)
    caster.protection_circle_count =(caster.protection_circle_count or 0) + 1
    local angle = (-caster.Transform:GetRotation() + 360/caster.annihilation_protection_opts.max * caster.protection_circle_count) * DEGREES
    local offset_pos = Vector3(math.cos(angle), 0, math.sin(angle)) * (caster.annihilation_protection_opts.max_offset + caster.annihilation_protection_opts.min_offset)/2
    magic_circle.Transform:SetPosition((caster:GetPosition() + offset_pos):Get())
end

local function AnnihilationProtectionMoveCondition(inst, data)
    return data.magic_circle and data.magic_circle:IsValid() and not data.magic_circle.spell_end and inst.sg:HasStateTag("spell")
end

local function GetNextDirection(current, min, max)
    return (current >= max or current <= min) and -1 or 1
end

local function AnnihilationProtectionMove(inst, data)
    local magic_circle               = data.magic_circle
    local current_movement_opts      = magic_circle.current_movement_opts
    local options                    = inst.annihilation_protection_opts
    -- Update Range
    current_movement_opts.range_dir = current_movement_opts.range_dir * GetNextDirection(current_movement_opts.range, options.min_range, options.max_range)
    local range_delta               = options.range_delta * current_movement_opts.range_dir
    current_movement_opts.range     = math.clamp(current_movement_opts.range + range_delta, options.min_range, options.max_range)
    magic_circle:SetRange(current_movement_opts.range)
    -- Calculate Offset
    current_movement_opts.offset_dir = current_movement_opts.offset_dir * ((current_movement_opts.offset >= options.max_offset or current_movement_opts.offset <= options.min_offset) and -1 or 1)
    local offset_delta               = options.offset_delta * current_movement_opts.offset_dir
    current_movement_opts.offset     = math.clamp(current_movement_opts.offset + offset_delta, options.min_offset, options.max_offset)
    -- Update Position
    local pos              = inst:GetPosition()
    pos.y                  = 0 -- Ensure the magic circle stays on the ground regardless of where the caster is
    local magic_circle_pos = magic_circle:GetPosition()
    local angle            = (-inst:GetAngleToPoint(magic_circle_pos) + options.angle_delta)*DEGREES
    local offset_pos       = Vector3(math.cos(angle), 0, math.sin(angle)) * current_movement_opts.offset
    data.magic_circle.Transform:SetPosition((pos + offset_pos):Get())
end

local function AnnihilationProtectionMoveSpell(inst, target, magic_circle)
    if inst.annihilation_protection_opts.move then
        magic_circle.current_movement_opts = { -- offset and range should match the starting values here
            offset     = (inst.annihilation_protection_opts.max_offset + inst.annihilation_protection_opts.min_offset)/2,
            offset_dir = 1,
            range      = 2,
            range_dir  = 1,
        }
        CreateConditionThread(inst, "move_" .. tostring(magic_circle.GUID), 0, FRAMES, AnnihilationProtectionMoveCondition, AnnihilationProtectionMove, nil, {magic_circle = magic_circle})
    end
end

local function AnnihilationProtectionComplete(caster, target)
    caster.protection_circle_count = math.max(caster.protection_circle_count - 1, 0)
end

local function GetValidCorpse(inst, target)
    return target and target:HasTag("corpse") and not inst.components.spellmaster:IsSpellCastingOnTarget("reanimate_corpse", target)
end

local function ReanimateCorpseFailConditionFN(magic_circle, caster, target)
    return target and not target:HasTag("corpse")
end

local function CastAnnihilationProtectionCircles(inst, data)
    if data.name == "annihilation" then
        local annihilation_protection_index = inst.components.spellmaster:GetSpellIndex("annihilation_protection")
        for i=1,inst.annihilation_protection_opts.max do
            inst.components.spellmaster:CastSpell(annihilation_protection_index, {TheWorld})
        end
    end
end

local function CanReviveTarget(inst, target)
    return target.components.revivablecorpse and target.components.revivablecorpse:CanBeRevivedBy(inst) and not inst.components.spellmaster:IsSpellCastingOnTarget("revive", target)
end

local function OnReviveComplete(inst, target)
    local function OnDeath()
        target:RemoveEventCallback("death", OnDeath)
        if inst:IsValid() and not inst.components.health:IsDead() then
            inst.components.spellmaster:EnableSpell("revive", true, false)
        end
    end
    inst.components.spellmaster:EnableSpell("revive", false, false)
    target:ListenForEvent("death", OnDeath)
end
--------------------------------------------------------------------------
-- Phases (Health Triggers)
--------------------------------------------------------------------------
-- New Attack: Slam
local function Phase1(inst)
    inst.components.healthtrigger:RemoveTrigger(tuning_values.PHASE_1_TRIGGER)
    COMMON_FNS.ForceTaunt(inst)
    -- Slam
    inst.components.spellmaster:EnableSpell("annihilation", true, true)
end

-- New Projectile Attack: Black Holes
local function Phase2(inst)
    inst.components.healthtrigger:RemoveTrigger(tuning_values.PHASE_2_TRIGGER)
    COMMON_FNS.ForceTaunt(inst)
    -- Black Hole
    inst.components.combat:ToggleAttack("black_hole", true)
    -- Revive Linked MummyClops
    inst.components.spellmaster:EnableSpell("revive", true, true)
end

 -- New Spells: Annihilation, Annihilation Protection
local function Phase3(inst)
    inst.components.healthtrigger:RemoveTrigger(tuning_values.PHASE_3_TRIGGER)
    COMMON_FNS.ForceTaunt(inst)
    -- Annihilation
    inst.components.spellmaster:EnableSpell("annihilation", true, true)
end

-- Annihilation Protection Circles now move in a circle
local function Phase4(inst)
    inst.components.healthtrigger:RemoveTrigger(tuning_values.PHASE_4_TRIGGER)
    COMMON_FNS.ForceTaunt(inst)
    -- Annihilation Protection
    inst.annihilation_protection_opts.move = true
    -- Hex Storm
    inst.components.spellmaster:EnableSpell("hex_storm", true, true)
end
--------------------------------------------------------------------------
-- Physics Functions
--------------------------------------------------------------------------
local physics = { --TODO needs to be reviewed, just using swineclops physics atm
    scale  = 1.05,
    mass   = 500,
    radius = 1.75,
    shadow = {4.5,2.25},
}

local function ShakeIfClose(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, .25, .015, .25, inst, 10)
end

local function PhysicsInit(inst)
	inst:SetPhysicsRadiusOverride(physics.radius)
    MakeCharacterPhysics(inst, physics.mass, physics.radius)
    inst.Transform:SetFourFaced()
    local scale = physics.scale
    inst.Transform:SetScale(scale,scale,scale)
	inst.DynamicShadow:SetSize(unpack(physics.shadow))
end
--------------------------------------------------------------------------
-- Pristine Functions
--------------------------------------------------------------------------
local function PristineFN(inst)
    COMMON_FNS.AddTags(inst, "largecreature", "epic", "cursed_helmet") --added cursed_helmet tag just incase we want to easily seperate them from other epic mobs.
    ------------------------------------------
    inst.AnimState:SetLightOverride(0.2)
    ------------------------------------------
    inst.entity:AddLight()
    inst.Light:SetIntensity(0.7)
    inst.Light:SetRadius(1.75)
    inst.Light:SetFalloff(0.7)
    inst.Light:Enable(true)
    inst.Light:SetColour(255/255, 56/255, 122/255)
    ------------------------------------------
    inst._camerafocus = net_bool(inst.GUID, "beetletaur._camerafocus", "camerafocusdirty")
end
--------------------------------------------------------------------------
local mob_values = {
    physics         = physics,
	physics_init_fn = PhysicsInit,
    pristine_fn     = PristineFN,
	stategraph      = "SGcursed_helmet",
	brain           = require("brains/cursed_helmetbrain"), --for ez animation testing
	sounds = {
		taunt = sound_path.."taunt",
		land = sound_path.."land",
		land2 = sound_path.."land2",
		attack = sound_path.."shoot",
		hit = sound_path.."hit",
		impact = sound_path.."impact",
		breath_in = sound_path.."breath_in",
		breath_out = sound_path.."breath_out",
	},
}
--------------------------------------------------------------------------
local function fn()
    local inst = COMMON_FNS.CommonMobFN("hf_cursed_helmet", "hf_cursed_helmet", mob_values, tuning_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        inst:ListenForEvent("camerafocusdirty", OnCameraFocusDirty) -- TODO should this be in non dedicated or non server?
        return inst
    end
	------------------------------------------
	COMMON_FNS.AddSymbolFollowers(inst, "head", nil, "large", {symbol = "body"}, {symbol = "body"})
	------------------------------------------
	COMMON_FNS.SetupBossFade(inst, 7)
	inst.EnableCameraFocus = EnableCameraFocus
    ------------------------------------------
    local attacks = {
        slam       = {active = false, cooldown = tuning_values.SLAM_CD, opts = {damage = tuning_values.SLAM_DAMAGE, range = tuning_values.SLAM_RANGE,}},
        black_hole = {active = false, cooldown = tuning_values.BLACK_HOLE_CD, opts = {damage = 0, max = 1, offset = 4, charge_duration = 3, pull_cooldown = 4, pull_duration = 2, pull_speed = 6, pull_range = 8, onchargecomplete_fn = OnBlackHoleChargeComplete, onpullcomplete_fn = OnBlackHolePullComplete,}},
        black_hole_projectile = {opts = {prefab = "hf_cursed_projectile", max = 4, delay = 0.5, damage = tuning_values.CURSED_PROJECTILE_DAMAGE}},
        projectile = {opts = {prefab = "hf_cursed_projectile", damage = 100, amount = 1}}
    }
    inst.components.combat:AddAttacks(attacks)
	inst.components.combat:SetHurtSound(inst.sounds.impact)
    inst.protection_circle_count = 0
    inst.annihilation_opts = {
        charge_time  = 10,
        max_levels   = 5,
        defence_buff = 0.5,
    }
    inst.annihilation_protection_opts = {
        max          = 3,
        max_offset   = 5,
        min_offset   = 5,
        max_range    = 2,
        min_range    = 2,
        angle_delta  = 1,
        offset_delta = 0.1,
        range_delta  = 0.01,
        move         = false,
    }
	------------------------------------------
	inst:AddComponent("healthtrigger")
    inst.components.healthtrigger:AddTrigger(tuning_values.PHASE_1_TRIGGER, Phase1)
    inst.components.healthtrigger:AddTrigger(tuning_values.PHASE_2_TRIGGER, Phase2)
    inst.components.healthtrigger:AddTrigger(tuning_values.PHASE_3_TRIGGER, Phase3)
    inst.components.healthtrigger:AddTrigger(tuning_values.PHASE_4_TRIGGER, Phase4)
	------------------------------------------
    inst.components.combat.ignorehitrange = true
    ------------------------------------------
	inst.recentlycharged = {}
    inst.Physics:SetCollisionCallback(COMMON_FNS.OnCollideDestroyObject)
    ------------------------------------------
    inst.components.debuffable:SetImmuneToAll(true)
    inst.components.debuffable:AddWeaknesses({"sleep", "healingcircle_regenbuff", "debuff_spice_regen"}, true)
	------------------------------------------
    inst:AddComponent("spellmaster")
    inst.components.spellmaster:AddSpell("annihilation", {"spell_annihilation"}, {
        cast_time    = 10,
        duration     = 0,
        range        = 1,
        target_range = 0,
        max_targets  = 1,
        rotations    = 1,
        cooldown     = 20,
        priority     = 2,
        onend_fn     = RemoveAnnihilationProtection,
        get_targets_fn = function() return {TheWorld} end,
        position_fn    = AnnihilationPosition,
        magic_circle   = "magic_circle_chase",
        ready          = false,
        enabled        = false,
    })
    inst.components.spellmaster:AddSpell("annihilation_protection", {"spell_annihilation_protection"}, {
        cast_time    = 1,
        duration     = "nil", -- cast_time + duration should be at least 1 frame longer than annihilations
        range        = 2,
        target_range = 0,
        max_targets  = 1,
        rotations    = 1,
        cooldown     = nil,
        priority     = 1,
        oncast_fn    = AnnihilationProtectionMoveSpell,
        onend_fn     = AnnihilationProtectionComplete,
        get_targets_fn = function() return {TheWorld} end,
        position_fn    = AnnihilationProtectionPosition,
        magic_circle   = "magic_circle_shield",
        ready          = false,
        enabled        = false,
    })
    inst.components.spellmaster:AddSpell("hex_storm", {"spell_hex_lightning_storm"}, {
        cast_time    = 1,
        duration     = "nil",
        range        = 1,
        target_range = 0,
        max_targets  = 1,
        rotations    = 1,
        cooldown     = 20,
        priority     = 1,
        get_targets_fn = function() return {TheWorld} end,
        position_fn    = COMMON_FNS.HideMagicCircle,
        magic_circle   = "magic_circle_chase",
        ready          = false,
        enabled        = false,
    })
    inst.components.spellmaster:AddSpell("hex_lightning", {"spell_hex_lightning"}, {
        cast_time    = 1,
        duration     = 0,
        range        = 2,
        target_range = 30,
        max_targets  = 1,
        rotations    = 1,
        cooldown     = nil,
        priority     = 1,
        on_spawn_fn  = function(magic_circle) magic_circle.AnimState:SetMultColour(unpack({255/255,58/255,138/255,1})) end,
        magic_circle = "magic_circle_acid_meteor",
        colour       = {255/255, 58/255, 138/255}, --this is for spellcast fx, see stategraph
        ready        = false,
        enabled      = false,
    })
    inst.components.spellmaster:AddSpell("reanimate_corpse", {"spell_reanimate_corpse"}, {
        cast_time    = 1,
        duration     = "nil",
        range        = 1,
        target_range = 900,
        max_targets  = 1,
        rotations    = 1,
        cooldown     = 20,
        priority     = 1,
        target_condition_fn = GetValidCorpse,
        fail_condition_fn   = ReanimateCorpseFailConditionFN,
        magic_circle        = "magic_circle_necromancy",
		colour		        = {179/255, 0, 255/255, 1},
		position_fn         = COMMON_FNS.HF.MagicCircleTrackTargetPos,
    })
    inst.components.spellmaster:AddSpell("curse", {"spell_curse"}, {
        cast_time    = 1,
        duration     = 10,
        range        = 1,
        target_range = 10,
        max_targets  = 1,
        rotations    = 1,
        cooldown     = 20,
        priority     = 4,
        magic_circle = "magic_circle_curse",
		position_fn  = COMMON_FNS.HF.MagicCircleTrackTargetPos,
		colour = {255/255, 58/255, 138/255}, --this is for spellcast fx, see stategraph
    })
    inst.components.spellmaster:AddSpell("revive", {"spell_revive_target"}, {
        val            = {spell_revive_target = {percent = 0.2}},
        cast_time      = 1,
        duration       = 1,
        range          = 2,
        target_range   = tuning_values.REVIVE_RANGE,
        max_targets    = nil,
        rotations      = 1,
        cooldown       = 45,
        priority       = 3,
        is_friendly    = true,
        onend_fn       = OnReviveComplete,
        target_condition_fn = CanReviveTarget,
        magic_circle        = "magic_circle_necromancy",
        ready               = false,
        enabled             = false,
		colour		        = {179/255, 0, 255/255, 1},
    })
    ------------------------------------------
	inst.components.combat.battlecryenabled = false -- TODO should this be true initially???
	--[[inst:DoPeriodicTask(0.2, function(inst)
		local af = SpawnPrefab("afterimage")
		af.Transform:SetPosition(inst:GetPosition():Get())
		af.Transform:SetRotation(inst.Transform:GetRotation())
		af.AnimState:PlayAnimation()
	end)--]]
    ------------------------------------------
    inst:DoTaskInTime(0, function()
        inst.components.spell_manager:SetCanReceiveSpells(false)
    end)
    ------------------------------------------
    inst:ListenForEvent("spell_cast", CastAnnihilationProtectionCircles)
	--inst:ListenForEvent("death", OnDeath)
	------------------------------------------
    MakeHauntablePanic(inst)
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
local function afterimage_fn() --I still want an afterimage so I'm not wanting to delete this yet.
	local inst = CreateEntity()
    ------------------------------------------
	inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    ------------------------------------------
	inst.AnimState:SetBank("hf_cursed_helmet")
    inst.AnimState:SetBuild("hf_cursed_helmet")
    inst.AnimState:PlayAnimation("idle_loop", false)
    ------------------------------------------
	inst.AnimState:SetMultColour(0.5, 0.5, 0.5, 0.5)
	inst.AnimState:SetSortOrder(-1)
    ------------------------------------------
	if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
	inst:AddComponent("colourtweener")
	inst.components.colourtweener:StartTween({0, 0, 0, 0}, 3, inst.Remove)
    ------------------------------------------
	return inst
end

local function Land(inst, pos)
	if inst.land_task then
		inst.land_task:Cancel()
		inst.land_task = nil
	end
    ------------------------------------------
	ShakeIfClose(inst)
    ------------------------------------------
	local event = TheWorld.components.lavaarenaevent
	local boss = COMMON_FNS.SpawnMob("cursed_helmet", pos, event and event.current_round, "mummy_curse", 0, false, inst.duplicator_count)
	boss.Transform:SetPosition(pos.x, 0, pos.z)
	boss.sg:GoToState("land")
    boss.owner = inst.owner
    if boss.owner then
        boss.owner.helmet = boss
    end
    ------------------------------------------
    inst.owner:PushEvent("linked_cursed_helmet", {cursed_helmet = boss})
    ------------------------------------------
	inst:Remove()
end

local function helmproj_fn()
	--This is just a barebones projectile whose sole purpose is to spawn the helmet when it "lands" on the ground.
	--TODO make this more flexible for other possible variants
    local inst = COMMON_FNS.BasicEntityInit("hf_cursed_helmet", "hf_cursed_helmet", "spin_loop", {pristine_fn = function(inst)
        inst.Transform:SetTwoFaced()
    	MakeInventoryPhysics(inst)
        ------------------------------------------
    	--TODO perhaps adjust the radius a bit since its just the helmet. Its currently sharing the same light properties as hardmode mummyclops.
    	inst.AnimState:SetLightOverride(0.1) --Light colours need to be flexible too.
        ------------------------------------------
    	inst.entity:AddLight()
    	inst.Light:SetIntensity(0.7)
    	inst.Light:SetRadius(1.75)
    	inst.Light:SetFalloff(0.7)
    	inst.Light:Enable(true)
    	inst.Light:SetColour(255/255, 56/255, 122/255)
    end})
    ------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    inst.land_task = inst:DoPeriodicTask(0.1, function(inst) --iirc theres alternate methods that might be better suited for this. So far its at least serviceable.
		local pos = inst:GetPosition()
		if pos.y < 1 then
			Land(inst, pos)
		end
	end)
    ------------------------------------------
    return inst
end
--------------------------------------------------------------------------
return ForgePrefab("inforge_cursed_helmet", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, "HALLOWED_FORGE", "images/hallowedforge_icons.xml", "icon_cursed_helmet.tex"),
