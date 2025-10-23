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
    Asset("ANIM", "anim/swap_lucy_axe.zip"),
    Asset("ANIM", "anim/lavaarena_lucy.zip"),
    Asset("INV_IMAGE", "lucy"),
}
local assets_fx = {
    Asset("ANIM", "anim/lavaarena_lucy.zip"),
}
local assets_lavasplash = {
	Asset("ANIM", "anim/splash_ocean.zip"),
}
local prefabs = {
    "reticulelong",
    "reticulelongping",
	"weaponsparks_fx",
    "weaponsparks_piercing_fx",
    "weaponsparks_bouncing_fx",
    "lucy_transform_fx",
    "splash_lavafx",
    "lucyspin_fx",
}
local tuning_values = TUNING.FORGE.RILEDLUCY
--------------------------------------------------------------------------
-- Ability Functions
--------------------------------------------------------------------------
local function ChuckLucy(inst, caster, pos)
	inst.components.projectile:AimedThrow(inst, caster, pos, caster.components.combat:CalcDamage(nil, inst, nil, true, nil, tuning_values.ALT_STIMULI), true)
    inst.components.aoespell:OnSpellCast(caster, nil, inst)
end

local function MakeNormal(inst)
	inst.Physics:Stop()
	inst.ismoving = false -- TODO not used...
	inst.components.projectile:Stop()
	inst:RemoveTag("NOCLICK")
	ChangeToInventoryPhysics(inst)
	inst.components.inventoryitem.canbepickedup = true
	inst.AnimState:SetMultColour(1,1,1,1)
    inst.components.scaler:ApplyScale()
end

local function IsValidPosition(inst)
    local pos = inst:GetPosition()
	return TheWorld.Map:IsGroundTargetBlocked(pos) or not TheWorld.Map:IsPassableAtPoint(pos:Get()) or not TheWorld.Map:IsValidTileAtPoint(pos:Get())
end

--[[
TODO
    what fx plays when throwing lucy out in lave and/or the stands?
        woodie?
        other character?
    How does lucy return to arena when thrown out of bounds?
--]]
local function Return(inst, attacker)
	attacker.components.combat.ignorehitrange = false
	inst.Physics:SetMotorVel(5, 0, 0)
    inst.components.inventoryitem.pushlandedevents = not (attacker) or inst.no_return -- This prevents the ReturnToGround function being called twice. Once by the is_landed check in inventoryitem and the check below
	inst:DoTaskInTime(15*FRAMES, function()
		inst.Physics:Stop()
        -- Return to thrower if Woodie
		if attacker then
			inst.AnimState:SetMultColour(0,0,0,0)
			inst.returnfrompos = inst:GetPosition()
            SpawnPrefab("lucy_transform_fx").Transform:SetPosition(inst:GetPosition():Get())
			inst.projectileowner = nil
			inst:DoTaskInTime(12*FRAMES, function()
                if attacker and attacker.entity and attacker.entity:IsValid() and attacker.entity:IsVisible() then -- TODO is any of this if statement needed? attacker should exist to even be here...
                    if attacker.sg:HasStateTag("idle") then
                        inst.projectileowner = attacker
                    end
                    attacker.components.inventory:Equip(inst)
                    local origin_pos = inst.returnfrompos or inst:GetPosition() or Vector3(0,0,0)
                    attacker:SpawnChild("lucyspin_fx"):SetOrigin(origin_pos:Get())
                    -- Play the transform fx if the attacker does not have a catch_equip state
                    if not attacker.sg.statemem.playedfx then
                        SpawnPrefab("lucy_transform_fx").entity:AddFollower():FollowSymbol(attacker.GUID, "swap_object", 50, -25, -1)
                    end
                elseif IsValidPosition(inst) then
                    COMMON_FNS.ReturnToGround(inst)
                end
                MakeNormal(inst)
                inst.returnfrompos = nil
            end)
        -- Drop Lucy on the ground
		else
            MakeNormal(inst)
		end
        inst.no_return = nil
	end)
