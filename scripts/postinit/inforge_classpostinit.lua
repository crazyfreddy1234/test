local STRINGS = _G.STRINGS
local RF_DATA = _G.REFORGED_DATA

local env = env or GLOBAL or _G
env.Node = env.Node or {}
local _OldAddEntity = env.Node.AddEntity

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
        local map_name  = self.settings.selected.map or self.settings.current.map
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













local Badge         = require "widgets/badge"
local PowerMeter    = require "widgets/test_widget"
local SkillMeter    = require "widgets/skill_widget"
local TeamHud       = require "widgets/skill_widget"

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


    self.teamhud = self:AddChild(TeamHud(self.owner))
    self.teamhud:SetPosition(-200,-20,0)
    self.teamhud:Show()
end)














local StackDisplay = require("widgets/stackdisplay")

AddClassPostConstruct("widgets/inventorybar", function(self)
    print("[INV]ACTIVATE")
    self.owner:DoTaskInTime(_G.FRAMES,function()
        if not self.owner or not self.owner.components or not self.owner.components.inventory then
            return
        end

        -- 장착된 무기인지 확인
        local inv = self.owner.components.inventory
        local equipped = inv and inv:GetEquippedItem(_G.EQUIPSLOTS.HANDS)

        print("[INV]",equipped)

        -- 현재 ItemTile이 장착 무기에 해당하지 않으면 무시
        if not (equipped) then
            return
        end

        -- HUD에 이미 StackDisplay가 있다면 제거
        if self.stackdisplay then
            self.stackdisplay:Kill()
            self.stackdisplay = nil
        end

        -- 조건 만족 시 새 HUD 생성
        if equipped ~= nil then -- 또는 HasTag("stack_hud")
            --[[
            local display = StackDisplay(_G.ThePlayer, equipped)
            _G.ThePlayer.HUD.stackdisplay = _G.ThePlayer.HUD:AddChild(display)
            display:MoveToFront()
            ]]--

            self.stackdisplay = self.root:AddChild(StackDisplay(self.owner, equipped))
            self.stackdisplay:MoveToFront()
            self.owner.stackdisplay = self.stackdisplay
        end
    end)
end)












AddClassPostConstruct("widgets/debuff_display", function(self)
    local _OldSetTarget = self.SetTarget

    local function ApplyStackedPercents(description, stack)
        return description:gsub("{([%-+]?%d+)}", function(num)
            local base = _G.tonumber(num)
            if base then
                return _G.tostring(base * stack)
            else
                return num
            end
        end)
    end

    self._onclientdebuffstackdirty = function(inst, data)
        if data ~= nil and (data.name ~= nil and STRINGS.REFORGED.DEBUFFS[data.name] ~= nil) and data.stack ~= nil then
            local debuff_description = STRINGS.REFORGED.DEBUFFS[data.name]
            local stack = data.stack

            print(STRINGS.REFORGED.DEBUFFS[data.name])
            print(data.stack)

            STRINGS.REFORGED.DEBUFFS[data.name] = ApplyStackedPercents(debuff_description, stack)
        end
        
        self:Update()
    end

    self.SetTarget = function(self, target, force_update)
        _OldSetTarget(self, target, force_update)

        if target and self.target == target then
            if self.target ~= nil then
                self.inst:RemoveEventCallback("stackchanged", self._onclientdebuffstackdirty, self.target)
            end

            self.inst:ListenForEvent("stackchanged", self._onclientdebuffstackdirty, target)
        end
    end
end)



