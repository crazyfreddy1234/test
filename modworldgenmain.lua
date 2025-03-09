local _G = GLOBAL
if _G.rawget(_G, "REFORGED_GROUND_TYPES") then
    local Layouts = _G.require("map/layouts").Layouts
    local StaticLayout = _G.require("map/static_layout")

--[[
    ---------Mangrove Arena------------
    Layouts["MY_Layout"] = StaticLayout.Get("map/static_layouts/my_map", {
        start_mask        = _G.PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
        fill_mask         = _G.PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
        layout_position   = _G.LAYOUT_POSITION.CENTER,
        disable_transform = true,
    })
    Layouts["MY_Layout"].ground_types = _G.REFORGED_GROUND_TYPES,       
    _G.AddStartLocation("my_map", {
        name           = _G.STRINGS.UI.SANDBOXMENU.DEFAULTSTART,
        location       = "my_map",
        start_setpeice = "MY_Layout",
        start_node     = "Blank",
    })
    _G.AddLocation({
        location = "my_map",
        version = 3,
        overrides = {
            task_set = "lavaarena_taskset",--"(TODO)_arena_taskset",
            start_location = "MY_Layout",
            season_start = "default",
            world_size = "small",
            layout_mode = "RestrictNodesByKey",
            wormhole_prefab = nil,
            roads = "never",
            keep_disconnected_tiles = true,
            no_wormholes_to_disconnected_tiles = true,
            no_joining_islands = true,
        },
        required_prefabs = {
            "lavaarena_portal",
        },
    })
    
    _G.AddWorldGenLevel(_G.LEVELTYPE.LAVAARENA, {
        id       = "MY_MAP",
        name     = "INFERNAL",
        desc     = "TODO",
        location = "my_map", -- this is actually the prefab name
        version  = 3,
        overrides = {
            boons          = "never",
            touchstone     = "never",
            traps          = "never",
            poi            = "never",
            protected      = "never",
            task_set       = "lavaarena_taskset",--"(TODO)_arena_taskset",
            start_location = "my_map",
            season_start   = "default",
            world_size     = "small",
            layout_mode    = "RestrictNodesByKey",
            keep_disconnected_tiles = true,
            wormhole_prefab = nil,
            roads           = "never",
            has_ocean = true,
        },
        required_prefabs = {
            "lavaarena_portal",
        },
        background_node_range = {0,1},
    })
    _G.AddSettingsPreset(LEVELTYPE.LAVAARENA, {
        id        = "MY_MAP",
        name      = "INFERNAL",
        desc      = "TODO",
        location  = "my_map", -- this is actually the prefab name
        version   = 3,
        overrides = {},
    })
]]--

    ----------CHAPTER1_CAVE--------------------

    Layouts["CHAPTER1"] = StaticLayout.Get("map/static_layouts/chapter1_cave", {
        start_mask        = _G.PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
        fill_mask         = _G.PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
        layout_position   = _G.LAYOUT_POSITION.CENTER,
        disable_transform = true,
    })
    Layouts["CHAPTER1"].ground_types = _G.REFORGED_GROUND_TYPES,       
    _G.AddStartLocation("chapter1_cave", {
        name           = _G.STRINGS.UI.SANDBOXMENU.DEFAULTSTART,
        location       = "chapter1_cave",
        start_setpeice = "CHAPTER1",
        start_node     = "Blank",
    })
    _G.AddLocation({
        location = "chapter1_cave",
        version = 3,
        overrides = {
            task_set = "lavaarena_taskset",--"(TODO)_arena_taskset",
            start_location = "CHAPTER1",
            season_start = "default",
            world_size = "small",
            layout_mode = "RestrictNodesByKey",
            wormhole_prefab = nil,
            roads = "never",
            keep_disconnected_tiles = true,
            no_wormholes_to_disconnected_tiles = true,
            no_joining_islands = true,
        },
        required_prefabs = {
            "lavaarena_portal",
        },
    })

    _G.AddWorldGenLevel(_G.LEVELTYPE.LAVAARENA, {
        id       = "CHAPTER1_CAVE",
        name     = "CHAPTER1",
        desc     = "TODO",
        location = "chapter1_cave", -- this is actually the prefab name
        version  = 3,
        overrides = {
            boons          = "never",
            touchstone     = "never",
            traps          = "never",
            poi            = "never",
            protected      = "never",
            task_set       = "lavaarena_taskset",--"(TODO)_arena_taskset",
            start_location = "chapter1_cave",
            season_start   = "default",
            world_size     = "default",
            layout_mode    = "RestrictNodesByKey",
            keep_disconnected_tiles = true,
            wormhole_prefab = nil,
            roads           = "never",
            --has_ocean = true,
        },
        required_prefabs = {
            "lavaarena_portal",
        },
        background_node_range = {0,1},
    })
    _G.AddSettingsPreset(LEVELTYPE.LAVAARENA, {
        id        = "CHAPTER1_CAVE",
        name      = "CHAPTER1",
        desc      = "TODO",
        location  = "chapter1_cave", -- this is actually the prefab name
        version   = 3,
        overrides = {},
    })
end