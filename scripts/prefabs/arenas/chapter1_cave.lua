local TileManager = require "tilemanager"
local GroundTiles = require "worldtiledefs"
local assets = { -- TODO which assets are needed? add to common fns?
    Asset("SCRIPT", "scripts/prefabs/world.lua"),

}
local prefabs = {
    "grotto_waterfall_big",
    "lavaarena_portal",
    "lavaarena_groundtargetblocker",
    "lavaarena_center",
    "lavaarena_spawner",

    "wave_shimmer",
    "wave_shore",
    "lantern",
    "backpack",
    "slurtle",
    "firepit",
    "flower_cave",
    "skeleton",
    "cavelight",
    "cavelight_small",
    "cavelight_tiny",
    "grotto_waterfall_small1",
    "grotto_waterfall_small2",
    
}
--------------------------------------------------------------------------
local map_values = {
    name = "chapter1_cave",
    colour_cube  = "images/colour_cubes/snow_cc.tex",
    sample_style = MAP_SAMPLE_STYLE.NINE_SAMPLE,
    ambient_lighting = {100/255, 100/255, 100/255},
}
--------------------------------------------------------------------------
local function common_preinit(inst)
    COMMON_FNS.MapPreInit(inst, map_values)

    
end
--------------------------------------------------------------------------
local function common_postinit(inst)
    COMMON_FNS.MapPostInit(inst, map_values)
--------------------------------------------------------------------------
    TheWorld:PushEvent("overrideambientlighting", Point(0, 0, 0))
	TheWorld:PushEvent("overridecolourcube", "images/colour_cubes/snow_cc.tex")
--------------------------------------------------------------------------
    -----CAVE----

    inst.components.ambientsound:SetReverbPreset("cave")
    inst.components.ambientsound:SetWavesEnabled(false)
--------------------------------------------------------------------------
    local map = TheWorld.Map 
    local tuning = TUNING.OCEAN_SHADER 

    TheWorld.Dunguen_Names = "chapter1_cave"
    
    map:SetOceanEnabled(true) 
    map:SetOceanTextureBlurParameters(tuning.TEXTURE_BLUR_PASS_SIZE, tuning.TEXTURE_BLUR_PASS_COUNT) 
    map:SetOceanNoiseParameters0(tuning.NOISE[1].ANGLE, tuning.NOISE[1].SPEED, tuning.NOISE[1].SCALE, tuning.NOISE[1].FREQUENCY) 
    map:SetOceanNoiseParameters1(tuning.NOISE[2].ANGLE, tuning.NOISE[2].SPEED, tuning.NOISE[2].SCALE, tuning.NOISE[2].FREQUENCY) 
    map:SetOceanNoiseParameters2(tuning.NOISE[3].ANGLE, tuning.NOISE[3].SPEED, tuning.NOISE[3].SCALE, tuning.NOISE[3].FREQUENCY)
--------------------------------------------------------------------------  
    mod_protect_TileManager = true
    inst:AddComponent("wavemanager")
    inst.Map:SetTransparentOcean(true)
--------------------------------------------------------------------------  
    if not TheNet:IsDedicated() then
        print("OCEAN COLOR UPDATING")
        inst.Map:DoOceanRender(true)
    end
end
--------------------------------------------------------------------------
local function master_postinit(inst)
    COMMON_FNS.MapMasterPostInit(inst)
--------------------------------------------------------------------------
    TheWorld:PushEvent("overrideambientlighting", Point(0, 0, 0))
end
--------------------------------------------------------------------------
local function fn()
    local inst = COMMON_FNS.NetworkInit()
    ------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    ------------------------------------------
    return inst
end
--------------------------------------------------------------------------
return MakeWorld(map_values.name, prefabs, assets, common_postinit, master_postinit, { "lavaarena" }, {common_preinit = common_preinit}), Prefab(map_values.name .. "_network", fn)