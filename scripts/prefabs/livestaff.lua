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
    Asset("ANIM", "anim/healingstaff.zip"),
    Asset("ANIM", "anim/swap_healingstaff.zip"),
}
local prefabs = {
    "forge_blossom_projectile",
    "forge_blossom_hit_fx",
    "lavaarena_healblooms",
    "reticuleaoe",
    "reticuleaoeping",
    "reticuleaoefriendlytarget",
}
local PROJECTILE_DELAY = 4 * FRAMES -- TODO tuning? if tuning might be able to put in common prefab fn
local tuning_values = TUNING.FORGE.LIVINGSTAFF
--------------------------------------------------------------------------
-- Ability Functions
--------------------------------------------------------------------------
local function LifeBlossom(inst, caster, pos)
	--[[
	local heal_rate = inst.heal_rate
	local boosted = false
	if caster.components.buffable then
		heal_rate = caster.components.buffable:ApplyStatBuffs({"spell_heal_rate", "heal_dealt"}, heal_rate)
		boosted = heal_rate > inst.heal_rate -- TODO use TUNING.FORGE
	end
	local circle = SpawnAt("healingcircle", pos)
	local cc = circle.components.heal_aura
	cc.heal_rate = heal_rate
	cc.caster = caster
    cc.range = cc.range * (caster and caster.components.scaler.scale or 1)
	circle.buffed = boosted
    circle.caster = caster
	Debug:Print("Heal: " .. tostring(heal_rate) .. "/s", nil, "LifeBlossom", nil, true)
	TheWorld:PushEvent("healingcircle_spawned")
	]]--
	if caster.components.channelcaster then
		caster.components.channelcaster:StartChanneling()
	end
end
--------------------------------------------------------------------------
local function ReticuleTargetFn()
	local player = ThePlayer
	local ground = TheWorld.Map
	local pos = Vector3()
	--Attack range is 8, leave room for error
	--Min range was chosen to not hit yourself (2 is the hit range)
	for r = 6.5, 3.5, -.25 do
		pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
		if ground:IsPassableAtPoint(pos:Get()) and not ground:IsGroundTargetBlocked(pos) then
			return pos
		end
	end
	return pos
end
--------------------------------------------------------------------------
-- Attack Functions
--------------------------------------------------------------------------
local function OnSwing(inst, attacker, target)
	inst.SoundEmitter:PlaySound("dontstarve/common/lava_arena/heal_staff")
	local offset = (target:GetPosition() - attacker:GetPosition()):GetNormalized()*1.2
	local particle = COMMON_FNS.CreateFX("forge_blossom_hit_fx", target, attacker, {scale = 0.8})
	particle.Transform:SetPosition((attacker:GetPosition() + offset):Get())
end

local function RechargeRegen_healing(inst)
	local cooldown_buff = 1
	if inst.owner then
		cooldown_buff = inst.owner.components.buffable:ApplyStatBuffs({"cooldown"}) or 1
	end
	local regen_val = (inst.healing_recharge:value() + (0.01 * cooldown_buff))

	if inst.healing_recharge:value() < 1 then
		inst.healing_recharge:set(regen_val)
	end
end

local function RechargeDegen_healing(inst)
	if inst.healing_recharge:value() > 0 then
		inst.healing_recharge:set(inst.healing_recharge:value() - (0.01 * inst.recharge_rate))
	end
end



local function RechargeRegen_dealing(inst)
	local cooldown_buff = 1
	if inst.owner then
		cooldown_buff = inst.owner.components.buffable:ApplyStatBuffs({"cooldown"}) or 1
	end
	local regen_val = (inst.dealing_recharge:value() + (0.01 * cooldown_buff))

	if inst.dealing_recharge:value() < 1 then
		inst.dealing_recharge:set(regen_val)
	end
end

local function RechargeDegen_dealing(inst)
	if inst.dealing_recharge:value() > 0 then
		inst.dealing_recharge:set(inst.dealing_recharge:value() - (0.01 * inst.recharge_rate))
	end
end


local RIGHT_TAG = { "player" }
local EXCEPTION_TAG = {"notarget", "INLIMBO", "playerghost"}

local ENEMY_TAG = {"LA_mob"}
local EXCEPTION_ENEMY_TAG = {"player", "notarget", "INLIMBO", "playerghost"}
local ABSORB_RANGE = 5

