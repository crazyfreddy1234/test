local lifebloom_boarilla_sg = deepcopy(require "stategraphs/SGboarilla")
lifebloom_boarilla_sg.name = "lifebloom_boarilla"
local tuning_values = TUNING.FORGE.BOARILLA


local function ShakePound(inst)
	inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/bodyfall_dirt")
    ShakeAllCameras(CAMERASHAKE.FULL, 1.2, .03, .7, inst, 30)
end

local function SpawnQuakeFX(inst)
    local boarilla_quake_fx = SpawnPrefab("groundpoundring_fx")
    local x, y, z = inst.Transform:GetWorldPosition()

    boarilla_quake_fx.Transform:SetPosition(x, y, z)
end

local function AddQuakeAllPlayers(inst)
    for i,player in pairs(AllPlayers) do
        if player:IsValid() and not player.components.health:IsDead() then
            if player:HasDebuff("debuff_quake") then
                player.components.debuffable:RemoveDebuff("debuff_quake")
            end
            player.components.debuffable:AddDebuff("debuff_quake", "debuff_quake")
        end
    end
end

local function KnockbackAllTargets(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 5, nil, nil, {"LA_mob","player","character"})

    for i,ent in pairs(ents) do
        if ent and ent ~= inst and not (ent:HasTag("LA_mob") and ent.sg:HasStateTag("hiding")) and not ent.components.health:IsDead() then
            if ent:HasTag("LA_mob") and ent.prefab == "snortoise" then
                ent:PushEvent("force_knockback", {knocker = ent, radius = 8, strengthmult = 10, forcelanded = false})
            else
                COMMON_FNS.KnockbackOnHit(inst, ent, 5, tuning_values.ATTACK_KNOCKBACK, 3, true) -- TODO tuning
            end
            inst.components.combat:DoAttack(ent)
        end
    end
end

local QUAKE_SNORTOISE_FRIENDLYFIRE = -100
local function DamageAllSnortoise(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 999, nil, nil, {"LA_mob"})

    for _, ent in pairs(ents) do
        if ent and ent.components.health and ent.components.health:IsDead() then
            ent.components.health:DoDelta(QUAKE_SNORTOISE_FRIENDLYFIRE)
        end
    end
end



local function PickUpToTwoAlivePlayers()
    local vaild_players = {}
    
    for _, player in pairs(AllPlayers) do
        if player and player:IsValid() and not player.components.health:IsDead() then
            table.insert(vaild_players, player)
        end
    end

    local vaild_players_count = #vaild_players
    if vaild_players_count == 0 then
        return {}                      
    elseif vaild_players_count == 1 then
        return { vaild_players[1] }       
    else
        -- 2명 이상이면 랜덤 2명
        local p1 = vaild_players[math.random(vaild_players_count)]
        local p2 = p1
        while p2 == p1 do
            p2 = vaild_players[math.random(vaild_players_count)]
        end
        return { p1, p2 }
    end
end

local function IsHard() 
    local difficulty = _G.REFORGED_SETTINGS.gameplay.difficulty or nil

    if difficulty and difficulty == "hard" then
        return true
    else
        return false
    end
end

local function CreateFissureTwoPlayers(inst)
    if inst.is_second_phase_started ~= true then return end -- only second phase

    local players = PickUpToTwoAlivePlayers()
    
    for _, player in pairs(players) do
        local fissure = nil

        if IsHard() then
            fissure = SpawnPrefab("antlion_sinkhole")
            fissure:PushEvent("startcollapse")
        else
            fissure = SpawnPrefab("antlion_sinkhole")
            fissure:PushEvent("startcollapse")
        end

        fissure.Transform:SetPosition(player.Transform:GetWorldPosition())
    end
end

local function QuakeDebuffAndDamage(inst) -- activate every 5sec until shield break
    SpawnQuakeFX(inst)
    AddQuakeAllPlayers(inst)
    KnockbackAllTargets(inst)
    DamageAllSnortoise(inst)
    CreateFissureTwoPlayers(inst)
end

local function RemoveAllQuakeDebuff(inst)
    for i,player in pairs(AllPlayers) do
        if player:IsValid() and not player.components.health:IsDead() and player:HasDebuff("debuff_quake") then
            player.components.debuffable:RemoveDebuff("debuff_quake")
        end
    end
end

local function StopQuakeAOE(inst)
    if inst.quaketask then
        _G.RemoveTask(inst.quaketask)
        inst.quaketask = nil
    end
end

