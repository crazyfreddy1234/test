local assets = {
    Asset("ANIM", "anim/sleepcloud.zip"),
}
local prefabs = {}
local tuning_values = TUNING.FORGE.SPICE_BOMB
local Inf_BloodOver = require "widgets/inf_bloodover"
local FumeOver_Red = require "widgets/fumeover_red"

local flower_colors = {
    dmg     = {1,0,0,1},
    def     = {0,0,1,1},
    regen   = {0,1,0,1},
    speed   = {1,1,1,1},
    unhit   = {1,0,1,1},
}
------------------------------------------------------------------------------
--[[
local function ChangeMouseTargetFn(length) --def
    return function (inst, mousepos)
		if mousepos ~= nil then
			local x, y, z = inst.Transform:GetWorldPosition()
			local dx = -mousepos.x + x
			local dz = -mousepos.z + z
			local l = dx * dx + dz * dz
			if l <= 0 then
				return inst.components.reticule.targetpos
			end
			l = length / math.sqrt(l) * (ThePlayer.replica.scaler and ThePlayer.replica.scaler:GetScale() or 1)
			return Vector3(x + dx * l, 0, z + dz * l)
		end
	end
end

local function ChangeMouseTargetToNormalFn(length) --def
    return function (inst, mousepos)
		if mousepos ~= nil then
			local x, y, z = inst.Transform:GetWorldPosition()
			local dx = mousepos.x - x
			local dz = mousepos.z - z
			local l = dx * dx + dz * dz
			if l <= 0 then
				return inst.components.reticule.targetpos
			end
			l = length / math.sqrt(l) * (ThePlayer.replica.scaler and ThePlayer.replica.scaler:GetScale() or 1)
			return Vector3(x + dx * l, 0, z + dz * l)
		end
	end
end

local function abcd(inst,data) --def
    inst.components.aoetargeting.reticule.mousetargetfn = ChangeMouseTargetToNormalFn(6.5)
    inst:RemoveEventCallback("unequipped",abcd)
end

local function UpdateTargetsInventoryPos(target,data) --def
	target.components.inventory:ForEachItem(function(item)
		if item.components.aoetargeting and target:HasTag("debuff_flower_def") then
			item.components.aoetargeting.reticule.mousetargetfn = ChangeMouseTargetFn(6.5)
            target.components.playercontroller:RefreshReticule()
            item:ListenForEvent("unequipped",abcd)
        elseif item.components.aoetargeting and not target:HasTag("debuff_flower_def") then
            item.components.aoetargeting.reticule.mousetargetfn = ChangeMouseTargetToNormalFn(6.5)
            target.components.playercontroller:RefreshReticule()
            item.components.aoetargeting:SetEnabled(true)
		end
	end)
end

local function ChangeController(target,is_change) --def

    local oldUP          = CONTROL_MOVE_UP
    local oldDOWN        = CONTROL_MOVE_DOWN
    local oldLEFT        = CONTROL_MOVE_LEFT
    local oldRIGHT       = CONTROL_MOVE_RIGHT
    local oldROTATELEFT  = CONTROL_ROTATE_LEFT
    local oldROTATERIGHT = CONTROL_ROTATE_RIGHT

    CONTROL_MOVE_UP      = oldDOWN
    CONTROL_MOVE_DOWN    = oldUP
    CONTROL_MOVE_LEFT    = oldRIGHT
    CONTROL_MOVE_RIGHT   = oldLEFT
    CONTROL_ROTATE_LEFT  = oldROTATERIGHT
    CONTROL_ROTATE_RIGHT = oldROTATELEFT
    
    if is_change then
        if target.components.locomotor.runspeed > 0 then
            target.components.locomotor.runspeed = target.components.locomotor.runspeed * -1
        end
    else 
        if target.components.locomotor.runspeed < 0 then
            target.components.locomotor.runspeed = target.components.locomotor.runspeed * -1
        end
    end
    
end
]]--
local MIN_ATTACK_TIME = 1

