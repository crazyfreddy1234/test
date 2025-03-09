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
local assets = {
    Asset("ANIM", "anim/lavaarena_firebomb.zip"),
    Asset("ANIM", "anim/swap_lavaarena_firebomb.zip"),
}
local assets_fx = {
    Asset("ANIM", "anim/lavaarena_firebomb.zip"),
}
local assets_sparks = {
    Asset("ANIM", "anim/sparks_molotov.zip"),
}
local prefabs = {
    "firebomb_projectile",
    "firebomb_proc_fx",
    "firebomb_sparks",
    "reticuleaoesmall",
    "reticuleaoesmallping",
    "reticuleaoesmallhostiletarget",
}
local prefabs_projectile = {
    "firebomb_explosion",
    "firehit",
}
local tuning_values = TUNING.FORGE.FIREBOMB
--------------------------------------------------------------------------
-- Ability Functions
--------------------------------------------------------------------------
-- TODO COMMON FN
local function DoExplosiveAoe(weapon, projectile, caster, target_pos, radius, damage, excluded_targets, is_alt)
	local targets = COMMON_FNS.EQUIPMENT.GetAOETargets(caster, target_pos, radius, nil, COMMON_FNS.GetPlayerExcludeTags(caster), nil, excluded_targets)
	for _,target in pairs(targets) do
		caster.components.combat:DoAttack(target, weapon, projectile, tuning_values.ALT_STIMULI, nil, damage, is_alt)
	end
end

local function ResetCharge(inst)
	inst.charge = 0
	inst.active = false
	inst.components.weapon:SetDamage(tuning_values.DAMAGE)
	inst.components.weapon:SetStimuli(tuning_values.STIMULI)
	if inst.charge_fx then
		inst.charge_fx:Remove()
		inst.charge_fx = nil
	end
	RemoveTask(inst.chargetask)
	inst.SoundEmitter:KillSound("hiss")
end

local function FireBombTossRepeat(inst, caster, pos, weapon)
    local Bomb_Count = 3
    local random = math.random()
    local firebomb_pos = inst:GetPosition()

    for i=1,Bomb_Count do
        local pt = pos
        local theta = ((i/Bomb_Count) + random) * 2 * PI
        local radius = 3
        local offset = FindWalkableOffset(pt, theta, radius, 2, true, true)
        if offset then
            print("active")
            pt = pt + offset
        else
            print("not active")
            pt = nil 
        end

        if pt then
            weapon:DoTaskInTime(0, function()
                local projectile = SpawnPrefab("infernal_firebomb_projectile")
                projectile.ischild = true
                projectile.Transform:SetPosition(firebomb_pos:Get())
                projectile.owner = caster
                projectile.components.complexprojectile:Launch(pt, caster, weapon, caster.components.combat:CalcDamage(nil, weapon, nil, true, nil, tuning_values.ALT_STIMULI), true)--print(tostring(ThePlayer.components.combat:CalcDamage(nil, inst, nil, true)))
                projectile:AttackArea(caster, weapon, pos)
            end)
        end
    end
end

local function FirebombToss(inst, caster, pos)
    --inst:ListenForEvent("firebomb_explode",FireBombTossRepeat)
	local projectile = SpawnPrefab("infernal_firebomb_projectile")
	projectile.Transform:SetPosition(inst:GetPosition():Get())
	projectile.owner = caster
	projectile.components.complexprojectile:Launch(pos, caster, inst, caster.components.combat:CalcDamage(nil, inst, nil, true, nil, tuning_values.ALT_STIMULI), true)--print(tostring(ThePlayer.components.combat:CalcDamage(nil, inst, nil, true)))
	projectile:AttackArea(caster, inst, pos) -- TODO is this needed?
	ResetCharge(inst)
	inst.components.rechargeable:StartRecharge()
	inst.components.aoespell:OnSpellCast(caster)
end

--Leo: Since I'm still looking for proof that firebombs lose charge overtime and not just fizzle, just gonna do it the easy way for now.
--Charge just fizzles if not attacking for 5 seconds.
local function AddChargeLvL(inst, level)
	if not inst.charge_fx then
		inst.charge_fx = COMMON_FNS.CreateFX("infernal_firebomb_sparks", nil, inst)
		inst.charge_fx.entity:AddFollower()
		inst.charge_fx.Follower:FollowSymbol(inst.components.inventoryitem.owner.GUID, "swap_object", 45, -10, 0)
        if inst.SoundEmitter:PlayingSound("hiss") then
            inst.SoundEmitter:KillSound("hiss")
        end
        inst.SoundEmitter:PlaySound("dontstarve/common/blackpowder_fuse_LP", "hiss")
	end
	inst.charge_fx.SetSparkLevel(inst.charge_fx, level)
