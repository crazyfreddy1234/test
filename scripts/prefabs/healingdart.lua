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
    Asset("ANIM", "anim/blowdart_lava2.zip"),
    Asset("ANIM", "anim/swap_blowdart_lava2.zip"),
}
local assets_projectile = {
    Asset("ANIM", "anim/lavaarena_blowdart_attacks.zip"),
}
local prefabs = {
    "healingdart_projectile",
    "healingdart_projectile_explosive",
    "reticulelong",
    "reticulelongping",
    
    "firebomb_projectile",
    "firebomb_proc_fx",
    "firebomb_sparks",
    "reticuleaoesmall",
    "reticuleaoesmallping",
    "reticuleaoesmallhostiletarget",
}
local prefabs_projectile = {
    "weaponsparks_piercing_fx",
}
local prefabs_projectile_explosive = {
    "explosivehit",
}
local PROJECTILE_DELAY = 4 * FRAMES -- TODO tuning? if tuning might be able to put in common prefab fn
local tuning_values = TUNING.INFORGE.HEALINGDART
--------------------------------------------------------------------------
-- Ability Functions
--------------------------------------------------------------------------
local function MoltenBolt(inst, caster, pos, options)
    if options.ctrl and options.ctrl == 2 then
        local projectile = SpawnPrefab("firebomb_projectile")
        projectile.Transform:SetPosition(inst:GetPosition():Get())
        projectile.owner = caster
        projectile.components.complexprojectile:Launch(pos, caster, inst, caster.components.combat:CalcDamage(nil, inst, nil, true, nil, tuning_values.ALT_STIMULI), true)--print(tostring(ThePlayer.components.combat:CalcDamage(nil, inst, nil, true)))
        projectile:AttackArea(caster, inst, pos) -- TODO is this needed?
        inst.components.rechargeable:StartRecharge()
        inst.components.aoespell:OnSpellCast(caster)
    else
        local dart = SpawnPrefab("healingdart_projectile_explosive")
        dart.Transform:SetPosition(inst:GetPosition():Get())
        dart.components.projectile:AimedThrow(inst, caster, pos, caster.components.combat:CalcDamage(nil, inst, nil, true, nil, tuning_values.ALT_STIMULI), true)
        dart.components.projectile:DelayVisibility(inst.projectiledelay)
        caster.SoundEmitter:PlaySound("dontstarve/common/lava_arena/blow_dart")
        inst.components.rechargeable:StartRecharge()
        inst.components.aoespell:OnSpellCast(caster, nil, dart)
    end
end
--------------------------------------------------------------------------
-- Pristine Functions
--------------------------------------------------------------------------
local function PristineFN(inst)
    COMMON_FNS.AddTags(inst, "blowdart", "sharp")
    ------------------------------------------
    inst.ability_strings = {"HEALING_DART", "HEALING_BOMB"}
    ------------------------------------------
    inst.projectiledelay = PROJECTILE_DELAY
end
--------------------------------------------------------------------------
local weapon_values = {
    name_override = "blowdart_lava2",
    swap_strings  = {"swap_blowdart_lava2"},
	projectile    = "healingdart_projectile",
	AOESpell      = MoltenBolt,
    pristine_fn   = PristineFN,
}
--------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.EQUIPMENT.CommonWeaponFN("blowdart_lava2", nil, weapon_values, tuning_values)
    ------------------------------------------
    inst.multiple_castaoe = {"blowdart","throw_line","blowdart","blowdart"}
    inst.multiple_reticule = {
        {type = "directional", pingprefab = "reticulelongping",              reticuleprefab = "reticulelong",     length = 6.5, validcolor = {0, 1, .5, 1}, invalidcolor = {0, .4, 0, 1}},
        {type = "aoe",         pingprefab = "reticuleaoesmallhostiletarget", reticuleprefab = "reticuleaoesmall", length = 5  , validcolor = {0, 1, .5, 1}, invalidcolor = {0, .4, 0, 1}},
        {type = "directional", pingprefab = "reticulelongping",              reticuleprefab = "reticulelong",     length = 6.5, validcolor = {0, 1, .5, 1}, invalidcolor = {0, .4, 0, 1}},
        {type = "directional", pingprefab = "reticulelongping",              reticuleprefab = "reticulelong",     length = 6.5, validcolor = {0, 1, .5, 1}, invalidcolor = {0, .4, 0, 1}}
    }
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
-- Projectile Functions
--------------------------------------------------------------------------
local FADE_FRAMES = 5
local tails = {
    ["tail_5_2"] = .15,
    ["tail_5_3"] = .15,
    ["tail_5_4"] = .2,
    ["tail_5_5"] = .8,
    ["tail_5_6"] = 1,
    ["tail_5_7"] = 1,
}
local thintails = {
    ["tail_5_8"] = 1,
    ["tail_5_9"] = .5,
}
local function OnUpdateProjectileTail(inst)
    local c = (not inst.entity:IsVisible() and 0) or (inst._fade ~= nil and (FADE_FRAMES - inst._fade:value() + 1) / FADE_FRAMES) or 1
    if c > 0 then
        local thin_tail = inst.thintailcount > 0
        local tail_values = {
            bank         = "lavaarena_blowdart_attacks",
            build        = "lavaarena_blowdart_attacks",
            anim         = weighted_random_choice(thin_tail and thintails or tails) .. inst.tail_suffix,
            add_colour   = not thin_tail and {1,1,0,0} or nil,
            --final_offset = 0, -- TODO test this now, forgot to erase this to test, need to set all the other projectiles that need -1
            orientation  = ANIM_ORIENTATION.OnGround,
        }
        local tail = inst.CreateTail(tail_values, inst)
        tail.Transform:SetPosition(inst.Transform:GetWorldPosition())
        tail.Transform:SetRotation(inst.Transform:GetRotation())
        if c < 1 then
            tail.AnimState:SetTime(c * tail.AnimState:GetCurrentAnimationLength())
        end
        if thin_tail then
            inst.thintailcount = inst.thintailcount - 1
        end
    end
