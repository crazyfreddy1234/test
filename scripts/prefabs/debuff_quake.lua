local assets = {}
local prefabs = {}
local MAX_LEVEL = 5
local DAMAGE_RECEIVED_MULT_DEBUFF = 1.2
local QUAKE_DAMAGE = 25
--------------------------------------------------------------------------
local function DecreasePlayerHealth(player, amount) 
    if player and player.components.health and not player.components.health:IsDead() then
        player.components.health:DoDelta(-amount)
    end
end

local function SpawnQuakeFx(player)
    local x, y, z = player.Transform:GetWorldPosition()
    local quake_fx = SpawnPrefab("groundpound_fx")

    quake_fx.Transform:SetPosition(x, y, z)
end

local function OnAttached(inst, target)
    print(target)
    DecreasePlayerHealth(target, QUAKE_DAMAGE)
    SpawnQuakeFx(target)
end

local function OnExtended(inst, target)
    DecreasePlayerHealth(target, QUAKE_DAMAGE)
    SpawnQuakeFx(target)
end

local function OnDetached(inst, target)
    inst:Remove()
end
--------------------------------------------------------------------------
local function fn(inst)
    local inst = COMMON_FNS.BasicEntityInit(nil, nil, nil, {anim_loop = false})
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetDetachedFn(OnDetached)
    inst.components.debuff:SetExtendedFn(OnExtended)

    inst.components.debuff:SetMaxStack(10)
    ------------------------------------------
    inst.duration = 20 -- in seconds
    inst.shield_mult = 0.8
    inst.SetDuration = function(inst, duration)
        inst.duration = duration or inst.duration
    end
    ------------------------------------------
    return inst
end

return Prefab("debuff_quake", fn)