local function IncreaseDamagePercent(target, inst) --dmg
    if target.readytodamage ~= true then return end

    local current_time = _G.GetTime()
    local targetmaxhealth = target.components.health.maxhealth or 150

    if (not target.components.combat.lastdoattacktime or current_time - target.components.combat.lastdoattacktime > MIN_ATTACK_TIME) 
        and #_G.TheWorld.components.forgemobtracker:GetAllLiveMobs() > 0 then
            inst.DAMAGE_PERCENT = 5
            target.FumeOver_RedEnable:set(true)
    else 
        inst.DAMAGE_PERCENT = 0
        target.FumeOver_RedEnable:set(false)
    end

    target.components.health:DoDelta(-((targetmaxhealth/100)*inst.DAMAGE_PERCENT), false, "enthusiasm", nil, nil)
end

local function DamagedSlowly(inst, target) --dmg
    inst.DAMAGE_PERCENT = 0
    target.readytodamage = true
    target:DoTaskInTime(0,function()
        _G.RemoveTask(target.dmg_task)
        target.dmg_task = target:DoPeriodicTask(1, IncreaseDamagePercent, nil, inst)
    end)
end

local function RemoveDamagedSlowly(inst, target) --dmg
    inst.DAMAGE_PERCENT = nil
    target.readytodamage = nil
    if target.dmg_task then
        _G.RemoveTask(target.dmg_task)
        target.dmg_task = nil
    end
end

local function StopDamage(inst, data)    
    if data.damageresolved <= 0 or inst.readytodamage ~= true then return end

    inst.readytodamage = false
    inst:DoTaskInTime(2,function()
        inst.readytodamage = true
    end)
end

local function SpeedRecalculateRate(handitem)
    local weapon = handitem.components.rechargeable
    if weapon.owner ~= nil and weapon.is_timer then
        weapon.cooldownrate = weapon.owner.components.buffable and weapon.owner.components.buffable:ApplyStatBuffs({"cooldown"}, 1) or 1
        if weapon.updatetask ~= nil then
            weapon.inst.replica.inventoryitem:SetChargeTime((weapon.pickup and weapon.pickup_cooldown) or weapon.maxrechargetime * weapon.cooldownrate)
        end
    end
end

local function UpdateTargetsInventoryCooldowns(target,isAdd) --speed
    local handitem = target.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    local bodyitem = target.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    local headitem = target.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)

    --[[
    if handitem.prefab == "riledlucy" and isAdd then
        handitem.components.rechargeable:SetRechargeTime(6)
    end
    ]]--
    if bodyitem and bodyitem.components.rechargeable then
        bodyitem.components.rechargeable:RecalculateRate()
    end
    if headitem and headitem.components.rechargeable then
        headitem.components.rechargeable:RecalculateRate()
    end

    if handitem and handitem.components.rechargeable then
        handitem:DoTaskInTime(FRAMES,function()
            if isAdd and handitem.components.rechargeable.pickup == true then
                --[[
                if handitem.components.rechargeable.updatetask ~= nil then 
                    handitem.components.rechargeable.pickup = false
                    handitem.components.rechargeable.updatetask:Cancel()
                    handitem.components.rechargeable.updatetask = nil
                end
                --]]
                --SpeedRecalculateRate(handitem)
                handitem.components.rechargeable:RecalculateRate()
                handitem.flower_cooldown = true
            elseif not isAdd and handitem.flower_cooldown == true then
                --[[
                if handitem.components.rechargeable.updatetask == nil then 
                    handitem.components.rechargeable.pickup = true
                    handitem.components.rechargeable:StartRecharge()
                end
                --]]
                --SpeedRecalculateRate(handitem)
                handitem.components.rechargeable:RecalculateRate()
                handitem.flower_cooldown = nil
            else
                handitem.components.rechargeable:RecalculateRate()
            end
        end)
    end  
end

local function DebuffEquip(inst, data)
    UpdateTargetsInventoryCooldowns(inst,true)
end

local function ChangeAlphaAllMobsAndPlayers(debuffer,alpha,shadow) --def
    --debuffer.components.transparent:SetAlpha(alpha)
    debuffer.MobsPlayersAlpha:set(alpha)
    debuffer.MobsPlayersShadowEnable:set(shadow)
end

local function HurtSelf(target, data) --unhit
    local OLD_HPS = target.HPS or 0
    target.HPS = GetTime()
    local damage = data.damageresolved * target.HPS -- 10% ~ 100%
    target.components.health:DoDelta(-damage, false, "patience", nil, nil)
end

