local _G=GLOBAL
local STRINGS = _G.STRINGS
local RF_TUNING = _G.TUNING.FORGE
local RF_DATA = _G.REFORGED_DATA

local function RGB(r, g, b)
    return { r / 255, g / 255, b / 255, 1 }
end
local INITIAL_LIGHT_CHECK_DELAY = 1
local phases = {}
local valid_phases = {}
local player_phases = {}
local player_valid_phases = {}
local isfirst = true
local isnormal = math.random(1,5)
local phasecount = 0
local lastlight = {}
local lightdefs = {}
local REVIVED_LIGHT_IMMUNITY_TIME = 5

lightdefs["stop"] = 15
lightdefs["hit"] = 1.05
lightdefs["move"] = 3.2
lightdefs["attack"] = 2.1
local function AddLightPhase(name, color, onenter_fn, onexit_fn, str, speech, fakeout_banter, min_time, max_time)
    phases[name] = {
        color          = color,
        str            = str,
        speech         = speech,
        fakeout_banter = fakeout_banter,
        min_time       = min_time or 10,
        max_time       = max_time or 20,
        onenter_fn     = onenter_fn,
        onexit_fn      = onexit_fn,
    }
    table.insert(valid_phases, name)
end
local function KillPlayer(inst)
    if inst and inst.components.health and not inst.components.health:IsDead() and not inst.light_immunity and inst:IsValid() then
        local current_light_phase = player_phases[inst]
        local light_phase_str = current_light_phase and phases[current_light_phase].str
        inst.components.health:DoDelta(-inst.components.health.maxhealth/lightdefs[current_light_phase],nil,light_phase_str or nil,true,nil,true)
    end
end
-- No Light: No restrictions
AddLightPhase("normal", RGB(255, 255, 255), nil, nil, "NOLIGHT", "NO LIGHT!", "REFORGED.RLGL.NOLIGHT_FAKEOUT_BANTER")
local MOVEMENT_CHECK_TASK_TIME = _G.FRAMES
-- Red Light: Can't move
local function StopPhaseOnLocomote(inst)
    if inst.sg:HasStateTag("moving") and player_phases[inst] == "stop" then --inst.Physics:GetMotorSpeed() > 0 then
        KillPlayer(inst)
    end
end
local function StopPhaseOnEnter(inst)
    inst.stop_task = inst:DoPeriodicTask(MOVEMENT_CHECK_TASK_TIME, StopPhaseOnLocomote, nil, 1)
end
local function StopPhaseOnExit(inst)
    _G.RemoveTask(inst.stop_task) -- ThePlayer.components.colouradder:PushColour("test", 255, 0, 0, 1)
end
AddLightPhase("stop", RGB(255, 0, 0), StopPhaseOnEnter, StopPhaseOnExit, "REDLIGHT", "LIGHTS!", "REFORGED.RLGL.REDLIGHT_FAKEOUT_BANTER", 4, 7)
-- Green Light: Can't stand still -- TODO for more than a second?
local MIN_MOVE_TIME = 0.5
local function MovePhaseCheck(inst)
    if not inst.sg:HasStateTag("moving") and (not inst.last_move_time or _G.GetTime() - inst.last_move_time > MIN_MOVE_TIME) and player_phases[inst] == "move" then
        KillPlayer(inst)
    end
end
local function MovePhaseOnLocomote(inst)
    if inst.Physics:GetMotorSpeed() > 0 or inst.sg:HasStateTag("moving") then
        inst.last_move_time = _G.GetTime()
    end
end
local function MovePhaseOnEnter(inst)
    inst:ListenForEvent("locomote", MovePhaseOnLocomote)
    inst.move_task = inst:DoPeriodicTask(MIN_MOVE_TIME, MovePhaseCheck, nil, 0)
end
local function MovePhaseOnExit(inst)
    _G.RemoveTask(inst.move_task)
    inst.move_task = nil
    inst:RemoveEventCallback("locomote", MovePhaseOnLocomote)
    inst.last_move_time = nil
