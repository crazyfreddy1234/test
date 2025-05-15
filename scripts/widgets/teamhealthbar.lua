local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"


local TeamHealthBar = Class(Widget, function(self, target_player, owner)
    Widget._ctor(self, "TeamHealthBar")

    self.owner = owner -- 누가 이걸 보고 있는지 (나)
    self.target_player = target_player -- 이 체력바의 대상 플레이어

    -- 체력 바 틀 (검정 배경)
    self.bg = self:AddChild(Image("images/global.xml", "square.tex"))
    self.bg:SetSize(150, 100) -- (너비, 높이)
    self.bg:SetTint(0, 0, 0, 1) -- 검정색

    -- 체력 바 내용 (채워지는 부분)
    self.hp_fill = self:AddChild(Image("images/global.xml", "square.tex"))
    self.hp_fill:SetSize(150, 100)
    self.hp_fill:SetTint(1, 0, 0, 1) -- 빨간색
    self.hp_fill:SetPosition(0, 0) -- 초기 위치

    self.name = self:AddChild(Text(CHATFONT, 22))
    self.name:SetString(self.target_player:GetDisplayName())
    self.name:SetPosition(0, 35)
    self.name:SetColour(1, 1, 1, 0.8)

    self.status_text = self:AddChild(Text(CHATFONT, 22))
    self.status_text:SetPosition(0, 0)
    self.status_text:SetColour(1, 1, 1, 1)

    self:SetPercent(1)

    if self.target_player.net_health_percent:value() ~= 1 then
        local percent = self.target_player.net_health_percent:value()
        self:SetPercent(percent)
    end


    local function HealthNetChange(inst)  
        local percent = inst.net_health_percent:value()
        self:SetPercent(percent)
    end
    

    if self.target_player.net_health_percent and self.target_player.net_health_percent:value() ~= 1 then
        HealthNetChange(self.target_player)
    end

    self.target_player:ListenForEvent("healthdirty", function()
        
        HealthNetChange(self.target_player)

    end, self.target_player)
end)

function TeamHealthBar:OnControl(control, down)
    if TeamHealthBar._base.OnControl(self, control, down) then
        return true
    end

    if down then
        if control == CONTROL_ACCEPT then
            print("[TeamHealthBar] 완쪽 클릭됨!")
            SendModRPCToServer(GetModRPC("Infernal_Forge_RPC", "item_click"), self.target_player.userid)
            return true
        elseif control == CONTROL_SECONDARY then
            print("[TeamHealthBar] 오른쪽 클릭됨!")
            SendModRPCToServer(GetModRPC("Infernal_Forge_RPC", "item_right_click"), self.target_player.userid)
            return true
        end
    end

    return false
end

function TeamHealthBar:SetPercent(health_percent)
    -- 체력에 따라 바 크기 계산
    local max_height = 100 -- 배경 네모 높이
    local new_height = max_height * health_percent

    self.hp_fill:SetSize(150, new_height) -- 높이만 조절
    self.hp_fill:SetPosition(0, -(max_height - new_height) / 2) -- 바닥에서 채워지는 느낌으로 조정

    if health_percent <= 0 then
        self.status_text:SetString("Dead")
        self.status_text:SetColour(1, 0.2, 0.2, 1)
    else
        self.status_text:SetString(string.format("%d%%", health_percent * 100))
        self.status_text:SetColour(1, 1, 1, 1)
    end
end

return TeamHealthBar