end

local function DoProcAlt(inst, caster, target)
	local pos = target:GetPosition()
	local fx = COMMON_FNS.CreateFX("infernal_firebomb_proc_fx", target, caster)
	--Leo: For some reason doing the proc bomb here makes it attack twice, making the fx do it for now.
	fx.Transform:SetPosition(pos:Get())
	inst.SoundEmitter:PlaySound("dontstarve/common/blackpowder_explo")
	-- TODO weapons position? or should it be the target it hits position?
    local scale = inst.Transform:GetScale()
	DoExplosiveAoe(inst, nil, caster, pos, tuning_values.PASSIVE_RANGE*scale, nil, {[target] = true}) -- TODO does 15 dmg atm, fix
	ResetCharge(inst)
end
--------------------------------------------------------------------------
-- Attack Functions
--------------------------------------------------------------------------
local function OnHitOther(inst, caster, target)
	--print("DEBUG: Firebomb is charging")
	if inst.components.inventoryitem.owner and not inst.active then
		inst.charge = (inst.charge or 0) + 1
		RemoveTask(inst.chargetask)
		inst.chargetask = inst:DoTaskInTime(tuning_values.CHARGE_DECAY_TIME, ResetCharge)
		if inst.charge > tuning_values.MAXIMUM_CHARGE_HITS then
			inst.active = true
			DoProcAlt(inst, caster, target)
		elseif inst.charge == tuning_values.MAXIMUM_CHARGE_HITS then
			inst.components.weapon:SetDamage(tuning_values.ALT_DAMAGE)
		elseif inst.charge >= tuning_values.CHARGE_HITS_2 then
			AddChargeLvL(inst, 2)
		elseif inst.charge >= tuning_values.CHARGE_HITS_1 then
			AddChargeLvL(inst, 1)
		end
	end
end

local function GetStimuliFn(inst, owner, target)
    return inst.charge == tuning_values.MAXIMUM_CHARGE_HITS and tuning_values.ALT_STIMULI or tuning_values.STIMULI
end
--------------------------------------------------------------------------
-- Pristine Functions
--------------------------------------------------------------------------
local function PristineFN(inst)
    inst.entity:AddSoundEmitter()
    ------------------------------------------
    inst:AddTag("throw_line")
end
--------------------------------------------------------------------------
local weapon_values = {
    name_override = "lavaarena_firebomb",
    swap_strings  = {"swap_lavaarena_firebomb"},
	AOESpell      = FirebombToss,
	OnAttack      = OnHitOther,
    onunequip_fn  = ResetCharge,
    pristine_fn   = PristineFN,
}
--------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.EQUIPMENT.CommonWeaponFN("lavaarena_firebomb", nil, weapon_values, tuning_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	inst.charge = 0
	inst.charge_level = 0
    inst.components.weapon:SetOverrideStimuliFn(GetStimuliFn)
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
-- Projectile Functions
--------------------------------------------------------------------------
local function CreateProjectileAnim(source)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    ------------------------------------------
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    ------------------------------------------
    --[[Non-networked entity]]
    inst.persists = false
    ------------------------------------------
	--Leo: We're not sure why Klei left this here, but it seems to break other similar projectiles like waterballoon?
	--Doesn't seem to do anything in general, real weird. If anyone is using this for their own firebomb clone, if your projectile is turning invisible, just disable this.
    --inst.Transform:SetSixFaced()
    ------------------------------------------
    inst.AnimState:SetBank("lavaarena_firebomb")
    inst.AnimState:SetBuild("lavaarena_firebomb")
    inst.AnimState:PlayAnimation("spin_loop", true)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    ------------------------------------------
    local scale = source.Transform:GetScale()
    inst.Transform:SetScale(scale,scale,scale)
    ------------------------------------------
    return inst
end

local function OnDirectionDirty(inst)
    inst.animent.Transform:SetRotation(inst.direction:value())
end

local function onthrown(inst, owner)
    inst:AddTag("NOCLICK")
    inst.persists = false
    ------------------------------------------
    if inst.SoundEmitter:PlayingSound("hiss") then
        inst.SoundEmitter:KillSound("hiss")
    end
    inst.SoundEmitter:PlaySound("dontstarve/common/blackpowder_fuse_LP", "hiss")
    ------------------------------------------
    --inst.Physics:SetMass(1)
    --inst.Physics:SetCapsule(0.2, 0.2)
    --inst.Physics:SetFriction(0)
    --inst.Physics:SetDamping(0)
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.ITEMS)
end

