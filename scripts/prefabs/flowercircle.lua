local FRAME = 1/1000

local function GiveBuffToTargets(inst, targets, flower_type, caster, is_buff, is_impact)
    for _,target in pairs(targets) do
        local debuffable = target.components.debuffable
        if debuffable and debuffable:IsEnabled() then
            local name = "debuff_flower_" .. (flower_type or "regen")
            debuffable:AddDebuff(name, "debuff_flower")
            local debuff_flower = debuffable:GetDebuff(name)
            if debuff_flower then
                debuff_flower:SetCaster(caster)
                debuff_flower:SetFlowerType(flower_type)
                debuff_flower:SetIsBuff(is_buff)
                debuff_flower:SetMult(is_impact and 1 or TUNING.FORGE.SPICE_BOMB.LINGERING_MULT)
                debuff_flower:SetSource(inst)
            end
            inst.targets[target] = target
        end
    end
end

local function RegenTargets(inst, targets, flower_type, caster, is_buff, is_impact)
    for _,target in pairs(targets) do
		if target.issleep == nil then
			target.issleep = false
		end
		if target.CANSTACK == nil then
			target.CANSTACK = true
		end

		if target.issleep == true then return end
		
		if target and target.components and target.components.grogginess and target.CANSTACK and flower_type == "regen" then
			target.components.grogginess:AddGrogginess(0.35, 5)
			target.CANSTACK = false
			if target.sg:HasStateTag("knockout") then 
				target.issleep = true
			end
			target:DoTaskInTime(0.1,function()
				target.CANSTACK = true
			end)
		end
    end
end

local function ApplyFlowerBuffs(inst, weapon, flower_type, caster, flower_pos, radius, damage, excluded_targets, is_alt, is_impact)
    GiveBuffToTargets(inst, COMMON_FNS.EQUIPMENT.GetAOETargets(caster, flower_pos, radius, {"player"}, {"noplayerindicator"}, nil, inst.targets, nil, true), flower_type, caster, true, is_impact)
	RegenTargets(inst, COMMON_FNS.EQUIPMENT.GetAOETargets(caster, flower_pos, radius, {"player"}, {"noplayerindicator"}, nil, nil, nil, true), flower_type, caster, true, is_impact)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    --[[Non-networked entity]]

	inst.SetBuilds = net_string(inst.GUID, "SetBuilds", "setbuildsdirty")
    ------------------------------------------
    inst:AddTag("CLASSIFIED")
    ------------------------------------------
	inst.blooms = {}
	inst.caster = nil
	------------------------------------------
    --MakeLargeBurnable(inst, 5) -- TODO change fx have large in mid, surrounded by medium and then outside is small
	MakeLargeBurnableCharacter(inst)
    --MakeLargePropagator(inst)
    ------------------------------------------
	inst:DoTaskInTime(1.5, function(inst)
		for _,v in pairs(inst.blooms) do
			if v.Kill ~= nil then v:Kill(true) end
		end
		inst:Remove()
	end)
	------------------------------------------
	function inst:SpawnBlooms()
		local center = inst:GetPosition()
		local inner_blooms = 0
		local outer_blooms = math.random(3,4)
		local max_blooms = 1 + inner_blooms + outer_blooms
		local random = math.random()
		for i = 1,max_blooms do
			local pt = inst:GetPosition()
			-- Inner and Outer Bloom Offset
			if i > 1 then
				local theta = ((i > (1 + inner_blooms) and (i-inner_blooms)/outer_blooms or (i-1)/inner_blooms) + random) * 2 * PI
				local radius = 3/(i > (1 + inner_blooms) and 1 or 2)
				local offset = FindWalkableOffset(pt, theta, radius, 2, true, true)
				if offset then
					pt = pt + offset
				else
					pt = nil 
				end
			end
			if pt then
				inst:DoTaskInTime(0, function()
					local bloom = COMMON_FNS.CreateFX("flowercircle_bloom", nil, inst.caster)
					bloom.Transform:SetPosition(pt:Get())
					bloom.buffed = inst.buffed
					if inst.SetBuilds:value() ~= nil then
						bloom.AnimState:SetBuild(inst.SetBuilds:value() .. "_flower_fx")
					else
						bloom.AnimState:SetBuild("regen_flower_fx")
					end
					table.insert(inst.blooms, bloom)
				end)
			end
		end
        --inst.components.burnable:Ignite()
	end
	------------------------------------------
	function inst:SpawnCenter()
		local pt = inst:GetPosition()
		local center = COMMON_FNS.CreateFX("flowercircle_center", nil, inst.caster)
		center.Transform:SetPosition(pt.x, 0, pt.z)
		center:DoTaskInTime(TUNING.FORGE.LIVINGSTAFF.COOLDOWN/2, inst.Remove)
	end
	------------------------------------------
	inst:DoTaskInTime(0, inst.SpawnCenter)
	inst:DoTaskInTime(0, inst.SpawnBlooms)
	------------------------------------------
    return inst
