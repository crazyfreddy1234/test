local assets = {}
local prefabs = {}

local DEFAULT_DURATION = 0
local DEFAULT_RANGE = 2



local function LinkMagicCircle(inst, magic_circle)
    inst.entity:SetParent(magic_circle.entity)
    inst.magic_circle = magic_circle
    --inst.Transform:SetPosition(magic_circle:GetPosition():Get())
    table.insert(magic_circle.spells, inst)
    inst:SetRange(magic_circle.range)
end

local function SetDuration(inst, duration)
    inst.duration = duration or inst.duration
end

local function SetRange(inst, range)
    inst.range = range or inst.range
end

local function SetCaster(inst, caster)
    inst.caster = caster
end

local function SetTarget(inst, target) -- TODO does this cause issues?
    if inst.target then
        inst.target:RemoveEventCallback("death", inst.EndSpell) -- TODO is this correct? does it need to pass inst as well?
    end
    inst.target = target
    --inst.Transform:SetPosition(target:GetPosition():Get())
    target:ListenForEvent("death", inst.EndSpell, inst)
end

local function GetSpellID(inst)
    return tostring(inst.prefab) .. "_" .. tostring(inst.GUID)
end

local function SetOptions(inst, options)
    --local data = data or {}
    for option,val in pairs(options or {}) do
        if inst.options[option] ~= nil then
            inst.options[option] = val
        end
    end
end




local function common_fn(start_spell_fn, end_spell_fn, set_val_fn)
    local inst = _G.COMMON_FNS.BasicEntityInit()
    ------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    inst.duration = DEFAULT_DURATION
    inst.range    = DEFAULT_RANGE
	------------------------------------------
	--[[
	inst.auratask = inst:DoPeriodicTask(0.2, function(inst)
		if inst.target and inst.target:IsValid() then
			local pos = inst.target:GetPosition()
			local fx = SpawnPrefab("hf_lifesteal_fx")
			if inst.colour then
				fx.AnimState:SetMultColour(inst.colour[1], inst.colour[2], inst.colour[3], 1)
			end
			fx.AnimState:SetScale(0.7, 0.7)
			fx.Transform:SetPosition(pos.x + (math.random(-2,2)), math.random(0, 2), pos.z + (math.random(-2,2)))
		end
	end)]]
    ------------------------------------------
    inst.GetSpellID      = GetSpellID
    inst.LinkMagicCircle = LinkMagicCircle
    inst.SetDuration     = SetDuration
    inst.SetRange        = SetRange
    inst.SetCaster       = SetCaster
    inst.SetTarget       = SetTarget
    inst.SetVal          = set_val_fn or SetOptions
    inst.CastSpell       = start_spell_fn
    inst.EndSpell = function(inst)
        if inst.target then
            inst.target:RemoveEventCallback("death", inst.EndSpell)
        end
        if end_spell_fn then
            end_spell_fn(inst)
        else
            inst.magic_circle:PushEvent("spell_complete", {spell = inst})
            inst:Remove()
        end
		if inst.auratask then
			inst.auratask:Cancel()
			inst.auratask = nil
		end
    end
    ------------------------------------------
    return inst
end

--------------------------------------------------------------------------
-- Upgraded Curse
--------------------------------------------------------------------------
-- AllPlayers takes a portion of damage that they inflict.
--------------------------------------------------------------------------
local function StopCurse(inst)
    inst.magic_circle:PushEvent("spell_complete", {spell = inst})
    inst:Remove()
end

local function StartCurse(inst, caster, target)
    inst:ListenForEvent("onhitother", function(target, data)
        local damage = inst.options.deals_flat_damage and inst.options.damage_dealt_flat or data.damageresolved * inst.options.damage_dealt_percent

        for player,_ (_G.AllPlayers) do
            if player:IsValid() and player.components.health then
                player.components.health:DoDelta(-damage, false, "spell_curse", false, inst.caster)
            end
        end

    end, target)
end
--------------------------------------------------------------------------
local function curse_fn()
    local inst = common_fn(StartCurse, StopCurse)
    ------------------------------------------
	inst.entity:SetPristine()
	
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    inst.options = {
        damage_dealt_percent = 0.05,
        damage_dealt_flat = 1,
        deals_flat_damage = false,
    }
    ------------------------------------------
    return inst
end

return Prefab("inforge_spell_upgraded_curse", curse_fn, assets),