local function StopShield(inst, target) --unhit
    if inst.OnBlock then
        inst:RemoveEventCallback("blocked", inst.OnBlock, inst.target)
    end
    target.components.combat:RemoveDamageBuff("unhit_shield", true)
    --if inst.OnAttacked then
     --   inst:RemoveEventCallback("attacked", inst.OnAttacked)
    --end
    --inst.hit_count = 0
    --target.components.health:SetAbsorptionAmount(0)
end

local function HalfReverseHeal(inst, data) --unhit
    local newhp = data.newpercent
    local oldhp = data.oldpercent
    local deltahp = newhp - oldhp

    if deltahp > 0 then
        inst.components.health:DoDelta(-((inst.components.health.maxhealth * deltahp) * 1.5),false,"enthusiasm",nil,nil,true)
    end
end

local function DropItemAndBlock(inst,data) --unhit
    local item = {}
    local headitem = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
    local bodyitem = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY) 
    local handitem = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    local attacker_pos = data.attacker and Vector3(data.attacker.Transform:GetWorldPosition()) or Vector3(0,0,0)
    local inst_pos = Vector3(inst.Transform:GetWorldPosition())
    local direction = attacker_pos - inst_pos
    if inst.isreadytodrop == nil then
        inst.isreadytodrop = true
    end
    if inst.isreadytodrop and not inst.sg:HasStateTag("nointerrupt")
        and inst.sg.currentstate.name ~= "combat_punch_pst"
        and not (inst.sg.currentstate.name == "combat_punch" and inst.sg:HasStateTag("aoe")) then

        local HEADORHAND = math.random()
        if headitem == nil and handitem == nil and bodyitem ~= nil 
            and (not inst.components.inventory.equipslots[EQUIPSLOTS.BODY].components.equippable.preventunequipping == true) then

                inst.components.inventory:DropItem(bodyitem, false, direction:GetNormalized())
        else
            if HEADORHAND <= 0.5 then 
                if headitem and (not inst.components.inventory.equipslots[EQUIPSLOTS.HEAD].components.equippable.preventunequipping == true) then
                    inst.components.inventory:DropItem(headitem, false, direction:GetNormalized()) 
                elseif handitem and (not inst.components.inventory.equipslots[EQUIPSLOTS.HANDS].components.equippable.preventunequipping == true) then
                    inst.components.inventory:DropItem(handitem, false, direction:GetNormalized()) 
                end
            else 
                if handitem and (not inst.components.inventory.equipslots[EQUIPSLOTS.HANDS].components.equippable.preventunequipping == true) then
                    inst.components.inventory:DropItem(handitem, false, direction:GetNormalized()) 
                elseif headitem and (not inst.components.inventory.equipslots[EQUIPSLOTS.HEAD].components.equippable.preventunequipping == true) then
                    inst.components.inventory:DropItem(headitem, false, direction:GetNormalized()) 
                end
            end
        end
        inst.isreadytodrop = false
    end
    if inst.isreadytodrop == false then
        inst:DoTaskInTime(1,function()
            inst.isreadytodrop = true
        end)
    end
end

