local swine_sg = require "stategraphs/SGswineclops_mummy"
swine_sg.name = "butter_swineclops_mummy"
local tuning_values = TUNING.HALLOWED_FORGE.SWINECLOPS_MUMMY

local function launchitem(inst, item) -- TODO common fn
    local target = inst.components.combat.target
    local target_pos = target and target:GetPosition() or _G.TheWorld.components.lavaarenaevent:GetArenaCenterPoint() or inst:GetPosition()
    local angle = -inst:GetAngleToPoint(target_pos:Get()) * DEGREES
    local speed = (math.random() * 4 + 8)/2
    angle = (angle + math.random() * 60 - 30) * DEGREES
    item.Physics:SetVel(speed * math.cos(angle), math.random() * 2 + 8, speed * math.sin(angle))
end

local function DoBurst(inst)
    if not inst.bursted then
        inst.bursted = true
        inst.AnimState:OverrideSymbol("body", inst.burst_build or "hf_beetletaur_mummy_bursted", "body")
    end

    local explodeBettles_amount = 0

    if #AllPlayers >= 6 then
        explodeBettles_amount = 2
    else
        local random = math.random()

        if ((#AllPlayers)-2)*0.25 > random then
            explodeBettles_amount = 2
        else
            explodeBettles_amount = 1
        end
    end


    for i = 1, (inst.components.combat:GetAttackOptions("beetles").burst_amount) - explodeBettles_amount do
        local pos = inst:GetPosition()
        local beetle = SpawnPrefab("hf_roach_beetle_projectile")
        beetle.duplicator_count = inst.duplicator_count -- Make sure the beetle projectile can pass the duplicator count to the Cursed Helmet mob.
        beetle.Transform:SetPosition(pos.x, 3, pos.z)
        launchitem(inst, beetle)
        beetle.owner = inst
    end

    for i = 1, explodeBettles_amount do
        local pos = inst:GetPosition()
        local beetle = SpawnPrefab("hf_butter_roach_beetle_projectile")
        beetle.duplicator_count = inst.duplicator_count 
        beetle.Transform:SetPosition(pos.x, 3, pos.z)
        launchitem(inst, beetle)
        beetle.owner = inst
    end

    inst.components.combat:StartCooldown("beetles")
end


local stomach_burst_pst_state = swine_sg.states.stomach_burst_pst
local _oldOnEnter = stomach_burst_pst_state.onenter

stomach_burst_pst_state.onenter = function(inst, data)
    inst.Physics:Stop()
    inst.AnimState:PlayAnimation("stun_loop", true)
    inst.SoundEmitter:PlaySound(inst.sounds.hit)

    DoBurst(inst)

    inst.components.combat:ToggleAttack("beetles", true)
    inst.sg:SetTimeout(1.5)
    inst.sg.mem.wants_to_burst = false
end


COMMON_FNS.ApplyStategraphPostInits(swine_sg)

return swine_sg
