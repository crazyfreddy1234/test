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
    local ents = _G.TheSim:FindEntities(pos.x, 0, pos.z, radius or 5,{"player", "companion", "ally"}, {"notarget", "INLIMBO", "playerghost"})

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

local function R_FindTargets(inst,radius)
    local pos = inst:GetPosition()
    local ents = _G.TheSim:FindEntities(pos.x, 0, pos.z, radius or 5,{"player", "companion", "ally", "RDPS"}, {"notarget", "INLIMBO", "playerghost","already_target"})

    if ents ~= nil and #ents > 0 then
        return ents
    else
        return nil
    end
end

local function M_FindTargets(inst,radius)
    local pos = inst:GetPosition()
    local ents = _G.TheSim:FindEntities(pos.x, 0, pos.z, radius or 5,{"player", "companion", "ally", "MDPS"}, {"notarget", "INLIMBO", "playerghost","already_target"})

    if ents ~= nil and #ents > 0 then
        return ents
    else
        return nil
    end
end

local function H_FindTargets(inst,radius)
    local pos = inst:GetPosition()
    local ents = _G.TheSim:FindEntities(pos.x, 0, pos.z, radius or 5,{"player", "companion", "ally", "HEALER"}, {"notarget", "INLIMBO", "playerghost","already_target"})

    if ents ~= nil and #ents > 0 then
        return ents
    else
        return nil
    end
end

local function T_FindTargets(inst, radius)
    local pos = inst:GetPosition()
    local ents = _G.TheSim:FindEntities(pos.x, 0, pos.z, radius or 5,{"player", "companion", "ally", "TANK"}, {"notarget", "INLIMBO", "playerghost","already_target"})

    if ents ~= nil and #ents > 0 then
        return ents
    else
        return nil
    end
end

local function FindTargetsPriority(inst, radius, R_PRIORITY, M_PRIORITY, H_PRIORITY, T_PRIORITY, target_num)
    if target_num <= 0 then return end
    
    local target_priority = {
        R = R_PRIORITY,
        M = M_PRIORITY,
        H = H_PRIORITY,
        T = T_PRIORITY,
    }

    local limits = {
        R = 3,
        M = 2,
        H = 2,
        T = 2,
    }

    for i, v in ipairs(target_priority) do
        if v == nil then
            table.remove(target_priority, i)
        else
            limits[v] = FindTargetsRDPS(s)
        end
    end
    
    local total_needed = target_num
    
    -- 결과 저장용
    local result = {}
    
    -- 1. 우선순위 테이블을 배열로 변환
    local priority_list = {}
    for k, priority in pairs(target_priority) do
        table.insert(priority_list, { key = k, priority = priority })
    end
    
    -- 2. 오름차순 정렬 (작은 수가 더 높은 우선순위)
    table.sort(priority_list, function(a, b)
        return a.priority < b.priority
    end)
    
    -- 3. 정렬된 우선순위대로 인원을 뽑기
    local remaining = total_needed
    
    for _, entry in ipairs(priority_list) do
        local key = entry.key
        local max_count = limits[key] or 0
    
        if remaining <= 0 then break end
    
        local to_add = math.min(max_count, remaining)
    
        -- to_add 만큼 키를 추가
        for i = 1, to_add do
            table.insert(result, key)
        end
    
        remaining = remaining - to_add
    end

    print("=== target_priority ===")
    for k, v in pairs(target_priority) do
        print(k, v)
    end
    
    print("\n=== Selected Result ===")
    for i, v in ipairs(result) do
        print(i, v)
    end
end

return {
    TurnOnPowerAllPlayer = TurnOnPowerAllPlayer,
    TurnOffPowerAllPlayer = TurnOffPowerAllPlayer,
    TurnOnPowerWhoJoinServer = TurnOnPowerWhoJoinServer,
    StopTurnOnPowerWhoJoinServer = StopTurnOnPowerWhoJoinServer,
    IsDungeon = IsDungeon,
    FindAllPlayer = FindAllPlayer,
}