end
AddLightPhase("move", RGB(0, 255, 127), MovePhaseOnEnter, MovePhaseOnExit, "GREENLIGHT", "LIGHTS!", "REFORGED.RLGL.GREENLIGHT_FAKEOUT_BANTER", 4, 7)
-- Orange Light: Must attack once every 5 seconds???
local MIN_ATTACK_TIME = 2
local function AttackPhaseCheck(inst)
    local current_time = _G.GetTime()
    -- Only kill the player if there are mobs to attack and the wave did not just start.
    if (not inst.components.combat.lastdoattacktime or current_time - inst.components.combat.lastdoattacktime > MIN_ATTACK_TIME) and #_G.TheWorld.components.forgemobtracker:GetAllLiveMobs() > 0 and current_time - _G.TheWorld.components.lavaarenaevent.wave_start_time > MIN_ATTACK_TIME and player_phases[inst] == "attack" then
        KillPlayer(inst)
    end
end
local function AttackPhaseOnEnter(inst)
    inst.attack_task = inst:DoPeriodicTask(MIN_ATTACK_TIME, AttackPhaseCheck, nil, math.max(0, MIN_ATTACK_TIME - INITIAL_LIGHT_CHECK_DELAY))
end
local function AttackPhaseOnExit(inst)
    _G.RemoveTask(inst.attack_task)
    inst.attack_task = nil
end
AddLightPhase("attack", RGB(255, 165, 0), AttackPhaseOnEnter, AttackPhaseOnExit, "ORANGELIGHT", "LIGHTS!", "REFORGED.RLGL.ORANGELIGHT_FAKEOUT_BANTER", 4, 7)
-- Blue Light: Can't get hit.
local function OnAttacked(inst)
    if player_phases[inst] == "hit" then
        KillPlayer(inst)
    end
end
local function HitPhaseOnEnter(inst)
    inst:ListenForEvent("attacked", OnAttacked)
end
local function HitPhaseOnExit(inst)
    inst:RemoveEventCallback("attacked", OnAttacked)
end
AddLightPhase("hit", RGB(0, 0, 255), HitPhaseOnEnter, HitPhaseOnExit, "BLUELIGHT", "LIGHTS!", "REFORGED.RLGL.BLUELIGHT_FAKEOUT_BANTER", 4, 7)


local function ResetValidPhases(inst, player)
    if #player_valid_phases[player] <= 0 then
        for phase,_ in pairs(phases) do
            if phase ~= "normal" then
                table.insert(player_valid_phases[player], phase)
            end              
        end
    end
end