local function DropAttackTool(inst, data) --unhit
    local tool = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

    if inst.isreadytodrop_attack == nil then
        inst.isreadytodrop_attack = true
    end
    if inst.isreadytodrop_attack_wait == nil then
        inst.isreadytodrop_attack_wait = true
    end

    if tool ~= nil and math.random() <= 0.8 and inst.isreadytodrop_attack == true 
        and inst.sg.currentstate.name ~= "combat_punch_pst"
        and not (inst.sg.currentstate.name == "combat_punch" and inst.sg:HasStateTag("aoe")) then

        local direction = Vector3(data.target.Transform:GetWorldPosition()) - Vector3(inst.Transform:GetWorldPosition()) or 0
        local projectile =
            data.weapon ~= nil and
            data.projectile == nil and
            (data.weapon.components.projectile ~= nil or data.weapon.components.complexprojectile ~= nil)

        if projectile and (not tool.prefab == "riledlucy") then 
            local num = data.weapon.components.stackable ~= nil and data.weapon.components.stackable:StackSize() or 1
            
            if num <= 1 then
                return
            end
            inst.components.inventory:Unequip(EQUIPSLOTS.HANDS, true)
            tool = data.weapon.components.stackable:Get(num - 1)
            tool.Transform:SetPosition(inst.Transform:GetWorldPosition())
            if tool.components.inventoryitem ~= nil then
                tool.components.inventoryitem:OnDropped(direction:GetNormalized())
            end
            inst.isreadytodrop_attack = false
        else 
            inst.components.inventory:Unequip(EQUIPSLOTS.HANDS, true)
            inst.components.inventory:DropItem(tool, false, direction:GetNormalized())
            inst.isreadytodrop_attack = false
        end

        if inst.isreadytodrop_attack == false and inst.isreadytodrop_attack_wait == true then
            inst.isreadytodrop_attack_wait = false
            inst:DoTaskInTime(4,function()
                inst.isreadytodrop_attack_wait = true
                inst.isreadytodrop_attack = true
            end)
        end

        --[[
        if tool.Physics ~= nil then
            local x, y, z = tool.Transform:GetWorldPosition()
            tool.Physics:Teleport(x, .3, z)

            local angle = (math.random() * 20 - 10) * DEGREES
            if data.target ~= nil and data.target:IsValid() then
                local x1, y1, z1 = inst.Transform:GetWorldPosition()
                x, y, z = data.target.Transform:GetWorldPosition()
                angle = angle + (
                    (x1 == x and z1 == z and math.random() * 2 * PI) or
                    (projectile and math.atan2(z - z1, x - x1)) or
                    math.atan2(z1 - z, x1 - x)
                )
            else
                angle = angle + math.random() * 2 * PI
            end
            local speed = projectile and 2 + math.random() or 3 + math.random() * 2
            tool.Physics:SetVel(math.cos(angle) * speed, 10, math.sin(angle) * speed)
        end
        ]]--
        --Lock out from picking up for a while?
        --V2C: no need, the stategraph goes into busy state
    end
end

local function OnTick(inst, target) --regen
    if not target.components.debuffable:HasDebuff("debuff_flower_regen") then
        target.components.health:RemoveRegen("debuff_flower")
        return
    end
    local current_time = GetTime()
    local current_tick_duration = current_time - inst.previous_tick_time
    inst.previous_tick_time = current_time
    if target.components.health and not target.components.health:IsDead() and not target:HasTag("playerghost") and target:IsValid() then
        local heal_value = inst.total_heal * inst.current_mult / inst.duration * current_tick_duration
        local total_heal_value = heal_value
        if target.sg:HasStateTag("knockout") then 
            total_heal_value = heal_value * 2.5
        end
        if target.components.buffable then
            total_heal_value = target.components.buffable:ApplyStatBuffs({"heal_recieved"}, total_heal_value)
        end
        target.components.health:DoDelta(total_heal_value > 0 and total_heal_value or 0, true, "calmness", nil, nil, true)
        target.components.health:AddRegen(inst.prefab, (total_heal_value/(inst.tick_rate/FRAMES)) * 20)
    else
        inst.components.debuff:Stop()
    end
end

local function AddBuff(inst, target)
    inst.current_mult = inst.mult
    if inst.type == "dmg" then
        if target.components.locomotor and target.components.combat then
            local targetmaxhealth = target.components.health.maxhealth or 150

            target.components.combat:AddDamageBuff("flower_atk_buff", 1 + inst.buffs.attack * inst.current_mult)
            target.components.locomotor:SetExternalSpeedMultiplier(target, "flower_dmg_debuff", 0.9)
            --target.FumeOver_RedEnable:set(true)
            DamagedSlowly(inst, target)
            target:ListenForEvent("attacked", StopDamage)
        end
    elseif inst.type == "def" then
        if target.components.combat then
            target.components.combat:AddDamageBuff("flower_def_buff", 1 + inst.buffs.defense * inst.current_mult, true)  
            target.GoggleVisonEnable:set(true)
            target.FXSound_Volume:set(true)

            --target.components.transparent:ChangeSound(true)
            ChangeAlphaAllMobsAndPlayers(target,0,false)
        end
    elseif inst.type == "speed" then
        if target.components.locomotor and target.components.buffable and target.components.combat then
            target.components.locomotor:SetExternalSpeedMultiplier(target, "flower_speed_buff", 1 + inst.buffs.speed * inst.current_mult)
            target.components.buffable:AddBuff("flower_speedcooldown_debuff", {{name = "cooldown", val = 9999, type = "add"}})
            UpdateTargetsInventoryCooldowns(target,true)
            target:ListenForEvent("equip",DebuffEquip,target)
            target.components.combat:AddDamageBuff("flower_defense_debuff", {buff = 1.5}, true)

            if _G.REFORGED_SETTINGS.gameplay.map == "hf_eye_arena" then
                if inst._Speedlight == nil or not inst._Speedlight:IsValid() then
                    inst._Speedlight = SpawnPrefab("yellowamuletlight")
                end
                inst._Speedlight.entity:SetParent(target.entity)
            
                if target.components.bloomer ~= nil then
                    target.components.bloomer:PushBloom(inst, "shaders/anim.ksh", 1)
                else
                    target.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
                end
            end
        end
    elseif inst.type == "regen" then
        if target.components.grogginess and not target.components.health:IsDead() then
            inst.previous_tick_time = GetTime()
            inst.regen_task = inst:DoPeriodicTask(inst.tick_rate, OnTick, nil, target)
            inst.total_heal = ((target.components.health.maxhealth - target.components.health.currenthealth)/10)
        end
    else    --unhit 
        --target:ListenForEvent("onhitother", HurtSelf, target)
        target:ListenForEvent("onhitother", DropAttackTool, target)
        target:ListenForEvent("attacked",DropItemAndBlock)
        target.components.buffable:AddBuff("flower_unhitcooldown_buff", {{name = "cooldown", val = -0.25, type = "add"}})
