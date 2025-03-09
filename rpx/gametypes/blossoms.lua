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

--인원 수
local function N_Players()
    local playercount
    for i,j in pairs(_G.AllNonSpectators) do
        playercount = i
    end
    return playercount
end
--어림된 방향
local function CleanDirection(player)
    return _G.RoundBiasedUp(player:GetRotation(),3)
end

local function WeaponType(player)
    local item = player.components.inventory:GetEquippedItem(_G.EQUIPSLOTS.HANDS)
    local item_prefab = item and item.prefab
    local item_type = item and (item.components.itemtype and item.components.itemtype.types or {"Other"})

    if item_prefab == "riledlucy" or item_prefab == "blacksmithsedge" or item_prefab == "livingstaff"
        or item_prefab == "petrifyingtome" or item_prefab == "spice_bomb" or item_prefab == nil 
            or item_prefab == "forginghammer" then
        return "TankOrHeal"
    else   
        if item_type then
            for i,j in pairs(item_type) do
                if tostring(i) == "darts" then
                    return "Darts"
                else 
                    return "Other"
                end               
            end
        else
            return "Other"
        end
    end
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

local function MakeCircleToPlayer(inst, player, phase, israndom)
    inst.circle_count = inst.circle_count + 1
    if overlap[target_index] then overlap[target_index]=overlap[target_index] + 1
    else table.insert(overlap, target_index, 1) end 
    if not player.components.health:IsDead() and player:IsValid() then
        inst.current_light_phase = phase
    
        local ice_circle = _G.SpawnPrefab("winter_impact_ping_fx")
        local player_pos

        if israndom then
            local seedvalue = 4-((N_Players()-1)/5) 
            if seedvalue < 0 then seedvalue = 0 end
            local randomvalue = seedvalue + 2*math.random(0,100)/100 -- 1명: 4~6    6명: 3~5
            local diagonalx = 0
            local diagonalz = 0
            player_pos = player:GetPosition() or _G.Vector3(0,0,0)

            diagonalx = math.random(0, randomvalue*100)/100 -- 4: -4~4  6: -6~6
            diagonalz = math.sqrt((randomvalue^2)-(diagonalx^2))
            if math.random(2) == 1 then diagonalx=diagonalx*(-1) end
            if math.random(2) == 1 then diagonalz=diagonalz*(-1) end

            if overlap[target_index] == 1 and player.Physics and player.Physics:GetMotorSpeed()>0 then --디버깅 필요
                diagonalx = 0 diagonalz = 0
                player_pos.x = player_pos.x - player.Physics:GetMotorSpeed()*math.cos(math.rad(CleanDirection(player)))
                player_pos.z = player_pos.z - player.Physics:GetMotorSpeed()*math.sin(math.rad(CleanDirection(player)))
                --_G.SpawnPrefab("rf_ping_banner").Transform:SetPosition(player_pos:Get())
            elseif overlap[target_index] == 2 and player.Physics and player.Physics:GetMotorSpeed()>0 then
                diagonalx = 0 diagonalz = 0
                player_pos.x = player_pos.x + math.random(10,20)/10*player.Physics:GetMotorSpeed()*math.cos(math.rad(CleanDirection(player)+math.random(-20,20)))
                player_pos.z = player_pos.z + math.random(10,20)/10*player.Physics:GetMotorSpeed()*math.sin(math.rad(CleanDirection(player)+math.random(-20,20)))
                --_G.SpawnPrefab("rf_ping_banner").Transform:SetPosition(player_pos:Get())
            elseif overlap[target_index] > 1 then
                randomvalue=randomvalue+math.random(20,30)/10
            end

            player_pos.x = player_pos.x + diagonalx
            player_pos.z = player_pos.z + diagonalz

            --print((overlap[target_index]+1).."번  x: "..player_pos.x..", z: "..player_pos.z..", radius: "..randomvalue) -- 검토
        else
            player_pos = player:GetPosition() or _G.Vector3(0,0,0)
            --print("1번 제자리")
        end

        local rlgl_talker = inst:GetRLGLTalker()
        if rlgl_talker then
            local speak = phases[inst.current_light_phase].speech
            rlgl_talker.components.talker:Say(speak, CHATTER_LINE_DURATION)
        end
        ice_circle.SetColor:set(phases[inst.current_light_phase].flower_type)     --working
        ice_circle.Transform:SetPosition(player_pos:Get())
        ice_circle.Transform:SetScale(0.86, 0.86, 0.86)

        local flower_type = phases[inst.current_light_phase].flower_type
        --[[
        if flower_type == "unhit" then
            WARNING = 1
        elseif flower_type == "dmg" or flower_type == "regen" then
            WARNING = 1.25
        else
            WARNING = 1.5
        end
        ]]--
        ice_circle:DoTaskInTime(WARNING, function()
            local Flower = _G.SpawnPrefab("flowercircle")          
            local color = phases[inst.current_light_phase].color
            local ice_circle_pos = ice_circle:GetPosition() or _G.Vector3(0,0,0)
            local flower_type = phases[inst.current_light_phase].flower_type
            Flower.Transform:SetPosition(ice_circle_pos:Get())
            Flower.SetBuilds:set(flower_type)

            _G.SpawnAt("flower_aoe", ice_circle):ApplyBuffs(nil, flower_type, player, nil, 1.5, 1, 3.8)

            ice_circle:DoTaskInTime(2.3, function(inst)
                ice_circle:KillFX()
            end)           
        end)
    end
