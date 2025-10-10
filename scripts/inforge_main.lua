local STRINGS = _G.STRINGS
local RF_DATA = _G.REFORGED_DATA

local env = env or GLOBAL or _G
env.Node = env.Node or {}
local _OldAddEntity = env.Node.AddEntity

local AddSGSwineclopsHard=function(sg)
    local RPXT = RPXT
    local enraged_tantrum=sg.states.enraged_tantrum
    local _onenter=enraged_tantrum.onenter
    enraged_tantrum.onenter=function(inst,data)
        _onenter(inst,data)
        local opts=inst.components.combat:GetAttackOptions("tantrum")
        if opts and opts.extrahard then
            if _G.REFORGED_SETTINGS.gameplay.waveset == "Extraordinary" then
                _G.TheWorld.state.temperature=95
            else
                _G.TheWorld.state.temperature=RPXT.EXH_TEMP_MAX
            end
        end
    end
    local _onexit=enraged_tantrum.onexit
    enraged_tantrum.onexit=function(inst)
        _onexit(inst)
        local opts=inst.components.combat:GetAttackOptions("tantrum")
        if opts and opts.extrahard then
            if _G.REFORGED_SETTINGS.gameplay.waveset == "Extraordinary" then
                _G.TheWorld.state.temperature=95
            else
                _G.TheWorld.state.temperature=RPXT.EXH_TEMP_UNDERLAY
            end
        end
    end
    local block_pst=sg.states.block_pst
    local pst_onenter=block_pst.onenter
    block_pst.onenter=function(inst,cb)
        pst_onenter(inst,cb)
        local opts=inst.components.combat:GetAttackOptions("guard")
        if opts and opts.extrahard and inst.enraged and (_G.GetTime()-inst.components.combat.laststartattacktime)>(TUNING.FORGE.SWINECLOPS.GUARD_TIME/2) then 
            inst.sg:GoToState("enraged_tantrum")
        end
    end
end
AddStategraphPostInit("swineclops_hard",AddSGSwineclopsHard)




AddComponentPostInit("rechargeable",function(self)
    local _oldGetRechargeTime = self.GetRechargeTime
    local _oldStartRecharge = self.StartRecharge
    local _oldRecalculateRate = self.RecalculateRate

    self.GetRechargeTime = function(self)
        if self.owner then
            if self.owner.components.debuffable:HasDebuff("debuff_flower_speed") then
                if self.recharge >= 10 then 
                    return (self.pickup and ((180-self.recharge)/30)) or self.maxrechargetime * self.cooldownrate
                end
                return self.pickup and 6 or (self.maxrechargetime * self.cooldownrate)
            elseif self.owner:HasTag("speed_flower_removed") then
                if not self.pickup then return self.maxrechargetime * self.cooldownrate end

                local current_value = self.recharge/180 
                local onesec_percent = (self.maxrechargetime-1)/self.maxrechargetime 

                if current_value < onesec_percent then 
                    self.rechargetime = 1
                end
                return self.pickup and ((current_value < onesec_percent) and 1 or ((1-current_value) * self.maxrechargetime)) or self.maxrechargetime * self.cooldownrate
            else
                return _oldGetRechargeTime(self)
            end
        else
            return _oldGetRechargeTime(self)
        end
    end

    self.StartRecharge = function(self)
        if self.owner and self.owner.components.debuffable:HasDebuff("debuff_flower_speed") then
            if not (self.isready or self.pickup) and self.charge_count > 0 then
                local charge_data = table.remove(self.charge_priority, 1)
                self:RemoveCooldownCharge(charge_data.source)
                self.owner:PushEvent("charge_consumed", {item = self.inst, source = charge_data.source})
            end
            self.isready = false
            if self.inst.components.aoetargeting and self.charge_count <= 0 then
                if self.inst:HasTag("targetingready") then
                    self.inst.components.aoetargeting:SetEnabled(false)
                end
            end
            self.rechargetime = self.pickup and 6 or self.maxrechargetime
            self.recharge = 0
            self.amount_charged = 0
            if self.is_timer then
                self:RecalculateRate()
                self.inst:DoTaskInTime(0, function()
                    self.inst.replica.inventoryitem:SetChargeTime(self:GetRechargeTime())
                    self.inst:PushEvent("rechargechange", { percent = self.recharge and self.recharge / 180, overtime = false })
                    _G.RemoveTask(self.updatetask)
                    self.updatetask = self.inst:DoPeriodicTask(_G.FRAMES, function() self:Update() end)
                end)
            else
                self.inst:PushEvent("forcerechargechange", {percent = self.recharge and self.recharge / 180, overtime = false})
            end
        else
            _oldStartRecharge(self)
        end
    end
end)

local function GoggleVisonEnableDirty(inst)
    if inst.components.playervision then
        inst.components.playervision:ForceGoggleVision(inst.GoggleVisonEnable:value())
    end
    if inst and inst.HUD and inst.HUD.controls and _G.REFORGED_SETTINGS.gameplay.mutators["no_hud"] == false then
        if inst.GoggleVisonEnable:value() == true then
            inst.HUD.controls.status:Hide()
            inst.HUD.controls.teamstatus:Hide()
            inst.HUD.controls:HideCraftingAndInventory()

            inst.HUD.controls._oldShowCraftingAndInventory = inst.HUD.controls.ShowCraftingAndInventory
            inst.HUD.controls.ShowCraftingAndInventory = function() end
        elseif inst.GoggleVisonEnable:value() == false or inst.GoggleVisonEnable:value() == nil then
            inst.HUD.controls.ShowCraftingAndInventory = inst.HUD.controls._oldShowCraftingAndInventory
            inst.HUD.controls._oldShowCraftingAndInventory = nil

            inst.HUD.controls.status:Show()
            inst.HUD.controls.teamstatus:Show()
            inst.HUD.controls:ShowCraftingAndInventory()
        end
    end
end

local function FumeOver_RedEnableDirty(inst)
    local Inf_BloodOver = require "widgets/inf_bloodover"

    if inst.FumeOver_RedEnable:value() == true and inst.HUD and inst.HUD.fumeover_red == nil then
        inst.HUD.fumeover_red = inst.HUD.overlayroot:AddChild(Inf_BloodOver(inst))
        inst.HUD.fumeover_red:TurnOn()
    elseif inst.FumeOver_RedEnable:value() == false and inst.HUD and inst.HUD.fumeover_red ~= nil then
        inst.HUD.fumeover_red:TurnOff()
        inst.HUD.fumeover_red = nil
    end   
end

local function FXSound_VolumeDirty(inst)
    if not (_G.ThePlayer ~= nil and inst == _G.ThePlayer) then
        return
    end

    if inst.FXSound_Volume:value() then
		_G.TheMixer:PushMix("infernal_silence")
	else	
		_G.TheMixer:PopMix("infernal_silence")
	end
end

local function InfernalPowerDirty(inst)
    local inst_hud = inst.HUD
    if inst.HUD and inst.HUD.controls.status.powerwidget and inst.components.infernal_power then
        local powerwidget = inst.HUD.controls.status.powerwidget
        local getmaxpower = inst.components.infernal_power:GetMaxPower() or 100
        powerwidget:SetValue(inst.InfernalPower:value(),getmaxpower)
    end
end

local function SpawnShieldFX(target)
    local armor_icon = _G.SpawnPrefab("forgedebuff_fx")
    local target_pos = target:GetPosition()
    armor_icon.Transform:SetPosition(target_pos.x,2,target_pos.z)
end

local function AddDamageDebuffToMobs(target)
    if target.power_tank_debuff ~= nil then
        _G.RemoveTask(target, "power_tank_debuff")
        target.power_tank_debuff = nil
    end

    target.components.combat:AddDamageBuff("power_atk_debuff", 0.5)
    target.AnimState:OverrideMultColour(1, 1, 1, 0.7)

    target.power_tank_debuff = target:DoTaskInTime(8,function(inst)
        target.AnimState:OverrideMultColour(1, 1, 1, 1)
        target.components.combat:RemoveDamageBuff("power_atk_debuff")
    end)
end