--[[
        local function HitCount(target, data)
            inst.hit_count = inst.hit_count + 1 
            if inst.hit_count >= 2 then --get 2 hit then remove shield
                StopShield(inst,target)
            end
        end

        --inst.OnAttacked = HitCount
        --inst.oldabsorb = target.components.health.absorb or 0
        --target:ListenForEvent("attacked", inst.OnAttacked, target)
        --target:ListenForEvent("healthdelta", HalfReverseHeal)
        --target.components.health:SetAbsorptionAmount(1)

        local function OnBlock(target, data)
            inst.hit_count = inst.hit_count + 1
            if inst.hit_count >= 2 then
                StopShield(inst,target)
            end
        end
        inst.OnBlock = OnBlock
        inst:ListenForEvent("attacked", inst.OnBlock, target)
        target.components.combat:AddDamageBuff("unhit_shield", 0.01,true)
     ]]--
    end
end

local function OnAttached(inst, target)
    inst:DoTaskInTime(0, function()
        inst.target = target
        inst.entity:SetParent(target.entity)
        inst:ListenForEvent("death", function()
            inst.components.debuff:Stop()
        end, target)

        AddBuff(inst, target)

        target["flower_debuff_" .. tostring(inst.type) .. "_timer"] = target:DoTaskInTime(inst.duration, function()
            inst.components.debuff:Stop()
        end)
    end)
end

local function RemoveBuff(inst, target, type)
    if type == "dmg" then
        if target.components.combat then
            target.components.combat:RemoveDamageBuff("flower_atk_buff")
            target.components.locomotor:RemoveExternalSpeedMultiplier(target, "flower_dmg_debuff")
            target.FumeOver_RedEnable:set(false)
            RemoveDamagedSlowly(inst, target)
        end
    elseif type == "def" then
        if target.components.combat then
            target.components.combat:RemoveDamageBuff("flower_def_buff", true)
            target.GoggleVisonEnable:set(false)
            target.FXSound_Volume:set(false)
            --target.components.transparent:ChangeSound(false)
            ChangeAlphaAllMobsAndPlayers(target,1,true)
        end
    elseif type == "speed" then
        if target.components.locomotor and target.components.buffable and target.components.combat then
            target.components.locomotor:RemoveExternalSpeedMultiplier(target, "flower_speed_buff")
            target.components.buffable:RemoveBuff("flower_speedcooldown_debuff")
            target.components.combat:RemoveDamageBuff("flower_defense_debuff",true)
            target:AddTag("speed_flower_removed")
            target:DoTaskInTime(5*FRAMES,function()
                if target:HasTag("speed_flower_removed") then
                    target:RemoveTag("speed_flower_removed")
                end
            end)
            UpdateTargetsInventoryCooldowns(target,false)
            target:RemoveEventCallback("equip",DebuffEquip,target)

            if target.components.bloomer ~= nil then
                target.components.bloomer:PopBloom(inst)
            else
                target.AnimState:ClearBloomEffectHandle()
            end

            if inst._Speedlight ~= nil then
                if inst._Speedlight:IsValid() then
                    inst._Speedlight:Remove()
                end
                inst._Speedlight = nil
            end
        end
    elseif type == "regen" and inst.regen_task then
        inst.regen_task = inst:DoPeriodicTask(inst.tick_rate, OnTick, nil, target)
        if target.components.grogginess:HasGrogginess() then
            target.components.grogginess:ResetGrogginess()
        end
        if target.issleep ~= nil then
            target.issleep = nil
        end
    elseif type == "unhit" then
        target.components.buffable:RemoveBuff("flower_unhitcooldown_buff")
        target:RemoveEventCallback("attacked",DropItemAndBlock)
        --target:RemoveEventCallback("onhitother", HurtSelf, target)
        target:RemoveEventCallback("onhitother", DropAttackTool)
        --StopShield(inst, target)
        --target:RemoveEventCallback("healthdelta", HalfReverseHeal)
    end