end

local function MakeCircleAsWeapon(inst, phase)
    if inst.circle_count >= 12 then return end

    local istankorheal = false
    local isdart = false
    local isother = false
    local activeplayer = 0
    local N_circle = {}

    for _,player in pairs(_G.AllNonSpectators) do
        N_circle[player] = {}
        N_circle[player]["count"] = 0
        if WeaponType(player) == "TankOrHeal" then
            istankorheal = true 
        elseif WeaponType(player) == "Darts" then
            N_circle[player]["count"] = N_circle[player]["count"] + 2
            isdart = true
        else
            N_circle[player]["count"] = N_circle[player]["count"] + 1
            isother = true
        end
        
        if N_Players() <= 3 then
            N_circle[player]["count"] = N_circle[player]["count"] + 1
        end

        if N_circle[player]["count"] > 0 then
            activeplayer = activeplayer + 1
        end
    end 

    if N_Players() == 1 then
        for _,player in pairs(_G.AllNonSpectators) do
            for i=1,2 do
                if math.random(3) ~= 1 then
                    N_circle[player]["count"] = N_circle[player]["count"] + 1
                end
            end
        end
    end

    for i=1,12-inst.circle_count do --ideal max=12
        if activeplayer <= 0 then return end

        local randomasweapon = math.random(1,10)
        local target = {}

        if randomasweapon <= 2 and istankorheal then
            for _,player in pairs(_G.AllNonSpectators) do
                if WeaponType(player) == "TankOrHeal" and N_circle[player]["count"] > 0 then
                    table.insert(target,player)
                end
            end
        elseif randomasweapon <= 5 and isother then
            for _,player in pairs(_G.AllNonSpectators) do
                if WeaponType(player) == "Other" and N_circle[player]["count"] > 0 then
                    table.insert(target,player)
                end
            end
        else 
            for _,player in pairs(_G.AllNonSpectators) do
                if N_circle[player]["count"] > 0 then
                    table.insert(target,player)
                end
            end
        end
        if #target <= 0 then return end
        local target_player = target[math.random(1,#target)]
        for k,v in pairs(_G.AllNonSpectators) do
            if v == target_player then target_index=k end
        end
        MakeCircleToPlayer(inst, target_player, phase, true)
        N_circle[target_player]["count"] = N_circle[target_player]["count"] - 1
        if N_circle[target_player]["count"] <= 0 then
            activeplayer = activeplayer - 1
            if WeaponType(target_player) == "TankOrHeal" then
                local isexist = false
                for k,player in pairs(_G.AllNonSpectators) do
                    if WeaponType(player) == "TankOrHeal" and N_circle[player]["count"] > 0 then
                        isexist = true
                    end
                end
                if not isexist then
                    istankorheal = false 
                end
            elseif WeaponType(target_player) == "Darts" then
                local isexist = false
                for k,player in pairs(_G.AllNonSpectators) do
                    if WeaponType(player) == "Darts" and N_circle[player]["count"] > 0 then
                        isexist = true
                    end
                end
                if not isexist then
                    isdart = false
                end
            else
                local isexist = false
                for k,player in pairs(_G.AllNonSpectators) do
                    if WeaponType(player) == "Other" and N_circle[player]["count"] > 0 then
                        isexist = true
                    end
                end
                if not isexist then
                    isother = false
                end
            end
        end
    end
end

AddSpicePhase("r", "Fever", "dmg",RGB(255, 0, 0), RedPhaseOnEnter, RedPhaseOnExit, "Fever!")

AddSpicePhase("gr", "Calmness", "regen", RGB(0, 255, 127), GreenPhaseOnEnter, GreenPhaseOnExit, "Calmness!")

AddSpicePhase("ye", "Boldness", "speed",RGB(255, 165, 0), YellowPhaseOnEnter, YellowPhaseOnExit, "Boldness!")

AddSpicePhase("bl", "Solitude", "def", RGB(0, 0, 255), BluePhaseOnEnter, BluePhaseOnExit, "Solitude!")

AddSpicePhase("pur", "Absorption", "unhit",RGB(127, 0, 127), PurplePhaseOnEnter, PurplePhaseOnExit, "Absorption!")

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