local _G=GLOBAL
local STRINGS, RF_TUNING, RF_DATA = _G.STRINGS, _G.TUNING.FORGE, _G.REFORGED_DATA

local function RGB(r, g, b)
    return { r / 255, g / 255, b / 255, 1 }
end

local phases = {}
local valid_phases = {}
local WARNING = 1.2
local LONG_WARNING = 1.5
local MID_WARNING = 1.25
local SMALL_WARNING = 1
local KILLFX_TIME = 1
local CHATTER_LINE_DURATION = 4
local overlap = {}
local target_index

local function GetCurrentSpicePhase()
    return _G.TheWorld.current_spice_phase
end 

local function AddSpicePhase(name, debuff_name, flower_type, color, onenter_fn, onexit_fn, speech)
    phases[name] = {
        debuff_name    = debuff_name, 
        flower_type    = flower_type,
        color          = color,
        speech         = speech,
        onenter_fn     = onenter_fn,
        onexit_fn      = onexit_fn,
    }
    table.insert(valid_phases, name)
end


--AddSpicePhase("r", "Fever", "dmg",RGB(255, 0, 0), RedPhaseOnEnter, RedPhaseOnExit, "Fever!")

--AddSpicePhase("gr", "Calmness", "regen", RGB(0, 255, 127), GreenPhaseOnEnter, GreenPhaseOnExit, "Calmness!")

AddSpicePhase("ye", "Boldness", "speed",RGB(255, 165, 0), YellowPhaseOnEnter, YellowPhaseOnExit, "Boldness!")

--AddSpicePhase("bl", "Solitude", "def", RGB(0, 0, 255), BluePhaseOnEnter, BluePhaseOnExit, "Solitude!")

--AddSpicePhase("pur", "Absorption", "unhit",RGB(127, 0, 127), PurplePhaseOnEnter, PurplePhaseOnExit, "Absorption!") -- unhit → cd?


local function ResetValidPhases(inst)
    if #valid_phases <= 0 then
        for phase,_ in pairs(phases) do
            table.insert(valid_phases, phase)
        end
    end
end

local function UpdateSpicePhase(inst)
    local next_phase
    local index = math.random(1,#valid_phases) or 1

    next_phase = valid_phases[index]
    table.remove(valid_phases, index)

    ResetValidPhases(inst)

    inst.circle_count = 0
    overlap=nil
    overlap={}
    target_index=0

    for _,player in pairs(_G.AllNonSpectators) do -- 발밑에 모두생성
        MakeCircleToPlayer(inst, player, next_phase, false)
    end

    MakeCircleAsWeapon(inst,next_phase)

    if inst.components.lavaarenaevent.victory ~= nil then return end

    local NEXT_SPICE = math.random(120,270)/10
    inst:DoTaskInTime(NEXT_SPICE, function()
        UpdateSpicePhase(inst)
    end)
end

local function StartRLGL(inst)
    inst:DoTaskInTime(5, function()
        UpdateSpicePhase(inst)
    end)  
    for _,player in pairs(_G.AllNonSpectators) do
        player:SetStateGraph("SGplayer_sleep")
    end
end

local function OnNewPlayer(inst, player)
    if player.components.transparent == nil then
        player:AddComponent("transparent")
    end
end


local rlgl_fns = {
    enable_server_fn = function(inst)
        inst.rlgl_talker = _G.SpawnPrefab("math_talker")
        inst.GetRLGLTalker = function()
            return inst.rlgl_talker
        end
        ------------------------------------------
        inst:ListenForEvent("ms_playerjoined", OnNewPlayer)
        inst:ListenForEvent("ms_forge_allplayersspawned", StartRLGL)
    end,
    disable_server_fn = function(inst)
        if inst.rlgl_talker then
            inst.rlgl_talker:Remove()
            inst.rlgl_talker = nil
        end
        ------------------------------------------
        inst:RemoveEventCallback("ms_playerjoined", OnNewPlayer)
        inst:RemoveEventCallback("ms_forge_allplayersspawned", StartRLGL)
    end,
}
local disco_icon = {atlas = "images/lotus.xml", tex = "lotus_flower.tex"}
local rlgl_exp = {desc = "BLOSSOMS_WIN", val = {mult = 3},atlas = "images/inventoryimages2.xml", tex = "lotus_flower.tex"}
_G.AddGametype("blossoms", rlgl_fns, disco_icon, rlgl_exp, 3.1)