local CHATTER_LINE_DURATION = 4
local BANTER_CHANCE = 0.2
--[[
local function CreateFakeoutBanter(inst, time_to_next_phase)
    local time_to_next_fake = math.random(1, time_to_next_phase)
    if math.random() <= BANTER_CHANCE and time_to_next_fake < time_to_next_phase then
        inst:DoTaskInTime(time_to_next_fake, function(inst)
            local fakeout_phase = valid_phases[math.random(1,#valid_phases)]
            local fakeout_banter = phases[fakeout_phase].fakeout_banter
            if inst.components.lavaarenaevent.victory ~= nil then return end -- Do not fakeout banter when the game is over
            local rlgl_talker = inst:GetRLGLTalker()
            if rlgl_talker then
                rlgl_talker.components.talker:Chatter(fakeout_banter, _G.COMMON_FNS.GetBanterID(fakeout_banter), CHATTER_LINE_DURATION)
            end
            CreateFakeoutBanter(inst, time_to_next_phase - time_to_next_fake)
        end)
    end
end
--]]
local function ChangeLightPhase(inst, phase, player)
    if phases[lastlight[player]].onexit_fn then
        phases[lastlight[player]].onexit_fn(player)
    end

    if inst.components.lavaarenaevent.victory ~= nil then return end -- Stop changing lights when the game is over
    inst.current_light_phase = phase
    local player_current_phase_info = phases[player_phases[player]]
    
    -- Set players color for the current phase

    if player.components.colouradder then
        local color = phases[player_phases[player]].color
        player.components.colouradder:PushColour("rlgl", color[1], color[2], color[3], color[4], nil, nil, true)
    elseif player.AnimState then
        player.AnimState:SetMultColour(_G.unpack(phases[player_phases[player]].color))
    end

    if phases[player_phases[player]].onenter_fn then
        inst:DoTaskInTime(INITIAL_LIGHT_CHECK_DELAY, function(inst)
            phases[player_phases[player]].onenter_fn(player)
        end)
    end

    local rlgl_talker = inst:GetRLGLTalker()
    if rlgl_talker then
        local speak = "Lights!"
        rlgl_talker.components.talker:Say(speak, CHATTER_LINE_DURATION)
    end
end

local function MakePlayerPhase(inst, player, next_phase)     
    if isfirst or (isnormal==phasecount) then
        player_phases[player] = "normal"
    else
        local index = player_valid_phases[player] and math.random(1,#player_valid_phases[player]) or 1
        player_phases[player] = player_valid_phases[player][index]
        table.remove(player_valid_phases[player], index)
    end
end

local function UpdateLightPhase(inst)
    local next_phase_player = {}
    local next_phase = "normal"
    phasecount = phasecount + 1

    if phasecount >= 6 then
        phasecount = 1
        isnormal = math.random(1,5)
    end

    for i,player in pairs(_G.AllPlayers) do
        if not player:HasTag("have_light_immunity") then
            player:ListenForEvent("respawnfromcorpse", function(inst)
                inst:AddTag("have_light_immunity")
                inst.light_immunity = true
                player:DoTaskInTime(REVIVED_LIGHT_IMMUNITY_TIME, function()
                    inst.light_immunity = false
                end)
            end)
        end

        if player and player_valid_phases[player] and player_phases[player] then
            MakePlayerPhase(inst, player, next_phase)
            ResetValidPhases(inst, player)
            ChangeLightPhase(inst, player_phases[player], player)
            lastlight[player] = player_phases[player]
        else
            lastlight[player] = "normal"
            player_valid_phases[player] = {}
            for phase,_ in pairs(phases) do
                if phase ~= "normal" then
                    table.insert(player_valid_phases[player], phase)
                end              
            end
            player_phases[player] = "normal"

            player:ListenForEvent("respawnfromcorpse", function(inst)
                inst.light_immunity = true
                player:DoTaskInTime(REVIVED_LIGHT_IMMUNITY_TIME, function()
                    inst.light_immunity = false
                end)
            end)
        end
    end   
    if inst.components.lavaarenaevent.victory ~= nil then return end -- Do not queue the next phase when the game is over
    -- Queue next phase
    local ravephase = math.random(60,90)/10
    inst:DoTaskInTime(ravephase, function()
        isfirst = false
        UpdateLightPhase(inst)
    end)
    
    --CreateFakeoutBanter(inst, time_to_next_phase)
end

local function StartRLGL(inst)
    for _,player in pairs(_G.AllPlayers) do
        lastlight[player] = "normal"

        player_valid_phases[player] = {}
        for phase,_ in pairs(phases) do
            if phase ~= "normal" then
                table.insert(player_valid_phases[player], phase)  
            end           
        end
        player_phases[player] = "normal"

        player:ListenForEvent("respawnfromcorpse", function(inst)
            inst:AddTag("have_light_immunity")
            inst.light_immunity = true
            player:DoTaskInTime(REVIVED_LIGHT_IMMUNITY_TIME, function()
                inst.light_immunity = false
            end)
        end)
    end

    UpdateLightPhase(inst)
end

local function OnNewPlayer(inst, player)
    lastlight[player] = "normal"
    player_valid_phases[player] = {}
    for phase,_ in pairs(phases) do
        if phase ~= "normal" then
            table.insert(player_valid_phases[player], phase)
        end              
    end
    player_phases[player] = "normal"

    player:ListenForEvent("respawnfromcorpse", function(inst)
        inst.light_immunity = true
        player:DoTaskInTime(REVIVED_LIGHT_IMMUNITY_TIME, function()
            inst.light_immunity = false
        end)
    end)
end



local rlgl_fns = {
    enable_server_fn = function(inst)
        inst.rlgl_talker = _G.SpawnPrefab("reforged_rlgl_talker")
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
        inst:RemoveEventCallback("ms_playerjoined", OnNewPlayer)
        inst:RemoveEventCallback("ms_forge_allplayersspawned", StartRLGL)
    end,
}
local disco_icon = {atlas = "images/disco_rave.xml", tex = "disco_rave.tex"}
local rlgl_exp = {desc = "DISCOLIGHTSRAVE_WIN", val = {mult = 6},atlas = "images/disco_rave.xml", tex = "disco_rave.tex"}
_G.AddGametype("discolightsrave", rlgl_fns, disco_icon, rlgl_exp, 10)