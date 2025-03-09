local swineclops_sg = deepcopy(require "stategraphs/SGswineclops")
local tuning_values = TUNING.FORGE.SWINECLOPS

local function ShakePound(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, 0.5, .03, .5, inst, 30)
end

local function DoGroundPoundAOE(inst)
    COMMON_FNS.DoAOE(inst, nil, nil, {range = tuning_values.GROUNDPOUND_RANGE})
	COMMON_FNS.LaunchItems(inst, tuning_values.GROUNDPOUND_RANGE)
end

local function GroundPound(inst)
	ShakePound(inst)
	inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/bonehit2")
	inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/trails/bodyfall")
    inst.SoundEmitter:PlaySound(inst.sounds.hit_2)
    DoGroundPoundAOE(inst)
end

local function SpawnGeyser(inst, pos, should_loop)
    local geyser = SpawnPrefab("geyser")
    geyser.components.scaler:SetSource(inst)
    geyser.Transform:SetPosition(TheWorld.center.Transform:GetWorldPosition())
    geyser:Start(inst, should_loop)
    geyser:DoTaskInTime(2, function(inst)
        geyser:Stop()
    end) 
    return geyser
end

local function OnHitOther_Poison(inst, target)   
	target.components.debuffable:AddDebuff("scorpeon_dot", "scorpeon_dot")
end

local function OnHitOther_Knockback(inst, target)
    COMMON_FNS.KnockbackOnHit(inst, target, 5, 12)
end

local function OnHitOther_Fire(inst, target)
    target.components.debuffable:AddDebuff("debuff_fire", "debuff_fire")
end

local tantrum_count = 1
local tantrum_count_MAX = 3
local snortoise_army = {}
local random_turtle_number = 1

local idle_state = swineclops_sg.states.idle
local _oldOnEnter = idle_state.onenter
idle_state.onenter = function(inst, data)
    if inst.sg.mem.wants_to_spawntrutle then 
        inst.sg.mem.wants_to_spawntrutle = nil
        tantrum_count_MAX = 1
        inst.sg:GoToState("turtlespawn_tantrum")
    elseif inst.sg.mem.wants_to_spawnAlltrutle then
        inst.sg.mem.wants_to_spawnAlltrutle = nil
        tantrum_count_MAX = 3
        inst.sg:GoToState("turtlespawn_tantrum")
    else
        _oldOnEnter(inst, data)
    end
end

swineclops_sg.states["turtlespawn_tantrum"] = State{
    name = "turtlespawn_tantrum",
    tags = {"busy", "nointerrupt", "nofreeze"},

    onenter = function(inst, data)
        SpawnGeyser(inst)
        inst.Physics:Stop()
        inst.AnimState:PlayAnimation("taunt2")

        inst.sg:AddStateTag("nostun")
        inst.sg:AddStateTag("nosleep")
        inst.sg:AddStateTag("nointerrupt")
    end,

    onexit = function(inst)

    end,

    timeline = {
        TimeEvent(8*FRAMES, GroundPound),
        TimeEvent(11*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.hit_2)
        end),
        TimeEvent(14*FRAMES, GroundPound),
        TimeEvent(24*FRAMES, GroundPound),
    },

    events = {
        EventHandler("animover", function(inst)   
            
            local cutesnortoise = SpawnPrefab("snortoise")
            cutesnortoise:SetStateGraph("SGrandom_snortoise_poison")
            cutesnortoise.components.health:SetMaxHealth(900)
            
            if random_turtle_number == 1 then
                cutesnortoise.AnimState:SetBuild("acid_turtle")
                cutesnortoise.components.colouradder:PushColour("acid_coat", 0.1, 0.5, 0.1, 1)
                cutesnortoise.components.combat.onhitotherfn = OnHitOther_Poison
                random_turtle_number = random_turtle_number + 1
            elseif random_turtle_number == 2 then
                cutesnortoise.AnimState:SetBuild("kb_turtle")
                --[[
                cutesnortoise.AnimState:SetSymbolMultColour("leg",0.1,0.1,0.1,1)
                cutesnortoise.AnimState:SetSymbolMultColour("head",0.1,0.1,0.1,1)
                cutesnortoise.AnimState:SetSymbolMultColour("body",0.1,0.1,0.1,1)
                cutesnortoise.AnimState:SetSymbolMultColour("shell",0.1,0.1,0.1,1)
                cutesnortoise.AnimState:SetSymbolMultColour("mouth",0.1,0.1,0.1,1)
                cutesnortoise.AnimState:SetSymbolMultColour("eye",1,0,0,1)
                ]]--
                cutesnortoise.components.combat.onhitotherfn = OnHitOther_Knockback
                random_turtle_number = random_turtle_number + 1
            else 
                cutesnortoise.AnimState:SetBuild("lavaarena_turtillus_hardmode")
                cutesnortoise.components.combat.onhitotherfn = OnHitOther_Fire
                random_turtle_number = 1
            end

            
            cutesnortoise.Transform:SetPosition(TheWorld.center.Transform:GetWorldPosition())
            snortoise_army[tantrum_count] = cutesnortoise
            tantrum_count = tantrum_count + 1

            if tantrum_count > tantrum_count_MAX then
                for i=1,tantrum_count-1 do
                    snortoise_army[i].sg.mem.spin_attack = true
                    snortoise_army[i].sg:GoToState("idle")
                end

                inst.sg:GoToState("taunt")
                tantrum_count = 1
            else
                inst.sg:GoToState("turtlespawn_tantrum")
            end
        end),
    },
}

COMMON_FNS.ApplyStategraphPostInits(swineclops_sg)
return swineclops_sg