local function RemoveStunLock(target)
    if target.removestunlock ~= nil then
        _G.RemoveTask(target, "removestunlock")
        target.removestunlock = nil
    end

    target.components.combat:SetPlayerStunlock(_G.PLAYERSTUNLOCK.NEVER)
    if target.components.combat.onhitotherfn ~= nil then
        target.knockbackfun = target.components.combat.onhitotherfn
        target.components.combat.onhitotherfn = nil
    end
    
    target.removestunlock = target:DoTaskInTime(8,function(inst)
        inst.components.combat:SetPlayerStunlock(_G.PLAYERSTUNLOCK.ALWAYS)
        if target.knockbackfun ~= nil and target.components.combat.onhitotherfn == nil then
            target.components.combat.onhitotherfn = target.knockbackfun
        end
    end)
end

local function UseOneKey(player,key)
    if player.components.health:IsDead() == true then return end
    local power = player.components.infernal_power
    local handitem = player.components.inventory and player.components.inventory:GetEquippedItem(_G.EQUIPSLOTS.HANDS) or nil
    local powervalue = 0
    
    if key == "KEY_1" then
        powervalue = 15
        if (power and power:GetPower() >= powervalue) and (handitem and handitem.components.itemtype.types) then
            power:DoDelta(-powervalue)

            for i,j in pairs(handitem.components.itemtype.types) do
                if tostring(i) == "melees" then
                    local pos = player:GetPosition()
                    local targets = _G.COMMON_FNS.EQUIPMENT.GetAOETargets(player, pos, 4.5, nil, _G.COMMON_FNS.GetPlayerExcludeTags(player))

                    for _,target in pairs(targets) do
                        if target.components.combat then
                            SpawnShieldFX(target)
                            AddDamageDebuffToMobs(target)
                            RemoveStunLock(target)
                        end
                    end
                else
                    handitem.components.rechargeable:FinishRecharge()
                end
            end
        end
    elseif key == "KEY_2" then
        powervalue = 10

        if (power and power:GetPower() >= powervalue) and (handitem and handitem.components.itemtype.types) then
            player.components.infernal_power:DoDelta(-powervalue)

            local pos = player:GetPosition()
            local targets = _G.COMMON_FNS.EQUIPMENT.GetAOETargets(player, pos, 4, nil, _G.COMMON_FNS.GetPlayerExcludeTags(player))

            for _,target in pairs(targets) do
                if target.components.combat then
                    target.components.combat:SetTarget(player)
                end
            end
        end
    elseif key == "KEY_3" then
        player.components.infernal_skill:Active()
    elseif key == "KEY_4" then
        if (handitem and handitem.components.itemtype.types) then
            for i,j in pairs(handitem.components.itemtype.types) do
                if tostring(i) == "melees" then
                    if player.aggroaoe == nil then
                        player.aggroaoe = _G.SpawnPrefab("reticuleaoe")
                        player.aggroaoe.entity:SetParent(player.entity)
                    else
                        player.aggroaoe:Remove()
                        player.aggroaoe = nil
                    end
                end
            end
        end
    end
end

local function ShowPowerUI(inst)
    if inst.HUD and inst.HUD.controls.status.powerwidget then
        local powerwidget = inst.HUD.controls.status.powerwidget
        
        powerwidget.circleframe:GetAnimState():PlayAnimation("open")
        powerwidget.circleframe:Show()
        powerwidget.anim:Show()
        powerwidget.num:Show()
    end
    if inst.HUD and inst.HUD.controls.status.skillwidget then
        local skillwidget = inst.HUD.controls.status.skillwidget
        
        skillwidget.backing:GetAnimState():PlayAnimation("close")
        skillwidget.circleframe:GetAnimState():PlayAnimation("open")
        skillwidget.circleframe:Show()
        skillwidget.anim:Show()
        skillwidget.num:Show()
    end
end

local function HidePowerUI(inst)
    if inst.HUD and inst.HUD.controls.status.powerwidget then
        local powerwidget = inst.HUD.controls.status.powerwidget
        
        powerwidget.circleframe:GetAnimState():PlayAnimation("close")
        powerwidget.circleframe:Hide()
        powerwidget.anim:Hide()
        powerwidget.num:Hide()
    end
    if inst.HUD and inst.HUD.controls.status.skillwidget then
        local skillwidget = inst.HUD.controls.status.skillwidget
        
        skillwidget.backing:GetAnimState():PlayAnimation("close")
        skillwidget.circleframe:GetAnimState():PlayAnimation("close")
        skillwidget.circleframe:Hide()
        skillwidget.anim:Hide()
        skillwidget.num:Hide()
    end
end

local function HealSelf(inst)
    if inst.components.health:IsDead() == true then return end
    local power = inst.components.infernal_power
    local handitem = inst.components.inventory and inst.components.inventory:GetEquippedItem(_G.EQUIPSLOTS.HANDS) or nil

    if power and (handitem and handitem.components.itemtype.types) then
        for i,j in pairs(handitem.components.itemtype.types) do
            if tostring(i) == "melees" then
                if inst.components.health:GetPercent() <= 0.5 then
                    inst.components.health:DoDelta(40)
                else
                    inst.components.health:DoDelta(20)
                end
            end
        end
    end
end

local function MakeSkill(inst)  
    inst.components.infernal_skill:SetSkillToActive()
    inst.components.infernal_skill:SetCost(40)
    inst.components.infernal_skill:SetMaxCoolDown(10)
    inst.components.infernal_skill:SetBackgroundColor(0,1,1/2,1)
    inst.components.infernal_skill:SetSkill(HealSelf)
end 

local function PowerTurnOn(inst)
    if inst.components.infernal_power == nil then
        inst:AddComponent("infernal_power")
    end
    if inst.components.infernal_skill == nil then
        inst:AddComponent("infernal_skill")
        MakeSkill(inst)
    end
---------------------------------------------------------------------------------    
    inst.components.infernal_power:SetPower(0)
    inst.components.infernal_power:ActiveDownPerSec()
    inst.components.infernal_power:DoDelta(10)
---------------------------------------------------------------------------------
    inst.GainPower = function(inst,data)
        if inst.components.infernal_power then 
            inst.components.infernal_power:DoDelta(3)
        end
    end

    inst:ListenForEvent("onhitother", inst.GainPower)
---------------------------------------------------------------------------------
    inst.useonekey  = _G.TheInput:AddKeyUpHandler(_G.KEY_1, function()
        if not (_G.ThePlayer ~= nil and inst == _G.ThePlayer) then
            return
        end

        SendModRPCToServer(GetModRPC("Infernal_Forge_RPC", "UsePower"),"KEY_1")
    end)
    inst.usetwokey = _G.TheInput:AddKeyUpHandler(_G.KEY_2, function()
        if not (_G.ThePlayer ~= nil and inst == _G.ThePlayer) then
            return
        end

        SendModRPCToServer(GetModRPC("Infernal_Forge_RPC", "UsePower"),"KEY_2")
    end)
    inst.usethreekey = _G.TheInput:AddKeyUpHandler(_G.KEY_3, function()
        if not (_G.ThePlayer ~= nil and inst == _G.ThePlayer) then
            return
        end

        SendModRPCToServer(GetModRPC("Infernal_Forge_RPC", "UsePower"),"KEY_3")
    end)
    inst.usefourkey = _G.TheInput:AddKeyUpHandler(_G.KEY_4, function()
        if not (_G.ThePlayer ~= nil and inst == _G.ThePlayer) then
            return
        end

        SendModRPCToServer(GetModRPC("Infernal_Forge_RPC", "UsePower"),"KEY_4")
    end)
---------------------------------------------------------------------------------
    ShowPowerUI(inst)

    inst.PowerHideByDeath = inst:ListenForEvent("death",HidePowerUI)
    inst.PowerShowByRevive = inst:ListenForEvent("respawnfromcorpse",ShowPowerUI)
---------------------------------------------------------------------------------
end

local function PowerTurnOff(inst)
    if inst.components.infernal_power ~= nil then
        inst.components.infernal_power:SetPower(0)
        inst.components.infernal_power:DeactiveDownPerSec()
    end
