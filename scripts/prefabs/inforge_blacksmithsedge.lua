local assets = {
    Asset("ANIM", "anim/sword_buster.zip"),
    Asset("ANIM", "anim/swap_sword_buster.zip"),
}
local prefabs = {
    "weaponsparks_fx",
    "forgedebuff_fx",
    "superjump_fx",
    "reticulearc",
    "reticulearcping",
}
local tuning_values = TUNING.INFORGE.INFORGE_BLACKSMITHSEDGE
--------------------------------------------------------------------------
-- Attack Functions
--------------------------------------------------------------------------
local function OnAttack(inst, attacker, target)
    COMMON_FNS.CreateFX("weaponsparks_fx", target, attacker)
    COMMON_FNS.EQUIPMENT.ApplyArmorBreak(attacker, target)
    FORGE_TARGETING.ForceAggro(target, attacker, TUNING.FORGE.AGGROTIMER_LUCY)
end
--------------------------------------------------------------------------
-- Ability Functions
--------------------------------------------------------------------------
local function Parry(inst, caster, pos)
    caster:PushEvent("combat_parry", {
        direction = inst:GetAngleToPoint(pos),
        duration = inst.components.parryweapon.duration,
        weapon = inst
    })
	inst.components.rechargeable:StartRecharge() -- TODO test if this fixed the no recharge bug
    inst.components.aoespell:OnSpellCast(caster)
end

local function OnParry(inst, caster)
    --inst.components.rechargeable:StartRecharge()
    caster.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/trails/hide_pre")
end

local function OnParrySuccess(inst, caster)
    caster.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/trails/hide_hit")
end

local function OnHelmSplit(inst, attacker, target)
    local fx = COMMON_FNS.CreateFX("superjump_fx", target, attacker)
    fx:SetTarget(inst)
end
--------------------------------------------------------------------------
-- Pristine Functions
--------------------------------------------------------------------------
local function PristineFN(inst)
    --parryweapon (from parryweapon component) added to pristine state for optimization
    COMMON_FNS.AddTags(inst, "sharp", "parryweapon")
end
--------------------------------------------------------------------------
local weapon_values = {
    image_name    = "lavaarena_heavyblade",
    swap_strings  = {"swap_sword_buster"},
	AOESpell      = Parry,
	OnAttack      = OnAttack,
    pristine_fn   = PristineFN,
}
--------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.EQUIPMENT.CommonWeaponFN("sword_buster", nil, weapon_values, tuning_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
    inst:AddComponent("parryweapon")
    inst.components.parryweapon.duration = tuning_values.PARRY_DURATION
    inst.components.parryweapon:SetOnParryStartFn(OnParry)
    inst.components.parryweapon:SetOnParrySuccessFn(OnParrySuccess)
	------------------------------------------
    inst:AddComponent("helmsplitter")
    inst.components.helmsplitter:SetOnHelmSplitFn(OnHelmSplit)
    inst.components.helmsplitter:SetDamage(tuning_values.HELMSPLIT_DAMAGE)
	------------------------------------------
    inst.components.equippable.walkspeedmult = tuning_values.SPEEDMULT
    inst:ListenForEvent("equipped", function(inst, data)
        if data.owner then
            data.owner.components.health:AddHealthBuff(inst.prefab, tuning_values.MAX_HP, "flat")
        end
    end)
    inst:ListenForEvent("unequipped", function(inst, data)
        if data.owner then
            data.owner.components.health:RemoveHealthBuff(inst.prefab, "flat")
        end
    end)


    return inst
end
--------------------------------------------------------------------------
return ForgePrefab("inforge_blacksmithsedge", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/inventoryimages.xml", "lavaarena_heavyblade.tex", "swap_sword_buster", "common_hand")