end
--------------------------------------------------------------------------
local FADEIN_TIME = 13 * FRAMES
local FADEOUT_TIME = 44 * FRAMES - FADEIN_TIME
local CLR = {0, 0.8, 0.55, 1}

local function PlayFlowerSound(inst)
	inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_lichen", "flower_summon")
    inst.SoundEmitter:SetVolume("flower_summon", .75)

    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/flowergrow", "flower_grow")
    inst.SoundEmitter:SetVolume("flower_grow", .65)

    inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds", "flower_sound")
    inst.SoundEmitter:SetVolume("flower_sound", .55)
	--inst.SoundEmitter:SetVolume("flower_sound", .25) --TODO: Leo - might need a volume check, leaving this comment here for reference of what it was before.
end

local function Start(inst)
	PlayFlowerSound(inst)

	inst.AnimState:PlayAnimation("in_"..inst.variation)
	inst.AnimState:PushAnimation("out_"..inst.variation, false)

	if inst.buffed then
		inst.components.scaler:SetBaseScale(1 + (math.random(unpack(TUNING.FORGE.LIVINGSTAFF.SCALE_RNG)) + math.random())/100)
		inst.components.scaler:ApplyScale()
		--inst.AnimState:ShowSymbol("drop")
	end

	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	DoColourBlooming(inst, FADEIN_TIME, FADEOUT_TIME, CLR, false, nil, function(inst)
		inst.AnimState:ClearBloomEffectHandle()
	end)
end

local function Kill(inst, withdelay)
	local function fn(inst)
		PlayFlowerSound(inst)
		inst:ListenForEvent("animover", function(inst)
			if not inst.AnimState:IsCurrentAnimation("out_"..inst.variation) then
				inst.AnimState:PlayAnimation("out_"..inst.variation)
			else
				inst:Remove()
			end
		end)
	end

	local delay = withdelay and math.random() or 0
	if delay > 0 then
		inst:DoTaskInTime(delay, fn)
	else
		fn(inst)
	end
end
--------------------------------------------------------------------------
local function bloom_fn()
	local inst = COMMON_FNS.FXEntityInit("lavaarena_heal_flowers", "def_flower_fx", nil, {noanimover = true, noanim = true, pristine_fn = function(inst)
	    inst.entity:AddSoundEmitter()
		inst.AnimState:SetScale(1.5,1.5,1.5)
		inst.AnimState:SetLightOverride(1)
	end})
	------------------------------------------
	if not TheWorld.ismastersim then
		return inst
	end
	------------------------------------------
	inst.variation = tostring(math.random(1, 6))
	------------------------------------------
	inst:AddComponent("colouradder")
	------------------------------------------
	inst.Start  = Start
	inst.Kill   = Kill
	inst.OnSave = inst.Remove
	------------------------------------------
	inst:DoTaskInTime(0, inst.Start)
	------------------------------------------
	return inst
end
--------------------------------------------------------------------------
local function center_fn()
	local inst = COMMON_FNS.FXEntityInit("lavaarena_heal_flowers", "dmg_flower_fx", nil, {noanimover = true, noanim = true, pristine_fn = function(inst)
		inst.AnimState:SetMultColour(0,0,0,0)
		--inst:Hide()
		------------------------------------------
		inst:AddTag("flowercircle")
	end})
	------------------------------------------
	if not TheWorld.ismastersim then
		return inst
	end
	------------------------------------------
	inst.variation = tostring(math.random(1, 6))
	inst.AnimState:PlayAnimation("in_"..inst.variation)
	inst.AnimState:PushAnimation("idle_"..inst.variation)
	------------------------------------------
	inst:DoTaskInTime(12, inst.Remove)
	------------------------------------------
	return inst
end

local function floweraoefn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    --[[Non-networked entity]]
    ------------------------------------------
    inst.persists = false
    inst:AddTag("CLASSIFIED")
    ------------------------------------------
    inst.entity:SetCanSleep(false)
    ------------------------------------------
    inst:AddComponent("updatelooper")
    ------------------------------------------
    inst.ApplyBuffs = function(inst, weapon, flower_type, attacker, damage, impact_time, lingering_time, alt_radius)
        local function Apply(inst)
            ApplyFlowerBuffs(inst, weapon, flower_type, attacker, inst:GetPosition(), alt_radius, damage, nil, true, true)
        end

        inst.targets = {}
        inst.components.updatelooper:AddOnUpdateFn(Apply)
        inst.buffs_task = inst:DoTaskInTime((impact_time and impact_time or 1) + (lingering_time and lingering_time or 0), function(inst)
            inst.components.updatelooper:RemoveOnUpdateFn(Apply)
            inst:Remove()
        end)
    end
    ------------------------------------------
    return inst
end
--------------------------------------------------------------------------
return Prefab("flowercircle", fn, nil, prefabs),
	Prefab("flowercircle_bloom", bloom_fn, nil, nil),
	Prefab("flowercircle_center", center_fn, nil, nil),
	Prefab("flower_aoe", floweraoefn)

	