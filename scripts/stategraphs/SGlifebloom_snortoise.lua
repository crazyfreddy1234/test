local lifebloom_snortoise_sg = deepcopy(require "stategraphs/SGsnortoise")
lifebloom_snortoise_sg.name = "lifebloom_snortoise"
local tuning_values = TUNING.FORGE.SNORTOISE



local spin_state = lifebloom_snortoise_sg.states.attack_spin
local _oldtimeline = spin_state.timeline
local new_timeline = {}

for i, v in ipairs(_oldtimeline) do
    table.insert(new_timeline, v)
end


local function SpinningCondition(inst)
    return inst.sg:HasStateTag("spinning")
end

local REPEL_RADIUS = 5
local REPEL_RADIUS_SQ = REPEL_RADIUS * REPEL_RADIUS
local function KnockbackFromTarget(inst, target, attack_knockback)
    if inst.components.combat and target.Physics then
        local x, y, z = inst.Transform:GetWorldPosition()
        local distsq = target:GetDistanceSqToPoint(x, 0, z)
        --if distsq < REPEL_RADIUS_SQ then
        if distsq > 0 then
            target:ForceFacePoint(x, 0, z)
        end
        local k = .5 * distsq / REPEL_RADIUS_SQ - 1
        target.speed = 60 * k
        target.dspeed = 2
        target.Physics:ClearMotorVelOverride()
        target.Physics:Stop()
        --[[ TODO why aren't we using kleis?
        local k = distsq < rangesq and .3 * distsq / rangesq - 1 or -.7
        inst.sg.statemem.speed = (data.strengthmult or 1) * 12 * k
        inst.sg.statemem.dspeed = 0--]]

        -- TODO Leo: Need to change this to check for bodyslot for these tags.
        if target.components.inventory and target.components.inventory:ArmorHasTag("heavyarmor") or target:HasTag("heavybody") then
            target:DoTaskInTime(0.1, function(inst) -- TODO why is this set to 0.1 and the else is set to 0? if they should both be the same then we can shorten this if statement to just be the dotaskintime
                target.Physics:SetMotorVelOverride(-TUNING.FORGE.KNOCKBACK_RESIST_SPEED, 0, 0)
            end)
        else
            target:DoTaskInTime(0, function(inst)
                target.Physics:SetMotorVelOverride(-(attack_knockback or 1), 0, 0)
            end)
        end
        target:DoTaskInTime(0.4, function(inst)
            target.Physics:ClearMotorVelOverride()
            target.Physics:Stop()
        end)
    end
end

local function Check_Mob_Spin(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, tuning_values.SPIN_HIT_RANGE + 0.5, {"LA_mob"})

    for i,ent in pairs(ents) do
        if ent and inst ~= ent then
            print(inst,ent)
            inst.sg:GoToState("stun",{stimuli = "strong"})
            KnockbackFromTarget(ent, inst, 40)
        end
    end
end

local function EndSpin(inst)
    inst:DoTaskInTime(2,function(inst)
        if not inst.components.health:IsDead() then
            inst.components.health:DoDelta(-inst.components.health.maxhealth)
        end
    end)    
end

table.insert(new_timeline, TimeEvent(21*FRAMES, function(inst)
    _G.CreateConditionThread(inst, "boarilla_stun_spin", 0, 0.05, SpinningCondition, Check_Mob_Spin, EndSpin)
end))

spin_state.timeline = new_timeline



COMMON_FNS.ApplyStategraphPostInits(lifebloom_snortoise_sg)
return lifebloom_snortoise_sg