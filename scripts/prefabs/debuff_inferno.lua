local assets = {
    Asset("ANIM", "anim/fire_large_character.zip"),
    Asset("SOUND", "sound/common.fsb"),
}
local prefabs = {
    "firefx_light",
}
------------------------------------------------------------------------------
local firelevels = {
    {
    anim  = "loop_small",
    pre   = "pre_small",
    pst   = "post_small",
    sound = "dontstarve/common/campfire",
    radius    = 2,
    intensity = .6,
    falloff   = .7,
    colour    = {197/255,197/255,170/255},
    soundintensity = 1
    },{
    anim  = "loop_med",
    pre   = "pre_med",
    pst   = "post_med",
    sound = "dontstarve/common/treefire",
    radius    = 3,
    intensity = .75,
    falloff   = .5,
    colour    = {255/255,255/255,192/255},
    soundintensity = 1
    },{
    anim  = "loop_large",
    pre   = "pre_large",
    pst   = "post_large",
    sound = "dontstarve/common/forestfire",
    radius    = 4,
    intensity = .8,
    falloff   = .33,
    colour    = {197/255,197/255,170/255},
    soundintensity = 1
    },
}

local function OnTick(inst, target)
    if not target.components.debuffable:HasDebuff("debuff_inferno") then
        target.components.health:RemoveRegen("debuff_inferno")
        return
    end
    local current_time = GetTime()
    local current_tick_duration = current_time - inst.previous_tick_time
    inst.previous_tick_time = current_time
    if target.components.health and not target.components.health:IsDead() and not target:HasTag("playerghost") and target:IsValid() then
        local fire_dmg = -inst.damage * current_tick_duration--(inst.tick_rate - FRAMES)
        if target.components.buffable then -- Apply fire resistance
            fire_dmg = target.components.buffable:ApplyStatBuffs({"fire_resistance"}, fire_dmg)
        end
        target.components.health:DoDelta(fire_dmg < 0 and fire_dmg or 0, true, inst.cause, nil, nil, true)
        target.components.health:AddRegen(inst.prefab, (fire_dmg/(inst.tick_rate/FRAMES)) * 30) -- Calculate 1 seconds worth of damage
    else
        inst.components.debuff:Stop()
    end
end

local function UpdateFireState(inst, state)
    inst.fire_state:set_local(state)
    inst.fire_state:set(state)
end

local function OnAnimOver(inst)
    inst.components.debuff:Stop()
end

local function OnDetachedAnimOver(inst)
    inst.components.debuff:Stop()
    inst:Remove()
end

local function ResetTimer(inst, target)
    target.inferno_debuff_timer = target:DoTaskInTime(inst.duration, function()
        local has_anim = inst.components.firefx:Extinguish()
        if has_anim then
            UpdateFireState(inst, "stop")
            inst.has_anim_over = true
            inst:ListenForEvent("animover", OnAnimOver)
        else
            inst.components.debuff:Stop()
        end
    end)
end

local function OnAttached(inst, target)
    --inst.Transform:SetScale(target.Transform:GetScale())
    --inst.Transform:SetPosition(0,0,1)
    inst.current_level = 2 -- TODO adjust from 1 to 3 based on size
    inst:DoTaskInTime(0, function() -- Delay so level can be set
        inst.entity:SetParent(target.entity)
        -- Remove debuff when target dies
        inst:ListenForEvent("death", function()
            inst.components.debuff:Stop()
        end, target)
        ResetTimer(inst, target)
        inst.components.firefx:SetLevel(inst.current_level)--, immediate)
        inst.previous_tick_time = GetTime()
        inst.inferno_task = inst:DoPeriodicTask(inst.tick_rate, OnTick, nil, target) -- TODO low tick rate causes issues...hmmm
    end)
end

local function OnExtended(inst, target)
    if inst.has_anim_over then
        inst.has_anim_over = nil
        inst.components.firefx.level = nil
        inst.components.firefx:SetLevel(inst.current_level, true)
        UpdateFireState(inst, "high")
        inst:RemoveEventCallback("animover", OnAnimOver)
    end
    RemoveTask(target.inferno_debuff_timer)
    ResetTimer(inst, target)
end

local function OnDetached(inst, target)
    UpdateFireState(inst, "stop")
    RemoveTask(target.inferno_debuff_timer)
    RemoveTask(inst.inferno_task)
    target:DoTaskInTime(0, function()
        target.components.health:RemoveRegen("debuff_inferno")

        local has_anim = inst.components.firefx:Extinguish()
        if has_anim then
            UpdateFireState(inst, "stop")
            inst.has_anim_over = true
            inst:ListenForEvent("animover", OnDetachedAnimOver)
        else
            OnDetachedAnimOver(inst)
        end
    end)
end
-- ThePlayer.components.debuffable:AddDebuff("debuff_inferno", "debuff_inferno")
local function DoT_OnInit(inst)
    UpdateFireState(inst, "high")
end

local function OnDebuffFireDirty(inst)
    local parent = inst.entity:GetParent()
    if parent then
        local fire_state = inst.fire_state:value()
        if fire_state == "low" or fire_state == "high" then
            parent:PushEvent("startfiredamage", {low = fire_state == "low"})
        else
            parent:PushEvent("stopfiredamage")
        end
    end
end
------------------------------------------------------------------------------
local function fn()
	local inst = COMMON_FNS.BasicEntityInit("fire_large_character", nil, nil, {noanim = true, pristine_fn = function(inst)
        inst.entity:AddSoundEmitter()
        ------------------------------------------
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetRayTestOnBB(true)
        inst.AnimState:SetFinalOffset(-1)
        ------------------------------------------
        COMMON_FNS.AddTags(inst, "FX", "NOCLICK", "CLASSIFIED")
        ------------------------------------------
        inst.fire_state = net_string(inst.GUID, "debuff_inferno.fire_state", "debufffiredirty")
        ------------------------------------------
        --inst:DoTaskInTime(FRAMES, DoT_OnInit)
        ------------------------------------------
    	if not TheNet:IsDedicated() then
            --inst:ListenForEvent("debufffiredirty", OnDebuffFireDirty)
    	end
    end})
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    inst.source = nil
    inst.damage = 10               -- per sec
    inst.tick_rate = 4*FRAMES--0.1 -- of a second (for acid)
    inst.cause = "fire_dot"
    inst.duration = 9999
    inst.current_level = 1
    inst.SetCurrentLevel = function(inst, level)
        isnt.current_level = level
        inst.components.firefx:SetLevel(inst.current_level)--, immediate)
    end
    ------------------------------------------
	inst:AddComponent("debuff")
	inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetExtendedFn(OnExtended)
	inst.components.debuff:SetDetachedFn(OnDetached)
    ------------------------------------------
    inst:AddComponent("firefx")
    inst.components.firefx.levels = firelevels
    ------------------------------------------
	return inst
end
------------------------------------------------------------------------------
return Prefab("debuff_inferno", fn, assets, prefabs)

--[[
fx.entity:AddFollower()
fx.Follower:FollowSymbol(self.inst.GUID, v.follow, xoffs, yoffs, zoffs)
"torso" for players
anyway to get center part of ents? or a way to adjust to it?

arrow on health badge is not displaying
--]]