local function HealingPlayers(weapon, pos)
	local x, y, z = pos.x or 0, 0, pos.z or 0
	local players = TheSim:FindEntities(x, y, z, ABSORB_RANGE, RIGHT_TAG, EXCEPTION_TAG)
	local is_heal_activate = false

	local weapon_owner = weapon.owner or nil
	local heal_dealt = weapon_owner and weapon_owner.components.buffable:ApplyStatBuffs({"heal_dealt"}) or 1

	for i, v in ipairs(players) do
		if v:IsValid() and not v:IsInLimbo() and v.components.health and not v.components.health:IsDead() and v.components.health:IsHurt() 
		and weapon.healing_recharge:value() > 0 then
			
			v.components.health:DoDelta(weapon.heal_rate * heal_dealt)
			is_heal_activate = true
		end
	end	

	if weapon.isplayer_healed 
	and #players > 0 and is_heal_activate == true then
		weapon.isplayer_healed:set(true)
		RechargeDegen_healing(weapon)
	else
		weapon.isplayer_healed:set(false)
		RechargeRegen_healing(weapon)
	end
end

local function DealingEnemies(weapon, pos)
	local x, y, z = pos.x or 0, 0, pos.z or 0
	local enemies = TheSim:FindEntities(x, y, z, ABSORB_RANGE, ENEMY_TAG, EXCEPTION_ENEMY_TAG)
	local is_deal_activate = false

	local weapon_owner = weapon.owner or nil
	local heal_dealt = weapon_owner and weapon_owner.components.buffable:ApplyStatBuffs({"heal_dealt"}) or 1

	for i, enemy in ipairs(enemies) do
		if enemy:IsValid() and not enemy:IsInLimbo() and enemy.components.health and not enemy.components.health:IsDead() and weapon.dealing_recharge:value() > 0 then
			weapon_owner.components.combat:DoAttack(enemy, weapon, nil, nil, nil, weapon.deal_rate * heal_dealt, true)
			is_deal_activate = true
		end
	end	

	if weapon.isplayer_dealing 
	and #enemies > 0 and is_deal_activate == true then
		weapon.isplayer_dealing:set(true)
		RechargeDegen_dealing(weapon)
	else
		weapon.isplayer_dealing:set(false)
		RechargeRegen_dealing(weapon)
	end
end

local function OnStartChanneling(inst, user)
	user.SoundEmitter:PlaySound("meta3/willow_lighter/lighter_absorb_LP","channel_loop")

	inst:AddTag("startchaneeling")

	if inst.staff_mode:value() == true then
		inst.healing_mode:set(true)

		if inst.recharge_regen_task then
			inst.recharge_regen_task:Cancel()
			inst.recharge_regen_task = nil
		end
	else
		inst.dealing_mode:set(true)

		if inst.recharge_deal_task then
			inst.recharge_deal_task:Cancel()
			inst.recharge_deal_task = nil
		end
	end
end

local function OnStartChanneling_Client(inst, staff_mode)
	if not _G.TheNet:IsDedicated() then
		if _G.ThePlayer == nil then
            return
        end

		if inst.components.reticule ~= nil then
			inst.components.reticule.mouseenabled = true
			inst.components.reticule:CreateReticule()
		end

		if staff_mode == true then
			if inst.healing_task then
				inst.healing_task:Cancel()
			end

			local function UpdateHealing(inst)
				if _G.ThePlayer == nil then
					return
				end

				local pos = _G.TheInput:GetWorldPosition()
				if pos then
					SendModRPCToServer(GetModRPC("Infernal_Forge_RPC", "SendMousePos"), pos.x, pos.z, "healing")
				end
			end

			inst.healing_task = inst:DoPeriodicTask(0.5, UpdateHealing)
		else
			if inst.dealing_task then
				inst.dealing_task:Cancel()
			end

			local function UpdateDealing(inst)
				if _G.ThePlayer == nil then
					return
				end

				local pos = _G.TheInput:GetWorldPosition()
				if pos then
					SendModRPCToServer(GetModRPC("Infernal_Forge_RPC", "SendMousePos"), pos.x, pos.z, "dealing")
				end
			end

			inst.dealing_task = inst:DoPeriodicTask(0.5, UpdateDealing)
		end
	end
end

local function OnStopChanneling(inst, user)
    user.SoundEmitter:KillSound("channel_loop")
    user.SoundEmitter:PlaySound("meta3/willow_lighter/extinguisher_deactivate")
	
	inst:RemoveTag("startchaneeling")

	if inst.staff_mode:value() == true then
		inst.healing_mode:set(false)
		inst.isplayer_healed:set(false)

		inst.recharge_regen_task = inst:DoPeriodicTask(0.5, RechargeRegen_healing)
	else
		inst.dealing_mode:set(false)
		inst.isplayer_dealing:set(false)

		inst.recharge_deal_task = inst:DoPeriodicTask(0.5, RechargeRegen_dealing)
	end
end

local function OnStopChanneling_Client(inst, staff_mode)
	if not _G.TheNet:IsDedicated() then

		if inst.components.reticule ~= nil then
			inst:DoTaskInTime(0, function()
				inst.components.reticule:DestroyReticule()
				inst.components.reticule.mouseenabled = false
			end)
		end

		if staff_mode == true then
			if inst.healing_task then
				inst.healing_task:Cancel()
				inst.healing_task = nil
			end
		else
			if inst.dealing_task then
				inst.dealing_task:Cancel()
				inst.dealing_task = nil
			end
		end
	end
