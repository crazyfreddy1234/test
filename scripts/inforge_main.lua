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




    inst._stack_count = _G.net_smallbyte(inst.GUID, "inf.stack", "inf_stackdirty")
    inst._Update_Stack = _G.net_bool(inst.GUID, "inf.updatestac", "inf_updatestackdirty")
    inst._stack_count:set(0)

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




        if inst and inst.stackdisplay ~= nil then
            inst.stackdisplay:UpdateText()
        end
    ----------------------------------------------------------------------

        inst:DoTaskInTime(0,function()
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
    print("[INFERNAL] FindPlayerByUserID : no player")
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

    print("[INFORGE] " .. self.pickup_cooldown)

	-- ✅ 스택 상태 초기화
	self.max_stacks = 2
    self.current_stacks = self.max_stacks
    self.recharge_queue = {}
    self.inforge_owner = nil



    local Old_StartRecharge = self.StartRecharge
    function self:StartRecharge()
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

                if self.inst.components.aoetargeting and self.current_stacks <= 0 then
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

        print("[INFORGE] USECHARGE " .. self.current_stacks)

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
    function self:FinishRecharge(...)
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