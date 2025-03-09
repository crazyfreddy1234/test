--[[
local directional_reticules = {
    reticulelong = true,
    reticulelongmulti = true,
    reticuleline = true,
    reticulearc = true,
}
]]--


--[[
AddComponentPostInit("aoetargeting",function(self)
    self.GetMouseTargetX = function(self, mouse_x, x)
        return self.inst.replica.inventoryitem:IsHeldBy(_G.ThePlayer) and _G.ThePlayer.debuff_flower_def:value() and (-mouse_x + x) or (mouse_x - x)
    end
      
    self.GetMouseTargetZ = function(self, mouse_z, z)
        return self.inst.replica.inventoryitem:IsHeldBy(_G.ThePlayer) and _G.ThePlayer.debuff_flower_def:value() and (-mouse_z + z) or (mouse_z - z)
    end

end)
]]--


--[[
AddPlayerPostInit(function(inst)
    
    inst.debuff_flower_def = _G.net_bool(inst.GUID, "player.debuff_flower_def")
    inst.debuff_flower_def:set(false)
    

    if not _G.TheNet:IsDedicated() then
        inst.SetAlphaPrefab = function(prefab,alpha)
            if prefab and prefab.AnimState and alpha then
                prefab.AnimState:OverrideMultColour(1, 1, 1, alpha)
            end
        end
    end
    
end)
]]--


--[[
local actions = {
    KEY_1 = function(arg1, arg2) 
        -- do stuff for KEY_1 using arg1 and arg2
    end,
    KEY_2 = function(arg1, arg2) 
        -- do stuff for KEY_2 using arg1 and arg2
    end,
    KEY_3 = function(arg1, arg2) 
        -- do stuff for KEY_3 using arg1 and arg2
    end,
    KEY_4 = function(arg1, arg2) 
        -- do stuff for KEY_4 using arg1 and arg2
    end,
    KEY_5 = function(arg1, arg2) 
        -- do stuff for KEY_5 using arg1 and arg2
    end,
    KEY_6 = function(arg1, arg2) 
        -- do stuff for KEY_6 using arg1 and arg2
    end,
    KEY_7 = function(arg1, arg2) 
        -- do stuff for KEY_7 using arg1 and arg2
    end,
    KEY_8 = function(arg1, arg2) 
        -- do stuff for KEY_8 using arg1 and arg2
    end,
    KEY_9 = function(arg1, arg2) 
        -- do stuff for KEY_9 using arg1 and arg2
    end,
}

local key = "KEY_1"  -- Assume this is determined by your logic
local extraArg1 = "example1"
local extraArg2 = "example2"

if actions[key] then
    actions[key](extraArg1, extraArg2)  -- Call the function with extra arguments
end



if options.ctrl == 1 then -- Suck Youth
            for count, target in pairs(TheSim:FindEntities(pos.x, pos.y, pos.z, tuning_values.ALT_RADIUS, nil, COMMON_FNS.GetAllyTags(inst), COMMON_FNS.GetEnemyTags(inst))) do
                if target and target:IsValid() and target.components.combat and target.components.health and not target.components.health:IsDead() then
                    local damage = target:HasTag("largecreature") and tuning_values.ALT_DAMAGE_LARGE or tuning_values.ALT_DAMAGE_SMALL

                    target.SoundEmitter:PlaySound("wanda2/characters/wanda/older_transition", nil, 0.6)

                    COMMON_FNS.CreateFX("oldager_become_older_fx", target, inst, { position = target:GetPosition() })

                    target.components.combat:GetAttacked(caster, damage, inst, nil, true, false, TUNING.FORGE.DAMAGETYPES.MAGIC, true)

                    if caster and caster.components.health and not caster.components.health:IsDead() then
                        local regen_duration = target:HasTag("largecreature") and tuning_values.SUCKYOUTH_HP_DURATION * 1.5 or tuning_values.SUCKYOUTH_HP_DURATION
                        local regen_hp_delta = target:HasTag("largecreature") and tuning_values.SUCKYOUTH_HP_DELTA * 2 or tuning_values.SUCKYOUTH_HP_DELTA
                        local regen_hp_tick = target:HasTag("largecreature") and tuning_values.SUCKYOUTH_HP_TICK * 2 or tuning_values.SUCKYOUTH_HP_TICK

                        Multiply hp regen rate by number of mobs affected
                        caster.components.health:StartRegen(regen_hp_delta*count, regen_hp_tick, false, "rapid_younging", "crf_time_staff")

                        caster:DoTaskInTime(regen_duration, function()
                            caster.components.health:StopRegen("rapid_younging")
                        end)
                    end
                end
            end
end
]]--