---------------------------------------------------------------------------------
    if inst.GainPower ~= nil then
        inst:RemoveEventCallback("onhitother", inst.GainPower)
        inst.GainPower = nil
    end
---------------------------------------------------------------------------------
    if inst.usefirstkey ~= nil then
        inst.usefirstkey = nil
    end
    if inst.usesecondkey ~= nil then
        inst.usesecondkey = nil
    end
    if inst.usefourkey ~= nil then
        inst.usefourkey = nil
    end
---------------------------------------------------------------------------------
    HidePowerUI(inst)
    if inst.PowerHideByDeath ~= nil then
        inst:RemoveEventCallback("death",HidePowerUI)
        inst.PowerHideByDeath = nil
    end
    if inst.PowerShowByRevive ~= nil then
        inst:RemoveEventCallback("respawnfromcorpse",ShowPowerUI)
        inst.PowerShowByRevive = nil
    end
---------------------------------------------------------------------------------
end

local function PowerOnOffDirty(inst)
    if inst.PowerOnOff:value() == true then
        PowerTurnOn(inst)
    else
        PowerTurnOff(inst)
    end
end

local function EnablePowerOnServer(inst)
    local ispower = _G.REFORGED_DATA.wavesets[_G.REFORGED_SETTINGS.gameplay.waveset].power_on

    if ispower and ispower == true then
        inst.PowerOnOff:set(true)
    end
end

local function SetHealthNet(inst)
    if inst.net_health_percent then
        local percent = inst.components.health:GetPercent()
        inst.net_health_percent:set(percent)
    end
end


local function OnHealthDelta(inst, data)
    if not _G.TheWorld.ismastersim then
        return
    end

    SetHealthNet(inst)            --체력변화용
end

AddPlayerPostInit(function(inst)
    inst.MobsPlayersAlpha = _G.net_float(inst.GUID, "MobsPlayersAlpha")
    inst.MobsPlayersShadowEnable = _G.net_bool(inst.GUID, "MobsPlayersShadowEnable")
    inst.GoggleVisonEnable = _G.net_bool(inst.GUID, "GoggleVisonEnable", "gogglevisonenabledirty")
    inst.FumeOver_RedEnable = _G.net_bool(inst.GUID, "FumeOver_RedEnable", "fumeover_redenabledirty")   
    inst.FXSound_Volume = _G.net_bool(inst.GUID, "FXSound_Volume", "fxsound_volumedirty")   
    inst.InfernalPower = _G.net_float(inst.GUID, "InfernalPower","infernalpowerdirty")
    inst.PowerOnOff = _G.net_bool(inst.GUID, "PowerOnOff", "poweronoffdirty")

    inst.MobsPlayersAlpha:set(1)
    inst.MobsPlayersShadowEnable:set(true)
    inst.GoggleVisonEnable:set(false)
    inst.FumeOver_RedEnable:set(false)
    inst.FXSound_Volume:set(false)
    inst.InfernalPower:set(0)

    inst:ListenForEvent("infernalpowerdirty",InfernalPowerDirty)
    inst:ListenForEvent("fxsound_volumedirty", FXSound_VolumeDirty)
    inst:ListenForEvent("gogglevisonenabledirty", GoggleVisonEnableDirty)
    inst:ListenForEvent("fumeover_redenabledirty", FumeOver_RedEnableDirty)
    inst:ListenForEvent("poweronoffdirty",PowerOnOffDirty)
    inst.PowerOnOff:set(false)
    inst:ListenForEvent("player_portal_spawn", EnablePowerOnServer)


    -----------------------------------------------------------------------------------------------------------------------------

    --[[

    inst.net_health_percent = _G.net_float(inst.GUID, "playerhud.net_health_percent", "healthdirty")
    inst.net_health_percent:set(1)
    
    if _G.TheWorld.ismastersim then
        inst:ListenForEvent("healthdelta", OnHealthDelta)
        inst:DoTaskInTime(0,function(inst)
            SetHealthNet(inst)                --(본인)재접용
        end)
    end

    if not _G.TheNet:IsDedicated() then
        inst:DoTaskInTime(0, function()
            if inst.HUD then
                inst.HUD.teammatehud = inst.HUD:AddChild(require("widgets/teamhud")(inst))
            end
        end)
    end

    ]]--

    -----------------------------------------------------------------------------------------------------------------------------

    local function RemoveAllTypeTag(player)
        local types = {"TANK","HEALER","MDPS","RDPS"}

        for i,v in pairs(types) do
            if player:HasTag(v) then
                player:RemoveTag(v)
            end
        end
    end

    local function CheckWeaponType(player, item)
        local types = {"TANK","HEALER","MDPS","RDPS"}
        local isType = false

        for i,v in pairs(types) do
            if item:HasTag(v) then
                player:AddTag(v)
                isType = true
            end
        end

        if isType ~= true then
            player:AddTag("RDPS")
        end
    end




    inst._stack_count = _G.net_shortint(inst.GUID, "inf.stack", "inf_stackdirty")
    inst._Update_Stack = _G.net_bool(inst.GUID, "inf.updatestac", "inf_updatestackdirty")
    inst._stack_count:set(-1)  ---- -1 is not a normal number. it means there is no stack in this weapon. So display will be disappear

    local function CheckFinishRecharge(inst, data)
        if data.stack and data.owner then
            data.owner._stack_count:set(data.stack)
        end
    end

    local function OnEquip(inst, data)
        
        RemoveAllTypeTag(inst)

        if data ~= nil and data.item ~= nil then
            local item = data.item

            CheckWeaponType(inst, item)
        else
            inst:AddTag("RDPS")
        end
    ----------------------------------------------------------------------

        inst:DoTaskInTime(0,function()
            if data ~= nil and data.item ~= nil 
            and data.item.components.rechargeable ~= nil and data.item.components.rechargeable:GetMaxStack() < 2 then
                if inst and inst.stackdisplay ~= nil then
                    inst._stack_count:set(-1)
                    return
                end
            end

            if not (data.item.components.equippable and data.item.components.equippable.equipslot == _G.EQUIPSLOTS.HANDS) then
                return
            end

            if inst and inst.stackdisplay ~= nil then
                inst.stackdisplay:UpdateText()
            end

            if inst and inst:IsValid() and inst._stack_count ~= nil
                and data ~= nil and data.item ~= nil 
                and data.item.components.rechargeable ~= nil and data.item.components.rechargeable:GetMaxStack() >= 2 then

                local current_stack = data.item.components.rechargeable:GetCurrentStack()

                inst._stack_count:set(current_stack)

                data.item:ListenForEvent("rechargechange", CheckFinishRecharge)
            end
        end)
    end


    local function OnUnequip(inst, data)
        if data ~= nil and data.item ~= nil then
            if not (data.item.components.equippable and data.item.components.equippable.equipslot == _G.EQUIPSLOTS.HANDS) then
                return
            end

            data.item:RemoveEventCallback("rechargechange", CheckFinishRecharge)

            if inst and inst.stackdisplay ~= nil then
                inst.stackdisplay:HideText()
            end
        end
    end

    inst:ListenForEvent("equip", OnEquip)
    inst:ListenForEvent("unequip", OnUnequip)
end)

AddModRPCHandler("Infernal_Forge_RPC", "UsePower", UseOneKey)



