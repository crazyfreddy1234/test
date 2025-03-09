local STRINGS = _G.STRINGS
local RF_DATA = _G.REFORGED_DATA

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




AddClassPostConstruct("widgets/game_settings_panel", function(self)
    local _OldGetOptions = self.GetOptions
    local _OldUpdateSetting = self.UpdateSetting

    local function SetOrdinary()
        local spinner = self.spinners.waveset.spinner
        local wavesets = self:GetWavesets()
        spinner:SetOptions(wavesets)
        spinner:SetSelected(self.settings.current.waveset)
    end

    local function CheckException(self,category,name)  --only work by map and waveset    --TODO can check by anything?
        local map_name          = self.settings.selected.map or self.settings.current.map
        local map_data  = RF_DATA.maps[map_name]

        local waveset_data = RF_DATA.wavesets[name]

        if category == "wavesets" and name == "swineclops" 
            or (map_data.is_dungeon == nil and waveset_data.must_map == nil) 
            or (map_data.is_dungeon == true and waveset_data.must_map ~= nil and map_name == waveset_data.must_map) then

            return true
        else
            return false
        end
    end
    
    self.GetOptions = function(self,category)
        local options = {}
        local strings = STRINGS.REFORGED[string.upper(category)]
        for name,data in pairs(RF_DATA[category] or {}) do
            local map_data = RF_DATA.maps[self.settings.selected.map or self.settings.current.map]
            local difficulties_name = self.settings.selected.difficulty or self.settings.current.difficulty
            if not (category == "wavesets" and (not _G.REFORGED_SETTINGS.other.enable_sandbox and name == "sandbox" or map_data and map_data.spawners < data.spawners)) 
                and not (category == "wavesets" and name == "Ordinary" and (not _G.REFORGED_SETTINGS.other.enable_sandbox and name == "sandbox" or difficulties_name and difficulties_name == "extrahard")) 
                and not (category == "wavesets" and name == "Extraordinary" and (not _G.REFORGED_SETTINGS.other.enable_sandbox and name == "sandbox" or difficulties_name and difficulties_name ~= "extrahard")) 
                and CheckException(self,category,name) then

                table.insert(options, {text = strings and (strings[name] and strings[name].name or strings[name]) or STRINGS.REFORGED.unknown, data = name, order_priority = data.order_priority or 999})
            end
        end
        table.sort(options, function(a, b)
            return a.order_priority < b.order_priority
        end)
        return options
    end

    self.UpdateSetting = function(self, setting, value)
        local selected_waveset    = self.settings.selected.waveset    or self.settings.current.waveset
        local selected_difficulty = self.settings.selected.difficulty or self.settings.current.difficulty
        local selected_map        = self.settings.selected.map        or self.settings.current.map

        local map_data  = RF_DATA.maps[selected_map]

        if ((selected_waveset == "Ordinary" and selected_difficulty == "extrahard") or (selected_waveset == "Extraordinary" and selected_difficulty ~= "extrahard")) 
            and self.isselected ~= true then

            local spinner = self.spinners.waveset.spinner
            local wavesets = self:GetWavesets()
            self.isselected = true
            spinner:SetOptions(wavesets)

            if selected_waveset == "Ordinary" then
                spinner:SetSelected("Extraordinary")
                self.isselected = nil
            elseif selected_waveset == "Extraordinary" then
                spinner:SetSelected("Ordinary")
                self.isselected = nil
            end
        end

        --[[
        if map_data and map_data.is_dungeon and (selected_waveset ~= map_data.must_waveset or selected_waveset ~= "swineclops") and self.isselected ~= true then
            local spinner = self.spinners.waveset.spinner
            local wavesets = self:GetWavesets()

            self.isselected = true
            spinner:SetOptions(wavesets)

            spinner:SetSelected(map_data.must_waveset)
            self.isselected = nil
        end
        ]]--

        _OldUpdateSetting(self, setting, value)
    end

    SetOrdinary()
end)

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
                self.inst.components.aoetargeting:SetEnabled(false)
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

local Badge         = require "widgets/badge"
local PowerMeter    = require "widgets/test_widget"
local SkillMeter    = require "widgets/skill_widget"
AddClassPostConstruct("widgets/statusdisplays_lavaarena", function(self)
	self.powerwidget = self:AddChild(PowerMeter(self.owner))
	self.powerwidget:SetPosition(-80,-20,0)
    
    self.powerwidget.circleframe:Hide()
    self.powerwidget.anim:Hide()
    self.powerwidget.num:Hide()  

    self.skillwidget = self:AddChild(SkillMeter(self.owner))
    self.skillwidget:SetPosition(-200,-20,0)
    self.skillwidget.circleframe:Hide()
    self.skillwidget.anim:Hide()
    self.skillwidget.num:Hide()  
end)

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
