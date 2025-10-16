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
--local TeamHud       = require "widgets/skill_widget"

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


    --self.teamhud = self:AddChild(TeamHud(self.owner))
    --self.teamhud:SetPosition(-200,-20,0)
    --self.teamhud:Show()
end)














local StackDisplay = require("widgets/stackdisplay")

AddClassPostConstruct("widgets/inventorybar", function(self)
    self.owner:DoTaskInTime(_G.FRAMES,function()
        if not self.owner or not self.owner.components or not self.owner.components.inventory then
            return
        end

        -- 장착된 무기인지 확인
        local inv = self.owner.components.inventory
        local equipped = inv and inv:GetEquippedItem(_G.EQUIPSLOTS.HANDS)

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
            self.owner.stackdisplay:HideText()
        end
    end)
end)















AddClassPostConstruct("widgets/debuff_display", function(self)

    local OldSetTarget = self.SetTarget
    local OldUpdate = self.Update

    self.stack_description = {}
    self.existing_stack_debuffs = {}
    self.debuffstack_count = {}
    self.stackdisplay = {}

        self._onclientdebuffstackdirty = function(inst)
        self:UpdateStackText()
    end

    function self:UpdateStackText()
        if self.target and self.target.replica.debuffable then
            local stackdebuff_str = self.target.stackdebuff_data:value()
            local name, stk = string.match(stackdebuff_str, "{([^=]+)=([^}]+)}")

            if name == nil or stk == nil then return end

            local debuff_description = name .. "_DESCRIPTION"
            local reforge_string = STRINGS.REFORGED.DEBUFFS
            local result = nil

            if name ~= nil and stk ~= nil and reforge_string[name] ~= nil and reforge_string[debuff_description] ~= nil then
                local str = reforge_string[debuff_description]

                result = str:gsub("{(.-)}", function(number_str)
                    local num = _G.tonumber(number_str)
                    if num then
                        local new_num = num * stk
                        return _G.tostring(new_num)
                    else
                        return number_str
                    end
                end)

                self.stack_description[name] = reforge_string[name] .. result
                self.debuffstack_count[name] = stk
                self:Update()
            end
        end
    end

    self.Update = function(self)
        if self.stack_description ~= nil then
            self.existing_stack_debuffs = {}

            if self.target and self.target.replica.debuffable then
                local debuffs = self.target.replica.debuffable:GetCurrentDebuffs()
                local count = 0
                local row = 1

                for name,_ in pairs(debuffs) do
                    count = count + 1
                    row = math.ceil(count/self.debuffs_per_row)
                    if not self.icons[count] then
                        local Image = require "widgets/image"

                        self.icons[count] = self:AddChild(Image())
                    end
                    local icon_info = self:GetDebuffIconInfo(name)
                    self.icons[count]:SetTexture(icon_info.atlas, icon_info.tex)

                    if self.stack_description[name] ~= nil then
                        local DebuffStack_Display = require("widgets/debuffstack_display")

                        if self.stackdisplay[name] ~= nil then
                            self.stackdisplay[name]:Kill()
                            self.stackdisplay[name] = nil
                        end

                        self.stackdisplay[name] = self:AddChild(DebuffStack_Display())
                        self.stackdisplay[name]:MoveToFront()
                        self.stackdisplay[name]:ShowText(self.debuffstack_count[name] or 1)

                        self.existing_stack_debuffs[name] = true
                        self.icons[count]:SetHoverText(self.stack_description[name])

                        self.icons[count]:SetPosition((((count - 1) % self.debuffs_per_row) + 1 - 1) * (self.icon_width + self.spacing), (row - 1) * (self.icon_height + self.spacing) * (self.add_icons_top_to_bottom and -1 or 1))
                        self.stackdisplay[name]:SetPosition( ((((count - 1) % self.debuffs_per_row) + 1 - 1) * (self.icon_width + self.spacing)) + 20 , ((row - 1) * (self.icon_height + self.spacing) * (self.add_icons_top_to_bottom and -1 or 1)) - 10 )
                    else
                        self.icons[count]:SetHoverText(icon_info.hover_text)
                        self.icons[count]:SetPosition((((count - 1) % self.debuffs_per_row) + 1 - 1) * (self.icon_width + self.spacing), (row - 1) * (self.icon_height + self.spacing) * (self.add_icons_top_to_bottom and -1 or 1))
                    end

                    
                    self.icons[count]:Show()
                end
                
                -- Hide extra icons
                if #self.icons > count then
                    for i = count + 1, #self.icons do
                        self.icons[i]:Hide()
                    end
                end
            else
            end
            
            for name,_ in pairs(self.stack_description) do
                local found = false
                for nam, _ in pairs(self.existing_stack_debuffs) do
                    if name == nam then
                        found = true
                        break
                    end
                end

                if not found then
                    self.stack_description[name] = nil
                    self.debuffstack_count[name] = nil

                    self.stackdisplay[name]:Kill()
                    self.stackdisplay[name] = nil
                end
            end

            
        else
            OldUpdate(self)
        end
    end


    self.SetTarget = function(self, target, force_update)   
        OldSetTarget(self, target, force_update)
         
        if target then
            if self.target ~= nil then
                self.target:RemoveEventCallback("stackdebuff_update_dirty", self._onclientdebuffstackdirty)
            end
            target:ListenForEvent("stackdebuff_update_dirty", self._onclientdebuffstackdirty)
        end
    end
end)
