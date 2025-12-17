local function TurnOnPowerAllPlayer()
    for _,player in pairs(AllPlayers) do
        player.PowerOnOff:set(true)
    end
end

local function TurnOffPowerAllPlayer()  
    for _,player in pairs(AllPlayers) do
        player.PowerOnOff:set(false)
    end
end

local function TurnOnPowerJoinPlayer(src,player)
    player:DoTaskInTime(1,function()
        player.PowerOnOff:set(true)
    end)
end

local function TurnOnPowerWhoJoinServer()
    _G.REFORGED_DATA.wavesets[_G.REFORGED_SETTINGS.gameplay.waveset].power_on = true
end

local function StopTurnOnPowerWhoJoinServer()
    _G.REFORGED_DATA.wavesets[_G.REFORGED_SETTINGS.gameplay.waveset].power_on = nil
end

local function IsDungeon()
    local map_name = _G.REFORGED_SETTINGS.gameplay.map or "lavaarena"

    return _G.REFORGED_DATA.maps[map_name].is_dungeon
end

local function FindAllPlayer(inst, radius)
    local pos = inst:GetPosition()
    local ents = _G.TheSim:FindEntities(pos.x, 0, pos.z, radius or 5,{"player"}, {"notarget", "INLIMBO", "playerghost"})

    if ents ~= nil and #ents > 0 then
        return ents
    else
        return nil
    end
end

local function FindTargets_WeaponType(inst, radius, weapontype)
    local types = {
        R = "RDPS",
        M = "MDPS",
        H = "HEALER",
        T = "TANK"
    }               ----range, melee, healer, tank
    local targets = {}
    local allplayer_radius = FindAllPlayer(inst, radius)

    for k, v in pairs(types) do
        if weapontype == k then
            for _, player in pairs(allplayer_radius) do
                if player:IsValid() and player:HasTag(v) then
                    table.insert(targets, player)
                end
            end
        end
    end
end

local function R_FindTargets(inst, radius)
    local pos = inst:GetPosition()
    local ents = _G.TheSim:FindEntities(pos.x, 0, pos.z, radius or 5,{"player", "RDPS"}, {"notarget", "INLIMBO", "playerghost","already_target"})


    if ents ~= nil and #ents > 0 then
        return ents
    else
        return nil
    end
end

local function M_FindTargets(inst, radius)
    local pos = inst:GetPosition()
    local ents = _G.TheSim:FindEntities(pos.x, 0, pos.z, radius or 5,{"player", "MDPS"}, {"notarget", "INLIMBO", "playerghost","already_target"})

    if ents ~= nil and #ents > 0 then
        return ents
    else
        return nil
    end
end

local function H_FindTargets(inst, radius)
    local pos = inst:GetPosition()
    local ents = _G.TheSim:FindEntities(pos.x, 0, pos.z, radius or 5,{"player", "HEALER"}, {"notarget", "INLIMBO", "playerghost","already_target"})

    if ents ~= nil and #ents > 0 then
        return ents
    else
        return nil
    end
end

local function T_FindTargets(inst, radius)
    local pos = inst:GetPosition()
    local ents = _G.TheSim:FindEntities(pos.x, 0, pos.z, radius or 5,{"player", "TANK"}, {"notarget", "INLIMBO", "playerghost","already_target"})

    if ents ~= nil and #ents > 0 then
        return ents
    else
        return nil
    end
end