end

local function OnEquipFn(inst, owner)
	inst.owner = owner

	if inst.components.channelcastable == nil then
		inst:AddComponent("channelcastable")
		inst.components.channelcastable:SetOnStartChannelingFn(OnStartChanneling)
		inst.components.channelcastable:SetOnStopChannelingFn(OnStopChanneling)
	end
end

local function OnUnEquip(inst, owner)
	inst.owner = nil
end
--------------------------------------------------------------------------
-- Pristine Functions
--------------------------------------------------------------------------
local function PristineFN(inst)
	inst.entity:AddSoundEmitter()
	------------------------------------------
	COMMON_FNS.AddTags(inst, "rangedweapon", "magicweapon")
	------------------------------------------
	inst.projectiledelay = PROJECTILE_DELAY
end
--------------------------------------------------------------------------
local weapon_values = {
	name_override = "livestaff",
	swap_strings  = {"swap_livestaff"},
	projectile    = "forge_blossom_projectile",
	projectile_fn = OnSwing,
	AOESpell      = LifeBlossom,
	pristine_fn   = PristineFN,
	onequip_fn    = OnEquipFn,
	onunequip_fn  = OnUnEquip,
}
--------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.BasicEntityInit("healingstaff", nil, weapon_values.anim, {pristine_fn = function(inst)
		MakeInventoryPhysics(inst)
		------------------------------------------
		inst.nameoverride = weapon_values.name_override
		------------------------------------------
		if weapon_values.pristine_fn then
			weapon_values.pristine_fn(inst)
		end
	end})
	------------------------------------------
	inst.staff_mode = _G.net_bool(inst.GUID, "livestaff.staff_mode", "staff_mode_dirty") -- is staff dealing mod or healing mod (healing = true , dealing = false)
	inst.staff_mode:set(true)

	inst:ListenForEvent("staff_mode_dirty", function(inst)
		if inst.staff_mode:value() == true then
			inst.dealing_mode:set(false)
			inst:PushEvent("forcerechargechange", {percent = inst.healing_recharge:value(), overtime = false}) -- change weapon's recharge view (inst.healing_recharge:value() == 1 == 100%)
		else
			inst.healing_mode:set(false)
			inst:PushEvent("forcerechargechange", {percent = inst.dealing_recharge:value(), overtime = false}) -- change weapon's recharge view (inst.dealing_recharge:value() == 1 == 100%)
		end
	end)
------------------------------------------------------------------------------------------------------------------------------------
	inst.healing_mode = _G.net_bool(inst.GUID, "livestaff.healing_mode", "healing_mode_dirty") -- is caster doing heal mode
	inst.healing_mode:set(false)

	if not _G.TheNet:IsDedicated() then
		inst:ListenForEvent("healing_mode_dirty",function(inst)
			if inst.healing_mode:value() == true then
				OnStartChanneling_Client(inst, true) -- true means healing
			else
				OnStopChanneling_Client(inst, true) -- true means healing
			end
		end)
	end
------------------------------------------------------------------------------------------------------------------------------------
	inst.isplayer_healed = _G.net_bool(inst.GUID, "livestaff.isplayer_healed", "isplayer_healed_dirty") -- is caster doing healing mode & someone (include caster) got healed
	inst.isplayer_healed:set(false)

	inst:ListenForEvent("isplayer_healed_dirty", function(inst)
		if inst.isplayer_healed:value() == true then  -- change reticule(circle) color to green (healing targets deteted)
			inst.components.reticule.validcolour = {0, 1, .75, .6}
			inst.components.reticule.invalidcolour = {0, 1, .75, .6}
		else                                          -- change reticule(circle) color to red (no healing targets)
			inst.components.reticule.validcolour = {0.5, 0.5, 0.5, .6}
			inst.components.reticule.invalidcolour = {0.5, 0.5, 0.5, .6}
		end
	end)
	------------------------------------------------------------------------------------------------------------------------------------
	inst.dealing_mode = _G.net_bool(inst.GUID, "livestaff.dealing_mode", "dealing_mode_dirty") -- is caster doing dealing mode
	inst.dealing_mode:set(false)

	if not _G.TheNet:IsDedicated() then
		inst:ListenForEvent("dealing_mode_dirty",function(inst)
			if inst.dealing_mode:value() == true then
				OnStartChanneling_Client(inst, false) -- false means dealing
			else
				OnStopChanneling_Client(inst, false) -- false means dealing
			end
		end)
	end