AddComponentPostInit("lavaarenaevent",function(self)
    local old_StartRound = self.StartRound

    self.StartRound = function(self,round,wave)
        if _G.INFORGE_COMMON_FNS.IsDungeon() then
            if self.wavemanager and self.wavemanager.onexit then
                self.wavemanager.onexit(self)
            end
            self.inst:StopUpdatingComponent(self)
            self.current_round_data = nil
        
            -- Apply any additional changes for next set of rounds (endless)
            if round == 1 and self.total_rounds_completed >= #self.waveset_data and self.endless_fn then
                self.endless_fn(math.floor(self.total_rounds_completed / #self.waveset_data))
            end
        
            -- Update current round data
            self.current_round = round
            self.inst.components.forgemobtracker:SetRound(self.current_round)
            self.current_round_data = self.waveset_data[round]
            if not self.current_round_data then
                Debug:Print("Unable to start round " .. tostring(self.current_round) .. ". No round data found.", "warning") -- TODO need a formal warning/error message that is used throughout the mod to make it easier for modders and users to find and understand possible issues
                return
            end
            if not self.current_round_data.roundend then
                self.current_round_data.roundend = _G.UTIL.WAVESET.defaultroundend
            end
            if not self.current_round_data.banner then
                self.current_round_data.banner = _G.UTIL.WAVESET.defaultbanner()
            end
        
            -- Force start occurs if wave was given and is greater than 1
            local forced_start = wave and wave > 1
            self:SetWaveManager(not forced_start and self.current_round_data.wavemanager)
        
            -- Start round
            --[[
            if not forced_start then
                self.wavemanager.onenter(self)
                if type(self.wavemanager.onupdate) == "function" then
                    self.inst:StartUpdatingComponent(self)
                end
            -- Force start the given wave
            else
                self:QueueWave(wave, true)
            end
            ]]--
        else
            return old_StartRound(self,round,wave)
        end
    end
end)


_G.AddDebuff("debuff_flower_dmg",   {atlas = "images/debuff_flower_dmg.xml", tex = "debuff_flower_dmg.tex"})
_G.AddDebuff("debuff_flower_def",   {atlas = "images/debuff_flower_def.xml", tex = "debuff_flower_def.tex"})
_G.AddDebuff("debuff_flower_speed", {atlas = "images/debuff_flower_speed.xml", tex = "debuff_flower_speed.tex"})
_G.AddDebuff("debuff_flower_regen", {atlas = "images/debuff_flower_regen.xml", tex = "debuff_flower_regen.tex"})
_G.AddDebuff("debuff_flower_unhit", {atlas = "images/debuff_flower_unhit.xml", tex = "debuff_flower_unhit.tex"})
_G.AddDebuff("debuff_inferno",      {atlas = "images/debuff_inferno.xml", tex = "debuff_inferno.tex"})

--_G.AddMap("my_map", "MY_MAP", 3)
_G.AddMap("chapter1_cave", "CHAPTER1_CAVE", 3)

local CH1_CAVE = RF_DATA.maps.chapter1_cave

CH1_CAVE.is_dungeon = true
CH1_CAVE.must_waveset = "Reflection"


local function FindPlayerByUserID(userid)
    for i, player in ipairs(_G.AllPlayers) do
        if player.userid == userid then
            return player
        end
    end

    return nil
end

AddModRPCHandler("Infernal_Forge_RPC", "item_click", function(user, target_userid)
    local target = FindPlayerByUserID(target_userid)
    local item = user.components.inventory and user.components.inventory:GetEquippedItem(_G.EQUIPSLOTS.HANDS)

    _G.INFORGE_COMMON_FNS.FindTargetsPriority(user, 10, 1, 1, 2, 3, 10)

    if target and item and item.components.infernal_weaponskill then
        item.components.infernal_weaponskill:Cast_LClick(item, user, target)
    end
end)

AddModRPCHandler("Infernal_Forge_RPC", "item_right_click", function(user, target_userid)
    local target = FindPlayerByUserID(target_userid)
    local item = user.components.inventory and user.components.inventory:GetEquippedItem(_G.EQUIPSLOTS.HANDS)

    if target and item and item.components.infernal_weaponskill then
        item.components.infernal_weaponskill:Cast_RClick(item, user, target)
    end
end)



AddComponentPostInit("rechargeable", function(self)
    if self.pickup_cooldown == nil then return end

    self.inst:AddTag("multi_recharge")

	-- 
	self.max_stacks = 1
    self.current_stacks = 1
    self.recharge_queue = {}
    self.inforge_owner = nil



    local Old_StartRecharge = self.StartRecharge
    self.StartRecharge = function(self)
        if self.max_stacks ~= nil and self.max_stacks > 1 then
            self.inst:DoTaskInTime(0,function()
                if not (self.isready or self.pickup) and self.charge_count > 0 then
                    local charge_data = table.remove(self.charge_priority, 1)
                    self:RemoveCooldownCharge(charge_data.source)
                    self.owner:PushEvent("charge_consumed", {item = self.inst, source = charge_data.source})
                end

                if self.current_stacks <= 0 then
                    self.isready = false
                end

                if self.inst.components.aoetargeting and (self.current_stacks <= 0 or self.pickup) then
                    self.inst.components.aoetargeting:SetEnabled(false)
                end


                if self.updatetask ~= nil then
                    return
                end

                self.rechargetime = self.pickup and self.pickup_cooldown or self.maxrechargetime
                self.recharge = 0
                self.amount_charged = 0

                if self.is_timer then
                    self:RecalculateRate()

                    self.inst:DoTaskInTime(0, function()
                        self.inst.replica.inventoryitem:SetChargeTime(self:GetRechargeTime())
                        self.inst:PushEvent("rechargechange", { percent = self.recharge and self.recharge / 180, overtime = false })
                        _G.RemoveTask(self.updatetask)
                        self.updatetask = self.inst:DoPeriodicTask(_G.FRAMES, function() self:Update() end)
                    end)

                else
                    self.inst:PushEvent("forcerechargechange", { percent = 0, overtime = true })
                end
            end)
        else
            Old_StartRecharge(self)
        end
    end

	function self:UseCharge()
        if self.current_stacks <= 0 then return false end

        self.current_stacks = math.max(self.current_stacks - 1, 0)

        --[[

        if self.current_stacks <= 0 then
            self.isready = false
        end

        
        if self.inst.components.aoetargeting and self.current_stacks <= 0 then
            self.inst.components.aoetargeting:SetEnabled(false)
        end
        ]]--

        table.insert(self.recharge_queue, true)

        self:UpdateHUD()
        return true
    end

    -- ✅ 기존 FinishRecharge 후 다음 큐 시작
    local _FinishRecharge = self.FinishRecharge
    self.FinishRecharge = function(...)
        if _FinishRecharge then _FinishRecharge(self, ...) end

        self.current_stacks = math.min(self.current_stacks + 1, self.max_stacks)
        table.remove(self.recharge_queue, 1)
 
        if #self.recharge_queue > 0 then
            self:StartRecharge() -- 다음 큐 실행
        end

        self:UpdateHUD()
    end

    function self:UpdateHUD()
        self.inst:PushEvent("rechargechange", { percent = self.recharge and self.recharge / 180, overtime = false, stack = self.current_stacks, owner = self.owner and self.owner or nil})
    end

    function self:SetMaxStack(stack)
        self.max_stacks = stack
        self.current_stacks = stack
    end

    function self:GetMaxStack() 
        return self.max_stacks or 1
    end

    function self:GetCurrentStack() 
        return self.current_stacks or 1
    end



    local function UseChargeFn(inst, data)
        self:UseCharge()
    end

    self.inst:ListenForEvent("equipped", function(inst, data)
        self.inforge_owner = data.owner

        self.inforge_owner:ListenForEvent("spell_complete",UseChargeFn)
    end)

    self.inst:ListenForEvent("unequipped", function(inst, data)
        self.inforge_owner:RemoveEventCallback("spell_complete", UseChargeFn)
        self.inforge_owner = nil
    end)
end)



--[[
local function OnCustomKeyControl(inst)
    local x, y = -30, -465
    inst:DoPeriodicTask(0, function()
        if inst.stackdisplay ~= nil then
            if _G.TheInput:IsControlPressed(_G.CONTROL_MOVE_LEFT) then
                x = x - 1
                inst.stackdisplay:SetPosition(x,y)
                print(x,y)
            elseif _G.TheInput:IsControlPressed(_G.CONTROL_MOVE_RIGHT) then
                x = x + 1
                inst.stackdisplay:SetPosition(x,y)
                print(x,y)
            elseif _G.TheInput:IsControlPressed(_G.CONTROL_MOVE_DOWN) then
                y = y - 1
                inst.stackdisplay:SetPosition(x,y)
                print(x,y)
            elseif _G.TheInput:IsControlPressed(_G.CONTROL_MOVE_UP) then
                y = y + 1
                inst.stackdisplay:SetPosition(x,y)
                print(x,y)
            end
        end
    end)
end

AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(_G.FRAMES,function()
        if inst then
            OnCustomKeyControl(inst)
        end
    end)
end)
]]--




AddPlayerPostInit(function(inst)
    inst.stackdebuff_data   = _G.net_string(inst.GUID, "stackdebuff_data", "stackdebuff_data_dirty")
    inst.stackdebuff_update = _G.net_bool(inst.GUID, "stackdebuff_update", "stackdebuff_update_dirty")

    inst.stackdebuff_update:set(false)
end)


AddComponentPostInit("debuff",function(self)
    self.current_stack = 0;
    self.max_stack = 1;
    self.min_stack = 0;

    self.debuff_stack = _G.net_tinybyte(self.inst.GUID, "debuff.stack", "debuff_stack_dirty")

    local function StackChange(self, inst)
        if inst then
            local debuff_name = self.name

            local stack = self:GetCurrentStack() or 0

            local stackdebuff_str = string.format("{%s=%s}", tostring(debuff_name), tostring(stack))
            local name, stk = string.match(stackdebuff_str, "{([^=]+)=([^}]+)}")

            inst.stackdebuff_data:set(stackdebuff_str)
            inst.stackdebuff_update:set(not inst.stackdebuff_update:value())
        end
    end
    
    function self:SetMaxStack(stack)
        self.max_stack = stack
    end

    function self:GetMaxStack()
        return self.max_stack
    end

    function self:SetMinStack(stack)
        self.min_stack = stack
    end

    function self:GetMinStack()
        return self.min_stack
    end

    function self:AddStack(val)
        local result = math.max(self.min_stack, math.min(self.current_stack + val, self.max_stack))

        if result ~= nil then
            self.current_stack = result;
            StackChange(self, self.target)
        end
    end

    function self:GetCurrentStack()
        return self.current_stack or 0
    end

end)

AddComponentPostInit("playercontroller",function(self)
    local Old_OnRightClick = self.OnRightClick

    self.OnRightClick = function(self, down)
        if not self:UsingMouse() then
            return
        elseif not down then
            if self:IsEnabled() then
                self:RemoteStopControl(_G.CONTROL_SECONDARY)
            end
            return
        end

        self:ClearActionHold()

        self.startdragtime = nil
        self.startdoubleclicktime = nil

        if self.placer_recipe ~= nil then
            self:CancelPlacement()
            return
        elseif self:IsAOETargeting() then
            self:CancelAOETargeting()
            return
        elseif not self:IsEnabled() or _G.TheInput:GetHUDEntityUnderMouse() ~= nil then
            return
        end

        self.actionholdtime = _G.GetTime()
        

        Old_OnRightClick(self, down)
    end
end)

local start_healing = _G.Action({priority = 10, distance = 20})
start_healing.str = "Start Healing"
start_healing.id = "START_CHANNEL_HEALING"
start_healing.fn = function(act)
    if act.doer and act.doer.components.channelcaster then
		if act.invobject == nil then
			--off-hand channel casting
			return act.doer.components.channelcaster:StartChanneling()
		elseif act.invobject.components.channelcastable and not act.invobject.components.channelcastable:IsAnyUserChanneling() then
			--equipped item channel casting
			return act.doer.components.channelcaster:StartChanneling(act.invobject)
		end
	end
	return true
end
AddAction(start_healing)

local stop_healing = _G.Action({priority = 10, distance = 20})
stop_healing.str = "Stop Healing"
stop_healing.id = "STOP_CHANNEL_HEALING"
stop_healing.fn = function(act)
    if act.invobject and
		act.invobject.components.channelcastable and
		act.invobject.components.channelcastable:IsUserChanneling(act.doer)
	then
		act.invobject.components.channelcastable:StopChanneling()
	end
	return true
end
AddAction(stop_healing)

local change_staff_mode = _G.Action({priority = 10, distance = 20})
change_staff_mode.str = "Change Staff Mode"
change_staff_mode.id = "CASTSPELL_LIVESTAFF"
change_staff_mode.fn = function(act)
    if act.invobject and
		act.invobject.components.channelcastable and
		act.invobject.components.channelcastable:IsUserChanneling(act.doer)
	then
		act.invobject.components.channelcastable:StopChanneling()
	end

    if act.invobject and act.invobject.staff_mode then
        local reverse_staff_mode = not act.invobject.staff_mode:value()

        act.invobject.staff_mode:set(reverse_staff_mode)
    end
    
	return true
end
AddAction(change_staff_mode)



AddComponentAction("POINT", "channelcastable", function(inst, doer, pos, actions, right, target)
    if right then
        if doer.Inforge_Skill_Key:value() == "nil" then
            if inst:HasTag("startchaneeling") then
                table.insert(actions, _G.ACTIONS.STOP_CHANNEL_HEALING)
            elseif not inst:HasTag("startchaneeling") then
                table.insert(actions, _G.ACTIONS.START_CHANNEL_HEALING)
            end
        elseif doer.Inforge_Skill_Key:value() == "SHIFT" then
            table.insert(actions, _G.ACTIONS.CASTSPELL_LIVESTAFF)
        elseif doer.Inforge_Skill_Key:value() == "CTRL" then

        elseif doer.Inforge_Skill_Key:value() == "ALT" then

        else

        end
        
    end
end)

AddStategraphActionHandler("wilson",        _G.ActionHandler(_G.ACTIONS.START_CHANNEL_HEALING, "start_channelcast_inforge"))
AddStategraphActionHandler("wilson_client", _G.ActionHandler(_G.ACTIONS.START_CHANNEL_HEALING, "start_channelcast_inforge"))

AddStategraphActionHandler("wilson",        _G.ActionHandler(_G.ACTIONS.STOP_CHANNEL_HEALING, "stop_channelcast_inforge"))
AddStategraphActionHandler("wilson_client", _G.ActionHandler(_G.ACTIONS.STOP_CHANNEL_HEALING, "stop_channelcast_inforge"))

AddStategraphActionHandler("wilson",        _G.ActionHandler(_G.ACTIONS.CASTSPELL_LIVESTAFF, "castspellmind_inforge"))
AddStategraphActionHandler("wilson_client", _G.ActionHandler(_G.ACTIONS.CASTSPELL_LIVESTAFF, "castspellmind_inforge"))


-------------------------------------------------ADD TAGS FOR MULTIPLE RETICLUE-----------------------------------
local function CheckTags(obj, tags, cant_have)
	for _,tag in pairs(tags or {}) do
		if not cant_have and not obj:HasTag(tag) then
			return false
		elseif cant_have and obj:HasTag(tag) then
			return false
		end
	end
	return true
end

local function GetState(obj, states, action)
	if not obj then return states.default end

    if obj.multiple_castaoe then
        for _,mul_action in pairs(obj.multiple_castaoe) do
            obj:RemoveTag(mul_action)
        end
        
        if action.options and action.options.ctrl then
            obj:AddTag(obj.multiple_castaoe[action.options.ctrl])
        end
    end

	for index,info in pairs(states) do
		if index ~= "default" and CheckTags(obj, info.must_tags) and CheckTags(obj, info.cant_tags, true) then
			return info.state
		end
	end
	return states.default
end

local function AltActionHandler(inst, action)
	return GetState(action.invobject, _G.TUNING.FORGE.CASTAOE_TAG_TO_STATE, action)
end

AddStategraphActionHandler("wilson",        _G.ActionHandler(_G.ACTIONS.CASTAOE, AltActionHandler))
AddStategraphActionHandler("wilson_client", _G.ActionHandler(_G.ACTIONS.CASTAOE, AltActionHandler))


AddPlayerPostInit(function(inst)
    local function CheckTagsForAttack(inst, data)
        local weapon = data.weapon or nil 
        local attack_tag = weapon and weapon.normalattack_tag or nil
        
        if weapon and attack_tag and (not weapon:HasTag(attack_tag)) then
            if weapon.multiple_castaoe then
                for _, v in pairs(weapon.multiple_castaoe) do
                    weapon:RemoveTag(v)   -- REMOVE ALL AOE TAGS. for safety
                end
            end
            weapon:AddTag(attack_tag)  -- add normal attack animation.
        end
    end

    inst:ListenForEvent("spell_complete", CheckTagsForAttack)
end)
---------------------------------------------------------------------------------------------------------

--[[
local _oldCastAOE = _G.ACTIONS.CASTAOE.fn
_G.ACTIONS.CASTAOE.fn = function(act)
    local act_pos = act:GetActionPoint()
    if act.invobject ~= nil and act.invobject.components.aoespell ~= nil and act.invobject.components.aoespell:CanCast(act.doer, act_pos) then

        if act.doer ~= nil and act.invobject and act.invobject.multiple_castaoe then
            for _,action in pairs(act.invobject.multiple_castaoe) do
                act.invobject:RemoveTag(action)
            end

            if act.options and act.options.ctrl then
                act.invobject:AddTag(act.invobject.multiple_castaoe[act.options.ctrl])
            end
        end

        act.invobject.components.aoespell:CastSpell(act.doer, act_pos, act.options)
        return true
    end
end
]]--




AddModRPCHandler("Infernal_Forge_RPC", "SendMousePos", function(player, x, z, mode)
    local pos = _G.Vector3(x, 0, z)
    local weapon = player.components.inventory:GetEquippedItem(_G.EQUIPSLOTS.HANDS)

    if weapon and mode == "healing" and weapon.heal_fn then
        weapon.heal_fn(weapon, pos)
    elseif weapon and mode == "dealing" and weapon.deal_fn then
        weapon.deal_fn(weapon, pos)
    end
end)

--[[
local CASTAOE_TAG_TUNING = TUNING.FORGE.CASTAOE_TAG_TO_STATE

CASTAOE_TAG_TUNING[13] = {
    must_tags = {"channelhealing"},
    state = "start_channelcast",
}
]]--

local INFORGE_STATES = require("inforge_state")

for _, state in ipairs(INFORGE_STATES.CLIENT_STATES) do
	AddStategraphState("wilson_client", state)
end

for _, state in ipairs(INFORGE_STATES.SERVER_STATES) do
	AddStategraphState("wilson", state)
end


local TheInput = _G.TheInput
local TheNet = _G.TheNet

-- 키 코드 → 이름 매핑
local KEY_NAMES = {
    [303] = "SHIFT",
    [304] = "SHIFT",
    [305] = "CTRL",
    [306] = "CTRL",
    [307] = "ALT",
    [308] = "ALT",
    [400] = "ALT",
    [401] = "CTRL",
    [402] = "SHIFT",
}

------------------------------------------------
-- 1. 서버에서 RPC 받는 부분
------------------------------------------------
AddModRPCHandler("Infernal_Forge_RPC", "SkillKeyState", function(player, keyname, state)
    -- keyname : SHIFT, CTRL, ALT, nil
    -- STATE   : up, down

    if state == "down" then
        player.Inforge_Skill_Key:set(keyname)
    else
        if player.Inforge_Skill_Key:value() == keyname then
            player.Inforge_Skill_Key:set("nil")
        end
    end
end)

------------------------------------------------
-- 2. 클라이언트에서 입력 감지
------------------------------------------------

local function AOEReticuleTargetFn(radius)
	return function ()
		local player = _G.ThePlayer
		local ground = _G.TheWorld.Map
		local pos = Vector3()
		--Cast range is 8, leave room for error
		--4 is the aoe range
		for r = radius, 0, -.25 do
			pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
			if ground:IsPassableAtPoint(pos:Get()) and not ground:IsGroundTargetBlocked(pos) then
				return pos
			end
		end
		return pos
	end
end

local function ReticuleUpdatePositionFn(inst, pos, reticule, ease, smoothing, dt)
    local x, y, z = inst.Transform:GetWorldPosition()
    reticule.Transform:SetPosition(x, 0, z)
    local rot = -math.atan2(pos.z - z, pos.x - x) / _G.DEGREES
    if ease and dt ~= nil then
        local rot0 = reticule.Transform:GetRotation()
        local drot = rot - rot0
        rot = Lerp((drot > 180 and rot0 + 360) or (drot < -180 and rot0 - 360) or rot0, rot, dt * smoothing)
    end
    reticule.Transform:SetRotation(rot)
end

local function ReticuleMouseTargetFn(length)
    return function (inst, mousepos)
		if mousepos ~= nil then
			local x, y, z = inst.Transform:GetWorldPosition()
			local dx = mousepos.x - x
			local dz = mousepos.z - z
			local l = dx * dx + dz * dz
			if l <= 0 then
				return inst.components.reticule.targetpos
			end
			l = length / math.sqrt(l) * (_G.ThePlayer.replica.scaler and _G.ThePlayer.replica.scaler:GetScale() or 1)
			return _G.Vector3(x + dx * l, 0, z + dz * l)
		end
	end
end

local function DirectionalReticuleTargetFn(length)
    return function ()
		return _G.Vector3(_G.ThePlayer.entity:LocalToWorldSpace(length * (_G.ThePlayer.replica.scaler and _G.ThePlayer.replica.scaler:GetScale() or 1), 0, 0))
	end
end

local SKILLKEY = {
    ["nil"]   = 1,
    ["SHIFT"] = 2,
    ["CTRL"]  = 3,
    ["ALT"]   = 4
}

local function ChangeReticule(player)
    local handitem = player and player.components.inventory and player.components.inventory:GetEquippedItem(_G.EQUIPSLOTS.HANDS) or nil
    if player.components.playercontroller and handitem and handitem.components.aoetargeting and handitem.multiple_reticule then

        local skill_key = SKILLKEY[player.Inforge_Skill_Key:value()]
        local retucule_info  = skill_key and handitem.multiple_reticule[skill_key] or nil

        if retucule_info then
            if retucule_info.type == "directional" then
                handitem.mustaoe = nil

                handitem.components.aoetargeting:SetAlwaysValid(retucule_info.alwaysvalid or true)
                handitem.components.aoetargeting.reticule.pingprefab = retucule_info.pingprefab or "reticulelongping"  --dir
                handitem.components.aoetargeting.reticule.mousetargetfn = ReticuleMouseTargetFn(retucule_info.length or 6.5)
                handitem.components.aoetargeting.reticule.updatepositionfn = ReticuleUpdatePositionFn
                handitem.components.aoetargeting.reticule.targetfn = DirectionalReticuleTargetFn(retucule_info.length or 6.5)
                handitem.components.aoetargeting.reticule.reticuleprefab = retucule_info.reticuleprefab or "reticulelong"
            elseif retucule_info.type == "aoe" then
                handitem.components.aoetargeting:SetAlwaysValid(retucule_info.alwaysvalid or false)
                handitem.components.aoetargeting.targetprefab = retucule_info.pingprefab or "reticuleaoehostiletarget" --aoe               
                handitem.components.aoetargeting.reticule.pingprefab = retucule_info.pingprefab and retucule_info.pingprefab.."ping" or "reticuleaoeping"
                handitem.components.aoetargeting.reticule.targetfn = AOEReticuleTargetFn(retucule_info.length or 7) 
                handitem.components.aoetargeting.reticule.reticuleprefab = retucule_info.reticuleprefab or "reticuleaoe"
            end
            handitem.components.aoetargeting.reticule.validcolour = retucule_info.validcolor or { 1, .75, 0, 1 } 
            handitem.components.aoetargeting.reticule.invalidcolour = retucule_info.invalidcolor or { .5, 0, 0, 1 } 
            handitem.components.aoetargeting.reticule.ease = true
            handitem.components.aoetargeting.reticule.mouseenabled = true
        end

        if handitem.components.reticule ~= nil then 
            handitem.mustaoe = nil
            for k, v in pairs(handitem.components.aoetargeting.reticule) do
                handitem.components.reticule[k] = v
            end

            if retucule_info.type == "aoe" then
                handitem.components.reticule.mousetargetfn = nil
                handitem.components.reticule.updatepositionfn = nil
            end
        else 
            if retucule_info.type == "aoe" then
                handitem.mustaoe = true
            end
        end

        handitem.isfirstAOE = false
        
        if _G.ThePlayer == player then
            player.components.playercontroller:RefreshReticule(handitem)
        end
    end
end

AddComponentPostInit("playercontroller",function(self)
    local _oldTryAOETargeting = self.TryAOETargeting

    self.TryAOETargeting = function(self)
        print("TryAOETargeting")
        return _oldTryAOETargeting(self)
    end
end)

AddComponentPostInit("aoetargeting",function(self)
    local _oldStartTargeting = self.StartTargeting

    self.StartTargeting = function(self)
        if self.inst.components.reticule == nil then
            local owner = _G.ThePlayer
            if owner.components.playercontroller ~= nil then
                local inventoryitem = self.inst.replica.inventoryitem
                if inventoryitem ~= nil and inventoryitem:IsGrandOwner(owner) then
                    self.inst:AddComponent("reticule")
                    for k, v in pairs(self.reticule) do
                        self.inst.components.reticule[k] = v
                    end
                    if self.inst.isfirstAOE == nil and self.inst.multiple_reticule then
                        ChangeReticule(owner)
                    end
                    if self.inst.mustaoe then   
                        self.inst.components.reticule.mousetargetfn = nil
                        self.inst.components.reticule.updatepositionfn = nil
                        self.inst.mustaoe = nil
                    end
                    owner.components.playercontroller:RefreshReticule(self.inst)
                end
            end
        end
    end
end)

AddPlayerPostInit(function(inst)
    inst.Inforge_Skill_Key = _G.net_string(inst.GUID, "Inforge_Skill_Key", "Inforge_Skill_Key_dirty")

    inst.Inforge_Skill_Key:set("nil")

    inst:ListenForEvent("Inforge_Skill_Key_dirty", ChangeReticule)

    if not TheNet:IsDedicated() then
        TheInput:AddKeyHandler(function(key, down)
            local name = KEY_NAMES[key]
            if name then
                if down then
                    SendModRPCToServer(GetModRPC("Infernal_Forge_RPC", "SkillKeyState"),name, "down")
                else
                    SendModRPCToServer(GetModRPC("Infernal_Forge_RPC", "SkillKeyState"),name, "up")
                end
            end
        end)
    end
end)

local infernal_mod_name = {
    "workshop-2961923603", -- original mod
    "workshop-2996203358", -- beta test
    "infernal_test"  --alpha test
}

AddComponentPostInit("playercontroller", function(self)
    local _oldOnRemoteRightClick = self.OnRemoteRightClick

    self.OnRemoteRightClick = function(self, actioncode, position, target, rotation, isreleased, controlmodscode, noforce, mod_name)
        if self.ismastersim and self:IsEnabled() and self.handler == nil then
            self.remote_controls[_G.CONTROL_SECONDARY] = 0
            self:DecodeControlMods(controlmodscode)
            _G.SetClientRequestedAction(actioncode, mod_name)
            local lmb,  rmb= self.inst.components.playeractionpicker:DoGetMouseActions(position, target)
            _G.ClearClientRequestedAction()
            if isreleased then
                self.remote_controls[_G.CONTROL_SECONDARY] = nil
            end
            self:ClearControlMods()

            local isInfernalMod = false

            for _,name in pairs(infernal_mod_name) do
                if mod_name == nil and rmb.action.mod_name == name then
                    mod_name = rmb.action.mod_name
                    isInfernalMod = true
                end
            end

            if isInfernalMod == false then
                _oldOnRemoteRightClick(self, actioncode, position, target, rotation, isreleased, controlmodscode, noforce, mod_name)
            end


            if rmb ~= nil and rmb.action.code == actioncode and rmb.action.mod_name == mod_name then
                if rmb.action.canforce and not noforce then
                    rmb:SetActionPoint(self:GetRemotePredictPosition() or self.inst:GetPosition())
                    rmb.forced = true
                end
                rmb.rotation = rotation or rmb.rotation
                self:DoAction(rmb)
            --elseif mod_name ~= nil then
                --print("Remote right click action failed: "..tostring(ACTION_MOD_IDS[mod_name][actioncode]))
            --else
                --print("Remote right click action failed: "..tostring(ACTION_IDS[actioncode]))
            end
        end
    end
end)


local IGNORE_TAGS = {"notarget", "INLIMBO", "playerghost"}
AddComponentPostInit("projectile",function(self)
    self.distance_traveled = 0
	local old_OnUpdate = self.OnUpdate


	local function CheckForTargets(self, inst, check_walls)
		local current_pos = self.inst:GetPosition()
		current_pos.y = 0
		-- Get valid targets near the projectile
		local valid_targets = {}
		local target = nil
		local x, y, z = current_pos:Get()
        local ignore_targets = self.inst:HasTag("inf_onlyhitteammate") and _G.COMMON_FNS.GetEnemyTags(self.attacker) or (self.inst:HasTag("inf_canattackplayer") and IGNORE_TAGS or _G.COMMON_FNS.CommonExcludeTags(self.attacker))
		local ents = TheSim:FindEntities(x, y, z, 3, check_walls and {"wall"}, ignore_targets) -- TODO check hit radius throughout this function
		for _,ent in ipairs(ents) do
			-- The owner/attacker is not a valid target.
			if ent.entity:IsValid() and ent.entity:IsVisible() and ent.components.health and not ent.components.health:IsDead() and not (ent == self.attacker or ent == self.owner) and ent.components.combat then
				local hit_range = ent:GetPhysicsRadius(0) + self.hitdist
				local current_range = _G.distsq(current_pos, ent:GetPosition())
				if hit_range > current_range then
					table.insert(valid_targets, {target = ent, hit_range = hit_range, current_range = current_range})
				end
			end
		end
		-- Check if any valid target is within hit range? TODO check this
		for _,data in pairs(valid_targets) do
			if not target or data.current_range - data.hit_range < target.range then
				target = {ent = data.target, range = data.current_range - data.hit_range}
				break
			end
		end
		if target then -- TODO can't we call this inside that for loop and return?
			--print("Hit Target: " .. tostring(target.ent))
			if target.ent then
				if target.ent.OnProjectileHit then
					target.ent.OnProjectileHit(inst) -- Custom projectile hit for wall
				else
					self:Hit(target.ent)
				end
			end
		end
	end

	function self:OnUpdate(dt)
		if self.aimed_throw or self.dropped then
			local current_pos = self.inst:GetPosition()
			current_pos.y = 0
			-- Check if max range has been reached
			if self.aimed_throw and self.range and _G.distsq(self.start, current_pos) > self.range * self.range or self.dropped and self.life_fn and self.life_fn(self.inst) then
				self:Miss()
			else
				CheckForTargets(self, inst)
			end
		else
		    -- Update distance traveled
		    if self.range ~= nil then
		        self.distance_traveled = (self.distance_traveled or 0) + math.sqrt(_G.distsq(self.last_position, self.inst:GetPosition()))
		        self.last_position = self.inst:GetPosition()
		        -- Updating the start position so the original OnUpdate does not need to manually overwritten.
		        self.start = self.last_position + _G.Vector3(1,0,0) * self.distance_traveled
		    end
			old_OnUpdate(self, dt)
			if self.attacker then
				CheckForTargets(self, inst, true)
			end
		end
	end
end)


AddComponentPostInit("combat",function(self)
    local _oldCanHitTarget = self.CanHitTarget

    self.CanHitTarget = function(self, target, weapon)
        if self.inst ~= nil and
            self.inst:IsValid() and
            target ~= nil and
            target:IsValid() and
            not target:IsInLimbo() and
            (   self:CanExtinguishTarget(target, weapon) or
                self:CanLightTarget(target, weapon) or
                (   target.components.combat ~= nil and
                    target.components.combat:CanBeAttacked(self.inst)
                )
            ) then

            local targetpos = target:GetPosition()
            -- V2C: this is 3D distsq
            local pos = self.temppos or self.inst:GetPosition()
            if self.ignorehitrange or _G.distsq(targetpos, pos) <= self:CalcHitRangeSq(target) then
                return true
            elseif weapon ~= nil and weapon.components.projectile ~= nil then
                local range = target:GetPhysicsRadius(0) + weapon.components.projectile.hitdist
                -- V2C: this is 3D distsq
                return _G.distsq(targetpos, weapon:GetPosition()) <= range * range
            end
        end
        return false
    end
end)

AddComponentPostInit("combat_replica",function(self)
    local _oldIsValidTarget = self.IsValidTarget
    local _oldCanBeAttacked = self.CanBeAttacked

    self.IsValidTarget = function(self, target)
        if target == nil or
            target == self.inst or
            not (target.entity:IsValid() and target.entity:IsVisible()) then
            return false
        end

        local weapon = self:GetWeapon()
        return self:CanExtinguishTarget(target, weapon)
            or self:CanLightTarget(target, weapon)
            or (target.replica.combat ~= nil and
                not IsEntityDead(target, true) and
                not target:HasTag("spawnprotection") and
                not (target:HasTag("shadow") and self.inst.replica.sanity == nil and not self.inst:HasTag("crazy")) and
                not (target:HasTag("playerghost") and (self.inst.replica.sanity == nil or self.inst.replica.sanity:IsSane()) and not self.inst:HasTag("crazy")) and
                (not self.inst:HasTag("birchnutroot") or not (target:HasTag("birchnutroot") or target:HasTag("birchnut") or target:HasTag("birchnutdrake"))) and
                (TheNet:GetPVPEnabled() or not (self.inst:HasTag("player") and target:HasTag("player")) or (weapon ~= nil and weapon:HasTag("inf_canattackplayer"))) and
                target:GetPosition().y <= self._attackrange:value())
    end

    self.CanBeAttacked = function(self, attacker)
        if self.inst:HasTag("playerghost") or
            self.inst:HasTag("flight") or
            (	not self.temp_iframes_keep_aggro and
                (	self.inst:HasTag("noattack") or
                    self.inst:HasTag("invisible")
                )
            )
        then
            --Can't be attacked by anyone
            return false
        end

        local sanity

        if attacker ~= nil then
            --Attacker checks
            if self.inst:HasTag("birchnutdrake")
                and (attacker:HasTag("birchnutdrake") or
                    attacker:HasTag("birchnutroot") or
                    attacker:HasTag("birchnut")) then
                --Birchnut check
                return false
            elseif self.inst:HasTag("noplayertarget") and attacker:HasTag("player") then
                --Can't be attacked by players
                return false
            elseif attacker ~= self.inst and self.inst:HasTag("player") then
                --Player target check
                if not TheNet:GetPVPEnabled() and attacker:HasTag("player") then
                    --PVP check
                    local combat = attacker.replica.combat
                    local weapon = combat ~= nil and combat:GetWeapon() or nil
                    if weapon == nil or not weapon:HasTag("inf_canattackplayer") then
                        --Allow friendly fire with props
                        return false
                    end
                end
                if self._target:value() ~= attacker then
                    local follower = attacker.replica.follower
                    if follower ~= nil then
                        local leader = follower:GetLeader()
                        if leader ~= nil and
                            leader ~= self._target:value() and
                            leader:HasTag("player") then
                            local combat = attacker.replica.combat
                            if combat ~= nil and combat:GetTarget() ~= self.inst then
                                --Follower check
                                print("Follower","false")
                                return false
                            end
                        end
                    end
                end
            end

            sanity = attacker.replica.sanity

            if sanity ~= nil and sanity:IsCrazy() or attacker:HasTag("crazy") then
                --Insane attacker can pretty much attack anything
                return true
            end
        end

        if self.inst:HasAnyTag("shadowcreature", "nightmarecreature") and
            (	self._target:value() == nil
                --[[or (--See if we're targeting someone else, and attacker isn't insane enough to help
                    attacker ~= nil and
                    sanity ~= nil and --set already in the above attacker ~= nil block
                    self._target:value() ~= attacker and
                    not (sanity:IsInsanityMode() and sanity:GetPercent() < .5)
                    )]]
                --V2C: The above version is the correct design; we should never have
                --     allowed targeting invisible entities.
                --     TODO: Add/improve items for revealing shadow creatures so we
                --           can switch to that version.
                or (--See if we're targeting someone else, but not actually hostile to them
                    attacker ~= nil and
                    self._target:value() ~= attacker and
                    (self.inst.HostileToPlayerTest ~= nil and not self.inst:HostileToPlayerTest(self._target:value()))
                    )
            ) and
            --Allow AOE damage on stationary shadows like Unseen Hands
            (attacker ~= nil or self.inst:HasTag("locomotor")) then
            --Not insane attacker cannot attack shadow creatures
            --(unless shadow creature is targeting attacker, or targeting
            -- someone else, and attacker is below 50% sanity to help out)
            return false
        end

        --Passed all checks, can be attacked by anyone
        return true
    end
end)

--[[
AddComponentPostInit("playeractionpicker", function(self)
    local _oldDoGetMouseActions = self.DoGetMouseActions

    self.DoGetMouseActions = function(self, position, target, spellbook)
        local isaoetargeting = false
        local wantsaoetargeting = false

        if position == nil then
            if TheInput:GetHUDEntityUnderMouse() ~= nil then
                return
            end

            isaoetargeting = self.inst.components.playercontroller:IsAOETargeting()
            --@V2C: #FORGE_AOE_RCLICK *searchable*
            --      -Forge used to strip all r.click actions to force r.click to start aoe targeting no matter what.
            --      -Now we only want to start aoe targeting if there are no other meaningful actions.
            --      -GetRightClickActions will naturally return nil in that case now.
            --wantsaoetargeting = not isaoetargeting and self.inst.components.playercontroller:HasAOETargeting()

            if isaoetargeting then
                position = self.inst.components.playercontroller:GetAOETargetingPos()
                spellbook = spellbook or self.inst.components.playercontroller:GetActiveSpellBook()
            else
                position = TheInput:GetWorldPosition()
                target = target or TheInput:GetWorldEntityUnderMouse()
            end

            local cansee
            if target == nil then
                local x, y, z = position:Get()
                cansee = _G.CanEntitySeePoint(self.inst, x, y, z)
            else
                cansee = target == self.inst or _G.CanEntitySeeTarget(self.inst, target)
            end

            --Check for actions in the dark
            if not cansee then
                local lmb = nil
                local rmb = nil
                if not isaoetargeting then
                    local lmbs = self:GetLeftClickActions(position)
                    for i, v in ipairs(lmbs) do
                        if (v.action == ACTIONS.DROP and self.inst:GetDistanceSqToPoint(position:Get()) < 16) or
                            v.action == ACTIONS.SET_HEADING or
                            v.action == ACTIONS.BOAT_CANNON_SHOOT then

                            lmb = v
                        end
                    end

                    local rmbs = self:GetRightClickActions(position, nil, spellbook)
                    for i, v in ipairs(rmbs) do
                        if (v.action == ACTIONS.STOP_STEERING_BOAT) or
                            v.action == ACTIONS.BOAT_CANNON_STOP_AIMING then
                            rmb = v
                        end
                    end
                end

                if rmb ~= nil then
                    for i,v in pairs(rmb) do
                        print("[1][PlayerActionPicker]",i,v)
                    end
                else
                    print("[1][PlayerActionPicker]","NONONONONON")
                end
                return lmb, rmb
            end
        end

        local lmb = not isaoetargeting and self:GetLeftClickActions(position, target)[1] or nil
        local rmb = not wantsaoetargeting and self:GetRightClickActions(position, target, spellbook)[1] or nil

        --@V2C: Filtering out local UI actions that we do not really want as explicit actions.
        --e.g. CLOSESPELLBOOK we can just [Esc] or R.Click anywhere to achieve the same thing,
        --     so we'd rather not have the player highlighted with an action prompt.
        --     (NOTE: We still generate these actions so that they block lower priority ones.)
        if rmb and rmb.action == _G.ACTIONS.CLOSESPELLBOOK and rmb.target == rmb.doer then
            rmb = nil
        end

        if rmb ~= nil then
            for i,v in pairs(rmb) do
                print("[2][PlayerActionPicker]",i,v)
            end
        else
            print("[2][PlayerActionPicker]","NONONONONON")
        end

        return _oldDoGetMouseActions(self, position, target, spellbook)
    end
end)
]]--