local function FindTargetsPriority(inst, radius, R_PRIORITY, M_PRIORITY, H_PRIORITY, T_PRIORITY, target_num)
    if target_num <= 0 then return end

    local find_target_funcs = {
        R = R_FindTargets,
        M = M_FindTargets,
        H = H_FindTargets,
        T = T_FindTargets,
    }
    
    local target_priority = {
        R = R_PRIORITY,
        M = M_PRIORITY,
        H = H_PRIORITY,
        T = T_PRIORITY,
    }

    local targets_count = {
        R = 0,
        M = 0,
        H = 0,
        T = 0,
    }

    for i, v in ipairs(target_priority) do
        if v == nil then
            table.remove(target_priority, i)
            table.remove(targets_count, i)
        else
            local find_func = find_target_funcs[i]

            if find_func then
                local targets = find_func(inst, radius)
                targets_count[i] = targets and #targets or 0
            else
                targets_count[i] = 0
            end
        end
    end
    
    local total_needed = target_num
    
    local result = {}
    
    local priority_list = {}
    for k, priority in pairs(target_priority) do
        table.insert(priority_list, { key = k, priority = priority })
    end
    
    table.sort(priority_list, function(a, b)
        return a.priority < b.priority
    end)
    
    local remaining = total_needed
    
    for _, entry in ipairs(priority_list) do
        local key = entry.key
        local max_count = targets_count[key] or 0
    
        if remaining <= 0 then break end
    
        local to_add = math.min(max_count, remaining)
    
        for i = 1, to_add do
            table.insert(result, key)
        end
    
        remaining = remaining - to_add
    end
    


    local result_players = {}

    for i, weapon_type in ipairs(result) do

        local type_FindTargets = find_target_funcs[weapon_type]

        if type_FindTargets then
            players = type_FindTargets(inst, radius) 

            if players and #players > 0 then
                local random_index = math.random(#players)
                local chosen = players[random_index]
                
                table.insert(result_players, chosen)
            else
            end
        end
    end
    
    return result_players
end

local function EncodeDebuffs(debuffs)
    local parts = {}
    for name, stack in pairs(debuffs) do
        table.insert(parts, name .. "=" .. _G.tostring(stack))
    end
    return table.concat(parts, ";")
end

local function DecodeDebuffs(data_str)
    local result = {}
    for pair in string.gmatch(data_str, "([^;]+)") do
        local name, stack = string.match(pair, "([^=]+)=([^=]+)")
        if name and stack then
            result[name] = _G.tonumber(stack)
        end
    end
    return result
end

local function DebuffHealthDelta(inst, amount, cause, cause_target, apply_defense_debuff, force_mult) -- cause_target must be prefab
    print("[INFORGE] DAMAGE ",amount)
    if inst and inst:IsValid() and inst.components and inst.components.health and not inst.components.health:IsDead() then
        if amount and amount < 0 and apply_defense_debuff then
            if inst.components.combat and inst.components.combat.damagebuffs then
                local defense_buffs = inst.components.combat.damagebuffs["recieved"] -- all defense buffs/debuffs table

                for debuff_name, debuff_data in pairs(defense_buffs) do
                    for _, defense_value in pairs(debuff_data) do
                        amount = amount * defense_value
                        print("[INFORGE]",amount,defense_value)
                    end
                end
            end
        end

        inst.components.health:DoDelta(amount * (force_mult or 1), false, cause or "NIL", nil, cause_target or nil, true)
    end
end

return {
    TurnOnPowerAllPlayer = TurnOnPowerAllPlayer,
    TurnOffPowerAllPlayer = TurnOffPowerAllPlayer,
    TurnOnPowerWhoJoinServer = TurnOnPowerWhoJoinServer,
    StopTurnOnPowerWhoJoinServer = StopTurnOnPowerWhoJoinServer,
    IsDungeon = IsDungeon,
    FindAllPlayer = FindAllPlayer,
    FindTargets_WeaponType = FindTargets_WeaponType,
    R_FindTargets = R_FindTargets,
    M_FindTargets = M_FindTargets,
    H_FindTargets = H_FindTargets,
    T_FindTargets = T_FindTargets,
    FindTargetsPriority = FindTargetsPriority,
    EncodeDebuffs = EncodeDebuffs,
    DecodeDebuffs = DecodeDebuffs,
    DebuffHealthDelta = DebuffHealthDelta,
}