end

local function OnThrown(inst, attacker, targetpos)
	attacker.components.inventory:DropItem(inst)
	inst:AddTag("NOCLICK")
	--inst.Physics:ClearCollisionMask()
	inst.components.inventoryitem.canbepickedup = false
	inst.AnimState:PlayAnimation("spin_loop", true)
	inst.ismoving = true
	attacker.components.combat.ignorehitrange = true
    inst:SetSource(nil, false)
end
--------------------------------------------------------------------------
-- Attack Functions
--------------------------------------------------------------------------

local function OnHit(inst, attacker, target)

    COMMON_FNS.EQUIPMENT.ApplyArmorBreak(attacker, target)
end
--[[
    COMMON_FNS.CreateFX("weaponsparks_piercing_fx", target, attacker)

	inst.AnimState:PlayAnimation("bounce")
	inst.AnimState:PushAnimation("idle")

	FORGE_TARGETING.ForceAggro(target, attacker, TUNING.FORGE.AGGROTIMER_LUCY)
	inst.components.projectile:RotateToTarget(attacker:GetPosition())
	Return(inst, attacker)

	if target and target.components.armorbreak_debuff and not (attacker and attacker.components.passive_shock and attacker.components.passive_shock.shock) then
		target.components.armorbreak_debuff:ApplyDebuff()
	end
end

local function OnMiss(inst, attacker, target)
    COMMON_FNS.CreateFX("weaponsparks_bouncing_fx", inst)
	inst.AnimState:PlayAnimation("bounce")
	inst.AnimState:PushAnimation("idle")
	Return(inst, attacker)
end
]]--

local function OnAttack(inst, attacker, target)
    COMMON_FNS.CreateFX("weaponsparks_fx", target, attacker)
	COMMON_FNS.EQUIPMENT.ApplyArmorBreak(attacker, target)
end
--------------------------------------------------------------------------
-- Pristine Functions
--------------------------------------------------------------------------
local function PristineFN(inst)
    inst.Transform:SetSixFaced()
    ------------------------------------------
    COMMON_FNS.AddTags(inst, "sharp", "throw_line", "chop_attack", "irreplaceable") --TODO: irreplaceable tag is a temp fix for the being
end
--------------------------------------------------------------------------
local weapon_values = {
    name_override = "lavaarena_lucy",
    image_name    = "lucy",
    swap_strings  = {"swap_lucy_axe"},
	OnAttack      = OnAttack,
	AOESpell      = ChuckLucy,
    pristine_fn   = PristineFN,
}
--------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.EQUIPMENT.CommonWeaponFN("lavaarena_lucy", nil, weapon_values, tuning_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    inst:AddComponent("scaler")
    ------------------------------------------
	inst:AddComponent("projectile") -- TODO tuning? common fn?
	inst.components.projectile:SetSpeed(30)
	inst.components.projectile:SetRange(tuning_values.ALT_DIST)
	inst.components.projectile:SetHitDist(tuning_values.ALT_HIT_RANGE*3)
	inst.components.projectile:SetStimuli(tuning_values.ALT_STIMULI)
	--inst.components.projectile:SetDamage(tuning_values.ALT_DAMAGE)
	inst.components.projectile:SetOnThrownFn(OnThrown)
    inst.components.projectile:SetOnHitFn(OnHit)
	--inst.components.projectile:SetOnMissFn(OnMiss)
	inst.components.projectile:SetMeleeWeapon(true)
    inst.components.projectile.is_piercing = true
	inst.components.projectile.no_pierce_limit = true
    ------------------------------------------
    inst.SetSource = COMMON_FNS.EQUIPMENT.SetProjectileSource
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------


--------------------------------------------------------------------------
return ForgePrefab("spinlucy", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/inventoryimages.xml", "lucy.tex", "swap_lucy_axe", "common_hand")