end

local function OnExtended(inst, target)
    inst:DoTaskInTime(0, function()
        if inst.previous_type ~= inst.type or inst.was_buff ~= inst.is_buff or inst.type == "regen" and not inst.is_buff then
            RemoveBuff(inst, target, inst.previous_type)
            AddBuff(inst, target)
        end

       target["flower_debuff_" .. tostring(inst.type) .. "_timer"] = target:DoTaskInTime(inst.duration, function()
            inst.components.debuff:Stop()
        end)
    end)
end

local function OnDetached(inst, target)
    RemoveBuff(inst, target, inst.type)
    RemoveTask(target.flower_debuff_timer)
    inst.AnimState:PlayAnimation("sleepcloud_overlay_pst")
    if inst.source then
        inst.source.targets[target] = nil
    end
end
-----------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.BasicEntityInit("sleepcloud", nil, "sleepcloud_overlay_pre", {anim_loop = false, pristine_fn = function(inst)
        inst.AnimState:SetFinalOffset(2)
        ------------------------------------------
        inst.Transform:SetScale(0.5,0.5,0.5)
        ------------------------------------------
        COMMON_FNS.AddTags(inst, "FX", "NOCLICK")
    end})
	------------------------------------------
	if not TheWorld.ismastersim then
		return inst
	end
    ------------------------------------------
    inst.source = nil
    inst.duration = tuning_values.DURATION
    inst.buffs = {
        attack  = 0.25, --1.25,
        defense = -0.25,--0.75,
        regen   = 20,
        speed   = 0.25, --1.25,
    }
    inst.debuffs = {
        attack  = 0.5,--0.5,
        defense = true,--1.1,
        sleep   = 5,
        speed   = -0.5,--0.9,
    }
    inst.tick_rate = 4*FRAMES--0.1 -- of a second (for acid)
    inst.cause = "flower_regen"
    inst.total_heal = inst.buffs.regen
    inst.SetCaster = function(inst, caster)
        if caster == nil then return end
        inst.caster = caster
    end
    inst.is_buff = true
    inst.SetIsBuff = function(inst, is_buff)
        inst.was_buff = inst.is_buff
        inst.is_buff = is_buff
    end
    inst.type = "regen"
    inst.SetFlowerType = function(inst, type)
        inst.previous_type = inst.type
        inst.type = type
		inst:DoTaskInTime(0, function(inst)
			inst.AnimState:SetMultColour(unpack(flower_colors[type] or {0,1,0,0}))
		end)
    end
    inst.mult = 1
    inst.SetMult = function(inst, mult)
        inst.mult = mult or 1
    end
    inst.SetSource = function(inst, source)
        inst.source = source
    end
    inst.hit_count = 0 
    ------------------------------------------
	inst:AddComponent("debuff")
	inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetExtendedFn(OnExtended)
	inst.components.debuff:SetDetachedFn(OnDetached)
    ------------------------------------------
    inst:ListenForEvent("animover", function(inst)
        if not inst.AnimState:IsCurrentAnimation("sleepcloud_overlay_pst") then
            inst.AnimState:PlayAnimation("sleepcloud_overlay_loop")
        else
            inst:Remove()
        end
    end)
    ------------------------------------------
	return inst
end
------------------------------------------------------------------------------
return Prefab("debuff_flower", fn, assets, prefabs)