------------------------------------------------------------------------------------------------------------------------------------
	inst.isplayer_dealing = _G.net_bool(inst.GUID, "livestaff.isplayer_dealing", "isplayer_dealing_dirty") -- is caster doing dealing mode & enemy got dealing
	inst.isplayer_dealing:set(false)

	inst:ListenForEvent("isplayer_dealing_dirty", function(inst)
		if inst.isplayer_dealing:value() == true then  -- change reticule(circle) color to green (dealing targets deteted)
			inst.components.reticule.validcolour = {139/255, 0, 1, .6}
			inst.components.reticule.invalidcolour = {139/255, 0, 1, .6}
		else                                          -- change reticule(circle) color to red (no dealing targets)
			inst.components.reticule.validcolour = {0.5, 0.5, 0.5, .6}
			inst.components.reticule.invalidcolour = {0.5, 0.5, 0.5, .6}
		end
	end)
------------------------------------------------------------------------------------------------------------------------------------
	inst.healing_recharge = _G.net_float(inst.GUID, "livestaff.healing_recharge", "healing_recharge_dirty")  -- heal gauge
	inst.healing_recharge:set(1) --- 1 is full

	inst:ListenForEvent("healing_recharge_dirty", function(inst)
		if inst.staff_mode:value() == true then -- true means healing mode
			inst:PushEvent("forcerechargechange", {percent = inst.healing_recharge:value(), overtime = false}) -- change weapon's recharge view (inst.healing_recharge:value() == 1 == 100%)
		end
	end)
------------------------------------------------------------------------------------------------------------------------------------
	inst.dealing_recharge = _G.net_float(inst.GUID, "livestaff.dealing_recharge", "dealing_recharge_dirty")  -- dealing gauge
	inst.dealing_recharge:set(1) --- 1 is full  

	inst:ListenForEvent("dealing_recharge_dirty", function(inst)
		if inst.staff_mode:value() == false then -- false means dealing mode
			inst:PushEvent("forcerechargechange", {percent = inst.dealing_recharge:value(), overtime = false}) -- change weapon's recharge view (inst.dealing_recharge:value() == 1 == 100%)
		end
	end)
	------------------------------------------
	inst:AddTag("channelhealing")
	inst:AddTag("allow_action_on_impassable")
	inst:AddTag("weapon")
	------------------------------------------
	inst:AddComponent("reticule")
	inst.components.reticule.targetfn = ReticuleTargetFn
	inst.components.reticule.reticuleprefab = "reticuleaoe"
	inst.components.reticule.validcolour = {0.5, 0.5, 0.5, .6}
	inst.components.reticule.invalidcolour = {0.5, 0.5, 0.5, .6}
	inst.components.reticule.mouseenabled = false
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	COMMON_FNS.EQUIPMENT.WeaponInit(inst, weapon_values, tuning_values)
	------------------------------------------
	COMMON_FNS.EQUIPMENT.ItemTypeInit(inst, tuning_values.ITEM_TYPE)
	------------------------------------------
	inst:AddComponent("inspectable")
	------------------------------------------
	COMMON_FNS.EQUIPMENT.InventoryItemInit(inst, weapon_values.image_name or "healingstaff")
	------------------------------------------
	local function WeaponOnEquip(inst, owner)
		if weapon_values.onequip_fn then
			weapon_values.onequip_fn(inst, owner)
		end
		inst.components.weapon:UpdateAltAttackRange(nil, nil, owner)
	end
	local function WeaponOnUnequip(inst, owner)
		if weapon_values.onunequip_fn then
			weapon_values.onunequip_fn(inst, owner)
		end
		inst.components.weapon:UpdateAltAttackRange(nil, nil, owner)
	end
	COMMON_FNS.EQUIPMENT.EquippableInit(inst, weapon_values.type or "hand", weapon_values.onequip_fn, weapon_values.onunequip_fn, unpack(weapon_values.swap_strings))
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	inst:AddComponent("rechargeable")
	inst:AddTag("rechargeable")

	inst.components.rechargeable:SetMaxStack(1)
	------------------------------------------
	inst:AddComponent("channelcastable")
	inst.components.channelcastable:SetOnStartChannelingFn(OnStartChanneling)
	inst.components.channelcastable:SetOnStopChannelingFn(OnStopChanneling)

	inst:AddComponent("customcomponent")
	------------------------------------------
    inst.castsound = "dontstarve/common/lava_arena/spell/heal" -- TODO move into sound table?

	inst.heal_rate = 1 -- per 0.5 sec
	inst.deal_rate = 1 -- per 0.5 sec
	inst.recharge_rate = 1 -- make sure similar as heal_rate,deal_rate

	inst.heal_fn = HealingPlayers
	inst.deal_fn = DealingEnemies
	inst.owner = nil
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
return ForgePrefab("livestaff", fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, nil, "images/inventoryimages.xml", "healingstaff.tex", "swap_healingstaff", "common_hand")
