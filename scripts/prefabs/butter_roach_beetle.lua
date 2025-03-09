
local assets = {
	Asset("ANIM", "anim/hf_roach_beetle.zip"),
	Asset("ANIM", "anim/butter_roach_beetle_build.zip"),
	Asset("ANIM", "anim/butter_roach_beetle_projectile.zip"),
}
local prefabs = {}
local tuning_values = TUNING.INFORGE.ROACH_BEETLE
local sound_path = "hf/creatures/roach_beetle/"
--------------------------------------------------------------------------
-- Physics Functions
--------------------------------------------------------------------------
local function PhysicsInit(inst)
	MakeCharacterPhysics(inst, 50, .5)
    inst.DynamicShadow:SetSize(1.75, 0.75)
	inst.Transform:SetScale(0.8, 0.8, 0.8)
    inst.Transform:SetFourFaced() --final build will be FourFaced
	inst.AnimState:OverrideMultColour(1, 1, 1, 1)
end
--------------------------------------------------------------------------
-- Physics Functions
--------------------------------------------------------------------------
local function PristineFN(inst)
	COMMON_FNS.AddTags(inst, "flippable")
end
--------------------------------------------------------------------------
local mob_values = {
	physics_init_fn = PhysicsInit,
	pristine_fn     = PristineFN,
	stategraph = "SGbutter_roach_beetle",
	brain = require("brains/butter_roach_beetlebrain"),
	sounds = {
		taunt    = sound_path .. "taunt",
		hit   	 = sound_path .. "hit",
		sleep_in = sound_path .. "sleep_in",
		sleep_out = sound_path .. "sleep_out",
		death	 = sound_path .. "death",
		idle = sound_path .. "idle",
		attack_pre = sound_path .. "attack",
		step	 = "dontstarve/creatures/spider/walk_spider",
		shell	 = "dontstarve/creatures/lava_arena/turtillus/shell_impact"
	},
}
--------------------------------------------------------------------------
local function common_fn()
	local inst = COMMON_FNS.CommonMobFN("roach_beetle", "butter_roach_beetle_build", mob_values, tuning_values)
	------------------------------------------
	if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	inst.components.health:SetAbsorptionAmount(1)
    ------------------------------------------
	COMMON_FNS.AddSymbolFollowers(inst, "swap_weapon", nil, "medium", {symbol = "body"}, {symbol = "body"})
	------------------------------------------
	inst.attacks = {}
	------------------------------------------
	inst.explode_remaining_time = 5
	----------------------------------------
	--[[
	local color_symbols = {"atenna","body","cheek","eye","head","mouth","shell"}

	for i=1,#color_symbols do
		local color = 0.25   --red
		inst.AnimState:SetSymbolHue(color_symbols[i],color) 
	end
	]]--
	------------------------------------------
	return inst 
end
--------------------------------------------------------------------------
local function Land(inst, pos)
	if inst.land_task then
		inst.land_task:Cancel()
		inst.land_task = nil
	end
	local event = TheWorld.components.lavaarenaevent
	local boss = COMMON_FNS.SpawnMob("butter_roach_beetle", pos, event and event.current_round, "mummy_curse", 0, false, inst.owner and inst.owner.duplicator_count)
	boss.Transform:SetPosition(pos.x, 0, pos.z)
	boss.sg:GoToState("land")
    boss.owner = inst.owner
	inst:Remove()
end

local function proj_fn()
	--This is just a barebones projectile whose sole purpose is to spawn the helmet when it "lands" on the ground.
	--TODO make this more flexible for other possible variants
    local inst = COMMON_FNS.BasicEntityInit("hf_roach_beetle_projectile", "butter_roach_beetle_projectile", "idle_loop", {pristine_fn = function(inst)
	    inst.Transform:SetTwoFaced()
		------------------------------------------
		inst.Transform:SetScale(0.8, 0.8, 0.8)
	end})
    ------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    inst.land_task = inst:DoPeriodicTask(0.1, function(inst) --iirc theres alternate methods that might be better suited for this. So far its at least serviceable.
		local pos = inst:GetPosition()
		if pos.y < 1 then
			Land(inst, pos)
		end
	end)
    ------------------------------------------
    return inst
end

return Prefab("hf_butter_roach_beetle_projectile", proj_fn, assets, prefabs),
ForgePrefab("butter_roach_beetle", common_fn, assets, prefabs, nil, tuning_values.ENTITY_TYPE, "HALLOWED_FORGE", "images/hallowedforge_icons.xml", "icon_roach_beetle.tex")
