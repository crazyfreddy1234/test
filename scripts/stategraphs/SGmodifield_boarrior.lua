local boarrior_sg = deepcopy(require "stategraphs/SGboarrior")

local function SpawnEntsRandomInCircle(inst, opts, current_ents)
    local options = {
        pos          = TheWorld.components.lavaarenaevent:GetArenaCenterPoint() or inst.Transform:GetPosition(),
        offset       = 13.5,
        angle_offset = PI/4,
        prefab       = "battlestandard_damager",
        max          = 4,
        delay_per_spawn = 4*FRAMES,
        duplicates      = false,
    }
    current_ents = current_ents or {}
    -- Load custom options
    MergeTable(options, opts or {}, true)
    -- Generate Positions
    local positions = {}
    for i = 1, options.max do
        local current_angle = 2 * PI / options.max * i + options.angle_offset
        local angled_offset = Vector3(options.offset * math.cos(current_angle), 0, options.offset * math.sin(current_angle))
        local pos = options.pos + angled_offset
        -- Check to see if ent already exists in this position
        local is_valid_pos = true
        if not options.duplicates then
            for _,ent in pairs(current_ents) do
                local ent_pos = ent:GetPosition()
                for i,val in pairs(ent_pos) do
                    ent_pos[i] = Round(val,100)
                end
                local is_same_pos = ent_pos.x == pos.x and ent_pos.y == pos.y and ent_pos.z == pos.z
                is_valid_pos = is_valid_pos and (ent:GetDistanceSqToPoint(pos) > 0.1)
            end
        end
        if is_valid_pos then
            table.insert(positions, pos)
        end
    end
    -- Spawn ents in random order
    local four_banners = {}
    table.insert(four_banners,"battlestandard_heal")
    table.insert(four_banners,"battlestandard_shield")
    table.insert(four_banners,"battlestandard_damager")
    table.insert(four_banners,"battlestandard_speed")
    for i = 1, #positions do
        local rand = math.random(#positions)
        local pos = positions[rand]
        table.remove(positions, rand)
        inst:DoTaskInTime(options.delay_per_spawn*(i-1), function(inst)
            local randomnum = math.random(1,#four_banners)
            local prefab = four_banners[randomnum]
            table.remove(four_banners,randomnum)
            local ent = SpawnPrefab(prefab)
            ent.Transform:SetPosition(pos:Get())
            current_ents[ent] = ent
            ent:ListenForEvent("onremove", function()
                current_ents[ent] = nil
            end)
        end)
    end

    return current_ents
end

local function SpawnBanners(inst)
    SpawnEntsRandomInCircle(inst, inst.components.combat:GetAttackOptions("reinforcements").banner_opts, inst.banners)
end

local _oldbanner_pre = boarrior_sg.states.banner_pre

_oldbanner_pre.onenter = function(inst, cb)
    inst.components.sleeper:SetResistance(9999)
    inst.Physics:Stop()
    inst.AnimState:PlayAnimation("banner_pre")
    if not inst.banner_call_timer then
        inst:DoTaskInTime(2, SpawnBanners) -- TODO tuning?
        TheWorld.components.lavaarenaevent:QueueWave(nil, true, inst.components.combat:GetAttackOptions("reinforcements").wave) -- TODO should this be an event pushed instead of a function call?
        inst.banner_call_timer = inst:DoTaskInTime(5, function(inst) -- TODO tuning?
            inst.banner_call_timer = nil
        end)
    end
end

COMMON_FNS.ApplyStategraphPostInits(boarrior_sg)
return boarrior_sg
