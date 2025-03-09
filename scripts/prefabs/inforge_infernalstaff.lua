local assets = {
    Asset("ANIM", "anim/fireballstaff.zip"),
    Asset("ANIM", "anim/swap_fireballstaff.zip"),
}
local prefabs = {
    "forge_fireball_projectile",
    "forge_fireball_hit_fx",
    "infernalstaff_meteor",
    "reticuleaoe",
    "reticuleaoeping",
    "reticuleaoehostiletarget",
}
local PROJECTILE_DELAY = 4 * FRAMES -- TODO tuning? if tuning might be able to put in common prefab fn
local tuning_values = TUNING.INFORGE.INFORGE_INFERNALSTAFF
--------------------------------------------------------------------------
-- Ability Functions
--------------------------------------------------------------------------
local function Cataclysm(inst, caster, pos)
	SpawnPrefab("infernalstaff_meteor"):AttackArea(caster, inst, pos, nil, COMMON_FNS.GetPlayerExcludeTags(caster))
	inst.components.rechargeable:StartRecharge()
end

local function CalcAltDamage(inst, attacker, target) -- TODO 220 for mobs outside of hitrange, check this
    local centerpos = inst.meteor:GetPosition()
    local base_damage = tuning_values.ALT_DAMAGE
    local center_mult = tuning_values.ALT_CENTER_MULT
    local base_dist = tuning_values.ALT_RADIUS * tuning_values.ALT_RADIUS -- 16
    local dist = distsq(centerpos, target:GetPosition())
    local dist_ratio = math.max(0, 1 - dist / base_dist)
    return base_damage*(1 + Lerp(0, center_mult, dist_ratio))
end
--------------------------------------------------------------------------
-- Attack Functions
--------------------------------------------------------------------------
local function OnAttack(inst, attacker, target)
	if inst.components.weapon.isaltattacking then
		local hit_fx = COMMON_FNS.CreateFX("infernalstaff_meteor_splashhit", target, attacker)
        hit_fx:SetTarget(target)
	end
end

local function OnSwing(inst, attacker, target)
    local offset = (target:GetPosition() - attacker:GetPosition()):GetNormalized()*1.2
    local particle = COMMON_FNS.CreateFX("forge_fireball_hit_fx", target, attacker, {scale = 0.8})
    particle.Transform:SetPosition((attacker:GetPosition() + offset):Get())
    --particle.AnimState:SetScale(0.8,0.8)
end
--------------------------------------------------------------------------
-- Pristine Functions
--------------------------------------------------------------------------
local function PristineFN(inst)
    COMMON_FNS.AddTags(inst, "magicweapon", "rangedweapon", "firestaff", "pyroweapon")
    ------------------------------------------
    inst.projectiledelay = PROJECTILE_DELAY
end
--------------------------------------------------------------------------
local weapon_values = {
    swap_strings  = {"swap_fireballstaff"},
	OnAttack      = OnAttack,
	projectile    = "forge_fireball_projectile",
	projectile_fn = OnSwing,
	CalcAltDamage = CalcAltDamage,
	AOESpell      = Cataclysm,
    pristine_fn   = PristineFN,
}
--------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.EQUIPMENT.CommonWeaponFN("fireballstaff", nil, weapon_values, tuning_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
    inst.castsound = "dontstarve/common/lava_arena/spell/meteor"
	------------------------------------------
    inst.components.equippable.walkspeedmult = tuning_values.SPEEDMULT

    return inst
end
--------------------------------------------------------------------------
return ForgePrefab("inforge_infernalstaff", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/inventoryimages.xml", "fireballstaff.tex", "swap_fireballstaff", "common_hand")
