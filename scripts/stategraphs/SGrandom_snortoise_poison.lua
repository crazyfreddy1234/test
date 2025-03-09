local snortoise_sg = deepcopy(require "stategraphs/SGsnortoise")
local tuning_values = TUNING.FORGE.SNORTOISE

local function SetTargetSpin(inst)
    local targetplayer = {}
    local count_player = 0
    local pos = Vector3(0,0,0)
    local ents = TheSim:FindEntities(pos.x, 0, pos.z, 999, {"_inventoryitem"})


    for _,player in pairs(AllPlayers) do
        if player.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
            for i,j in pairs((player.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)).components.itemtype.types) do
                if tostring(i) ~= "melees" then
                    count_player = count_player + 1
                    targetplayer[count_player] = player
                    break
                end
            end
        end
    end

    if count_player == 0 then
        for _,player in pairs(AllPlayers) do
            count_player = count_player + 1
            targetplayer[count_player] = player
        end
    end

    local attack_player = targetplayer[math.random(1,count_player)]
    if attack_player and attack_player.components.debuffable then
        attack_player.components.debuffable:AddDebuff("debuff_mfd", "debuff_mfd")
    end
    inst.components.combat:SetTarget(attack_player)
    inst.sg:GoToState("taunt")
    inst:DoTaskInTime(1, function(inst)
        inst.sg:GoToState("attack_spin")
    end)   
    inst:DoTaskInTime(8, function(inst)
        if attack_player and attack_player.components.debuffable and attack_player.components.debuffable:HasDebuff("debuff_mfd") then
            attack_player.components.debuffable:RemoveDebuff("debuff_mfd")
            count_player = 0
        end
    end)      
end

local idle_state = snortoise_sg.states.idle
local _oldOnEnter = idle_state.onenter
idle_state.onenter = function(inst, data)
    if inst.sg.mem.spin_attack then 
        inst.sg.mem.spin_attack = nil
        SetTargetSpin(inst)
    else
        _oldOnEnter(inst, data)
    end
end


COMMON_FNS.ApplyStategraphPostInits(snortoise_sg)
return snortoise_sg

