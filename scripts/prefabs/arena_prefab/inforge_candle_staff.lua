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
    Asset("ANIM", "anim/fireballstaff.zip"),
    Asset("ANIM", "anim/swap_fireballstaff.zip"),

	Asset("ANIM", "anim/hf_candle_staff.zip"),
	Asset("ANIM", "anim/swap_hf_candle_staff.zip"),
}
local prefabs = {
    "forge_fireball_projectile",
    "forge_fireball_hit_fx",
    "infernalstaff_meteor",
    "reticuleaoe",
    "reticuleaoeping",
	"inforge_candlefire",
    "reticuleaoehostiletarget",
}
local PROJECTILE_DELAY = 4 * FRAMES -- TODO tuning? if tuning might be able to put in common prefab fn
local tuning_values = TUNING.HALLOWED_FORGE.HF_CANDLE_STAFF
--------------------------------------------------------------------------
-- Ability Functions
--------------------------------------------------------------------------
local function LightTurret(inst, caster, pos)
	local light_turret = COMMON_FNS.Summon("light_turret", caster, pos)
	light_turret:SetCaster(caster)
	inst.components.rechargeable:StartRecharge()
	inst.components.aoespell:OnSpellCast(caster)
end
--------------------------------------------------------------------------
-- Attack Functions
--------------------------------------------------------------------------
local function OnSwing(inst, attacker, target)
	local offset = (target:GetPosition() - attacker:GetPosition()):GetNormalized()*1.2
	local particle = SpawnPrefab("hf_candlestaff_hit_fx")
	particle.Transform:SetPosition((attacker:GetPosition() + offset):Get())
	particle.AnimState:SetScale(0.5,0.5)
end

local function OnAttack(inst, attacker, target)
	if target.components.burnable and target.components.burnable.lightmebaby and target.components.fueled then
		target.components.fueled:AddFuel(attacker, attacker.components.combat:CalcDamage(target, inst))
	end
end
--------------------------------------------------------------------------
-- Weapon Functions
--------------------------------------------------------------------------
local function OnPickUp(inst, owner)
	if inst.fx then
		inst.fx:Remove()
		inst.fx = nil
	end
end

local function OnDropped(inst, owner)
	if not inst.fx then
		inst.fx = SpawnPrefab("inforge_candlefire")
		inst.fx.entity:SetParent(inst.entity)
		inst.fx.entity:AddFollower()
		inst.fx.Follower:FollowSymbol(inst.GUID, "swap_fire", 0, 0, 0)
		inst.fx._light.Light:SetColour(182/255, 156/255, 255/255)
		inst.fx:AttachLightTo(inst)
	end
end

local function OnEquip(inst, owner)
	owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
	owner.AnimState:OverrideSymbol("swap_object", "swap_hf_candle_staff", "swap_hf_candle_staff")
    owner.SoundEmitter:PlaySound("dontstarve/wilson/torch_swing")
	if inst.fires == nil then
		OnPickUp(inst, owner)
        inst.fires = {}
        local fx = SpawnPrefab("inforge_candlefire")
        fx.entity:SetParent(owner.entity)
        fx.entity:AddFollower()
        fx.Follower:FollowSymbol(owner.GUID, "swap_object", 15, -210, 0)
		fx._light.Light:SetColour(182/255, 156/255, 255/255)
        fx:AttachLightTo(owner)

        table.insert(inst.fires, fx)
    end
end

local function OnUnequip(inst, owner)
	if inst.fires ~= nil then
        for i, fx in ipairs(inst.fires) do
            fx:Remove()
        end
        inst.fires = nil
    end
    OnDropped(inst, owner)
end
--------------------------------------------------------------------------
-- Pristine Functions
--------------------------------------------------------------------------
local function PristineFN(inst)
	COMMON_FNS.AddTags(inst, "magicweapon", "rangedweapon", "firestaff", "pyroweapon", "rangedlighter")
	------------------------------------------
	inst.projectiledelay = PROJECTILE_DELAY
end
--------------------------------------------------------------------------
local weapon_values = {
	swap_strings  = {"swap_hf_candle_staff"},
	OnAttack      = OnAttack,
	projectile    = "hf_candlestaff_projectile",
	projectile_fn = OnSwing,
	AOESpell      = LightTurret,
	onequip_fn    = OnEquip,
	onunequip_fn  = OnUnequip,
	pristine_fn   = PristineFN,
}
--------------------------------------------------------------------------
local function fn()
	--overworld item sprites are usually 200x200 - 250x250
	local inst = COMMON_FNS.EQUIPMENT.CommonWeaponFN("hf_candle_staff", "hf_candle_staff", weapon_values, tuning_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	inst.components.inventoryitem.atlasname = "images/hallowedforge_icons.xml"
	inst.components.inventoryitem:SetOnPickupFn(OnPickUp)
	inst.components.inventoryitem:SetOnDroppedFn(OnDropped)
    ------------------------------------------
    inst.fx = SpawnPrefab("inforge_candlefire")
    inst.fx.entity:SetParent(inst.entity)
    inst.fx.entity:AddFollower()
    inst.fx.Follower:FollowSymbol(inst.GUID, "swap_fire", 0, 0, 0)
    inst.fx._light.Light:SetColour(182/255, 156/255, 255/255)
    inst.fx:AttachLightTo(inst)
	------------------------------------------
    inst.castsound = "dontstarve/common/lava_arena/spell/meteor"
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
local function fire_fn(inst)
	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	return inst
end
--------------------------------------------------------------------------
return ForgePrefab("inforge_candle_staff", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, "HALLOWED_FORGE", "images/hallowedforge_icons.xml", "hf_candle_staff.tex", "swap_hf_candle_staff", "common_hand")
