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

local function KnockbackFromTarget(inst, target, force, duration)
    if not inst or not inst:IsValid() then return end
    if not target or not target:IsValid() then return end
    if not inst.Physics then return end

    force = force or 6
    duration = duration or 0.2

    -- 위치 가져오기 (DST: Transform:GetWorldPosition() -> x, y, z)
    local ix, iy, iz = inst.Transform:GetWorldPosition()
    local tx, ty, tz = target.Transform:GetWorldPosition()

    -- 대상에서 내 쪽으로의 벡터가 아니라, "내 - 대상" 으로 해서
    -- 대상으로부터 멀어지는 방향을 계산.
    local dx = ix - tx
    local dz = iz - tz

    -- 길이(거리)
    local dist = math.sqrt(dx * dx + dz * dz)

    -- 동일 좌표(0으로 나누는 경우) 방지: 약간 랜덤 방향으로 보정
    if dist == 0 then
        dx = (math.random() - 0.5)
        dz = (math.random() - 0.5)
        dist = math.sqrt(dx * dx + dz * dz)
        if dist == 0 then
            dx, dz = 1, 0
            dist = 1
        end
    end

    -- 정규화
    dx = dx / dist
    dz = dz / dist

    -- 기존 속도 제거 후 모터 속도 설정
    inst.Physics:Stop()
    inst.Physics:SetMass(0)
    inst.Physics:SetMotorVel(force * dx, 0, force * dz)

    -- (선택) 스턴/상태 처리가 필요하면 여기서 상태 전환: 예)
    -- if inst.sg then inst.sg:GoToState("stunned") end

    -- duration 뒤에 속도 정지(그리고 필요하면 상태 해제)
    inst:DoTaskInTime(duration, function()
        if inst and inst.Physics then
            inst.Physics:Stop()
            inst.Physics:SetMass(150)
        end
    end)
end

local function Check_Mob_Spin(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, tuning_values.SPIN_HIT_RANGE + 0.5, {"LA_mob"})

    for i,ent in pairs(ents) do
        if ent and inst ~= ent then
            print(inst,ent)
            inst.sg:GoToState("stun",{stimuli = "electric"})
            KnockbackFromTarget(inst, ent, 5, 2)
        end
    end
end

local function EndSpin(inst)
    inst:DoTaskInTime(2,function(inst)
        if not inst.components.health:IsDead() then
            inst.components.health:DoDelta(inst.components.health.maxhealth)
        end
    end)    
end

table.insert(new_timeline, TimeEvent(21*FRAMES, function(inst)
    _G.CreateConditionThread(inst, "boarilla_stun_spin", 0, 0.15, SpinningCondition, Check_Mob_Spin, EndSpin)
end))

spin_state.timeline = new_timeline



COMMON_FNS.ApplyStategraphPostInits(lifebloom_snortoise_sg)
return lifebloom_snortoise_sg