lifebloom_boarilla_sg.states["enter_shield_phase"] = State{
    name = "enter_shield_phase", -- just jump to center
    tags = {"attack", "busy", "jumping", "keepmoving", "pre_attack", "nofreeze", "delaysleep"},

    onenter = function(inst, data)
        inst.components.combat:StartAttack()
        inst.components.locomotor:Stop()
        ToggleOffCharacterCollisions(inst)
        inst.AnimState:PlayAnimation("attack1")

        if data and data.phase == 2 then
            inst.sg.statemem.cratefissure = true
        end
    end,

    onexit = function(inst)
        inst.components.item_launcher:Enable(false)
        ToggleOnCharacterCollisions(inst)
    end,

    timeline = {
        TimeEvent(10*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.grunt)
            inst.sg:RemoveStateTag("pre_attack")

            local world_center = _G.TheWorld.components.lavaarenaevent and _G.TheWorld.components.lavaarenaevent:GetArenaCenterPoint() or {0,0,0}
            local function MoveOverTime(inst, target_pos, total_frames, on_done)
                if target_pos == nil or total_frames == nil or total_frames <= 0 then
                    return
                end

                local start_pos = inst:GetPosition()
                local elapsed_frames = 0

                inst:ForceFacePoint(target_pos:Get())
                inst.jumptask = inst:DoPeriodicTask(FRAMES, function(inst)
                    elapsed_frames = elapsed_frames + 1

                    local t = elapsed_frames / total_frames
                    if t > 1 then
                        t = 1
                    end

                    local x = start_pos.x + (target_pos.x - start_pos.x) * t
                    local y = start_pos.y + (target_pos.y - start_pos.y) * t
                    local z = start_pos.z + (target_pos.z - start_pos.z) * t

                    inst.Transform:SetPosition(x, y, z)

                    if t >= 1 then
                        inst.jumptask:Cancel()
                        if on_done ~= nil then
                            on_done(inst)
                        end
                    end
                end)
            end

            MoveOverTime(inst,world_center,13)
        end),
        TimeEvent(18*FRAMES, function(inst)
            inst.components.locomotor:Stop()
        end),
        TimeEvent(20*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.attack1)
            ShakePound(inst)
        end),
        TimeEvent(23*FRAMES, function(inst)
            inst.components.item_launcher:Enable(true) -- TODO attack hits on this frame? but the sound is 3 frames earlier?
            COMMON_FNS.DoAOE(inst, nil, tuning_values.DAMAGE, {range = 3, stimuli = "strong"}) -- TODO why offset???
            ToggleOnCharacterCollisions(inst)
        end),
    },

    events = {
        EventHandler("animqueueover", function(inst)
            local world_center = _G.TheWorld.components.lavaarenaevent:GetArenaCenterPoint()
            local look_position = Vector3(world_center.x, world_center.y, world_center.z + 10)
            inst:ForceFacePoint(look_position:Get())

            inst.sg:GoToState("shield_phase_hide_start")
        end),
    },
}

lifebloom_boarilla_sg.states["shield_phase_hide_start"] = State{
    name = "shield_phase_hide_start",
    tags = {"busy", "nosleep", "hide_pre", "nofreeze"}, -- TODO better tag name for hide_pre, used in shield behavior

    onenter = function(inst)
        inst.sg:AddStateTag("nointerrupt")
        inst.Physics:Stop()
        inst.AnimState:PlayAnimation("hide_pre")

        inst.is_using_shield = true
    end,

    timeline = {
		TimeEvent(7*FRAMES, function(inst) --TODO need to verify the accuracy of this
			inst.sg:AddStateTag("nointerrupt")
		end),
		TimeEvent(10*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.hide_pre) -- TODO change name, hide_pre to start_hiding?
        end),
    },

    onexit = function(inst)
        --Leo: Adding this here incase mobs (like snortoise) become "invincible" mid state and it gets interrupted.
        inst.components.health:SetAbsorptionAmount(0)
        inst.components.sleeper:SetResistance(1)
    end,

    events = {
        EventHandler("animover", function(inst)
            inst.sg:GoToState("shield_phase_hiding")
        end),
    },
}


local QUAKE_ACTIVATE_TIME = 5
local INITIAL_TIME = 0

lifebloom_boarilla_sg.states["shield_phase_hiding"] = State{
    name = "shield_phase_hiding",
    tags = {"busy", "hiding", "nosleep", "nofreeze"},

    onenter = function(inst)
        inst.sg:AddStateTag("nostun")
        inst.sg:AddStateTag("nosleep")
        inst.sg:AddStateTag("nointerrupt")

        inst.Physics:SetMass(0)
        
        inst.components.debuffable:RemoveDebuff("shield_buff", "shield_buff")
        inst.components.sleeper:SetResistance(9999)
        inst.components.health:SetAbsorptionAmount(inst.hide_absorption or 1)

        if inst.quaketask == nil then
            inst.quaketask = inst:DoPeriodicTask(QUAKE_ACTIVATE_TIME, QuakeDebuffAndDamage, INITIAL_TIME)
        end

        inst.Physics:Stop()
        inst.AnimState:PlayAnimation("hide_loop")
    end,

    onexit = function(inst)
        inst.Physics:SetMass(500)
        inst.components.health:SetAbsorptionAmount(0)
        inst.components.sleeper:SetResistance(1)
    end,

    events = {
        EventHandler("animover", function(inst)
            inst.sg:GoToState("shield_phase_hiding")
        end),
    },
}   








local function OnEnterShieldPhase(inst, data)
    inst.sg:GoToState("enter_shield_phase", data)
end
lifebloom_boarilla_sg.events["enter_shield_phase"] = EventHandler("enter_shield_phase", OnEnterShieldPhase)



local function OnEnterForceKnockbackPhase(inst, data)
    StopQuakeAOE(inst)
    RemoveAllQuakeDebuff(inst)
    inst.sg:GoToState("knockback", data)
end
lifebloom_boarilla_sg.events["force_knockback"] = EventHandler("force_knockback", OnEnterForceKnockbackPhase)



COMMON_FNS.ApplyStategraphPostInits(lifebloom_boarilla_sg)
return lifebloom_boarilla_sg