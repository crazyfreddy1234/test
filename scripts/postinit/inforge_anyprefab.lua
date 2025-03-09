local TARGETING_RANGE = 15
local MAX_RANGE = 1200
local ALERT_RANGE = 30

local LA_MUST_TAGS = { "LA_mob" }
local LA_mob_list ={
    "pitpig",
    "crocommander",
    "snortoise"
}


---------------------------------------------------------------------------------------------------------------------------




local function GetLeader(mob)
    return mob.components.follower and mob.components.follower.leader
end

local function CanTarget(target, mob)
    return mob.components.combat:CanTarget(target) and not _G.COMMON_FNS.IsAlly(mob, target)
end

local function FindClosestTarget(mob, targets, exclude_target, pos_override)
    local closest = {target = false, distsq = MAX_RANGE, exclude_target = false, exclude_target_distsq = MAX_RANGE}
    local mob_pos = pos_override or mob:GetPosition()
	local target_exclude_tags = _G.COMMON_FNS.CommonExcludeTags(mob)
	table.insert(target_exclude_tags, "companion") --companions are lower priority, so they aren't targeted. TODO add generic tag for this?
	local tar_table = targets or TheSim:FindEntities(mob_pos.x, 0, mob_pos.z, TARGETING_RANGE, {"_combat"}, target_exclude_tags)
    local function CompareClosest(target, dist_index, target_index)
        local curdistsq = _G.distsq(mob_pos, target:GetPosition())
        if curdistsq < closest[dist_index] then
            closest[dist_index] = curdistsq
            closest[target_index] = target
        end
    end
    for _,target in pairs(tar_table) do
        if CanTarget(target, mob) then
            if target == exclude_target then
                CompareClosest(target, "exclude_target_distsq", "exclude_target")
            else
                CompareClosest(target, "distsq", "target")
            end
        end
    end
    return closest.target or closest.exclude_target or nil, math.sqrt(closest.distsq or closest.exclude_target_distsq)
end

local function RetargetFn(mob)
    if not mob.components.combat.target and not GetLeader(mob) then
        mob.components.combat:EngageTarget(FindClosestTarget(mob))      
	elseif GetLeader(mob) and mob.components.follower.leader.components.combat.target then
		mob.components.combat:SetTarget(mob.components.follower.leader.components.combat.target)
    end
end

local function IsDungeon()
    local map_name = _G.REFORGED_SETTINGS.gameplay.map or "lavaarena"

    return _G.REFORGED_DATA.maps[map_name].is_dungeon
end



-------------------------------------------------------------------------------------------------------------------------




AddPrefabPostInitAny(function(inst)
    if not (inst:IsValid() and _G.TheNet:GetIsServer()) then
        return
    end

    if inst and (inst:HasTag("player") or inst:HasTag("LA_mob")) and (not _G.TheNet:IsDedicated()) then  --(Player or Mob) and not Server
        inst:AddComponent("transparent")  
        if _G.REFORGED_SETTINGS.gameplay.gametype == "blossoms" then
            inst.components.transparent:Start()
        end
    end

    if inst:HasTag("LA_mob") and _G.INFORGE_COMMON_FNS.IsDungeon() then  --Mob and Dungeon

        local prefab_name = inst.prefab

        inst.components.combat:SetRetargetFunction(1, RetargetFn)

        for i=1,#LA_mob_list do
            if prefab_name == LA_mob_list[i] then
                local brainFileName = "brains/" .. prefab_name .. "brain_dunguen" 
                local Brain_Dunguen = require(brainFileName) 
                local Old_OnLoad = nil

                if inst.OnLoad then
                    Old_OnLoad = inst.OnLoad
                end

                local function onload(inst, data)
                    if Old_OnLoad then
                        Old_OnLoad(inst,data)
                    end
                    if data and data.home_pos then
                        inst.home_pos = data.home_pos
                    end
                    if data and data.standstill then
                        inst.standstill = data.standstill
                    end
                    if data.team_num then
                        inst.team_num = data.team_num
                    end
                end

                local function AlertToAllTeam(inst,data)
                    local x, y, z = inst.Transform:GetWorldPosition()
                    local ents = TheSim:FindEntities(x, y, z, ALERT_RANGE, LA_MUST_TAGS)
                    local target = data.target

                    for i, mob in ipairs(ents) do
                        if mob.team_num and mob.team_num == inst.team_num and not mob.components.combat.target then
                            mob.components.combat:EngageTarget(target)
                        end
                    end
                end

                inst:ListenForEvent("newcombattarget",AlertToAllTeam)

                inst.OnLoad = onload
                inst:SetBrain(Brain_Dunguen)
            end
        end
    end
end)
