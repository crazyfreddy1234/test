require("prefabs/world")
local TileManager = require "tilemanager"
local GroundTiles = require "worldtiledefs"
local assets = { -- TODO which assets are needed? add to common fns?

}
local prefabs = {
    "lavaarena_portal",
    "lavaarena_groundtargetblocker",
    "lavaarena_center",
    "lavaarena_spawner",

    "wave_shimmer",
    "wave_shore",
    "slurtle",
    "flower_cave",
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
    mod_protect_TileManager = false
    inst:AddComponent("wavemanager")
    inst.Map:SetTransparentOcean(true)
    
    if not TheNet:IsDedicated() then
        inst.Map:DoOceanRender(true)
    end
    mod_protect_TileManager = true
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