end

local function OnHit(inst, attacker, target)
    COMMON_FNS.CreateFX("weaponsparks_piercing_fx", target, attacker)
	inst:Remove()
end

local function ShakeIfClose(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, .4, .02, .2, inst, 30)
end

local function AltOnHit(inst, attacker, target)
    local explosive_fx = COMMON_FNS.CreateFX("explosivehit", target, attacker)
	explosive_fx.Transform:SetPosition(inst:GetPosition():Get())
	ShakeIfClose(inst)

    if target and target.components.health and not target.components.health:IsDead() and target:HasTag("player") then
        target.components.health:DoDelta(tuning_values.ALT_HEAL)
    end

	inst:Remove()
end
--------------------------------------------------------------------------
local projectile_values = {
	speed         = 30,
	range         = tuning_values.HIT_RANGE,
	--hit_dist = 0.5, default is 1 so this had 1?
	launch_offset = Vector3(-2, 1, 0),
	OnHit         = OnHit,
	alt = {
		speed   = 30,
		range   = tuning_values.ALT_RANGE,
		stimuli = tuning_values.ALT_STIMULI,
		OnHit   = AltOnHit,
	},
    add_colour    = {1,1,0,0},
}
local tail_values = {
    --bank        = "lavaarena_blowdart_attacks",
    --build       = "lavaarena_blowdart_attacks",
    --anim        = "tail_1",
    --orientation = ANIM_ORIENTATION.OnGround,
    OnUpdateProjectileTail = OnUpdateProjectileTail,
}
--------------------------------------------------------------------------
local function commonprojectilefn(anim, tail_suffix, alt)

	projectile_values.is_alt = alt
    projectile_values.pristine_fn = function(inst)
        inst.entity:AddSoundEmitter()
        ------------------------------------------
        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        ------------------------------------------
        COMMON_FNS.AddTags(inst, "dart")

        if alt then
            inst:AddTag("inf_onlyhitteammate")
        end
        ------------------------------------------
        if not TheNet:IsDedicated() then
            inst.thintailcount = alt and math.random(3, 5) or math.random(2, 4)
            inst.tail_suffix = tail_suffix
        end
        ------------------------------------------
        if alt then
            inst._fade = net_tinybyte(inst.GUID, "blowdart_lava2_projectile_explosive._fade")
        end
    end
    ------------------------------------------
    local inst = COMMON_FNS.EQUIPMENT.CommonProjectileFN("lavaarena_blowdart_attacks", "lavaarena_blowdart_attacks", anim, projectile_values, tail_values)
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    inst._hastail:set(true)
	------------------------------------------
	inst.SoundEmitter:PlaySound("dontstarve/common/lava_arena/blow_dart") -- TODO why was this in a dotask of 0? did that do anything?
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
local function projectilefn()
    return commonprojectilefn("attack_4", "", false)
end
--------------------------------------------------------------------------
local function projectileexplosivefn()
    return commonprojectilefn("attack_4_large", "_large", true)
end
--------------------------------------------------------------------------
return ForgePrefab("healingdart", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/inventoryimages.xml", "blowdart_lava2.tex", "swap_blowdart_lava2", "common_hand"),
    Prefab("healingdart_projectile", projectilefn, assets_projectile, prefabs_projectile),
    Prefab("healingdart_projectile_explosive", projectileexplosivefn, assets_projectile, prefabs_projectile_explosive)
