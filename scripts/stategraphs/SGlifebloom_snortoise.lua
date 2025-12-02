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
    if target.components.combat and target.Physics then
        local x, y, z = inst.Transform:GetWorldPosition()
        local distsq = target:GetDistanceSqToPoint(x, 0, z)
        --if distsq < REPEL_RADIUS_SQ then
        target:ForceFacePoint(x, 0, z)
        local k = .5 * distsq / REPEL_RADIUS_SQ - 1
        target.speed = 60 * k
        target.dspeed = 2
        target.Physics:ClearMotorVelOverride()
        target.Physics:Stop()

        for i= 0, 0.3, 0.1 do
            target:DoTaskInTime(i, function(target)
                target.Physics:ClearMotorVelOverride()
                target.Physics:Stop()
                target.Physics:SetMotorVelOverride(-(attack_knockback or 1), 0, 0)
            end)
        end

        target:DoTaskInTime(0.4, function(target)
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
            inst.sg:GoToState("stun",{stimuli = "electric"})
            inst:DoTaskInTime(0, function(inst)
                if ent and not ent.components.health:IsDead() then
                    inst:PushEvent("force_knockback", {knocker = ent, radius = 5, strengthmult = (ent.prefab == " boarilla" and 10) or 2, forcelanded = true})
                end
            end)
        end
    end
end

local function EndSpin(inst)
    if not inst.components.health:IsDead() then
        inst.components.health:DoDelta(-500)
    end  
end

table.insert(new_timeline, TimeEvent(21*FRAMES, function(inst)
    _G.CreateConditionThread(inst, "boarilla_stun_spin", 0, 0.05, SpinningCondition, Check_Mob_Spin, EndSpin)
end))

spin_state.timeline = new_timeline




local function OnEnterForceKnockbackPhase(inst, data)
    inst.sg:GoToState("knockback", data)
end

lifebloom_snortoise_sg.events["force_knockback"] = EventHandler("force_knockback", OnEnterForceKnockbackPhase)



COMMON_FNS.ApplyStategraphPostInits(lifebloom_snortoise_sg)
return lifebloom_snortoise_sg