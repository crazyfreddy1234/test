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
}
--------------------------------------------------------------------------
local map_values = {
    name = "my_map",
    colour_cube  = "images/colour_cubes/day05_cc.tex",
    sample_style = MAP_SAMPLE_STYLE.NINE_SAMPLE,
}
--------------------------------------------------------------------------
local function common_preinit(inst)
    COMMON_FNS.MapPreInit(inst, map_values)
end
--------------------------------------------------------------------------
local function common_postinit(inst)
    COMMON_FNS.MapPostInit(inst, map_values)
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
--return MakeWorld(map_values.name, prefabs, assets, common_postinit, master_postinit, { "lavaarena" }, {common_preinit = common_preinit}), Prefab(map_values.name .. "_network", fn)