local function OnHitFire(inst, attacker, target, weapon, damage)
    if inst.ischild ~= true then
        FireBombTossRepeat(inst,attacker,inst:GetPosition(),weapon)
    end
	inst.SoundEmitter:KillSound("hiss")
	local explosion = COMMON_FNS.CreateFX("infernal_firebomb_explosion", target, attacker)
    explosion.Transform:SetPosition(inst.Transform:GetWorldPosition())
    local scale = inst.Transform:GetScale()
	DoExplosiveAoe(weapon, inst, attacker, inst:GetPosition(), tuning_values.ALT_RANGE*scale, damage, nil, true)
    inst:DoTaskInTime(FRAMES,function()
        inst:Remove()
    end)
end
--------------------------------------------------------------------------
-- Physics Functions
--------------------------------------------------------------------------
local physics = {
    mass   = 1,
    radius = 0.2,
}
local function PhysicsInit(inst)
    inst.entity:AddPhysics()
    inst.Physics:SetMass(physics.mass)
    inst.Physics:SetFriction(0)
    inst.Physics:SetDamping(0)
    inst.Physics:SetRestitution(.5)
    inst.Physics:SetCollisionGroup(COLLISION.ITEMS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
    inst.Physics:SetCapsule(physics.radius,physics.radius)
end

local function PristineFN(inst)
    inst.entity:AddSoundEmitter()
    ------------------------------------------
    inst.direction = net_float(inst.GUID, "lavaarena_firebomb_projectile.direction", "directiondirty")
    ------------------------------------------
    --Dedicated server does not need to spawn the local animation
    if not TheNet:IsDedicated() then
        inst.animent = CreateProjectileAnim(inst)
        inst.animent.entity:SetParent(inst.entity)
    end
end
--------------------------------------------------------------------------
local projectile_values = {
    physics         = physics,
    physics_init_fn = PhysicsInit,
    pristine_fn     = PristineFN,
    complex         = true,
    no_tail         = true,
    speed           = tuning_values.HORIZONTAL_SPEED,
    gravity         = tuning_values.GRAVITY,
    launch_offset   = Vector3(unpack(tuning_values.VECTOR)),
    OnLaunch        = onthrown,
    OnHit           = OnHitFire,
}
--------------------------------------------------------------------------
local function projectilefn()
    local inst = COMMON_FNS.EQUIPMENT.CommonProjectileFN(nil, nil, nil, projectile_values)
    ------------------------------------------
    if not TheWorld.ismastersim then
        inst:ListenForEvent("directiondirty", OnDirectionDirty)
        return inst
    end
    ------------------------------------------
	inst.AttackArea = function(inst, attacker, weapon, pos) -- TODO are any of these actually used?
		weapon.firebomb = inst
		inst.attacker = attacker
		inst.owner = weapon
	end
    ------------------------------------------
    return inst
end
--------------------------------------------------------------------------
local function explosionfn()
    local inst = COMMON_FNS.FXEntityInit("lavaarena_firebomb", "lavaarena_firebomb", "used", {pristine_fn = function(inst)
        inst.entity:AddSoundEmitter()
        ------------------------------------------
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetLightOverride(1)
        inst.AnimState:SetFinalOffset(-1)
    end})
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	inst.persists = false
	------------------------------------------
	inst.SoundEmitter:PlaySound("dontstarve/common/blackpowder_explo")
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
local function procfxfn()
    local inst = COMMON_FNS.FXEntityInit("lavaarena_firebomb", "lavaarena_firebomb", "hitfx", {pristine_fn = function(inst)
        inst.entity:AddSoundEmitter()
        ------------------------------------------
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetLightOverride(1)
        inst.AnimState:SetFinalOffset(-1)
    end})
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	inst.persists = false
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
local function SetSparkLevel(inst, level)
    inst.AnimState:PlayAnimation(tostring(level), true)
end
--------------------------------------------------------------------------
local function sparksfn()
    local inst = COMMON_FNS.FXEntityInit("sparks_molotov", "sparks_molotov", "1", {noanimover = true, anim_loop = true, pristine_fn = function(inst)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetLightOverride(1)
        inst.AnimState:SetFinalOffset(1)
    end})
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
    inst.persists = false
    inst.SetSparkLevel = SetSparkLevel
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
return ForgePrefab("infernal_firebomb", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/inventoryimages.xml", "lavaarena_firebomb.tex", "swap_lavaarena_firebomb", "common_hand"),
    Prefab("infernal_firebomb_projectile", projectilefn, assets_fx, prefabs_projectile),
    Prefab("infernal_firebomb_explosion", explosionfn, assets_fx),
    Prefab("infernal_firebomb_proc_fx", procfxfn, assets_fx),
    Prefab("infernal_firebomb_sparks", sparksfn, assets_sparks)
